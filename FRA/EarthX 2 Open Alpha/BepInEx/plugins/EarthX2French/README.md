# EarthX 2 Localisation Française

> **Avertissement important :** La personne qui a créé ce mod n'a pas de connaissances dans cette
> langue. Toutes les traductions ont été réalisées par **DeepseekV4FLASH** (IA).

Patch de traduction communautaire en français pour **EarthX 2 Open Alpha (Windows)**, construit
avec le même mécanisme à trois couches que le patch chinois (voir `AI-PATCH-GUIDE.md`) :

- **L1** `EarthX_Data/StreamingAssets/Localization/French/` - couche de localisation JSON officielle (aucun plugin nécessaire pour la charger)
- **L2** `fr-strings*.tsv` - règles de correction de chaînes IL (`SCOPE^^^ORIG^^^TRANS`) appliquées par un transpileur Harmony
- **L3** `fr-baked*.tsv` - règles de balayage du texte TMP incorporé (`ORIG^^^TRANS`)

**Police :** Le français utilise la SDF LiberationSans incorporée au jeu (alphabet latin, y compris
les caractères accentués et la cédille/les accents circonflexes). Ce plugin ne fournit volontairement
**aucun fichier de police** et n'injecte **aucune police de secours**.

## Installation
1. Nécessite BepInEx 5.4.x (Unity Mono x64) déjà installé dans le répertoire du jeu.
2. Extrayez cette archive dans le répertoire du jeu EarthX 2 (à côté de `EarthX.exe`),
   fusionnez/remplacez.
3. Lancez le jeu - il démarre automatiquement en français (`ForceFrench = true`).

## Désinstallation
- Supprimez `BepInEx/plugins/EarthX2French/` et
  `EarthX_Data/StreamingAssets/Localization/French/`.
- Facultatif : supprimez les entrées `French` de `Documents/EarthX 2/settings.json` en
  réinstallant la langue du jeu de votre choix (les originaux anglais ne sont jamais modifiés).

## Remarques
- GUID du plugin : `earthx2.french.localization` (config : `BepInEx/config/earthx2.french.localization.cfg`).
- N'activez pas `ForceFrench` et `ForceChinese` (si vous utilisez aussi le patch chinois) en même
  temps - le dernier plugin chargé gagne le changement de langue.