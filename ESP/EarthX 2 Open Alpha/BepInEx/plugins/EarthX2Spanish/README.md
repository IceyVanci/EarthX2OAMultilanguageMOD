# EarthX 2 Localización al Español

> **Aviso importante:** La persona que creó este mod no tiene conocimientos de este idioma.
> Todas las traducciones han sido realizadas por **DeepseekV4FLASH** (IA).

Parche de traducción comunitaria al español para **EarthX 2 Open Alpha (Windows)**, construido con
el mismo mecanismo de tres capas que el parche chino (ver `AI-PATCH-GUIDE.md`):

- **L1** `EarthX_Data/StreamingAssets/Localization/Spanish/` - capa oficial de localización JSON (no se necesita el plugin para cargarla)
- **L2** `es-strings*.tsv` - reglas de parcheo de cadenas IL (`SCOPE^^^ORIG^^^TRANS`) aplicadas por un transpilador de Harmony
- **L3** `es-baked*.tsv` - reglas de barrido de texto TMP incrustado (`ORIG^^^TRANS`)

**Fuente:** El español utiliza el SDF LiberationSans incrustado en el juego (escritura latina,
incluye tildes á/é/í/ó/ú, ñ y ü). Este plugin **no incluye archivos de fuente** y **no inyecta
ninguna fuente de reserva**.

## Instalación
1. Requiere BepInEx 5.4.x (Unity Mono x64) ya instalado en la raíz del juego.
2. Extrae este archivo en la raíz de EarthX 2 (junto a `EarthX.exe`), fusiona/reemplaza.
3. Ejecuta - el juego arranca en español automáticamente (`ForceSpanish = true`).

## Desinstalación
- Elimina `BepInEx/plugins/EarthX2Spanish/` y
  `EarthX_Data/StreamingAssets/Localization/Spanish/`.
- Opcional: elimina las entradas `Spanish` de `Documents/EarthX 2/settings.json`
  reinstalando el idioma del juego que prefieras (los originales en inglés nunca se modifican).

## Notas
- GUID del plugin: `earthx2.spanish.localization` (config: `BepInEx/config/earthx2.spanish.localization.cfg`).
- No actives `ForceSpanish` y `ForceChinese` (si también usas el parche chino) al mismo tiempo -
  gana el idioma del plugin cargado en último lugar.
