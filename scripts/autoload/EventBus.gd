extends Node

signal quest_step_changed(step: String)
signal objective_changed(text: String)
signal dialogue_requested(npc_id: String)
signal spell_cast(spell_id: String)
signal seal_weakened(remaining_hits: int)
signal seal_cleansed()
signal sword_unlocked()
signal flight_mode_changed(enabled: bool)
signal comfort_settings_changed(settings: ComfortSettings)
signal damage_received(target_id: String, amount: int, current_health: int, max_health: int)
signal health_changed(target_id: String, current_health: int, max_health: int)
signal enemy_defeated(enemy_id: String)
signal player_defeated(source_id: String)
signal combat_feedback_requested(spell_id: String, target_id: String, outcome: String)
signal player_health_changed(current_health: int, max_health: int)
signal quest_completed()
signal completion_feedback_requested(title: String, message: String)


signal dialogue_shown(npc_id: String, text: String)
signal interaction_requested()
signal notification_requested(text: String)
signal pause_requested()
signal retry_requested()
signal menu_requested()

signal player_damage_requested(amount: int, source_id: String)
