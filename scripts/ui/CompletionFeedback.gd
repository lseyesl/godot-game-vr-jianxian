extends CanvasLayer
class_name CompletionFeedback

@export var panel_path: NodePath = ^"Panel"
@export var title_label_path: NodePath = ^"Panel/TitleLabel"
@export var message_label_path: NodePath = ^"Panel/MessageLabel"
@export var audio_player_path: NodePath = ^"CompletionAudio"

var feedback_visible := false

func _ready() -> void:
	_set_panel_visible(false)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("completion_feedback_requested"):
		event_bus.completion_feedback_requested.connect(show_completion)

func show_completion(title: String, message: String) -> void:
	var title_label := get_node_or_null(title_label_path) as Label
	var message_label := get_node_or_null(message_label_path) as Label
	if title_label != null:
		title_label.text = title
	if message_label != null:
		message_label.text = message
	feedback_visible = true
	_set_panel_visible(true)
	var audio_player := get_node_or_null(audio_player_path) as AudioStreamPlayer
	if audio_player != null and audio_player.stream != null:
		audio_player.play()

func _set_panel_visible(visible: bool) -> void:
	var panel := get_node_or_null(panel_path) as CanvasItem
	if panel != null:
		panel.visible = visible
