@tool
extends Control

## NavMesh Workflow Panel — scan, inspect, and bake NavigationRegion3D nodes.
##
## Scans the currently edited scene for NavigationRegion3D nodes, displays
## their polygon count, and provides one-click bake/rebake.

const FONT_SIZE_NAME := 14
const FONT_SIZE_INFO := 12

@onready var nav_region_item_list := $VBoxContainer/NavRegionList as ItemList
@onready var scan_button := $VBoxContainer/ScanBar/ScanButton as Button
@onready var bake_selected_button := $VBoxContainer/ActionBar/BakeSelected as Button
@onready var bake_all_button := $VBoxContainer/ActionBar/BakeAll as Button
@onready var status_label := $VBoxContainer/StatusLabel as Label

var _nav_regions: Array[NavigationRegion3D] = []


func _ready() -> void:
	scan_button.pressed.connect(_on_scan_pressed)
	bake_selected_button.pressed.connect(_on_bake_selected_pressed)
	bake_all_button.pressed.connect(_on_bake_all_pressed)
	_scan_nav_regions()


func _on_scan_pressed() -> void:
	_scan_nav_regions()


func _on_bake_selected_pressed() -> void:
	var selected := nav_region_item_list.get_selected_items()
	if selected.is_empty():
		status_label.text = "No NavigationRegion3D selected"
		return
	var index := selected[0]
	if index < 0 or index >= _nav_regions.size():
		return
	_bake_nav_region_and_update(_nav_regions[index])


func _on_bake_all_pressed() -> void:
	if _nav_regions.is_empty():
		status_label.text = "No NavigationRegion3D found"
		return
	for nav_region in _nav_regions:
		_bake_nav_region(nav_region)
	_update_list()
	status_label.text = "Baked %d NavigationRegion3D(s)" % _nav_regions.size()


func _scan_nav_regions() -> void:
	_nav_regions.clear()
	nav_region_item_list.clear()
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		status_label.text = "No scene open — open or select a scene"
		return
	for child in root.find_children("*", "NavigationRegion3D", true, true):
		_nav_regions.push_back(child as NavigationRegion3D)
	_update_list()
	status_label.text = "Found %d NavigationRegion3D(s)" % _nav_regions.size()


func _update_list() -> void:
	nav_region_item_list.clear()
	for i in range(_nav_regions.size()):
		var nr := _nav_regions[i]
		var nm: NavigationMesh = nr.navigation_mesh
		var polygon_count := nm.get_polygon_count() if nm else 0
		var text := "%s — %d polygon(s)" % [nr.name, polygon_count]
		nav_region_item_list.add_item(text)


func _bake_nav_region_and_update(nav_region: NavigationRegion3D) -> void:
	_bake_nav_region(nav_region)
	_update_list()
	status_label.text = "Baked: %s" % nav_region.name


func _bake_nav_region(nav_region: NavigationRegion3D) -> void:
	var nav_mesh := nav_region.navigation_mesh
	if nav_mesh == null:
		nav_mesh = NavigationMesh.new()
		nav_region.navigation_mesh = nav_mesh

	# Collect source geometry from standard scene nodes
	var source_geo := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source_geo, nav_region)

	# Add Terrain3D source geometry for any Terrain3D children
	for terrain in nav_region.find_children("*", "Terrain3D", true, true):
		if not terrain.has_method(&"generate_nav_mesh_source_geometry"):
			continue
		var aabb: AABB = nav_mesh.filter_baking_aabb
		aabb.position += nav_mesh.filter_baking_aabb_offset
		if nav_region.is_inside_tree():
			aabb = nav_region.global_transform * aabb
		var faces := terrain.generate_nav_mesh_source_geometry(aabb)
		if not faces.is_empty():
			source_geo.add_faces(faces, Transform3D.IDENTITY)

	# Bake the navigation mesh
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source_geo)

	# Post-process: round vertices to cell grid to avoid Godot issue #85548
	_postprocess_nav_mesh(nav_mesh)

	# Force editor debug display to refresh
	nav_region.set_navigation_mesh(null)
	nav_region.set_navigation_mesh(nav_mesh)

	# Save to disk if the navmesh is an external resource
	if not nav_mesh.get_path().is_empty():
		ResourceSaver.save(nav_mesh, nav_mesh.get_path(), ResourceSaver.FLAG_COMPRESS)


static func _postprocess_nav_mesh(nav_mesh: NavigationMesh) -> void:
	if nav_mesh.get_polygon_count() == 0:
		return

	var cell_size := Vector3(nav_mesh.cell_size, nav_mesh.cell_height, nav_mesh.cell_size)
	var round_factor := cell_size * 1.001
	var vertices := nav_mesh.get_vertices()
	for i in range(vertices.size()):
		vertices[i] = (vertices[i] / round_factor).floor() * round_factor

	# Rebuild polygons removing any that collapsed to < 3 vertices
	var polygons: Array[PackedInt32Array] = []
	for i in range(nav_mesh.get_polygon_count()):
		var old_poly := nav_mesh.get_polygon(i)
		var new_poly: PackedInt32Array = []
		var seen: PackedVector3Array = []
		for idx in old_poly:
			var v := vertices[idx]
			if seen.has(v):
				continue
			seen.push_back(v)
			new_poly.push_back(idx)
		if new_poly.size() > 2:
			polygons.push_back(new_poly)

	nav_mesh.clear_polygons()
	nav_mesh.set_vertices(vertices)
	for poly in polygons:
		nav_mesh.add_polygon(poly)
