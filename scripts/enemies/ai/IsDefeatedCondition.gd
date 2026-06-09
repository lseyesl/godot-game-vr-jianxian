extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("is_defeated") and actor.is_defeated():
		return SUCCESS
	return FAILURE
