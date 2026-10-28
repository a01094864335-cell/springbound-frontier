extends "res://scripts/prologue.gd"

const OUT := "res://assets/environment/"
var catalog: Array = []

func _ready() -> void:
	# Reuse the game's material palette and primitive conventions; do not run gameplay.
	terrain_atlas = load("res://assets/winter-materials.png")
	_prepare_surface_materials()
	for i in range(terrain_materials.size()):
		var mat: StandardMaterial3D = terrain_materials[i]
		var img := mat.albedo_texture.get_image()
		var path := OUT + "textures/material_%d.png" % i
		img.save_png(path)
		# External resource paths are stable after an editor import.
		var tex := ImageTexture.create_from_image(img)
		ResourceSaver.save(tex, OUT + "materials/texture_%d.res" % i)
		tex.take_over_path(OUT + "materials/texture_%d.res" % i)
		mat.albedo_texture = tex
		ResourceSaver.save(mat, OUT + "materials/surface_%d.tres" % i)
		mat.take_over_path(OUT + "materials/surface_%d.tres" % i)
	_make_buildings()
	_make_landscape()
	_make_street()
	_make_furniture()
	_make_modules()
	var file := FileAccess.open(OUT + "catalog.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(catalog, "\t"))
	print("ENVIRONMENT_PACK: %d scenes created" % catalog.size())
	get_tree().quit()

func begin_asset(id: String) -> void:
	map_root = Node3D.new()
	map_root.name = id.to_pascal_case()
	add_child(map_root)
	obstacles.clear()
	occluders.clear()
	map_paths.clear()
	rng.seed = 7284

func finish_asset(id: String, title: String, category: String, maps: Array) -> void:
	# Actual Godot collision plus metadata for the current custom grid walker.
	var bounds: Array = []
	for rect in obstacles:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(maxf(rect.size.x, 0.05), 1.2, maxf(rect.size.y, 0.05))
		shape.shape = box
		body.position = Vector3(rect.get_center().x, 0.6, rect.get_center().y)
		body.add_child(shape)
		map_root.add_child(body)
		bounds.append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	map_root.set_meta("grid_obstacles", bounds)
	map_root.set_meta("display_name", title)
	map_root.set_meta("asset_id", id)
	_own(map_root, map_root)
	var packed := PackedScene.new()
	assert(packed.pack(map_root) == OK)
	var path := OUT + "scenes/" + id + ".tscn"
	assert(ResourceSaver.save(packed, path) == OK)
	catalog.append({"id":id,"name":title,"category":category,"scene":path,"maps":maps,"grid_obstacles":bounds,"origin":"ground center; front +Z","source":"procedural geometry with existing project winter materials"})
	map_root.queue_free()

func _own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_own(child, root)

func timber(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := _box(pos, size, Color("68513a"))
	_texture_surface(mesh, 3)
	return mesh

func stone(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := _box(pos, size, Color("87918d"))
	_texture_surface(mesh, 2)
	return mesh

func snow(pos: Vector3, size: Vector3) -> void:
	var mesh := _box(pos, size, Color("e1e8f4"))
	_texture_surface(mesh, 1)

func crate_at(pos: Vector3, size: Vector3) -> void:
	timber(pos + Vector3(0,size.y/2,0), size)
	for x in [-1,1]:
		timber(pos + Vector3(x*(size.x/2-0.08),size.y/2,size.z/2+0.04),Vector3(0.13,size.y,0.08))
	for y in [0.1,size.y-0.1]:
		timber(pos + Vector3(0,y,size.z/2+0.05),Vector3(size.x,0.13,0.1))
	var a := pos + Vector3(-size.x/2+0.1,0.12,size.z/2+0.11)
	var b := pos + Vector3(size.x/2-0.1,size.y-0.12,size.z/2+0.11)
	_beam(a,b,0.12)
	obstacles.append(Rect2(pos.x-size.x/2,pos.z-size.z/2,size.x,size.z))

func _make_buildings() -> void:
	for entry in [["herbalist_house","마르타의 약초사 집",6.0,5.0],["village_cottage","서리골 민가",5.5,4.5],["village_inn","서리골 여관",6.5,5.5],["village_store","서리골 잡화점",6.0,5.0],["border_office","돌샘 연락소",8.0,6.0],["mountain_cottage","돌샘 산촌 민가",5.0,5.0]]:
		var id: String = entry[0]
		begin_asset(id)
		_house(0,0,entry[2],entry[3],Color("657179"))
		# Threshold and a porch without enlarging the walker's footprint.
		stone(Vector3(0,0.14,float(entry[3])/2+0.4),Vector3(1.5,0.28,0.7))
		if id == "herbalist_house":
			for i in range(3):
				var herb := _cylinder(Vector3(-1.1+i*0.35,2.2,2.8),0.09,0.55,Color("6d8056"),0.17)
				herb.rotation.z = 0.12*(i-1)
		if id == "border_office":
			for x in [-3.1,3.1]:
				_box(Vector3(x,2.2,3.25),Vector3(0.6,1.3,0.06),Color("253f70"))
		if id == "village_inn":
			# Bed pictogram: no baked text or language-specific labels.
			var z := float(entry[3])/2+0.29
			_box(Vector3(2.3,2.3,z),Vector3(0.85,0.55,0.1),Color("3a332e"))
			_box(Vector3(2.3,2.28,z+0.08),Vector3(0.57,0.14,0.03),Color("ece4cd"))
			_box(Vector3(2.06,2.4,z+0.08),Vector3(0.08,0.23,0.03),Color("ece4cd"))
		finish_asset(id,entry[1],"buildings",["서리골" if id != "border_office" and id != "mountain_cottage" else "돌샘"])

func _make_landscape() -> void:
	# Keep the accepted hand-painted tree sprite and its exact foot anchoring.
	tree_texture = load("res://assets/snow-spruce.png")
	var img := tree_texture.get_image()
	if img.is_compressed(): img.decompress()
	tree_used = img.get_used_rect()
	for spec in [["snow_spruce_tall",1.0],["snow_spruce_small",0.7],["snow_spruce_wide",1.2]]:
		begin_asset(spec[0]); _tree(0,0,spec[1])
		finish_asset(spec[0],"눈 덮인 침엽수", "vegetation",["서리골","산길","돌샘"])
	for spec in [["snow_boulder",Vector3(1.6,1.5,1.6)],["snow_pebble",Vector3(0.4,0.35,0.4)],["cliff_rock",Vector3(1.6,2,1.4)]]:
		begin_asset(spec[0]); _rock(Vector3(0,0.15,0),spec[1])
		finish_asset(spec[0],"적설 바위", "landscape",["서리골","산길"])
	begin_asset("frozen_stream_segment")
	stone(Vector3(0,-0.1,0),Vector3(6.6,0.3,5))
	_box(Vector3(0,0.08,0),Vector3(6.0,0.05,5),Color("74aaa9"))
	for x in [-3.1,3.1]: snow(Vector3(x,0.2,0),Vector3(0.5,0.3,5))
	obstacles.append(Rect2(-3.3,-2.5,6.6,5))
	finish_asset("frozen_stream_segment","얼어붙은 계류 모듈","landscape",["산길"])
	begin_asset("snow_drift")
	_rock(Vector3(0,0.06,0),Vector3(1.0,0.35,0.7),false)
	for node in map_root.get_children():
		if node is MeshInstance3D: _texture_surface(node,1)
	finish_asset("snow_drift","길 가장자리 눈더미","landscape",["서리골","산길","돌샘"])
	begin_asset("herb_patch")
	for i in range(7):
		var blade := _cylinder(Vector3(sin(i*2.4)*0.3,0.16,cos(i*2.4)*0.3),0.04,0.32,Color("708452"),0.0)
		blade.rotation.z = sin(i)*0.3
	finish_asset("herb_patch","약초 군락","vegetation",["산길"])

func _make_street() -> void:
	for covered in [false,true]:
		var id := "covered_well" if covered else "village_well"
		begin_asset(id); _stone_well(Vector2.ZERO,covered)
		obstacles.append(Rect2(-1.4,-1.4,2.8,2.8) if covered else Rect2(-1,-1,2,2))
		finish_asset(id,"지붕 우물" if covered else "마을 우물","street",["돌샘" if covered else "서리골"])
	begin_asset("border_gate"); _border_gate(Vector2.ZERO)
	finish_asset("border_gate","북쪽 국경문","street",["서리골"])
	begin_asset("wood_fence"); _fence(Vector2(-1.5,0),Vector2(1.5,0))
	snow(Vector3(0,0.97,0),Vector3(3.1,0.06,0.18))
	finish_asset("wood_fence","3m 목책 모듈","street",["서리골","산길","돌샘"])
	begin_asset("lantern_post"); _lantern(0,0)
	finish_asset("lantern_post","따뜻한 가로등","street",["서리골","산길","돌샘"])
	begin_asset("notice_board")
	for x in [-0.6,0.6]: timber(Vector3(x,0.8,0),Vector3(0.12,1.6,0.12))
	timber(Vector3(0,1.3,0),Vector3(1.6,1.1,0.18))
	for i in range(3): _box(Vector3(-0.45+i*0.43,1.32,0.11),Vector3(0.34,0.65,0.02),Color("ded2b3"))
	snow(Vector3(0,1.9,0),Vector3(1.85,0.12,0.35))
	obstacles.append(Rect2(-0.8,-0.2,1.6,0.4))
	finish_asset("notice_board","마을 게시판","street",["서리골"])
	begin_asset("trail_sign")
	timber(Vector3(0,0.8,0),Vector3(0.15,1.6,0.15))
	timber(Vector3(0,1.55,0),Vector3(1.3,0.45,0.16))
	# Geometric arrow instead of generated lettering.
	_box(Vector3(0,1.55,0.1),Vector3(0.6,0.04,0.02),Color("e8dfbd"))
	for angle in [-0.65,0.65]:
		var line := _box(Vector3(0.24,1.55+sin(angle)*0.09,0.1),Vector3(0.24,0.04,0.02),Color("e8dfbd")); line.rotation.z=angle
	finish_asset("trail_sign","산길 방향 표지","street",["산길"])
	begin_asset("snow_barrel"); _barrel(0,0)
	finish_asset("snow_barrel","눈 덮인 나무통","supplies",["서리골","돌샘"])
	begin_asset("supply_crate"); crate_at(Vector3.ZERO,Vector3(1.5,0.9,1.1))
	finish_asset("supply_crate","보급 상자","supplies",["돌샘"])
	begin_asset("stacked_crates")
	crate_at(Vector3(-0.7,0,0),Vector3(1.2,0.8,1.0)); crate_at(Vector3(0.65,0,0),Vector3(1.2,1.1,1.0)); crate_at(Vector3(-0.6,0.8,0),Vector3(0.8,0.65,0.8))
	finish_asset("stacked_crates","적재한 보급품","supplies",["돌샘"])
	begin_asset("firewood_stack")
	for layer in range(3):
		for col in range(4-layer):
			var log_mesh := _cylinder(Vector3((col-(3-layer)/2.0)*0.36,0.18+layer*0.3,0),0.18,1.2,Color("745337"))
			log_mesh.rotation.x=PI/2; _texture_surface(log_mesh,3)
	obstacles.append(Rect2(-0.8,-0.7,1.6,1.4))
	finish_asset("firewood_stack","쌓아둔 장작","supplies",["서리골"])
	begin_asset("traveler_pack")
	_box(Vector3(0,0.24,0),Vector3(0.6,0.48,0.45),Color("7d6042"))
	for x in [-0.18,0.18]: timber(Vector3(x,0.26,0.24),Vector3(0.06,0.48,0.04))
	finish_asset("traveler_pack","레온 곁 여행 짐","supplies",["산길"])

func _make_furniture() -> void:
	begin_asset("wood_table")
	timber(Vector3(0,1,0),Vector3(3.2,0.25,1.9))
	for x in [-1.3,1.3]:
		for z in [-0.65,0.65]: timber(Vector3(x,0.5,z),Vector3(0.18,1,0.18))
	obstacles.append(Rect2(-1.6,-0.95,3.2,1.9))
	finish_asset("wood_table","마르타의 작업 탁자","interior",["집"])
	begin_asset("wood_chair")
	timber(Vector3(0,0.55,0),Vector3(0.8,0.12,0.8))
	for x in [-0.3,0.3]:
		for z in [-0.3,0.3]: timber(Vector3(x,0.28,z),Vector3(0.1,0.55,0.1))
	timber(Vector3(0,1,-0.35),Vector3(0.8,0.85,0.12))
	obstacles.append(Rect2(-0.4,-0.4,0.8,0.8))
	finish_asset("wood_chair","작업 의자","interior",["집"])
	begin_asset("herbalist_bed")
	timber(Vector3(0,0.6,0),Vector3(3,0.9,3.5))
	_box(Vector3(0,1.1,0.35),Vector3(2.8,0.25,2.3),Color("698a81"))
	_box(Vector3(0,1.16,-1.05),Vector3(2.3,0.22,0.65),Color("e2dac2"))
	timber(Vector3(0,1,-1.65),Vector3(3.1,1.4,0.15))
	obstacles.append(Rect2(-1.5,-1.75,3,3.5))
	finish_asset("herbalist_bed","에일의 침대","interior",["집"])
	begin_asset("medicine_shelf")
	for x in [-1.65,1.65]: timber(Vector3(x,1,0),Vector3(0.14,2,1.6))
	for y in [0.15,0.75,1.35,1.95]: timber(Vector3(0,y,0),Vector3(3.4,0.12,1.6))
	for row in range(3):
		for col in range(5): _cylinder(Vector3(-1.1+col*0.55,0.38+row*0.6,0.15),0.16,0.32,Color("6d8056") if col%2 else Color("ac986b"))
	obstacles.append(Rect2(-1.7,-0.8,3.4,1.6))
	finish_asset("medicine_shelf","약병 선반","interior",["집"])
	begin_asset("medicine_parcel")
	_box(Vector3(0,0.2,0),Vector3(0.65,0.4,0.5),Color("c2b590"))
	for x in [-0.12,0.12]: timber(Vector3(x,0.41,0),Vector3(0.035,0.025,0.51))
	finish_asset("medicine_parcel","돌샘에 전할 약 꾸러미","interior",["집"])
	begin_asset("medicine_stand"); crate_at(Vector3.ZERO,Vector3(1.2,1.1,1))
	finish_asset("medicine_stand","약 꾸러미 받침 상자","interior",["집"])
	begin_asset("mortar_and_pestle")
	_cylinder(Vector3(0,0.14,0),0.28,0.28,Color("b8af8c"),0.35)
	var pestle := _cylinder(Vector3(0.08,0.35,0),0.05,0.5,Color("968671")); pestle.rotation.z=-0.4
	finish_asset("mortar_and_pestle","약초 절구","interior",["집"])
	begin_asset("medicine_bottle")
	_cylinder(Vector3(0,0.18,0),0.13,0.3,Color("638b69"))
	_cylinder(Vector3(0,0.37,0),0.065,0.12,Color("638b69"))
	_cylinder(Vector3(0,0.45,0),0.07,0.05,Color("9d8053"))
	finish_asset("medicine_bottle","약병","interior",["집"])
	begin_asset("woven_rug")
	_box(Vector3(0,0.025,0),Vector3(5.5,0.05,4.5),Color("6c8072"))
	for z in [-2.1,2.1]: _box(Vector3(0,0.055,z),Vector3(5.2,0.01,0.13),Color("b6a477"))
	finish_asset("woven_rug","작업실 깔개","interior",["집"])
	begin_asset("interior_window")
	_box(Vector3(0,0.85,0),Vector3(2,1.7,0.12),Color("a8c9c3"))
	for x in [-1,0,1]: timber(Vector3(x,0.85,0.1),Vector3(0.12,1.8,0.1))
	for y in [0,0.85,1.7]: timber(Vector3(0,y,0.1),Vector3(2.1,0.12,0.1))
	finish_asset("interior_window","작업실 창문","interior",["집"])

func _make_modules() -> void:
	for item in [["cobblestone_tile","돌길 바닥",0],["snow_tile","눈 바닥",1],["stone_wall_panel","돌벽 모듈",2],["wood_floor_tile","목재 바닥",3],["slate_roof_panel","슬레이트 지붕면",4],["plaster_wall_panel","회벽 모듈",5]]:
		begin_asset(item[0])
		var wall: bool = item[0].contains("wall")
		var size := Vector3(3,3,0.2) if wall else Vector3(3,0.05,3)
		var mesh := _box(Vector3(0,size.y/2,0),size,Color.WHITE)
		_texture_surface(mesh,item[2])
		if wall: obstacles.append(Rect2(-1.5,-0.1,3,0.2))
		finish_asset(item[0],item[1],"modules",["집","서리골","산길","돌샘"])
