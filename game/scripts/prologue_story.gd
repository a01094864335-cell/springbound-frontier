extends RefCounted
## Narrative state commits only after the last line, independently of map reloads.
const FLAGS := ["morning", "water", "towels", "request", "farewell", "closing", "nia", "doren", "vera", "roke", "leon_arrival", "halven", "eda"]
var flags: Dictionary = {}
var data: Dictionary

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://story/prologue_dialogue.json"))
	reset()

func reset() -> void:
	for flag in FLAGS: flags[flag] = false

func done(flag: String) -> bool:
	return flags.get(flag, false)

func errands_done() -> bool:
	return done("water") and done("towels")

func finish(scene: String) -> void:
	var changes := {"opening":"morning", "well_first":"water", "inn_first":"towels", "request":"request", "farewell":"farewell", "closing":"closing"}
	if changes.has(scene): flags[changes[scene]] = true
	if scene in FLAGS: flags[scene] = true
	if scene == "nia_late": flags.nia = true

func lines(scene: String) -> Array:
	return data.scenes.get(scene, []).duplicate(true)

func title(scene: String) -> String:
	return data.titles.get(scene, "")

func restore(version: int, medicine: bool, leon: bool, delivered: bool, saved: Variant) -> bool:
	var next := {}
	if version == 1:
		# Old records have no morning errands. Do not send a traveller back home.
		for flag in FLAGS: next[flag] = (medicine or leon or delivered) if flag in ["morning","water","towels","request","farewell"] else false
		next.closing = false
	else:
		if not saved is Dictionary: return false
		for flag in FLAGS:
			if not saved.get(flag) is bool: return false
			next[flag] = saved[flag]
		if (next.water or next.towels) and not next.morning: return false
		if next.request and not (next.water and next.towels): return false
		if next.farewell and not (next.request and medicine): return false
		if medicine and not next.request: return false
		if leon and not (medicine and next.farewell): return false
		if delivered and not leon: return false
		if next.closing and not delivered: return false
	flags = next
	return true
