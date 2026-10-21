# Google Play 첫 출시 상태

2026-10-21. **내부 테스트 활성, 실제 광고 검수 정지** 상태다. 공개 목표는 Seolee Apps의 한국 전체 배포이며 심사는 아직 제출하지 않았다.

| 항목 | 확인 상태 |
| --- | --- |
| 출시 후보 | v1.0.0, code 1, 0823aaeeb104851b36fc025a74df50bc4b5b7a18 |
| 제품과 소유 | 내 새끼 대학 보내기, com.seorilabs.keeum, Seolee Apps 개인 계정 |
| 콘텐츠 | 활동 24, 이벤트 48, 엔딩 40, 전용 CG 12 |
| 개발 검수 | 같은 후보 CI, 독립 코어와 UI 3회 통과. 대표 UI48턴과 40종 코어 경로를 구분 |
| 서명 | 승인 후 앱 전용 업로드 키 생성, 로컬과 BeeStation 복원 검증, GitHub 실행 복제본과 Play 배포 서명 대조 완료 |
| AAB | CI 서명 빌드 성공. 실제 API 36,debug=false,운영 광고ID,16KB ELF 2개와 재생성 원본 제외 확인 |
| 내부 테스트 | 1.0.0(1) completed. 기존 내부테스트 그룹 2명 선택과 저장 재조회, 트랙 활성 |
| 실제 Android 광고 | Seeker의 제거된 디버그 keeum에 남은 데이터와 서명 기록을 발견해 설치 전 정지. 실제 SDK와 UMP, 테스트 광고는 미실행 |
| 데이터 추가 승인 | 잔여 keeum 데이터만 삭제하고 Play 서명 설치본으로 교체하는 선택을 사용자에게 요청. 응답 전 삭제나 교체 금지 |
| 스토어 등록 | 문구, 아이콘, 기능 그래픽과 실제 화면 3장 readback 일치. 개인정보와 광고, 데이터 보안, IARC와 광고ID 선언 저장. 주의 필요 0개 |
| 실제 한국 IARC 결과 | 전체이용가. 목표 15세와 구분, 최종 심사 결과 확인 전 |
| AdMob | 앱과 광고 단위 2개 등록, keeum 전용 GDPR 메시지 게시. 스토어 검색 결과 없음, 검토 필요와 게재 제한 상태. 실제 게재 통과 아님 |
| 심사, 승인, 공개 | 미진행 |
| 리텐션 | 미측정 |

[설계와 승인](../docs/design/2026-10-21-google-play-launch/design.md), [QA 계획](../docs/game-design/07-qa-launch-plan.md), [실행 이슈 #60](https://github.com/seoleeapps/keeum/issues/60), [기계 판독 근거](evidence/google-play-1.0.0.json).

[태그 발급](https://github.com/seoleeapps/keeum/actions/runs/39521283892), [서명 빌드](https://github.com/seoleeapps/keeum/actions/runs/39521374449), [같은 후보 E2E](https://github.com/seoleeapps/keeum/actions/runs/39469353484), [Release와 증거](https://github.com/seoleeapps/keeum/releases/tag/v1.0.0).

AAB SHA-256은 `8564479ee833a29e4c0c746427aeb157133c5ec474c0d09403eda17d0b7d9eb6`이다. Play API가 같은 해시와 versionCode 1, internal completed를 반환했다. Play가 생성한 APK도 버전과 배포 인증서가 일치했다. adb 설치를 Play Store 설치로 주장하지 않는다.

한국 공개, 업로드 키 생성과 등록, Android 한 대 총25분은 이미 승인받았다. 약 2분의 조회 뒤 정지했으며 추가 요청은 이 패키지의 잔여 데이터 삭제와 설치 후 최대 18분 검수다. 공개 후 같은 기기 최소5분을 유지한다. 저장 내용과 다른 앱을 읽거나 변경하지 않았다.

실제 광고 검수 통과 후 중앙 before-release를 다시 실행한다. 그 뒤 같은 AAB를 한국 프로덕션으로 승격하고 심사, 승인, 공개 스토어와 최소 실행까지 진행한다. 이 문서 업데이트로 이미 빌드한 v1.0.0 태그나 출시 후보를 바꾸지 않는다.
