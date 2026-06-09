extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("try_attack_target") and actor.try_attack_target():
		return SUCCESS
	return FAILURE
