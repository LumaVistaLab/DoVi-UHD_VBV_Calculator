# Dolby Vision UHD Blu-ray VBV Parameters Calculator

面向 UHD Blu-ray / Dolby Vision Profile 7 工作流的 VBV 参数计算与工程规则整理仓库。项目核心是一个 Windows 批处理计算器，用于根据 `VBV_safeRate` 和增强层类型（MEL / FEL）生成 BL/EL 的 `max_vbv_data_rate` 与 `vbv_buffer_size` 分配参数；同时提供完整工程指南、实验日志和原始参考文献，便于复核参数来源。

## 项目结构

```text
.
├── calculator/
│   ├── CalcRates_v3.1.bat
│   ├── CalcLogs_v3.1.txt
│   └── RateRules_v3.0.txt
├── final_guide/
│   ├── UHD_BluRay_Encoding_Parameter_Optimization_Guide.html
│   └── UHD_BluRay_Encoding_Parameter_Optimization_Guide.pdf
├── references/
│   ├── BD-ROM_Part3_V3.1_WhitePaper_160729.pdf
│   └── Dolby_Vision_UHD_BluRay_Authoring_Workflow.pdf
├── LICENSE
└── README.md
```

## 适用场景

- 为 Dolby Vision Profile 7 MEL / FEL 双层编码拆分 BL 与 EL 的 VBV 参数。
- 在 Scenarist UHD MUX 前，先用统一的 `VBV_safeRate` 模型估算视频安全预算。
- 对比 100GB 单碟、66GB two-zoned disc 等 UHD Blu-ray 方案中的 M2TS 传输约束。
- 复用已验证的 96 Mbps video-safe profile 作为生产或压力测试参数模板。

## 目录说明

| 路径 | 说明 |
| --- | --- |
| `calculator/` | 计算器、速率规则和示例运行日志。日常使用主要进入这个目录。 |
| `final_guide/` | 最终版 UHD Blu-ray 编码参数优化指南，提供 HTML 与 PDF 两种格式。 |
| `references/` | 参数推导引用的公开规范与 Dolby Vision 工作流资料。 |
| `LICENSE` | 项目许可证。 |

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `calculator/CalcRates_v3.1.bat` | 交互式 Windows 批处理计算器。输入整数 Mbps 的 `VBV_safeRate`，再选择 `MEL` 或 `FEL`，输出 BL/EL 分层参数。 |
| `calculator/RateRules_v3.0.txt` | 速率、容量、VBV 模型与 BL/EL 分配约束的文本规则。 |
| `calculator/CalcLogs_v3.1.txt` | 计算器示例运行日志，包含 96 Mbps 和超高输入自动回退案例。 |
| `final_guide/UHD_BluRay_Encoding_Parameter_Optimization_Guide.html` | 完整工程指南，包含理论约束、音频预算、MEL/FEL 案例、生产规则和 QC 清单。 |
| `final_guide/UHD_BluRay_Encoding_Parameter_Optimization_Guide.pdf` | 上述 HTML 指南的 PDF 版本。 |
| `references/BD-ROM_Part3_V3.1_WhitePaper_160729.pdf` | Blu-ray Disc Read-Only Format / Ultra HD Blu-ray 白皮书参考资料。 |
| `references/Dolby_Vision_UHD_BluRay_Authoring_Workflow.pdf` | Dolby Vision UHD Blu-ray Authoring Workflow 参考资料。 |

## 快速开始

### 运行环境

- Windows 10 / 11
- `cmd.exe` 或 Windows Terminal
- 不需要安装额外依赖

### 运行计算器

在仓库根目录执行：

```bat
.\calculator\CalcRates_v3.1.bat
```

也可以进入 `calculator/` 目录后执行：

```bat
cd calculator
CalcRates_v3.1.bat
```

按提示输入：

1. `VBV_safeRate`：整数 Mbps，例如 `96`。
2. 增强层类型：`MEL` 或 `FEL`。

示例输入：

