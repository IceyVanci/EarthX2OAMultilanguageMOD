# ESP Parche de Español — Instrucciones

> **Aviso importante:** La persona que creó este mod no tiene conocimientos de este idioma.
> Todas las traducciones fueron realizadas por **DeepseekV4FLASH** (IA).

Código de idioma: `ESP` (Español) · Versión: véase `ESP\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Spanish\version.txt`

## Instalación

El contenido del parche se encuentra en el directorio `ESP\EarthX 2 Open Alpha\` del repositorio,
cuyo diseño es idéntico al del directorio del juego. **Copia todo el contenido de la carpeta
`EarthX 2 Open Alpha` al directorio del juego** (donde se encuentra `EarthX.exe`) y sobrescribe/combina.

- Recomendado: `ESP-EarthX2OASpanishMOD_v<Versión>_full.zip` (incluye el framework BepInEx, listo para usar)
- O bien: `ESP-EarthX2OASpanishMOD_v<Versión>.zip` (solo parche; BepInEx 5.4.x debe estar ya instalado)

> **Nota de compatibilidad:** Existen problemas de compatibilidad entre los mods de distintos
> idiomas. Antes de cambiar de idioma, asegúrate de haber **eliminado el mod anterior** o de haber
> realizado un **cambio completo** (reinstalación limpia de un solo idioma).

## Alcance de la traducción

- L1 localización JSON oficial: 64 archivos (`EarthX_Data\StreamingAssets\Localization\Spanish\`, ~1665 claves)
- L2 reglas de cadenas IL: 8 archivos `es-strings*.tsv` (591 líneas / 580 ORIG únicos)
- L3 reglas de texto TMP incrustado: 2 archivos `es-baked*.tsv` (299 reglas)
- Los nombres propios (personas/empresas/universidades/institutos/satélites) se mantienen deliberadamente en el original.
- El parche **no está traducido al 100%**: algunos textos compuestos dinámicamente, poco frecuentes
  o añadidos en versiones recientes pueden seguir en inglés y se irán completando progresivamente.

## Fuente tipográfica

Este parche utiliza la **fuente incrustada en el juego (LiberationSans)** y **no incluye archivos
de fuente propios**. De este modo no hay dependencia de fuentes del sistema ni problemas de
licencia: los caracteres acentuados del español (á/é/í/ó/ú/ñ/ü) los representa por completo la
fuente del juego.

## Desinstalación

- Elimina `BepInEx\plugins\EarthX2Spanish\` y `EarthX_Data\StreamingAssets\Localization\Spanish\`
- Si BepInEx se instaló solo para el parche, también puedes eliminar `BepInEx\`, `winhttp.dll`,
  `doorstop_config.ini`, `.doorstop_version`

## Seguridad de los datos de guardado (solución de problemas)

- El parche **no modifica los datos de guardado**: instalar, actualizar o desinstalar no afecta a
  tu partida.
- Si el juego muestra errores tras la instalación: **borra la carpeta del juego** y vuelve a
  descomprimir el juego desde el paquete de prueba pública (después vuelve a aplicar el parche
  según los pasos de instalación).
- Los datos de guardado no se encuentran en la carpeta del juego; este proceso **no provoca
  pérdida de datos de guardado**.

## Actualización

Sobrescritura manual: descarga el nuevo zip y coloca el contenido de `EarthX 2 Open Alpha` sobre
el directorio del juego. Si la descripción de la versión menciona "archivos obsoletos", elimínalos.
Versión instalada: `version.txt`.
