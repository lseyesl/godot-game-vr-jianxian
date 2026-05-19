extends Node

signal quest_step_changed(step: String)
signal objective_changed(text: String)
signal dialogue_requested(npc_id: String)
signal spell_cast(spell_id: String)
signal seal_weakened(remaining_hits: int)
signal seal_cleansed()
signal sword_unlocked()
signal flight_mode_changed(enabled: bool)
signal comfort_settings_changed(settings)
