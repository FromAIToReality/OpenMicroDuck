# -*- coding: utf-8 -*-
"""读一遍总线上所有舵机的当前姿态，打一张表。不写任何寄存器。

  python readpose.py --port COM5
  python readpose.py --port /dev/ttyUSB0 --ids 20-24,30-34,10-14
"""
import argparse
import json
import time

import feetech
from server import DEFAULT_IDS, JOINT_NAMES, parse_ids

STEP_DEG = 360 / 4096


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", required=True)
    ap.add_argument("--baud", type=int, default=1_000_000)
    ap.add_argument("--ids", default=DEFAULT_IDS)
    ap.add_argument("--json", help="把结果另存成 JSON")
    a = ap.parse_args()
    bus = feetech.FeetechBus(a.port, a.baud)
    ids = parse_ids(a.ids)
    present = [i for i in ids if bus.ping(i) is not None]
    print(f"串口 {a.port} @ {a.baud}，在线 {len(present)}/{len(ids)}：{present}")
    missing = [i for i in ids if i not in present]
    if missing:
        print(f"没应答：{missing}")
    if not present:
        return
    st = bus.states(present)
    print(f"\n{'ID':>3} {'关节':<16} {'位置':>5} {'偏离2048':>8} {'角度°':>7} {'电压':>5} {'温度':>4} {'负载%':>6} {'电流mA':>7} {'扭矩':>4} 状态")
    rows = []
    for i in present:
        s = st[i]
        if not s:
            print(f"{i:>3} {JOINT_NAMES.get(i, ''):<16} 读失败")
            continue
        try:
            torque = bus.read_u8(i, 40)
        except feetech.BusError:
            torque = -1
        d = s["pos"] - 2048
        print(f"{i:>3} {JOINT_NAMES.get(i, ''):<16} {s['pos']:>5} {d:>+8} {d * STEP_DEG:>+7.1f} {s['volt']:>5.1f} {s['temp']:>4} "
              f"{s['load'] / 10:>6.1f} {s['current_ma']:>7.0f} {torque:>4} {s['status_text'] or ('0x%02X' % s['status'] if s['status'] else 'ok')}")
        rows.append({"id": i, "joint": JOINT_NAMES.get(i), "pos": s["pos"], "deg_from_2048": round(d * STEP_DEG, 1),
                     "volt": s["volt"], "temp": s["temp"], "torque": torque, "status": s["status"]})
    print(f"\n收发统计：{bus.stats}")
    if a.json:
        with open(a.json, "w", encoding="utf-8") as f:
            json.dump({"time": time.strftime("%Y-%m-%d %H:%M:%S"), "port": a.port, "rows": rows}, f, ensure_ascii=False, indent=1)
        print("已存", a.json)
    bus.close()


if __name__ == "__main__":
    main()
