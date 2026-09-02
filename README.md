# EarthX2OAMultilanguageMOD

**English** | [中文版 README_CN.md](README_CN.md)

Community multi-language localization for **EarthX 2 (Open Alpha)**. The repository is
organized per language; each language folder contains the **patch file tree** (identical
layout to the game root). **No game files are included or modified.**

## Disclaimer / 声明

This mod was produced with AI collaboration and has **not undergone full human review**.
Some language versions are translated autonomously by AI based on the CHS translation
workflow, and may contain translation errors or content that is not accepted in certain
regions. We respect the cultural norms and expression conventions of different regions;
however, since the translation process is AI-completed and not fully human-reviewed,
**this project assumes no responsibility for any controversial or offensive content**
that may appear.

本 mod 未经完整人工审校，在 AI 协作下完成。部分语言的翻译完全基于 CHS 翻译流程由 AI 自主完成，
可能存在翻译错误或在不同地区不被认可的内容。我们尊重不同地区的文化与表述传统；但由于翻译流程
由 AI 完成且未经完整人工审校，如果出现具有争议或冒犯性的内容，**本项目不对此负责**。

## Translation Coverage / 翻译覆盖范围

This mod is **not 100% translated**. Basic content and most of the in-game text are covered;
some strings (dynamic concatenation, rarely-seen scenes, newly added content, etc.) may
remain in the original language.

本 mod **未实现 100% 完全翻译**，只对基础内容与大部分文本进行了翻译；少量动态拼接、罕见场景或
新版本新增内容可能仍为原文。

## Language Guides / 各语言使用说明

| Language | Patch folder | Guide |
|---|---|---|
| 简体中文 (CHS) | [`CHS/EarthX 2 Open Alpha/`](CHS/EarthX%202%20Open%20Alpha/) | [`docs/CHS-NOTES.md`](docs/CHS-NOTES.md) |
| 日本語 (JPN) | [`JPN/EarthX 2 Open Alpha/`](JPN/EarthX%202%20Open%20Alpha/) | [`docs/JPN-NOTES.md`](docs/JPN-NOTES.md) |
| Deutsch (DEU) | [`DEU/EarthX 2 Open Alpha/`](DEU/EarthX%202%20Open%20Alpha/) | [`docs/DEU-NOTES.md`](docs/DEU-NOTES.md) |

## How these mods were made / Request a language

I created the **CHS** mod end-to-end myself. After establishing the workflow, I used a coding
AI agent to complete the **German** and **Japanese** translations as a demonstration. I may
create and release more language mods in the future.

If you would like another language:
- Leave a comment in the **Issues**, or
- Download the source code and make it yourself — the project already contains all the
  necessary information. When doing so, **base your work on the CHS mod**, because the
  AI-automation documentation is written against the CHS version.

See [**AI-PATCH-GUIDE.md**](AI-PATCH-GUIDE.md) — a complete method guide written for AI coding
assistants (and humans): architecture, rule contracts, safety red lines, toolchain workflow
and an acceptance checklist.

## Install

1. Download the zip for your language from the [`release/`](release/) folder in this repository:
   `<LANG>-EarthX2OA<LANG>MOD_v<version>_full.zip` (recommended, self-contained) or
   `<LANG>-EarthX2OA<LANG>MOD_v<version>.zip` (patch only; BepInEx required).
   Replace `<LANG>` with the language code you want (e.g. `CHS` → `CHS-EarthX2OAChineseMOD_v1.0.0_full.zip`).
2. Extract/copy the contents of that language's `EarthX 2 Open Alpha` folder into the game
   root (the folder with `EarthX.exe`), merge/overwrite.
3. Launch the game.

Updates are manual overwrites. For uninstall / verify / FAQ, see that language's guide in
the table above.

> **Compatibility:** there are compatibility issues between different language mods. Before
> switching languages, make sure you have **removed the old mod** or performed a **complete
> switch** (clean re-install of one language only).

## About the project

- **3-layer patch**: official JSON localization (`StreamingAssets\Localization\<Lang>\`) +
  IL string rewriting (`StringPatch`, Harmony transpiler) + baked TextMeshPro text
  (`TextSweep`).
- **Embedded fonts**: CJK languages ship their OFL-licensed font inside their plugin `fonts\`
  folder (CHS = Source Han Sans CN, JPN = Source Han Sans JP; both SIL OFL 1.1) — no system
  font dependency, no copyright concern from proprietary CJK fonts. Exception: **DEU ships no
  font files** and relies on the game's embedded LiberationSans, which already covers German
  glyphs (ä/ö/ü/ß).

## Declarations / License

- Patch content (JSON / TSV / plugin source) is provided **as-is** for the EarthX 2 player
  community, free to use.
- **Embedded fonts: Source Han Sans (CN / JP, SIL OFL 1.1)** — freely redistributable with the
  patch; license text in `licenses\SourceHanSansCN-LICENSE.txt` (also shipped in each CJK
  language's `fonts\`).
- The **full package** bundles **unmodified** third-party binaries:
  - BepInEx 5.4.23.2 — LGPL-2.1 — https://github.com/BepInEx/BepInEx
  - UnityDoorstop 4.x (`winhttp.dll`) — LGPL-2.1 — https://github.com/NeighTools/UnityDoorstop
  - HarmonyX / MonoMod / Mono.Cecil — MIT (bundled within BepInEx core)
  - License texts and notices: `licenses\` folder.
- This project is **not affiliated with** the game's developers or publisher.

## Contributing

Issues and PRs welcome. To add or improve a language, read
[**AI-PATCH-GUIDE.md**](AI-PATCH-GUIDE.md) first.

## Acknowledgments

This project was developed with the assistance of **Opencode** combined with
**DeepseekV4Flash** and **GLM5.2**.

本项目使用 **Opencode** 搭配 **DeepseekV4Flash** 与 **GLM5.2** 进行协助开发。
