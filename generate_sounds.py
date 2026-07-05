#!/usr/bin/env python3
"""Generate funny cartoon sound effects for the caterpillar game."""
import struct, wave, math, random, os

RATE = 44100

def write_wav(path, samples):
    with wave.open(path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        for s in samples:
            f.writeframes(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))))

def gen_move():
    """Squeaky spring boing – quick pitch sweep up then down."""
    dur = 0.22
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        p = t / dur  # 0..1
        # frequency sweep: up from 300 to 900 then back down
        if p < 0.35:
            freq = 300 + (900 - 300) * (p / 0.35)
        else:
            freq = 900 - (900 - 400) * ((p - 0.35) / 0.65)
        # add a wobble for comedy
        freq += 80 * math.sin(2 * math.pi * 18 * t)
        phase = 2 * math.pi * freq * t
        # envelope: quick attack, medium decay
        env = min(1.0, t / 0.01) * max(0.0, 1.0 - t / dur)
        env = env ** 0.6
        sample = 0.7 * math.sin(phase) + 0.3 * math.sin(phase * 2.02)
        out.append(sample * env * 0.65)
    return out

def gen_bite():
    """Apple bite – sharp crack then juicy crunch."""
    dur = 0.38
    n = int(RATE * dur)
    rng = random.Random(42)
    out = []
    # Pre-generate crunch grain timings (little random impulse clicks)
    grain_times = sorted([rng.uniform(0.01, 0.25) for _ in range(60)])
    for i in range(n):
        t = i / RATE
        s = 0.0

        # 1) Initial skin crack – sharp transient at t=0
        if t < 0.012:
            crack_env = (1.0 - t / 0.012) ** 2
            s += (rng.random() * 2 - 1) * crack_env * 0.95

        # 2) Jaw thud – low frequency impact
        if t < 0.06:
            thud_env = math.exp(-50 * t)
            s += math.sin(2 * math.pi * 120 * t) * thud_env * 0.6

        # 3) Crunchy texture – dense burst of filtered noise grains
        if t < 0.22:
            crunch_env = math.exp(-6 * t) * 0.55
            # Bandpassed noise (resonant crunch around 2-4 kHz feel via shaped noise)
            noise_raw = rng.random() * 2 - 1
            # Shape with a simple resonance
            freq_r = 2800 + 800 * math.sin(t * 90)
            resonance = math.sin(2 * math.pi * freq_r * t) * 0.3
            s += (noise_raw * 0.7 + resonance) * crunch_env

        # 4) Micro-grain pops (individual fiber snaps)
        for gt in grain_times:
            dt = t - gt
            if 0 < dt < 0.004:
                grain_env = (1.0 - dt / 0.004) ** 3
                s += grain_env * (rng.random() * 2 - 1) * 0.3

        # 5) Juicy wet tail – slight squelch
        if 0.08 < t < 0.30:
            wet_t = t - 0.08
            wet_env = math.sin(math.pi * wet_t / 0.22) * 0.15
            wet_freq = 400 + 200 * math.sin(t * 60)
            s += math.sin(2 * math.pi * wet_freq * t) * wet_env

        # 6) Gentle fade-out body resonance
        if t > 0.15:
            tail_env = math.exp(-8 * (t - 0.15)) * 0.12
            s += math.sin(2 * math.pi * 180 * t) * tail_env

        out.append(max(-1.0, min(1.0, s * 0.75)))
    return out

def gen_eat():
    """Funny gulp/burp when wall is fully eaten."""
    dur = 0.45
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        p = t / dur
        # descending wobble "gulp"
        freq = 350 - 200 * p + 60 * math.sin(2 * math.pi * 6 * t)
        env = math.exp(-3 * t) * min(1.0, t / 0.01)
        # add harmonics for burpy quality
        phase = 2 * math.pi * freq * t
        s = (0.5 * math.sin(phase) +
             0.3 * math.sin(phase * 1.5 + 0.5) +
             0.2 * math.sin(phase * 0.5))
        # little pop at the end
        if 0.32 < t < 0.40:
            pop_t = t - 0.32
            pop_env = math.sin(math.pi * pop_t / 0.08) * 0.3
            s += math.sin(2 * math.pi * 500 * pop_t) * pop_env
        out.append(s * env * 0.7)
    return out

