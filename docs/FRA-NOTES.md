# FRA Patch Français — Instructions

> **Avertissement important :** La personne qui a créé ce mod n'a pas de connaissances dans cette
> langue. Toutes les traductions ont été réalisées par **DeepseekV4FLASH** (IA).

Code de langue : `FRA` (Français) · Version : voir `FRA\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2French\version.txt`

## Installation

Le contenu du patch se trouve dans le répertoire `FRA\EarthX 2 Open Alpha\` du dépôt, dont la
disposition est identique à celle du répertoire du jeu. **Copiez tout le contenu du dossier
`EarthX 2 Open Alpha` dans le répertoire du jeu** (là où se trouve `EarthX.exe`) et
écrasez/fusionnez.

- Recommandé : `FRA-EarthX2OAFrenchMOD_v<Version>_full.zip` (inclut le framework BepInEx, prêt à l'emploi)
- Ou : `FRA-EarthX2OAFrenchMOD_v<Version>.zip` (patch seul ; BepInEx 5.4.x doit déjà être installé)

> **Note de compatibilité :** Il existe des problèmes de compatibilité entre les mods de différentes
> langues. Avant de changer de langue, assurez-vous d'avoir **supprimé l'ancien mod** ou effectué un
> **changement complet** (réinstallation propre d'une seule langue).

## Portée de la traduction

- L1 localisation JSON officielle : 64 fichiers (`EarthX_Data\StreamingAssets\Localization\French\`, ~1664 clés)
- L2 règles de chaînes IL : 8 fichiers `fr-strings*.tsv` (591 lignes / 580 ORIG uniques)
- L3 règles de texte TMP incorporé : 2 fichiers `fr-baked*.tsv` (299 règles)
- Les noms propres (personnes/entreprises/universités/instituts/satellites) sont délibérément
  conservés dans la langue d'origine.
- Le patch **n'est pas traduit à 100 %** : certains textes composés dynamiquement, peu fréquents ou
  ajoutés dans des versions récentes peuvent rester en anglais et seront complétés progressivement.

## Police de caractères

Ce patch utilise la **police incorporée au jeu (LiberationSans)** et **n'inclut aucun fichier de
police propre**. Il n'y a donc ni dépendance aux polices du système ni problème de licence : les
caractères accentués du français (é/è/ê/à/ù/ç/î/ô/œ) sont entièrement représentés par la police
du jeu.

## Désinstallation

- Supprimez `BepInEx\plugins\EarthX2French\` et `EarthX_Data\StreamingAssets\Localization\French\`
- Si BepInEx n'a été installé que pour le patch, vous pouvez également supprimer `BepInEx\`,
  `winhttp.dll`, `doorstop_config.ini`, `.doorstop_version`

## Sécurité des données de sauvegarde (dépannage)

- Le patch **ne modifie pas les données de sauvegarde** : installer, mettre à jour ou désinstaller
  n'affecte pas votre partie.
- Si le jeu affiche des erreurs après l'installation : **supprimez le dossier du jeu** et
  décompressez à nouveau le jeu depuis le paquet de test public (puis réappliquez le patch selon
  les étapes d'installation).
- Les données de sauvegarde ne se trouvent pas dans le dossier du jeu ; ce processus **n'entraîne
  aucune perte de données de sauvegarde**.

## Mise à jour

Écrasement manuel : téléchargez le nouveau zip et placez le contenu de `EarthX 2 Open Alpha` sur
le répertoire du jeu. Si la description de la version mentionne des « fichiers obsolètes »,
supprimez-les. Version installée : `version.txt`.