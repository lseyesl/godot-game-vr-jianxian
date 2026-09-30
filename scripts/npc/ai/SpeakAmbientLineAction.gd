extends "res://addons/beehave/nodes/leaves/action.gd"

func tick(actor: Node, blackboard: Blackboard) -> int:
	if actor.has_method("speak_context_line"):
		actor.speak_context_line()
		return SUCCESS
	return FAILURE
