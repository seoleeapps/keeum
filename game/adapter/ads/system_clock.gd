class_name AdClock
extends RefCounted

func now() -> int:
	return int(Time.get_unix_time_from_system())

func ticks() -> int:
	return int(Time.get_ticks_msec() / 1000)

func today() -> String:
	return Time.get_date_string_from_system()
