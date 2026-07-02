@tool
class_name AssetPlacer
extends RefCounted


const _GhostPreviewScript := preload("res://addons/asset_placer/scripts/ghost_preview.gd")

enum State { IDLE, PLACING }

var state: int = State.IDLE
var active_prefab_path: String = ""
var _ghost


func enter_placing_mode(prefab_path: String) -> void:
	state = State.PLACING
	active_prefab_path = prefab_path

	if not _ghost:
		_ghost = _GhostPreviewScript.new()

	var prefab := load(prefab_path) as PackedScene
	if prefab:
		_ghost.source_scene = prefab

	var root := EditorInterface.get_edited_scene_root()
	if root and not _ghost.is_inside_tree():
		root.add_child(_ghost)
		_ghost.show_at(Vector3.ZERO)


func exit_placing_mode() -> void:
	state = State.IDLE
	active_prefab_path = ""
	if _ghost:
		_ghost.hide_preview()
		if _ghost.is_inside_tree():
			_ghost.get_parent().remove_child(_ghost)


func is_placing() -> bool:
	return state == State.PLACING


func handle_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if state != State.PLACING:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseMotion:
		_update_ghost(viewport_camera, event.position)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place(viewport_camera, event.position)
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			MOUSE_BUTTON_RIGHT:
				exit_placing_mode()
				return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _update_ghost(camera: Camera3D, mouse_pos: Vector2) -> void:
	var result := _raycast(camera, mouse_pos)
	if result.is_empty():
		_ghost.hide_preview()
		return
	_ghost.show_at(result.position, result.normal)


func _raycast(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	if not space:
		return _intersect_ground_plane(
			camera.project_ray_origin(mouse_pos),
			camera.project_ray_normal(mouse_pos)
		)

	var origin := camera.project_ray_origin(mouse_pos)
	var normal := camera.project_ray_normal(mouse_pos)
	var end := origin + normal * 1000.0

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	if _ghost:
		query.exclude = [_ghost]
	var result := space.intersect_ray(query)
	if not result.is_empty():
		return result
	return _intersect_ground_plane(origin, normal)


func _intersect_ground_plane(origin: Vector3, direction: Vector3) -> Dictionary:
	if absf(direction.y) < 0.0001:
		return {}
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return {}
	return {
		"position": origin + direction * distance,
		"normal": Vector3.UP,
	}


func _place(camera: Camera3D, mouse_pos: Vector2) -> void:
	var result := _raycast(camera, mouse_pos)
	if result.is_empty():
		return

	var prefab := load(active_prefab_path) as PackedScene
	if not prefab:
		return

	var instance := prefab.instantiate() as Node3D
	if not instance:
		return

	instance.global_position = result.position

	var root := EditorInterface.get_edited_scene_root()
	if not root:
		instance.queue_free()
		return

	root.add_child(instance, true)
	instance.owner = root

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(instance)
