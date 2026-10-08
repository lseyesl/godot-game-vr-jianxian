extends SceneTree
func _init(): call_deferred("run")
func run():
	var scene = load("res://scenes/player/XRPlayer.tscn")
	if scene == null:
		quit(1)
		return
	var player = scene.instantiate()
	root.add_child(player)
	await process_frame
	var bus = root.get_node("EventBus")
	var counts = [0, 0]
	bus.interaction_requested.connect(func(): counts[0] += 1)
	bus.pause_requested.connect(func(): counts[1] += 1)
	player._on_right_button("ax_button")
	player._on_right_button("by_button")
	player.get_node("XROrigin3D/PlayerBody").receive_damage(1, "test")
	if counts != [1, 1] or player.get_health_component().current_health != 4:
		printerr("XR scene signal or damage forwarding failed")
		player.queue_free()
		quit(1)
		return
	print("XR SCENE AND INPUT BRIDGE PASSED")
	player.queue_free()
	await process_frame
	quit()
