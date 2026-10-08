extends Node3D
class_name PlayableJourney

const DesktopScene = preload("res://scenes/player/DesktopDebugPlayer.tscn")
const DialogueScript = preload("res://scripts/npc/NpcDialogue.gd")
const SealScene = preload("res://scenes/interaction/SealEncounter.tscn")
const SwordScene = preload("res://scenes/items/FlyingSword.tscn")
const DemonScript = preload("res://scripts/enemies/LesserDemon.gd")
const HealthScript = preload("res://scripts/combat/HealthComponent.gd")
const HudScript = preload("res://scripts/ui/JourneyHud.gd")
const TARGETS := {
	"start": Vector3(-5, 0, 3), "ask_tavern": Vector3(5, 0, -11),
	"go_to_mountain": Vector3(0, 0, -49), "cleanse_seal": Vector3(0, 1.5, -65),
	"collect_sword": Vector3(0, 1.0, -70), "fly_back": Vector3(0, 5, 16),
	"complete": Vector3(0, 5, 16),
}

var player_node: Node3D
var seal: Node3D
var sword: Node3D
var demons: Array[Node3D] = []
var beacon: Node3D
var hud: CanvasLayer
var elapsed := 0.0
var flight_sword: MeshInstance3D

func _ready() -> void:
	_build_world()
	_spawn_player()
	seal = SealScene.instantiate()
	seal.position = TARGETS.cleanse_seal
	seal.require_defeated_enemies = true
	add_child(seal)
	seal.get_node("SealVisual").material_override = _material(Color("#a556bd"), true)
	seal.get_node("DemonVisual").hide()
	sword = SwordScene.instantiate()
	sword.position = TARGETS.collect_sword
	add_child(sword)
	sword.get_node("Blade").material_override = _material(Color("#9aefdf"), true)
	_spawn_demon(Vector3(-3, 0, -58), "山魈 · 左")
	_spawn_demon(Vector3(3, 0, -62), "山魈 · 右")
	_npc("innkeeper", "云来客栈 · 掌柜", TARGETS.start)
	_npc("tavern_keeper", "听雨酒馆 · 说书人", TARGETS.ask_tavern)
	_npc("trial_spirit", "守山灵", Vector3(-5, 0, -50))
	_trigger("Trial", Vector3(0, 1, -49), Vector3(12, 4, 6), "entered_trial")
	_trigger("Return", Vector3(0, 6, 16), Vector3(7, 3, 6), "returned_to_town")
	beacon = Node3D.new()
	add_child(beacon)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	_mesh(beacon, ring, Vector3(0, 0.12, 0), Color("#83ead4"), true)
	var bus := get_node("/root/EventBus")
	bus.quest_step_changed.connect(_on_step)
	bus.enemy_defeated.connect(_on_enemy_defeated)
	_restore_checkpoint()
	hud = HudScript.new()
	add_child(hud)
	_on_step(get_node("/root/Game").quest_state.current_step)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if flight_sword != null: flight_sword.visible = player_node.flight_enabled
	if is_instance_valid(sword) and not sword.unlocked:
		sword.get_node("Blade").rotation.y += delta
		sword.get_node("Blade").position.y = sin(elapsed * 2.0) * 0.13
	if is_instance_valid(beacon):
		beacon.rotation.y += delta * 0.5
	if is_instance_valid(player_node) and player_position().y < -12.0:
		get_node("/root/EventBus").player_defeated.emit("坠落")

func player_position() -> Vector3:
	if player_node.has_method("get_body_position"):
		return player_node.get_body_position()
	return player_node.global_position

func _spawn_player() -> void:
	var game := get_node("/root/Game")
	var scene: PackedScene = DesktopScene
	if game.selected_player_mode == "vr":
		var xr := XRServer.find_interface("OpenXR")
		if xr != null and (xr.is_initialized() or xr.initialize()):
			get_viewport().use_xr = true
			scene = load("res://scenes/player/XRPlayer.tscn")
		else:
			game.selected_player_mode = "desktop_simulation"
	player_node = scene.instantiate()
	player_node.position = checkpoint_position(game.quest_state.current_step)
	add_child(player_node)
	var blade := BoxMesh.new()
	blade.size = Vector3(0.22, 0.06, 2.1)
	var mount: Node3D = player_node
	if game.selected_player_mode == "vr": mount = player_node.get_node("XROrigin3D/PlayerBody")
	flight_sword = _mesh(mount, blade, Vector3(0, 0.15, -0.3), Color("#86ded0"), true)
	flight_sword.visible = false

