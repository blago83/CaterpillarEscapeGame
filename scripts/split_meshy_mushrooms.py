#!/usr/bin/env python3
import json
import struct
from pathlib import Path

import numpy as np

SOURCE = Path("assets/mushrooms/Meshy_AI_Toadstool_Parade_0704201945_texture.glb")
OUTPUT_DIR = Path("assets/mushrooms/meshy_split_mushrooms")
CLUSTER_COUNT = 8

CTYPE_TO_DTYPE = {
    5126: np.dtype("<f4"),
    5125: np.dtype("<u4"),
    5123: np.dtype("<u2"),
    5121: np.dtype("u1"),
}
TYPE_COUNTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def align4(value: int) -> int:
    return (value + 3) & ~3


def parse_glb(path: Path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67 or version != 2:
        raise ValueError("Unsupported GLB")
    pos = 12
    json_chunk = None
    bin_chunk = None
    while pos < length:
        chunk_len, chunk_type = struct.unpack_from("<II", data, pos)
        pos += 8
        chunk = data[pos:pos + chunk_len]
        pos += chunk_len
        if chunk_type == 0x4E4F534A:
            json_chunk = chunk
        elif chunk_type == 0x004E4942:
            bin_chunk = chunk
    if json_chunk is None or bin_chunk is None:
        raise ValueError("Missing JSON or BIN chunk")
    return json.loads(json_chunk.decode("utf-8")), bin_chunk


def read_accessor(gltf, bin_chunk, accessor_index: int):
    accessor = gltf["accessors"][accessor_index]
    view = gltf["bufferViews"][accessor["bufferView"]]
    offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    count = accessor["count"]
    components = TYPE_COUNTS[accessor["type"]]
    dtype = CTYPE_TO_DTYPE[accessor["componentType"]]
    raw = bin_chunk[offset: offset + count * components * dtype.itemsize]
    arr = np.frombuffer(raw, dtype=dtype)
    if components > 1:
        arr = arr.reshape((count, components))
    return arr


def connected_components(indices: np.ndarray, vertex_count: int):
    parent = np.arange(vertex_count, dtype=np.int64)
    rank = np.zeros(vertex_count, dtype=np.int8)

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a: int, b: int):
        ra, rb = find(a), find(b)
        if ra == rb:
            return
        if rank[ra] < rank[rb]:
            parent[ra] = rb
        elif rank[ra] > rank[rb]:
            parent[rb] = ra
        else:
            parent[rb] = ra
            rank[ra] += 1

    for tri in indices:
        a, b, c = map(int, tri)
        union(a, b)
        union(b, c)
        union(a, c)

    roots = np.array([find(i) for i in range(vertex_count)], dtype=np.int64)
    tri_roots = roots[indices[:, 0]]
    unique_roots = np.unique(tri_roots)
    components = []
    for root in unique_roots:
        tri_mask = tri_roots == root
        tri_subset = indices[tri_mask]
        verts = np.unique(tri_subset.reshape(-1))
        components.append({
            "root": int(root),
            "triangles": tri_subset,
            "vertices": verts,
        })
    return components


def build_component_stats(components: list, positions: np.ndarray):
    centers = []
    tri_counts = []
    heights = []
    widths = []
    for comp in components:
        pts = positions[comp["vertices"]]
        mn = pts.min(axis=0)
        mx = pts.max(axis=0)
        size = mx - mn
        centers.append(pts.mean(axis=0))
        tri_counts.append(len(comp["triangles"]))
        heights.append(float(size[1]))
        widths.append(float(max(size[0], size[2])))
    return {
        "centers": np.array(centers, dtype=np.float64),
        "tri_counts": np.array(tri_counts, dtype=np.int64),
        "heights": np.array(heights, dtype=np.float64),
        "widths": np.array(widths, dtype=np.float64),
    }


def choose_row_aware_anchors(stats: dict, k: int):
    if k != 8:
        raise ValueError("This splitter expects 8 mushrooms (4 per row)")

    centers = stats["centers"]
    tri_counts = stats["tri_counts"]
    heights = stats["heights"]
    widths = stats["widths"]
    if len(centers) < k:
        raise ValueError(f"Need at least {k} components, got {len(centers)}")

    ratios = heights / np.maximum(widths, 1e-6)
    score = tri_counts.astype(np.float64) * (1.0 + 0.65 * ratios)
    candidates = np.argsort(score)[::-1]

    # First gather spatially separated candidates.
    separated: list[int] = []
    for idx in candidates:
        idx = int(idx)
        if tri_counts[idx] < 80:
            break
        if not separated:
            separated.append(idx)
            continue
        pts = centers[np.array(separated)][:, :2]
        d2 = ((pts - centers[idx][:2]) ** 2).sum(axis=1)
        if float(d2.min()) >= 0.020:
            separated.append(idx)
        if len(separated) >= 24:
            break

    if len(separated) < 8:
        for idx in candidates:
            idx = int(idx)
            if idx not in separated:
                separated.append(idx)
            if len(separated) >= 8:
                break

    # Force row layout: pick 4 highest-Y and 4 lowest-Y anchors.
    by_y = sorted(separated, key=lambda i: centers[i][1], reverse=True)
    top = by_y[:4]
    bottom = sorted(by_y[4:], key=lambda i: centers[i][1])[:4]
    if len(top) < 4 or len(bottom) < 4:
        # Fallback if candidate pool is too small.
        all_by_y = sorted(range(len(centers)), key=lambda i: centers[i][1], reverse=True)
        top = all_by_y[:4]
        bottom = sorted(all_by_y[4:], key=lambda i: centers[i][1])[:4]

    anchors = np.array(top + bottom, dtype=np.int64)
    return anchors


