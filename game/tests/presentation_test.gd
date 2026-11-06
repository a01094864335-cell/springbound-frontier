extends SceneTree
var world: Node
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: errors.append(message); push_error(message)
func run() -> void:
	world = load("res://scenes/prologue.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world._new_game()
	world._qa_finish_dialog()
	var marta: Dictionary = world.interactions.filter(func(p): return p.kind == "marta")[0]
	world.travel.click(world.camera.unproject_position(Vector3(marta.pos.x,0.8,marta.pos.y)))
	check(world.travel.pending.get("kind") == "marta","Click did not select the actual person")
	for i in range(500):
		world._physics_process(0.05)
		if world.dialog_panel.visible: break
	check(world.dialog_panel.visible and world.active_scene == "marta_wait","Click did not walk and activate dialogue")
	world._qa_finish_dialog()
	world._set_click_route(Vector3(4,0,4))
	world.travel.click(world.camera.unproject_position(Vector3(0,0,0)))
	check(not world.has_walk_target and is_instance_valid(world.travel.marker),"Invalid click retained a stale route / lacked feedback")
	check(world.travel.marker.material_override.albedo_color == Color("e98278"),"Blocked destination feedback is not red")
	world.travel.approach(marta)
	Input.action_press("move_down")
	world._physics_process(0.05)
	Input.action_release("move_down")
	check(world.travel.pending.is_empty(),"Keyboard movement did not cancel automatic interaction")
	world._prepare_battle_test()
	var battle = world.battle_view
	check(battle.tutorial.panel.visible and battle.model.paused,"First battle guidance is not visible / paused")
	var position: Vector3 = world.hero.position
	world._physics_process(0.5)
	check(world.hero.position == position and battle.model.elapsed == 0,"Guidance pause advances combat")
	var potions: int = battle.model.potions
	battle.tutorial.finish()
	check(battle.model.paused and battle.model.potions == potions,"Skip guide resumed combat or spent an item")
	# Exercise the actual terminal-event branch with a still-active hit flash.
	battle.model.enemy_hp = 6
	battle.hero_flash = 10
	world._qa_win_first_battle(false)
	check(world.combat.won and battle.hero_flash == 0 and world.hero_sprite.modulate == Color.WHITE,"Victory reapplied a stale red hit tint")
	world.combat.hp = 40
	world.combat.potions = 2
	world._field_heal()
	check(world.combat.hp == 48 and world.combat.potions == 1,"Field healing did not cap health or consume one item")
	world._field_heal()
	check(world.combat.potions == 1,"Full-health healing consumed an item")
	world._qa_complete_treatment()
	check(world.companion.active,"Companion did not join after treatment")
	check(world.companion.actor.position.distance_to(world.hero.position) >= 1.8,"Companion spawns overlapping the hero")
	world.queue_free()
	await process_frame
	print("PRESENTATION_QA: ","PASS" if errors.is_empty() else "FAIL"," ",errors)
	quit(0 if errors.is_empty() else 1)
