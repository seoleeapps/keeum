extends RefCounted
## Poing AdMob v5.1.0의 실제 API. 네이티브 singleton이 없는 개발 환경에서는 호출하지 않는다.
var _initialized := false
var _initializing := false
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _rewarded_loader: RewardedAdLoader
var _interstitial_loader: InterstitialAdLoader
var _rewarded_loading := false
var _interstitial_loading := false

func start() -> void:
	var settings: Dictionary = AdGateway.config().android
	if String(settings.rewarded_unit_id).is_empty() or String(settings.interstitial_unit_id).is_empty():
		return
	UserMessagingPlatform.consent_information.update(ConsentRequestParameters.new(),
		_consent_updated, func(_error: FormError) -> void: _initialize_if_allowed())

func _consent_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_error: FormError) -> void: _initialize_if_allowed()),
			func(_error: FormError) -> void: _initialize_if_allowed())
	else:
		_initialize_if_allowed()

func _consent_allows() -> bool:
	return UserMessagingPlatform.consent_information.get_consent_status() in [
		ConsentInformation.ConsentStatus.OBTAINED, ConsentInformation.ConsentStatus.NOT_REQUIRED]

func _initialize_if_allowed() -> void:
	if not _consent_allows() or _initializing: return
	if _initialized:
		_load_rewarded()
		_load_interstitial()
		return
	_initializing = true
	var configuration := RequestConfiguration.new()
	configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_T
	MobileAds.set_request_configuration(configuration)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_initializing = false
		_initialized = true
		_load_rewarded()
		_load_interstitial()
	MobileAds.initialize(listener)

func ready(kind: String) -> bool:
	if not _initialized or not _consent_allows(): return false
	if kind == "rewarded":
		if _rewarded == null: _load_rewarded()
		return _rewarded != null
	if _interstitial == null: _load_interstitial()
	return _interstitial != null

func _load_rewarded() -> void:
	if _rewarded_loading or _rewarded != null or not _consent_allows(): return
	_rewarded_loading = true
	_rewarded_loader = RewardedAdLoader.new()
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_rewarded_loading = false
	_rewarded_loader.load(str(AdGateway.config().android.rewarded_unit_id), AdRequest.new(), callback)

func _load_interstitial() -> void:
	if _interstitial_loading or _interstitial != null or not _consent_allows(): return
	_interstitial_loading = true
	_interstitial_loader = InterstitialAdLoader.new()
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_interstitial_loading = false
	_interstitial_loader.load(str(AdGateway.config().android.interstitial_unit_id), AdRequest.new(), callback)

func show_rewarded(earned: Callable, closed: Callable, shown: Callable) -> void:
	if not ready("rewarded"):
		closed.call_deferred()
		return
	var ad := _rewarded
	_rewarded = null
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_showed_full_screen_content = shown
	var cleanup := func() -> void:
		ad.destroy()
		closed.call()
		_load_rewarded()
	callbacks.on_ad_dismissed_full_screen_content = cleanup
	callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void: cleanup.call()
	ad.full_screen_content_callback = callbacks
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void: earned.call()
	ad.show(reward_listener)

func show_interstitial(shown: Callable, closed: Callable) -> void:
	if not ready("interstitial"):
		closed.call_deferred()
		return
	var ad := _interstitial
	_interstitial = null
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_showed_full_screen_content = shown
	var cleanup := func() -> void:
		ad.destroy()
		closed.call()
		_load_interstitial()
	callbacks.on_ad_dismissed_full_screen_content = cleanup
	callbacks.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void: cleanup.call()
	ad.full_screen_content_callback = callbacks
	ad.show()

func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	# 동의 변경 전에 로드한 광고는 폐기하고 상태를 다시 확인한다.
	if _rewarded != null: _rewarded.destroy()
	if _interstitial != null: _interstitial.destroy()
	_rewarded = null
	_interstitial = null
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError) -> void: _initialize_if_allowed())
