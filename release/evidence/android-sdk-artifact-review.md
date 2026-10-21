# 로컬 SDK 검수 APK 독립 인계 검토

로컬 산출물 결속은 통과했다. 실제 SDK 검수와 교체 설치는 아직 미실행이며 추가 승인이 필요하다.

- 검토자: `/root/ui_qa`. 후보: `0823aaeeb104851b36fc025a74df50bc4b5b7a18`. 최신 중앙 SHA: a6dc6937f37eb5783ae249cfc315ba00f11fabfc.
- APK는142404359바이트이고 SHA256은 `95eb152e607ea8d5615e5bc3acc726e2dcdb743a0f7835d0a060aa66c2f139c0`다. 원래 signed CI AAB `8564479ee833a29e4c0c746427aeb157133c5ec474c0d09403eda17d0b7d9eb6`와 결속한다.
- 원래 root 검증5개는 DEX3개와 .so2개만 포함했다. 게임 에셋의 실제 위치는 `assetPackInstallTime/assets/`이며 base/assets 검사는 이를 빠뜨렸다. 원래 파일과 판정은 바꾸지 않았다.
- 독립 검토에서 게임 에셋622개, DEX3개, .so2개 모두 원본과 바이트 일치했다. APK assets/dexopt의 baseline.prof와 baseline.profm도 AAB BUNDLE-METADATA의 원문과 일치했다. 총629개, 누락/불일치/미설명 추가 항목0건이다.
- apksigner 검증 종료0, 업로드키 인증서77F926…1E16, zipalign16KB 검사 종료0. 독립 manifest dump로 package,1.0.0(1),target36,debuggable 속성 부재(기본 false), 운영 AdMob App ID를 확인했다. APK의 monetization JSON도 승인 값과 같고 설정 지문 `e7b3bd5e6713a049addf519eaf43ff05ae7f05630b40b80cd1f7a1ff355b634c`를 재계산해 일치했다.
- 로컬 DEX3개는 AAB와 같다. Play 생성본은DEX4개이며 LicenseClient/Pairip 표식이 있다. 로컬 APK에는 이 표식이 없었다. 보호된 Play APK를 패치한 결과가 아니며 이 APK의 로컬 결속 검토로 Play 설치 출처 보호 문제를 해결했다고 쓰지 않는다.

## 중앙 경로 판정

[최신 중앙 실행 환경](https://github.com/seorilabs/.github/blob/a6dc6937f37eb5783ae249cfc315ba00f11fabfc/docs/agent-governance/development-workflow.md#실행과-단계별-검사)은 Android android-device 실행에 테스트 채널 빌드 또는 같은 SHA 로컬 빌드를 허용한다. 이 파일은 보존한 같은 CI AAB를 로컬에서 포장했고 게임 코드/에셋/SDK 바이트와 승인 광고 설정을 보존했으므로 같은 SHA 로컬 빌드 경로에 맞는다.

실제 실행 시 sourceSha, target google-play, device, 빌드 문자열(로컬 포장/APK해시/업로드 인증서 명시), 설정 지문, 독립 실행자, 계획과 실제 시각, 격리 QA 데이터, 실제 필수 시나리오 결과를 남겨야 한다. 이는 기기 실행을 승인하거나 통과시키는 판정이 아니다. 서명이 다른 로컬 SDK 검수로 Play Store 설치, Play 자동 보호, 공개 채널 최소 실행을 대신하지 않는다. UMP와 광고의 기능 판정은 실제 실행 뒤에만 가능하다.

[Android 공식 bundletool 문서](https://developer.android.com/tools/bundletool)는 같은 AAB에서 로컬 APK를 생성해 테스트하는 방식과 universal 모드를 설명한다. 이 APK의 실제 포함 범위는 문구에 의존하지 않고 위629개 바이트 대조로 확인했다.

## 인계 파일

- all-payload-binding.json:629개 전체 해시와 로컬 결속 판정.
- payload-byte-review-base-only.json: 최초 독립5개 범위. payload-byte-review-full.json:622개 에셋을 포함한 중간 대조. 원래 root verification.json은 보존.
- apksigner-independent.txt, zipalign-independent.txt, manifest-independent.txt:독립 도구 원문. badging-independent-captured.txt는 도구 표시 한도로 잘렸음을 별도 표시하며 manifest 원문으로 결속했다.
- native-test-proposal.md와 JSON:별도 최대20분, 두 차례 서명 교체와 QA 데이터 삭제/원래 Play 서명 APK 복원을 포함한 추가 승인 제안.

검토 중 기기 조회, 설치, 실행, 삭제, 계정과 OS 설정 변경은0건이다. source HEAD와 작업 트리 clean을 유지한다.

전체629개 결속 보고서와 실행 제안의 보존본은 [Release 증거 ZIP](https://github.com/seoleeapps/keeum/releases/download/v1.0.0/native-wifi-and-sdk-proposal-1.0.0-evidence.zip)에 있다. 원시 기기 자료와 APK 본체는 비공개로 보존했다.
