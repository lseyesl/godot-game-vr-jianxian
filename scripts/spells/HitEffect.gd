extends GPUParticles3D

func _ready() -> void:
	emitting = true

func _process(_delta: float) -> void:
	if not emitting and not is_emitting():
		queue_free()
