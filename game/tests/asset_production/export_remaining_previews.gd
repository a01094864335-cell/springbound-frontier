extends SceneTree
var output: Array=[]
func _initialize() -> void:call_deferred("run")
func geometry(node: Node3D) -> Dictionary:
	var triangles: Array=[]
	var sprites: Array=[]
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null:continue
		var points: PackedVector3Array=mesh.mesh.get_faces()
		var color: Color=Color("83918a")
		if mesh.material_override is StandardMaterial3D:color=mesh.material_override.albedo_color
		for i in range(0,points.size(),3):
			var a: Vector3=mesh.global_transform*points[i]
			var b: Vector3=mesh.global_transform*points[i+1]
			var c: Vector3=mesh.global_transform*points[i+2]
			var normal: Vector3=(b-a).cross(c-a).normalized()
			var shade: float=.5+.5*maxf(0,normal.dot(Vector3(-.3,.8,.5).normalized()))
			triangles.append([[a.x,a.y,a.z],[b.x,b.y,b.z],[c.x,c.y,c.z],[color.r*shade,color.g*shade,color.b*shade]])
	for sprite in node.find_children("*","AnimatedSprite3D",true,false):
		var tex: AtlasTexture=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		sprites.append({"id":String(sprite.animation),"position":[sprite.global_position.x,sprite.global_position.y,sprite.global_position.z],"rect":[tex.region.position.x,tex.region.position.y,tex.region.size.x,tex.region.size.y]})
	return {"triangles":triangles,"sprites":sprites}
func run() -> void:
	root.size=Vector2i(1000,800)
	for group in ["props","ui","events","world_states"]:
		var entries: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/"+group+"/catalog.json"))
		for e in entries:
			var scene: Node=(load(e.path) as PackedScene).instantiate()
			root.add_child(scene)
			await process_frame
			await process_frame
			var item: Dictionary={"id":e.id,"name":e.name,"group":group}
			if group=="ui":
				var controls: Array=[]
				for c in scene.find_children("*","Control",true,false):
					if c.has_signal("destination_selected"):
						var rect: Rect2=c.get_global_rect()
						var points: Array=[]
						for index in range(c.destinations.size()):
							var point: Vector2=c.point(index)
							points.append([point.x+rect.position.x,point.y+rect.position.y])
						controls.append({"kind":"MapView","points":points,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
					if c is Label or c is Button or c is ProgressBar or c is HSlider or c is ColorRect or c is TextureRect:
						var rect: Rect2=c.get_global_rect()
						var value: Dictionary={"kind":c.get_class(),"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
						if c is Label or c is Button:value.text=c.text
						if c is Range:value.value=c.value;value.max=c.max_value
						if c is TextureRect and c.texture!=null:
							if c.texture is AtlasTexture:
								value.image=c.texture.atlas.resource_path.replace("res://","game/")
								var region: Rect2=c.texture.region
								value.source_rect=[region.position.x,region.position.y,region.size.x,region.size.y]
							else:value.image=c.texture.resource_path.replace("res://","game/")
						if c is ColorRect:value.color=[c.color.r,c.color.g,c.color.b,c.modulate.a]
						controls.append(value)
				item.controls=controls
				item.width=scene.size.x
				item.height=scene.size.y
			elif group=="events":
				var frames: Array=[]
				for i in range(9):
					scene.seek(float(e.duration)*i/8)
					frames.append(geometry(scene))
				item.frames=frames
			else:item.geometry=geometry(scene)
			output.append(item)
			scene.free()
	var f:=FileAccess.open("res://tests/asset_production/remaining-previews.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(output))
	print("EXPORTED_PREVIEWS ",output.size())
	quit()