static func checkpoint_position(step: String) -> Vector3:
	match step:
		"go_to_mountain": return Vector3(0, 0.1, -18)
		"cleanse_seal": return Vector3(0, 0.1, -49)
		"collect_sword": return Vector3(0, 0.1, -67)
		"fly_back": return Vector3(0, 1, -67)
		"complete": return Vector3(0, 5.1, 16)
		_: return Vector3(0, 0.1, 9)

func _restore_checkpoint() -> void:
	var game := get_node("/root/Game")
	var step: String = game.quest_state.current_step
	if step in ["collect_sword", "fly_back", "complete"]:
		seal.cleansed = true
		seal.remaining_hits = 0
		seal.hide()
		seal.get_node("HitArea").set_deferred("monitorable", false)
		for demon in demons:
			demon.queue_free()
		demons.clear()
	if game.save_state.sword_unlocked:
		sword.unlocked = true
		sword.hide()
		get_node("/root/EventBus").flight_mode_changed.emit(true)

func _on_step(step: String) -> void:
	beacon.position = TARGETS.get(step, Vector3.ZERO)
	beacon.visible = step != "complete"
	if step in ["collect_sword", "fly_back", "complete"]:
		seal.hide()
	if step in ["fly_back", "complete"]:
		sword.hide()
	for demon in demons:
		if is_instance_valid(demon) and not demon.defeated:
			demon.set_physics_process(step == "cleanse_seal")

func _on_enemy_defeated(enemy_id: String) -> void:
	for demon in demons:
		if is_instance_valid(demon) and demon.enemy_id == enemy_id:
			demon.hide()
			demon.get_node("CollisionShape3D").set_deferred("disabled", true)

func _spawn_demon(pos: Vector3, id: String) -> void:
	var demon := DemonScript.new()
	demon.enemy_id = id
	demon.sight_range_m = 20
	demon.move_speed_mps = 1.65
	demon.position = pos
	var health := HealthScript.new()
	health.name = "HealthComponent"
	health.target_id = id
	demon.add_child(health)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	_collision(demon, shape, Vector3(0, 0.9, 0))
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.8
	_mesh(demon, body, Vector3(0, 0.9, 0), Color("#a34a6c"))
	_label(demon, id, Vector3(0, 2.3, 0), Color("#f2a9bf"))
	add_child(demon)
	demons.append(demon)

func _npc(id: String, title: String, pos: Vector3) -> void:
	var npc := Node3D.new()
	npc.name = id
	npc.position = pos
	var dialogue := DialogueScript.new()
	dialogue.npc_id = id
	npc.add_child(dialogue)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = 1.6
	_mesh(npc, mesh, Vector3(0, 0.8, 0), Color("#579b98"))
	_label(npc, title + "\n靠近后按 F / 右 A 交谈", Vector3(0, 2.3, 0), Color("#e2cb94"))
	var area := Area3D.new()
	area.collision_layer = 0
	var shape := SphereShape3D.new()
	shape.radius = 2.7
	_collision(area, shape, Vector3(0, 1, 0))
	area.body_entered.connect(dialogue._on_interact_area_body_entered)
	area.body_exited.connect(dialogue._on_interact_area_body_exited)
	npc.add_child(area)
	add_child(npc)

