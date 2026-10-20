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
	e2e.begin("onboarding-and-cosmetics", ["core-loop", "cosmetics", "settings"])
	await e2e.shot("01-onboarding")
	await _tap("이 아이와 시작하기")
	e2e.expect_equal("home after actual start tap", main.get("_current_name"), "home")
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

	e2e.begin("full-48-turns-without-ads", ["core-loop", "events-endings", "save", "ads"])
	var count := 0
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
				e2e.step("scroll and pick family time", await e2e.tap(leisure.get("family_talk", leisure.get("playground"))))
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
		if count == 12 and gc.run != null:
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