def _row_x_distance_threshold(centers: np.ndarray, row: list[int]) -> float:
    if len(row) <= 1:
        return 0.22
    xs = sorted(float(centers[i][0]) for i in row)
    gaps = [abs(xs[i + 1] - xs[i]) for i in range(len(xs) - 1)]
    if not gaps:
        return 0.22
    return max(0.18, min(0.34, float(np.median(gaps)) * 0.7))


def build_groups(stats: dict, anchors: np.ndarray):
    centers = stats["centers"]
    tri_counts = stats["tri_counts"]

    top_row = [int(a) for a in anchors[:4]]
    bottom_row = [int(a) for a in anchors[4:]]
    top_mean_y = float(np.mean([centers[i][1] for i in top_row]))
    bottom_mean_y = float(np.mean([centers[i][1] for i in bottom_row]))

    top_x_thresh = _row_x_distance_threshold(centers, top_row)
    bottom_x_thresh = _row_x_distance_threshold(centers, bottom_row)
    max_weighted_d2 = 0.030

    groups = {int(a): [int(a)] for a in anchors}
    anchor_set = set(int(a) for a in anchors)

    for idx in range(len(centers)):
        if idx in anchor_set:
            continue
        if tri_counts[idx] < 10:
            continue
        # Keep very large non-anchor chunks isolated to avoid cross-mushroom merges.
        if tri_counts[idx] > 1400:
            continue

        # Choose top/bottom row by Y first to avoid cross-row contamination.
        use_top = abs(float(centers[idx][1] - top_mean_y)) <= abs(float(centers[idx][1] - bottom_mean_y))
        row = top_row if use_top else bottom_row
        x_thresh = top_x_thresh if use_top else bottom_x_thresh

        best_anchor = None
        best_d2 = 1e9
        best_dy = 1e9
        for a in row:
            dx = float(centers[idx][0] - centers[a][0])
            dy = float(centers[idx][1] - centers[a][1])
            dz = float(centers[idx][2] - centers[a][2])
            d2 = dx * dx + (dy * 1.55) * (dy * 1.55) + (dz * 1.10) * (dz * 1.10)
            if d2 < best_d2:
                best_d2 = d2
                best_anchor = a
                best_dy = abs(dy)

        if best_anchor is None:
            continue

        dx = abs(float(centers[idx][0] - centers[best_anchor][0]))
        if dx <= x_thresh and best_d2 <= max_weighted_d2 and best_dy <= 0.22:
            groups[best_anchor].append(int(idx))

    return groups


