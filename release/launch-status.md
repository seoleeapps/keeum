# Google Play 첫 출시 상태

2026-10-21 22:03 KST. **한국 프로덕션 심사 제출, 제출ID1 검토 중**이다. 승인, 공개와 광고 게재 완료는 아직 확인하지 않았다.

| 항목 | 확인 상태 |
| --- | --- |
| 후보 | v1.0.0, code1, 0823aaeeb104851b36fc025a74df50bc4b5b7a18 |
| 제품과 소유 | 내 새끼 대학 보내기, com.seorilabs.keeum, Seolee Apps 개인 계정 |
| 콘텐츠 | 활동24, 이벤트48, 엔딩40, 전용 CG12 |
| 개발 검수 | 같은 후보 CI, 독립 코어와 UI3회 통과. 대표 UI48턴과40종 코어 경로를 구분 |
| 서명과 AAB | 앱 전용 업로드 키와 복원 검증, API36, debug=false, 운영 광고ID,16KB ELF2개, 재생성 원본 제외 확인 |
| 내부 테스트 | 같은 AAB의1.0.0(1) completed, 기존 내부테스트 그룹2명 활성 |
| 실제 Android SDK | Poing 연결, UMP 응답 저장, 두 형식 Test Ad, 완료60젬 한 번 지급과 광고 종료 후 게임 복귀 확인 |
| 추가 기기 제안 | 부분 완료. UMP enum과 창, 취소 무보상,60초 미만 차단,180초 억제는 기기 통과로 세지 않음 |
| 복원과 사용 시간 | 원래 Play 서명 APK 복원과 메타데이터 확인 완료. 이번1007.065초, 누적2158.184초. 공개 후300초 미사용 예약 |
| 중앙 검사 | 최신 중앙 f73637d에서 Release 게시 근거로 google-play before-release L3 통과 |
| Play 프로덕션 | 같은 code1, 한국1개 국가, 전체 출시. 22:01 KST 제출ID1,22:03 재조회 검토 중 |
| 등록정보와 정책 | 실제 화면3장과 문구 readback 일치. 필수 선언10개, 주의 필요0개. 실제 한국 IARC 전체이용가, 타겟18+ |
| AdMob | 앱과 광고 단위2개, 전용 GDPR 메시지 등록. Play 패키지 연결 저장과 재조회 완료. 앱 인증과 게재 준비 미완료 |
| 승인, 공개와 공개 후 실행 | 미완료 |
| 리텐션 | 미측정 |

[설계와 승인](../docs/design/2026-10-21-google-play-launch/design.md), [실행 이슈 #60](https://github.com/seoleeapps/keeum/issues/60), [기계 판독 원장](evidence/google-play-1.0.0.json), [출시 단계 원장](market-launch-state.json).

[같은 후보 E2E](https://github.com/seoleeapps/keeum/actions/runs/39469353484), [서명 빌드](https://github.com/seoleeapps/keeum/actions/runs/39521374449), [Release와 검수 근거](https://github.com/seoleeapps/keeum/releases/tag/v1.0.0).

실제 SDK 실행은 [독립 검수 보고서](evidence/android-native-1.0.0-sdk.md)와 [JSON](evidence/android-native-1.0.0-sdk.json)에 기록했다. 같은 AAB에서 만든 업로드키 서명 로컬 APK로 검수했다. 게임 에셋과 SDK 등629개 파일은 AAB와 바이트 일치한다. 로컬 APK 검수를 Play Store 설치나 Play 보호 동작 확인으로 확장하지 않는다.

실제 UMP 응답의 `gdprApplies=0` 저장을 확인했으며 명시 ConsentStatus enum이나 필수 동의창 표시를 확인한 것은 아니다. 첫 취소 의도 입력은 이미 완료 뒤여서 완료 지급으로 기록했다. 다음 테스트 광고에서1.719초에 Back을 입력했지만 광고가 계속돼 보상 전 취소도 확인하지 못했다. 취소, 실패, 중복 콜백,60초와180초 규칙의 개발 환경 근거는 유지하고 기기 미검증 분기와 구분한다. 화면 전송 오류 뒤 일반 검수를 중단하고 복원을 우선했다. 원문 앱 로그가 수집되지 않은 이후 구간의 오류 부재를 주장하지 않는다.

[구체 추가20분 승인](evidence/android-sdk-test-authorization.json)에 따라 QA 데이터와 서명 설치본을 두 번 교체했고, 원래 Play 서명 APK 복원 뒤 실행하지 않은 상태로 종료했다. 이전1151.120초와 이번1007.065초를 보존한다. 누적2158.184초이며 승인된 최대2651.120초 중 공개 후300초는 별도 예약이다. 종료한 검수 구간을 다시 시작하지 않는다.

[중앙 before-release 결과](evidence/before-release-real-sdk.json)는 실제 통과한 SDK5항목과 기존 개발 L3를 합친 판정이다. 추가 기기 제안 전체 통과나 공개 완료를 뜻하지 않는다. 공개 증거 ZIP은 업로드 후 다시 내려받아 해시와 내부 manifest를 대조했으며 APK, 계정과 원문 기기 기록은 공개하지 않았다.

Play API의 최초 completed 승격은 초안 앱 제약으로 거절됐고 미반영을 재조회했다. Console에서 기존 라이브러리의 동일 code1을 선택해 [프로덕션에 저장](evidence/play-build1-production-pre-review.json)했다. 선택 경고2개는 가독화 파일과 네이티브 디버그 기호 미첨부다. 한국 전체 출시와 관리형 게시 사용 중지 설정을 유지한다. 빠른 검사 뒤 22:01 KST에 변경11개를 전송했다. [제출 활동](evidence/production-submission-activity.json)과 [세부정보](evidence/production-submission-details.json)에서 제출ID1, 같은 버전과 한국 전체 출시, 검토 중 상태를 읽었다. 제출 직전 [중앙 검사](evidence/before-release-before-submission.json)도 통과했다. 승인 후 자동 공개 설정이며 22:03 KST 한국 스토어는 HTTP404다. 승인과 한국 공개, AdMob 앱 인증과 게재 준비, 예약된 최소 실행이 남아 있다. 출시 지시는 공개까지 유효하며 심사 대기를 공개 완료로 표시하지 않는다.

22:13 KST AdMob의 [동일 앱ID와 패키지 연결](evidence/admob-linked-row-readback.json)을 재조회했다. 미검토 Play 앱의 실제 패키지와 링크를 대조해 저장했으며 광고 단위2개는 유지됐다. 앱 인증은 재검사 한 번 뒤에도 미완료다. [공개 파일](evidence/app-ads-after-store-link-http.json)의 게시자 행, HTTP 응답과 robots 허용을 확인했으나 [이 앱의 크롤링 URL과 시각](evidence/admob-own-appads-all-pages.json)은 상태 목록에 없었다. 다른 앱의 인증을 이 앱의 근거로 쓰거나 원인을 전파 지연으로 단정하지 않는다. [Google의 인증 안내](https://support.google.com/admob/answer/14538460)와 [문제 해결 안내](https://support.google.com/admob/answer/9776740)를 대조했으며 공개 파일은 수정하지 않았다.
