class_name ShopScreen
extends UIScreen
## 무료로 모은 젬과 회차 보상으로 외형만 꾸민다.
func enter(_data: Variant = null) -> void:
	var root := page_root(56)
	var top := UIKit.hbox(8)
	top.add_child(UIKit.title("꾸미기", 38))
	top.add_child(UIKit.spacer())
	top.add_child(UIKit.icon_text("gem", "%d" % GameController.profile.premium, 26, UIKit.PREMIUM))
	root.add_child(top)
	var body := scroll_body(root)
	var preview := ChildAvatar.new()
	preview.custom_minimum_size = Vector2(0, 350)
	if GameController.run != null:
		UIUtil.configure_avatar(preview, GameController.run, reduce_motion())
	body.add_child(preview)
	var gacha := UIKit.icon_button("ribbon", "코스메틱 뽑기 (확률과 천장 공개)", true)
	gacha.pressed.connect(func() -> void:
		AudioBus.tap()
		router.goto("gacha"))
	body.add_child(gacha)
	body.add_child(UIKit.label("젬은 회차를 마치거나 홈에서 광고를 보고 모을 수 있어요.\n꾸미기 아이템은 성장과 엔딩에 영향을 주지 않아요.", 24, UIKit.TEXT_SOFT, HORIZONTAL_ALIGNMENT_CENTER, true))
	var back := UIKit.button("홈으로")
	back.pressed.connect(func() -> void:
		AudioBus.tap()
		router.goto("home"))
	root.add_child(back)
