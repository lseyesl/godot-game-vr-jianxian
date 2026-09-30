extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("look_at_player") and actor.look_at_player():
		return SUCCESS
	return FAILURE
