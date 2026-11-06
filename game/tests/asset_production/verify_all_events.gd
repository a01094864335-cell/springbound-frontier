extends SceneTree
var failures: Array=[]
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var events: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/events/catalog.json"))
	if events.size()!=14:failures.append("Expected14 events")
	for entry in events:
		var event: Node3D=(load(entry.path) as PackedScene).instantiate()
		root.add_child(event)
		var signals: Array=[]
		event.finished.connect(func(id):signals.append(id))
		event.play()
		event.seek(float(entry.duration)/2)
		for track in entry.tracks:
			if event.get_node_or_null(track.node)==null:failures.append(entry.id+" missing track target")
		event.skip()
		event.skip()
		if signals.size()!=1:failures.append(entry.id+" repeated completion")
		for track in entry.tracks:
			var actual: Variant=event.get_node(track.node).get(track.property)
			var expected: Variant=track["keys"][-1].value
			if expected is Array:
				if not actual.is_equal_approx(Vector3(expected[0],expected[1],expected[2])):failures.append(entry.id+" final transform mismatch")
			elif not is_equal_approx(float(actual),float(expected)):failures.append(entry.id+" final value mismatch")
		event.play()
		event.stop()
		if event.playing:failures.append(entry.id+" stop failed")
		event.free()
		results.append({"id":entry.id,"loaded":true,"skip_once":true})
	var states: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/world_states/catalog.json"))
	if states.size()!=4:failures.append("Expected4 states")
	for entry in states:
		var state: Node3D=(load(entry.path) as PackedScene).instantiate()
		root.add_child(state)
		await physics_frame
		await physics_frame
		var space:=state.get_world_3d().direct_space_state
		for z in range(-6,7):
			var shape:=SphereShape3D.new()
			shape.radius=.4
			var q:=PhysicsShapeQueryParameters3D.new()
			q.shape=shape
			q.transform=Transform3D(Basis.IDENTITY,Vector3(0,.9,z))
			if not space.intersect_shape(q).is_empty():failures.append(entry.id+" travel lane blocked")
		state.free()
		results.append({"id":entry.id,"loaded":true,"lane_clear":true})
	var f:=FileAccess.open("res://tests/asset_production/event-verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":failures.is_empty(),"count":results.size(),"results":results,"failures":failures},"\t"))
	print("EVENT_QA ",failures.is_empty()," count=",results.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
