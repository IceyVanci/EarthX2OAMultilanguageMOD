# EarthX2OAMultilanguageMOD（多语言本地化补丁）

[中文版](README_CN.md) | **English [README.md](README.md)**

为 **EarthX 2（Open Alpha）** 制作的社区多语言本地化补丁集合。本仓库按语言分目录发布，
每个语言目录内是**补丁文件树本体**（与游戏根目录同构）。**不含、不修改任何游戏本体文件。**

## 声明

本 mod 未经完整人工审校，在 AI 协作下完成。部分语言的翻译完全基于 CHS 翻译流程由 AI 自主完成，
可能存在翻译错误或在不同地区不被认可的内容。我们尊重不同地区的文化与表述传统；但由于翻译流程
由 AI 完成且未经完整人工审校，如果出现具有争议或冒犯性的内容，**本项目不对此负责**。

This mod was produced with AI collaboration and has **not undergone full human review**.
Some language versions are translated autonomously by AI based on the CHS translation
workflow, and may contain translation errors or content that is not accepted in certain
regions. We respect the cultural norms and expression conventions of different regions;
however, since the translation process is AI-completed and not fully human-reviewed,
**this project assumes no responsibility for any controversial or offensive content** that may appear.

## 翻译覆盖范围 / Translation Coverage

本 mod **未实现 100% 完全翻译**，只对基础内容与大部分文本进行了翻译；少量动态拼接、罕见场景或
新版本新增内容可能仍为原文。

This mod is **not 100% translated**. Basic content and most of the in-game text are covered;
some strings (dynamic concatenation, rarely-seen scenes, newly added content, etc.) may
remain in the original language.

## 语言指南 / Language Guides

| 语言 | 补丁目录 | 使用说明 |
|---|---|---|
| 简体中文 (CHS) | [`CHS/EarthX 2 Open Alpha/`](CHS/EarthX%202%20Open%20Alpha/) | [`docs/CHS-NOTES.md`](docs/CHS-NOTES.md) |
| 日本語 (JPN) | [`JPN/EarthX 2 Open Alpha/`](JPN/EarthX%202%20Open%20Alpha/) | [`docs/JPN-NOTES.md`](docs/JPN-NOTES.md) |
| Deutsch (DEU) | [`DEU/EarthX 2 Open Alpha/`](DEU/EarthX%202%20Open%20Alpha/) | [`docs/DEU-NOTES.md`](docs/DEU-NOTES.md) |
| Español (ESP) | [`ESP/EarthX 2 Open Alpha/`](ESP/EarthX%202%20Open%20Alpha/) | [`docs/ESP-NOTES.md`](docs/ESP-NOTES.md) |
| 한국어 (KOR) | [`KOR/EarthX 2 Open Alpha/`](KOR/EarthX%202%20Open%20Alpha/) | [`docs/KOR-NOTES.md`](docs/KOR-NOTES.md) |
| Français (FRA) | [`FRA/EarthX 2 Open Alpha/`](FRA/EarthX%202%20Open%20Alpha/) | [`docs/FRA-NOTES.md`](docs/FRA-NOTES.md) |
| Português (POR) | [`POR/EarthX 2 Open Alpha/`](POR/EarthX%202%20Open%20Alpha/) | [`docs/POR-NOTES.md`](docs/POR-NOTES.md) |

> **FRA / POR：** 进行中——补丁树与说明文档已在仓库内，正式发布 zip 尚未发布。

## 制作方式与语言请求

我全流程制作了 **CHS** 的 mod，并在确立流程后使用 Coding AI Agent 完成了**德语**、**日语**、
**西班牙语**、**韩语**、**法语**和**葡萄牙语**的翻译作为示范。未来我可能还会制作并发布其他语言的 mod。

如果你想要其他语言：
- 欢迎在 **issue** 中留言，或
- 下载源代码自行制作——项目中已包含必要信息。请以 **CHS** 的 mod 为基底制作，因为针对 AI 的
  自动化描述是基于 CHS 版本编写的。

请阅读 [**AI-PATCH-GUIDE.md**](AI-PATCH-GUIDE.md) —— 面向 AI 编程助手（也面向人类）的完整方法指南，
含架构、规则契约、安全红线、工具链工作流与验收清单。

## 安装

1. 从本仓库的 [`release/`](release/) 目录下载对应语言的 zip：
   `<LANG>-EarthX2OA<LANG>MOD_v<版本>_full.zip`（推荐，解压即用）
   或 `<LANG>-EarthX2OA<LANG>MOD_v<版本>.zip`（纯补丁，需先装 BepInEx）。
   将 `<LANG>` 替换为目标语言代码（如 `CHS` → `CHS-EarthX2OAChineseMOD_v1.0.0_full.zip`）。
2. 将该语言 `EarthX 2 Open Alpha` 目录内的全部内容解压/复制到游戏根目录（`EarthX.exe` 所在目录），
   合并覆盖。
3. 启动游戏。

升级一律手动覆盖。卸载 / 验证 / FAQ 见上表中对应语言的指南。

> **兼容性提醒**：不同语言的 mod 之间存在兼容性问题，切换语言前请确保已经**清除了旧的 mod**
> 或进行了**完整切换**（只干净地重装一种语言）。

## 关于本项目

- **三层补丁**：官方 JSON 本地化层（`StreamingAssets\Localization\<Lang>\`）+ IL 字符串改写
  （`StringPatch`，Harmony transpiler）+ 烘焙 TextMeshPro 文本（`TextSweep`）。
- **内嵌字体**：CJK 语言插件 `fonts\` 内嵌各自 OFL 许可字体（CHS = 思源黑体 CN、JPN = 思源黑体 JP、
  KOR = 思源黑体 K，均 SIL OFL 1.1）——无系统字体依赖、无专有 CJK 字体版权问题。例外：**DEU、ESP、
  FRA 与 POR 不随包分发字体**，复用游戏内嵌 LiberationSans（已完整覆盖 ä/ö/ü/ß 德语字形、
  á/é/í/ó/ú/ñ/ü 西语字形、é/è/ê/à/ç/ô/û/œ 法语字形与 á/ã/é/ê/í/ó/ô/õ/ú/ç 葡语字形）。

## 声明与许可

- 补丁内容（JSON / TSV / 插件源码）按"现状"提供给 EarthX 2 玩家社区自由使用。
- **内嵌字体为思源黑体（CN / JP / K，SIL OFL 1.1）**，可自由随补丁再分发，许可全文见
  `licenses\SourceHanSansCN-LICENSE.txt` 与 `licenses\SourceHanSansK-LICENSE.txt`
  （各 CJK 语言 `fonts\` 内亦随附）。
- **完整包**内附带的第三方二进制均为**未经修改**的官方发行文件：
  - BepInEx 5.4.23.2 —— LGPL-2.1 —— https://github.com/BepInEx/BepInEx
  - UnityDoorstop 4.x（`winhttp.dll`）—— LGPL-2.1 —— https://github.com/NeighTools/UnityDoorstop
  - HarmonyX / MonoMod / Mono.Cecil —— MIT（随 BepInEx core 分发）
  - 许可全文与来源声明见 `licenses\` 目录。
- 本项目与游戏的开发商或发行商**无任何关联**。

## 贡献

欢迎 issue / PR。要新增或改进一种语言，请先阅读
[**AI-PATCH-GUIDE.md**](AI-PATCH-GUIDE.md)。

## 致谢

本项目使用 **Opencode** 搭配 **DeepseekV4Flash** 与 **GLM5.2** 进行协助开发。

This project was developed with the assistance of **Opencode** combined with
**DeepseekV4Flash** and **GLM5.2**.
