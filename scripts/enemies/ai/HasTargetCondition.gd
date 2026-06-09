extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("has_target") and actor.has_target():
		return SUCCESS
	return FAILURE
