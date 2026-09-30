extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta: float = blackboard.get_value("delta", 0.016)
	if actor.has_method("move_toward_target") and actor.move_toward_target(delta):
		return RUNNING
	return FAILURE