```text
VBV_safeRate: 96
Type: MEL
```

示例输出：

```text
VBV_safeRate = 96 Mbps
BL_maxRate   = 85968 Kbps
BL_buffSize  = 28656 Kbps
MEL_maxRate  = 432 Kbps
MEL_buffSize = 144 Kbps
BL_MEL_ratio = 99.5%, 0.5%
```

FEL 示例：

```text
VBV_safeRate = 96 Mbps
BL_maxRate   = 82080 Kbps
BL_buffSize  = 27360 Kbps
FEL_maxRate  = 4320 Kbps
FEL_buffSize = 1440 Kbps
BL_FEL_ratio = 95%, 5%
```

如果输入的 `VBV_safeRate` 太高，脚本会自动向下回退到满足约束的最大可用值。

## 计算模型

项目把可用于视频的 M2TS 预算抽象为 `VBV_safeRate`，再转换为编码器可用的 VBV 参数：

```text
VBV_maxRate    = 0.9 * VBV_safeRate
VBV_bufferSize = 1/3 * VBV_maxRate
VBV_peakRate   = VBV_maxRate + VBV_bufferSize
```

当 `VBV_safeRate = 96 Mbps` 时：

```text
VBV_maxRate    = 86,400 Kbps
VBV_bufferSize = 28,800 Kbps
VBV_peakRate   = 115,200 Kbps
```

随后脚本根据增强层类型拆分 BL/EL：

- MEL：在 `99.5/0.5`、`99/1`、`98.5/1.5`、`98/2` 中寻找可整除且满足单层上限的最高 BL 参数。
- FEL：在 `80/20` 到 `95/5` 区间内选择满足约束的 BL/FEL 比例。
- BL、MEL、FEL 的 `maxRate` 均需不超过 `100,000 Kbps`。

## 推荐参数模板

通用 96 Mbps video-safe profile：

```text
VBV_safeRate      = 96,000 Kbps
VBV_maxRate       = 86,400 Kbps
VBV_bufferSize    = 28,800 Kbps
VBV_peakRate      = 115,200 Kbps
```

MEL production profile：

```text
BL_MEL_ratio      = 99.5 / 0.5
BL max/buffer     = 85,968 / 28,656 Kbps
MEL max/buffer    =    432 /    144 Kbps
```

FEL stress-test profile：

```text
BL_FEL_ratio      = 95 / 5
BL max/buffer     = 82,080 / 27,360 Kbps
FEL max/buffer    =  4,320 /  1,440 Kbps
```

## 工程注意事项

- 先计算 M2TS 预算，再计算视频参数：`Video_safeRate = M2TS_maxRate - Audio_maxRate - Guard`。
- 音频预算应使用最大码率或实测峰值，不建议只用平均码率。
- 每次调整音频流、字幕、章节拆分、平均码率或 BL/EL 比例后，都应重新进行 Scenarist UHD MUX 验证。
- 若出现 `buffer_underflows`，优先降低 `Video_safeRate`，再考虑降低平均 `data_rate`、减少音频峰值或调整分碟方案。
- 最终交付参数应以实际 encoded elementary streams 的 MUX 验证结果为准。

## 指南与参考资料

- 快速查看最终指南：打开 `final_guide/UHD_BluRay_Encoding_Parameter_Optimization_Guide.html`。
- 需要打印或归档时使用：`final_guide/UHD_BluRay_Encoding_Parameter_Optimization_Guide.pdf`。
- 需要复核规范来源时查看：`references/BD-ROM_Part3_V3.1_WhitePaper_160729.pdf` 与 `references/Dolby_Vision_UHD_BluRay_Authoring_Workflow.pdf`。

## 编码与显示

批处理脚本会切换到 UTF-8 代码页：

```bat
chcp 65001
```

如果在旧版 `cmd.exe` 中看到中文提示乱码，可改用 Windows Terminal，或在运行前确认终端字体与代码页支持 UTF-8。参数字段名和数值不受中文显示影响。

## License

参见 `LICENSE`。