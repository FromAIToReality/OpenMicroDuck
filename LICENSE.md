# 许可边界

这是混合来源仓库，不能将全部内容视为统一的 Apache 或 MIT 项目。

补充技术资料沿用上游根 LICENSE 的边界：根目录参考记录、`docs/` 中上游文档、`assembly-drawings/`、`assets/` 中上游技术图片、`build-log/` 照片按 CC BY-NC-SA 4.0；`scripts/`、`tools/` 原作者工具代码按 Apache-2.0（如子目录另有声明则按其声明）。上游实物照片归其参与者，不是 FromAIToReality 拍摄。厂商资料的原有来源说明保留，不对第三方内容扩大授权。

- `software/training/`：代码、参数和相应文档遵循其 [Apache-2.0](software/training/LICENSE)；其中 Microduck 模型及网格保留上游 CC BY-NC-SA 4.0 条件，见 [UPSTREAM](software/training/UPSTREAM.md)。
- `tools/servo-web/`：代码沿用 fanhao375 的 Apache-2.0 说明；该工具文档沿用其 CC BY-NC-SA 4.0；派生机器人模型不因与软件放在一起而变成 Apache 许可。
- `hardware/imu_to_dxl/firmware/`：固件根目录 [MIT 许可证](hardware/imu_to_dxl/firmware/LICENSE)及 Drivers 等子目录第三方许可证各自适用。
- `cad/print/` 与飞特 CAD Release：机械行者Robo的图纸，基于 Pollen Robotics Microduck 模型的衍生作品；依据发布仓库声明采用 **CC BY-NC-SA 4.0（署名、非商业、相同方式共享）**。署名机械行者Robo，保留 fanhao375 与 Pollen Robotics 来源。
- FromAIToReality 新增的 README、来源和整理说明采用 CC BY-NC-SA 4.0；不改变任何上游内容的许可。

全文参考：[Apache-2.0](licenses/LICENSE-APACHE-2.0.txt)、[CC BY-NC-SA 4.0](licenses/LICENSE-CC-BY-NC-SA-4.0.txt)。没有把许可证不明确的独立 PCB 设计文件作为可直接生产的工程导入。
