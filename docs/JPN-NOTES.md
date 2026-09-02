# JPN 日本語化パッチ — 説明

> **重要な注意:** このModを作成した人物はこの言語を使用する能力を持っていません。
> すべての翻訳は **DeepseekV4FLASH**（AI）によって作成されました。

言語コード：`JPN`（日本語）· バージョン：`JPN\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Japanese\version.txt` 参照

## インストール

パッチ内容はリポジトリ `JPN\EarthX 2 Open Alpha\` ディレクトリにあり、そのレイアウトはゲームルートと一致します。
**`EarthX 2 Open Alpha` ディレクトリ内の全内容をゲームルート**（`EarthX.exe` のあるディレクトリ）にコピーし、上書きマージしてください。

- 推奨：`JPN-EarthX2OAJapaneseMOD_v<バージョン>_full.zip`（BepInEx フレームワーク同梱、解凍後すぐに使用可能）
- または `JPN-EarthX2OAJapaneseMOD_v<バージョン>.zip`（パッチのみ。先に BepInEx 5.4.x のインストールが必要）

> **互換性の注意:** 異なる言語のMOD間には互換性の問題があります。言語を切り替える前に、
> **古いMODを削除した**か、**完全な切り替え**（1つの言語だけをクリーンに再インストール）を
> 行ったことを確認してください。

## フォントについて

本パッチには **Source Han Sans JP（思源黑体 日本語版、SIL OFL 1.1）** の Regular + Bold の 2 ウェイトが同梱され、
`BepInEx\plugins\EarthX2Japanese\fonts\` に格納されています。同梱フォントはパッチと一緒に配布され、
システムへの日本語フォントのインストールは不要です。ライセンス全文は
`fonts\SourceHanSansJP-LICENSE.txt`（OFL 1.1）を参照してください。

## アンインストール

- `BepInEx\plugins\EarthX2Japanese\` と `EarthX_Data\StreamingAssets\Localization\Japanese\` を削除
- BepInEx フレームワークをパッチ専用に導入した場合は、併せて `BepInEx\`、`winhttp.dll`、`doorstop_config.ini`、`.doorstop_version` を削除

## セーブデータの安全性（障害復旧）

- 本パッチは**セーブデータを変更しません**：インストール・アップグレード・アンインストールしてもゲームのセーブデータに影響はありません。
- パッチ導入後にゲームでエラーが発生した場合は、**ゲームフォルダを削除**し、公開テスト用圧縮パッケージからゲームファイルを再解凍してください（再解凍後、手順に従ってパッチを再配置）。
- セーブデータはゲームフォルダの削除では失われません。この操作で**セーブデータが失われることはありません**。

## アップグレード

手動で上書き：新しいバージョンの zip をダウンロードし、`EarthX 2 Open Alpha` ディレクトリの内容をゲームルートに上書きしてください。
Release の説明に「廃止ファイル」の記載がある場合は、その指示に従って削除してください。インストール済みバージョンは `version.txt` で確認できます。
