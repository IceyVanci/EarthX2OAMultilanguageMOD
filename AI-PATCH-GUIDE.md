# AI-PATCH-GUIDE — 为 EarthX 2 制作其他语言补丁的方法指南

> 本文是 **面向 AI 编程助手**（也面向人类）的完整方法指南：把整篇文档喂给 AI，并给出目标语言
> （如 `日语` / `韩语` / `德语`）后，AI 应能据此产出一份可编译、可验证、可发布的语言补丁。
> 文中所有路径、格式、命令均取自本项目实际结构。已按本指南落地的语言：
> **简体中文 v1.0.0**（`CHS\`，首个语言）、**德语 v1.0.0**（`DEU\`，拉丁扩展语言 fork 实例，
> 复用游戏内嵌 LiberationSans，不随包字体）、**西班牙语 v1.0.0**（`ESP\`，同 DEU 的拉丁扩展实例）、
> **日语 v1.0.0**（`JPN\`，CJK 内嵌字体实例）与 **韩语 v1.0.0**（`KOR\`，CJK 内嵌字体实例）。
>
> 语言约定：正文中文，命令与代码英文。占位符 `<LANG>` 表示目标语言（如 `Japanese`），
> `<lang>` 为小写（如 `ja`）。

---

## 0. 用法（怎么把本文交给 AI）

把本文第 1–12 节连同以下上下文一并交给 AI：

- 本仓库根目录下的实际文件树（语言目录 `CHS\EarthX 2 Open Alpha\` 下的 `EarthX_Data\` 与 `BepInEx\`）
- 插件源码：`CHS\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese\src\EarthX2Chinese.cs`
- 现有简体中文规则文件：`...\BepInEx\plugins\EarthX2Chinese\zh-strings*.tsv`、`zh-baked*.tsv`
- 各语言说明模板：`publish\docs\CHS-NOTES.md`（生成 `<LANG>-NOTES.md`，见 §6.7）
- 游戏根目录历史文档：`翻译校对与优化检查推进方案.md`、`精确翻译方案.md`、
  `翻译流程优化方案.md`、`TASK_A~D_*.md`、`错误分析_Player日志.md`、
  `存档加载失败_检查结果与修复设计.md`
- 校验工具：`handoff\check_tsv.ps1`、`handoff\verify_current.ps1`、
  `handoff\scripts\validate_loc.ps1`、`publish\scripts\verify.ps1`、`publish\scripts\build-artifacts.ps1`

AI 的产出物（第 12 节验收清单逐项打勾）即算完成。

---

## 1. 补丁三层架构

EarthX 2 的文本来自三个不同来源，补丁需分别覆盖：

| 层 | 文本来源 | 覆盖方式 | 文件 |
|---|---|---|---|
| **L1 官方本地化层** | Unity 官方 `LocalizationAsset`（`AssetsManager.Assets` 按语言 Id 索引） | 新增一个 `Localization\Chinese\` 目录（游戏已内置按 Id 加载机制） | `EarthX_Data\StreamingAssets\Localization\Chinese\*.json`（64 文件，~1665 键） |
| **L2 代码内字符串** | C# IL 中的 `ldstr` 常量 | BepInEx 插件 **Harmony transpiler** 在运行时替换 `ldstr` 操作数 | `BepInEx\plugins\EarthX2Chinese\zh-strings*.tsv`（591 行规则，580 唯一 ORIG） |
| **L3 烘焙文本** | TextMeshPro 场景/预制体/运行时字符串 | 插件 **TextSweep** 挂钩 TMP 渲染，运行时精确替换 | `BepInEx\plugins\EarthX2Chinese\zh-baked*.tsv`（299 条规则） |

> 关键点：**L1 不需要改插件**（只加 JSON 目录）；**L2/L3 需要插件**。简体中文补丁把三层都做了。

---

## 2. 插件机制（`src\EarthX2Chinese.cs`，必须读懂）

### 2.1 入口与配置

- `BepInPlugin("earthx2.chinese.localization", "EarthX2 Chinese Localization", "1.1.0")`
- 配置文件：`BepInEx\config\earthx2.chinese.localization.cfg`
  - `ForceChinese`：启动时把游戏语言强制切到该补丁语言（默认 true）
  - `AddFontFallback`：注入 TMP 回退字体（默认 true）

### 2.2 `ChineseLanguage.Register()` —— 注册 L1 语言

```
LocalizationAsset asset = CreateInstance<LocalizationAsset>();
asset.name = "Chinese";  asset.Id = "Chinese";      // ← 语言 Id（改语言 X 的关键字面量）
asset.InitializeAsset();                             // 从 StreamingAssets\Localization\Chinese\ 加载
AssetsManager.Assets["Chinese"] = asset;             // ← 注册进游戏资产管理器
// 反射预填 Asset.AssetSingleCache["Chinese"]（静态缓存）
```

要注册新语言，**必须把 `"Chinese"` 全部替换为目标语言 Id**，且 JSON 目录名与之完全一致
（`StreamingAssets\Localization\<Id>\`）。

### 2.3 `StringPatch` —— 替换 L2 代码字符串

- `LoadRules(dir)`：读取插件目录下所有 `zh-strings*.tsv`（**通配符写死在源码里**）
- 行解析：`line.Split("^^^")` → `p[0]=scope`、`p[1]=orig`、`p[2]=trans`；
  `p.Length < 3 continue`（**第 4 列 FLAG 被忽略，向后兼容**）；`Unescape(\r,\n)`
- 键：`DeclaringType.FullName.Replace('+','/') + "::" + 方法名`（嵌套类 `+` → `/`）
- 匹配：`key.StartsWith(scope, Ordinal)` 前缀匹配 → 命中则**无条件**把 `ldstr` 操作数换成 trans
- 日志：`StringPatch: N rules loaded`、`N methods matched, N patched`

### 2.4 `TextSweep` —— 替换 L3 烘焙文本

- 读取插件目录下所有 `zh-baked*.tsv`（**通配符写死**），行格式 `ORIG^^^TRANS`
- 挂钩 TMP_Text 渲染（on-text-changed 等），`orig` 精确匹配则替换
- 日志：`TextSweep: N rules loaded, hooks applied`

### 2.5 `FontFix` —— 字体回退（CJK 等缺字问题）

- **优先加载插件目录 `fonts\` 内嵌字体**（`SourceHanSansCN-Regular.otf` / `-Bold.otf`，
  思源黑体 SIL OFL 1.1，随补丁分发，免系统字体依赖、无版权争议），注册两个回退资产：
  `ChineseFallback`（Regular）+ `ChineseFallbackBold`（Bold）
- 内嵌失败时回退系统字体清单（msyh.ttc / simhei.ttf / Deng.ttf / SourceHanSansSC / NotoSansCJKsc 等）
- **回退字体资产名必须为 `"ChineseFallback"` / `"ChineseFallbackBold"`**（代码硬编码检测，已注册则跳过）
- **字体按目标文字分为两类，务必区分**：
  - **拉丁扩展语言（法/德等）**：**无需替换字体**，直接用原版内嵌 LiberationSans SDF
    （已覆盖 é/è/ß 等拉丁扩展字形），`fonts\` 可省略不进包。
  - **CJK 语言（日/韩等）**：`fonts\` 换成覆盖目标文字的 OFL 字体
    （如日语 SourceHanSansJP / 韩语 SourceHanSansKR），许可文本随附 `fonts\`。
  - 思源黑体族（SC/TC/JP/KR 子集）本身含拉丁字形，可兜底拉丁字符，但非拉丁版主字体默认无需引入。

---

## 3. 制作语言 X 的决策清单

| # | 决策 | 说明 |
|---|---|---|
| 1 | 语言 Id | `"Chinese"` → `"<LANG>"`（如 `"Japanese"`），JSON 目录名、`Register()`、配置均同步 |
| 2 | 通配符 | **零代码方案**：文件仍叫 `zh-strings*.tsv` / `zh-baked*.tsv`（插件不关心语言名）；或 **fork 源码** 改通配为 `"<lang>-strings*.tsv"` |
| 3 | 字体 | 拉丁扩展语言（法/德）无需替换，直接用原版 LiberationSans SDF（可省略 `fonts\`）；CJK 语言（日/韩）换成 SourceHanSansJP / SourceHanSansKR（OFL 1.1 随附） |
| 4 | GUID/版本 | 新 GUID（`earthx2.<lang>.localization`）避免与中文补丁配置/日志混淆；版本号独立 |
| 5 | ForceChinese | 保持 true（启动即切换，避免玩家手动改游戏语言设置）；fork 时配置项可改名 `Force<LANG>`，与独立 GUID（决策 4）的 cfg 隔离一致 |
| 6 | 代码复用 | 其余逻辑（transpiler/sweep/注册）完全复用中文补丁，只改上面几处 |
| 7 | 仓库目录 | 新语言放在 `publish\<LANG>\EarthX 2 Open Alpha\`，zip 名带 `<LANG>-` 前缀，构建用 `build-artifacts.ps1 -Lang <LANG>` |

**重编译命令**（.NET Framework 4.x，引用 BepInEx core；完整参考 `TASK_D_*.md` §2.2）：

```powershell
$refs = @('BepInEx\core\0Harmony.dll','BepInEx\core\BepInEx.dll','BepInEx\core\Mono.Cecil.dll',
          'BepInEx\core\UnityEngine.CoreModule.dll','BepInEx\core\UnityEngine.TextRenderingModule.dll',
          'BepInEx\core\UnityEngine.UI.dll','BepInEx\core\Assembly-CSharp.dll')
