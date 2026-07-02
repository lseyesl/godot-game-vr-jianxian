@tool
extends EditorPlugin

const PANEL_NAME := "Prefab Inspector"

var bottom_panel: Control
var inspector_panel: PrefabInspectorPanel
var scanner: PrefabInspectorScanner


func _enter_tree() -> void:
	scanner = PrefabInspectorScanner.new()

	var panel_scene := load("res://addons/prefab_inspector/panels/inspector_panel.tscn") as PackedScene
	bottom_panel = panel_scene.instantiate() as Control
	inspector_panel = bottom_panel as PrefabInspectorPanel
	inspector_panel.scanner = scanner

	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)
	make_bottom_panel_item_visible(bottom_panel)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
		inspector_panel = null
	scanner = null
