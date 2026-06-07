extends Node3D
class_name Main

const PLAYER_MODE_DESKTOP_SIMULATION := "desktop_simulation"
const PLAYER_MODE_VR := "vr"
const DESKTOP_PLAYER_SCENE_PATH := "res://scenes/player/DesktopDebugPlayer.tscn"
const VR_PLAYER_SCENE_PATH := "res://scenes/player/XRPlayer.tscn"

@export_enum("desktop_simulation", "vr") var player_mode := PLAYER_MODE_DESKTOP_SIMULATION
@export var player_spawn_position := Vector3(0, 0, 6)

var player_node: Node

func _ready() -> void:
	spawn_player()

func normalize_player_mode(mode: String) -> String:
	if mode == PLAYER_MODE_VR:
		return PLAYER_MODE_VR
	return PLAYER_MODE_DESKTOP_SIMULATION

func resolve_player_scene_path(mode: String = player_mode) -> String:
	if normalize_player_mode(mode) == PLAYER_MODE_VR:
		return VR_PLAYER_SCENE_PATH
	return DESKTOP_PLAYER_SCENE_PATH

func instantiate_player_for_mode(mode: String) -> Node:
	var scene_path := resolve_player_scene_path(mode)
	var packed_scene := load(scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		push_error("Unable to load player scene: %s" % scene_path)
		return null
	return packed_scene.instantiate()

func spawn_player() -> Node:
	if player_node != null:
		player_node.queue_free()
	player_node = instantiate_player_for_mode(player_mode)
	if player_node == null:
		return null
	if player_node is Node3D:
		player_node.position = player_spawn_position
	add_child(player_node)
	return player_node
