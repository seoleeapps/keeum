extends SceneTree
## 실제 시작 장면과 좌표 입력. 함수 호출로 화면을 건너뛰지 않는다.
const Driver := preload("res://tools/e2e/e2e_driver.gd")
var e2e: RefCounted
var main: Control
var gc: Node
var out: String
var ads := FakeAds.new()
var clock := FakeAdClock.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not LocalSave.is_user_dir_isolated():
		push_error("E2E requires an isolated user directory")
		quit(1)
		return
	seed(20261021)
	FX.force_reduced = true
	var args := OS.get_cmdline_user_args()
	out = args[args.find("--out") + 1] if args.has("--out") else "build/e2e"
	var height := int(args[args.find("--height") + 1]) if args.has("--height") else 1920
	e2e = Driver.new(self, Vector2i(1080, height), out, args.has("--capture"))
	gc = root.get_node("GameController")
	if args.has("--large-text"):
		UIKit.set_font_scale_tier(2)
	ads.available = false
	AdGateway.configure(ads, clock)
	await _mount()
	e2e.begin("onboarding-and-cosmetics", ["core-loop", "events-endings", "cosmetics", "settings"])
	# 파일이 있어도 import remap이 빠지면 폴백으로 실행된다. 실제 리소스 로드까지 검사한다.
	for ending: Dictionary in gc.content.endings:
		if bool(ending.get("cg", false)):
			e2e.step("CG texture imported: " + str(ending.id), Art.has_art("cg_" + str(ending.id)))
	for season_name: String in ["spring", "summer", "autumn", "winter"]:
		e2e.step("home background imported: " + season_name, Art.has_art("bg_home_" + season_name))
	for audio_path: String in ["res://assets/audio/bgm_home.ogg", "res://assets/audio/bgm_ending.ogg", "res://assets/audio/sfx/tap.ogg"]:
		e2e.step("audio resource imported: " + audio_path, ResourceLoader.exists(audio_path, "AudioStream"))
	await e2e.shot("01-onboarding")
	await _tap("이 아이와 시작하기")
	e2e.expect_equal("home after actual start tap", main.get("_current_name"), "home")
	e2e.step("child body texture imported", Art.has_art(Art.char_body_name(gc.run.child.stage, str(gc.run.child.appearance.get("hair", "mushroom")))))
	await e2e.shot("02-home")
	await _tap("꾸미기")
	await e2e.shot("03-shop")
	await _tap("코스메틱 뽑기", true)
	var gems: int = gc.profile.premium
	await _tap("단차 뽑기", true)
	e2e.expect_equal("insufficient gems do not charge", gc.profile.premium, gems)
	await _tap("꾸미기로")
	await _tap("홈으로")
	await _tap("설정")
	await e2e.shot("04-settings")
	await _tap("홈으로")
	e2e.end()

	await _coin_display_checks()

	e2e.begin("full-48-turns-without-ads", ["core-loop", "events-endings", "save", "ads"])
	var count := 0
	var restarted := false
	while gc.run != null and count < 220:
		count += 1
		match String(main.get("_current_name")):
			"home":
				await _tap("이번 달 활동 정하기")
			"activity":
				var screen: Control = main.current_screen()
				var cards: Dictionary = screen.get("_a_cards")
				await e2e.tap(cards.get("home_reading"))
				var leisure: Dictionary = screen.get("_b_cards")
				e2e.step("scroll and pick family time", await e2e.tap(leisure.get("family_talk", leisure.get("playground"))), "turn=%d" % gc.run.turn_index)
				if gc.run.turn_index == 0:
					await e2e.shot("05-activity-scrolled")
				await _tap("결정!")
			"result": await _tap("다음", true)
			"term": await _tap("다음 학기")
			"event":
				var screen: Control = main.current_screen()
				var choice_box: VBoxContainer = screen.get("_choice_box")
				e2e.step("event choice by coordinate", await e2e.tap(choice_box.get_child(0)))
				await _tap("다음")
			"transition":
				var screen: Control = main.current_screen()
				var option_box: VBoxContainer = screen.get("_option_box")
				e2e.step("transition choice by coordinate", await e2e.tap(option_box.get_child(0)))
				await e2e.shot("06-transition")
				await _tap("다음")
			"application":
				e2e.expect_equal("48 completed turns", gc.run.turn_index, 48)
				await e2e.shot("07-application")
				await _tap("진로 자유", true)
			_: break
		if count >= 12 and not restarted and gc.run != null and String(main.get("_current_name")) in ["home", "event"]:
			restarted = true
			var turn: int = gc.run.turn_index
			var step: Dictionary = gc.run.current_step.duplicate(true)
			await e2e.unmount(main)
			gc.restore_from_disk()
			await _mount()
			e2e.expect_equal("restart restores turn", gc.run.turn_index, turn)
			e2e.expect_equal("restart restores pending event", gc.run.current_step, step)
	e2e.expect_equal("ending reached through inputs", main.get("_current_name"), "ending")
	e2e.expect_equal("one run registered", gc.profile.total_runs, 1)
	await e2e.shot("08-ending")
	await _tap("도감에 등록")
	await e2e.shot("09-codex")
	await _tap("새 아이 키우기")
	e2e.expect_equal("next child onboarding", main.get("_current_name"), "onboarding")
	e2e.end()
	e2e.begin("rewarded-failure-duplicates-and-free-gacha", ["ads", "cosmetics", "save"])
	await _tap("이 아이와 시작하기")
	ads.available = true
	await _tap("꾸미기")
	await _tap("홈으로")
	var before: int = gc.profile.premium
	await _tap("광고 보고 60젬", true)
	e2e.expect_equal("no grant before completion", gc.profile.premium, before)
	ads.show()
	ads.close()
	await e2e.frames(4)
	e2e.expect_equal("cancelled ad grants nothing", gc.profile.premium, before)
	clock.advance(60)
	await _tap("꾸미기")
	await _tap("홈으로")
	await _tap("광고 보고 60젬", true)
	ads.show()
	ads.earn()
	ads.earn()
	ads.close()
	await e2e.frames(4)
	e2e.expect_equal("completed ad grants once", gc.profile.premium, before + 60)
	await e2e.shot("10-daily-reward")
	await _tap("꾸미기")
	await _tap("코스메틱 뽑기", true)
	var balance: int = gc.profile.premium
	await _tap("단차 뽑기", true)
	e2e.expect_equal("free gems charged 150", gc.profile.premium, balance - 150)
	e2e.step("cosmetic acquired", gc.profile.owned_cosmetics.size() > 0)
	await e2e.shot("11-free-gacha")
	await _tap("꾸미기로")
	await _tap("홈으로")
	clock.advance(60)
	await _tap("이번 달 활동 정하기")
	e2e.step("new run first month explanation", "코인은 게임에서 얻고 활동에 사용하는 재화예요." in _visible_texts(main.current_screen()))
	await _tap("보너스 슬롯 열기", true)
	e2e.step("confirm blocked during ad", main.current_screen().get("_confirm_btn").disabled)
	ads.show()
	ads.earn()
	ads.earn()
	ads.close()
	await e2e.frames(4)
	e2e.step("bonus unlocked on earned callback", main.current_screen().get("_bonus_open"))
	await _tap("결정!")
	var saved_balance: int = gc.profile.premium
	await e2e.unmount(main)
	gc.restore_from_disk()
	await _mount()
	e2e.expect_equal("ad and gacha balance survives restart", gc.profile.premium, saved_balance)
	e2e.expect_equal("next run turn persisted", gc.run.turn_index, 1)
	e2e.end()
	await e2e.unmount(main)
	# 사인 톤의 짧은 지연 재생도 끝낸 뒤 종료한다.
	await create_timer(0.1).timeout
	root.get_node("AudioBus").stop_all()
	# stop은 오디오 스레드에서 처리된다. 실제 파일 재생을 종료한 뒤 믹스를 기다린다.
	await create_timer(0.1).timeout
	AdGateway.reset_test_state()
	ads.reward_callback = Callable()
	ads.close_callback = Callable()
	ads.shown_callback = Callable()
	var code: int = e2e.finish({"sourceSha": OS.get_environment("GITHUB_SHA"), "seed": 20261021})
	e2e.viewport.queue_free()
	await process_frame
	await process_frame
	e2e = null
	quit(code)

