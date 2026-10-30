extends Node
## Rendering/input adapter. Simulation and persistence live outside UI callbacks.
const Battle = preload("res://scripts/first_battle.gd")
var world: Node
var model = Battle.new()
var panel: PanelContainer
var heading: Label
var health: Label
var enemy_health: Label
var order_label: Label
var log_label: Label
var help_label: Label
var hero_bar: ProgressBar
var enemy_bar: ProgressBar
var resume_button: Button
var item_button: Button
var defeat_panel: PanelContainer
var defeat_text: Label
var defeat_heading: Label
var enemy_actor: Node3D
var enemy_sprite: Sprite3D
var enemy_caption: Label3D
var sword: Node3D
var target_ring: MeshInstance3D
var destination_ring: MeshInstance3D
var textures: Dictionary = {}
var target_mode := ""
var keyboard_cell := Vector3.ZERO
var keyboard_target := false
var log_lines: Array[String] = []
var enemy_flash := 0.0
var hero_flash := 0.0
var enemy_contact := 0.0
var sounds: Dictionary = {}
var audio_players: Array[AudioStreamPlayer] = []
var audio_index := 0
var retry_button: Button
var attack_button: Button
var move_button: Button
var resolved := false
var threat_visible := false
var cell_overlay: Node3D
var overlay_key := ""

func setup(owner_world: Node) -> void:
	world = owner_world
	_make_ui()
	_make_weapon()
	for i in range(4):
		var audio := AudioStreamPlayer.new()
		audio.volume_db = -19
		add_child(audio)
		audio_players.append(audio)

func busy() -> bool:
	return threat_visible or model.active or model.outcome == "defeat"

func show_threat() -> void:
	threat_visible = true
	if is_instance_valid(enemy_actor): return
	_make_enemy()
	enemy_actor.position = Vector3(5,0,5)
	enemy_caption.text = "가시털 들쥐"

func start(checkpoint: Dictionary, restore_defeat := false) -> void:
	show_threat()
	var hero_pos := Vector3(float(checkpoint.hero[0]),0,float(checkpoint.hero[1]))
	var enemy_pos := Vector3(float(checkpoint.enemy[0]),0,float(checkpoint.enemy[1]))
	model.setup(hero_pos,enemy_pos,int(checkpoint.hp),int(checkpoint.mp),int(world.combat.potions),str(checkpoint.mode),world._blocked,_path,_line_clear)
	# The exploration walker is the same moving actor, not a second simulation.
	world.walker = model.player
	world.hero.position = model.player.position
	resolved = false
	target_mode = ""
	log_lines.clear()
	enemy_flash = 0
	hero_flash = 0
	enemy_contact = 0
	panel.show()
	world.hud.hide()
	world.exploration_controls.hide()
	defeat_panel.hide()
	if restore_defeat:
		model.active = false
		model.outcome = "defeat"
		resolved = true
		_show_defeat(true)
	_refresh()

func stop() -> void:
	model.active = false
	model.outcome = ""
	if world.exploration_controls: world.exploration_controls.show()
	threat_visible = false
	world.hud.show()
	panel.hide()
	defeat_panel.hide()
	target_mode = ""
	if is_instance_valid(enemy_actor): enemy_actor.queue_free()
	enemy_actor = null
	world.hero_sprite.modulate = Color.WHITE
	if is_instance_valid(target_ring): target_ring.queue_free()
	if is_instance_valid(destination_ring): destination_ring.queue_free()
	target_ring = null
	destination_ring = null
	_clear_cells()
	_sync_weapon()

