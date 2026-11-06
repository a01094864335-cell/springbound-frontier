extends RefCounted
## Narrative state commits only after the last line, independently of map reloads.
const FLAGS := ["morning", "water", "towels", "request", "farewell", "closing", "nia", "doren", "vera", "roke", "leon_arrival", "halven", "eda", "leon_found"]
const EXTRA_FLAGS := ["trail_intro", "treatment", "arrival", "tea", "records", "homeward", "departure"]
var return_choice := ""
var flags: Dictionary = {}
var data: Dictionary

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://story/prologue_dialogue.json"))
	reset()

func reset() -> void:
	return_choice = ""
	for flag in FLAGS + EXTRA_FLAGS: flags[flag] = false

func done(flag: String) -> bool:
	return flags.get(flag, false)

func errands_done() -> bool:
	return done("water") and done("towels")

func finish(scene: String) -> void:
	var changes := {"opening":"morning", "well_first":"water", "inn_first":"towels", "request":"request", "farewell":"farewell", "closing":"closing"}
	if changes.has(scene): flags[changes[scene]] = true
	if scene in FLAGS + EXTRA_FLAGS and scene != "homeward": flags[scene] = true
	if scene == "leon_bridge": flags.treatment = true
	if scene == "arrival": flags.leon_arrival = true
	if scene == "homeward_a" or scene == "homeward_b":
		return_choice = scene.right(1)
		flags.homeward = true
	if scene == "departure": flags.closing = true
	if scene == "nia_late": flags.nia = true
	if scene == "leon_first": flags.leon_found = true

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
		next.leon_found = leon
	else:
		if not saved is Dictionary: return false
		for flag in FLAGS:
			if flag == "leon_found" and not saved.has(flag):
				next[flag] = leon
				continue
			if not saved.get(flag) is bool: return false
			next[flag] = saved[flag]
		if (next.water or next.towels) and not next.morning: return false
		if next.request and not (next.water and next.towels): return false
		if next.farewell and not (next.request and medicine): return false
		if medicine and not next.request: return false
		if next.leon_found and not (medicine and next.farewell): return false
		if leon and not (medicine and next.farewell and next.leon_found): return false
		if delivered and not leon: return false
		if next.closing and not delivered: return false
	# Older saves keep their location and completed delivery. Only new story steps resume.
	for flag in EXTRA_FLAGS:
		if saved is Dictionary and saved.has(flag) and not saved[flag] is bool: return false
		next[flag] = saved.get(flag, false) if saved is Dictionary else false
	var choice := ""
	if saved is Dictionary:
		if not saved.get("return_choice", "") is String: return false
		choice = saved.get("return_choice", "")
	if choice not in ["", "a", "b"]: return false
	if next.tea and not delivered: return false
	if next.records and not next.tea: return false
	if next.homeward and (not next.records or choice.is_empty()): return false
	if next.departure and not next.homeward: return false
	# closing meant tea in v3; it becomes the final MQ05 boundary only in new saves.
	if version < 4 and not (saved is Dictionary and saved.has("departure")):
		next.tea = next.closing
		next.closing = false
	if next.closing != next.departure: return false
	flags = next
	return_choice = choice
	return true

func scene_for(kind: String, medicine: bool, leon: bool, delivered: bool) -> String:
	match kind:
		"marta":
			if delivered: return "marta_return"
			if not done("morning"): return "opening"
			if not errands_done():
				if done("water"): return "marta_towels_left"
				if done("towels"): return "marta_water_left"
				return "marta_wait"
			if not done("request"): return "request"
			if not medicine: return "parcel_reminder"
			return "marta_departed" if done("farewell") else "farewell"
		"medicine":
			if delivered: return "parcel_delivered"
			if medicine: return "parcel_ready" if done("farewell") else "parcel_packed"
			return "medicine" if done("request") else "parcel_wait"
		"water", "inn":
			if not done("morning"): return "morning_reminder"
			var flag := "water" if kind == "water" else "towels"
			var prefix := "well" if kind == "water" else "inn"
			return prefix + ("_again" if done(flag) else "_first")
		"leon":
			if delivered: return "leon_return"
			if leon: return "leon_again"
			return "leon_bridge" if done("leon_found") else "leon_first"
		"leon_arrival":
			if delivered:
				if done("departure"): return "rest_again"
				if not done("tea"): return "tea"
				if not done("records"): return "morning_wait"
				return "departure" if done("homeward") else "homeward"
			return "leon_arrival_again" if done("leon_arrival") else "leon_arrival"
		"delivery", "halven", "eda":
			if not medicine or not leon: return "office_wait_eda" if kind == "eda" else "office_wait"
			if not delivered: return "delivery"
			if kind == "halven" and done("tea") and not done("records"): return "records"
			if kind == "delivery": return "delivery_again"
			return kind+"_again" if done(kind) else kind
		"room_map": return "map"
		"nia":
			if delivered: return "nia_again" if done("nia") else "nia_late"
			if done("nia"): return "nia_departure" if medicine else "nia_again"
			return "nia"
		"roke":
			if not done("farewell"): return "roke_before_trip"
			return "roke_again" if done("roke") else "roke"
		"doren":
			if done("water") and not done("request"): return "doren_water_done"
			return "doren_again" if done("doren") else "doren"
		"vera": return "vera_again" if done("vera") else "vera"
		"tracks":
			if delivered: return "tracks"
			return "tracks_after" if done("leon_found") or leon else "tracks"
	return kind

func snapshot() -> Dictionary:
	var result := flags.duplicate()
	result.return_choice = return_choice
	return result
