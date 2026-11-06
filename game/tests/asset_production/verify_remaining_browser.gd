extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var browser: Node3D=(load("res://tests/asset_production/remaining_browser.tscn") as PackedScene).instantiate()
	root.add_child(browser)
	var failures: Array=[]
	for group in {"motions":1563,"props":112,"ui":36,"events":14,"world_states":4,"icons":85,"fields":29}:
		browser.set_group(group)
		await process_frame
		if browser.selected.size()!= {"motions":1563,"props":112,"ui":36,"events":14,"world_states":4,"icons":85,"fields":29}[group]:failures.append(group+" count mismatch")
		if browser.selected.is_empty():continue
		browser.show_entry(browser.selected.size()-1)
		await process_frame
		if not is_instance_valid(browser.current):failures.append(group+" missing preview")
	browser.free()
	print("REMAINING_BROWSER_QA ",failures.is_empty()," failures=",failures)
	quit(0 if failures.is_empty() else 1)
