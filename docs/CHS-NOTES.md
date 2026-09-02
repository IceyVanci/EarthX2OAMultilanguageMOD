# CHS 简体中文补丁 — 说明

语言码：`CHS`（简体中文） · 版本：见 `CHS\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Chinese\version.txt`

## 安装

补丁内容位于仓库 `CHS\EarthX 2 Open Alpha\` 目录，其布局与游戏根目录一致。**将
`EarthX 2 Open Alpha` 目录内的全部内容复制到游戏根目录**（`EarthX.exe` 所在目录），合并/覆盖即可。

- 推荐直接下载 `CHS-EarthX2OAChineseMOD_v<版本>_full.zip`（内含 BepInEx 框架，解压即用）
- 或 `CHS-EarthX2OAChineseMOD_v<版本>.zip`（纯补丁，需先装 BepInEx 5.4.x）

> **兼容性提醒**：不同语言的 mod 之间存在兼容性问题，切换语言前请确保已经**清除了旧的 mod**
> 或进行了**完整切换**（只干净地重装一种语言）。

## 翻译范围

- 本补丁**未实现 100% 完全翻译**，只对基础内容与大部分文本进行了翻译。部分动态拼接、
  较少出现的场景或后续版本新增的内容可能仍显示为英文原文，后续版本将持续补全。

## 字体说明

本补丁内嵌 **思源黑体（Source Han Sans CN，SIL OFL 1.1）** Regular + Bold 两字重，
存放于 `BepInEx\plugins\EarthX2Chinese\fonts\`。内嵌字体随补丁分发，无需系统安装中文字体，
且完全规避微软雅黑等专有字体的版权再分发问题。许可全文见
`fonts\SourceHanSansCN-LICENSE.txt`（OFL 1.1）。

## 卸载

- 删除 `BepInEx\plugins\EarthX2Chinese\` 与 `EarthX_Data\StreamingAssets\Localization\Chinese\`
- 如 BepInEx 框架仅为汉化安装，可一并删除 `BepInEx\`、`winhttp.dll`、`doorstop_config.ini`、`.doorstop_version`

## 存档安全（故障恢复）

- 本补丁**没有修改存档的功能**：安装、升级、卸载都不会影响你的游戏存档。
- 若安装补丁后游戏出现错误，可**删除游戏文件夹**，然后重新从公开测试的压缩包解压游戏文件
  （重新解压后按安装步骤再次放入补丁即可）。
- 存档不随游戏文件夹被删除，此操作**不会导致存档丢失**。

## 升级

手动覆盖：下载新版 zip，将 `EarthX 2 Open Alpha` 目录内容覆盖到游戏根目录。
若 Release 说明标注"废弃文件"，按说明删除。已安装版本见 `version.txt`。
