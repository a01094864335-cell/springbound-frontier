extends SceneTree
## Traverse real maps and execute production interaction/command handlers. No progress,
## actor positions, health, inventory or victory flags are assigned by the test.
var world: Node
var errors: Array[String] = []
var steps := 0
var captures := false
var answer := "a"
var reverse_errands := false
var hold_choice := false
var mute_audio := false
var large_text := false
var output := "/private/tmp/prologue-e2e"

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)
func key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	world._unhandled_input(e)
func dialog() -> void:
	var count := 0
	while world.dialog_panel.visible and count < 400:
		key(KEY_ENTER)
		count += 1
	check(count < 400, "Dialogue cannot finish")
func capture(label: String) -> void:
	print("E2E_STAGE ", label, " map=",world.map_id," hp=",world.combat.hp)
	if not captures: return
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+label+".png")
func settle() -> void:
	var timeout := Time.get_ticks_msec()+8000
	while world.transitioning and Time.get_ticks_msec()<timeout: await process_frame
	check(not world.transitioning, "Transition did not finish")
	dialog()
func go(kind: String, destination := -1) -> void:
	var matches: Array = world.interactions.filter(func(p): return p.kind == kind and (destination<0 or p.get("map",-1)==destination))
	if matches.is_empty(): check(false,"Missing interaction "+kind); return
	check(world.travel.approach(matches[0]), "Unreachable "+kind)
	var budget := 3000
	while (not world.travel.pending.is_empty() or world.has_walk_target or world.walker.moving) and not world.transitioning and not world.dialog_panel.visible and budget>0:
		world._physics_process(0.05)
		budget-=1
		steps+=1
		if budget%20==0: await process_frame
	check(budget>0, "Walking timed out "+kind)
	await settle()
func roundtrip(label: String) -> void:
	var before: Dictionary = world.story.snapshot()
	var hp: int = world.combat.hp
	var potions: int = world.combat.potions
	var map: int = world.map_id
	check(world._save_game(false),"Save failed "+label)
	world._load_game()
	check(world.story.snapshot()==before and world.combat.hp==hp and world.combat.potions==potions and world.map_id==map,"Save changed state "+label)
func move_safe(range_only := false) -> bool:
	var b = world.battle_view
	var origin: Vector3 = b.model.player.target
	for offset in [Vector3(0,0,3),Vector3(0,0,-3),Vector3(3,0,0),Vector3(-3,0,0)]:
		var target: Vector3 = origin+offset
		if world._blocked(target) or b._path(origin,target).is_empty(): continue
		var distance: Vector3 = target-b.model.leap_target
		if range_only and absf(distance.x)+absf(distance.z)<2: continue
		var click := InputEventMouseButton.new()
		click.pressed=true
		click.button_index=MOUSE_BUTTON_RIGHT
		click.position=world.camera.unproject_position(target)
		b.handle(click)
		key(KEY_SPACE)
		return true
	return false
func attack() -> void:
	world.battle_view._choose("attack")
	key(KEY_ENTER)
	key(KEY_SPACE)
