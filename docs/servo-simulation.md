# 先验证模拟器，不连接实机

使用 Python **3.12**。本轮发现 macOS 自带 Python 3.9 无法解析上游 feetech.py 中的 f-string；不要用默认 python3 版本猜测兼容性。

在独立虚拟环境中安装 `tools/servo-web/requirements.txt` 和 `requirements-test.txt`，进入 `tools/servo-web/` 后执行：

```bash
python selftest.py
python -m pytest -q
```

上述测试使用上游模拟器，不需要接舵机。需要查看模拟页面时，可使用 `python server.py --fake`；不要选择真实串口。首次实机使用前必须核对方向、零位、限位、供电及紧急停止方式。

模拟通过只说明覆盖到的软件行为，不证明真实舵机、电源或机械结构安全。
