extends Node3D

var entries: Array
var index := 0
var shown: Node3D
var caption: Label
var camera: Camera3D

func _ready() -> void:
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/catalog.json"))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("b9c7db")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c4cee4")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_energy = 0.85
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position = Vector3(8,12,15)
	add_child(camera)
	camera.look_at(Vector3(0,1.5,0))
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24,24)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("dce3ec")
	floor_mesh.material_override = mat
	floor_mesh.position.y = -0.05
	add_child(floor_mesh)
	var ui := CanvasLayer.new()
	add_child(ui)
	caption = Label.new()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size",24)
	caption.add_theme_color_override("font_color",Color("172b3f"))
	ui.add_child(caption)
	_show_asset()

func _show_asset() -> void:
	if is_instance_valid(shown): shown.queue_free()
	shown = load(entries[index].scene).instantiate()
	add_child(shown)
	caption.text = "%02d / %02d  %s\n%s\n← → 선택 · 휠 확대/축소" % [index+1,entries.size(),entries[index].name,entries[index].id]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT: index = (index+1)%entries.size(); _show_asset()
		if event.keycode == KEY_LEFT: index = (index-1+entries.size())%entries.size(); _show_asset()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.size = maxf(2,camera.size-1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.size = minf(24,camera.size+1)
