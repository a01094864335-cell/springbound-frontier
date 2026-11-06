extends SceneTree
var failures: Array = []
var verified: Array = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/fields/catalog.json"))
	if rows.size() != 29:
		failures.append("Expected 29 fields")
	for entry in rows:
		var packed: PackedScene = load(entry.path)
		if packed == null:
			failures.append(entry.id + " load failed")
			continue
		var scene: Node3D = packed.instantiate()
		root.add_child(scene)
		await physics_frame
		await physics_frame
		var space: PhysicsDirectSpaceState3D = scene.get_world_3d().direct_space_state
		var samples: int = 0
		for i in range(entry.route.size()-1):
			var a: Vector3 = Vector3(entry.route[i][0], .9, entry.route[i][1])
			var b: Vector3 = Vector3(entry.route[i+1][0], .9, entry.route[i+1][1])
			var shape: SphereShape3D = SphereShape3D.new()
			shape.radius = .4
			for step in range(int(a.distance_to(b)*2)+1):
				var pos: Vector3 = a.move_toward(b, step*.5)
				var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
				query.shape = shape
				query.transform = Transform3D(Basis.IDENTITY,pos)
				if not space.intersect_shape(query).is_empty():
					failures.append(entry.id+" route obstructed at "+str(pos))
				var floor_query := PhysicsRayQueryParameters3D.create(pos,pos-Vector3(0,2,0))
				if space.intersect_ray(floor_query).is_empty():
					failures.append(entry.id+" missing floor")
				samples += 1
		for rect in entry.obstacles:
			var probe := SphereShape3D.new()
			probe.radius = .4
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = probe
			query.transform = Transform3D(Basis.IDENTITY,Vector3(rect[0]+rect[2]/2.0,.9,rect[1]+rect[3]/2.0))
			if space.intersect_shape(query).is_empty():
				failures.append(entry.id+" obstacle fails to block")
		for name in ["Entry","Exit","Objective"]:
			if not scene.get_node_or_null(name) is Marker3D:
				failures.append(entry.id+" missing "+name)
		verified.append({"id":entry.id,"route_samples":samples})
		scene.free()
	var file := FileAccess.open("res://tests/asset_production/field-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"count":verified.size(),"results":verified,"failures":failures},"\t"))
	print("FIELD_QA ",failures.is_empty()," count=",verified.size()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
