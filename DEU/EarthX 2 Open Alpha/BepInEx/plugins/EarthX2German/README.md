# EarthX 2 German Localization

> **Wichtiger Hinweis:** Die Person, die dieses Mod erstellt hat, besitzt keine Fähigkeiten in
> dieser Sprache. Alle Übersetzungen wurden von **DeepseekV4FLASH** (KI) erstellt.

Community German translation patch for **EarthX 2 Open Alpha (Windows)**, built with the
same three-layer mechanism as the Chinese patch (see `AI-PATCH-GUIDE.md`):

- **L1** `EarthX_Data/StreamingAssets/Localization/German/` - official JSON localization layer (no plugin needed to load it)
- **L2** `de-strings*.tsv` - IL string-patch rules (`SCOPE^^^ORIG^^^TRANS`) applied by a Harmony transpiler
- **L3** `de-baked*.tsv` - baked TMP text sweep rules (`ORIG^^^TRANS`)

**Font:** German uses the game-embedded LiberationSans SDF (Latin script incl. a/o/u umlauts and
eszett). This plugin intentionally ships **no font files** and injects **no fallback font**.

## Install
1. Requires BepInEx 5.4.x (Unity Mono x64) already installed in the game root.
2. Extract this archive into the EarthX 2 game root (next to `EarthX.exe`), merge/replace.
3. Launch - the game starts in German automatically (`ForceGerman = true`).

## Uninstall
- Delete `BepInEx/plugins/EarthX2German/` and
  `EarthX_Data/StreamingAssets/Localization/German/`.
- Optional: remove the `German` entries from `Documents/EarthX 2/settings.json` by
  reinstalling the game language of your choice (the English originals are never modified).

## Notes
- Plugin GUID: `earthx2.german.localization` (config: `BepInEx/config/earthx2.german.localization.cfg`).
- Do not enable `ForceGerman` and `ForceChinese` (if you also use the Chinese patch) at the
  same time - the plugin loaded last wins the language switch.