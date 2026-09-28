# 本次发布验证

2026-09-28，macOS ARM64；不连接硬件。

## 已核对

- 两个飞特 v2.1 CAD 附件的 SHA-256、大小与 GitHub 上游元数据一致，ZIP CRC 全部通过。
- 全套含 17 个 SolidWorks 装配体、43 个零件；独立 STEP 包含 10 个改动件。
- M6 参数与 LuwuDynamics 原文件 SHA-256 一致。
- 发布文档的本地 Markdown 目标路径检查通过；CAD/来源页面的 10 个主要外部来源链接返回 HTTP 200。
- 基本凭据模式、本机私人路径和单文件大小检查通过。这不是全面的安全审计。
- 采用筛选导入，不包含社群二维码、社交推广图片或本地聊天记录。作者姓名、版权、技术链接和许可证保留；署名原文中的社交账号标识已移除。

## 舵机工具测试

使用 Python 3.12.12、pytest 8.4.2、starlette 0.49.3、uvicorn 0.39.0、pyserial 3.5、httpx 0.28.1。

- `python selftest.py`：退出码 0，模拟器自检全部通过。
- `python -m pytest -q test_sim.py test_servo_report.py test_imu_bus.py`：**33 passed**。
- `python -m pytest -q`：**97 passed, 6 failed**，另有 1 条 Starlette/AnyIO 弃用警告。

完整测试的 6 项失败：`JLinkConnectionGuardTests` 的 5 项测试在 macOS 上模拟 Windows 时触发 `WindowsPath` 不可实例化；另 1 项 `ConfigTests.test_config_paths_relative_to_config_and_resume_is_opt_in` 因 macOS `/var` 与 `/private/var` 路径表示不同而断言失败。此处记录失败，不将它们隐藏或改成跳过，也不据此宣称 Windows J-Link 路径已通过验证。

首次尝试 Python 3.9 时发生语法错误；切到 3.12 后语法检查及上述模拟测试可执行，因此当前推荐 3.12，不声称兼容 macOS 系统自带 Python。

## 未验证

没有运行真实舵机、烧录固件、编译固件、重建 SolidWorks 装配体、执行 CUDA 训练、导出新策略或进行实机步态测试。网页端 Three.js 仍依赖上游 CDN，离线运行未验证。发布版本为基线整合，不是稳定整机版本。
