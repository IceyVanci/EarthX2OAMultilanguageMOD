# POR Patch em Português — Instruções

> **Aviso importante:** A pessoa que criou este mod não possui conhecimentos deste idioma.
> Todas as traduções foram feitas por **DeepseekV4FLASH** (IA).

Código do idioma: `POR` (Português) · Versão: veja `POR\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Portuguese\version.txt`

## Instalação

O conteúdo do patch está no diretório `POR\EarthX 2 Open Alpha\` do repositório, cuja estrutura é
idêntica à do diretório do jogo. **Copie todo o conteúdo da pasta `EarthX 2 Open Alpha` para o
diretório do jogo** (onde fica `EarthX.exe`) e sobrescreva/combine.

- Recomendado: `POR-EarthX2OAPortugueseMOD_v<Versão>_full.zip` (inclui o framework BepInEx, pronto para usar)
- Ou: `POR-EarthX2OAPortugueseMOD_v<Versão>.zip` (somente patch; BepInEx 5.4.x já deve estar instalado)

> **Nota de compatibilidade:** Existem problemas de compatibilidade entre os mods de idiomas
> diferentes. Antes de mudar de idioma, certifique-se de ter **removido o mod antigo** ou feito
> uma **troca completa** (reinstalação limpa de um único idioma).

## Escopo da tradução

- L1 localização JSON oficial: 64 arquivos (`EarthX_Data\StreamingAssets\Localization\Portuguese\`, ~1664 chaves)
- L2 regras de strings IL: 8 arquivos `pt-strings*.tsv` (591 linhas / 580 ORIG únicos)
- L3 regras de texto TMP incorporado: 2 arquivos `pt-baked*.tsv` (299 regras)
- Os nomes próprios (pessoas/empresas/universidades/institutos/satélites) são deliberadamente
  mantidos no idioma original.
- O patch **não está traduzido 100%**: alguns textos compostos dinamicamente, pouco frequentes ou
  adicionados em versões recentes podem continuar em inglês e serão completados progressivamente.

## Fonte tipográfica

Este patch utiliza a **fonte incorporada no jogo (LiberationSans)** e **não inclui arquivos de
fonte próprios**. Assim, não há dependência de fontes do sistema nem problemas de licença: os
caracteres acentuados do português (á/ã/ç/é/ê/í/ó/õ/ú) são totalmente representados pela fonte
do jogo.

## Desinstalação

- Exclua `BepInEx\plugins\EarthX2Portuguese\` e `EarthX_Data\StreamingAssets\Localization\Portuguese\`
- Se o BepInEx foi instalado apenas para o patch, você também pode excluir `BepInEx\`,
  `winhttp.dll`, `doorstop_config.ini`, `.doorstop_version`

## Segurança dos dados de salvamento (solução de problemas)

- O patch **não modifica os dados de salvamento**: instalar, atualizar ou desinstalar não afeta
  sua partida.
- Se o jogo apresentar erros após a instalação: **exclua a pasta do jogo** e descompacte
  novamente o jogo a partir do pacote de teste público (depois reaplique o patch conforme os
  passos de instalação).
- Os dados de salvamento não ficam na pasta do jogo; esse processo **não causa perda de dados
  de salvamento**.

## Atualização

Sobrescrita manual: baixe o novo zip e coloque o conteúdo de `EarthX 2 Open Alpha` sobre o
diretório do jogo. Se a descrição da versão mencionar "arquivos obsoletos", exclua-os.
Versão instalada: `version.txt`.