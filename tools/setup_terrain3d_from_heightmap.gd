@tool
extends Node

## One-shot Terrain3D heightmap importer.
##
## 1. Open setup_terrain3d_from_heightmap.tscn in the editor
## 2. Tool _ready() runs automatically on scene open
## 3. Delete this scene after import

const HEIGHTMAP_PATH := "res://assets/textures/terrain/heightmaps/terrain_heightmap.png"
const ASSETS_PATH := "res://assets/textures/terrain/terrain_assets.tres"
const DATA_DIR := "res://assets/terrain3d/data/"

const HEIGHT_OFFSET := -0.5
const HEIGHT_SCALE := 32.0
const REGION_SIZE := 512


func _ready() -> void:
	if not Engine.is_editor_hint():
		return

	var dir := DirAccess.open(DATA_DIR)
	if dir and dir.file_exists("terrain3d_00_00.res"):
		print("Terrain3D data already exists. Delete ", DATA_DIR, " to re-import.")
		return

	print("=== Terrain3D Heightmap Import ===")
	print("Loading: ", HEIGHTMAP_PATH)

	var htex: Texture2D = load(HEIGHTMAP_PATH)
	if htex == null:
		push_error("Failed to load heightmap")
		return

	var src_img: Image = htex.get_image()
	src_img.convert(Image.FORMAT_RF)
	print("Size: ", src_img.get_width(), "x", src_img.get_height())

	var terrain := Terrain3D.new()
	terrain.name = "Terrain3D_Setup"
	add_child(terrain)
	terrain.owner = self

	terrain.material = Terrain3DMaterial.new()
	terrain.material.world_background = Terrain3DMaterial.NONE
	terrain.material.auto_shader = true

	if ResourceLoader.exists(ASSETS_PATH):
		terrain.assets = load(ASSETS_PATH)
		print("Assets: ", terrain.assets.get_texture_count(), " textures")
	else:
		push_error("Assets not found: ", ASSETS_PATH)
		return

	terrain.region_size = REGION_SIZE
	print("Region size: ", REGION_SIZE)

	var img_w := src_img.get_width()
	var img_h := src_img.get_height()
	var import_pos := Vector3(-img_w / 2.0, 0, -img_h / 2.0)

	print("Importing heightmap...")
	terrain.data.import_images([src_img, null, null], import_pos, HEIGHT_OFFSET, HEIGHT_SCALE)

	DirAccess.make_dir_recursive_absolute(DATA_DIR)
	terrain.data.save_directory(DATA_DIR)

	var count := terrain.data.get_region_count()
	print("=== Import complete: ", count, " regions ===")
	print("Saved to: ", DATA_DIR)
