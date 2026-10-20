class_name AdGateway
extends RefCounted
## 광고 SDK와 게임 보상을 잇는다. 설정은 로컬 데이터이며 지표를 전송하지 않는다.
static var _provider: RefCounted
static var _clock: AdClock = AdClock.new()
static var _config: Dictionary = {}
static var _session_started := false
static var _session_rewarded := 0
static var _session_interstitial := 0
static var _rewarded_end_tick := -1000000
static var _interstitial_end_tick := -1000000
static var _busy := false
static var _serial := 0
static var persist: Callable

static func config() -> Dictionary:
	if _config.is_empty():
		_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/monetization/ads.json"))
	return _config

static func configure(provider: RefCounted, clock: AdClock = null) -> void:
	_provider = provider
	if clock != null:
		_clock = clock

static func begin_session(profile: Profile) -> bool:
	if _session_started:
		return false
	_session_started = true
	profile.ad_sessions += 1
	return true

static func is_busy() -> bool:
	return _busy

static func is_available() -> bool:
	return _provider != null and _provider.ready("rewarded")

static func _elapsed(last_wall: int, last_tick: int) -> int:
	if last_wall == 0:
		return 1000000
	# 어느 시계가 되돌아가도 간격이 새로 열리지 않는다.
	return mini(_clock.now() - last_wall, _clock.ticks() - last_tick)

static func _daily_count(key: String, count: int) -> int:
	return 0 if key == "" or _clock.today() > key else count

static func can_open(profile: Profile, placement := "activity_bonus") -> bool:
	var rules: Dictionary = config().rewarded
	if _busy or not is_available() or _session_rewarded >= int(rules.session_cap):
		return false
	if _daily_count(profile.ad_daily_key, profile.ad_daily_count) >= int(rules.daily_cap):
		return false
	if _elapsed(profile.ad_rewarded_end, _rewarded_end_tick) < int(rules.cooldown_seconds):
		return false
	if placement == "daily_gems" and profile.ad_gem_day != "" and _clock.today() <= profile.ad_gem_day:
		return false
	return placement in ["activity_bonus", "daily_gems"]

static func request_rewarded(profile: Profile, placement: String, reward: Callable, finished: Callable) -> bool:
	if not can_open(profile, placement):
		return false
	_busy = true
	_serial += 1
	var token := _serial
	var state := {"shown": false, "earned": false, "closed": false}
	_provider.show_rewarded(
		func() -> void:
			if token != _serial or state.closed or state.earned or not state.shown:
				return
			state.earned = true
			if reward.is_valid():
				if placement == "daily_gems":
					profile.ad_gem_day = _clock.today() if _clock.today() > profile.ad_gem_day else profile.ad_gem_day
					profile.add_premium(int(config().daily_gems.amount))
				reward.call(),
		func() -> void:
			if token != _serial or state.closed:
				return
			state.closed = true
			if state.shown:
				profile.ad_rewarded_end = maxi(profile.ad_rewarded_end, _clock.now())
				_rewarded_end_tick = _clock.ticks()
			_busy = false
			if finished.is_valid(): finished.call(bool(state.earned)),
		func() -> void:
			if token != _serial or state.closed or state.shown: return
			state.shown = true
			_session_rewarded += 1
			if profile.ad_daily_key == "" or _clock.today() > profile.ad_daily_key:
				profile.ad_daily_key = _clock.today()
				profile.ad_daily_count = 0
			profile.ad_daily_count += 1
			if persist.is_valid(): persist.call())
	return true

static func can_interstitial(profile: Profile) -> bool:
	var rules: Dictionary = config().interstitial
	return not _busy and _provider != null and _provider.ready("interstitial") \
		and profile.ad_sessions >= int(rules.first_session) \
		and _session_interstitial < int(rules.session_cap) \
		and _daily_count(profile.ad_interstitial_day, profile.ad_interstitial_count) < int(rules.daily_cap) \
		and _elapsed(profile.ad_interstitial_end, _interstitial_end_tick) >= int(rules.cooldown_seconds) \
		and _elapsed(profile.ad_rewarded_end, _rewarded_end_tick) >= int(rules.after_rewarded_seconds)

static func request_interstitial(profile: Profile, finished: Callable) -> bool:
	if not can_interstitial(profile): return false
	_busy = true
	_serial += 1
	var token := _serial
	var state := {"shown": false, "closed": false}
	_provider.show_interstitial(
		func() -> void:
			if token != _serial or state.closed or state.shown: return
			state.shown = true
			_session_interstitial += 1
			if profile.ad_interstitial_day == "" or _clock.today() > profile.ad_interstitial_day:
				profile.ad_interstitial_day = _clock.today()
				profile.ad_interstitial_count = 0
			profile.ad_interstitial_count += 1
			if persist.is_valid(): persist.call(),
		func() -> void:
			if token != _serial or state.closed: return
			state.closed = true
			if state.shown:
				profile.ad_interstitial_end = maxi(profile.ad_interstitial_end, _clock.now())
				_interstitial_end_tick = _clock.ticks()
			_busy = false
			if finished.is_valid(): finished.call())
	return true

static func privacy_options_required() -> bool:
	return _provider != null and _provider.has_method("privacy_options_required") and _provider.privacy_options_required()

static func show_privacy_options() -> void:
	if _provider != null and _provider.has_method("show_privacy_options"):
		_provider.show_privacy_options()

static func reset_test_state() -> void:
	_provider = null
	persist = Callable()
	_clock = AdClock.new()
	_session_started = false
	_session_rewarded = 0
	_session_interstitial = 0
	_rewarded_end_tick = -1000000
	_interstitial_end_tick = -1000000
	_busy = false
	_serial += 1
