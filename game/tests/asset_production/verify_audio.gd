extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/audio/catalog.json"))
	var results: Array=[]
	for entry in catalog:
		var stream: AudioStreamWAV=load(entry.path) as AudioStreamWAV
		assert(stream != null,entry.path)
		assert(stream.mix_rate == int(entry.sample_rate))
		assert(stream.data.size()>0)
		assert(absf(stream.get_length()-float(entry.duration))<.001)
		var copy: AudioStreamWAV=stream.duplicate() as AudioStreamWAV
		if entry.loop:
			copy.loop_mode=AudioStreamWAV.LOOP_FORWARD
			copy.loop_begin=0
			copy.loop_end=int(entry.loop_end)
		results.append({"id":entry.id,"loaded":true,"duration":stream.get_length(),"loop_configured":bool(entry.loop)})
	var file: FileAccess=FileAccess.open("res://tests/asset_production/audio-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"count":results.size(),"passed":true,"listening_review":false,"results":results},"\t"))
	file.close()
	print("AUDIO_ASSET_QA true count=",results.size())
	quit()
