extends RefCounted

const FEEDBACK_SCENE := "res://scenes/ui/CompletionFeedback.tscn"

func run(t) -> void:
	_test_completion_feedback_scene_exists(t)
	_test_completion_feedback_updates_visible_text(t)

func _test_completion_feedback_scene_exists(t) -> void:
	t.assert_true(ResourceLoader.exists(FEEDBACK_SCENE), "CompletionFeedback scene exists")
	if not ResourceLoader.exists(FEEDBACK_SCENE):
		return
	var scene := load(FEEDBACK_SCENE)
	t.assert_true(scene is PackedScene, "CompletionFeedback scene loads")
	if not scene is PackedScene:
		return
	var feedback = scene.instantiate()
	t.assert_true(feedback.get_node_or_null("Panel/TitleLabel") is Label, "feedback has title label")
	t.assert_true(feedback.get_node_or_null("Panel/MessageLabel") is Label, "feedback has message label")
	t.assert_true(feedback.get_node_or_null("CompletionAudio") is AudioStreamPlayer, "feedback has optional audio player")
	feedback.free()

func _test_completion_feedback_updates_visible_text(t) -> void:
	if not ResourceLoader.exists(FEEDBACK_SCENE):
		return
	var feedback = load(FEEDBACK_SCENE).instantiate()
	t.assert_true(feedback.has_method("show_completion"), "feedback exposes show_completion")
	if not feedback.has_method("show_completion"):
		feedback.free()
		return
	t.assert_true(not feedback.feedback_visible, "feedback starts hidden")
	feedback.show_completion("试炼完成", "飞剑归鞘")
	t.assert_true(feedback.feedback_visible, "feedback becomes visible")
	t.assert_equal(feedback.get_node("Panel/TitleLabel").text, "试炼完成", "title label updates")
	t.assert_equal(feedback.get_node("Panel/MessageLabel").text, "飞剑归鞘", "message label updates")
	feedback.show_completion("完成", "新的反馈")
	t.assert_equal(feedback.get_node("Panel/TitleLabel").text, "完成", "repeat request updates same title")
	t.assert_equal(feedback.get_node("Panel/MessageLabel").text, "新的反馈", "repeat request updates same message")
	feedback.free()
