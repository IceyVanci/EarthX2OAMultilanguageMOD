# EarthX 2 Localização em Português (Brasil)

> **Aviso importante:** A pessoa que criou este mod não possui conhecimentos deste idioma.
> Todas as traduções foram feitas por **DeepseekV4FLASH** (IA).

Patch de tradução comunitária para o português do Brasil de **EarthX 2 Open Alpha (Windows)**,
construído com o mesmo mecanismo de três camadas do patch chinês (ver `AI-PATCH-GUIDE.md`) :

- **L1** `EarthX_Data/StreamingAssets/Localization/Portuguese/` - camada de localização JSON oficial (nenhum plugin necessário para carregá-la)
- **L2** `pt-strings*.tsv` - regras de correção de strings IL (`SCOPE^^^ORIG^^^TRANS`) aplicadas por um transpilador Harmony
- **L3** `pt-baked*.tsv` - regras de varredura do texto TMP incorporado (`ORIG^^^TRANS`)

**Fonte:** O português usa a SDF LiberationSans incorporada ao jogo (alfabeto latino, incluindo
caracteres acentuados e cedilha/circunflexo). Este plugin deliberadamente **não inclui arquivos
de fonte** e **não injeta fonte de fallback**.

## Instalação
1. Requer BepInEx 5.4.x (Unity Mono x64) já instalado no diretório do jogo.
2. Extraia este arquivo no diretório do jogo EarthX 2 (ao lado de `EarthX.exe`), combine/substitua.
3. Inicie o jogo - ele inicia automaticamente em português (`ForcePortuguese = true`).

## Desinstalação
- Exclua `BepInEx/plugins/EarthX2Portuguese/` e
  `EarthX_Data/StreamingAssets/Localization/Portuguese/`.
- Opcional: remova as entradas `Portuguese` de `Documents/EarthX 2/settings.json`
  reinstalando o idioma do jogo de sua escolha (os originais em inglês nunca são modificados).

## Observações
- GUID do plugin: `earthx2.portuguese.localization` (config: `BepInEx/config/earthx2.portuguese.localization.cfg`).
- Não ative `ForcePortuguese` e `ForceChinese` (se você também usar o patch chinês) ao mesmo
  tempo - o último plugin carregado vence a troca de idioma.