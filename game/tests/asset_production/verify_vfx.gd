extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/vfx/catalog.json"))
	var results: Array=[]
	for e in catalog:
		var packed: PackedScene=load(e.path) as PackedScene
		assert(packed != null,e.path)
		var a: Node3D=packed.instantiate() as Node3D
		var b: Node3D=packed.instantiate() as Node3D
		root.add_child(a)
		root.add_child(b)
		assert(a.material != b.material,"VFX instance materials must be independent")
		a.play()
		a.seek(.5)
		assert(is_equal_approx(float(a.material.get_shader_parameter("progress")),.5))
		a.stop()
		assert(not a.playing and not a.visible)
		a.play()
		a._process(float(e.duration)+.01)
		assert(a.playing == bool(e.loop))
		results.append({"id":e.id,"loaded":true,"isolated_material":true,"play_stop_seek":true,"lifetime":true})
		a.queue_free()
		b.queue_free()
		await process_frame
	var file: FileAccess=FileAccess.open("res://tests/asset_production/vfx-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"count":results.size(),"passed":true,"results":results},"\t"))
	file.close()
	print("VFX_ASSET_QA true count=",results.size())
	quit()