$args = @('-nologo','-target:library','-out:EarthX2<LANG>.dll') +
        ($refs | ForEach-Object { "-r:`"$_\"" } ) +
        @('EarthX2<LANG>.cs')
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" $args
```

> `Assembly-CSharp.dll` 需从 `EarthX_Data\Managed\` 拷出；引用列表以实际报错为准（缺啥补啥）。

---

## 4. 规则文件契约（TSV 格式）

### 4.1 两种文件的字段

| 文件 | 通配 | 字段 | 说明 |
|---|---|---|---|
| L2 规则 | `zh-strings*.tsv` | `scope^^^orig^^^trans[^^^FLAG]` | scope=类型+`::`+方法前缀；第 4 列 FLAG 插件忽略，仅供工具链 |
| L3 规则 | `zh-baked*.tsv` | `orig^^^trans` | 精确匹配 |

- 分隔符：`^^^`（三个脱字符）
- 编码：**UTF-8 无 BOM、LF** 换行；空行与 `#` 开头行为注释
- 注释示例：`# DISABLED: <orig>` —— 26 条历史禁用词条以此形式保留，不参与加载

### 4.2 转义口径（三处不同，务必区分）

| 位置 | 换行符形态 |
|---|---|
| TSV 规则文件 | **字面** `\n` / `\r`（两个字符） |
| `ldstr-inventory.tsv`（提取产物） | **字面** `\n`（与 TSV 一致，可直接复制） |
| DLL 真实值（`verify_current.ps1` 反解） | **真实**换行（校验脚本负责 Unescape 后比对） |
| `baked-level0.txt`（运行时采集） | **真实**换行 |
| `baked-full.txt`（DLL 全量提取） | **字面** `\n` |