func tick(delta: float) -> void:
	_sync_weapon()
	if not model.active: return
	if world.dialog_panel.visible or world.history_panel.visible or world.paused: return
	model.advance(delta)
	world.hero.position = model.player.position
	world.hero_status_label.text = "에일  HP %d / 48" % model.hp
	world._set_walk_frame()
	world._update_camera(delta)
	world._update_occlusion()
	world.prompt_label.hide()
	world.minimap.queue_redraw()
	if is_instance_valid(enemy_actor): enemy_actor.position = model.enemy.position
	if not model.paused:
		enemy_flash = maxf(0,enemy_flash-delta)
		hero_flash = maxf(0,hero_flash-delta)
		enemy_contact = maxf(0,enemy_contact-delta)
	while not model.events.is_empty(): _event(model.events.pop_front())
	if is_instance_valid(enemy_sprite):
		enemy_sprite.modulate = Color("ff8d80") if enemy_flash > 0 else Color.WHITE
		var pose := "front"
		var diff: Vector3 = model.player.position-model.enemy.position
		if model.enemy_windup > 0: pose = "prepare"
		elif enemy_contact > 0: pose = "contact"
		elif absf(diff.x) > absf(diff.z): pose = "side"
		elif diff.z < 0: pose = "back"
		enemy_sprite.texture = textures[pose]
		enemy_sprite.offset.y = enemy_sprite.texture.get_height()/2.0
		enemy_sprite.pixel_size = 1.0/enemy_sprite.texture.get_height()
		enemy_sprite.flip_h = pose in ["side","prepare","contact"] and diff.x > 0
		enemy_caption.text = "가시털 들쥐 · 공격 준비" if model.enemy_windup > 0 else "가시털 들쥐"
	world.hero_sprite.modulate = Color("ff9b87") if hero_flash > 0 else Color.WHITE
	_refresh()
	_update_cells()

func _event(event: Dictionary) -> void:
	match event.kind:
		"item":
			_sound("heal")
			_log("에일 회복 +%d · 회복약 %d개 남음" % [event.amount,model.potions])
			world._combat_item_used(model.potions)
		"enemy_hit": _sound("strike"); enemy_flash = 0.2; _log("가시털 들쥐에게 %d 피해" % event.amount)
		"hero_hit": _sound("hurt"); enemy_contact = 0.18; hero_flash = 0.25; _log("에일이 %d 피해를 받았다" % event.amount)
		"enemy_prepare": _log("마물이 몸을 낮췄다. 거리를 벌리면 물기를 피할 수 있다.")
		"enemy_miss": enemy_contact = 0.18; _log("마물의 물기를 피했다")
		"hero_miss": _log("검이 닿지 않았다. 거리를 확인하자.")
		"blocked": _log("그 지점으로 갈 수 없다")
		"victory":
			if resolved: return
			resolved = true
			_sound("victory")
			panel.hide()
			world._combat_victory(model.hp,model.mp,model.potions)
		"defeat":
			if resolved: return
			resolved = true
			world._combat_defeat(model.potions)
			_show_defeat()

func handle(event: InputEvent) -> bool:
	if not busy(): return false
	if world.dialog_panel.visible: return false
	if event is InputEventKey and event.pressed and not event.echo:
		if model.outcome == "defeat": return event.keycode not in [KEY_TAB,KEY_ENTER,KEY_SPACE,KEY_UP,KEY_DOWN]
		if not target_mode.is_empty() and event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_ENTER]:
			if event.keycode == KEY_ENTER:
				if target_mode == "attack":
					model.select_order("attack")
					target_mode = ""
				else:
					var click := InputEventMouseButton.new()
					click.pressed = true
					click.button_index = MOUSE_BUTTON_RIGHT
					click.position = world.camera.unproject_position(keyboard_cell)
					handle(click)
			else:
				keyboard_target = true
				var directions := {KEY_UP:Vector3.FORWARD,KEY_DOWN:Vector3.BACK,KEY_LEFT:Vector3.LEFT,KEY_RIGHT:Vector3.RIGHT}
				keyboard_cell += directions[event.keycode]
			_refresh()
			_update_cells()
			return true
		if event.keycode in [KEY_SPACE,KEY_ESCAPE]:
			if event.keycode == KEY_ESCAPE and not target_mode.is_empty():
				target_mode = ""
				_log("대상 선택 취소 · 현재 명령은 유지됩니다")
			else: _toggle_time()
			_refresh()
			return true
		if event.keycode in [KEY_F5,KEY_F9]:
			_log("전투 중에는 전투 직전 기록을 유지합니다. 패배하면 재도전할 수 있습니다.")
			return true
		if event.keycode == KEY_1:
			_log("에일 선택")
			return true
		if event.keycode in [KEY_TAB,KEY_ENTER,KEY_UP,KEY_DOWN] and target_mode.is_empty() and model.paused: return false
		# Exploration, saving and loading cannot bypass the battle checkpoint.
		return true
	if event is InputEventMouseMotion:
		keyboard_target = false
	if event is InputEventMouseButton and event.pressed and model.active:
		if event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: return true
		var point: Variant = _ground(event.position)
		if point == null: return true
		if event.button_index == MOUSE_BUTTON_RIGHT or target_mode == "move":
			var cell := Vector3(roundf(point.x),0,roundf(point.z))
			var route := _path(model.player.position,cell)
			if world._blocked(cell) or route.is_empty() or cell.distance_to(model.enemy.position) < 0.8:
				_log("이동할 수 없는 지점이야. 길 위를 선택하자.")
			else:
				model.select_order("move",cell)
				target_mode = ""
				_show_destination(cell)
				_log("이동 명령 선택 · Space로 재개")
		elif _enemy_hit_screen(event.position):
			model.select_order("attack")
			target_mode = ""
			_log("가시털 들쥐 공격 선택 · Space로 재개")
		_refresh()
		return true
	return false

