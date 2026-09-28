# -*- coding: utf-8 -*-
"""把 microduck_rl 的 MuJoCo 模型（robot_allcollisions.xml + assets/*.stl）转成网页用的紧凑格式。

  python build_model.py --src <microduck_rl>/src/mjlab_microduck/robot/microduck

输出 model/model.json（运动学树、几何体、颜色、顶点在 bin 里的偏移）和 model/meshes.bin
（每个网格：int16 量化的顶点 xyz + uint16/uint32 三角形索引）。只依赖 numpy。

来源：https://github.com/apirrone/microduck_rl（Apache-2.0）。里面的网格是 Pollen 官方 CAD 导出的。
"""
import argparse
import json
import os
import struct
import xml.etree.ElementTree as ET

import numpy as np

JOINT_IDS = {
    "left_hip_yaw": 20, "left_hip_roll": 21, "left_hip_pitch": 22, "left_knee": 23, "left_ankle": 24,
    "neck_pitch": 30, "head_pitch": 31, "head_yaw": 32, "head_roll": 33, "mouth": 34,
    "right_hip_yaw": 10, "right_hip_roll": 11, "right_hip_pitch": 12, "right_knee": 13, "right_ankle": 14,
}
# 壳子里看不见的东西，不进网页
SKIP_DEFAULT = "pcb__raspberry_pi_zero_2_w,elec_rpi_robot_hat_pcb,seeed_bearing__configuration__22x16x4,seeed_bearing__configuration_default,speaker,m12_lens_holder,banana_pcb_locker,upper_leg_rigidity_plate,motor_support,power_support"


