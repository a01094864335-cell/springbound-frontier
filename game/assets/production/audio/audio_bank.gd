extends RefCounted
## Each caller receives its own stream, with catalogued loop points.
static func stream(asset_id: String) -> AudioStreamWAV:
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/audio/catalog.json"))
	for entry in catalog:
		if entry.id != asset_id: continue
		var source: AudioStreamWAV=load(entry.path) as AudioStreamWAV
		if source == null: return null
		var result: AudioStreamWAV=source.duplicate() as AudioStreamWAV
		if entry.loop:
			result.loop_mode=AudioStreamWAV.LOOP_FORWARD
			result.loop_begin=int(entry.loop_start)
			result.loop_end=int(entry.loop_end)
		return result
	push_error("Unknown production audio id: "+asset_id)
	return null
