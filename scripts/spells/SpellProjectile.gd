extends Area3D
class_name SpellProjectile

@export var spell_id := "spirit_bolt"
@export var speed_mps := 16.0
@export var lifetime_s := 3.0

var direction := Vector3.FORWARD
var age := 0.0

func launch(origin: Vector3, forward: Vector3) -> void:
	global_position = origin
	direction = forward.normalized()
	age = 0.0

func _physics_process(delta: float) -> void:
	global_position += direction * speed_mps * delta
	age += delta
	if age >= lifetime_s:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit_target(body)

func _on_area_entered(area: Area3D) -> void:
	_hit_target(area)

func _hit_target(target: Node) -> void:
	if target.has_method("receive_spell"):
		target.receive_spell(spell_id)
	queue_free()
