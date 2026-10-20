# Poing AdMob v5.1.0

출처: https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0

GDScript 및 editor plugin은 poing-godot-admob-v5.1.0.zip, Android ads 바이너리는 android-template-v4.7.2.zip에서 가져왔다. MIT LICENSE를 보존한다. mediation adapter는 사용하지 않는다.

로컬 수정: internal/services/network/binary_installer.gd에서 활성화한 마켓의 바이너리만 내려받도록 했다. keeum 첫 출시는 Android 전용이며 꺼진 iOS용 SDK 다운로드와 CI 변경을 막는다. iOS를 활성화하면 원래 설치 경로를 사용한다.
