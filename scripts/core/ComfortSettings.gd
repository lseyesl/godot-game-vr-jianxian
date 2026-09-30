extends Resource
class_name ComfortSettings

@export var movement_mode := "comfort"
@export var turn_mode := "snap"
@export var flight_vignette_enabled := true
@export var flight_speed_limit_mps := 6.0
@export var flight_height_limit_m := 45.0

func apply_mode(mode: String) -> void:
	if mode == "immersive":
		movement_mode = "immersive"
		turn_mode = "smooth"
		flight_vignette_enabled = false
		flight_speed_limit_mps = 9.0
		flight_height_limit_m = 60.0
	else:
		movement_mode = "comfort"
		turn_mode = "snap"
		flight_vignette_enabled = true
		flight_speed_limit_mps = 6.0
		flight_height_limit_m = 45.0
