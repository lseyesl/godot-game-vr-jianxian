extends RefCounted

func run(t) -> void:
	var path := "res://scripts/spells/SpellCaster.gd"
	t.assert_true(FileAccess.file_exists(path), "SpellCaster script exists")
	if not FileAccess.file_exists(path):
		return
	var SpellCaster := load(path)
	t.assert_true(SpellCaster.can_instantiate(), "SpellCaster can instantiate")
	if not SpellCaster.can_instantiate():
		return
	var caster = SpellCaster.new()
	t.assert_true(caster.can_cast("spirit_bolt"), "spirit bolt starts ready")
	t.assert_true(caster.cast("spirit_bolt"), "spirit bolt casts")
	t.assert_true(not caster.can_cast("spirit_bolt"), "cooldown starts after cast")
	caster.tick_cooldowns(2.0)
	t.assert_true(caster.can_cast("spirit_bolt"), "spirit bolt returns after cooldown")
	t.assert_true(caster.cast("seal_break"), "seal break casts")
	t.assert_true(not caster.cast("unknown"), "unknown spell does not cast")
	caster.free()
