# Changelog

All notable changes to the EarthX2OAMultilanguageMOD project.
Format: 新增 / 修复 / 数据变更 (Added / Fixed / Data).

## [打包流程 2026-09-04] 解耦多语言打包 + 增量构建

重构 `build-artifacts.ps1`：各语言打包互相解耦，修改/新增任一语言不再影响其他语言产物。

### 新增 Added

- **语言包只含本语言内容**：patch zip 从"内嵌全部根文档（README/README_CN/AI-PATCH-GUIDE +
  `docs\*`）"改为仅含本语言 JSON + 插件 + `docs\<LANG>-NOTES.md` +（字体语言）本语言字体许可。
  共享文档只存仓库根，不再进包 → 改文档/加新语言**永不改变其他语言的 zip 内容**
- **manifest 增量跳过**：每语言构建时计算 `langHash`（仓库树内容哈希）与 `frameworkHash`
  （框架+许可哈希），与 `release\_manifest_<LANG>.json` 比对；版本+两哈希一致且产物存在 →
  `SKIP`（不写 zip/sha/`latest.json`/manifest，git 零 diff）。`-Force` 强制重建
- **`-All` 批量模式**：一次构建全部已发布语言（CHS/DEU/JPN/ESP/KOR），输出 `BUILT/SKIP/FAILED`
  汇总；profile 新增 `Released` 白名单（FRA/POR 未发布，仅可 `-Lang` 单构建）
- **解耦断言**：patch staging 禁止出现根文档、非本语言 NOTES、非本语言字体许可

### 数据变更 Data

- 5 语言产物已按新契约一次性迁移重打（zip 体积变化：移除共享文档后 CHS ~14.8MB、DEU ~143KB、
  ESP ~142KB、JPN ~27.5MB、KOR ~27.5MB；full 包同步更新）
