extends XRToolsPlayerBody
class_name JourneyXRBody

func receive_damage(amount: int, source_id: String = "") -> int:
	var bus := get_node_or_null("/root/EventBus")
	if bus != null: bus.player_damage_requested.emit(amount, source_id)
	return 0
