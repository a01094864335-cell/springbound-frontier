extends SceneTree
var world: Node3D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	world=Node3D.new()
	root.add_child(world)
	var camera: Camera3D=Camera3D.new()
	world.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=18
	camera.position=Vector3(13,18,22)
	camera.look_at(Vector3(0,0.5,0))
	camera.current=true
	var light: DirectionalLight3D=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=1.25
	light.shadow_enabled=true
	world.add_child(light)
	var fill: DirectionalLight3D=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-35,145,0)
	fill.light_energy=.45
	world.add_child(fill)
	var env: WorldEnvironment=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("202f37")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d1dbe2")
	env.environment.ambient_light_energy=.5
	world.add_child(env)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/interiors/catalog.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/asset_production/renders"))
	for entry in data.rooms:
		var room: Node3D=(load(entry.path) as PackedScene).instantiate() as Node3D
		world.add_child(room)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image: Image=root.get_texture().get_image()
		var result: int=image.save_png("res://tests/asset_production/renders/"+entry.id+".png")
		print("RENDER ",entry.id," ",result)
		room.queue_free()
		await process_frame
	quit()
