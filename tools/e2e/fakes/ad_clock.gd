class_name FakeAdClock
extends AdClock
var epoch := 1792540800
var elapsed := 1000
var date := "2026-10-21"
func now() -> int: return epoch
func ticks() -> int: return elapsed
func today() -> String: return date
func advance(seconds: int) -> void:
	epoch += seconds
	elapsed += seconds
