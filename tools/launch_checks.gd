extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_gacha()
	_check_ads()
	_check_ending_conditions()
	_check_ending_routes()
	quit(1 if failures > 0 else 0)

func expect(label: String, value: bool) -> void:
	if not value:
		push_error("launch check: " + label)
		failures += 1

func _check_ads() -> void:
	AdGateway.reset_test_state()
	var clock := FakeAdClock.new()
	var ads := FakeAds.new()
	AdGateway.configure(ads, clock)
	var p := Profile.new()
	AdGateway.begin_session(p)
	expect("first session excludes interstitial", not AdGateway.can_interstitial(p))
	var rewards := [0]
	var give := func() -> void: rewards[0] += 1
	var done := func(_earned: bool) -> void: pass
	expect("reward request accepted", AdGateway.request_rewarded(p, "daily_gems", give, done))
	expect("no reward before callback", p.premium == 60)
	expect("double request rejected", not AdGateway.request_rewarded(p, "daily_gems", give, done))
	ads.show(); ads.earn(); ads.earn()
	expect("duplicate callbacks grant once", p.premium == 120 and rewards[0] == 1)
	ads.close(); ads.earn(); ads.close()
	expect("late callback grants nothing", p.premium == 120 and rewards[0] == 1)
	clock.advance(60)
	expect("daily gems limited once", not AdGateway.can_open(p, "daily_gems"))
	expect("activity bonus opens after 60s", AdGateway.can_open(p))
	AdGateway.request_rewarded(p, "activity_bonus", give, done)
	ads.show(); ads.close(); ads.earn()
	expect("cancel grants nothing", rewards[0] == 1)
	expect("cancelled view counts toward daily cap", p.ad_daily_count == 2)
	clock.advance(59)
	expect("59 seconds still blocked", not AdGateway.can_open(p))
	clock.advance(1)
	expect("60 seconds allowed", AdGateway.can_open(p))
	AdGateway.request_rewarded(p, "activity_bonus", give, done)
	ads.close()
	expect("failed show not charged", p.ad_daily_count == 2)
	ads.available = false
	expect("no fill rejected", not AdGateway.request_rewarded(p, "activity_bonus", give, done))
	ads.available = true
	clock.date = "2026-10-20"
	expect("date rollback retains gem cap", not AdGateway.can_open(p, "daily_gems"))
	clock.epoch -= 3600
	expect("clock rollback keeps cooldown", not AdGateway.can_open(p))
	clock.epoch += 3600
	clock.date = "2026-10-22"
	clock.advance(180)
	p.ad_sessions = 2
	expect("second session after cooldown permits interstitial", AdGateway.can_interstitial(p))
	AdGateway.request_interstitial(p, func() -> void: pass)
	expect("interstitial counters", p.ad_interstitial_count == 1)
	expect("interstitial cooldown", not AdGateway.can_interstitial(p))
	clock.advance(180)
	AdGateway.request_interstitial(p, func() -> void: pass)
	clock.advance(180)
	expect("session interstitial cap two", not AdGateway.can_interstitial(p))
	for i in 6:
		AdGateway.request_rewarded(p, "activity_bonus", give, done)
		ads.show(); ads.earn(); ads.close(); clock.advance(60)
	expect("rewarded session cap eight", not AdGateway.can_open(p))
	var restored := Profile.from_dict(p.to_dict())
	expect("ad state survives save", restored.ad_gem_day == p.ad_gem_day and restored.ad_rewarded_end == p.ad_rewarded_end)
	AdGateway.reset_test_state()
	AdGateway.configure(ads, clock)
	p.ad_daily_key = clock.date
	p.ad_daily_count = 18
	expect("daily cap survives process restart", not AdGateway.can_open(p))
	AdGateway.reset_test_state()
	ads.reward_callback = Callable()
	ads.close_callback = Callable()
	ads.shown_callback = Callable()
	print("광고 정책 검사 완료")

