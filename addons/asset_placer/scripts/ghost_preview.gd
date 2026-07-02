@tool
class_name GhostPreview
extends Node3D


var source_scene: PackedScene:
	set(value):
		source_scene = value
		_rebuild_preview()


func _rebuild_preview() -> void:
	for child in get_children():
		child.queue_free()

	if not source_scene:
		return

	var instance := source_scene.instantiate()
	add_child(instance)
	_make_transparent(instance, 0.35)


func _make_transparent(node: Node, alpha: float) -> void:
	for child in node.get_children(false):
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh:
				for i in mi.mesh.get_surface_count():
					var mat := mi.mesh.surface_get_material(i)
					if mat and mat is BaseMaterial3D:
						var ghost_mat := mat.duplicate() as BaseMaterial3D
						ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						ghost_mat.albedo_color.a = alpha
						ghost_mat.disable_ambient_light = true
						mi.set_surface_override_material(i, ghost_mat)
		_make_transparent(child, alpha)


func show_at(position: Vector3, normal: Vector3 = Vector3.UP) -> void:
	global_position = position
	visible = true


func hide_preview() -> void:
	visible = false
