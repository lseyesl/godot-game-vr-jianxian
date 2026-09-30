extends Node
class_name SpellCaster

const SPELLS := {
	"spirit_bolt": {"cooldown": 1.0, "label": "灵光弹"},
	"guard_charm": {"cooldown": 4.0, "label": "护身诀"},
	"seal_break": {"cooldown": 2.0, "label": "破封印"},
}

var cooldowns: Dictionary = {}

func can_cast(spell_id: String) -> bool:
	return SPELLS.has(spell_id) and float(cooldowns.get(spell_id, 0.0)) <= 0.0

func cast(spell_id: String) -> bool:
	if not can_cast(spell_id):
		return false
	cooldowns[spell_id] = SPELLS[spell_id]["cooldown"]
	if is_inside_tree():
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus != null:
			event_bus.spell_cast.emit(spell_id)
	return true

func tick_cooldowns(delta: float) -> void:
	for spell_id in cooldowns.keys():
		cooldowns[spell_id] = maxf(0.0, float(cooldowns[spell_id]) - delta)