> AI 陷阱：从 DLL/采集件里抄 ORIG 时，若源是"真实换行"必须转成字面 `\n` 再写进 TSV，
> 否则规则永远不命中。`verify_current.ps1 -TargetDir` 会抓出这类错误。

### 4.3 FLAG 语义（工具链内部）

- `DISPLAY`：界面可见文本（安全直译）
- `MIXED`：含不可译片段
- `AUTO`：无条件替换风险词条（等未来运行时消费感知上线前的过渡标记）
- 校验 gate：第 4 列只允许 `DISPLAY/MIXED/AUTO` 三值，非法即 FAIL

### 4.4 占位符与富文本

- `String.Format` 多参合法：**TRANS 可省略多余参数**（运行时传参不影响），
  但 `{0}`/`{1}`… 顺序与数目必须与 ORIG 语义一致（`{2}` 若在原文末尾且格式串不消费，
  中文补丁有意省略——见第 10 节坑 7）
- 富文本标签（`<color=...>`、`<b>`、`<size>` 等）数量必须与 ORIG 相等
- ORIG 在全部文件内必须**唯一**（重复 = CONFLICT = FAIL）

### 4.5 产物基线（简体中文 v1.0.0，供对账）

```
L2: 591 行 / 580 唯一 ORIG（DISPLAY 386 / AUTO 205）
L3: 299 条（其中 109 条 no-op 已记录放行）
L1: 64 JSON / ~1665 键
```

---

## 5. 安全红线（决定翻译是否被拒绝）

### 5.1 禁译清单

以下内容**绝不翻译**（改了会破坏游戏逻辑）：

- **资产 ID**：`Asset::GetAsset` 等返回的 key（车辆/部件/地图/特效 ID）
- **动画参数**：`Animator::GetBool/SetBool/SetTrigger/SetInteger/SetFloat/Play` 的参数字符串
- **物理 tag**：`OnTriggerEnter/Exit` 里的 tag（如 `TCMechazillaArm`）
- **路径前缀**：`Icons/`、`Panels/`、`Prefabs/`、`Chart And Graph/`、`Themes/` 等资源路径
- **着色器属性**：`_xxx` 形式（`_Color`、`_MainTex` 等）
- **第三方库内部**：MEC（`CoroutineHandle`）、Pinwheel 等库字符串
- **语言 Id 与本地化键**：`English`、`Month{0}`、`Day{0}` 等 `Localize` 键
- **配置/菜单键名**：`SettingName` 等 `PlayerPrefs` 键

