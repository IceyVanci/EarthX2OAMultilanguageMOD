# EarthX 2 简体中文汉化包

## 功能
- 全量简体中文本地化（64 个文件 / 1665 个键值：物品、载具、合同、剧情新闻、
  建筑建筑描述、里程碑、设置界面、社交动态等）
- 基于 BepInEx 的中文动态回退字体（自动使用系统"微软雅黑"，拉丁字符保持
  原版 LiberationSans 字形不变）
- 启动时自动注册并切换到中文语言（原版 English 语言不受任何影响）
- **硬编码文本汉化（v1.1.0 新增）**：
  - `StringPatch`：JIT 阶段用 Harmony transpiler 重写 Assembly-CSharp.dll 中
    `ldstr` 硬编码字符串（规则来自 `zh-strings*.tsv`，按"方法作用域"精确匹配，
    只改玩家可见文本，不动资产 ID / 动画名 / 开发者控制台）
  - `TextSweep`：运行时扫描 TMP 组件，替换烘焙在场景/预制体里的文本
    （规则来自 `zh-baked*.tsv`）

## 文件结构
```
EarthX 2 Open Alpha (Windows)\
├─ BepInEx\
│  ├─ core\                          （BepInEx 框架，必需）
│  └─ plugins\EarthX2Chinese\
│     ├─ EarthX2Chinese.dll          （汉化插件 v1.1.0）
│     ├─ zh-strings*.tsv             （IL 硬编码字符串规则：SCOPE^^^ORIG^^^TRANS）
│     ├─ zh-baked*.tsv               （烘焙 TMP 文本规则：ORIG^^^TRANS）
│     └─ README.md
├─ EarthX_Data\StreamingAssets\Localization\
│  ├─ English\                       （原版英文，未改动）
│  └─ Chinese\                       （中文翻译文件）
├─ winhttp.dll                       （BepInEx 加载器，必需）
└─ doorstop_config.ini               （BepInEx 配置，必需）
```

## 使用
直接运行 EarthX.exe 即可，无需任何操作。游戏会自动以简体中文启动。

## 卸载 / 还原英文
删除 `BepInEx\plugins\EarthX2Chinese` 文件夹即可恢复英文
（或把 BepInEx 配置项 ForceChinese 设为 false）。
彻底移除汉化：删除 winhttp.dll、doorstop_config.ini、.doorstop_version 和 BepInEx 文件夹。

## 插件配置
`BepInEx\cfg\earthx2.chinese.localization.cfg`
- ForceChinese         = true   启动时切换到中文
- AddFontFallback      = true   注入中文回退字体
- TranslateHardcodedText = true 启用硬编码文本汉化（StringPatch + TextSweep）

## 汉化覆盖情况（v1.1.0）
- JSON 官方本地化：1665 键全部中文化（已验证键集/占位符/富文本与英文版一致）
- IL 硬编码字符串：572 条规则，已扫描并 Harmony 打补丁 **252 个方法**
  （规则原文均与 DLL 逐字核对过；作用域精确限定在玩家可见方法）
- TMP 烘焙文本：299 条规则（含主菜单、HUD、事件面板等）
- 已知未覆盖：极少数动画事件名、开发者控制台字符串、部分存档内嵌文本仍为英文；
  少数烘焙长文本（信用/事件详情）待翻译校对任务修正原文后生效

## 技术说明
- 插件通过 Harmony 后缀 `AssetsManager.PrepareAssets` 实现：
  1) 用 `Font.Internal_CreateFontFromPath` 加载系统 CJK 字体，
     经 `TMP_FontAsset.CreateFontAsset` 生成动态 SDF 字体并挂入
     `TMP_Settings.fallbackFontAssets`；
  2) 构造 `LocalizationAsset`（Id=Chinese，读取
     `StreamingAssets/Localization/Chinese/*.json`），注册到
     `AssetsManager.Assets` 并置 `Settings.Langauge = "Chinese"`；
  3) `StringPatch`：用 Mono.Cecil 扫描 Assembly-CSharp.dll 中引用目标字符串的
     方法，反射解析后用 Harmony transpiler 改写 `ldstr` 操作数；
  4) `TextSweep`：patch `TMP_Text.set_text` 前缀 + `OnEnable` 后缀，
     并订阅 `SceneManager.sceneLoaded` 做全场景扫描。
- 游戏更新后若键值变化：只需对比 English 与 Chinese 文件夹补译新增键，
  框架无需重新适配。

