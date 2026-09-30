extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("is_in_attack_range") and actor.is_in_attack_range():
		return SUCCESS
	return FAILURE
