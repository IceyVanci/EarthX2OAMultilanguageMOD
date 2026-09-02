# DEU Deutsch-Patch — Anleitung

> **Wichtiger Hinweis:** Die Person, die dieses Mod erstellt hat, besitzt keine Fähigkeiten in
> dieser Sprache. Alle Übersetzungen wurden von **DeepseekV4FLASH** (KI) erstellt.

Sprachcode: `DEU` (Deutsch) · Version: siehe `DEU\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2German\version.txt`

## Installation

Der Patch befindet sich im Verzeichnis `DEU\EarthX 2 Open Alpha\` des Repos, dessen Layout mit
dem Spielverzeichnis identisch ist. **Kopiere den gesamten Inhalt des Ordners
`EarthX 2 Open Alpha` in das Spielverzeichnis** (in dem sich `EarthX.exe` befindet) und
überschreibe/merge ihn.

- Empfohlen: `DEU-EarthX2OAGermanMOD_v<Version>_full.zip` (enthält das BepInEx-Framework, sofort nutzbar)
- Oder: `DEU-EarthX2OAGermanMOD_v<Version>.zip` (nur Patch; BepInEx 5.4.x muss bereits installiert sein)

> **Kompatibilitätshinweis:** Es gibt Kompatibilitätsprobleme zwischen den Mods verschiedener
> Sprachen. Stelle vor dem Sprachwechsel sicher, dass du den **alten Mod entfernt** oder einen
> **vollständigen Wechsel** (saubere Neuinstallation nur einer Sprache) durchgeführt hast.

## Übersetzungsumfang

- L1 offizielle JSON-Lokalisierung: 64 Dateien (`EarthX_Data\StreamingAssets\Localization\German\`, ~1665 Keys)
- L2 IL-Stringregeln: 8 Dateien `de-strings*.tsv` (591 Zeilen / 580 eindeutige ORIG)
- L3 TMP-Backttextregeln: 2 Dateien `de-baked*.tsv` (299 Regeln)
- Eigennamen (Personen-/Firmen-/Universitäts-/Instituts-/Satellitennamen) bleiben bewusst im Original.
- Der Patch ist **nicht 100% übersetzt**: Einzelne dynamisch zusammengesetzte, seltene oder in
  neueren Versionen ergänzte Texte können weiterhin Englisch sein und werden nach und nach ergänzt.

## Schriftart

Dieser Patch nutzt die **im Spiel eingebettete Schrift (LiberationSans)** und liefert **keine
eigenen Font-Dateien** mit. Dadurch gibt es weder eine System-Font-Abhängigkeit noch
Lizenzprobleme – deutsche Umlaute (ä/ö/ü/ß) werden von der Spielschrift vollständig dargestellt.

## Deinstallation

- Lösche `BepInEx\plugins\EarthX2German\` und `EarthX_Data\StreamingAssets\Localization\German\`
- Wenn BepInEx nur für den Patch installiert wurde, kann zusätzlich `BepInEx\`, `winhttp.dll`,
  `doorstop_config.ini`, `.doorstop_version` gelöscht werden

## Speicherdaten-Sicherheit (Fehlerbehebung)

- Der Patch **ändert keine Speicherdaten**: Installation, Upgrade und Deinstallation wirken sich
  nicht auf deinen Spielstand aus.
- Falls das Spiel nach der Installation Fehler zeigt: **Spielordner löschen** und das Spiel neu
  aus dem öffentlichen Testpaket entpacken (danach den Patch gemäß Installationsschritten erneut
  einspielen).
- Speicherdaten liegen nicht im Spielordner; dieser Vorgang **führt nicht zu Speicherdatenverlust**.

## Upgrade

Manuell überschreiben: Neue Zip herunterladen, den Inhalt von `EarthX 2 Open Alpha` über das
Spielverzeichnis legen. Wenn die Release-Beschreibung „veraltete Dateien" nennt, diese löschen.
Installierte Version: `version.txt`.
