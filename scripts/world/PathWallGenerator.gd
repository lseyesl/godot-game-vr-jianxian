@tool
extends Node3D
class_name PathWallGenerator

@export var wall_scene: PackedScene
@export var wall_width_m := 2.0
@export var wall_y_offset := 0.0
@export var generated_parent_name := "GeneratedWalls"
@export var auto_generate_on_ready := true
@export var regenerate := false:
	set(value):
		regenerate = false
		if value:
			generate_walls()


func _ready() -> void:
	if auto_generate_on_ready:
		generate_walls()


func generate_walls() -> Node3D:
	var generated_parent := _recreate_generated_parent()
	if wall_scene == null or wall_width_m <= 0.0:
		return generated_parent

	for path in _get_wall_paths():
		_generate_path_walls(path, generated_parent)
	return generated_parent


func _get_wall_paths() -> Array[Path3D]:
	var paths: Array[Path3D] = []
	for child in get_children():
		if child is Path3D and child.curve != null and child.curve.get_baked_length() > 0.0:
			paths.append(child)
	paths.sort_custom(func(a: Path3D, b: Path3D) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	return paths


func _recreate_generated_parent() -> Node3D:
	var existing := get_node_or_null(generated_parent_name)
	if existing != null:
		remove_child(existing)
		existing.free()

	var generated_parent := Node3D.new()
	generated_parent.name = generated_parent_name
	add_child(generated_parent)
	return generated_parent


func _generate_path_walls(path: Path3D, generated_parent: Node3D) -> void:
	var curve := path.curve
	var length := curve.get_baked_length()
	var segment_count := ceili(length / wall_width_m)
	if segment_count <= 0:
		return

	var segment_length := length / float(segment_count)
	for index in range(segment_count):
		var start_offset := segment_length * float(index)
		var end_offset := segment_length * float(index + 1)
		var mid_offset := (start_offset + end_offset) * 0.5
		var local_mid := curve.sample_baked(mid_offset)
		var local_start := curve.sample_baked(start_offset)
		var local_end := curve.sample_baked(end_offset)
		var local_tangent := local_end - local_start
		if local_tangent.length_squared() <= 0.0001:
			continue

		var wall := wall_scene.instantiate() as Node3D
		if wall == null:
			continue

		wall.name = "%s_%03d" % [path.name, index]
		generated_parent.add_child(wall)
		_place_wall(wall, generated_parent, path, local_mid, local_tangent.normalized(), segment_length)
		wall.set_meta("path_name", path.name)
		wall.set_meta("segment_index", index)
		wall.set_meta("segment_count", segment_count)
		wall.set_meta("segment_length_m", segment_length)


func _place_wall(
	wall: Node3D,
	generated_parent: Node3D,
	path: Path3D,
	local_mid: Vector3,
	local_tangent: Vector3,
	segment_length: float
) -> void:
	var town_wall_position := path.transform * local_mid
	town_wall_position.y += wall_y_offset

	var town_wall_tangent := (path.transform.basis * local_tangent).normalized()
	var local_x_axis := (generated_parent.transform.basis.inverse() * town_wall_tangent).normalized()
	if local_x_axis.length_squared() <= 0.0001:
		local_x_axis = Vector3.RIGHT

	var local_y_axis := Vector3.UP
	var local_z_axis := local_x_axis.cross(local_y_axis).normalized()
	if local_z_axis.length_squared() <= 0.0001:
		local_z_axis = Vector3.FORWARD
	local_y_axis = local_z_axis.cross(local_x_axis).normalized()

	var scale_x := segment_length / wall_width_m
	var local_position := generated_parent.transform.affine_inverse() * town_wall_position
	wall.transform = Transform3D(
		Basis(local_x_axis * scale_x, local_y_axis, local_z_axis),
		local_position
	)
