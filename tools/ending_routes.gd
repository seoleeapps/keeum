extends SceneTree
## 시작 seed와 합법적인 활동, 선택으로 만든 실제 48턴 경로를 기록한다.
var content := ContentDB.new()
var routes := {}
var random := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	content.load_all()
	random.seed = 1041
	for trial in 1200:
		var run := GameRun.new()
		run.setup(content)
		var run_seed := trial + 1
		var impression: Dictionary = content.profiles.first_impressions[trial % content.profiles.first_impressions.size()]
		run.start_new({"seed": run_seed, "impression": impression})
		var goal := {
			"academic": [20, 40, 60, 85, 100][random.randi_range(0, 4)],
			"emotion": [20, 50, 70, 85, 100][random.randi_range(0, 4)],
			"talent": [10, 40, 60, 80, 100][random.randi_range(0, 4)],
			"bonding": [30, 60, 75, 95][random.randi_range(0, 3)],
			"stress": [20, 50, 75, 95][random.randi_range(0, 3)],
		}
		var temperament := Balance.TEMPERAMENTS[trial % 6]
		var choices: Array = []
		while not run.is_final_turn():
			var a := _pick(run, "A", goal) if trial != 0 else ""
			var cost := int(content.activity(a).get("cost", 0))
			var b := _pick(run, "B", goal, cost) if trial != 0 else ""
			choices.append({"type": "turn", "a": a, "b": b})
			run.resolve_turn(a, b)
			while run.has_steps():
				var step := run.next_step()
				match str(step.screen):
					"event":
						var index := random.randi_range(0, step.event.choices.size() - 1)
						if trial == 0:
							var worst := 10000
							for i in step.event.choices.size():
								var effects: Dictionary = step.event.choices[i].get("effects", step.event.choices[i].get("reject", {}))
								var score := int(effects.get("bonding", 0)) * 10 + int(effects.get("emotion", 0))
								if score < worst and not step.event.choices[i].has("temptation"):
									worst = score
									index = i
						choices.append({"type": "event", "id": step.event.id, "choice": index})
						run.resolve_event(step.event, index)
					"transition":
						var index := 0
						for i in step.transition.options.size():
							if step.transition.options[i].target == temperament: index = i
						choices.append({"type": "transition", "gate": step.transition.gate, "choice": index})
						run.resolve_transition(step.transition, index)
		for app: String in ["hanul", "stable", "art", "free"]:
			run.set_application(app)
			var ending := run.determine_ending()
			if not routes.has(str(ending.id)):
				routes[str(ending.id)] = {"seed": run_seed, "impression": impression.id, "application": app, "choices": choices, "summary": run.run_summary(ending)}
				print("route %d/40: %s seed=%d" % [routes.size(), ending.id, run_seed])
		if routes.size() == 40: break
		if trial % 200 == 0: await process_frame
	var out := OS.get_environment("KEEUM_ENDING_OUT")
	if out.is_empty(): out = "user://ending-routes"
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out.path_join("routes.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind": "real-48-turn-core-routes", "routes": routes}, "  "))
	var missing: Array = []
	for e: Dictionary in content.endings:
		if not routes.has(str(e.id)): missing.append(e.id)
	print("routes missing: ", missing)
	quit(0 if missing.is_empty() else 1)

func _pick(run: GameRun, slot: String, goal: Dictionary, other_cost := 0) -> String:
	var best := ""
	var best_score := 0.0
	for act: Dictionary in run.available_activities(slot):
		var cost := int(act.get("cost", 0))
		if cost + other_cost > run.household.money: continue
		var score := random.randf_range(-5.0, 5.0)
		if slot == "A":
			var growth := Growth.learn_result(act, run.child)
			for subject: String in growth.subjects:
				score += float(growth.subjects[subject]) * clampf(float(goal.academic - run.child.subject_value(subject)) / 20.0, -2.0, 3.0)
			score += float(growth.stress) * clampf(float(goal.stress - run.child.stress) / 40.0, -2.0, 1.0)
		else:
			var current := {"emotion": run.child.emotion, "talent": run.child.talent, "bonding": run.household.bonding, "stress": run.child.stress}
			for stat: String in current:
				score += float(act.get(stat, 0)) * clampf(float(goal[stat] - current[stat]) / 15.0, -2.0, 2.0)
			score += float(act.get("stamina", 0)) * (0.5 if run.child.stamina < 50 else 0.0)
		# 일정한 저축과 지출을 섞어 학원, 무료 활동 모두 탐색한다.
		score -= float(cost) * (0.08 if run.household.money < 250 else 0.01)
		score += float(act.get("money", 0)) * (0.12 if run.household.money < 200 else 0.02)
		if score > best_score:
			best_score = score
			best = str(act.id)
	return best