- `release\` 新增 `_manifest_<LANG>.json` ×5（随包提交）

## [KOR 1.0.0] - 2026-09-03

首个韩语（KOR）补丁版本：基于 CHS 流程 fork 出独立韩语补丁 `KOR\`，离线仓库树为唯一数据源，
随包交付 `EarthX2Korean.dll` 与 `docs\KOR-NOTES.md`。

### 新增 Added

- **韩语插件 `EarthX2Korean`**：fork 自 JPN（GUID `earthx2.korean.localization`、`ko-*` 通配、
  配置 `ForceKorean=true`、`AddFontFallback=true`、`TranslateHardcodedText=true`）
- **L1 官方 JSON 层**：`Localization\Korean\` 64 文件 / ~1665 键全译（含 HUD.json 增补
  `Korean_Name`/`Korean_Desc`）；Misc 专有名词（人名/公司/大学/机构/卫星名）保留原文
- **L2 IL 字符串规则**：`ko-strings*.tsv` ×8（591 行 / 580 唯一 ORIG），ORIG 与 CHS 逐字一致
- **L3 TMP 烘焙规则**：`ko-baked*.tsv` ×2（299 条）
- **内嵌字体 Source Han Sans K**（SIL OFL 1.1，Regular + Bold）随插件 `fonts\` 分发
  （源文件取自本地字体库 `D:\工具软件\字体\08_SourceHanSansK`，OFL 1.1 许可随附）；回退资产
  沿用固定名 `ChineseFallback`/`ChineseFallbackBold`（技术性硬编码，勿改）；系统字体清单
  适配韩文（malgun/gulim/batang/dotum 等）
- 工具链 `-Lang`/`-Prefix ko` 参数化复用；`verify.ps1` KOR profile 复用 **ORIG 继承门禁**
  （580 ORIG 集合必须与 CHS 完全相等）+ `fonts\` 必备断言
- 双包发布：`KOR-EarthX2OAKoreanMOD_v1.0.0.zip` + `_full.zip` + sha256 + `KOR-latest.json`

### 修复 Fixed

- 修正 `ko-strings6.tsv` 三参 `Added` 规则 ORIG 尾部标签顺序（`</size></color>` → `</color></size>`，
  与 DLL ldstr 逐字对齐）；同文件 CRLF 归一为 LF
- 修正 `ko-strings3.tsv` `Transfer window with` TRANS 误加闭合标签导致的富文本失配
- `StringPatch` 增加 transpiler 反射方法 null 防护（运行时空引用兜底）

### 数据变更 Data

- Korean JSON：64 文件 / ~1665 键
- IL 规则：591 行 / 580 唯一 ORIG（DISPLAY 386 / AUTO 205）
- 烘焙规则：299 条（109 条与 CHS 相同的已知无害 no-op）
- 字体：内嵌 SourceHanSansK-Regular.otf (16.5 MB) + Bold.otf (17.0 MB)，OFL 1.1 许可随附

## [ESP 1.0.0] - 2026-09-03

首个西班牙语（ESP）补丁版本：基于 CHS 流程 fork 出独立西语补丁 `ESP\`，离线仓库树为唯一数据源，
随包交付 `EarthX2Spanish.dll` 与 `docs\ESP-NOTES.md`。

### 新增 Added

- **西语插件 `EarthX2Spanish`**：fork 自 DEU（GUID `earthx2.spanish.localization`、`es-*` 通配、
  配置 `ForceSpanish=true`、`TranslateHardcodedText=true`），**FontFix 整体剥离**——ESP 复用游戏
  内嵌字体 LiberationSans，不随包分发任何字体文件（á/é/í/ó/ú/ñ/ü 完整支持）
- **L1 官方 JSON 层**：`Localization\Spanish\` 64 文件 / ~1665 键全译（含 HUD.json 增补
  `Spanish_Name`/`Spanish_Desc`，语言选择器显示 "Español"）；Misc 专有名词（人名/公司/大学/
  机构/卫星名）保留原文
- **L2 IL 字符串规则**：`es-strings*.tsv` ×8（591 行 / 580 唯一 ORIG），ORIG 与 CHS 逐字一致
- **L3 TMP 烘焙规则**：`es-baked*.tsv` ×2（299 条）
- 工具链 `-Lang`/`-Prefix es` 参数化复用；`verify.ps1` ESP profile 复用 **ORIG 继承门禁**
  （580 ORIG 集合必须与 CHS 完全相等）+ 无 `fonts\` 断言
- 双包发布：`ESP-EarthX2OASpanishMOD_v1.0.0.zip`（纯补丁 166.1 KB）+ `_full.zip`（含框架
  802.7 KB）+ sha256 + `ESP-latest.json`

### 修复 Fixed

- 修正 `es-strings6.tsv` 三参 `Added` 规则 ORIG 尾部标签顺序（`</size></color>` → `</color></size>`，
  与 DLL ldstr 逐字对齐）；同文件 CRLF 归一为 LF
- `StringPatch` 增加 transpiler 反射方法 null 防护（运行时空引用兜底）

### 数据变更 Data

- Spanish JSON：64 文件 / ~1665 键
- IL 规则：591 行 / 580 唯一 ORIG（DISPLAY 386 / AUTO 205）
- 烘焙规则：299 条（109 条与 CHS 相同的已知无害 no-op）
- 字体：无随包字体（复用游戏内嵌 LiberationSans）

## [JPN 1.0.0] - 2026-09-02

首个日语（JPN）补丁版本：基于 CHS 流程 fork 出独立日语补丁 `JPN\`，离线仓库树为唯一数据源，
随包交付 `EarthX2Japanese.dll` 与 `docs\JPN-NOTES.md`。

### 新增 Added

- **日语插件 `EarthX2Japanese`**：fork 自 CHS（GUID `earthx2.japanese.localization`、`ja-*` 通配、
  配置 `ForceJapanese=true`、`AddFontFallback=true`、`TranslateHardcodedText=true`）
- **L1 官方 JSON 层**：`Localization\Japanese\` 64 文件 / ~1665 键全译（含 HUD.json 增补
  `Japanese_Name`/`Japanese_Desc`）；Misc 专有名词（人名/公司/大学/机构/卫星名）保留原文
- **L2 IL 字符串规则**：`ja-strings*.tsv` ×8（591 行 / 580 唯一 ORIG），ORIG 与 CHS 逐字一致
- **L3 TMP 烘焙规则**：`ja-baked*.tsv` ×2（299 条）
- **内嵌字体 Source Han Sans JP**（SIL OFL 1.1，Regular + Bold）随插件 `fonts\` 分发，回退资产
  沿用固定名 `ChineseFallback`/`ChineseFallbackBold`（技术性硬编码，勿改）
- 工具链 `-Lang`/`-Prefix ja` 参数化复用；`verify.ps1` JPN profile 复用 **ORIG 继承门禁**
  （580 ORIG 集合必须与 CHS 完全相等）
- 双包发布：`JPN-EarthX2OAJapaneseMOD_v1.0.0.zip` + `_full.zip` + sha256 + `JPN-latest.json`

### 数据变更 Data

- Japanese JSON：64 文件 / ~1665 键
- IL 规则：591 行 / 580 唯一 ORIG（DISPLAY 386 / AUTO 205）
- 烘焙规则：299 条
- 字体：内嵌 SourceHanSansJP-Regular.otf + Bold.otf（OFL 1.1 许可随附）

## [DEU 1.0.0] - 2026-09-02

首个德语（DEU）补丁版本：基于 CHS 流程 fork 出独立德语补丁 `DEU\`，离线仓库树为唯一数据源，
随包交付 `EarthX2German.dll` 与 `docs\DEU-NOTES.md`。

### 新增 Added

- **德语插件 `EarthX2German`**：fork 自 CHS（GUID `earthx2.german.localization`、`de-*` 通配、
  配置 `ForceGerman=true`、`TranslateHardcodedText=true`），**FontFix 整体剥离**——DEU 复用游戏
  内嵌字体 LiberationSans，不随包分发任何字体文件（无版权/依赖问题，ä/ö/ü/ß 完整支持）
- **L1 官方 JSON 层**：`Localization\German\` 64 文件 / ~1665 键全译（含 HUD.json 增补
  `German_Name`/`German_Desc`，语言选择器显示 "Deutsch"）；Misc 专有名词（人名/公司/大学/
  机构/卫星名）按德语惯例保留原文
- **L2 IL 字符串规则**：`de-strings*.tsv` ×8（591 行 / 580 唯一 ORIG），ORIG 与 CHS 逐字一致
- **L3 TMP 烘焙规则**：`de-baked*.tsv` ×2（299 条）
- 正式文风：非正式 "du" 称谓、术语统一（Vertrag=contract、Nutzlast=payload、Startrampe=
  launch pad、Drohnenschiff=droneship、Transferfenster=transfer window、Mittlere Rakete=
  Prime Rocket 等）
- 工具链 `-Lang`/`-Prefix de` 参数化复用；`verify.ps1` DEU profile 新增 **ORIG 继承门禁**
  （580 ORIG 集合必须与 CHS 完全相等）+ 无 `fonts\` 断言
- 双包发布：`DEU-EarthX2OAGermanMOD_v1.0.0.zip`（纯补丁 159.8 KB）+ `_full.zip`（含框架
  794.3 KB）+ sha256 + `DEU-latest.json`

### 修复 Fixed

- 重建被损坏的 `de-strings4.tsv`（全 NUL 字节，139 行从 CHS 源重译）
- 修正 `de-strings3.tsv` `\nDeploy Legs` ORIG 尾随 `\n` 与 CHS 源不一致问题

### 数据变更 Data

- German JSON：64 文件（59 已译 / 5 专有名词保留原文）
- IL 规则：591 行 / 580 唯一 ORIG（DISPLAY 386 / AUTO 205，FLAG 门禁通过）
- 烘焙规则：299 条（109 条与 CHS 相同的已知无害 no-op）
- 字体：无随包字体（复用游戏内嵌 LiberationSans）

## [1.0.0] - 2026-09-02

新发布体系首个版本（替代旧 handoff\release 流程；本版本包含 2026-09-01 全部校对与安全修复）。

### 新增 Added

- **多语言发布结构**：`publish\` 按语言分目录（`CHS\EarthX 2 Open Alpha\`），zip 带语言前缀
  （`CHS-EarthX2OAChineseMOD_v<版本>.zip`），构建脚本 `-Lang` 参数化；**仓库文件分发**：
  zip + sha256 + `<LANG>-latest.json` 直接提交入库（`release\`），各语言独立版本号，无 GitHub Releases
- **内嵌字体（思源黑体）**：插件 `fonts\` 内嵌 Source Han Sans CN（SIL OFL 1.1）Regular + Bold，
  免系统字体依赖、规避微软雅黑等专有字体版权再分发问题；两字重回退资产
  （`ChineseFallback` / `ChineseFallbackBold`），系统字体清单降级为回退
- 官方 JSON 本地化层：64 个文件（`EarthX_Data\StreamingAssets\Localization\Chinese\`，~1665 键）
- `StringPatch` IL 字符串补丁：591 条规则（580 唯一 ORIG），每条带 FLAG 分类（DISPLAY/AUTO），
  由消费点分类管线（classification-manifest.tsv）生成
- `TextSweep` TMP 烘焙文本规则：299 条（zh-baked.tsv / zh-baked2.tsv）
- 双包发布：纯补丁包 + 含 BepInEx 框架完整包（LGPL-2.1 合规：未修改二进制随附 + 许可文本 + 来源声明）
- 文档归位：根目录 `README.md`（英文主页，开头链接各语言使用说明）/`AI-PATCH-GUIDE.md`，
  各语言说明入 `docs\`（`CHS-NOTES.md`）；升级机制为手动覆盖
- 构建期质量门禁（verify.ps1 + build 内断言）：ORIG 唯一数、0 FAIL/0 冲突、FLAG 合法性、
  禁发文件零容忍、仓库树=工作区 MD5 对账

### 修复 Fixed

- 34 行译文缺陷：5 条富文本前导闭合丢失（样式泄漏）、25 条闭合顺序颠倒（颜色在外/尺寸在内）、
  2 处引号全角/半角配对、TimeLeft 占位符 {2} 恢复有意省略（避免"剩余 3 年 剩余"）
- 8 处作用域精修（以 DLL IL 为真值逐点复核）、4 处重复规则去重
- 阶段 0 安全处置：禁用 26 条会把资产 ID/动画参数/场景 ID 当显示文本翻译的规则
  （以 `# DISABLED` 注释保留在 TSV 内，可逆，待阶段 4 消费点感知后按显示侧恢复）

### 数据变更 Data

- JSON 键数：~1665（Chinese 层 64 文件）
- IL 规则：591 行 / 580 唯一 ORIG（DISPLAY 386 行 / AUTO 205 行，第 4 列 FLAG，插件向后兼容）
- 烘焙规则：299 条（其中 109 条为运行时无害 no-op，待运行时采集甄别）
- 字体：内嵌 SourceHanSansCN-Regular.otf (8.1MB) + Bold.otf (8.6MB)，OFL 1.1 许可随附
