extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if "velocity" in actor:
		actor.velocity = Vector3.ZERO
	return RUNNING
