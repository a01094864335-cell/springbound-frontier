extends Node3D
const Bank=preload("res://assets/production/motions/motion_bank.gd")
var rows: Array=[]
var selected: Array=[]
var group: String="motions"
var current: Node
var selector: OptionButton
var search: LineEdit
var caption: Label
var ui: CanvasLayer
var camera: Camera3D
func _ready() -> void:
	camera=Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.current=true
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=1.3
	add_child(light)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("bbc8ca")
	env.environment.ambient_light_energy=.6
	add_child(env)
	ui=CanvasLayer.new()
	add_child(ui)
	var box:=VBoxContainer.new()
	box.position=Vector2(18,18)
	ui.add_child(box)
	var label:=Label.new()
	label.text="전체 잔여 애셋 · 1차 제작 검토 (게임 플레이 미연결)"
	box.add_child(label)
	var modes:=OptionButton.new()
	for name in ["motions","props","ui","events","world_states","icons","fields"]:modes.add_item(name)
	modes.item_selected.connect(func(index):set_group(modes.get_item_text(index)))
	box.add_child(modes)
	search=LineEdit.new()
	search.placeholder_text="이름 또는 ID 검색"
	search.custom_minimum_size.x=680
	search.text_changed.connect(func(_text):filter_rows())
	box.add_child(search)
	selector=OptionButton.new()
	selector.item_selected.connect(show_entry)
	box.add_child(selector)
	var replay:=Button.new()
	replay.text="다시 재생"
	replay.pressed.connect(func():
		if group=="events" and is_instance_valid(current):current.play()
		elif group=="motions" and is_instance_valid(current):current.frame=0;current.play())
	box.add_child(replay)
	caption=Label.new()
	box.add_child(caption)
	set_group("motions")
func set_group(value: String) -> void:
	group=value
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/"+group+"/catalog.json"))
	rows=data.entries if group=="motions" else data
	search.clear()
	filter_rows()
func filter_rows() -> void:
	selected=[]
	selector.clear()
	for entry in rows:
		if search.text.is_empty() or search.text.to_lower() in (str(entry.id)+" "+str(entry.name)).to_lower():
			selected.append(entry)
			selector.add_item(str(entry.id)+" · "+str(entry.name))
	if not selected.is_empty():show_entry(0)
	else:
		if is_instance_valid(current):current.free()
		caption.text="검색 결과 없음"
func show_entry(index: int) -> void:
	if index<0 or index>=selected.size():return
	selector.select(index)
	if is_instance_valid(current):current.free()
	var entry: Dictionary=selected[index]
	caption.text=entry.name+" · 최종 미술·게임 통합 검수는 별도"
	if group=="motions":
		current=Bank.sprite(entry.id)
		add_child(current)
		current.play(entry.id)
	elif group=="icons":
		var rect:=TextureRect.new()
		rect.texture=load(entry.path)
		rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.position=Vector2(320,280)
		rect.size=Vector2(300,300)
		ui.add_child(rect)
		current=rect
	else:
		current=(load(entry.path) as PackedScene).instantiate()
		if group=="ui":
			ui.add_child(current)
			current.position=Vector2(180,280)
		else:
			add_child(current)
			if group=="events":current.play()
	var wide: bool=group in ["fields","world_states"]
	camera.size=48 if wide else 10
	camera.position=Vector3(25,35,32) if wide else Vector3(7,8,11)
	camera.look_at(Vector3(0,0 if wide else 1,0))