func _mount() -> void:
	main = load("res://game/ui/main.tscn").instantiate()
	await e2e.mount(main)

func _tap(label: String, prefix := false) -> bool:
	var button := _find_button(main.current_screen(), label, prefix)
	var ok: bool = await e2e.tap(button)
	e2e.step("tap " + label, ok)
	await e2e.frames(3)
	return ok

func _find_button(node: Node, label: String, prefix: bool) -> Button:
	if node is Button:
		var b := node as Button
		# icon_button stores its label in a child Label.
		var text := b.text
		for child: Node in b.get_children():
			if child is BoxContainer:
				for sub: Node in child.get_children():
					if sub is Label:
						text += sub.text
		if b.is_visible_in_tree() and (text.begins_with(label) if prefix else text == label):
			return b
	for child: Node in node.get_children():
		var found := _find_button(child, label, prefix)
		if found != null:
			return found
	return null

## 저장 어댑터에 경계값 픽스처를 넣고 실제 화면과 좌표 입력으로 표시를 검증한다.
func _coin_display_checks() -> void:
	e2e.begin("coin-labels-and-first-month", ["core-loop"])
	var original := LocalSave.load_data().duplicate(true)
	for amount: int in [0, 250, 9999999]:
		await e2e.unmount(main)
		var fixture := original.duplicate(true)
		fixture["run"]["household"]["money"] = amount
		e2e.step("isolated balance fixture saved", LocalSave.save(fixture))
		gc.restore_from_disk()
		await _mount()
		e2e.expect_equal("restored money", gc.run.household.money, amount)
		var balance := "%d 코인" % amount
		e2e.step("home coin unit " + str(amount), balance in _visible_texts(main.current_screen()))
		_coin_layout(main.current_screen())
		await e2e.shot("coin-home-" + str(amount))
		await _tap("이번 달 활동 정하기")
		var screen: Control = main.current_screen()
		var texts := _visible_texts(screen)
		e2e.step("activity coin unit", balance in texts)
		e2e.step("first month explanation", "코인은 게임에서 얻고 활동에 사용하는 재화예요." in texts)
		var leisure: Dictionary = screen.get("_b_cards")
		var nature: Button = leisure["nature_play"]
		e2e.step("activity cost in coins", nature.text.contains("30 코인"))
		e2e.expect_equal("zero balance prevents paid activity", nature.disabled, amount < 30)
		_coin_layout(screen)
		await e2e.shot("coin-activity-" + str(amount))
		if amount >= 30:
			e2e.step("pick paid activity by coordinate", await e2e.tap(nature))
		await _tap("결정!")
		e2e.expect_equal("paid activity cost unchanged", gc.run.household.money, amount + Balance.BASE_INCOME_PER_TURN - (30 if amount >= 30 else 0))
		if amount >= 30:
			e2e.step("result uses coin label", "코인" in _visible_texts(main.current_screen()))
		await e2e.shot("coin-result-" + str(amount))
		# 홈으로 돌아올 때 실제 count_up 경로를 켜서 매 프레임 단위를 확인한다.
		FX.force_reduced = false
		await _tap("다음", true)
		var samples := 0
		var animation_ok := true
		var changed := false
		var previous := ""
		var until := Time.get_ticks_msec() + 700
		while Time.get_ticks_msec() < until:
			for text: String in _visible_texts(main.current_screen()):
				if text.ends_with(" 코인"):
					changed = changed or (previous != "" and previous != text)
					previous = text
					samples += 1
			animation_ok = animation_ok and _visible_texts(main.current_screen()).any(func(t: String) -> bool: return t.ends_with(" 코인"))
			await e2e.frames(1)
		e2e.step("coin unit on every animation frame", animation_ok and samples > 1)
		e2e.step("balance animation changes number", changed)
		FX.force_reduced = true
		var saved_money: int = gc.run.household.money
		await e2e.unmount(main)
		gc.restore_from_disk()
		await _mount()
		e2e.expect_equal("coin balance survives restart", gc.run.household.money, saved_money)
		await _tap("이번 달 활동 정하기")
		e2e.step("explanation hidden after first month", not "코인은 게임에서 얻고 활동에 사용하는 재화예요." in _visible_texts(main.current_screen()))
	# 각각은 살 수 있지만 합계가 잔액을 넘는 조합.
	await e2e.unmount(main)
	var limited := original.duplicate(true)
	limited["run"]["child"]["stage"] = "elementary"
	limited["run"]["household"]["money"] = 130
	e2e.step("limited fixture saved", LocalSave.save(limited))
	gc.restore_from_disk()
	await _mount()
	await _tap("이번 달 활동 정하기")
	var screen: Control = main.current_screen()
	var a_cards: Dictionary = screen.get("_a_cards")
	var b_cards: Dictionary = screen.get("_b_cards")
	e2e.step("pick 120 coin activity", await e2e.tap(a_cards["specialty_math_spartan"]))
	e2e.step("pick additional 30 coin activity", await e2e.tap(b_cards["nature_play"]))
	e2e.step("combined over-budget selection blocked", screen.get("_confirm_btn").disabled)
	await e2e.shot("coin-over-budget")
	# 소득 활동은 고등 단계의 저장 픽스처로 실제 카드에서 읽는다.
	await e2e.unmount(main)
	limited["run"]["child"]["stage"] = "high"
	e2e.step("income fixture saved", LocalSave.save(limited))
	gc.restore_from_disk()
	await _mount()
	await _tap("이번 달 활동 정하기")
	e2e.step("income uses coin prefix", _visible_texts(main.current_screen()).any(func(t: String) -> bool: return t.contains("코인 +")))
	await e2e.unmount(main)
	e2e.step("original isolated save restored", LocalSave.save(original))
	gc.restore_from_disk()
	await _mount()
	e2e.end()

func _visible_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Control and not node.is_visible_in_tree():
		return texts
	if node is Label or node is Button:
		texts.append(node.text)
	for child: Node in node.get_children():
		texts.append_array(_visible_texts(child))
	return texts

func _coin_layout(node: Node) -> void:
	for text: String in _visible_texts(node):
		e2e.step("no real currency display", not text.contains("₩") and not text.contains("재력"))
	for label: Node in node.find_children("*", "Label", true, false):
		if label.is_visible_in_tree() and label.text.ends_with(" 코인"):
			var rect: Rect2 = label.get_global_rect()
			e2e.step("coin label inside viewport", rect.position.x >= 0 and rect.end.x <= e2e.viewport.size.x)
