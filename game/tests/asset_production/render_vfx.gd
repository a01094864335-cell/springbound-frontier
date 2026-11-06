extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1500,900)
	var world: Node3D=Node3D.new()
	root.add_child(world)
	var camera: Camera3D=Camera3D.new()
	world.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=20.0
	camera.position=Vector3(0,0,20)
	camera.current=true
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/vfx/catalog.json"))
	for i in range(catalog.size()):
		var e: Dictionary=catalog[i]
		var effect: Node3D=(load(e.path) as PackedScene).instantiate() as Node3D
		effect.autoplay=false
		world.add_child(effect)
		var quad: QuadMesh=effect.get_node("Visual").mesh as QuadMesh
		var factor: float=2.3/maxf(quad.size.x,quad.size.y)
		effect.scale=Vector3.ONE*factor
		effect.position=Vector3((i%6)*3.0-7.5,5.3-floori(float(i)/6)*2.6-quad.size.y*.5*factor,0)
		effect.seek(.45)
		var label: Label3D=Label3D.new()
		label.text=e.id
		label.font_size=28
		label.pixel_size=.008
		label.position=Vector3((i%6)*3.0-7.5,4.1-floori(float(i)/6)*2.6,0)
		world.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/asset_production/vfx-contact-sheet.png")
	print("VFX_RENDER_DONE")
	quit()
