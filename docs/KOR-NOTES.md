# KOR 한국어 패치 — 안내

> **중요한 안내:** 이 모드를 제작한 사람은 이 언어를 구사하지 못합니다.
> 모든 번역은 **DeepseekV4FLASH**(AI)에 의해 제작되었습니다.

언어 코드: `KOR`(한국어) · 버전: `KOR\EarthX 2 Open Alpha\BepInEx\plugins\EarthX2Korean\version.txt` 참조

## 설치

패치 내용은 저장소의 `KOR\EarthX 2 Open Alpha\` 디렉터리에 있으며, 그 구조는 게임 루트와 동일합니다.
**`EarthX 2 Open Alpha` 디렉터리 안의 전체 내용을 게임 루트**(`EarthX.exe`가 있는 디렉터리)에 복사하고,
덮어쓰기/병합해 주세요.

- 권장: `KOR-EarthX2OAKoreanMOD_v<버전>_full.zip` (BepInEx 프레임워크 포함, 압축 해제 후 바로 사용 가능)
- 또는 `KOR-EarthX2OAKoreanMOD_v<버전>.zip` (패치만 포함. 먼저 BepInEx 5.4.x를 설치해야 함)

> **호환성 주의:** 다른 언어의 MOD 사이에는 호환성 문제가 있습니다. 언어를 전환하기 전에
> **이전 MOD를 제거**했거나 **완전한 전환**(한 언어만 깨끗하게 재설치)을 했는지 확인해 주세요.

## 번역 범위

- L1 공식 JSON 로컬라이제이션: 64개 파일 (`EarthX_Data\StreamingAssets\Localization\Korean\`, ~1665키)
- L2 IL 문자열 규칙: 8개 파일 `ko-strings*.tsv` (591줄 / 고유 ORIG 580개)
- L3 TMP 구워진 텍스트 규칙: 2개 파일 `ko-baked*.tsv` (299개 규칙)
- 고유명사(사람/기업/대학/연구소/위성 이름)는 의도적으로 원문을 유지합니다.
- 이 패치는 **100% 번역된 것은 아닙니다**: 동적으로 조합되거나 드물게 사용되거나 최신 버전에서
  추가된 일부 텍스트는 계속 영어로 표시될 수 있으며, 점진적으로 보완됩니다.

## 폰트에 관하여

이 패치에는 **Source Han Sans K(본고딕/思源黑體 한국어판, SIL OFL 1.1)** Regular + Bold의
두 가지 웨이트가 포함되어 있으며, `BepInEx\plugins\EarthX2Korean\fonts\`에 들어 있습니다.
동봉된 폰트는 패치와 함께 배포되므로 시스템에 한국어 폰트를 별도로 설치할 필요가 없습니다.
전체 라이선스 문구는 `fonts\SourceHanSansK-LICENSE.txt`(OFL 1.1)를 참조하세요.

## 제거(언어 전환/삭제)

- `BepInEx\plugins\EarthX2Korean\`와 `EarthX_Data\StreamingAssets\Localization\Korean\`을 삭제
- BepInEx 프레임워크를 패치 전용으로 설치한 경우, 함께 `BepInEx\`, `winhttp.dll`,
  `doorstop_config.ini`, `.doorstop_version`을 삭제

## 세이브 데이터 안전성 (장애 복구)

- 이 패치는 **세이브 데이터를 변경하지 않습니다**: 설치·업그레이드·제거해도 게임 세이브에
  영향이 없습니다.
- 패치 적용 후 게임에 오류가 발생하면 **게임 폴더를 삭제**하고 공개 테스트 압축 패키지에서
  게임 파일을 다시 풀어 주세요(이후 안내된 설치 절차에 따라 패치를 다시 배치).
- 세이브 데이터는 게임 폴더에 있지 않으며, 이 과정으로 **세이브 데이터가 손실되지 않습니다**.

## 업그레이드

수동 덮어쓰기: 새 버전의 zip을 다운로드하고 `EarthX 2 Open Alpha` 디렉터리의 내용을 게임 루트에
덮어쓰세요. 릴리스 설명에 "폐기 파일" 언급이 있으면 해당 지침에 따라 삭제하세요.
설치된 버전은 `version.txt`에서 확인할 수 있습니다.
