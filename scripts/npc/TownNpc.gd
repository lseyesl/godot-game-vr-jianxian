extends CharacterBody3D
class_name TownNpc

@export var npc_role := "pedestrian"
@export var move_speed_mps := 1.0
@export var player_sense_radius_m := 2.5
@export var wait_duration_s := 1.5
@export var waypoints: Array[Vector3] = []

var current_waypoint_index := 0
var last_spoken_line := ""
var nearby_player: Node3D
var wait_remaining_s := 0.0


func _ready() -> void:
	var tree := $BehaviorTree as BeehaveTree
	if tree != null:
		tree.process_thread = BeehaveTree.ProcessThread.MANUAL
	if waypoints.is_empty():
		waypoints = [Vector3.ZERO]


func _physics_process(delta: float) -> void:
	var tree := $BehaviorTree as BeehaveTree
	if tree != null and tree.enabled:
		tree.blackboard.set_value("delta", delta, str(get_instance_id()))
		tree.tick()

const LINES := {
	"vendor": [
		"新摘的灵草，熬汤最养气。",
		"少侠慢走，摊上的符纸都压过香灰。",
	],
	"inn_owner": [
		"客栈还有热茶，出镇前歇一口气。",
		"昨夜剑光从屋脊掠过，镇里人都看见了。",
	],
	"tavern_owner": [
		"山风带妖气，酒也压不住。",
		"听说北边旧祭台又亮了。",
	],
	"pedestrian": [
		"今天集市比往常热闹。",
		"有人说山里传来钟声。",
	],
}

func line_for_role() -> String:
	var lines: Array = LINES.get(npc_role, LINES["pedestrian"])
	if lines.is_empty():
		return ""
	var index := absi(hash(npc_role)) % lines.size()
	return lines[index]

func speak_context_line() -> String:
	last_spoken_line = line_for_role()
	return last_spoken_line

func set_nearby_player(player: Node) -> void:
	if player is Node3D and player.is_in_group("player"):
		nearby_player = player

func clear_nearby_player(player: Node) -> void:
	if player == nearby_player:
		nearby_player = null

func has_nearby_player() -> bool:
	return nearby_player != null and is_instance_valid(nearby_player)

func move_to_next_waypoint(delta: float) -> bool:
	if waypoints.is_empty():
		velocity = Vector3.ZERO
		return false
	var target: Vector3 = waypoints[current_waypoint_index]
	var current := global_position if is_inside_tree() else position
	var offset: Vector3 = target - current
	offset.y = 0.0
	if offset.length() <= 0.05:
		velocity = Vector3.ZERO
		return true
	var step: Vector3 = offset.normalized() * move_speed_mps
	velocity = step
	if is_inside_tree():
		move_and_slide()
	else:
		position += step * delta
	return true

func is_at_waypoint() -> bool:
	if waypoints.is_empty():
		return true
	var current := global_position if is_inside_tree() else position
	var target: Vector3 = waypoints[current_waypoint_index]
	current.y = 0.0
	target.y = 0.0
	return current.distance_to(target) <= 0.1

func advance_waypoint() -> void:
	if not waypoints.is_empty():
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()

func start_waiting() -> void:
	wait_remaining_s = wait_duration_s

func tick_wait(delta: float) -> bool:
	wait_remaining_s = maxf(0.0, wait_remaining_s - delta)
	if wait_remaining_s <= 0.0:
		advance_waypoint()
		return false
	return true

func look_at_player() -> bool:
	if not has_nearby_player():
		return false
	var target := nearby_player.global_position if nearby_player.is_inside_tree() else nearby_player.position
	var current := global_position if is_inside_tree() else position
	target.y = current.y
	if current.distance_to(target) <= 0.01:
		return false
	look_at(target, Vector3.UP)
	return true

func _on_sense_area_body_entered(body: Node3D) -> void:
	set_nearby_player(body)

func _on_sense_area_body_exited(body: Node3D) -> void:
	clear_nearby_player(body)
