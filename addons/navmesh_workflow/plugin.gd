@tool
extends EditorPlugin

const PANEL_NAME := "NavMesh"

var bottom_panel: Control


func _enter_tree() -> void:
	var panel_scene := load("res://addons/navmesh_workflow/panels/workflow_panel.tscn") as PackedScene
	if panel_scene == null:
		push_error("NavMesh Workflow: Failed to load panel scene")
		return
	bottom_panel = panel_scene.instantiate() as Control
	if bottom_panel == null:
		push_error("NavMesh Workflow: Panel scene root is not a Control")
		return
	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
