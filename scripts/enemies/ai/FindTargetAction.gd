extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("find_target") and actor.find_target():
		return SUCCESS
	return FAILURE
