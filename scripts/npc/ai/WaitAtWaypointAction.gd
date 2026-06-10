extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta: float = blackboard.get_value("delta", 0.016)
	if "wait_remaining_s" in actor and actor.wait_remaining_s <= 0.0 and actor.has_method("start_waiting"):
		actor.start_waiting()
	if actor.has_method("tick_wait") and actor.tick_wait(delta):
		return RUNNING
	return SUCCESS
