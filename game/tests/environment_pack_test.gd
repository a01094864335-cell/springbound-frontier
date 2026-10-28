extends SceneTree

func _initialize() -> void:
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/catalog.json"))
	var failures: Array = []
	var ids: Dictionary = {}
	for entry in entries:
		if ids.has(entry.id): failures.append("Duplicate " + entry.id)
		ids[entry.id] = true
		var packed = load(entry.scene)
		if not packed is PackedScene:
			failures.append("Scene missing: " + entry.id)
			continue
		var node = packed.instantiate()
		if not node is Node3D: failures.append("Not 3D: " + entry.id)
		if node.get_child_count() == 0: failures.append("Empty: " + entry.id)
		if node.get_meta("asset_id", "") != entry.id: failures.append("Metadata: " + entry.id)
		var bounds: Array = node.get_meta("grid_obstacles", [])
		if bounds.size() != entry.grid_obstacles.size():
			failures.append("Bounds count: " + entry.id)
		else:
			for i in range(bounds.size()):
				for j in range(4):
					if not is_equal_approx(float(bounds[i][j]),float(entry.grid_obstacles[i][j])):
						failures.append("Bounds: " + entry.id)
		node.free()
	print("ENVIRONMENT_PACK_QA: %s (%d scenes) %s" % ["PASS" if failures.is_empty() else "FAIL",entries.size(),failures])
	quit(0 if failures.is_empty() else 1)