func _choose(value: String) -> void:
	if not model.active: return
	model.paused = true
	if value == "wait":
		model.select_order("wait")
		target_mode = ""
	else:
		target_mode = value
		keyboard_cell = model.player.target
		keyboard_target = true
	_refresh()

func _item() -> void:
	if model.select_item():
		target_mode = ""
		_log("회복약 선택 · 재개할 때 즉시 사용")
	_refresh()

func _retry(with_help: bool) -> void:
	world._restore_combat_checkpoint()
	model.retry()
	world.walker = model.player
	world.hero.position = model.player.position
	resolved = false
	defeat_panel.hide()
	panel.show()
	enemy_flash = 0
	hero_flash = 0
	enemy_contact = 0
	target_mode = ""
	world.hero_sprite.modulate = Color.WHITE
	_log("재도전 · 남은 회복약 %d개" % model.potions)
	_refresh()
	if with_help: world._play_scene("firstbattle_help")

func _refresh() -> void:
	heading.text = "첫 전투 · " + ("명령 정지" if model.paused else "시간 진행 중")
	health.text = "에일  HP %d / %d   MP %d   회복약 %d개" % [model.hp,Battle.MAX_HP,model.mp,model.potions]
	enemy_health.text = "가시털 들쥐  HP %d / %d" % [model.enemy_hp,Battle.ENEMY_HP]
	hero_bar.value = model.hp
	enemy_bar.value = model.enemy_hp
	var labels := {"wait":"대기","attack":"마물에게 접근해 반복 공격","move":"선택한 칸으로 이동"}
	order_label.text = "에일의 명령: "+labels[model.order]+(" · 회복약 사용 예약" if model.pending_item else "")
	if model.hero_cooldown > 0: order_label.text += " · 행동 후 대기 %.1f초" % model.hero_cooldown
	resume_button.text = "재개 · Space" if model.paused else "정지 · Space"
	item_button.text = "회복약 (%d)" % model.potions
	item_button.disabled = not model.active or model.hp >= Battle.MAX_HP or model.potions <= 0 or model.hero_cooldown > 0 or model.pending_item
	help_label.text = "이동 칸: 방향키 → Enter · 마우스로도 선택" if target_mode == "move" else ("마물 선택: Enter / 클릭 · 인접 1칸 공격" if target_mode == "attack" else "명령을 고른 뒤 Space로 재개 · 우클릭 이동 · 마물 클릭 공격")
	if target_mode.is_empty() and not model.commands_used.has("attack_hit"):
		help_label.text = "① 공격 → 마물 클릭 → Space 재개. 사거리까지 다가가 반복 공격합니다."
	elif target_mode.is_empty() and not model.commands_used.has("dodge"):
		help_label.text = "② 마물이 공격 준비를 하면 이동할 칸을 지정하고 Space로 재개해 피하세요."
	elif target_mode.is_empty() and model.hp < Battle.MAX_HP and model.potions > 0 and not model.commands_used.has("item_used"):
		help_label.text = "③ Space로 정지 → 회복약 선택 → Space 재개. 사용 뒤에는 잠시 기다립니다."
	if is_instance_valid(target_ring): target_ring.visible = model.order == "attack" and model.active
	if is_instance_valid(destination_ring): destination_ring.visible = model.order == "move" and model.active

func _log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 2: log_lines.pop_front()
	log_label.text = "\n".join(log_lines)

