extends Resource
class_name EnvironmentState

const SEASON_SPRING := "spring"
const SEASON_SUMMER := "summer"
const SEASON_AUTUMN := "autumn"
const SEASON_WINTER := "winter"
const HOURS_PER_DAY := 24.0

@export_range(0.0, 24.0, 0.01) var time_of_day_hours := 16.0
@export_enum("spring", "summer", "autumn", "winter") var season := SEASON_SUMMER
@export var time_scale := 0.0

func set_time_from_clock(hour: int, minute: int) -> void:
	time_of_day_hours = _wrap_hours(float(hour) + float(minute) / 60.0)

func advance_time(delta_seconds: float) -> void:
	if time_scale <= 0.0:
		return
	time_of_day_hours = _wrap_hours(time_of_day_hours + delta_seconds * time_scale)

func normalized_day_progress() -> float:
	return time_of_day_hours / HOURS_PER_DAY

func is_summer() -> bool:
	return season == SEASON_SUMMER

func _wrap_hours(hours: float) -> float:
	return fposmod(hours, HOURS_PER_DAY)
