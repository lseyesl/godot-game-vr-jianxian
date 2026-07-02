@tool
extends EditorPlugin

const PANEL_NAME := "Asset Placer"

var bottom_panel: Control
var browser_panel: AssetBrowserPanel
var scanner: AssetScanner
var placer: AssetPlacer


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()

	scanner = AssetScanner.new()
	placer = AssetPlacer.new()

	var panel_scene := load("res://addons/asset_placer/panels/asset_browser_panel.tscn") as PackedScene
	bottom_panel = panel_scene.instantiate() as Control
	browser_panel = bottom_panel as AssetBrowserPanel
	browser_panel.scanner = scanner
	browser_panel.start_placing.connect(_on_start_placing)
	browser_panel.stop_placing.connect(_on_stop_placing)

	add_control_to_bottom_panel(bottom_panel, PANEL_NAME)
	make_bottom_panel_item_visible(bottom_panel)


func _exit_tree() -> void:
	if bottom_panel:
		remove_control_from_bottom_panel(bottom_panel)
		bottom_panel.queue_free()
		bottom_panel = null
		browser_panel = null

	placer = null
	scanner = null


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if placer and placer.is_placing():
		return placer.handle_input(viewport_camera, event)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_start_placing(path: String) -> void:
	placer.enter_placing_mode(path)


func _on_stop_placing() -> void:
	placer.exit_placing_mode()
