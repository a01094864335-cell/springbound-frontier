extends Node3D
var entries: Array
var field: Node3D
var actor: CharacterBody3D
func _ready() -> void:
	entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/fields/catalog.json"))
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 46
	camera.position = Vector3(28,40,38)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-60,-25,0)
	light.light_energy = 1.5
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("26383f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b4c4ca")
	env.environment.ambient_light_energy = .6
	add_child(env)
	actor = CharacterBody3D.new()
	actor.name = "LayoutProbe"
	add_child(actor)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	capsule.height = 1.4
	shape.shape = capsule
	actor.add_child(shape)
	var mesh := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = .4
	capsule_mesh.height = 1.4
	mesh.mesh = capsule_mesh
	actor.add_child(mesh)
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := VBoxContainer.new()
	panel.position = Vector2(18,18)
	ui.add_child(panel)
	var label := Label.new()
	label.text = "Field layout blockouts (29) · Arrow keys: 4-direction probe · R: reset\nGeometry and navigation only; not final terrain art or character assets."
	panel.add_child(label)
	var select := OptionButton.new()
	for e in entries:
		select.add_item(e.id+" · "+e.name)
	select.item_selected.connect(show_field)
	panel.add_child(select)
	show_field(0)
func show_field(index: int) -> void:
	if is_instance_valid(field):
		field.free()
	field = (load(entries[index].path) as PackedScene).instantiate()
	add_child(field)
	reset_probe()
func reset_probe() -> void:
	actor.position = field.get_node("Entry").position + Vector3(0,.9,0)
	actor.velocity = Vector3.ZERO
func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	var direction := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT):
		direction.x = -1
	elif Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x = 1
	elif Input.is_physical_key_pressed(KEY_UP):
		direction.z = -1
	elif Input.is_physical_key_pressed(KEY_DOWN):
		direction.z = 1
	actor.velocity.x = direction.x*5
	actor.velocity.z = direction.z*5
	actor.velocity.y -= 20*delta
	actor.move_and_slide()
	if Input.is_physical_key_pressed(KEY_R):
		reset_probe()
