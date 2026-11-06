extends Node3D
const Bank=preload("res://assets/production/audio/audio_bank.gd")
var entries: Array=[]
var index: int=0
var mode: int=0
var current: Node3D
var camera: Camera3D
var audio: AudioStreamPlayer
var selector: OptionButton
var caption: Label
func _ready() -> void:
	camera=Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.current=true
	var sun: DirectionalLight3D=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-25,0)
	sun.light_energy=1.2
	sun.shadow_enabled=true
	add_child(sun)
	var env: WorldEnvironment=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d1dbe2")
	env.environment.ambient_light_energy=.5
	add_child(env)
	audio=AudioStreamPlayer.new()
	audio.volume_db=-15
	add_child(audio)
	var canvas: CanvasLayer=CanvasLayer.new()
	add_child(canvas)
	var panel: PanelContainer=PanelContainer.new()
	panel.position=Vector2(18,18)
	panel.custom_minimum_size=Vector2(680,120)
	canvas.add_child(panel)
	var column: VBoxContainer=VBoxContainer.new()
	panel.add_child(column)
	var title: Label=Label.new()
	title.text="Springbound Frontier - 151 native first-pass assets (not final approval)"
	column.add_child(title)
	var row: HBoxContainer=HBoxContainer.new()
	column.add_child(row)
	var modes: OptionButton=OptionButton.new()
	for text in ["Rooms (22)","Furniture (20)","VFX (29)","Audio (80)"]:modes.add_item(text)
	modes.item_selected.connect(set_mode)
	row.add_child(modes)
	for text in ["Previous","Next","Play / Replay","Stop"]:
		var button: Button=Button.new()
		button.text=text
		if text=="Previous":button.pressed.connect(func():show_entry(wrapi(index-1,0,entries.size())))
		elif text=="Next":button.pressed.connect(func():show_entry(wrapi(index+1,0,entries.size())))
		elif text=="Play / Replay":button.pressed.connect(replay)
		else:button.pressed.connect(stop)
		row.add_child(button)
	selector=OptionButton.new()
	selector.item_selected.connect(show_entry)
	column.add_child(selector)
	caption=Label.new()
	column.add_child(caption)
	set_mode(0)
func set_mode(value: int) -> void:
	mode=value
	var data: Variant
	if mode<2:
		data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/interiors/catalog.json"))
		entries=data.rooms if mode==0 else data.furniture
	elif mode==2:entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/vfx/catalog.json"))
	else:entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/audio/catalog.json"))
	selector.clear()
	for entry in entries:selector.add_item(entry.id+"  "+str(entry.get("name","")))
	show_entry(0)
func show_entry(value: int) -> void:
	index=value
	selector.select(index)
	audio.stop()
	if is_instance_valid(current):current.free()
	caption.text=str(index+1)+" / "+str(entries.size())+"   "+entries[index].id
	if mode==3:
		caption.text+=" - press Play to listen; listening review is pending"
		return
	current=(load(entries[index].path) as PackedScene).instantiate() as Node3D
	if mode==2:current.autoplay=false
	add_child(current)
	if mode==0:
		camera.size=18
		camera.position=Vector3(13,18,22)
		camera.look_at(Vector3(0,.5,0))
	elif mode==1:
		camera.size=4.5
		camera.position=Vector3(4,3,5)
		camera.look_at(Vector3(0,.8,0))
	else:
		var quad: QuadMesh=current.get_node("Visual").mesh as QuadMesh
		camera.size=maxf(4,maxf(quad.size.x,quad.size.y)*1.6)
		camera.position=Vector3(0,quad.size.y/2,20)
		camera.look_at(Vector3(0,quad.size.y/2,0))
		current.seek(.45)
func replay() -> void:
	if mode==3:
		audio.stream=Bank.stream(entries[index].id)
		audio.play()
	elif mode==2 and is_instance_valid(current):current.play()
func stop() -> void:
	audio.stop()
	if mode==2 and is_instance_valid(current):current.stop()
