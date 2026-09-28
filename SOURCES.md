# 来源与署名

## 实际导入

| 内容 | 作者／仓库 | 固定版本 |
|---|---|---|
| HD1910 训练基线、servo-web、IMU 固件及各自第三方组件 | [fanhao375/microduck-replica](https://github.com/fanhao375/microduck-replica) 与原文件中署名的贡献者 | `a23f4c18a4741a3cde5257e639960ea37bbadd8d` |
| 1910 BAM M6 参数（通过以上训练目录导入） | [LuwuDynamics/xgoduck_rl](https://github.com/LuwuDynamics/xgoduck_rl) | `326d77a1122870bdefa2c36403937502c958e69c` |
| 飞特 CAD、3MF、装配资料 | **机械行者Robo**；[fanhao375/microduck-replica-cad](https://github.com/fanhao375/microduck-replica-cad) 维护发布 | 源码 `749fcefb404a0750777d7cc8badfe30700df2f9b`；CAD Release `v2.1` |
| 原始 Microduck 训练生态、模型及运行时接口来源 | [Pollen Robotics](https://github.com/pollen-robotics/microduck_rl) | 详细导入版本见 [训练 UPSTREAM](software/training/UPSTREAM.md) |
| 执行器模型依赖 | [Rhoban/BAM](https://github.com/Rhoban/bam) | 训练锁文件与 UPSTREAM 指定版本 |

逐文件来源、导入前后 SHA-256 见 [导入清单](provenance/import-manifest.json)。来自上游的代码没有被重新命名成我们的原创算法；此次主要工作是筛选、去重、组织资料、连接下载和标注验证边界。

2026-09-28 补充导入同一固定版本的技术参考文档、装配/接线图片与辅助工具；来源、原始及发布哈希见 [补充清单](provenance/reference-import-manifest.json)。正文仍为上游作者记录，新增提示区分本项目和上游验证范围。未导入的独立 PCB 设计文件及大型系统镜像保留上游下载入口。

## 参考但未导入

[JoyandAI/OpenMicroDuck](https://github.com/JoyandAI/OpenMicroDuck/tree/eb0eabb98b591fa9f9176b013cc0a67ca30ae847) 用作架构、BOM 和结构参考。其 README 与 LICENSE 对图纸许可的表述存在差异，本次不导入该项目图纸；标准 Apache/CC 许可证全文副本不是导入其设计。

上游原有版权说明和内嵌第三方许可证保持保留；[fanhao375 原始许可与署名记录](licenses/microduck-replica/)作为历史来源原文保存，其中路径描述和未导入的素材清单属于原仓库，并不表示这些素材在本仓库中。