func _check_ending_conditions() -> void:
	var content := ContentDB.new()
	expect("content loaded", content.load_all())
	expect("activities 24", content.activities.size() == 24)
	expect("events 48", content.events.size() == 48)
	expect("endings 40", content.endings.size() == 40)
	var random := RandomNumberGenerator.new()
	random.seed = 20261021
	var witnesses: Array = []
	for target: Dictionary in content.endings:
		var req: Dictionary = target.requires
		var reached := false
		for trial in 2000:
			var run := GameRun.new()
			run.setup(content)
			run.start_new({"seed": trial + 1})
			run.application = str(req.get("applied", ["hanul", "stable", "art", "free"][random.randi_range(0, 3)]))
			run.exposed = bool(req.get("exposed", false))
			run.child.temperament = str(req.get("temperament", Balance.TEMPERAMENTS[random.randi_range(0, 5)]))
			var stats := {}
			for stat: String in ["academic", "emotion", "stress", "talent", "bonding", "stamina"]:
				stats[stat] = random.randi_range(int(req.get(stat + "_min", 0)), int(req.get(stat + "_max", 100)))
			for subject: String in ["korean", "english", "math", "science", "social"]:
				run.child.subject_scores[subject] = stats.academic
			run.child.emotion = stats.emotion
			run.child.stress = stats.stress
			run.child.talent = stats.talent
			run.child.stamina = stats.stamina
			run.household.bonding = stats.bonding
			if run.determine_ending().id == target.id:
				witnesses.append({"id": target.id, "stats": stats, "applied": run.application, "temperament": run.child.temperament, "exposed": run.exposed})
				reached = true
				break
		expect("ending not shadowed: " + str(target.id), reached)
	var out := OS.get_environment("KEEUM_ENDING_OUT")
	if out.is_empty(): out = "user://ending-conditions"
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out.path_join("conditions.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind": "condition-witnesses-not-playthroughs", "witnesses": witnesses}, "  "))
	print("엔딩 조건 도달 검사 %d/40" % witnesses.size())

func _check_ending_routes() -> void:
	var content := ContentDB.new()
	content.load_all()
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/e2e/fixtures/ending-routes.json"))
	var routes: Dictionary = fixture.routes
	expect("40 complete routes", routes.size() == 40)
	for id: String in routes:
		var route: Dictionary = routes[id]
		var impression := {}
		for imp: Dictionary in content.profiles.first_impressions:
			if str(imp.id) == str(route.impression): impression = imp
		var run := GameRun.new()
		run.setup(content)
		run.start_new({"seed": int(route.seed), "impression": impression})
		for action: Dictionary in route.choices:
			if action.type == "turn":
				expect(id + " activity A available", str(action.a) == "" or run.available_activities("A").any(func(a: Dictionary) -> bool: return a.id == action.a))
				expect(id + " activity B available", str(action.b) == "" or run.available_activities("B").any(func(a: Dictionary) -> bool: return a.id == action.b))
				var cost := int(content.activity(str(action.a)).get("cost", 0)) + int(content.activity(str(action.b)).get("cost", 0))
				expect(id + " can afford pair before income", run.household.can_afford(cost))
				run.resolve_turn(str(action.a), str(action.b))
			else:
				var step := run.next_step()
				while str(step.screen) == "term": step = run.next_step()
				if action.type == "event":
					expect(id + " event sequence", str(step.get("event", {}).get("id", "")) == str(action.id))
					run.resolve_event(step.get("event", {}), int(action.choice))
				else:
					expect(id + " transition sequence", str(step.get("transition", {}).get("gate", "")) == str(action.gate))
					run.resolve_transition(step.get("transition", {}), int(action.choice))
			# 다음 턴 전에 남은 학기/입시 알림을 확인한다. 이벤트와 전환기는 다음 action에서 처리한다.
			if action.type != "turn" and not run.current_step.is_empty(): run.current_step = {}
		# 마지막 알림은 상태를 바꾸지 않는 학기 정산과 입시뿐이다.
		expect(id + " completed 48 turns", run.is_final_turn() and run.turn_index == 48)
		run.set_application(str(route.application))
		expect(id + " actual ending", str(run.determine_ending().id) == id)
	print("48턴 실제 코어 경로 재생 40/40")

func _check_gacha() -> void:
	expect("special lower boundary", CosmeticDraw.tier_for_roll(0.0, 1) == "special")
	expect("special upper boundary", CosmeticDraw.tier_for_roll(0.029999, 1) == "special")
	expect("rare lower boundary", CosmeticDraw.tier_for_roll(0.03, 1) == "rare")
	expect("rare upper boundary", CosmeticDraw.tier_for_roll(0.199999, 1) == "rare")
	expect("normal lower boundary", CosmeticDraw.tier_for_roll(0.20, 1) == "normal")
	expect("normal upper boundary", CosmeticDraw.tier_for_roll(0.999999, 1) == "normal")
	expect("40th guarantees special", CosmeticDraw.tier_for_roll(0.999999, 40) == "special")
	print("무료 뽑기 확률 경계와 천장 검사 완료")
