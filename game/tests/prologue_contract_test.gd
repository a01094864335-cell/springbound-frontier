extends SceneTree
const Story=preload("res://scripts/prologue_story.gd")
const Progress=preload("res://scripts/combat_progress.gd")
const Audio=preload("res://assets/production/audio/audio_bank.gd")
var errors: Array[String]=[]
var world: Node
var assertions:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	assertions+=1
	if not ok: errors.append(message);push_error(message)
func press(code: Key) -> void:
	var e:=InputEventKey.new();e.pressed=true;e.keycode=code
	world.battle_view.handle(e)
func write(path: String, data: Dictionary) -> void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
func run() -> void:
	world=load("res://scenes/prologue.tscn").instantiate();root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.save_path="/private/tmp/prologue-contract-save.json"
	world._prepare_battle_test()
	world._qa_finish_dialog()
	var b=world.battle_view
	check(b.tutorial.stage=="resume", "Guidance starts with pause/resume")
	b._choose("attack")
	check(b.target_mode.is_empty() and b.model.order=="wait", "Cannot bypass learning by killing target")
	press(KEY_SPACE)
	for i in range(50): world._physics_process(.03)
	check(b.model.hp==48 and b.model.enemy_windup==0 and b.model.leap_windup==0, "Enemy held during input lesson")
	press(KEY_SPACE)
	world._qa_finish_dialog()
	check(b.tutorial.stage=="move", "Actual pause/resume unlocks movement")
	check(not b.model.select_order("move", b.model.player.position),"Same-cell move cannot complete lesson")
	var start: Vector3=b.model.player.position
	var target: Vector3=start+Vector3.BACK*2
	check(not world._blocked(target),"Tutorial route fixture reachable")
	b.model.select_order("move",target)
	check(b.tutorial.stage=="move" and b.model.player.position==start,"Selection does not execute movement")
	press(KEY_SPACE)
	for i in range(60):world._physics_process(.03)
	world._qa_finish_dialog()
	check(b.tutorial.stage=="wait", "Arrival unlocks wait")
	press(KEY_SPACE)
	check(b.tutorial.stage=="wait", "Auto-arrival wait does not count as explicit wait command")
	b._choose("wait");press(KEY_SPACE)
	check(b.tutorial.stage=="dodge" and b.model.leap_windup>0 and b.model.paused,"Explicit wait reveals range warning while paused")
	world._qa_finish_dialog()
	var before:int=b.model.hp
	press(KEY_SPACE)
	for i in range(60):world._physics_process(.03)
	check(b.model.hp<before and b.tutorial.stage=="dodge_retry" and b.model.paused,"Failed dodge applies actual damage and repeat guidance")
	check(not b.model.commands_used.has("range_dodge"),"Failed dodge is not recorded as success")
	b.stop()
	# Legacy journey resolution is explicitly distinct from a played victory.
	for version in [1,2,3]:
		var st=Story.new()
		for scene in ["opening","well_first","inn_first","request","farewell","leon_first"]:st.finish(scene)
		var flags:Dictionary=st.flags.duplicate()
		for flag in Story.EXTRA_FLAGS:flags.erase(flag)
		flags.closing=true
		var cp:Dictionary=Progress.fresh();cp.won=true
		if version<3:cp={}
		var record={"version":version,"map":3,"position":[-2,13],"medicine":true,"leon":true,"arrived":true,"story":flags,"combat":cp}
		write(world.save_path,record)
		world._load_game()
		check(world.map_id==3 and world.arrived and world.story.done("tea")== (version>1) and not world.story.done("departure"),"Legacy tea continues at records v"+str(version))
		check(FileAccess.file_exists(world.save_path+".v%d.bak"%version),"Legacy original backup v"+str(version))
		if version<3:check(world.combat.victory_source=="legacy_skipped","Legacy does not claim played victory")
	# Invalid saves leave both live progress and disk bytes intact.
	var before_story:Dictionary=world.story.snapshot()
	var invalid={"version":999,"map":0}
	write(world.save_path,invalid)
	var bytes:=FileAccess.get_file_as_string(world.save_path)
	world._load_game()
	check(world.story.snapshot()==before_story and world.map_id==3,"Unsupported save preserves live journey")
	check(FileAccess.get_file_as_string(world.save_path)==bytes,"Invalid original is not overwritten")
	world.save_path="/private/tmp/prologue-no-such-directory/sub/save.json"
	check(not world._save_game(false),"Write failure is reported as failure")
	var heal:AudioStreamWAV=Audio.stream("audio-0-15")
	var music:AudioStreamWAV=Audio.stream("audio-2-04")
	check(heal!=null and music!=null and music.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Production audio and loop points loaded")
	check(world.hero_sprite.has_meta("active_clip"),"Production hero clip used after load")
	world.queue_free();await process_frame
	print("PROLOGUE_CONTRACT_QA: ","PASS" if errors.is_empty() else "FAIL"," assertions=",assertions," ",errors)
	quit(0 if errors.is_empty() else 1)