func _make_ui() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	world.ui_root.add_child(panel)
	var layout := Control.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(layout)
	var status := _window(layout,Vector2(24,-158),Vector2(330,134),Control.PRESET_BOTTOM_LEFT)
	var left := VBoxContainer.new()
	status.add_child(left)
	world._label(left,"PLAYER  /  에일",13,Color("d6d3bd"))
	health = world._label(left,"",16)
	hero_bar = _bar(left,Battle.MAX_HP,Color("76ba9d"))
	order_label = world._label(left,"",14)
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var target := _window(layout,Vector2(-298,24),Vector2(274,82),Control.PRESET_TOP_RIGHT)
	var target_stack := VBoxContainer.new()
	target.add_child(target_stack)
	world._label(target_stack,"TARGET",12,Color("c8bca5"))
	enemy_health = world._label(target_stack,"",16)
	enemy_bar = _bar(target_stack,Battle.ENEMY_HP,Color("bb7470"))
	var commands := _window(layout,Vector2(-218,-328),Vector2(194,304),Control.PRESET_BOTTOM_RIGHT)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation",3)
	commands.add_child(buttons)
	world._label(buttons,"COMMAND  /  에일",14,Color("e6d3a3"))
	attack_button = _small_button(buttons,"공격",func(): _choose("attack"))
	move_button = _small_button(buttons,"이동",func(): _choose("move"))
	_small_button(buttons,"대기",func(): _choose("wait"))
	item_button = _small_button(buttons,"회복약",_item)
	resume_button = _small_button(buttons,"재개 · Space",_toggle_time)
	_small_button(buttons,"조작 안내",func(): model.paused = true; world._play_scene("firstbattle_help"))
	heading = world._label(layout,"",18,Color("f1d89d"))
	heading.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	heading.position = Vector2(-160,24)
	heading.size = Vector2(320,28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label = world._label(layout,"",14,Color("e5d9b5"))
	help_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	help_label.position = Vector2(-250,-60)
	help_label.size = Vector2(500,44)
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label = world._label(layout,"",14,Color("e2e6dc"))
	log_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	log_label.position = Vector2(24,24)
	log_label.size = Vector2(360,76)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [heading,help_label,log_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_shadow_color",Color("10151c"))
		label.add_theme_constant_override("shadow_outline_size",5)
	panel.hide()
	defeat_panel = PanelContainer.new()
	defeat_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	defeat_panel.offset_left = -280
	defeat_panel.offset_right = 280
	defeat_panel.offset_top = -190
	defeat_panel.offset_bottom = 190
	defeat_panel.add_theme_stylebox_override("panel",world._panel_style(Color("101d39")))
	world.ui_root.add_child(defeat_panel)
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation",12)
	defeat_panel.add_child(choices)
	defeat_heading = world._label(choices,"에일이 쓰러졌다",29,Color("edbba3"))
	defeat_text = world._label(choices,"",18)
	defeat_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retry_button = world._button(choices,"다시 도전 · 명령부터 선택",func(): _retry(false))
	world._button(choices,"조작 안내를 보고 다시 도전",func(): _retry(true))
	world._button(choices,"시작 화면으로",world._combat_to_title)
	defeat_panel.hide()

func _bar(parent: Node, maximum: int, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0,12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar

func _small_button(parent: Node, title: String, callback: Callable) -> Button:
	var button: Button = world._button(parent,title,callback)
	button.custom_minimum_size = Vector2(166,32)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size",16)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("34404a") if state in ["hover","focus"] else Color("17232d")
		style.border_color = Color("d2c89d") if state in ["hover","focus"] else Color("657477")
		style.set_border_width_all(1)
		style.set_content_margin_all(5)
		button.add_theme_stylebox_override(state,style)
	return button

func _show_defeat(interrupted := false) -> void:
	_clear_cells()
	defeat_heading.text = "전투 직전 기록을 불러왔다" if interrupted else "에일이 쓰러졌다"
	panel.hide()
	defeat_text.text = "체력·마나·위치·진행은 전투 직전으로 돌아갑니다.\n사용한 회복약은 돌아오지 않습니다.\n남은 회복약: %d개" % model.potions
	defeat_panel.show()
	world.ui_root.move_child(defeat_panel,-1)
	retry_button.grab_focus()

func _ground(screen: Vector2) -> Variant:
	return Plane(Vector3.UP,0).intersects_ray(world.camera.project_ray_origin(screen),world.camera.project_ray_normal(screen))

func _path(from: Vector3, to: Vector3) -> Array:
	var start := Vector2i(roundi(from.x),roundi(from.z))
	var end := Vector2i(roundi(to.x),roundi(to.z))
	if not world.navigation.is_in_boundsv(start) or not world.navigation.is_in_boundsv(end): return []
	var result: Array = []
	for cell in world.navigation.get_id_path(start,end): result.append(Vector3(cell.x,0,cell.y))
	return result

func _line_clear(from: Vector3, to: Vector3) -> bool:
	for fraction in [0.2,0.4,0.6,0.8]:
		if world._blocked(from.lerp(to,fraction),0.12): return false
	return true

func _make_enemy() -> void:
	var source: Texture2D = load("res://assets/battle/spine-rat-board-v1.png")
	var regions := {"front":Rect2i(910,120,210,240),"back":Rect2i(1140,120,220,260),"side":Rect2i(1365,120,395,240),"prepare":Rect2i(880,510,285,290),"contact":Rect2i(1165,510,320,285)}
	for key in regions:
		textures[key] = _cutout(source,regions[key])
	enemy_actor = Node3D.new()
	world.map_root.add_child(enemy_actor)
	enemy_sprite = Sprite3D.new()
	enemy_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	enemy_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	enemy_sprite.shaded = false
	enemy_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	enemy_sprite.texture = textures.front
	enemy_sprite.pixel_size = 1.0/enemy_sprite.texture.get_height()
	enemy_sprite.offset.y = enemy_sprite.texture.get_height()/2.0
	enemy_sprite.position.y = 0.04
	enemy_actor.add_child(enemy_sprite)
	enemy_caption = Label3D.new()
	enemy_caption.font = world.body_font
	enemy_caption.font_size = 28
	enemy_caption.pixel_size = 0.012
	enemy_caption.position.y = 2.1
	enemy_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	enemy_caption.no_depth_test = true
	enemy_actor.add_child(enemy_caption)
	target_ring = _ring(0.65,Color("ee9b64"))
	enemy_actor.add_child(target_ring)
	target_ring.visible = false
	destination_ring = _ring(0.42,Color("e3cd80"))
	world.map_root.add_child(destination_ring)
	destination_ring.hide()

func _cutout(source: Texture2D, rect: Rect2i) -> ImageTexture:
	var image := source.get_image().get_region(rect)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()
	var visited := PackedByteArray()
	visited.resize(w*h)
	var queue: Array[Vector2i] = []
	for x in range(w): queue.append(Vector2i(x,0)); queue.append(Vector2i(x,h-1))
	for y in range(h): queue.append(Vector2i(0,y)); queue.append(Vector2i(w-1,y))
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if cell.x < 0 or cell.y < 0 or cell.x >= w or cell.y >= h: continue
		var offset := cell.y*w+cell.x
		if visited[offset]: continue
		visited[offset] = 1
		var color := image.get_pixelv(cell)
		if color.r < 0.76 or color.g < 0.71 or color.b < 0.6: continue
		image.set_pixelv(cell,Color.TRANSPARENT)
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: queue.append(cell+direction)
	return ImageTexture.create_from_image(image.get_region(image.get_used_rect()))

func _ring(radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius-0.04
	torus.outer_radius = radius
	mesh.mesh = torus
	mesh.position.y = 0.06
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh.material_override = material
	return mesh

func _show_destination(pos: Vector3) -> void:
	if is_instance_valid(destination_ring): destination_ring.position = pos+Vector3(0,0.06,0)

func _make_weapon() -> void:
	sword = Node3D.new()
	world.hero.add_child(sword)
	var blade := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.09,0.06,0.9)
	blade.mesh = shape
	blade.position.z = -0.4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("dbe5e7")
	blade.material_override = material
	sword.add_child(blade)
	var guard := MeshInstance3D.new()
	var guard_shape := BoxMesh.new()
	guard_shape.size = Vector3(0.32,0.08,0.08)
	guard.mesh = guard_shape
	guard.material_override = material
	sword.add_child(guard)
	sword.position = Vector3(0.4,0.9,0.2)
	sword.hide()

func _sync_weapon() -> void:
	if not is_instance_valid(sword): return
	sword.visible = bool(world.combat.sword)
	if model.active:
		var diff: Vector3 = model.enemy.position-world.hero.position
		var angle := atan2(-diff.x,-diff.z)
		var swing: float = -0.9+1.8*(1-model.hero_windup/Battle.HERO_WINDUP) if model.hero_windup > 0 else 0.0
		sword.rotation.y = angle+swing
	else: sword.rotation.y = -0.4


func _toggle_time() -> void:
	if model.paused and not target_mode.is_empty():
		_log("먼저 마물이나 이동할 지점을 선택하세요. Esc로 선택을 취소할 수 있습니다.")
		_refresh()
		return
	model.toggle_time()
	_refresh()

func _enemy_hit_screen(point: Vector2) -> bool:
	var foot: Vector2 = world.camera.unproject_position(model.enemy.position)
	return Rect2(foot-Vector2(55,100),Vector2(110,115)).has_point(point)

func _sound(kind: String) -> void:
	var args := OS.get_cmdline_user_args()
	if "--qa" in args or "--battle-qa" in args or "--battle-capture" in args or "--story-capture" in args: return
	if not sounds.has(kind):
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var duration := 0.25 if kind == "victory" else 0.10
		var count := int(duration*22050)
		var pcm := PackedByteArray()
		pcm.resize(count*2)
		var frequencies := {"strike":880.0,"hurt":125.0,"heal":660.0,"victory":523.25}
		for i in range(count):
			var t := float(i)/22050.0
			var envelope := pow(1.0-float(i)/count,2)
			var tone := sin(TAU*float(frequencies[kind])*t)
			if kind in ["strike","hurt"]: tone = tone*0.5+sin(TAU*3127*t)*0.3
			elif kind == "victory": tone = (tone+sin(TAU*659.25*t)+sin(TAU*783.99*t))/3.0
			pcm.encode_s16(i*2,int(tone*envelope*14000))
		stream.data = pcm
		sounds[kind] = stream
	var audio := audio_players[audio_index % audio_players.size()]
	audio_index += 1
	audio.stream = sounds[kind]
	audio.play()


func _exit_tree() -> void:
	for audio in audio_players:
		if is_instance_valid(audio): audio.stop()
	model.blocked = Callable()
	model.pathfinder = Callable()
	model.line_clear = Callable()


func _clear_cells() -> void:
	if is_instance_valid(cell_overlay): cell_overlay.queue_free()
	cell_overlay = null
	overlay_key = ""

func _update_cells() -> void:
	var point: Variant = _ground(world.get_viewport().get_mouse_position())
	if point == null: return
	var hover := keyboard_cell if keyboard_target else Vector3(roundf(point.x),0,roundf(point.z))
	var origin: Vector3 = model.player.target if model.player.moving else model.player.position
	var key := str([origin,model.enemy.target,hover,model.paused,target_mode,model.order,model.destination])
	if key == overlay_key: return
	_clear_cells()
	overlay_key = key
	if not model.active: return
	cell_overlay = Node3D.new()
	world.map_root.add_child(cell_overlay)
	# The board appears while issuing commands, keeping the moving field readable.
	if model.paused:
		for x in range(roundi(origin.x)-6,roundi(origin.x)+7):
			for z in range(roundi(origin.z)-6,roundi(origin.z)+7):
				var cell := Vector3(x,0,z)
				if not world._blocked(cell): _cell_outline(cell,Color(0.55,0.8,0.9,0.26),0.018)
		for direction in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
			var cell: Vector3 = model.enemy.target+direction
			if not world._blocked(cell): _cell_outline(cell,Color(1,0.48,0.25,0.85),0.04)
	var goal: Vector3 = hover if model.paused and target_mode == "move" else model.destination
	if model.order == "move" or (model.paused and target_mode == "move"):
		var route := _path(origin,goal)
		var valid: bool = not world._blocked(goal) and not route.is_empty() and goal.distance_to(model.enemy.target) > 0.8
		if valid:
			for cell: Vector3 in route: _cell_outline(cell,Color(0.35,0.95,0.8,0.85),0.045)
		_cell_outline(goal,Color("f6d687") if valid else Color("ef6565"),0.08)
	_cell_outline(origin,Color("8fcdf3"),0.045)

func _cell_outline(cell: Vector3, color: Color, width: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	for i in range(4):
		var edge := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.94,0.012,width) if i < 2 else Vector3(width,0.012,0.94)
		edge.mesh = box
		edge.material_override = material
		edge.position = cell+Vector3(0,0.085,(-0.47 if i == 0 else 0.47)) if i < 2 else cell+Vector3((-0.47 if i == 2 else 0.47),0.085,0)
		cell_overlay.add_child(edge)


func _window(parent: Control, offset: Vector2, dimensions: Vector2, preset: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.set_anchors_and_offsets_preset(preset)
	box.position = offset
	box.size = dimensions
	box.custom_minimum_size = dimensions
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08,0.12,0.16,0.94)
	style.border_color = Color("b4b5a3")
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel",style)
	parent.add_child(box)
	return box
