class_name WaterBody
extends Node3D

@export_enum("lake", "river", "waterfall") var water_type := "lake"
@export var flow_speed := 0.2
@export var flow_direction := Vector2(0.0, 1.0)
@export var audio_enabled := true
@export var collision_enabled := true

var flow_phase := 0.0
var _water_surfaces: Array[MeshInstance3D] = []

func _ready() -> void:
	_collect_water_surfaces(self)
	_apply_collision_enabled()
	_apply_audio_enabled()
	_update_water_materials()

func _process(delta: float) -> void:
	flow_phase = fmod(flow_phase + maxf(flow_speed, 0.0) * delta, 10000.0)
	_update_water_materials()

func _collect_water_surfaces(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var material := mesh_instance.get_active_material(0)
			if material is ShaderMaterial:
				_water_surfaces.append(mesh_instance)
		_collect_water_surfaces(child)

func _update_water_materials() -> void:
	for mesh_instance in _water_surfaces:
		var material := mesh_instance.get_active_material(0)
		if material is ShaderMaterial:
			material.set_shader_parameter("flow_phase", flow_phase)
			material.set_shader_parameter("flow_direction", flow_direction)

func _apply_collision_enabled() -> void:
	for area in _find_children_of_type(self, "Area3D"):
		area.monitoring = collision_enabled
		area.monitorable = collision_enabled
		for child in area.get_children():
			if child is CollisionShape3D:
				child.disabled = not collision_enabled

func _apply_audio_enabled() -> void:
	for audio_player in _find_children_of_type(self, "AudioStreamPlayer3D"):
		audio_player.autoplay = audio_enabled
		if audio_enabled and audio_player.stream != null and not audio_player.playing:
			audio_player.play()
		elif not audio_enabled and audio_player.playing:
			audio_player.stop()

func _find_children_of_type(node: Node, type_name: StringName) -> Array[Node]:
	var matches: Array[Node] = []
	for child in node.get_children():
		if child.is_class(type_name):
			matches.append(child)
		matches.append_array(_find_children_of_type(child, type_name))
	return matches
