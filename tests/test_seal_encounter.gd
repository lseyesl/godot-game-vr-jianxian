extends RefCounted

func run(t) -> void:
	var path := "res://scripts/interaction/SealEncounter.gd"
	t.assert_true(FileAccess.file_exists(path), "SealEncounter script exists")
	if not FileAccess.file_exists(path):
		return
	var SealEncounter := load(path)
	t.assert_true(SealEncounter.can_instantiate(), "SealEncounter can instantiate")
	if not SealEncounter.can_instantiate():
		return
	var encounter = SealEncounter.new()
	t.assert_equal(encounter.remaining_hits, 3, "seal starts with three hits")
	encounter.receive_spell("spirit_bolt")
	t.assert_equal(encounter.remaining_hits, 2, "spirit bolt weakens demon seal")
	encounter.receive_spell("guard_charm")
	t.assert_equal(encounter.remaining_hits, 2, "guard charm does not weaken seal")
	encounter.receive_spell("seal_break")
	t.assert_equal(encounter.remaining_hits, 0, "seal break finishes encounter")
	t.assert_true(encounter.cleansed, "encounter is cleansed")
	encounter.free()
