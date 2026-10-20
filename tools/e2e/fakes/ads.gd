class_name FakeAds
extends RefCounted
var available := true
var reward_callback: Callable
var close_callback: Callable
var shown_callback: Callable
var requests := 0
var interstitials := 0
func ready(_kind: String) -> bool: return available
func show_rewarded(earned: Callable, closed: Callable, shown: Callable) -> void:
	requests += 1
	reward_callback = earned
	close_callback = closed
	shown_callback = shown
func show_interstitial(shown: Callable, closed: Callable) -> void:
	interstitials += 1
	shown.call()
	closed.call()
func show() -> void: shown_callback.call()
func earn() -> void: reward_callback.call()
func close() -> void: close_callback.call()
