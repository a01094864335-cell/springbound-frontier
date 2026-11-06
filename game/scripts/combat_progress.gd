extends RefCounted
const Story = preload("res://scripts/prologue_story.gd")
const Battle = preload("res://scripts/first_battle.gd")

static func fresh() -> Dictionary:
	return {"hp":Battle.MAX_HP,"mp":0,"potions":2,"won":false,"sword":false,"mode":"story","checkpoint":{}}

static func decode(value: Variant, version: int, met_leon: bool, delivered: bool, map_index: int) -> Dictionary:
	var result := fresh()
	if version < 3:
		# Existing prototype journeys already past Leon are not forced to replay.
		result.won = met_leon or delivered
		return result
	if not value is Dictionary: return {}
	for field in ["hp","mp","potions"]:
		if not _integer(value.get(field)): return {}
	if value.hp < 1 or value.hp > Battle.MAX_HP or value.mp < 0 or value.mp > 999 or value.potions < 0 or value.potions > 2: return {}
	for field in ["won","sword"]:
		if not value.get(field) is bool: return {}
	if value.get("mode") not in ["story","tactical"] or not value.get("checkpoint") is Dictionary: return {}
	if (met_leon or delivered) and not value.won: return {}
	if delivered and value.sword: return {}
	var cp: Dictionary = value.checkpoint
	if not cp.is_empty():
		if map_index != 2 or value.won or met_leon or delivered or not value.sword: return {}
		if not _position(cp.get("hero")) or not _position(cp.get("enemy")): return {}
		if not _integer(cp.get("hp")) or cp.hp < 1 or cp.hp > Battle.MAX_HP: return {}
		if not _integer(cp.get("mp")) or cp.mp < 0 or cp.mp > 999: return {}
		if cp.get("mode") != value.mode or not cp.get("story") is Dictionary: return {}
		# Checkpoints only exist after medicine, farewell and the Leon encounter.
		if cp.story.get("farewell") != true or cp.story.get("leon_found") != true: return {}
		var validator = Story.new()
		if not validator.restore(3,true,false,false,cp.story): return {}
		if value.hp != cp.hp or value.mp != cp.mp: return {}
	result = value.duplicate(true)
	return result

static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

static func _position(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	return _integer(value[0]) and _integer(value[1]) and absf(float(value[0])) < 16 and absf(float(value[1])) < 26