### 5.2 危险消费点签名表（翻译前先对照）

| 签名模式 | 含义 | 处理 |
|---|---|---|
| `Asset::GetAsset(string)` / `Asset::GetAssets(...)` | 用字符串查资产 | **不译**（key 必须保持原文） |
| `AssetsPooling::GetAsset(...)` | 同上 | **不译** |
| `Data::GetDataByLinq(...)` / `Data::GetDataByUniqueId(string)` | 数据查找 key | **不译** |
| `PlanetsManager::LoadPlanetWithoutTransition(string)` | 行星 key | **不译** |
| `PlayerPrefs::Get*(...)/Set*(...)` | 存档键 | **不译**（值若为显示文本可谨慎译） |
| `Dictionary`2::get_Item / ContainsKey(string)` | 字典 key 消费 | 判定其上游是否用翻译后字符串做 key |
| `String::op_Equality/op_Inequality/Equals/Compare/CompareOrdinal` | 字符串比较 | **不译**（值参与逻辑） |
| `String::Concat / Format` 结果再次作为 key | 拼接 key 模式 | 上游已替换则需处理 |

### 5.3 位置判定法（AI 必须遵守）

1. **ldstr 必须是紧邻消费调用的实参**：用 Mono.Cecil 检查栈语义，确认该 `ldstr` 确实被
   危险方法作为实参取用，而不是相邻无关指令（对照 `getassettype-audit.txt` 的审计方法）。
2. **禁止线性扫描**：`ldstr` 之后若有分支（`beq/br/brtrue` 等）跳到别处，后面紧接着的
   `GetAsset(ldarg.0)` 并不消费该 ldstr。典型陷阱：`Cheats::PlayCutsceneCommand`
   （`ldstr` → `stloc.1` → `br.s` 跳过 → 另一分支 `GetAsset(ldarg.0)`）。
   必须**沿实际数据流**追踪，而非按指令顺序盲扫。
3. **`GetAssetType` 家族**：`GetAssetType()`/`GetAssetType2()` 是 switch-return 的**显示名**，
   已审计 9 个调用点全部为显示拼接（`getassettype-audit.txt`），此类**可译**，但改前重新审计。

---

## 6. 工具链工作流（命令逐条）

### 6.0 免游戏依赖的数据源复用（推荐路径，制作新语言的核心）

制作新语言**无需运行游戏、无需重新提取基准**。L2/L3 的提取（§6.2/§6.3）只对简体中文做过一次，
新语言直接复用其产出作为源，全程离线：

1. **L2 规则**：复制 `zh-strings*.tsv` → 保留 `SCOPE^^^ORIG` 两列不变，**只把 `TRANS` 列译成目标语言**
2. **L3 规则**：复制 `zh-baked*.tsv` → `ORIG` 不变，只译 `TRANS`
3. **L1 JSON**：复制 `StreamingAssets\Localization\English\*.json` → 键不变，只把值译成目标语言

要点：
- **翻译源策略**：必须取 `ORIG`（原版英文原文）**直译**；**禁止**从中文译文二次转译（会失真、引入中文句式残留）。
- **继承安全红线**：直接复用 CHS 的 SCOPE / 富文本 / 占位符结构，只改译文 →
  自动继承 CHS 已验证的"哪些能译、哪些不能译"决策，规避 §5 全部风险（不碰资产 ID / 键 / 逻辑字符串）。
- **真值对账**：`verify_current.ps1` 复用同一份 `Assembly-CSharp.dll` 基线，发布前跑一次即可（§6.4）。
- **ORIG 继承门禁**（`verify.ps1` §3，仅 offline/fork 语言）：fork 语言的 ORIG 集合必须与
  CHS 基线**完全相等**（缺一或多一都 FAIL），确保 SCOPE/ORIG 结构零漂移、只换译文。
- 对应译文列宽度/长度：拉丁（法/德）与 CJK（日/韩）对占位符 `{n}`、富文本标签数量要求与 §4.4 一致。

### 6.1 预置

```powershell
# 工作区路径
$game = "F:\EarthX 2 Open Alpha (Windows)"
# Mono.Cecil 反汇编依赖（已在 BepInEx core）
$cecil = "$game\BepInEx\core\Mono.Cecil.dll"
# 游戏程序集
$asm = "$game\EarthX_Data\Managed\Assembly-CSharp.dll"
```

### 6.2 提取 L2 基准（ldstr inventory）

用 Mono.Cecil 遍历 `Assembly-CSharp.dll` 全部方法，收集：

- 每个 `ldstr` 的字面值（转字面 `\n`）
- 所在方法键：`DeclaringType.FullName.Replace('+','/') + "::" + 方法名`

输出 `ldstr-inventory.tsv`（`值<TAB>方法1,方法2,...`）。参考实现：`handoff\verify_current.ps1`
的 `opsByMethod` 遍历逻辑（它已含 ldstr→操作数收集）。简体中文基线 1802 个唯一 ldstr。

### 6.3 提取 L3 基准（烘焙文本）

- `baked-level0.txt`：游戏运行时从 TMP 组件 dump（**真实换行**）——简体基线 574 条
- `baked-full.txt`：从 DLL 里提取的 `ldstr` + 插值串全量（**字面 `\n`**）——简体基线 27946 行
- 匹配基线：`baked-full` 中能对上 `baked-level0` 的才算可覆盖烘焙文本（`baked-full-matched-report.txt`）

### 6.4 校验规则文件

```powershell
# JSON 层（L1）校验
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\scripts\validate_loc.ps1" -GameRoot $game -SkipRuntime

