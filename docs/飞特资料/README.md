> **上游技术参考，不是本项目实测结论。** 来源：[fanhao375/microduck-replica](https://github.com/fanhao375/microduck-replica/blob/a23f4c18a4741a3cde5257e639960ea37bbadd8d/docs/%E9%A3%9E%E7%89%B9%E8%B5%84%E6%96%99/README.md)。保留原作者及贡献者署名；正文中的“本项目”、实物、照片和测试记录属于上游。与我们的硬件不一致时，以[本项目说明](../hardware.md)为准。

# 飞特舵机官方资料 · 副本

飞特官网文档站 [doc.feetech.cn](http://doc.feetech.cn/#/prodinfodownload?srcType=FTServo-emanual-ab4947a479784a71a8cb7928) 上的《飞特舵机电子使用手册》，2026-09-17 拉下来的副本。文档站是前端应用，网页不好存、也不好检索，所以把正文原样放进仓库，方便对着 [`software/飞特适配架构.md`](../../software/飞特适配架构.md) 核对。**以官网为准，这里只是当天的快照。**

| 文件 | 版本 | 官网更新日期 | 用途 |
|---|---|---|---|
| [`SCS通信协议-v1.0-2026-06-09.md`](SCS通信协议-v1.0-2026-06-09.md) | v1.0 | 2026-06-09 | 包格式、指令表。**这版有重启指令 0x08、参数备份 0x09、状态重置 0x0A**，2019 版没有 |
| [`磁编码STS内存表手册-v1.1-2026-08-27.md`](磁编码STS内存表手册-v1.1-2026-08-27.md) | v1.1 | 2026-08-27 | HD-1910 所属的 STS 系列内存表：EEPROM / SRAM 分区、出厂值、锁标志语义、状态位定义 |
| [`磁编码SMS内存表手册-v1.1-2026-08-27.md`](磁编码SMS内存表手册-v1.1-2026-08-27.md) | v1.1 | 2026-08-27 | 同上，SMS（RS485）版。跟 STS 的差别：7 是应答返回延时（STS 是预留）、33 运行模式范围 0~2、40 扭矩开关没有阻尼值 2、83 是 Hts、相位 BIT5 含义不同 |
| `磁编码SMS&STS&HTS-十六进制指令生成表-250508.xlsx` | 250508 | 2025-05-08 | 官方 Excel，填参数自动生成十六进制指令帧，串口助手直接发；有解锁 / 改 ID / 清圈数 / 中位校准的现成例子 |

HD-1910-C001 是定制型号，官网没有单独的内存表；差异（出厂模式 4、扭矩、减速比）见 [HD-1910 训练前数据清单](../HD-1910训练前数据清单.md)，实机导出的寄存器底账做完也放这个目录。

其它入口（都在官网电子使用手册索引里）：调试软件 FD [gitee.com/ftservo/fddebug](https://gitee.com/ftservo/fddebug)、Linux SDK [gitee.com/ftservo/FTServo_Linux](https://gitee.com/ftservo/FTServo_Linux)、Python SDK [gitee.com/ftservo/FTServo_Python](https://gitee.com/ftservo/FTServo_Python)。

怎么拉的（文档站的接口，下次更新用）：

```text
索引  http://longbos.com:9009/workflow/yf-specification/getBysrcType/FTServo-emanual-ab4947a479784a71a8cb7928
正文  http://longbos.com:9009/workflow/yf-specification/getQr/<q>     q 取索引正文里 #/f?q=… 的值
       STS 内存表 2506abfb1cb0 · SMS 内存表 2602a06ca658 · SCS 协议 2506ba160b93
返回 JSON，data.mdcontent 是 Markdown 正文，data.lastModifiedDate 是更新时间
```
