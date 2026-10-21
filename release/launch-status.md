# Google Play 첫 출시 상태

2026-10-21 20:18 KST. **내부 테스트 활성, 실제 광고 검수 차단** 상태다. 공개 목표는 Seolee Apps의 한국 전체 배포이며 심사는 아직 제출하지 않았다.

| 항목 | 확인 상태 |
| --- | --- |
| 출시 후보 | v1.0.0, code 1, 0823aaeeb104851b36fc025a74df50bc4b5b7a18 |
| 제품과 소유 | 내 새끼 대학 보내기, com.seorilabs.keeum, Seolee Apps 개인 계정 |
| 콘텐츠 | 활동 24, 이벤트 48, 엔딩 40, 전용 CG 12 |
| 개발 검수 | 같은 후보 CI, 독립 코어와 UI 3회 통과. 대표 UI48턴과 40종 코어 경로를 구분 |
| 서명 | 승인 후 앱 전용 업로드 키 생성, 로컬과 BeeStation 복원 검증, GitHub 실행 복제본과 Play 배포 서명 대조 완료 |
| AAB | CI 서명 빌드 성공. 실제 API 36,debug=false,운영 광고ID,16KB ELF 2개와 재생성 원본 제외 확인 |
| 내부 테스트 | 1.0.0(1) completed. 기존 내부테스트 그룹 2명 선택과 저장 재조회, 트랙 활성 |
| 실제 Android 광고 | 잔여 데이터 삭제와 Play 생성 APK 설치 완료. 실제 내부 테스트 참여 뒤에도 Play 다운로드는 항목 없음, 앱은 설치 출처 보호 종료. 실제 UMP, GMA SDK와 광고 통과0건 |
| 추가 기기 승인 | 기존 Wi-Fi 확인과 재연결 승인 후 정상 연결을 확인해 설정 변경0건. 기기 구간 종료. 같은 AAB의 로컬 검수 APK 교체와 추가20분은 별도 승인 대기 |
| 스토어 등록 | 문구, 아이콘, 기능 그래픽과 실제 화면 3장 readback 일치. 개인정보와 광고, 데이터 보안, IARC와 광고ID 선언 저장. 주의 필요 0개 |
| 실제 한국 IARC 결과 | 전체이용가. 목표 15세와 구분, 최종 심사 결과 확인 전 |
| AdMob | 앱과 광고 단위 2개 등록, keeum 전용 GDPR 메시지 게시. 스토어 검색 결과 없음, 검토 필요와 게재 제한 상태. 실제 게재 통과 아님 |
| 심사, 승인, 공개 | 미진행 |
| 리텐션 | 미측정 |

[설계와 승인](../docs/design/2026-10-21-google-play-launch/design.md), [QA 계획](../docs/game-design/07-qa-launch-plan.md), [실행 이슈 #60](https://github.com/seoleeapps/keeum/issues/60), [기계 판독 근거](evidence/google-play-1.0.0.json).

[태그 발급](https://github.com/seoleeapps/keeum/actions/runs/39521283892), [서명 빌드](https://github.com/seoleeapps/keeum/actions/runs/39521374449), [같은 후보 E2E](https://github.com/seoleeapps/keeum/actions/runs/39469353484), [Release와 증거](https://github.com/seoleeapps/keeum/releases/tag/v1.0.0).

AAB SHA-256은 `8564479ee833a29e4c0c746427aeb157133c5ec474c0d09403eda17d0b7d9eb6`이다. Play API가 같은 해시와 versionCode 1, internal completed를 반환했다. Play가 생성한 APK도 버전과 배포 인증서가 일치했다. adb 설치를 Play Store 설치로 주장하지 않는다.

한국 공개, 업로드 키 생성과 등록, Android 한 대 총25분은 이미 승인받았다. [기존 설치 차단](evidence/android-native-1.0.0-blocked.md)에 이어 [이번 실행](evidence/android-native-1.0.0-wifi-review.md)은 19:56:22부터 20:07:21 KST까지658.989초였다. 이전 두 구간492.131초를 유지해 누적1151.120초다. 공개 후5분을 예약하면 기존25분 안의 잔여 상한은48.880초다. 종료한 구간을 재시작하거나 대기를 빼지 않는다.

Wi-Fi는 기존부터 정상 연결된 상태였고 설정 변경은0건이다. 앞선 일반형 테스트 URL 사용은 잘못된 확인 경로였다. Console의 실제 [내부 테스트 초대 링크](https://play.google.com/apps/internaltest/4701172449333307182)로 수정해 같은 기존 테스터가 초대를 수락했다. 실제 다운로드 링크도 항목 없음으로 막혔고, 참여 후 앱을 한 번 재실행해도 설치 출처 보호 종료가 이어졌다. native Play의 현재 선택 계정은 확인하지 못했으며 원인을 계정이나 네트워크 문제로 단정하지 않는다.

같은 signed AAB에서 [로컬 SDK 검수 APK](evidence/android-sdk-artifact-review.md)를 준비했다. 게임 에셋622개, DEX3개, 라이브러리2개, 프로필2개 총629개가 원본과 바이트 일치한다. 원래5개 검사는 DEX와 라이브러리만 포함했으므로 독립 검수에서 에셋 전체 대조를 보완했다. APK는 앱 전용 업로드 키로 서명했고 아직 설치하지 않았다. 실제 SDK 실행과 Play 설치, 보호 동작의 통과 근거가 아니다.

[추가 검수 제안](evidence/android-sdk-test-proposal.md)은 같은 기기에서 최대20분, 현재 Play 서명 QA 설치본 삭제와 검수 APK 설치, 실제 SDK 검사, 원래 Play 서명 APK 복원까지 포함한다. 두 서명 교체에서 해당 패키지의 QA 저장이 삭제된다. 이전19분11초와 공개5분을 유지한 제안 최대 합계는44분11초다. 추가 승인 전에는 adb를 실행하지 않는다.

20:14 KST 최신 중앙 before-release는 `TEST_LEVEL_BELOW_FLOOR platform-first ads android`로 실패했다. 실제 광고 검수 통과 후 같은 검증기를 다시 실행한다. 그 뒤 같은 AAB를 한국 프로덕션으로 승격하고 심사, 승인, 공개 스토어와 최소 실행까지 진행한다. 이 문서 업데이트로 v1.0.0 태그, 게임 후보와 공개용 AAB를 바꾸지 않는다.
