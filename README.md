# OpenMicroDuck · FromAIToReality

面向 **Radxa ZERO 3W + 飞特 HD1910** 的机器鸭复刻与适配记录。我们整理社区已有成果，逐步验证硬件、装配、舵机控制和强化学习训练。

**当前版本是资料与代码基线整合，不是已经验证会走路的整机方案。** 不提供即插即用步态；不要直接将示例姿态、零位或策略用于真实机器人。

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
- 发布目录不加入社群二维码、关注账号推广和私人聊天资料。署名、版权声明与技术来源仍保留。
- 对未随本仓库导入的资料，文档链接指向固定上游版本；实际导入和链接调整见 [provenance](provenance/)。

## 已知限制

- 我们尚未完成实机零位、方向、限位、IMU、主控时序及整机步态验证。
- 训练基线需要适合该软件栈的 CUDA 环境；不是在 Mac 或 ZERO 3W 上直接完成大规模训练。
- 附带的上游 3MF 是 PLA 预设，**不是我们 PA6-CF/TPU 的已验证打印参数**。
- `servo-web` 内的方向和姿态是上游示例，不是我们的实机校准值。它可以写 EEPROM 和开扭矩，使用前务必审查。
- 上游文档中的“已测试”“本项目”等描述属于原作者记录，不等于 FromAIToReality 已完成同样测试。

本项目与 Pollen Robotics、fanhao375、LuwuDynamics、JoyandAI 无隶属关系。感谢作者及贡献者；具体署名与许可见 [SOURCES.md](SOURCES.md) 和 [LICENSE.md](LICENSE.md)。