# TSV 层（L2/L3）校验（结构/占位符/FLAG/冲突/烘焙基线）
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\check_tsv.ps1" -TargetDir "$game\BepInEx\plugins\EarthX2Chinese"

# DLL 真值对账（确认规则确实能命中真实字符串）
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\verify_current.ps1" -TargetDir "$game\BepInEx\plugins\EarthX2Chinese"
```

### 6.5 分类与归档（可选，简体中文已内置基线）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\scripts\classify_strings.ps1" -TargetDir <plug>
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\scripts\adjudicate_manifest.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$game\handoff\scripts\generate_rules.ps1"
```

### 6.6 发布门禁与打包（解耦流程）

`verify.ps1` 与 `build-artifacts.ps1` 均支持 `-Lang CHS|DEU|JPN|FRA|POR|ESP|KOR`（`-Lang` 指定语言，
默认 CHS）。**各语言打包互相解耦**：语言包只含本语言内容，共享文档只在仓库根；增量构建通过
manifest 哈希自动跳过未变化语言。

```powershell
# 门禁（含仓库树=工作区对账；CHS 为工作区来源，其余为 offline 仓库树来源）
powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\verify.ps1" -GameRoot $game -Lang CHS

# 构建单个语言（刷新仓库树 → 门禁 → 打该语言补丁包 + full 包；内容未变则 SKIP）
powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\build-artifacts.ps1" -GameRoot $game -Lang DEU

# 批量构建全部已发布语言（CHS/DEU/JPN/ESP/KOR，各自套用 SKIP 逻辑，输出 BUILT/SKIP/FAILED 汇总）
powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\build-artifacts.ps1" -All

# 强制重建（绕过 SKIP）
powershell -NoProfile -ExecutionPolicy Bypass -File "$publish\scripts\build-artifacts.ps1" -Lang ESP -Force
```

**解耦打包设计（2026-09-03）**：

