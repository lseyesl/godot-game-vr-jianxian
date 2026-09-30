extends StaticBody3D
class_name HeightmapTerrain

@export_file("*.png", "*.jpg", "*.jpeg", "*.exr") var heightmap_path := "res://assets/textures/terrain/heightmaps/terrain_heightmap.png"
@export var world_size := Vector2(120.0, 80.0)
@export_range(2, 513, 1) var sample_columns := 129
@export_range(2, 513, 1) var sample_rows := 129
@export var height_scale_m := 32.0
@export_range(0.0, 1.0, 0.01) var base_gray_level := 0.5
@export var generate_collision := false
@export var regenerate_on_ready := true
@export var terrain_material: Material

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D


func _ready() -> void:
	if regenerate_on_ready:
		generate_from_heightmap()


func generate_from_heightmap() -> bool:
	var image: Image = _load_heightmap_image()
	if image == null or image.is_empty():
		push_error("HeightmapTerrain: failed to load heightmap: %s" % heightmap_path)
		return false

	image.convert(Image.FORMAT_RGB8)
	var mesh := _build_mesh(image)
	if mesh == null:
		return false

	_ensure_nodes()
	mesh_instance.mesh = mesh
	if terrain_material != null:
		mesh_instance.material_override = terrain_material

	if generate_collision:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(_build_collision_faces(mesh))
		collision_shape.shape = shape
		collision_shape.disabled = false
	else:
		collision_shape.shape = null
		collision_shape.disabled = true

	return true


func get_height_at_world_position(world_position: Vector3) -> float:
	var image: Image = _load_heightmap_image()
	if image == null or image.is_empty():
		return world_position.y
	image.convert(Image.FORMAT_RGB8)
	var local_position: Vector3 = global_transform.affine_inverse() * world_position if is_inside_tree() else world_position
	var u: float = local_position.x / world_size.x + 0.5
	var v: float = local_position.z / world_size.y + 0.5
	var local_height := _sample_height(image, u, v)
	if is_inside_tree():
		return (global_transform * Vector3(local_position.x, local_height, local_position.z)).y
	return local_height


func _load_heightmap_image() -> Image:
	var texture: Texture2D = ResourceLoader.load(heightmap_path) as Texture2D
	if texture != null:
		return texture.get_image()

	var image: Image = Image.new()
	var error: Error = image.load(heightmap_path)
	if error != OK:
		return null
	return image


func _ensure_nodes() -> void:
	mesh_instance = get_node_or_null("TerrainMesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "TerrainMesh"
		add_child(mesh_instance)

	collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)


func _build_mesh(image: Image) -> ArrayMesh:
	var cols: int = maxi(sample_columns, 2)
	var rows: int = maxi(sample_rows, 2)
	var vertex_count: int = cols * rows
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	vertices.resize(vertex_count)
	normals.resize(vertex_count)
	uvs.resize(vertex_count)

	for z: int in range(rows):
		var v: float = float(z) / float(rows - 1)
		for x: int in range(cols):
			var u: float = float(x) / float(cols - 1)
			var i: int = z * cols + x
			var height: float = _sample_height(image, u, v)
			vertices[i] = Vector3((u - 0.5) * world_size.x, height, (v - 0.5) * world_size.y)
			uvs[i] = Vector2(u, v)

	for z: int in range(rows - 1):
		for x: int in range(cols - 1):
			var i0: int = z * cols + x
			var i1: int = i0 + 1
			var i2: int = i0 + cols
			var i3: int = i2 + 1
			indices.append_array(PackedInt32Array([i0, i2, i1, i1, i2, i3]))
			var n0: Vector3 = _triangle_normal(vertices[i0], vertices[i2], vertices[i1])
			normals[i0] += n0
			normals[i2] += n0
			normals[i1] += n0
			var n1: Vector3 = _triangle_normal(vertices[i1], vertices[i2], vertices[i3])
			normals[i1] += n1
			normals[i2] += n1
			normals[i3] += n1

	for i: int in range(normals.size()):
		if normals[i].length_squared() > 0.0001:
			normals[i] = normals[i].normalized()
		else:
			normals[i] = Vector3.UP

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _sample_height(image: Image, u: float, v: float) -> float:
	var px: int = clampi(roundi(u * float(image.get_width() - 1)), 0, image.get_width() - 1)
	var py: int = clampi(roundi(v * float(image.get_height() - 1)), 0, image.get_height() - 1)
	var color: Color = image.get_pixel(px, py)
	var gray: float = (color.r + color.g + color.b) / 3.0
	return (gray - base_gray_level) * height_scale_m


func _triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (b - a).cross(c - a).normalized()


func _build_collision_faces(mesh: ArrayMesh) -> PackedVector3Array:
	var faces: PackedVector3Array = PackedVector3Array()
	if mesh.get_surface_count() == 0:
		return faces
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	faces.resize(indices.size())
	for i: int in range(indices.size()):
		faces[i] = vertices[indices[i]]
	return faces
