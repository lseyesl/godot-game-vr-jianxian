extends Node3D
class_name Main

const PLAYER_MODE_DESKTOP_SIMULATION := "desktop_simulation"
const PLAYER_MODE_VR := "vr"
const DESKTOP_PLAYER_SCENE_PATH := "res://scenes/player/DesktopDebugPlayer.tscn"
const VR_PLAYER_SCENE_PATH := "res://scenes/player/XRPlayer.tscn"

@export_enum("desktop_simulation", "vr") var player_mode := PLAYER_MODE_DESKTOP_SIMULATION
@export var player_spawn_path: NodePath = ^"PlayerSpawn"
@export var player_spawn_position := Vector3(0, 0, 6)
@export var terrain_spawn_path: NodePath = ^"TerrainContainer/NavigationRegion3D/Terrain3D"
@export var player_spawn_surface_clearance_m := 0.05

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
		if player_node.get_parent() != null:
			player_node.get_parent().remove_child(player_node)
		player_node.free()
	player_node = instantiate_player_for_mode(player_mode)
	if player_node == null:
		return null
	add_child(player_node)
	if player_node is Node3D:
		var spawn_position := resolve_player_spawn_position(player_node)
		if player_node.is_inside_tree() and is_inside_tree():
			player_node.global_position = spawn_position
		else:
			player_node.position = spawn_position
	return player_node

func resolve_player_spawn_position(player: Node = player_node) -> Vector3:
	var spawn_position := resolve_base_player_spawn_position()
	var terrain := get_node_or_null(terrain_spawn_path)
	var terrain_height := get_terrain_height_at_world_position(terrain, spawn_position)
	if is_nan(terrain_height):
		return spawn_position
	var lowest_collision_offset := get_lowest_collision_offset(player)
	var minimum_root_y := terrain_height - lowest_collision_offset + player_spawn_surface_clearance_m
	if minimum_root_y > spawn_position.y:
		spawn_position.y = minimum_root_y
	return spawn_position

func resolve_base_player_spawn_position() -> Vector3:
	var spawn_node := get_node_or_null(player_spawn_path) as Node3D
	if spawn_node == null:
		return player_spawn_position
	if spawn_node.is_inside_tree() and is_inside_tree():
		return spawn_node.global_position
	return spawn_node.position

func get_terrain_height_at_world_position(terrain: Node, world_position: Vector3) -> float:
	if terrain == null:
		return NAN
	if terrain.has_method("get_height_at_world_position"):
		return terrain.get_height_at_world_position(world_position)
	if terrain is Terrain3D:
		var terrain3d := terrain as Terrain3D
		if terrain3d.data == null:
			return NAN
		return terrain3d.data.get_height(world_position)
	return NAN

func get_lowest_collision_offset(player: Node) -> float:
	var player_3d := player as Node3D
	if player_3d == null:
		return 0.0
	var lowest := 0.0
	var found_collision := false
	var shapes := player_3d.find_children("*", "CollisionShape3D", true, false)
	for shape_node in shapes:
		var collision_shape := shape_node as CollisionShape3D
		if collision_shape == null or collision_shape.shape == null:
			continue
		var local_position: Vector3
		if collision_shape.is_inside_tree() and player_3d.is_inside_tree():
			local_position = player_3d.global_transform.affine_inverse() * collision_shape.global_position
		else:
			local_position = collision_shape.position
		var shape_bottom := local_position.y - get_shape_half_height(collision_shape.shape)
		if not found_collision or shape_bottom < lowest:
			lowest = shape_bottom
			found_collision = true
	return lowest if found_collision else 0.0

func get_shape_half_height(shape: Shape3D) -> float:
	if shape is CapsuleShape3D:
		return (shape as CapsuleShape3D).height * 0.5
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size.y * 0.5
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius
	return 0.0
