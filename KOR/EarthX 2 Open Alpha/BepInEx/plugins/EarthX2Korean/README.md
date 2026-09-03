# EarthX 2 한국어 패치

> **중요한 안내:** 이 모드를 제작한 사람은 이 언어를 구사하지 못합니다.
> 모든 번역은 **DeepseekV4FLASH**(AI)에 의해 제작되었습니다.

## 기능
- 전면 한국어 로컬라이제이션 (64 파일 / 1665 키: 아이템, 차량, 계약, 스토리 뉴스,
  건물·건물 설명, 마일스톤, 설정 화면, 소셜 피드 등)
- BepInEx 기반 한국어 동적 폴백 폰트 (내장 Source Han Sans K 우선, 시스템 한글 폰트 자동 사용.
  라틴 문자는 원본 LiberationSans 글리프 유지)
- 시작 시 자동으로 한국어 등록·전환 (원본 English 언어에는 영향 없음)
- **하드코딩 텍스트 한국어화 (v1.0.0 추가)**:
  - `StringPatch`: JIT 단계에서 Harmony transpiler로 Assembly-CSharp.dll의
    `ldstr` 하드코딩 문자열을 재작성 (규칙은 `ko-strings*.tsv`, 메서드 스코프로 정확히 일치.
    플레이어에게 보이는 텍스트만 변경하며, 에셋 ID / 애니메이션 이름 / 개발자 콘솔은 변경하지 않음)
  - `TextSweep`: 실행 시 TMP 컴포넌트를 순회하여 씬 / 프리팹에 구워진 텍스트를 치환
    (규칙은 `ko-baked*.tsv`)

## 파일 구성
```
EarthX 2 Open Alpha (Windows)\
├─ BepInEx\
│  ├─ core\                          (BepInEx 프레임워크, 필수)
│  └─ plugins\EarthX2Korean\
│     ├─ EarthX2Korean.dll           (한국어화 플러그인 v1.0.0)
│     ├─ ko-strings*.tsv             (IL 하드코딩 문자열 규칙: SCOPE^^^ORIG^^^TRANS)
│     ├─ ko-baked*.tsv               (구워진 TMP 텍스트 규칙: ORIG^^^TRANS)
│     ├─ fonts\                      (내장 한글 폰트 Source Han Sans K + 라이선스)
│     └─ README.md
├─ EarthX_Data\StreamingAssets\Localization\
│  ├─ English\                       (원본 영어, 변경 없음)
│  └─ Korean\                        (한국어 번역 파일)
├─ winhttp.dll                       (BepInEx 로더, 필수)
└─ doorstop_config.ini               (BepInEx 설정, 필수)
```

## 사용법
`EarthX.exe`를 실행하기만 하면 됩니다. 게임이 자동으로 한국어로 시작됩니다.

## 삭제 / 영어로 되돌리기
`BepInEx\plugins\EarthX2Korean` 폴더를 삭제하면 영어로 돌아갑니다
(또는 BepInEx 설정의 `ForceKorean`을 false로 설정).
한국어화를 완전히 제거할 경우: `winhttp.dll`, `doorstop_config.ini`, `.doorstop_version`, `BepInEx` 폴더를 삭제하세요.

## 플러그인 설정
`BepInEx\cfg\earthx2.korean.localization.cfg`
- ForceKorean           = true   시작 시 한국어로 전환
- AddFontFallback       = true   한국어 폴백 폰트 주입
- TranslateHardcodedText = true  하드코딩 텍스트 한국어화 활성화 (StringPatch + TextSweep)

## 한국어화 적용 범위 (v1.0.0)
- JSON 공식 로컬라이제이션: 1665 키 전부 한국어화 (키 세트 / 플레이스홀더 / 리치 텍스트가 영어판과 일치함을 검증 완료)
- IL 하드코딩 문자열: 572 규칙, 스캔 완료 및 Harmony 패치 **252 메서드**
  (규칙 원문은 DLL과 한 글자씩 대조 완료; 스코프는 플레이어에게 보이는 메서드로 한정)
- TMP 구워진 텍스트: 299 규칙 (메인 메뉴, HUD, 이벤트 패널 등 포함)
- 알려진 미지원: 일부 애니메이션 이벤트 이름, 개발자 콘솔 문자열, 일부 세이브 데이터 내 텍스트는 영어로 남음;
  일부 구워진 장문(크레딧 / 이벤트 상세)은 원문 수정 후 반영

## 기술 설명
- 플러그인은 Harmony 후행 `AssetsManager.PrepareAssets`에서 다음을 구현:
  1) `Font.Internal_CreateFontFromPath`로 내장 / 시스템 한글 폰트를 로드하고,
     `TMP_FontAsset.CreateFontAsset`로 동적 SDF 폰트를 생성하여
     `TMP_Settings.fallbackFontAssets`에 등록 (폴백 폰트 에셋 이름 `ChineseFallback` / `ChineseFallbackBold`는
     기술상 중복 등록 방지를 위해 고정 이름 사용);
  2) `LocalizationAsset`(Id=Korean, `StreamingAssets/Localization/Korean/*.json` 로드)을 구성하고,
     `AssetsManager.Assets`에 등록한 뒤 `Settings.Langauge = "Korean"`으로 설정;
  3) `StringPatch`: Mono.Cecil로 Assembly-CSharp.dll 내 대상 문자열을 참조하는 메서드를 스캔하고,
     리플렉션 분석 후 Harmony transpiler로 `ldstr` 오퍼랜드를 재작성;
  4) `TextSweep`: `TMP_Text.set_text`의 전위 + `OnEnable`의 후위를 패치하고,
     `SceneManager.sceneLoaded`를 구독하여 전체 씬을 순회.
- 게임 업데이트로 키 값이 바뀐 경우: English와 Korean 폴더를 비교하여 추가 키를 번역하면 되며,
  프레임워크 재적용은 필요 없습니다.
