# Google Play 첫 출시 상태

2026-10-21. 공개 목표는 한국 Google Play 전체 배포다. 빌드와 업로드, 심사, 승인, 공개, 광고 게재를 별도로 판정한다.

| 항목 | 현재 확인 |
| --- | --- |
| Play 소유 계정 | Seolee Apps 개인 계정, 라이브 Console에서 확인 |
| Play 앱 | 내 새끼 대학 보내기, com.seorilabs.keeum, Console 앱 4975075776591973401 등록 |
| AdMob 앱 | ca-app-pub-9932778305312246~7499948507 |
| 보상형 | keeum_rewarded, ca-app-pub-9932778305312246/1213916766 |
| 전면 광고 | keeum_interstitial, ca-app-pub-9932778305312246/6386352398 |
| AdMob 실제 게재 | 검토 필요, 공개 스토어 연결과 제공자 확인 전 |
| 프로덕션 업로드 키 | 카탈로그에 app/keeum/google-play/upload-key 없음. 다른 앱 키 사용 금지 |
| 개발 검수 | 로컬 실제 입력 E2E와 렌더링 수행. 최종 동일 후보 CI와 독립 3회는 별도 기록 |
| 기기 검수 | 접근하지 않음. 실제 SDK, UMP 동의 창과 광고 복귀만 개발 검수 후 소명하고 별도 사용 승인 필요 |
| 서명 AAB와 16KB | 미빌드, 미검증 |
| 내부 테스트 | 미업로드 |
| 심사, 승인, 한국 공개 | 미진행 |
| 리텐션 | 미측정 |

승인 범위: docs/design/2026-10-21-google-play-launch. 실행 이슈: https://github.com/seoleeapps/keeum/issues/60

개인정보처리방침은 https://github.com/seorilabs/seorilabs-official/pull/83 에서 병합, 배포했다. 실제 URL의 HTTP 200과 본문을 읽어 확인한다.

필수 남은 항목은 프로덕션 키 신규 등록, 실제 Android 광고 SDK와 UMP 검증, 최종 SHA CI와 독립 UI 검수, AAB 검증, Console의 데이터 보안과 IARC, 테스트와 심사, 공개 스토어와 최소 실행 확인이다. 출시 지시는 공개까지 유효하며, 별도 기기 사용과 자격증명 생성 승인은 대신하지 않는다.
