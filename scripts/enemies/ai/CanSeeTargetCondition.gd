extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("can_see_target") and actor.can_see_target():
		return SUCCESS
	return FAILURE
