extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("has_nearby_player") and actor.has_nearby_player():
		return SUCCESS
	return FAILURE
