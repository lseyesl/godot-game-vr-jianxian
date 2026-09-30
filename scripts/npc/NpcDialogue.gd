extends Node
class_name NpcDialogue

@export var npc_id := "townsperson"
var last_line := ""
var nearby_player: Node3D

const LINES := {
	"innkeeper": {
		"start": "少侠，你的飞剑昨夜化作青光飞向山谷。先去酒馆问问，说书人见过那道光。",
		"complete": "飞剑归来，气息也稳了。你已踏出剑仙第一步。",
		"default": "客栈有热茶，也有远行人的消息。",
	},
	"tavern_keeper": {
		"ask_tavern": "山谷旧祭台有妖气盘旋。沿镇门外的石阶走，看到瀑布就到了。",
		"default": "酒香压不住山里的怪风，今夜少往山里去。",
	},
	"trial_spirit": {
		"cleanse_seal": "凝神，立定，掌心聚灵。以灵光破妖，以破封诀开阵。",
		"default": "试炼只认心定之人。",
	},
}

const EVENTS := {
	"innkeeper": {"start": "talked_to_innkeeper"},
	"tavern_keeper": {"ask_tavern": "talked_to_tavern_keeper"},
}

func line_for_step(step: String) -> String:
	var npc_lines: Dictionary = LINES.get(npc_id, {})
	return npc_lines.get(step, npc_lines.get("default", "……"))

func quest_event_for_step(step: String) -> String:
	var npc_events: Dictionary = EVENTS.get(npc_id, {})
	return npc_events.get(step, "")

func interact(current_step: String) -> String:
	var event_id := quest_event_for_step(current_step)
	if event_id != "":
		var game := _get_game()
		if game != null and game.has_method("advance_quest"):
			game.advance_quest(event_id)
	last_line = line_for_step(current_step)
	return last_line

func has_nearby_player() -> bool:
	return nearby_player != null and is_instance_valid(nearby_player)

func interact_with_current_step() -> String:
	var game := _get_game()
	var step := "start"
	if game != null:
		step = game.quest_state.current_step
	return interact(step)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and has_nearby_player():
		interact_with_current_step()

func _on_interact_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	nearby_player = body

func _on_interact_area_body_exited(body: Node3D) -> void:
	if body == nearby_player:
		nearby_player = null

func _get_game() -> Node:
	var local_game := get_parent().get_node_or_null("Game") if get_parent() != null else null
	if local_game != null:
		return local_game
	if is_inside_tree():
		return get_node_or_null("/root/Game")
	return null
