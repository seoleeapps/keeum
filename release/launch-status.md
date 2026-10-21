# Google Play 첫 출시 상태

2026-10-21 18:38 KST. **내부 테스트 활성, 실제 광고 검수 차단** 상태다. 공개 목표는 Seolee Apps의 한국 전체 배포이며 심사는 아직 제출하지 않았다.

| 항목 | 확인 상태 |
| --- | --- |
| 출시 후보 | v1.0.0, code 1, 0823aaeeb104851b36fc025a74df50bc4b5b7a18 |
| 제품과 소유 | 내 새끼 대학 보내기, com.seorilabs.keeum, Seolee Apps 개인 계정 |
| 콘텐츠 | 활동 24, 이벤트 48, 엔딩 40, 전용 CG 12 |
| 개발 검수 | 같은 후보 CI, 독립 코어와 UI 3회 통과. 대표 UI48턴과 40종 코어 경로를 구분 |
| 서명 | 승인 후 앱 전용 업로드 키 생성, 로컬과 BeeStation 복원 검증, GitHub 실행 복제본과 Play 배포 서명 대조 완료 |
| AAB | CI 서명 빌드 성공. 실제 API 36,debug=false,운영 광고ID,16KB ELF 2개와 재생성 원본 제외 확인 |
| 내부 테스트 | 1.0.0(1) completed. 기존 내부테스트 그룹 2명 선택과 저장 재조회, 트랙 활성 |
| 실제 Android 광고 | 승인 후 잔여 데이터 삭제와 Play 생성 APK 설치 성공. Play 설치 출처 보호와 같은 패키지 Play 상세의 오프라인 화면으로 첫 실행 차단. 실제 UMP, GMA SDK와 광고 통과 0건 |
| 데이터 추가 승인 | 사용자 “계속 진행하라.”로 해당 패키지 잔여 데이터 삭제와 추가 최대18분 검수 승인, 삭제와 설치 완료. 다른 앱과 계정, OS 설정은 변경하지 않음 |
| 스토어 등록 | 문구, 아이콘, 기능 그래픽과 실제 화면 3장 readback 일치. 개인정보와 광고, 데이터 보안, IARC와 광고ID 선언 저장. 주의 필요 0개 |
| 실제 한국 IARC 결과 | 전체이용가. 목표 15세와 구분, 최종 심사 결과 확인 전 |
| AdMob | 앱과 광고 단위 2개 등록, keeum 전용 GDPR 메시지 게시. 스토어 검색 결과 없음, 검토 필요와 게재 제한 상태. 실제 게재 통과 아님 |
| 심사, 승인, 공개 | 미진행 |
| 리텐션 | 미측정 |

[설계와 승인](../docs/design/2026-10-21-google-play-launch/design.md), [QA 계획](../docs/game-design/07-qa-launch-plan.md), [실행 이슈 #60](https://github.com/seoleeapps/keeum/issues/60), [기계 판독 근거](evidence/google-play-1.0.0.json).

[태그 발급](https://github.com/seoleeapps/keeum/actions/runs/39521283892), [서명 빌드](https://github.com/seoleeapps/keeum/actions/runs/39521374449), [같은 후보 E2E](https://github.com/seoleeapps/keeum/actions/runs/39469353484), [Release와 증거](https://github.com/seoleeapps/keeum/releases/tag/v1.0.0).

AAB SHA-256은 `8564479ee833a29e4c0c746427aeb157133c5ec474c0d09403eda17d0b7d9eb6`이다. Play API가 같은 해시와 versionCode 1, internal completed를 반환했다. Play가 생성한 APK도 버전과 배포 인증서가 일치했다. adb 설치를 Play Store 설치로 주장하지 않는다.

한국 공개, 업로드 키 생성과 등록, Android 한 대 총25분은 이미 승인받았다. 추가 승인 구간은 18:31:41부터 18:37:55 KST까지 대기 포함 373.433초였다. 이전118.698초와 합쳐 누적492.131초를 사용했다. 공개 후5분을 예약하면 전체25분 안의 잔여 상한은707.869초다. 종료한 구간을 재시작하거나 대기를 빼지 않는다.

[네이티브 검수 결과](evidence/android-native-1.0.0-blocked.md)는 설치와 플러그인 등록, 실제 SDK 미실행을 구분한다. `LicenseClient`가 adb 설치 출처를 거절한 뒤 앱이 종료됐고, 실제 Play 설치 경로도 오프라인 화면에 막혔다. 네트워크 설정 복구는 원래 승인 범위 밖이므로 기기 조작을 종료했다. 기존 Wi-Fi 연결 복구와 잔여 예산 내 검수 재개 또는 사용자의 직접 복구 선택을 요청한 상태다. 계정과 OS 설정을 임의로 변경하거나 설치 출처를 위장하지 않았다.

18:37 KST 중앙 before-release 재실행도 `TEST_LEVEL_BELOW_FLOOR platform-first ads android`로 실패했다. 실제 광고 검수 통과 후 같은 검증기를 다시 실행한다. 그 뒤 같은 AAB를 한국 프로덕션으로 승격하고 심사, 승인, 공개 스토어와 최소 실행까지 진행한다. 이 문서 업데이트로 이미 빌드한 v1.0.0 태그나 출시 후보를 바꾸지 않는다.
