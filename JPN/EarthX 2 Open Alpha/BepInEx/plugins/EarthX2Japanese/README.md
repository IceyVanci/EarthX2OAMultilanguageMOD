# EarthX 2 日本語化パッチ

> **重要な注意:** このModを作成した人物はこの言語を使用する能力を持っていません。
> すべての翻訳は **DeepseekV4FLASH**（AI）によって作成されました。

## 機能
- 全面日本語ローカライズ（64 ファイル / 1665 キー：アイテム、ビークル、契約、ストーリーニュース、
  建物・建物説明、マイルストーン、設定画面、ソーシャルフィードなど）
- BepInEx ベースの日本語ダイナミック回帰フォント（システムの日本語フォントを自動使用。
  ラテン文字はオリジナルの LiberationSans 字形を維持）
- 起動時に自動で日本語に登録・切り替え（オリジナルの English 言語には影響しません）
- **ハードコードテキスト日本語化（v1.0.0 追加）**：
  - `StringPatch`：JIT 段階で Harmony transpiler により Assembly-CSharp.dll の
    `ldstr` ハードコード文字列を書き換え（ルールは `ja-strings*.tsv`、メソッドスコープで正確に一致。
    プレイヤーに見えるテキストのみ変更し、アセット ID / アニメーション名 / 開発者コンソールは変更しない）
  - `TextSweep`：実行時に TMP コンポーネントを走査し、シーン / プレハブに焼き込まれたテキストを置換
    （ルールは `ja-baked*.tsv`）

## ファイル構成
```
EarthX 2 Open Alpha (Windows)\
├─ BepInEx\
│  ├─ core\                          （BepInEx フレームワーク、必須）
│  └─ plugins\EarthX2Japanese\
│     ├─ EarthX2Japanese.dll          （日本語化プラグイン v1.0.0）
│     ├─ ja-strings*.tsv              （IL ハードコード文字列ルール：SCOPE^^^ORIG^^^TRANS）
│     ├─ ja-baked*.tsv                （焼き込み TMP テキストルール：ORIG^^^TRANS）
│     ├─ fonts\                       （内蔵日本語フォント Source Han Sans JP）
│     └─ README.md
├─ EarthX_Data\StreamingAssets\Localization\
│  ├─ English\                       （オリジナル英語、未変更）
│  └─ Japanese\                      （日本語翻訳ファイル）
├─ winhttp.dll                       （BepInEx ローダー、必須）
└─ doorstop_config.ini               （BepInEx 設定、必須）
```

## 使い方
`EarthX.exe` を実行するだけです。ゲームは自動的に日本語で起動します。

## アンインストール / 英語に戻す
`BepInEx\plugins\EarthX2Japanese` フォルダを削除すれば英語に戻ります
（または BepInEx 設定の `ForceJapanese` を false に設定）。
日本語化を完全に除去する場合：`winhttp.dll`、`doorstop_config.ini`、`.doorstop_version`、`BepInEx` フォルダを削除してください。

## プラグイン設定
`BepInEx\cfg\earthx2.japanese.localization.cfg`
- ForceJapanese          = true   起動時に日本語へ切り替え
- AddFontFallback        = true   日本語回帰フォントを注入
- TranslateHardcodedText = true   ハードコードテキスト日本語化を有効化（StringPatch + TextSweep）

## 日本語化対応状況（v1.0.0）
- JSON 公式ローカライズ：1665 キーを全て日本語化（キーセット / プレースホルダ / リッチテキストが英語版と一致することを検証済み）
- IL ハードコード文字列：572 ルール、スキャン済みで Harmony パッチ **252 メソッド**
  （ルール原文は DLL と一字ずつ照合済み；スコープはプレイヤーに見えるメソッドに限定）
- TMP 焼き込みテキスト：299 ルール（メインメニュー、HUD、イベントパネルなどを含む）
- 既知の未対応：ごく一部のアニメーションイベント名、開発者コンソール文字列、一部のセーブデータ内テキストは英語のまま；
  一部の焼き込み長文（クレジット / イベント詳細）は原文修正後に反映

## 技術説明
- プラグインは Harmony 後置 `AssetsManager.PrepareAssets` で以下を実装：
  1) `Font.Internal_CreateFontFromPath` でシステム / 内蔵 CJK フォントを読み込み、
     `TMP_FontAsset.CreateFontAsset` でダイナミック SDF フォントを生成し、
     `TMP_Settings.fallbackFontAssets` に登録（回帰フォント資産名 `ChineseFallback` / `ChineseFallbackBold` は
     技術上の重複登録防止のため固定名を使用）；
  2) `LocalizationAsset`（Id=Japanese、`StreamingAssets/Localization/Japanese/*.json` を読み込み）を構築し、
     `AssetsManager.Assets` に登録して `Settings.Langauge = "Japanese"` に設定；
  3) `StringPatch`：Mono.Cecil で Assembly-CSharp.dll 内の対象文字列を参照するメソッドを走査し、
     反射解析後に Harmony transpiler で `ldstr` オペランドを書き換え；
  4) `TextSweep`：`TMP_Text.set_text` の前置 + `OnEnable` の後置をパッチし、
     `SceneManager.sceneLoaded` を購読して全シーンを走査。
- ゲーム更新でキー値が変わった場合：English と Japanese フォルダを比較し、追加キーを翻訳するだけで、
  フレームワークの再適合は不要です。