def gen_leaf():
    """Happy sparkle pickup sound."""
    dur = 0.30
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        # ascending arpeggio: three quick notes
        if t < 0.10:
            freq = 800
            env = math.sin(math.pi * t / 0.10)
        elif t < 0.20:
            freq = 1100
            env = math.sin(math.pi * (t - 0.10) / 0.10)
        else:
            freq = 1400
            env = math.sin(math.pi * (t - 0.20) / 0.10)
        s = math.sin(2 * math.pi * freq * t) * 0.5
        s += math.sin(2 * math.pi * freq * 2 * t) * 0.25
        s += math.sin(2 * math.pi * freq * 3 * t) * 0.1
        out.append(s * env * 0.6)
    return out

def gen_portal():
    """Warp/teleport whoosh."""
    dur = 0.50
    n = int(RATE * dur)
    rng = random.Random(99)
    out = []
    for i in range(n):
        t = i / RATE
        p = t / dur
        # ascending sweep with noise
        freq = 200 + 1200 * p * p
        env = math.sin(math.pi * p) ** 0.5
        s = math.sin(2 * math.pi * freq * t) * 0.5
        s += (rng.random() * 2 - 1) * 0.15 * env
        # shimmer
        s += math.sin(2 * math.pi * (freq * 1.5) * t) * 0.2
        out.append(s * env * 0.6)
    return out

def gen_spider():
    """Creepy skitter sound for spider."""
    dur = 0.25
    n = int(RATE * dur)
    rng = random.Random(77)
    out = []
    for i in range(n):
        t = i / RATE
        # rapid clicking/tapping
        click_rate = 25
        click_phase = (t * click_rate) % 1.0
        click = 1.0 if click_phase < 0.1 else 0.0
        # filtered noise for each click
        noise = (rng.random() * 2 - 1)
        env = math.exp(-3 * t)
        s = noise * click * 0.4 + math.sin(2 * math.pi * 180 * t) * click * 0.3
        out.append(s * env * 0.7)
    return out

def gen_ouch():
    """Cartoony ouch yelp for spike hit."""
    dur = 0.28
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        p = t / dur
        # Falling yelp pitch with slight wobble.
        freq = 980 - 520 * p + 45 * math.sin(2 * math.pi * 11 * t)
        env = (min(1.0, t / 0.015) * max(0.0, 1.0 - p)) ** 0.7
        phase = 2 * math.pi * freq * t
        s = 0.62 * math.sin(phase)
        s += 0.24 * math.sin(phase * 1.95 + 0.4)
        s += 0.10 * math.sin(phase * 0.53)
        # Tiny initial click to make impact feel immediate.
        if t < 0.006:
            s += (1.0 - t / 0.006) * 0.35
        out.append(s * env * 0.75)
    return out

if __name__ == "__main__":
    outdir = os.path.join(os.path.dirname(__file__), "assets", "sounds")
    os.makedirs(outdir, exist_ok=True)
    sounds = {
        "move_step.wav": gen_move(),
        "bite.wav": gen_bite(),
        "eat_wall.wav": gen_eat(),
        "leaf_pickup.wav": gen_leaf(),
        "portal_enter.wav": gen_portal(),
        "spider_alert.wav": gen_spider(),
        "ouch.wav": gen_ouch(),
    }
    for name, samples in sounds.items():
        path = os.path.join(outdir, name)
        write_wav(path, samples)
        print(f"  wrote {path}  ({len(samples)/RATE:.2f}s, {len(samples)} samples)")
    print("Done!")