func fight() -> void:
	var b = world.battle_view
	check(b.model.active and b.model.paused,"Battle not paused at start")
	for i in range(30000):
		if not b.model.active: break
		if world.dialog_panel.visible:
			dialog()
			continue
		var stage: String = b.tutorial.stage
		if b.model.paused:
			match stage:
				"resume", "pause", "dodge_retry": key(KEY_SPACE)
				"move": check(move_safe(),"No tutorial movement")
				"wait": b._choose("wait"); key(KEY_SPACE)
				"dodge":
					if i<100: await capture("04-range-warning")
					check(move_safe(true),"No safe dodge cell")
				"attack": attack()
				"heal": b.tutorial.finish(); key(KEY_SPACE)
				_: key(KEY_SPACE)
		elif stage=="pause":
			key(KEY_SPACE)
		elif stage=="off":
			if b.model.leap_windup>0.7 and b.model.order=="attack" and not b.model.player.moving: move_safe(true)
			elif b.model.order=="wait" and b.model.enemy_windup<=0 and b.model.leap_windup<=0: attack()
		world._physics_process(0.03)
		if i%40==0: await process_frame
	print("BATTLE_E2E_STATE ",b.tutorial.stage," ",b.model.order," ",b.model.commands_used," hp=",b.model.hp)
	check(world.combat.won and world.combat.hp>0,"Battle did not end in victory")
	check(b.model.commands_used.has("range_dodge"),"Area dodge did not execute")
	check(b.model.commands_used.has("attack_hit"),"No actual sword hit")
	check(b.model.potions==2,"Optional healing was forced")
	dialog()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg=="--mute": mute_audio=true
		if arg=="--large-text": large_text=true
		if arg=="--hold-choice": hold_choice=true
		if arg=="--choice=b": answer="b"; reverse_errands=true
		if arg.begins_with("--qa-output="): output=arg.trim_prefix("--qa-output=")
	DirAccess.make_dir_recursive_absolute(output)
	captures=DisplayServer.get_name()!="headless"
	world=load("res://scenes/prologue.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.save_path=output+"/save.json"
	world.settings_path=output+"/settings.cfg"
	if mute_audio: world.audio.set_levels(0,0)
	if large_text: world._toggle_text_scale()
	world._new_game()
	dialog()
	await capture("01-morning")
	await go("exit",1)
	await go("inn" if reverse_errands else "water")
	check(not world.story.errands_done(),"Single errand completes both")
	await go("water" if reverse_errands else "inn")
	check(world.story.errands_done(),"Errands incomplete")
	roundtrip("errands")
	await go("exit",0)
	await go("marta")
	await go("medicine")
	await go("marta")
	roundtrip("farewell")
	await go("exit",1)
	await go("exit",2)
	check(world.story.done("trail_intro"),"Trail introduction missing")
	await capture("02-trail")
	await go("leon")
	await capture("03-battle-paused")
	await fight()
	await capture("05-victory")
	await go("leon")
	check(world.met_leon and world.companion.active and world.story.done("treatment"),"Treatment / injured companion missing")
	roundtrip("companion")
	await go("exit",3)
	check(world.story.done("arrival"),"Arrival scene missing")
	await go("delivery")
	check(world.arrived and not world.combat.sword,"Medicine/patient handoff or sword return missing")
	roundtrip("delivery")
	await capture("06-handoff")
	await go("leon_arrival")
	await settle()
	check(world.story.done("tea") and not world.story.done("closing"),"Tea incorrectly completes MQ05")
	roundtrip("tea")
	await go("halven")
	check(world.story.done("records"),"Morning records missing")
	await capture("07-records")
	await go("leon_arrival")
	check(world.choice_panel.visible and not world.story.done("homeward"),"Choice commits before player selects")
	check(not world._save_game(false),"Can save unselected choice as complete")
	await capture("08-choice")
	if hold_choice:
		while world.choice_panel.visible: await process_frame
	else:
		key(KEY_1 if answer=="a" else KEY_2)
	dialog()
	check(world.story.return_choice==answer and world.story.done("homeward"),"Wrong choice branch")
	roundtrip("choice")
	await go("leon_arrival")
	check(world.story.done("departure") and world.story.done("closing") and world.completion_panel.visible,"MQ05 not complete")
	check(world.combat.sword,"Sword custody not renewed")
	await capture("09-complete")
	world._close_completion()
	roundtrip("complete")
	await go("leon_arrival")
	check(not world.completion_panel.visible,"Repeat talk replays completion")
	# Invalid file cannot mutate live progress.
	var valid := FileAccess.get_file_as_string(world.save_path)
	var broken: Dictionary=JSON.parse_string(valid)
	broken.position=["invalid",0]
	var f:=FileAccess.open(world.save_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(broken)); f.close()
	world._load_game()
	check(world.story.done("departure") and world.map_id==3,"Corrupt save mutates progress")
	f=FileAccess.open(world.save_path,FileAccess.WRITE);f.store_string(valid);f.close()
	var report={"passed":errors.is_empty(),"errors":errors,"choice":answer,"reverse_errands":reverse_errands,"muted":mute_audio,"large_text":large_text,"walking_ticks":steps,"hp":world.combat.hp,"potions":world.combat.potions,"story":world.story.snapshot(),"engine":Engine.get_version_info().string,"renderer":DisplayServer.get_name()}
	f=FileAccess.open(output+"/result.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	world.queue_free()
	await process_frame
	print("PROLOGUE_E2E: ","PASS" if errors.is_empty() else "FAIL"," choice=",answer," ",errors)
	quit(0 if errors.is_empty() else 1)
