extends RefCounted
var world: Node
var errors: Array[String]=[]
var checks:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:errors.append(message);push_error(message)
func key(code: Key) -> void:
	var e:=InputEventKey.new();e.pressed=true;e.keycode=code;e.physical_keycode=code
	Input.parse_input_event(e)
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e)
func click(point: Vector2, button:=MOUSE_BUTTON_LEFT) -> void:
	var e:=InputEventMouseButton.new();e.pressed=true;e.button_index=button;e.position=point;e.global_position=point
	Input.parse_input_event(e)
	e=e.duplicate();e.pressed=false;Input.parse_input_event(e)
func run(owner: Node) -> Dictionary:
	world=owner
	world._prepare_battle_test()
	world._qa_finish_dialog()
	var b=world.battle_view
	check(b.model.active and b.model.paused,"Safe initial preparation")
	check(not world.dialog_panel.visible and not b.model.tutorial_hold,"No modal or enemy hold from contextual guide")
	for i in range(3):await world.get_tree().process_frame
	click(world.camera.unproject_position(b.model.enemy.position)-Vector2(0,25))
	await world.get_tree().process_frame
	check(b.model.order=="attack" and not b.model.paused,"One enemy click commits and starts combat")
	var first_hit:float=-1
	for i in range(300):
		world._physics_process(.01)
		if b.model.commands_used.has("attack_hit"):first_hit=b.model.elapsed;break
	check(first_hit>0 and first_hit<3.0,"Prompt actual impact after one click")
	key(KEY_SPACE);await world.get_tree().process_frame
	check(b.model.paused and b.manual_pause,"Space is an explicit tactical pause")
	var clock:float=b.model.elapsed
	world._physics_process(.5)
	check(b.model.elapsed==clock,"Tactical pause freezes simulation")
	key(KEY_A);await world.get_tree().process_frame
	check(b.model.order=="attack" and b.model.paused,"New attack preserves explicit pause")
	var target:Vector3=b.model.player.position+Vector3.BACK*2
	if world._blocked(target):target=b.model.player.position+Vector3.LEFT*2
	click(world.camera.unproject_position(target),MOUSE_BUTTON_RIGHT)
	await world.get_tree().process_frame
	check(b.model.order=="move" and b.model.paused,"Direct move preserves explicit pause")
	key(KEY_SPACE);await world.get_tree().process_frame
	check(not b.model.paused and not b.manual_pause,"Space resumes tactical plan")
	click(b.move_button.get_global_rect().get_center());await world.get_tree().process_frame
	check(b.target_mode=="move" and b.model.paused,"Target selection temporarily holds running time")
	key(KEY_ESCAPE);await world.get_tree().process_frame
	check(b.target_mode.is_empty() and not b.model.paused,"Cancel returns to prior running state")
	click(b.attack_button.get_global_rect().get_center());await world.get_tree().process_frame
	check(b.model.order=="attack" and not b.model.paused,"Attack button commits without second target selection")
	click(b.move_button.get_global_rect().get_center());await world.get_tree().process_frame
	key(KEY_DOWN);await world.get_tree().process_frame
	var selected:Vector3=b.keyboard_cell
	key(KEY_ENTER);await world.get_tree().process_frame
	check(b.model.destination==selected and not b.model.paused,"Keyboard movement confirms and resumes automatically")
	check(not b._issue_order("move",Vector3(999,0,999)),"Invalid move is rejected")
	check(not b.model.paused,"Invalid move does not create surprise pause")
	# Boundary fixture: inventory effects still execute exactly once at simulation time.
	b.model.hp=20;b.model.hero_cooldown=0
	key(KEY_I);await world.get_tree().process_frame
	check(b.model.pending_item and not b.model.paused,"Item key queues while preserving running clock")
	world._physics_process(.02)
	check(b.model.potions==1 and world.combat.potions==1 and b.model.hp==44,"One item effect and inventory write")
	var remaining:float=b.model.hero_cooldown
	key(KEY_A);await world.get_tree().process_frame
	check(b.model.hero_cooldown==remaining,"Changing order cannot erase item recovery")
	b.tutorial.finish()
	check(not b.tutorial.panel.visible,"Guide is dismissible without gating combat")
	check(b.hero_action_bar!=null and b.enemy_action_bar!=null,"Action timing is visible on both sides")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		world.get_viewport().get_texture().get_image().save_png("res://../../combat-input-screen.png")
	print("COMBAT_INPUT_QA: ","PASS" if errors.is_empty() else "FAIL"," checks=",checks," first_hit=",first_hit," ",errors)
	return {"passed":errors.is_empty(),"checks":checks,"first_hit":first_hit,"errors":errors}