def write_glb(output_path: Path, gltf: dict, bin_data: bytes):
    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    json_padded_len = align4(len(json_bytes))
    bin_padded_len = align4(len(bin_data))
    json_bytes += b" " * (json_padded_len - len(json_bytes))
    bin_data += b"\x00" * (bin_padded_len - len(bin_data))
    total_len = 12 + 8 + json_padded_len + 8 + bin_padded_len
    with output_path.open("wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total_len))
        f.write(struct.pack("<II", json_padded_len, 0x4E4F534A))
        f.write(json_bytes)
        f.write(struct.pack("<II", bin_padded_len, 0x004E4942))
        f.write(bin_data)


def export_group(component_indices: list[int], export_idx: int, components: list, positions, normals, texcoords, image_chunks, gltf):
    tri_blocks = []
    verts = []
    for comp_index, comp in enumerate(components):
        if comp_index not in component_indices:
            continue
        tri_blocks.append(comp["triangles"])
        verts.append(comp["vertices"])
    if not tri_blocks:
        return None

    triangles = np.concatenate(tri_blocks, axis=0)
    used_vertices = np.unique(np.concatenate(verts))
    remap = np.full(len(positions), -1, dtype=np.int64)
    remap[used_vertices] = np.arange(len(used_vertices), dtype=np.int64)
    remapped_indices = remap[triangles.reshape(-1)].reshape((-1, 3))

    new_positions = positions[used_vertices].astype(np.float32)
    new_normals = normals[used_vertices].astype(np.float32)
    new_texcoords = texcoords[used_vertices].astype(np.float32)

    max_index = int(remapped_indices.max())
    if max_index <= 65535:
        index_dtype = np.uint16
        component_type = 5123
    else:
        index_dtype = np.uint32
        component_type = 5125
    new_indices = remapped_indices.astype(index_dtype).reshape(-1)

    parts = []
    buffer_views = []
    accessors = []
    cursor = 0

    def add_blob(blob: bytes, target=None):
        nonlocal cursor
        offset = cursor
        parts.append(blob)
        cursor += len(blob)
        pad = align4(cursor) - cursor
        if pad:
            parts.append(b"\x00" * pad)
            cursor += pad
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(blob)}
        if target is not None:
            view["target"] = target
        buffer_views.append(view)
        return len(buffer_views) - 1

    idx_view = add_blob(new_indices.tobytes(), target=34963)
    pos_view = add_blob(new_positions.tobytes(), target=34962)
    uv_view = add_blob(new_texcoords.tobytes(), target=34962)
    norm_view = add_blob(new_normals.tobytes(), target=34962)

    accessors.append({
        "bufferView": idx_view,
        "componentType": component_type,
        "count": int(len(new_indices)),
        "type": "SCALAR",
        "max": [int(new_indices.max())],
        "min": [int(new_indices.min())],
    })
    accessors.append({
        "bufferView": pos_view,
        "componentType": 5126,
        "count": int(len(new_positions)),
        "type": "VEC3",
        "max": new_positions.max(axis=0).astype(float).tolist(),
        "min": new_positions.min(axis=0).astype(float).tolist(),
    })
    accessors.append({
        "bufferView": uv_view,
        "componentType": 5126,
        "count": int(len(new_texcoords)),
        "type": "VEC2",
        "max": new_texcoords.max(axis=0).astype(float).tolist(),
        "min": new_texcoords.min(axis=0).astype(float).tolist(),
    })
    accessors.append({
        "bufferView": norm_view,
        "componentType": 5126,
        "count": int(len(new_normals)),
        "type": "VEC3",
        "max": new_normals.max(axis=0).astype(float).tolist(),
        "min": new_normals.min(axis=0).astype(float).tolist(),
    })

    images = []
    for image in gltf.get("images", []):
        original_view = image["bufferView"]
        copied_view = add_blob(image_chunks[original_view])
        new_image = dict(image)
        new_image["bufferView"] = copied_view
        images.append(new_image)

    new_gltf = {
        "asset": gltf["asset"],
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "matrix": [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]}],
        "meshes": [{
            "primitives": [{
                "attributes": {"POSITION": 1, "TEXCOORD_0": 2, "NORMAL": 3},
                "indices": 0,
                "mode": 4,
                "material": 0,
            }]
        }],
        "materials": gltf.get("materials", []),
        "textures": gltf.get("textures", []),
        "samplers": gltf.get("samplers", []),
        "images": images,
        "bufferViews": buffer_views,
        "accessors": accessors,
        "buffers": [{"byteLength": cursor}],
    }

    output_path = OUTPUT_DIR / f"mushroom_{export_idx + 1:02d}.glb"
    write_glb(output_path, new_gltf, b"".join(parts))
    return output_path


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    gltf, bin_chunk = parse_glb(SOURCE)
    primitive = gltf["meshes"][0]["primitives"][0]
    positions = read_accessor(gltf, bin_chunk, primitive["attributes"]["POSITION"])
    texcoords = read_accessor(gltf, bin_chunk, primitive["attributes"]["TEXCOORD_0"])
    normals = read_accessor(gltf, bin_chunk, primitive["attributes"]["NORMAL"])
    indices = read_accessor(gltf, bin_chunk, primitive["indices"]).astype(np.int64).reshape((-1, 3))
    components = connected_components(indices, len(positions))

    if len(components) < CLUSTER_COUNT:
        raise ValueError(f"Only {len(components)} mesh islands found; cannot split into {CLUSTER_COUNT} mushrooms")

    stats = build_component_stats(components, positions)
    anchors = choose_row_aware_anchors(stats, CLUSTER_COUNT)
    groups = build_groups(stats, anchors)

    # Explicit 2x4 order: top row left->right, then bottom row left->right.
    top = sorted([int(a) for a in anchors[:4]], key=lambda i: stats["centers"][i][0])
    bottom = sorted([int(a) for a in anchors[4:]], key=lambda i: stats["centers"][i][0])
    ordered_anchors = top + bottom

    image_chunks = {}
    for image in gltf.get("images", []):
        view_index = image["bufferView"]
        view = gltf["bufferViews"][view_index]
        start = view.get("byteOffset", 0)
        end = start + view["byteLength"]
        image_chunks[view_index] = bin_chunk[start:end]

    manifest = []
    for export_idx, anchor_idx in enumerate(ordered_anchors):
        part_indices = groups.get(anchor_idx, [anchor_idx])
        path = export_group(part_indices, export_idx, components, positions, normals, texcoords, image_chunks, gltf)
        tri_count = int(sum(len(components[i]["triangles"]) for i in part_indices))
        center = stats["centers"][anchor_idx]
        manifest.append({
            "file": path.name if path else None,
            "anchor_component": int(anchor_idx),
            "parts": len(part_indices),
            "center_xy": [round(float(center[0]), 4), round(float(center[1]), 4)],
            "triangles": tri_count,
        })

    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