def load_stl(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        tris = []
        for line in data.decode("ascii", "ignore").splitlines():
            line = line.strip()
            if line.startswith("vertex"):
                tris.append([float(x) for x in line.split()[1:4]])
        v = np.array(tris, dtype=np.float32).reshape(-1, 3)
    else:
        n = struct.unpack("<I", data[80:84])[0]
        rec = np.frombuffer(data[84:84 + 50 * n], dtype=np.dtype([("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")]))
        v = rec["v"].reshape(-1, 3).astype(np.float32)
    # 合并重复顶点
    uniq, inv = np.unique(v, axis=0, return_inverse=True)
    idx = inv.reshape(-1, 3).astype(np.uint32)
    return uniq, idx


def floats(s, default):
    return [float(x) for x in s.split()] if s else list(default)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="microduck_rl 的 robot/microduck 目录")
    ap.add_argument("--xml", default="robot_allcollisions.xml")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "model"))
    ap.add_argument("--skip", default=SKIP_DEFAULT)
    ap.add_argument("--mouth-pivot", default="0.003 0 -0.018", help="嘴铰链在头壳体系里的位置（米），估的")
    ap.add_argument("--official", default="F:/chengshenzhilu/Robot/Microduck/microduck/kinematics/assets/alpha/robot_walk.xml",
                    help="官方 robot_walk.xml，取每个 body 的质量和质心算重心；没有就不算")
    a = ap.parse_args()
    skip = set(x for x in a.skip.split(",") if x)
    root = ET.parse(os.path.join(a.src, a.xml)).getroot()
    meshdir = root.find("compiler").get("meshdir", "assets")
    mesh_files = {}
    for m in root.iter("mesh"):
        name = m.get("name") or os.path.splitext(os.path.basename(m.get("file")))[0]
        mesh_files[name] = (os.path.join(a.src, meshdir, m.get("file")), floats(m.get("scale"), (1, 1, 1)))
    materials = {m.get("name"): floats(m.get("rgba"), (0.8, 0.8, 0.8, 1)) for m in root.iter("material")}

    bodies, used = [], {}

    def walk(el, parent):
        idx = len(bodies)
        b = {"name": el.get("name"), "parent": parent, "pos": floats(el.get("pos"), (0, 0, 0)),
             "quat": floats(el.get("quat"), (1, 0, 0, 0)), "joint": None, "geoms": []}
        j = el.find("joint")
        if j is not None and j.get("type", "hinge") == "hinge":
            b["joint"] = {"name": j.get("name"), "axis": floats(j.get("axis"), (0, 0, 1)),
                          "range": floats(j.get("range"), (-3.14, 3.14)), "id": JOINT_IDS.get(j.get("name"))}
        for g in el.findall("geom"):
            if g.get("type") != "mesh" or g.get("class") == "collision":
                continue
            m = g.get("mesh")
            if m in skip or m not in mesh_files:
                continue
            used[m] = True
            b["geoms"].append({"mesh": m, "pos": floats(g.get("pos"), (0, 0, 0)), "quat": floats(g.get("quat"), (1, 0, 0, 0)),
                               "rgba": materials.get(g.get("material"), [0.8, 0.8, 0.8, 1])})
        bodies.append(b)
        for c in el.findall("body"):
            walk(c, idx)

    for top in root.find("worldbody").findall("body"):
        walk(top, -1)

    # 嘴：MJCF 里没有这个关节，下颌焊在头壳上。把 jaw / jaw_soft 两块几何拆出来挂到一个补的铰链上，
    # 轴 = 头壳系的 y（左右），铰点取嘴舵机（xl330 几何）的原点，正角度 = 张嘴。位置是估的，只为显示。
    notes = []
    pivot = [float(x) for x in a.mouth_pivot.split()]
    for b in bodies:
        jaw_geoms = [g for g in b["geoms"] if g["mesh"] in ("jaw", "jaw_soft")]
        if not jaw_geoms:
            continue
        b["geoms"] = [g for g in b["geoms"] if g not in jaw_geoms]
        for g in jaw_geoms:
            g["pos"] = [g["pos"][k] - pivot[k] for k in range(3)]
        bodies.append({"name": "jaw_hinge", "parent": bodies.index(b), "pos": pivot, "quat": [1, 0, 0, 0],
                       "joint": {"name": "mouth", "axis": [0, 1, 0], "range": [-0.0873, 0.5236], "id": JOINT_IDS["mouth"], "synthetic": True},
                       "geoms": jaw_geoms})
        notes.append("嘴 34 的铰链是补的（原模型没有），位置估的，只为显示")
        break

    # 质量和质心：从官方 robot_walk.xml 的 inertial 取，按关节名对应（两份模型 body 名字不一样）
    if a.official and os.path.exists(a.official):
        off = ET.parse(a.official).getroot()
        by_joint = {}
        def walk_off(el):
            inert = el.find("inertial"); j = el.find("joint")
            m = (float(inert.get("mass")), floats(inert.get("pos"), (0, 0, 0))) if inert is not None else (0.0, [0, 0, 0])
            if j is not None: by_joint[j.get("name")] = m
            elif el.find("freejoint") is not None: by_joint["__trunk__"] = m
            for c in el.findall("body"): walk_off(c)
        for top in off.find("worldbody").findall("body"): walk_off(top)
        for b in bodies:
            key = b["joint"]["name"] if b["joint"] else "__trunk__"
            mass, com = by_joint.get(key, (0.0, [0, 0, 0]))
            if b["joint"] and b["joint"].get("synthetic"): mass, com = 0.0, [0, 0, 0]
            b["mass"], b["com"] = mass, com
        total = sum(b["mass"] for b in bodies)
        notes.append(f"质量 {total*1000:.0f} g 来自官方 robot_walk.xml，重心按它算")
        print(f"质量：{total*1000:.0f} g，{sum(1 for b in bodies if b['mass'])} 个 body 有质量")
    # 脚底支撑区：sole 网格在踝体系里的包围盒，页面投影到地面画矩形
    for b in bodies:
        for g in b["geoms"]:
            if g["mesh"] in ("sole_left", "sole_right"):
                b["sole"] = {"mesh": g["mesh"], "pos": g["pos"], "quat": g["quat"]}

    os.makedirs(a.out, exist_ok=True)
    meshes, blob = {}, bytearray()
    for name in sorted(used):
        path, scale = mesh_files[name]
        v, idx = load_stl(path)
        v = v * np.array(scale, dtype=np.float32)
        lo, hi = v.min(0), v.max(0)
        span = np.where(hi - lo > 0, hi - lo, 1).astype(np.float32)
        q = np.round((v - lo) / span * 65535 - 32768).clip(-32768, 32767).astype("<i2")
        ib = 2 if len(v) < 65536 else 4
        ind = idx.astype("<u2" if ib == 2 else "<u4")
        while len(blob) % 4:
            blob += b"\0"
        off = len(blob)
        blob += q.tobytes()
        while len(blob) % 4:
            blob += b"\0"
        ioff = len(blob)
        blob += ind.tobytes()
        meshes[name] = {"voff": off, "nverts": int(len(v)), "ioff": ioff, "ntris": int(len(idx)), "index_bytes": ib,
                        "bbox_min": lo.tolist(), "bbox_max": hi.tolist()}
        print(f"{name:45s} {len(v):7d} v {len(idx):7d} tri")
    model = {"source": "apirrone/microduck_rl " + a.xml, "license": "Apache-2.0", "up": "z", "notes": notes,
             "bodies": bodies, "meshes": meshes, "joint_ids": JOINT_IDS}
    with open(os.path.join(a.out, "model.json"), "w", encoding="utf-8") as f:
        json.dump(model, f, ensure_ascii=False, separators=(",", ":"))
    with open(os.path.join(a.out, "meshes.bin"), "wb") as f:
        f.write(blob)
    joints = [b["joint"]["name"] for b in bodies if b["joint"]]
    print(f"\n{len(bodies)} bodies, {len(joints)} joints, {len(meshes)} meshes, meshes.bin {len(blob) / 1e6:.2f} MB")
    print("joints:", joints)
    missing = [n for n in JOINT_IDS if n not in joints]
    if missing:
        print("模型里没有的关节（网页上不动）:", missing)


if __name__ == "__main__":
    main()
