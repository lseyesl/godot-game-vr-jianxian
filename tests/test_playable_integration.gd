extends SceneTree

var failures: Array[String] = []
var assertions := 0
var game: Node
var world: Node3D
var player: CharacterBody3D
const SAVE := "user://test_integration_checkpoint.json"

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok: failures.append(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func walk_to(target: Vector3, maximum_frames: int = 1500) -> void:
	var arrived := false
	for i in maximum_frames:
		if paused and game.quest_state.current_step == "complete":
			arrived = true
			break
		var offset := target - player.global_position
		offset.y = 0
		if offset.length() < 0.45:
			arrived = true
			break
		player.rotation.y = atan2(-offset.x, -offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	await frames(3)
	check(arrived, "walkable route reaches %s (actual %s)" % [target, player.global_position])

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = action
	Input.parse_input_event(event)
	await frames(2)

func run() -> void:
	game = root.get_node("Game")
	game.checkpoint_path = SAVE
	game.reset_demo()
	game.save_checkpoint()
	change_scene_to_file("res://scenes/main/PlayableJourney.tscn")
	await scene_changed
	await frames(30)
	world = current_scene
	player = world.player_node
	check(player.is_on_floor(), "player spawns and settles on traversable ground")
	world.sword.collect()
	check(not world.sword.unlocked and not game.save_state.sword_unlocked, "early sword collection is rejected")
	world.seal.receive_spell("seal_break")
	check(not world.seal.cleansed, "early seal break is rejected")
	await walk_to(Vector3(-5, 0, 4))
	await press("interact")
	check(game.quest_state.current_step == "ask_tavern", "real NPC interaction advances first quest")
	check(world.hud.dialogue.text.contains("客栈掌柜"), "NPC dialogue is visible on HUD")
	await walk_to(Vector3(0, 0, 0))
	await walk_to(Vector3(5, 0, -10))
	await press("interact")
	check(game.quest_state.current_step == "go_to_mountain", "second NPC gives trial objective")
	await walk_to(Vector3(0, 0, -15))
	await walk_to(Vector3(0, 0, -48))
	check(game.quest_state.current_step == "cleanse_seal", "walking through trigger starts trial")
	world.seal.receive_spell("seal_break")
	check(not world.seal.cleansed, "living guardians block the seal")
	await press("spell_guard")
	check(player.receive_damage(3, "test") == 5, "guard protects the actual player")
	for demon in world.demons:
		if demon.is_defeated(): continue
		player.camera.look_at(demon.global_position + Vector3(0, 0.9, 0), Vector3.UP)
		check(player.cast_spell_id("seal_break"), "projectile cast accepted")
		await frames(130)
		check(demon.is_defeated(), "moving projectile hits and defeats guardian")
	check(not paused, "player survives guarded encounter")
	await walk_to(Vector3(0, 0, -59))
	player.camera.look_at(world.seal.global_position, Vector3.UP)
	check(player.cast_spell_id("spirit_bolt"), "spirit bolt casts at seal")
	await frames(75)
	check(world.seal.remaining_hits == 2, "projectile hits seal exactly once")
	check(player.cast_spell_id("seal_break"), "finishing seal projectile casts")
	await frames(60)
	check(game.quest_state.current_step == "collect_sword", "seal projectile unlocks sword objective")
	await walk_to(Vector3(0, 0, -70))
	check(game.quest_state.current_step == "fly_back", "physical sword pickup advances quest")
	check(player.flight_enabled, "sword enables flight")
	var before := player.position.y
	Input.action_press("flight_ascend")
	await frames(65)
	Input.action_release("flight_ascend")
	check(player.position.y > before + 5, "flight ascends")
	before = player.position.y
	Input.action_press("flight_descend")
	await frames(15)
	Input.action_release("flight_descend")
	check(player.position.y < before - 1, "flight descends")
	await walk_to(Vector3(0, 0, 16), 1200)
	check(game.quest_state.current_step == "complete", "flight return trigger completes entire quest")
	check(paused and world.hud.mode == "complete", "completion shows actionable end screen and pauses game")
	world.hud.return_to_menu()
	await scene_changed
	check(current_scene is MainMenu, "return button reaches main menu")
	check(not current_scene.continue_button.disabled, "saved progress can be continued")
	current_scene._continue_game()
	await scene_changed
	await frames(5)
	check(current_scene.hud.mode == "complete", "continuing completed save restores end screen")
	paused = false
	game.reset_demo()
	game.quest_state.current_step = "cleanse_seal"
	game.save_checkpoint()
	reload_current_scene()
	await scene_changed
	await frames(5)
	world = current_scene
	player = world.player_node
	world.hud.toggle_pause()
	var stopped_position := player.position
	Input.action_press("move_forward")
	await frames(15)
	Input.action_release("move_forward")
	check(player.position == stopped_position, "pause freezes movement")
	world.hud.close_modal()
	player.receive_damage(99, "test")
	check(paused and world.hud.mode == "defeat", "death produces retry screen")
	world.hud.retry()
	await scene_changed
	await frames(5)
	check(not paused, "retry resumes gameplay")
	check(game.quest_state.current_step == "cleanse_seal", "retry retains checkpoint quest")
	check(current_scene.player_node.get_health_component().current_health == 5, "retry restores health")
	check(not current_scene.seal.cleansed, "retry resets unfinished encounter")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures.is_empty(): print("INTEGRATION PASSED: %d assertions" % assertions)
	else:
		for failure in failures: printerr("FAIL: " + failure)
		printerr("INTEGRATION FAILED: %d / %d" % [failures.size(), assertions])
	quit(0 if failures.is_empty() else 1)