func _trigger(id: String, pos: Vector3, size: Vector3, event: String) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.name = id
	area.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	_collision(area, shape, Vector3.ZERO)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			get_node("/root/Game").advance_quest(event)
	)
	add_child(area)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#173d50")
	sky_mat.sky_horizon_color = Color("#a6c2bf")
	sky_mat.ground_horizon_color = Color("#a6c2bf")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#bedbd7")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -25, 0)
	sun.light_color = Color("#ffe5b9")
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	_box(self, Vector3(0, -0.65, -27), Vector3(54, 1.3, 114), Color("#365b52"), true)
	_box(self, Vector3(0, 0.015, -28), Vector3(4, 0.03, 104), Color("#82988c"))
	for z in range(-76, 23, 3):
		_box(self, Vector3(0, 0.04, z), Vector3(3.5, 0.04, 0.06), Color("#c7c5a3"))
	_building(Vector3(-10, 0, 3), "云来客栈", Color("#825446"))
	_building(Vector3(10, 0, -11), "听雨酒馆", Color("#4c777a"))
	for z in [16, -13, -27]:
		_building(Vector3(-16, 0, z), "", Color("#536967"))
		_building(Vector3(16, 0, z), "", Color("#536967"))
	_box(self, Vector3(-4, 2.5, -30), Vector3(0.5, 5, 0.5), Color("#704b3a"), true)
	_box(self, Vector3(4, 2.5, -30), Vector3(0.5, 5, 0.5), Color("#704b3a"), true)
	_box(self, Vector3(0, 4.7, -30), Vector3(10, 0.5, 1.6), Color("#273f46"))
	_label(self, "青 岚 山  ·  试 炼 道", Vector3(0, 3.8, -29.7), Color("#e2cb94"))
	_box(self, Vector3(0, 4.5, 16), Vector3(8, 1, 7), Color("#617d7b"), true)
	for x in [-3, 3]:
		_box(self, Vector3(x, 2, 16), Vector3(0.6, 4, 0.6), Color("#617d7b"), true)
	_label(self, "归 剑 台\n取回飞剑后，飞上高台", Vector3(0, 7, 16), Color("#e2cb94"))
	_label(self, "山 谷 封 印\n先驱散两只山魈，再以灵光弹 / 破封诀净化", Vector3(0, 5, -70), Color("#d7c9e9"))
	for i in range(24):
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector3(side * (10 + i % 5 * 3), 0, -34 - i * 2)
		_tree(pos)
	for i in range(12):
		var mountain := CylinderMesh.new()
		mountain.top_radius = 0.0
		mountain.bottom_radius = 12 + i % 3 * 5
		mountain.height = 22 + i % 4 * 9
		mountain.radial_segments = 7
		_mesh(self, mountain, Vector3(-70 + i * 13, mountain.height * 0.5 - 3, -112 - i % 3 * 8), Color("#416b72"))
	for z in range(-70, 20, 12):
		for x in [-3.2, 3.2]:
			_box(self, Vector3(x, 0.6, z), Vector3(0.15, 1.2, 0.15), Color("#745e45"))
			_box(self, Vector3(x, 1.3, z), Vector3(0.35, 0.4, 0.35), Color("#eabe78"), false, true)

func _building(pos: Vector3, title: String, color: Color) -> void:
	_box(self, pos + Vector3(0, 1.6, 0), Vector3(6, 3.2, 6), color, true)
	for y in [3.3, 4.1]:
		var roof := CylinderMesh.new()
		roof.top_radius = 0.6
		roof.bottom_radius = 5.2 - (y - 3.3)
		roof.height = 1.4
		roof.radial_segments = 4
		var visual := _mesh(self, roof, pos + Vector3(0, y, 0), Color("#23494f"))
		visual.rotation.y = PI / 4.0
	if not title.is_empty():
		_label(self, title, pos + Vector3(0, 5.5, 0), Color("#e2cb94"))

func _tree(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 1.5, 0), Vector3(0.4, 3, 0.4), Color("#605448"))
	for y in [2.8, 4.0, 5.0]:
		var crown := CylinderMesh.new()
		crown.top_radius = 0
		crown.bottom_radius = 2.4 - y * 0.25
		crown.height = 2.4
		crown.radial_segments = 7
		_mesh(self, crown, pos + Vector3(0, y, 0), Color("#346c62"))

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color, solid: bool = false, glow: bool = false) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(parent, mesh, pos, color, glow)
	if solid:
		var body := StaticBody3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		_collision(body, shape, pos)
		parent.add_child(body)

func _mesh(parent: Node, mesh: Mesh, pos: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _material(color, glow)
	visual.position = pos
	parent.add_child(visual)
	return visual

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	material.emission_enabled = glow
	material.emission = color
	return material

func _collision(parent: Node, shape: Shape3D, pos: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)

func _label(parent: Node, text: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 44
	label.pixel_size = 0.012
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
