extends "res://addons/beehave/nodes/leaves/condition.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("is_at_waypoint") and actor.is_at_waypoint():
		return SUCCESS
	return FAILURE