- **补丁 zip 只含本语言内容**：`Localization\<Id>\*.json` + `BepInEx\plugins\EarthX2<Lang>\` 全部
  （DLL/TSV/插件 README/src/fonts/version.txt）+ `docs\<LANG>-NOTES.md`（仅本语言）+ 本语言字体许可
  （内嵌字体语言）。**不再内嵌** `README.md`/`README_CN.md`/`AI-PATCH-GUIDE.md` 或 `docs\*` 全量，
  这些共享文档只存在于仓库根。→ 修改/新增任何语言都不会使其他语言的包内容变化。
- **增量跳过（manifest）**：每个语言构建时计算 `langHash`（该语言仓库树内容哈希）与
  `frameworkHash`（winhttp/doorstop/BepInEx core + licenses），与 `release\_manifest_<LANG>.json`
  比对；版本 + 两哈希一致且产物存在 → `SKIP`，不写 zip/sha/`latest.json`/manifest（git 零 diff）。
  - patch zip 由 `langHash` 决定；`_full.zip` 由 `langHash` + `frameworkHash` 共同决定。
  - `-Force` 强制重建；`-SkipFull` 只打补丁包。
- **语言白名单**：profile 内 `Released=$true` 才参与 `-All`（当前 CHS/DEU/JPN/ESP/KOR；FRA/POR 未发布，
  只能 `-Lang` 单独构建）。
- 产物：双 zip + sha256 + `<LANG>-latest.json` + `_build_report_<LANG>.txt` + `_manifest_<LANG>.json`。

`verify.ps1` 的**完整门禁清单**（任一 FAIL 即终止，`build-artifacts.ps1` 内部也调用它作为硬门禁）：

| # | 门禁 | 覆盖层 | 说明 |
|---|---|---|---|
| 1 | `validate_loc.ps1` JSON 层 | L1 | English ↔ `<LANG>` 键集/占位符/富文本/@别名 一致性（扁平解析，**不查语法**） |
| 2 | `check_tsv.ps1` TSV 层 | L2/L3 | 结构 0 FAIL / 0 CONFLICT / FLAG 合法 / 烘焙基线 no-op 上限 |
| 3 | ORIG 唯一数基线 | L2 | `-UniqueOrig`（CHS/DEU/JPN/ESP/KOR = 580） |
| 4 | **ORIG 继承门禁**（仅 offline） | L2 | fork 语言 ORIG 集合与 CHS 基线完全相等（§6.0） |
| 5 | JSON 文件数 | L1 | `-JsonCount`（64） |
| 6 | **严格 JSON 语法门禁** | L1 | 用 `JavaScriptSerializer` 严格解析每个 `*.json`，**捕获未转义引号等运行时致命错误**（validate_loc 的扁平解析抓不到） |
| 7 | 插件目录禁发文件 | 插件 | `rules_backup`/`__MACOSX`/`.DS_Store`/`.log` 等零容忍 |
| 8 | 字体策略断言 | 插件 | CHS/JPN/KOR 须有 `fonts\`；**DEU/ESP 禁止 `fonts\`**（游戏内嵌字体） |
| 9 | 仓库树/版本 | 仓库 | 工作区↔仓库树 MD5 对账（CHS）、`version.txt` = `publish\VERSION` |

### 6.7 生成语言 NOTES 文档（`docs\<LANG>-NOTES.md`）

各语言的 `publish\docs\<LANG>-NOTES.md`（玩家使用说明）以简体中文的
`publish\docs\CHS-NOTES.md` 为模板生成。**文件名必须 ASCII**（坑 #4），
内容可按目标语言或中英双语撰写。对照模板逐节改写：

| CHS-NOTES.md 小节 | 生成 `<LANG>-NOTES.md` 的改写点 |
|---|---|
| 标题 / 语言码 | `<LANG>` 语言码（如 `JPN`），版本仍取 `version.txt` |
| 安装 | 补丁目录改为 `<LANG>\EarthX 2 Open Alpha\`；zip 名改为 `<LANG>-EarthX2OA<LANG>MOD_v<版本>.zip` / `_full.zip` |
| 字体说明 | **CJK 语言**：写明内嵌字体名（SourceHanSansJP/KR…）+ OFL 许可位置；**拉丁语言（法/德）**：整节改写为"无需内嵌字体，使用游戏原版 LiberationSans SDF"或直接删节 |
| 卸载 | `Localization\Chinese\` 路径改为 `<Id>\`（如 `Japanese\`），其余同 |
| 存档安全 / 升级 | 与 CHS 一致，仅确认无语言特定改动 |

- 产物位置：`publish\docs\<LANG>-NOTES.md`（解耦流程下**仅本语言的 `docs\<LANG>-NOTES.md` 进包**，
  其他语言的 NOTES 与根文档不进包，见 §6.6）。
- 生成后**不要手动复制进 `publish\<LANG>\...`**（该仓库树由构建脚本从工作区刷新，见 §6.6）。
- 参考实例：`publish\docs\DEU-NOTES.md` 与 `ESP-NOTES.md`（拉丁语言：无内嵌字体、用游戏内嵌
  LiberationSans 的字体节写法）、`JPN-NOTES.md` 与 `KOR-NOTES.md`（CJK 语言：内嵌字体 + OFL 许可）。

---

## 7. 硬护栏（不可逾越）

1. **不改游戏本体**：不修改 `EarthX_Data` 下除 `StreamingAssets\Localization\<Id>\` 之外的任何文件
2. **不改游戏 DLL**：绝不重编译/替换 `Assembly-CSharp.dll`（补丁是运行时注入）
3. **批量修改前备份**：规则文件改动前复制到 `handoff\backup\work\` 时间戳快照
4. **只动受控目录**：工作区 `BepInEx\plugins\EarthX2Chinese\`、`handoff\`、`publish\`
5. **规则数基线核对**：每次改动后对比插件日志 `StringPatch: N rules loaded`（简体=580）
6. **发布前过门禁**：`verify.ps1` 0 FAIL 才允许 `build-artifacts.ps1`

---

## 8. 已知坑清单（简体中文补丁实战沉淀）

| # | 坑 | 说明与规避 |
|---|---|---|
| 1 | PowerShell 5.1 `Assert` 布尔陷阱 | `Assert([string]$x)` 会强转字符串：`"False"` 非空 → 真值。校验脚本必须 `[bool]` 化再断言，否则 FAIL 被静默吞掉 |
| 2 | 方法实参逗号优先级 | `obj.Method($a -replace 'x','y', $z)` 中逗号把 `$a -replace 'x'` 拆成独立参数。PS 5.1 无 `??`、逗号在实参里优先于 `+`/`-replace` → 必须括号包裹 |
| 3 | PS 5.1 无 BOM UTF-8 脚本 | 无 BOM 的 `.ps1` 被按 ANSI（GBK）读取 → 中文字面量乱码。脚本要么**纯 ASCII**，要么**带 BOM** |
| 4 | .NET Framework ZipArchive 无 EFS 标志 | 中文 zip 条目名跨系统必乱码（无 EFS 位，解压器按本机代码页猜）。→ **所有 zip 内文件名一律 ASCII**（README.md / AI-PATCH-GUIDE.md，勿用中文名） |
| 5 | `Copy-Item -LiteralPath` 通配符失效 | `-LiteralPath` 不展开 `*`，含通配的复制必须用 `-Path` |
| 6 | 分支跳转误扫 | 见 5.3 判定法；线性扫描会误译出破坏逻辑的词条 |
| 7 | `TimeLeft {2}` 有意省略 | 某些 `String.Format` 的 `{2}` 参数在格式串中不出现（多参合法），勿强行补 `{2}` |
| 8 | 回退字体名硬编码 | TMP 回退字体必须命名 `ChineseFallback`，否则重复注入 |
| 9 | ORIG 冲突 | 同一 ORIG 出现于多个文件/行 → CONFLICT → 构建 FAIL，需去重或按 scope 收窄 |
| 10 | 语言 Id 与游戏语言列表 | 新增 `<LANG>` 可能不显示在游戏内语言切换下拉框（游戏可能只认内置语言）。需游戏内验证；若需 patch 语言列表 UI，记为新增改动点（§3 决策 1） |
| 11 | NOTES 文档文件名 ASCII | `docs\<LANG>-NOTES.md` 文件名必须 ASCII（如 `JPN-NOTES.md`），中文/特殊字符文件名进 zip 会乱码（同坑 #4）；内容可含目标语言 |
| 12 | JSON 字符串内未转义 ASCII 双引号 | 德语引号 `„…“`（U+201E/U+201C）若混入 ASCII `"` 会破坏 JSON 语法。游戏 `LocalizationAsset.InitializeAsset()` 用 Newtonsoft **无 try-catch** 遍历解析 `Localization\<Id>\*.json`，任一文件抛 `JsonReaderException` → **整个语言注册中断、静默回退英文**（mod 看似失效）。`validate_loc.ps1` 的扁平解析器**抓不到**语法错误，须靠 `verify.ps1` 的严格 JSON 门禁（§6.6 门禁 #6）拦截。DEU 实战：Catter.json 1 处 + Upgrades.json 2 处 `„Landen"` 型引号导致 v1.0.0 首版整体失效 |
| 13 | 语言选择器名称键 | 想让游戏内语言切换下拉框显示语言名，需在 HUD.json 增补 `<LANG>_Name`/`<LANG>_Desc` 键（如 `German_Name`="Deutsch"）；`validate_loc.ps1` 自动把 `${TargetLang}_Name/_Desc` 加入白名单（不判为多余键） |
| 14 | offline 语言运行 validate_loc 的路径 | `-GameRoot` 必须指向游戏根（含 `English\` 基线），而 `-LangDir`/`-PluginDir` 指向 `publish\<LANG>\...` 仓库树；把 DEU 仓库树当 `-GameRoot` 会报 "English directory not found" |

---

## 9. 参考文档索引

| 文档 | 位置 | 内容 |
|---|---|---|
| 推进总纲 | 根目录 `翻译校对与优化检查推进方案.md` | 三层架构、stage0-3、禁译红线（§9.3） |
| 翻译方法 | 根目录 `精确翻译方案.md` / `翻译流程优化方案.md` | 占位符/富文本规则、翻译流程 |
| 任务书 | 根目录 `TASK_A~D_*.md` | A=校对、B=工具化校验与打包、C=IL 残留汉化（ldstr）、D=烘焙采集（baked） |
| 错误分析 | 根目录 `错误分析_Player日志.md` | 运行时日志问题归类 |
| 存档修复 | 根目录 `存档加载失败_检查结果与修复设计.md` | 存档安全约束 |
| 分类清单 | `handoff\classification-manifest.tsv` | 580 ORIG 符号栈分类（0 IDENTIFIER） |
| 审计记录 | `handoff\getassettype-audit.txt` | GetAssetType 9 调用点审计结论 |
| 质检报告 | `handoff\qa-report.md` | 阶段 0-3 质检汇总（含六/七章） |
| 提取基准 | `handoff\ldstr-inventory.tsv` / `baked-level0.txt` / `baked-full.txt` | 提取基线 |
| 校验脚本 | `handoff\check_tsv.ps1` / `verify_current.ps1` / `scripts\validate_loc.ps1` | 门禁实现 |

---

## 10. 语言 X 验收清单（DoD）

制作完成后逐项打勾，全部通过才算发布：

- [ ] **L1**：`StreamingAssets\Localization\<Id>\*.json` 已就位，键值完整，`<Id>` 与 `Register()` 一致
- [ ] **L1 严格语法**：全部 JSON 通过严格解析（`verify.ps1` 门禁 #6，坑 #12）——未转义引号会导致整个语言注册失效
- [ ] **NOTES**：`publish\docs\<LANG>-NOTES.md` 已按 §6.7 生成（ASCII 文件名，内容含安装/卸载/字体说明）
- [ ] **L2**：`<lang>-strings*.tsv`（或复用 `zh-*`）通过 `check_tsv.ps1` 0 FAIL / 0 CONFLICT
- [ ] **L3**：`<lang>-baked*.tsv` 通过基线匹配，无超量 no-op
- [ ] **真值对账**：`verify_current.ps1` 0 FAIL（规则能命中 DLL 真实字符串）
- [ ] **编译**：插件 `<LANG>` 版本 csc 编译成功，无缺引用
- [ ] **游戏内冒烟**：主菜单/车辆/行星选择/设置均显示 `<LANG>`；无方块缺字（字体已换）；无英文残留关键路径
- [ ] **逻辑回归**：发射、存档读/写、行星切换正常；无 `GetAsset`/`PlayerPrefs` key 被误译
- [ ] **日志**：`StringPatch: N rules loaded`、`TextSweep: N rules loaded, hooks applied` 出现且计数符合预期
- [ ] **门禁**：`verify.ps1` ALL PASS（offline/fork 语言含 **ORIG 继承门禁**：580 ORIG 集合与 CHS 完全相等，§6.6 门禁 #4）
- [ ] **打包**：`build-artifacts.ps1` BUILD OK；zip 内文件名全 ASCII
- [ ] **发布**：zip + sha256 + `<LANG>-latest.json` 入 `release\` 并提交（仓库文件分发，无 GitHub Releases），废弃文件以文档注明

---

## 11. 附：语言 X 修改点速查（对照简体中文）

```
publish\<LANG>\EarthX 2 Open Alpha\EarthX_Data\StreamingAssets\Localization\
    Chinese\        →   <LANG>\                     (64 JSON，键结构同)
