extends CanvasLayer
class_name TaskHud

@onready var objective_label: Label = get_node("ObjectivePanel/ObjectiveLabel")

func _ready() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.objective_changed.connect(_on_objective_changed)
	var game := get_node_or_null("/root/Game")
	if game != null:
		_on_objective_changed(game.quest_state.current_objective())

func _on_objective_changed(text: String) -> void:
	objective_label.text = text
