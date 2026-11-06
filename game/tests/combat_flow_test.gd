extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world=load("res://scenes/prologue.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	var probe=preload("res://tests/combat_input_probe.gd").new()
	var result:Dictionary=await probe.run(world)
	world.queue_free()
	await process_frame
	quit(0 if result.passed else 1)