publish\<LANG>\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese\
    推荐：直接复制 CHS 的 zh-strings*.tsv / zh-baked*.tsv，只改 TRANS 列，不改 SCOPE/结构（见 §6.0）
    src\EarthX2Chinese.cs
        "Chinese"                 →   "<LANG>"       (2.2 节，多处)
        "zh-strings*.tsv"         →   "<lang>-strings*.tsv"   (2.3 节，或文件复用 zh-)
        "zh-baked*.tsv"           →   "<lang>-baked*.tsv"     (2.4 节)
        fonts\SourceHanSansCN-*.otf  → 仅 CJK 语言需换（SourceHanSansJP/KR）；拉丁语言（法/德）可省略 fonts\
        "ChineseFallback"/"ChineseFallbackBold"  → 保持原名（硬编码检测）
        BepInPlugin("earthx2.chinese.localization",...,"1.1.0")
                                  →   ("earthx2.<lang>.localization",...,"<新版本>")
        ForceChinese              →   Force<LANG>（§3 决策 5）
publish\docs\<LANG>-NOTES.md      →   该语言说明（放 docs\，ASCII 文件名）
构建：build-artifacts.ps1 -Lang <LANG>；zip 名 <LANG>-EarthX2OA<LANG>MOD_v<版本>.zip；
      产物（zip×2+sha256×2+<LANG>-latest.json）入 release\ 并提交（仓库文件分发，无 Releases）
门禁：verify.ps1 ALL PASS 含严格 JSON 语法（§6.6 门禁 #6）与 offline fork 语言的 ORIG 继承门禁（#4）
```
