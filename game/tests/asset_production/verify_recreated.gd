extends SceneTree
var failures: Array = []
var results: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for group in ["props","ui"]:
		var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/"+group+"/catalog.json"))
		for entry in entries:
			var resource: PackedScene = load(entry.path)
			if resource == null:
				failures.append(entry.id+" load failed")
				continue
			var scene: Node = resource.instantiate()
			root.add_child(scene)
			await process_frame
			if group == "props":
				if scene.find_children("*","MeshInstance3D",true,false).is_empty():
					failures.append(entry.id+" has no geometry")
				for mesh in scene.find_children("*","MeshInstance3D",true,false):
					if mesh.mesh == null:
						failures.append(entry.id+" null mesh")
			else:
				var got: Array = []
				scene.action_requested.connect(func(a,p):got.append([a,p]))
				scene.configure({"speaker":"검증", "value":25,"max":50,"progress":.5})
				for button in scene.find_children("*","Button",true,false):
					var count: int = got.size()
					button.pressed.emit()
					if got.size()!=count+1:
						failures.append(entry.id+" signal failed")
				if scene.get_child_count()==0:
					failures.append(entry.id+" empty UI")
			results.append({"id":entry.id,"loaded":true})
			scene.free()
	var f := FileAccess.open("res://tests/asset_production/recreated-verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"count":results.size(),"passed":failures.is_empty(),"results":results,"failures":failures},"\t"))
	print("RECREATED_QA ",failures.is_empty()," count=",results.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
