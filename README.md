# OpenMicroDuck · FromAIToReality

面向 **Radxa ZERO 3W + 飞特 HD1910** 的机器鸭复刻与适配记录。我们整理社区已有成果，逐步验证硬件、装配、舵机控制和强化学习训练。

**当前版本是资料与代码基线整合，不是已经验证会走路的整机方案。** 不提供即插即用步态；不要直接将示例姿态、零位或策略用于真实机器人。

## 开发进展与 DIY 交流

我们正在启动飞特 **HD1910 舵机专用 HAT 扩展板**的开发，围绕 Radxa ZERO 3W 主控，规划舵机通信、供电和 IMU 接口，电池供电部分采用 **FB-NP-F550-B20 单供电板**。目前处于方案设计阶段，重点考虑好安装、好接线、方便调试，后续会逐步分享设计与测试进展。

欢迎喜欢 DIY 和机器人的朋友扫码进群，一起讨论机器鸭的 **3D 打印、耗材选择、支撑优化、零件装配、舵机调试及板卡开发**。不论刚入门还是有经验，都可以交流想法、分享踩坑记录，一起把机器鸭做出来！

<p align="center">
  <img src="assets/community/wechat-diy-2026-09-28.png" alt="机器鸭 DIY 微信交流群二维码" width="320">
</p>

二维码标注有效期至 **2026 年 10 月 5 日前**，过期后需更新。

## 从哪里开始

| 需要什么 | 入口 |
|---|---|
| 硬件现状与缺项 | [硬件清单与边界](docs/hardware.md) |
| 舵机网页调试候选工具 | [servo-web](tools/servo-web/README.md)，先看[安全与验证状态](docs/status.md) |
| 飞特训练基线 | [HD1910 训练说明](software/training/docs/hd1910-baseline.md) |
| CAD、STEP、打印工程、装配资料 | [机械文件下载](cad/README.md) |
| IMU 桥接固件参考 | [STM32G031 + LSM6DSV16X](hardware/imu_to_dxl/firmware/README.md) |
| 我们的整合取舍 | [整合说明](docs/integration.md) |
| 不接硬件的工具验证 | [Python 3.12 模拟测试](docs/servo-simulation.md) |
| 本轮实际验证结果 | [发布检查：97 通过、6 项平台相关失败](docs/release-validation.md) |
| 上游项目与许可 | [来源](SOURCES.md) · [许可边界](LICENSE.md) |

## 这次整合做了什么

- 采用 fanhao375 的 HD1910 训练基线与调试工具，保留原有安全说明及测试。
- LuwuDynamics 的 `1910_m6.json` 已包含在训练目录中，内容保持原样，不再重复引入另一套同名训练包。
- 机械 CAD 采用机械行者Robo的飞特 v2.1；大文件作为 Release 附件发布。
- 不导入上游社群二维码、关注账号推广或私人聊天资料；首页仅展示本项目提供的 DIY 交流群。署名、版权声明与技术来源仍保留。
- 对未随本仓库导入的资料，文档链接指向固定上游版本；实际导入和链接调整见 [provenance](provenance/)。

## 已知限制

- 我们尚未完成实机零位、方向、限位、IMU、主控时序及整机步态验证。
- 训练基线需要适合该软件栈的 CUDA 环境；不是在 Mac 或 ZERO 3W 上直接完成大规模训练。
- 附带的上游 3MF 是 PLA 预设，**不是我们 PA6-CF/TPU 的已验证打印参数**。
- `servo-web` 内的方向和姿态是上游示例，不是我们的实机校准值。它可以写 EEPROM 和开扭矩，使用前务必审查。
- 上游文档中的“已测试”“本项目”等描述属于原作者记录，不等于 FromAIToReality 已完成同样测试。

本项目与 Pollen Robotics、fanhao375、LuwuDynamics、JoyandAI 无隶属关系。感谢作者及贡献者；具体署名与许可见 [SOURCES.md](SOURCES.md) 和 [LICENSE.md](LICENSE.md)。
