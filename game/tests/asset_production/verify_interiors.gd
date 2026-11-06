extends SceneTree
var results: Array = []
func _initialize() -> void:
	call_deferred("run")
func blocked(point: Vector2, obstacles: Array) -> bool:
	for r in obstacles:
		if Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])).grow(0.22).has_point(point): return true
	return false
func walkable(room: Node3D) -> bool:
	var obstacles: Array = room.get_meta("grid_obstacles")
	var anchor: Vector3 = room.get_node("Focus").position
	var goal: Vector2i = Vector2i(roundi(anchor.x),roundi(anchor.z))
	var frontier: Array[Vector2i] = [Vector2i(0,5)]
	var seen: Dictionary = {Vector2i(0,5): true}
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_front()
		if cell == goal: return true
		for step in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell+step
			if absi(next.x)>5 or absi(next.y)>5 or seen.has(next) or blocked(Vector2(next),obstacles): continue
			seen[next]=true
			frontier.append(next)
	return false
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/interiors/catalog.json"))
	var failed: bool = false
	for entry in data.furniture+data.rooms:
		var resource: PackedScene = load(entry.path) as PackedScene
		if resource == null:
			failed=true
			results.append({"id":entry.id,"error":"failed to load"})
			continue
		var instance: Node3D = resource.instantiate() as Node3D
		root.add_child(instance)
		var ok: bool = instance.get_meta("asset_id") == entry.id
		if entry.id.begins_with("interior"):
			ok = ok and instance.has_node("Entry") and instance.has_node("Focus") and walkable(instance)
		results.append({"id":entry.id,"loaded":true,"entry_to_focus":ok})
		failed = failed or not ok
		instance.queue_free()
		await process_frame
	var file: FileAccess = FileAccess.open("res://tests/asset_production/verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"count":results.size(),"results":results},"\t"))
	file.close()
	print("INTERIOR_ASSET_QA ",not failed," count=",results.size())
	quit(1 if failed else 0)
