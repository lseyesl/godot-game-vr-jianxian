extends Node3D
class_name SceneLodGroup

@export var near_lod_path: NodePath
@export var mid_lod_path: NodePath
@export var far_lod_path: NodePath
@export var mid_distance_m := 25.0
@export var far_distance_m := 70.0
@export var update_interval_sec := 0.25

var _time_until_update := 0.0

func _ready() -> void:
	apply_default_lod()

func _process(delta: float) -> void:
	_time_until_update -= delta
	if _time_until_update > 0.0:
		return
	_time_until_update = update_interval_sec
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		apply_default_lod()
		return
	update_for_camera_position(camera.global_position)

func update_for_camera_position(camera_position: Vector3) -> void:
	var origin := global_position if is_inside_tree() else position
	var distance := origin.distance_to(camera_position)
	if distance >= far_distance_m:
		_set_active_lod(far_lod_path)
	elif distance >= mid_distance_m:
		_set_active_lod(mid_lod_path)
	else:
		_set_active_lod(near_lod_path)

func apply_default_lod() -> void:
	_set_active_lod(near_lod_path)

func _set_active_lod(active_path: NodePath) -> void:
	var paths := [near_lod_path, mid_lod_path, far_lod_path]
	for path in paths:
		var node := _node_for_path(path)
		if node != null:
			node.visible = path == active_path

func _node_for_path(path: NodePath) -> Node3D:
	if path.is_empty():
		return null
	var node := get_node_or_null(path)
	if node is Node3D:
		return node
	return null
