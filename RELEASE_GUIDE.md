# 发布指引（仓库文件分发，无 GitHub Releases）

> 分发方式：**zip + sha256 + `<LANG>-latest.json` 直接作为仓库文件提交**。各语言独立版本号，
> 用户可在仓库 `release\` 目录直接下载任意语言的任意版本。不创建 GitHub Releases、不打 tag。
>
> 前置：本目录（publish\）即仓库工作副本。首次发布前需自行完成：
> 1. 在 GitHub 创建仓库（建议名 `EarthX2OAMultilanguageMOD`，Public）
> 2. `git init` → 添加 remote → 提交 `CHS\`、`docs\`、`scripts\`、`licenses\`、`release\`、`VERSION`、
>    `CHANGELOG.md`、`README.md`、`README_CN.md`、`AI-PATCH-GUIDE.md`、`.gitignore`
>    （`_staging*`、`*.log`、`release\_build_report.txt` 已被 .gitignore 排除）
> 3. 将构建产物 `<LANG>-latest.json` 中的 `{REPO}` 替换为 `用户名/仓库名`
>    （`zipUrl`/`zipFullUrl`/`notes` 共 3 处）

## 每次发布的步骤

1. **构建**：`powershell -ExecutionPolicy Bypass -File scripts\build-artifacts.ps1 -All`
   - 批量构建全部已发布语言（CHS/DEU/JPN/ESP/KOR），各自套用 manifest 增量跳过逻辑；
     FRA/POR 代码未完成（`Released=$false`），发布时置 `$true` 后自动纳入 `-All`
   - 门禁不过会直接中止；通过后产出 `release\` 下双 zip + .sha256 + `<LANG>-latest.json` +
     `_build_report_<LANG>.txt` + `_manifest_<LANG>.json`
   - 仅构建单一语言：`-Lang ESP`（内容未变则 SKIP）；强制重建：`-Lang ESP -Force`
2. **回填 URL**：编辑 `release\<LANG>-latest.json`，把 3 处 `{REPO}` 替换为 `用户名/仓库名`
3. **提交**：`git add -A && git commit -m "release <LANG> v<版本>"`（`<LANG>\EarthX 2 Open Alpha\` 与 `release\` 已由构建刷新）
4. **推送**：`git push origin main`（无 tag、无 GitHub Release）

## 包内容速查（解耦：zip 只含本语言内容）

| 包 | 内容 | 适用 |
|---|---|---|
| `CHS-EarthX2OAChineseMOD_v<版本>.zip` | Chinese JSON ×64 + 插件（dll/tsv×10/README/src/version.txt/**fonts\×3**）+ docs\CHS-NOTES.md + licenses\SourceHanSansCN-LICENSE.txt | 已装 BepInEx 的玩家 |
| `CHS-EarthX2OAChineseMOD_v<版本>_full.zip` | 上述全部 + BepInEx 5.4.23.2 框架（winhttp.dll/doorstop_config.ini/.doorstop_version/BepInEx\core ×18）+ licenses\（LGPL-2.1 + NOTICE + 字体许可） | 全新玩家，解压即用 |
| `KOR-EarthX2OAKoreanMOD_v<版本>.zip` | Korean JSON ×64 + 插件（dll/tsv×10/README/src/version.txt/**fonts\×3**）+ docs\KOR-NOTES.md + licenses\SourceHanSansK-LICENSE.txt | 已装 BepInEx 的玩家（同 JPN 的 CJK 内嵌字体包） |
| `ESP-EarthX2OASpanishMOD_v<版本>.zip` | Spanish JSON ×64 + 插件（dll/tsv×10/README/src/version.txt，**无 fonts\**）+ docs\ESP-NOTES.md | 已装 BepInEx 的玩家（同 DEU 的无字体拉丁包） |
| `FRA-EarthX2OAFrenchMOD_v<版本>.zip` | French JSON ×64 + 插件（dll/tsv×10/README/src/version.txt，**无 fonts\**）+ docs\FRA-NOTES.md | 已装 BepInEx 的玩家（同 DEU/ESP 的无字体拉丁包；**待发布**） |
| `POR-EarthX2OAPortugueseMOD_v<版本>.zip` | Portuguese JSON ×64 + 插件（dll/tsv×10/README/src/version.txt，**无 fonts\**）+ docs\POR-NOTES.md | 已装 BepInEx 的玩家（同 DEU/ESP 的无字体拉丁包；**待发布**） |

> **共享文档（README.md/README_CN.md/AI-PATCH-GUIDE.md 及其他语言 NOTES）不再内嵌进语言 zip**，
> 只在仓库根分发（GitHub 直接可见）。zip 内容即 `<LANG>\EarthX 2 Open Alpha\` 目录内容 +
> 本语言 `docs\<LANG>-NOTES.md` +（字体语言）本语言字体许可；解压到游戏根目录即可。
> 玩家下载：仓库 → `release\` 目录 → 选择对应语言与版本的 zip。

## 升级机制

- 玩家：下载新 zip → 解压任意处 → 手动将 `EarthX 2 Open Alpha` 目录内容覆盖到游戏根目录
- 若文档标注"废弃文件"，按说明删除
- 备份位置：游戏根 `_chinapatch_backup\<时间戳>\`（玩家自行或旧版 update.ps1 遗留）

## 门禁基线（发布前必须全绿）

- strings 唯一 ORIG = 580；0 FAIL / 0 scope WARN / 0 CONFLICT；FLAG ∈ {DISPLAY,MIXED,AUTO}
- Chinese JSON = 64；staging 禁发文件（English/游戏 DLL/rules_backup/.DS_Store/日志）= 0
- baked 109 条 no-op 为已记录放行项（>120 则报警）
- 仓库树 = 工作区 MD5 对账：Chinese 64 + plugin（含 fonts\）全同步
- fonts\ 内嵌思源黑体（OFL 1.1）两字重随包（CHS/JPN/KOR）；`licenses\SourceHanSansCN-LICENSE.txt`
  或 `SourceHanSansK-LICENSE.txt` 按语言必备，两包均须随附；DEU/ESP/FRA/POR 无字体包禁止出现 `fonts\`
- **解耦约束**：patch zip 不得含根文档（README.md/README_CN.md/AI-PATCH-GUIDE.md）或他语言
  `docs\*`（仅本语言 `docs\<LANG>-NOTES.md`）；构建前 staging 断言
- **manifest**：`release\_manifest_<LANG>.json` 随包提交；增量构建据 `langHash`/`frameworkHash`
  决定 SKIP/BUILT；手动改动语言树后若未重打产物，`latest.json` 与 zip sha 可能失配——发布前以
  `build-artifacts.ps1 -All` 为准刷新
- `release\` 内 zip + sha256 + `<LANG>-latest.json` + `_manifest_<LANG>.json` 全部提交入库
