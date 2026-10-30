extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var scene = load("res://scenes/prologue.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._prepare_battle_test()
	scene._play_scene("leon_bridge")
	scene._qa_finish_dialog()
	for i in range(8): await process_frame
	scene.canvas.hide()
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.battle_view.enemy_caption.hide()
	scene.battle_view._clear_cells()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../design/battle-ui/assets/battle-field.png"))
	quit()
