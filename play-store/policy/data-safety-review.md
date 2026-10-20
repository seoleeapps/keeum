# 광고 SDK 데이터 보안 검토

게임 진행은 기기에 저장하며 운영자에게 보내지 않는다. 로그인, Firebase, 클라우드 저장, 결제와 별도 이용 분석은 없다. 광고 제공자의 수집과 전송은 별도로 신고해야 한다.

- Google Mobile Ads와 UMP: IP 주소로 추정하는 대략적 위치, 광고 상호작용, 진단 정보, 기기 식별자.
- 목적: 광고 제공과 측정, 진단과 부정 이용 방지. 실제 Play Console의 하위 유형, 공유의 서비스 제공자 예외와 선택 여부를 현재 SDK 공개 자료에 맞춰 확인한다.
- 전송 중 암호화. 앱 운영자는 광고 제공자가 수집한 전체 데이터를 직접 삭제할 수 없다. Android 광고 식별자 설정과 제공자의 개인정보 선택 경로를 안내한다.
- 가상 자녀의 이름은 로컬 사용자 입력이다. 실제 개인정보를 입력할 필요가 없으며 외부로 보내지 않는다.
- 게임 초기화 뒤 복구용 이전 백업과 결과 카드는 남을 수 있다. 앱 데이터 삭제로 앱 내부 데이터를 제거한다.

공식 확인 자료:
- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://developers.google.com/admob/android/privacy

상태: Console 설문과 최종 SDK AAB 검토 전. 이 문서는 제출 완료 근거가 아니다.
