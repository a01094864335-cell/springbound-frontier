extends Node3D

const MapView = preload("res://scripts/map_view.gd")
const SAVE_PATH := "user://prologue_save.json"
const NAMES := ["마르타의 집", "서리골", "고요한 산길", "돌샘 연락소"]
const CHAPTERS := ["01 / 집 안의 아침", "02 / 봄을 기다리는 마을", "03 / 눈 아래의 길", "04 / 국경의 작은 불빛"]
const MAP_SIZES := [Vector2(18, 16), Vector2(40, 38), Vector2(34, 54), Vector2(36, 34)]
const HERO_SPEED := 5.2

var map_root: Node3D
var hero: Node3D
var hero_sprite: Sprite3D
var camera: Camera3D
var sun: DirectionalLight3D
var atmosphere: WorldEnvironment
var canvas: CanvasLayer
var ui_root: Control
var hud: Control
var title_screen: Control
var pause_screen: Control
var dialog_panel: PanelContainer
var speaker_label: Label
var dialog_label: Label
var portrait: TextureRect
var prompt_label: Label
var location_label: Label
var chapter_label: Label
var objective_label: Label
var toast_label: Label
var minimap: Control
var fade: ColorRect
var map_size := Vector2(18, 16)
var map_paths: Array[Rect2] = []
var obstacles: Array[Rect2] = []
var interactions: Array[Dictionary] = []
var occluders: Array[Dictionary] = []
var particles: Array[Node3D] = []
var map_id := 0
var has_medicine := false
var met_leon := false
var arrived := false
var started := false
var paused := false
var transitioning := false
var dialog_lines: Array = []
var dialog_action: Callable
var current_interaction: Dictionary = {}
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var step_clock := 0.0
var facing := 0
var walk_target := Vector3.ZERO
var has_walk_target := false
var zoom := 18.0
var ui_scale := 1.0
var body_font: SystemFont
var title_font: SystemFont
var sprite_atlas: Texture2D
var material_cache := {}
var qa_mode := false
var navigation := AStarGrid2D.new()
var route: Array[Vector3] = []
var rebind_action := ""
var rebind_buttons := {}
var bind_help: Label
var binding_panel: PanelContainer

func _ready() -> void:
	qa_mode = "--qa" in OS.get_cmdline_user_args()
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Apple SD Gothic Neo", "Malgun Gothic", "Noto Sans CJK KR", "sans-serif"])
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "serif"])
	if ResourceLoader.exists("res://assets/prologue-atlas.png"):
		sprite_atlas = load("res://assets/prologue-atlas.png")
	_setup_world()
	_setup_ui()
	_load_map(1, Vector3(0, 0, 9))
	hud.hide()
	title_screen.show()
	if qa_mode:
		call_deferred("_run_qa")
	elif "--capture" in OS.get_cmdline_user_args():
		call_deferred("_run_capture")

func _setup_world() -> void:
	atmosphere = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("99b8bd")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b6cdcc")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	atmosphere.environment = environment
	add_child(atmosphere)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("eff6ff")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.far = 150
	add_child(camera)
	hero = _actor(0)
	add_child(hero)
	hero_sprite = hero.get_node("Sprite") as Sprite3D

func _material(color: Color, translucent := false) -> StandardMaterial3D:
	var key := str(color) + str(translucent)
	if material_cache.has(key):
		return material_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	if translucent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_cache[key] = mat
	return mat

func _box(pos: Vector3, dimensions: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	mesh.mesh = geometry
	mesh.material_override = _material(color)
	mesh.position = pos
	map_root.add_child(mesh)
	if solid:
		obstacles.append(Rect2(Vector2(pos.x - dimensions.x / 2, pos.z - dimensions.z / 2), Vector2(dimensions.x, dimensions.z)))
	return mesh

func _cylinder(pos: Vector3, radius: float, height: float, color: Color, top_radius: float = -1) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var geometry := CylinderMesh.new()
	geometry.bottom_radius = radius
	geometry.top_radius = radius if top_radius < 0 else top_radius
	geometry.height = height
	geometry.radial_segments = 8
	mesh.mesh = geometry
	mesh.position = pos
	mesh.material_override = _material(color)
	map_root.add_child(mesh)
	return mesh

func _rock(pos: Vector3, scale_value: Vector3, snow := true) -> void:
	var rock := MeshInstance3D.new()
	var geometry := SphereMesh.new()
	geometry.radial_segments = 7
	geometry.rings = 3
	rock.mesh = geometry
	rock.position = pos
	rock.scale = scale_value
	rock.material_override = _material(Color("637977"))
	map_root.add_child(rock)
	if scale_value.x > 1.0:
		obstacles.append(Rect2(Vector2(pos.x-scale_value.x*0.4,pos.z-scale_value.z*0.4),Vector2(scale_value.x*0.8,scale_value.z*0.8)))
	if snow:
		_cylinder(pos + Vector3(0, scale_value.y * 0.35, 0), scale_value.x * 0.44, 0.12, Color("dce9de"))

func _tree(x: float, z: float, tree_scale := 1.0) -> void:
	var base := Vector3(x, 0, z)
	_cylinder(base + Vector3(0, 1.2 * tree_scale, 0), 0.19 * tree_scale, 2.4 * tree_scale, Color("5d5141"))
	var crown: Array[MeshInstance3D] = []
	for i in range(3):
		var h := (1.9 + i * 1.05) * tree_scale
		var radius := (1.5 - i * 0.31) * tree_scale
		crown.append(_cylinder(base + Vector3(0, h, 0), radius, 2.35 * tree_scale, Color("244f49"), 0))
		crown.append(_cylinder(base + Vector3(0, h + 0.42 * tree_scale, 0), radius * 0.78, 1.65 * tree_scale, Color("dbe7dc"), 0))
	obstacles.append(Rect2(Vector2(x - 0.42, z - 0.42), Vector2(0.84, 0.84)))
	occluders.append({"pos": Vector2(x, z), "width": 1.7 * tree_scale, "meshes": crown})

func _roof(center: Vector3, width: float, depth: float, height: float, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(-width/2,0,-depth/2),Vector3(width/2,0,-depth/2),Vector3(0,height,-depth/2),
		Vector3(-width/2,0,depth/2),Vector3(0,height,depth/2),Vector3(width/2,0,depth/2),
		Vector3(-width/2,0,-depth/2),Vector3(0,height,-depth/2),Vector3(0,height,depth/2),
		Vector3(-width/2,0,-depth/2),Vector3(0,height,depth/2),Vector3(-width/2,0,depth/2),
		Vector3(width/2,0,-depth/2),Vector3(width/2,0,depth/2),Vector3(0,height,depth/2),
		Vector3(width/2,0,-depth/2),Vector3(0,height,depth/2),Vector3(0,height,-depth/2)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		st.add_vertex(vertex)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.position = center
	var mat := _material(color).duplicate() as StandardMaterial3D
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	map_root.add_child(mesh)
	return mesh

func _house(x: float, z: float, width: float, depth: float, roof_color: Color) -> void:
	var walls := _box(Vector3(x, 1.55, z), Vector3(width, 3.1, depth), Color("d8d0b5"), true)
	_box(Vector3(x, 0.25, z), Vector3(width + 0.25, 0.5, depth + 0.25), Color("7c8274"))
	var roof := _roof(Vector3(x, 3.1, z), width + 1.0, depth + 0.9, 2.15, roof_color)
	var snow := _roof(Vector3(x - 0.06, 3.24, z), width + 1.0, depth + 0.95, 2.15, Color("e1ebe0"))
	for offset in [-width * 0.32, width * 0.32]:
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.04), Vector3(0.85, 0.95, 0.12), Color("6c5744"))
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.11), Vector3(0.63, 0.73, 0.04), Color("e6c888"))
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.15), Vector3(0.06, 0.75, 0.04), Color("6c5744"))
	_box(Vector3(x, 1.0, z + depth/2 + 0.1), Vector3(1.05, 2, 0.18), Color("655744"))
	_box(Vector3(x + width*0.25, 4.45, z - 0.9), Vector3(0.65, 1.6, 0.7), Color("9c9985"))
	for offset in [-width/2 + 0.12, width/2 - 0.12]:
		_box(Vector3(x + offset, 1.5, z + depth/2 + 0.08), Vector3(0.15, 3.1, 0.15), Color("6c6754"))
	occluders.append({"pos": Vector2(x,z), "width": width/2 + 0.6, "meshes": [walls,roof,snow]})

func _fence(start: Vector2, end: Vector2) -> void:
	var length_value := start.distance_to(end)
	var count := int(length_value / 1.5) + 1
	for i in range(count + 1):
		var p := start.lerp(end, float(i) / count)
		_box(Vector3(p.x,0.65,p.y),Vector3(0.17,1.3,0.17),Color("777461"))
	var midpoint := (start + end) / 2.0
	var bar := _box(Vector3(midpoint.x,0.85,midpoint.y),Vector3(length_value,0.13,0.12),Color("92907b"))
	bar.rotation.y = -atan2(end.y-start.y,end.x-start.x)
	if abs(end.x-start.x) > abs(end.y-start.y):
		obstacles.append(Rect2(Vector2(minf(start.x,end.x),start.y-0.1),Vector2(length_value,0.2)))
	else:
		obstacles.append(Rect2(Vector2(start.x-0.1,minf(start.y,end.y)),Vector2(0.2,length_value)))

func _path(rect: Rect2, color := Color("a1ab96")) -> void:
	map_paths.append(rect)
	_box(Vector3(rect.get_center().x, 0.035, rect.get_center().y),Vector3(rect.size.x,0.05,rect.size.y),color)
	for i in range(int(rect.get_area() / 1.6)):
		var p := Vector3(rng.randf_range(rect.position.x,rect.end.x),0.07,rng.randf_range(rect.position.y,rect.end.y))
		var stone := _box(p,Vector3(rng.randf_range(0.15,0.45),0.03,rng.randf_range(0.1,0.3)),color.darkened(0.10))
		stone.rotation.y = rng.randf_range(-1,1)

func _lantern(x: float, z: float) -> void:
	_cylinder(Vector3(x,1.25,z),0.08,2.5,Color("4b5b52"))
	_box(Vector3(x,2.5,z),Vector3(0.38,0.5,0.38),Color("e3c483"))
	_box(Vector3(x,2.8,z),Vector3(0.5,0.12,0.5),Color("4b5b52"))
	var light := OmniLight3D.new()
	light.position = Vector3(x,2.5,z)
	light.light_color = Color("ffd699")
	light.light_energy = 0.8
	light.omni_range = 5.0
	map_root.add_child(light)

func _marker(pos: Vector3, text: String, color := Color("eee1b3")) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = body_font
	label.font_size = 38
	label.pixel_size = 0.012
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_size = 8
	label.no_depth_test = true
	map_root.add_child(label)

func _actor(row: int) -> Node3D:
	var actor := Node3D.new()
	var sprite := Sprite3D.new()
	sprite.name = "Sprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.position.y = 1.12
	if sprite_atlas:
		sprite.texture = sprite_atlas
		sprite.hframes = 3
		sprite.vframes = 3
		sprite.frame = row * 3
		sprite.pixel_size = 2.5 / (sprite_atlas.get_height() / 3.0)
	actor.add_child(sprite)
	var shadow := MeshInstance3D.new()
	var circle := CylinderMesh.new()
	circle.top_radius = 0.36
	circle.bottom_radius = 0.36
	circle.height = 0.012
	shadow.mesh = circle
	shadow.position.y = 0.08
	shadow.material_override = _material(Color(0.1,0.19,0.17,0.2),true)
	actor.add_child(shadow)
	return actor

func _npc(row: int, pos: Vector3, npc_name: String) -> void:
	var actor := _actor(row)
	actor.position = pos
	map_root.add_child(actor)
	_marker(pos + Vector3(0,2.65,0),npc_name)
	obstacles.append(Rect2(Vector2(pos.x-0.35,pos.z-0.35),Vector2(0.7,0.7)))

func _interact(pos: Vector2, title: String, kind: String, data: Dictionary = {}) -> void:
	var point := {"pos":pos,"title":title,"kind":kind}
	point.merge(data)
	interactions.append(point)
	if kind == "exit":
		_marker(Vector3(pos.x,1.0,pos.y),"◇  " + title,Color("e8ca8e"))

func _load_map(index: int, spawn: Vector3) -> void:
	if map_root:
		remove_child(map_root)
		map_root.queue_free()
	map_root = Node3D.new()
	map_root.name = "Map"
	add_child(map_root)
	map_id = index
	map_size = MAP_SIZES[index]
	map_paths.clear()
	obstacles.clear()
	interactions.clear()
	occluders.clear()
	particles.clear()
	current_interaction = {}
	has_walk_target = false
	route.clear()
	rng.seed = 370 + index
	var ground_color := Color("aebfbb") if index != 0 else Color("947e5b")
	_box(Vector3(0,-0.45,0),Vector3(map_size.x if index == 0 else map_size.x+40,0.9,map_size.y if index == 0 else map_size.y+40),ground_color)
	_box(Vector3(0,-1.1,0),Vector3(map_size.x+0.2,0.7,map_size.y+0.2),Color("536d64"))
	match index:
		0: _build_home()
		1: _build_village()
		2: _build_trail()
		3: _build_well()
	_build_navigation()
	hero.position = spawn
	camera.size = zoom
	_update_camera(1.0, true)
	_update_quest()
	location_label.text = NAMES[index]
	chapter_label.text = CHAPTERS[index]
	atmosphere.environment.background_color = Color("d3cdb5") if index == 0 else Color("9fb9ba")
	sun.light_energy = 0.42 if index == 0 else 0.52
	if index != 0:
		_add_ground_details()
		_make_snow()

func _build_home() -> void:
	for x in range(-8,9):
		_box(Vector3(x,0.012,0),Vector3(0.035,0.02,16),Color("776748"))
	_box(Vector3(0,1.7,-7.5),Vector3(18,3.4,0.5),Color("b5aa89"),true)
	_box(Vector3(-8.6,1.2,0),Vector3(0.45,2.4,16),Color("b5aa89"),true)
	_box(Vector3(8.6,1.2,0),Vector3(0.45,2.4,16),Color("b5aa89"),true)
	for x in [-7.0,0.0,7.0]:
		_box(Vector3(x,1.65,-7.16),Vector3(0.22,3.3,0.2),Color("635e46"))
	_box(Vector3(0,0.08,0.3),Vector3(5.5,0.05,4.5),Color("6c8072"))
	_box(Vector3(0,1.0,0),Vector3(3.2,0.25,1.9),Color("6c5640"),true)
	for x in [-1.3,1.3]:
		for z in [-0.65,0.65]:
			_box(Vector3(x,0.5,z),Vector3(0.18,1.0,0.18),Color("65533d"))
	_cylinder(Vector3(0.6,1.25,0.1),0.28,0.25,Color("b8af8c"))
	_cylinder(Vector3(-0.6,1.3,-0.2),0.12,0.35,Color("b79d5c"))
	_box(Vector3(-5.6,0.6,-4.8),Vector3(3,0.9,3.5),Color("655741"),true)
	_box(Vector3(-5.6,1.1,-4.4),Vector3(2.8,0.25,2.3),Color("698a81"))
	_box(Vector3(-5.6,1.16,-5.8),Vector3(2.3,0.22,0.65),Color("e2dac2"))
	_box(Vector3(5.7,1.0,-5.5),Vector3(3.4,2.0,1.6),Color("6b5e44"),true)
	for i in range(5):
		_cylinder(Vector3(4.5+i*0.55,2.18,-5.4),0.17,0.35,Color("638b69"))
		for j in range(3):
			_box(Vector3(4.4+i*0.57,0.5+j*0.5,-4.65),Vector3(0.32,0.35,0.25),Color("b69c70"))
	_box(Vector3(4.0,0.55,3.6),Vector3(1.2,1.1,1),Color("6d6650"),true)
	_marker(Vector3(4,1.9,3.6),"◇  돌샘에 전할 약")
	_interact(Vector2(4,3.6),"약 꾸러미 챙기기","medicine")
	_npc(2,Vector3(3,0,-1.5),"마르타")
	_interact(Vector2(3,-1.5),"마르타와 대화","marta")
	_box(Vector3(-2.5,1.7,-7.2),Vector3(2,1.7,0.12),Color("a8c9c3"))
	_box(Vector3(-2.5,1.7,-7.05),Vector3(0.12,1.8,0.1),Color("655c44"))
	_box(Vector3(-2.5,1.7,-7.05),Vector3(2.1,0.12,0.1),Color("655c44"))
	_interact(Vector2(0,6.7),"서리골로","exit",{"map":1,"spawn":Vector3(-7,0,7),"requires_medicine":true})
	_path(Rect2(-1.4,4.8,2.8,3.0),Color("b3a17b"))

func _build_village() -> void:
	_path(Rect2(-2.6,-17,5.2,35))
	_path(Rect2(-16,4,32,4.5))
	_path(Rect2(-10,0,4,7))
	_house(-8,-2,6,5,Color("6d7f75"))
	_house(9,-8,6.5,5.5,Color("6c7c7c"))
	_house(-10,-12,5.5,4.5,Color("7d7568"))
	_house(10,9,6,5,Color("707f6a"))
	_cylinder(Vector3(0,0.48,6.2),1.0,0.95,Color("9ba695"))
	_cylinder(Vector3(0,1.0,6.2),0.74,0.1,Color("426d6c"))
	obstacles.append(Rect2(-1,5.2,2,2))
	_box(Vector3(0,2,6.2),Vector3(0.14,2.1,0.14),Color("5d6c56"))
	_lantern(-3.8,8.8)
	_lantern(3.6,-9)
	_fence(Vector2(-17,10),Vector2(-5,10))
	_fence(Vector2(5,-17),Vector2(16,-17))
	for p in [Vector2(-17,-15),Vector2(-17,-7),Vector2(-17,1),Vector2(-16,15),Vector2(17,15),Vector2(17,-2),Vector2(17,-13),Vector2(6,17),Vector2(-7,17)]:
		_tree(p.x,p.y,rng.randf_range(0.8,1.15))
	for i in range(35):
		var x := rng.randf_range(-18,18)
		var z := rng.randf_range(-17,17)
		if abs(x) > 3 and not _blocked(Vector3(x,0,z),0.6):
			_rock(Vector3(x,0.1,z),Vector3(0.4,0.35,0.4))
	_interact(Vector2(-8,1.7),"マ르타의 집으로".replace("マ","마"),"exit",{"map":0,"spawn":Vector3(0,0,5)})
	_interact(Vector2(0,-16.4),"산길 · 돌샘 방면","exit",{"map":2,"spawn":Vector3(0,0,23),"requires_medicine":true})
	_marker(Vector3(0,2.0,-13),"돌샘  ↑")
	_interact(Vector2(4,5),"마을 게시판 읽기","notice")
	_box(Vector3(4,1.15,5),Vector3(1.6,1.4,0.2),Color("6b6650"),true)
	_box(Vector3(4,1.2,5.13),Vector3(1.3,1.05,0.04),Color("d7cfab"))

func _build_trail() -> void:
	_path(Rect2(-2.2,10,4.4,16))
	_path(Rect2(-2.2,7,12.2,4.4))
	_path(Rect2(6,-8,4,19))
	_path(Rect2(-8,-9,18,4))
	_path(Rect2(-8,-25,4,19))
	for x in range(-14,16,4):
		for z in range(-23,25,5):
			var candidate := Vector2(x + rng.randf_range(-0.6,0.6),z + rng.randf_range(-0.6,0.6))
			var on_path := false
			for rect in map_paths:
				if rect.grow(2.2).has_point(candidate): on_path = true
			if not on_path: _tree(candidate.x,candidate.y,rng.randf_range(0.8,1.3))
	# Cliffs and the stream are impassable: the broad switchback is the walkable route.
	_box(Vector3(-8,0.15,7),Vector3(7,0.3,19),Color("658984"),true)
	_box(Vector3(-8,-0.05,7),Vector3(6.6,0.1,19),Color("81b4b0"))
	for z in [-2,3,8,13,17]:
		_rock(Vector3(-3.7,0.3,z),Vector3(1.5,1.5,1.6))
	for z in [-21,-16,-11]:
		_rock(Vector3(0,0.3,z),Vector3(1.6,2,1.4))
	_npc(1,Vector3(10.2,0,3),"레온")
	_interact(Vector2(10.2,3),"부상당한 여행자 살피기","leon")
	_cylinder(Vector3(11.4,0.15,3.8),0.25,0.25,Color("75664a"))
	_interact(Vector2(0,24),"서리골로","exit",{"map":1,"spawn":Vector3(0,0,-14.2)})
	_interact(Vector2(-6,-24),"돌샘 연락소로","exit",{"map":3,"spawn":Vector3(-2,0,13),"requires_leon":true})
	_marker(Vector3(4,1.3,9),"돌샘  →")
	_lantern(5.4,9.4)
	_fence(Vector2(10.8,-4),Vector2(10.8,-12))

func _build_well() -> void:
	_path(Rect2(-4,-13,5,29),Color("a5ac91"))
	_path(Rect2(-13,-1,27,5),Color("a5ac91"))
	_house(8,-6,8,6,Color("6a7b70"))
	_house(-10,-8,5,5,Color("7b7461"))
	_cylinder(Vector3(-1,0.5,0),1.35,1.0,Color("929b84"))
	_cylinder(Vector3(-1,1.02,0),0.96,0.08,Color("527f7a"))
	obstacles.append(Rect2(-2.4,-1.4,2.8,2.8))
	for x in [-2.4,0.4]:
		_box(Vector3(x,1.5,0),Vector3(0.17,3,0.17),Color("655b43"))
	_roof(Vector3(-1,3,0),3.7,2.3,0.9,Color("7c7c61"))
	_lantern(2.0,6)
	_lantern(5.4,-1)
	for x in [-15,15]:
		for z in [-13,-5,8,13]: _tree(x,z,0.95)
	_fence(Vector2(-15,-14),Vector2(15,-14))
	_box(Vector3(3,0.6,6),Vector3(2,1.2,1.2),Color("8b7857"),true)
	_box(Vector3(5.3,0.4,6),Vector3(1.5,0.8,1.1),Color("a28a64"),true)
	_npc(1,Vector3(-5,0,4),"레온")
	_interact(Vector2(-5,4),"레온과 대화","leon_arrival")
	_interact(Vector2(8,-2),"약 꾸러미 전달하기","delivery")
	_marker(Vector3(8,2,-2),"◇  국경 연락소")
	_interact(Vector2(-2,14.7),"산길로","exit",{"map":2,"spawn":Vector3(-6,0,-21.7)})

func _make_snow() -> void:
	for i in range(65):
		var flake := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.035,0.035) * rng.randf_range(0.7,1.8)
		flake.mesh = mesh
		var mat := _material(Color(0.94,0.98,0.92,0.65),true).duplicate() as StandardMaterial3D
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		flake.material_override = mat
		flake.position = Vector3(rng.randf_range(-map_size.x/2,map_size.x/2),rng.randf_range(1,9),rng.randf_range(-map_size.y/2,map_size.y/2))
		map_root.add_child(flake)
		particles.append(flake)

func _blocked(pos: Vector3, radius := 0.29) -> bool:
	var point := Vector2(pos.x,pos.z)
	if abs(pos.x) > map_size.x/2 - 0.9 or abs(pos.z) > map_size.y/2 - 0.9:
		return true
	if map_id == 2:
		var on_path := false
		for rect in map_paths:
			if rect.grow(1.8).has_point(point): on_path = true
		if not on_path: return true
	for rect in obstacles:
		if rect.grow(radius).has_point(point): return true
	return false

func _physics_process(delta: float) -> void:
	elapsed += delta
	if not started or paused or transitioning or dialog_panel.visible:
		return
	var axis := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"),Input.get_action_strength("move_down")-Input.get_action_strength("move_up"))
	if axis.length_squared() > 0.01:
		has_walk_target = false
		route.clear()
	elif has_walk_target:
		axis = Vector2(walk_target.x-hero.position.x,walk_target.z-hero.position.z)
		if axis.length() < 0.2:
			if not route.is_empty():
				walk_target = route.pop_front()
			else:
				has_walk_target = false
			axis = Vector2.ZERO
	axis = axis.limit_length(1.0)
	var speed := HERO_SPEED * (1.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	var movement := Vector3(axis.x,0,axis.y) * speed * delta
	var before := hero.position
	var next := hero.position + Vector3(movement.x,0,0)
	if not _blocked(next): hero.position = next
	next = hero.position + Vector3(0,0,movement.z)
	if not _blocked(next): hero.position = next
	var moving := hero.position.distance_to(before) > 0.001
	if moving:
		step_clock += delta * 11
		if abs(axis.x) > abs(axis.y):
			facing = 2
			hero_sprite.flip_h = axis.x < 0
		else:
			facing = 0 if axis.y > 0 else 1
			hero_sprite.flip_h = false
		hero_sprite.position.y = 1.12 + abs(sin(step_clock)) * 0.065
		hero_sprite.rotation.z = sin(step_clock) * 0.025
	else:
		hero_sprite.position.y = lerpf(hero_sprite.position.y,1.12,0.25)
		hero_sprite.rotation.z = 0
	hero_sprite.frame = facing
	_update_camera(delta)
	_update_nearest()
	_update_occlusion()
	minimap.queue_redraw()

func _process(delta: float) -> void:
	if not paused:
		for flake in particles:
			flake.position.y -= delta * 0.42
			flake.position.x += delta * 0.08
			if flake.position.y < 0: flake.position.y = 8

func _update_camera(delta: float, snap := false) -> void:
	var view_width := zoom * get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y
	var limit_x := maxf(0,map_size.x/2-view_width/2)
	var limit_z := maxf(0,map_size.y/2-zoom*0.55)
	var focus := Vector3(clampf(hero.position.x,-limit_x,limit_x),0,clampf(hero.position.z,-limit_z,limit_z))
	var desired := focus + Vector3(0,19,17)
	camera.position = desired if snap else camera.position.lerp(desired,1-exp(-delta*6))
	camera.look_at(camera.position-Vector3(0,19,17),Vector3.UP)
	camera.size = lerpf(camera.size,zoom,1-exp(-delta*8))

func _update_occlusion() -> void:
	for item in occluders:
		var p: Vector2 = item.pos
		var hidden: bool = abs(hero.position.x-p.x) < item.width and hero.position.z < p.y+0.4 and hero.position.z > p.y-6
		for mesh: MeshInstance3D in item.meshes:
			mesh.transparency = 0.74 if hidden else 0.0

func _update_nearest() -> void:
	current_interaction = {}
	var closest := 2.35
	for point in interactions:
		var distance := Vector2(hero.position.x,hero.position.z).distance_to(point.pos)
		if distance < closest:
			closest = distance
			current_interaction = point
	prompt_label.visible = not current_interaction.is_empty()
	if prompt_label.visible: prompt_label.text = _key_name("interact") + "   " + current_interaction.title

func _configure_inputs() -> void:
	var bindings := {"move_left":KEY_A,"move_right":KEY_D,"move_up":KEY_W,"move_down":KEY_S,"interact":KEY_E}
	for action: String in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var key := InputEventKey.new()
		var config := ConfigFile.new()
		config.load("user://controls.cfg")
		key.physical_keycode = int(config.get_value("keys",action,bindings[action]))
		InputMap.action_add_event(action,key)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not rebind_action.is_empty():
			if event.keycode != KEY_ESCAPE: _rebind(event)
			rebind_action = ""
			bind_help.text = "바꿀 동작을 누른 뒤 사용할 키를 누르세요."
			return
		if event.keycode == KEY_F5 and started and not dialog_panel.visible and not transitioning:
			_save_game()
			return
		if event.keycode == KEY_F9 and not transitioning:
			_load_game()
			return
		if dialog_panel.visible:
			if event.is_action_pressed("interact") or event.keycode in [KEY_ENTER,KEY_SPACE]: _advance_dialog()
			return
		if event.keycode == KEY_ESCAPE and started and not transitioning:
			_set_pause(not paused)
			return
		if event.keycode == KEY_SPACE and started and not transitioning:
			_set_pause(not paused)
			return
		if not started or paused or transitioning: return
		if event.is_action_pressed("interact"):
			_activate_interaction()
		if event.keycode == KEY_M:
			minimap.visible = not minimap.visible
	if event is InputEventMouseButton and started and not paused and not dialog_panel.visible and not transitioning:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom = clampf(zoom-1,13,24)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom = clampf(zoom+1,13,24)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var ray_origin := camera.project_ray_origin(event.position)
			var ray_direction := camera.project_ray_normal(event.position)
			var ground = Plane(Vector3.UP,0.0).intersects_ray(ray_origin,ray_direction)
			if ground != null and not _blocked(ground):
				_set_click_route(ground)

func _activate_interaction() -> void:
	if current_interaction.is_empty(): return
	var point := current_interaction.duplicate()
	match point.kind:
		"exit":
			if point.get("requires_medicine",false) and not has_medicine:
				_dialog([["에일","약 꾸러미를 먼저 챙겨야 해. 돌샘에서 기다리고 계실 테니까.",0]])
				return
			if point.get("requires_leon",false) and not met_leon:
				_dialog([["에일","저쪽에 사람이 있어. 다친 것 같은데… 먼저 살펴보자.",0]])
				return
			_transition(point.map,point.spawn)
		"medicine":
			if has_medicine:
				_toast("약 꾸러미는 가방에 잘 넣어 두었다.")
			else:
				_dialog([["에일","붕대, 말린 약초, 해열제… 빠진 건 없겠지?",0],["마르타","돌샘에 도착하면 연락소에 맡겨. 그리고 네 점심도 가방 안에 있다.",2],["에일","약보다 먼저 확인했어요. 걱정 마세요.",0]],func(): has_medicine = true; _update_quest())
		"marta":
			_dialog([["마르타","산길 그늘에는 아직 눈이 남아 있을 거다. 서두르지 말고.",2],["에일","다녀올게요. 저녁 전에 돌아오면 따뜻한 차 부탁해요.",0],["마르타","힘들면 쉬어 가렴. 괜찮다는 말로 다 해결되는 건 아니야.",2]])
		"notice":
			_dialog([["서리골 게시판","돌샘 방면 여행자께. 해가 진 뒤에는 산길을 피하십시오. 약재 운반은 국경 연락소로 문의 바랍니다.",-1]])
		"leon":
			_dialog([["에일","움직이지 마세요. 상처부터 볼게요. 돌샘에서 오셨어요?",0],["레온","…연락소로 가던 길이야. 네가 약초사인가?",1],["에일","아직 배우는 중이에요. 그래도 붕대는 자신 있어요.",0],["레온","고맙다. 길은 내가 알려 주지. 돌샘은 저 굽이를 지나면 돼.",1]],func(): met_leon = true; _update_quest())
		"leon_arrival":
			_dialog([["레온","여기가 돌샘이다. 연락소는 우물 오른편 건물이고.",1],["에일","다 왔네요. 이번에는 제가 먼저 쉬자고 할게요.",0],["레온","좋은 생각이야. 약을 전하면 따뜻한 것을 구해 보자.",1]])
		"delivery":
			if arrived:
				_dialog([["에일","약은 잘 전했어. 조금 쉬었다가 돌아가자.",0]])
			else:
				_dialog([["돌샘 연락소","서리골에서 오셨군요. 기다리던 약입니다. 정말 고맙습니다.",-1],["에일","마르타가 보내셨어요. 젖지 않게 안쪽에 넣어 뒀어요.",0],["레온","네가 챙겨 온 덕분에 살았군. 오늘은 내가 차를 사지.",1]],func(): arrived = true; _update_quest(); _save_game())

func _transition(index: int, spawn: Vector3) -> void:
	if transitioning: return
	transitioning = true
	prompt_label.hide()
	var tween := create_tween()
	tween.tween_property(fade,"color:a",1.0,0.22)
	await tween.finished
	_load_map(index,spawn)
	_save_game(false)
	tween = create_tween()
	tween.tween_property(fade,"color:a",0.0,0.32)
	await tween.finished
	transitioning = false
	_toast(NAMES[index])

func _dialog(lines: Array, action := Callable()) -> void:
	dialog_lines = lines.duplicate(true)
	dialog_action = action
	has_walk_target = false
	prompt_label.hide()
	dialog_panel.show()
	_advance_dialog()

func _advance_dialog() -> void:
	if dialog_lines.is_empty():
		dialog_panel.hide()
		if dialog_action.is_valid(): dialog_action.call()
		dialog_action = Callable()
		return
	var line: Array = dialog_lines.pop_front()
	speaker_label.text = line[0]
	dialog_label.text = line[1]
	portrait.visible = int(line[2]) >= 0
	if portrait.visible:
		var files := ["ael-portrait.png","leon-portrait.png","marta-portrait.png"]
		var path: String = "res://assets/" + files[int(line[2])]
		if ResourceLoader.exists(path):
			var atlas := AtlasTexture.new()
			atlas.atlas = load(path)
			atlas.region = Rect2(560,615,225,320) if int(line[2]) != 2 else Rect2(600,640,220,310)
			portrait.texture = atlas

func _update_quest() -> void:
	if arrived:
		objective_label.text = "약을 무사히 전했다\n돌샘에서 잠시 쉬어 가자"
	elif met_leon:
		objective_label.text = "국경 연락소에 약 전달하기\n우물 오른편 건물로 이동" if map_id == 3 else "돌샘으로 향하기\n산길 북쪽 굽이를 따라 이동"
	elif has_medicine:
		objective_label.text = "돌샘에 약 전하기\n굽이진 산길을 따라 이동" if map_id == 2 else "돌샘에 약 전하기\n서리골 북쪽 산길로 이동"
	else:
		objective_label.text = "여행 준비\n집 안에서 약 꾸러미 챙기기"

func _save_game(notify := true) -> bool:
	var save := {"version":1,"map":map_id,"position":[hero.position.x,hero.position.z],"medicine":has_medicine,"leon":met_leon,"arrived":arrived}
	var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file == null:
		if notify: _toast("저장하지 못했습니다. 저장 공간을 확인해 주세요.")
		return false
	file.store_string(JSON.stringify(save))
	if notify: _toast("여행을 기록했습니다")
	return true

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_toast("아직 저장된 여행이 없습니다")
		return
	var value = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not value is Dictionary or value.get("version") != 1:
		_toast("저장 기록을 읽을 수 없습니다")
		return
	var index := int(value.get("map",-1))
	var coords = value.get("position",[])
	if index < 0 or index >= NAMES.size() or not coords is Array or coords.size() != 2:
		_toast("저장 기록을 읽을 수 없습니다")
		return
	for flag in ["medicine","leon","arrived"]:
		if not value.get(flag) is bool:
			_toast("저장 기록을 읽을 수 없습니다")
			return
	if not (coords[0] is float or coords[0] is int) or not (coords[1] is float or coords[1] is int):
		_toast("저장 기록을 읽을 수 없습니다")
		return
	has_medicine = value.medicine
	met_leon = value.leon
	arrived = value.arrived
	started = true
	paused = false
	title_screen.hide()
	pause_screen.hide()
	dialog_panel.hide()
	dialog_lines.clear()
	dialog_action = Callable()
	hud.show()
	_load_map(index,Vector3(float(coords[0]),0,float(coords[1])))
	if _blocked(hero.position): hero.position = _safe_spawn(index)
	_update_camera(1.0,true)
	_toast("기록한 여행을 이어갑니다")

func _safe_spawn(index: int) -> Vector3:
	return [Vector3(0,0,4),Vector3(0,0,12),Vector3(0,0,23),Vector3(-2,0,13)][index]

func _new_game() -> void:
	has_medicine = false
	met_leon = false
	arrived = false
	started = true
	paused = false
	title_screen.hide()
	pause_screen.hide()
	hud.show()
	_load_map(0,Vector3(-3,0,3.8))
	_toast("서리골의 아침 · 마르타가 여행 준비를 하고 있다")

func _set_pause(value: bool) -> void:
	paused = value
	if not value:
		binding_panel.hide()
		rebind_action = ""
	pause_screen.visible = value
	prompt_label.visible = false

func _toast(message: String) -> void:
	toast_label.text = message
	toast_label.modulate.a = 1
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(toast_label,"modulate:a",0.0,0.6)

func _panel_style(color: Color, border := Color("a9ad8d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func _label(parent: Node, text: String, font_size: int, color := Color("e9e5d1")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font",body_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(270,48)
	button.add_theme_font_override("font",body_font)
	button.add_theme_font_size_override("font_size",19)
	button.add_theme_color_override("font_color",Color("efe8ce"))
	button.add_theme_stylebox_override("normal",_panel_style(Color("203d37"),Color("798779")))
	button.add_theme_stylebox_override("hover",_panel_style(Color("365b4b"),Color("d5ba80")))
	button.add_theme_stylebox_override("pressed",_panel_style(Color("4c6c54"),Color("e8d39d")))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _setup_ui() -> void:
	_configure_inputs()
	canvas = CanvasLayer.new()
	add_child(canvas)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui_root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	var location := PanelContainer.new()
	location.position = Vector2(30,26)
	location.custom_minimum_size = Vector2(290,88)
	location.add_theme_stylebox_override("panel",_panel_style(Color(0.09,0.18,0.16,0.92)))
	hud.add_child(location)
	var location_stack := VBoxContainer.new()
	location.add_child(location_stack)
	chapter_label = _label(location_stack,"",12,Color("b8c6ae"))
	location_label = _label(location_stack,"",27,Color("f0e6c9"))
	var quest := PanelContainer.new()
	quest.position = Vector2(30,132)
	quest.custom_minimum_size = Vector2(290,96)
	quest.add_theme_stylebox_override("panel",_panel_style(Color(0.09,0.18,0.16,0.88),Color("687b68")))
	hud.add_child(quest)
	var quest_stack := VBoxContainer.new()
	quest.add_child(quest_stack)
	_label(quest_stack,"◇  지금의 여정",13,Color("d3b77c"))
	objective_label = _label(quest_stack,"",17)
	var map_container := VBoxContainer.new()
	map_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_container.position = Vector2(-210,26)
	map_container.size = Vector2(180,180)
	hud.add_child(map_container)
	var map_title := _label(map_container,"N   /   주변 지도",12,Color("e7ddbd"))
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	minimap = MapView.new()
	minimap.custom_minimum_size = Vector2(180,142)
	minimap.world = self
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_container.add_child(minimap)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 30
	bottom.offset_right = -30
	bottom.offset_top = -82
	bottom.offset_bottom = -24
	bottom.add_theme_stylebox_override("panel",_panel_style(Color(0.09,0.18,0.16,0.94),Color("697f6a")))
	hud.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation",20)
	bottom.add_child(bottom_row)
	_label(bottom_row,"エイル".replace("エイル","에일") + "   /   여행자",18,Color("e4d2a1"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer)
	_label(bottom_row,"WASD 이동   ·   E 대화 / 조사   ·   Shift 달리기   ·   Esc 메뉴",14,Color("c0cbb6"))
	prompt_label = _label(hud,"",19,Color("fff0c2"))
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-270,-132)
	prompt_label.size = Vector2(540,40)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_shadow_color",Color("172f28"))
	prompt_label.add_theme_constant_override("shadow_outline_size",10)
	toast_label = _label(ui_root,"",18,Color("f1dfae"))
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-350,36)
	toast_label.size = Vector2(700,40)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_shadow_color",Color("183b32"))
	toast_label.add_theme_constant_override("shadow_outline_size",8)
	_make_dialog_ui()
	_make_title_ui()
	_make_pause_ui()
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.03,0.07,0.06,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fade)

func _make_dialog_ui() -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.offset_top = -228
	dialog_panel.offset_bottom = -32
	dialog_panel.add_theme_stylebox_override("panel",_panel_style(Color("e9e1c8"),Color("9e9169")))
	ui_root.add_child(dialog_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",25)
	dialog_panel.add_child(row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(145,158)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",10)
	row.add_child(stack)
	speaker_label = _label(stack,"",20,Color("49624e"))
	dialog_label = _label(stack,"",22,Color("293b31"))
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var next := _button(stack,"다음  ·  E / Enter",_advance_dialog)
	next.custom_minimum_size = Vector2(180,32)
	next.size_flags_horizontal = Control.SIZE_SHRINK_END
	dialog_panel.hide()

func _make_title_ui() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(title_screen)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035,0.09,0.08,0.52)
	title_screen.add_child(shade)
	var panel := VBoxContainer.new()
	panel.position = Vector2(92,125)
	panel.size = Vector2(650,480)
	panel.add_theme_constant_override("separation",16)
	title_screen.add_child(panel)
	var english := _label(panel,"SPRINGBOUND FRONTIER",15,Color("d4c598"))
	english.add_theme_font_override("font",title_font)
	_label(panel,"봄을 기다리는\n국경",60,Color("f1ead1"))
	_label(panel,"눈이 녹지 않은 길에도,\n누군가는 따뜻한 소식을 기다린다.",20,Color("c5cfbb"))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	panel.add_child(spacer)
	var start := _button(panel,"새로운 여정   →",_new_game)
	start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var resume := _button(panel,"여행 이어가기",_load_game)
	resume.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	resume.disabled = not FileAccess.file_exists(SAVE_PATH)
	var footer := _label(title_screen,"PROLOGUE   /   서리골에서 돌샘까지",13,Color("c3c9b6"))
	footer.position = Vector2(94,665)

func _make_pause_ui() -> void:
	pause_screen = Control.new()
	pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(pause_screen)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03,0.07,0.06,0.78)
	pause_screen.add_child(shade)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.position = Vector2(-180,-220)
	stack.size = Vector2(360,440)
	stack.add_theme_constant_override("separation",12)
	pause_screen.add_child(stack)
	_label(stack,"잠시 쉬어 가기",30,Color("e8dbb4"))
	_label(stack,"F5 저장   ·   F9 불러오기   ·   M 지도\n우클릭 목적지 이동   ·   휠 화면 확대",15,Color("aebfa9"))
	_button(stack,"여행 계속하기",func(): _set_pause(false))
	_button(stack,"여행 기록하기",func(): _save_game())
	_button(stack,"기록 불러오기",_load_game)
	_button(stack,"글자 크기 조절",_toggle_text_scale)
	_button(stack,"이동·상호작용 키 설정",func(): binding_panel.visible = not binding_panel.visible)
	_button(stack,"시작 화면으로",func(): paused = false; started = false; pause_screen.hide(); hud.hide(); title_screen.show())
	pause_screen.hide()
	_make_binding_ui()

func _toggle_text_scale() -> void:
	ui_scale = 1.15 if ui_scale == 1.0 else 1.0
	dialog_label.add_theme_font_size_override("font_size",int(22*ui_scale))
	objective_label.add_theme_font_size_override("font_size",int(17*ui_scale))
	_toast("대사·목표 글자 크기  " + ("크게" if ui_scale > 1 else "기본"))

func _run_qa() -> void:
	await get_tree().process_frame
	var errors: Array[String] = []
	_new_game()
	if not _blocked(Vector3(0,0,0)): errors.append("Home table collision missing")
	if _blocked(hero.position): errors.append("Home spawn blocked")
	current_interaction = interactions.filter(func(p): return p.kind == "medicine")[0]
	_activate_interaction()
	while dialog_panel.visible: _advance_dialog()
	if not has_medicine: errors.append("Medicine interaction failed")
	var before_move := hero.position
	Input.action_press("move_right")
	_physics_process(0.1)
	Input.action_release("move_right")
	if hero.position.x <= before_move.x: errors.append("WASD movement failed")
	_set_click_route(Vector3(5,0,3.8))
	if not has_walk_target or route.is_empty(): errors.append("Click route missing")
	for waypoint in route:
		if _blocked(waypoint): errors.append("Click route crosses collider")
	for index in range(4):
		_load_map(index,_safe_spawn(index))
		if _blocked(hero.position): errors.append("Blocked map spawn " + str(index))
		# Every exit must have a reachable approach, not a collider covering its marker.
		for point in interactions:
			if point.kind == "exit" and _blocked(Vector3(point.pos.x,0,point.pos.y),0.1): errors.append("Blocked exit: " + point.title)
		if not _route_reachable(): errors.append("Disconnected route in map " + str(index))
	_load_map(2,Vector3(8,0,4))
	current_interaction = interactions.filter(func(p): return p.kind == "leon")[0]
	_activate_interaction()
	while dialog_panel.visible: _advance_dialog()
	if not met_leon: errors.append("Leon interaction failed")
	_load_map(3,Vector3(-2,0,13))
	var old_save := FileAccess.get_file_as_string(SAVE_PATH) if FileAccess.file_exists(SAVE_PATH) else ""
	current_interaction = interactions.filter(func(p): return p.kind == "delivery")[0]
	_activate_interaction()
	while dialog_panel.visible: _advance_dialog()
	if not arrived: errors.append("Delivery interaction failed")
	if not _save_game(false): errors.append("Save failed")
	_load_map(0,_safe_spawn(0))
	_load_game()
	if map_id != 3 or not arrived or not has_medicine or not met_leon: errors.append("Save roundtrip failed")
	if old_save.is_empty():
		DirAccess.remove_absolute(SAVE_PATH)
	else:
		var restore := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
		restore.store_string(old_save)
	print("PROLOGUE_QA: ","PASS" if errors.is_empty() else "FAIL", " ",errors)
	get_tree().quit(0 if errors.is_empty() else 1)

func _route_reachable() -> bool:
	# Flood-fill a half-meter navigation grid using the same collision predicate as movement.
	var step := 0.5
	var start := Vector2i(roundi(hero.position.x/step),roundi(hero.position.z/step))
	var frontier: Array[Vector2i] = [start]
	var visited := {start:true}
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if visited.has(neighbor): continue
			if _blocked(Vector3(neighbor.x*step,0,neighbor.y*step)): continue
			visited[neighbor] = true
			frontier.append(neighbor)
	for point in interactions:
		var reachable := false
		for cell in visited:
			if (Vector2(cell)*step).distance_to(point.pos) < 2.2:
				reachable = true
				break
		if not reachable: return false
	return true

func _run_capture() -> void:
	var output := ProjectSettings.globalize_path("res://../docs/screenshots")
	DirAccess.make_dir_recursive_absolute(output)
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output + "/00-title.png")
	_new_game()
	for index in range(4):
		has_medicine = index > 0
		met_leon = index == 3
		var positions := [Vector3(-3,0,3.8),Vector3(0,0,10),Vector3(7,0,6),Vector3(-2,0,8)]
		_load_map(index,positions[index])
		toast_label.modulate.a = 0
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output + "/0" + str(index+1) + "-map.png")
	_load_map(0,Vector3(3,0,0.8))
	_dialog([["마르타","힘들면 쉬어 가렴. 괜찮다는 말로 다 해결되는 건 아니야.",2]])
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output + "/05-dialogue.png")
	print("CAPTURE_COMPLETE: ",output)
	get_tree().quit()

func _build_navigation() -> void:
	navigation.region = Rect2i(-int(map_size.x),-int(map_size.y),int(map_size.x*2)+1,int(map_size.y*2)+1)
	navigation.cell_size = Vector2(0.5,0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(navigation.region.position.x,navigation.region.end.x):
		for y in range(navigation.region.position.y,navigation.region.end.y):
			navigation.set_point_solid(Vector2i(x,y),_blocked(Vector3(x*0.5,0,y*0.5),0.37))

func _set_click_route(target: Vector3) -> void:
	var start := Vector2i(roundi(hero.position.x*2),roundi(hero.position.z*2))
	var end := Vector2i(roundi(target.x*2),roundi(target.z*2))
	if not navigation.is_in_boundsv(start) or not navigation.is_in_boundsv(end): return
	if navigation.is_point_solid(start) or navigation.is_point_solid(end): return
	var points := navigation.get_point_path(start,end)
	route.clear()
	for point in points: route.append(Vector3(point.x,0,point.y))
	if not route.is_empty():
		walk_target = route.pop_front()
		has_walk_target = true

func _make_binding_ui() -> void:
	binding_panel = PanelContainer.new()
	binding_panel.position = Vector2(820,120)
	binding_panel.custom_minimum_size = Vector2(380,440)
	binding_panel.add_theme_stylebox_override("panel",_panel_style(Color("203d37")))
	pause_screen.add_child(binding_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",10)
	binding_panel.add_child(stack)
	bind_help = _label(stack,"바꿀 동작을 누른 뒤 사용할 키를 누르세요.",14)
	var captions := {"move_up":"위로 이동","move_down":"아래로 이동","move_left":"왼쪽으로 이동","move_right":"오른쪽으로 이동","interact":"대화 / 조사"}
	for action: String in captions:
		var key_name := OS.get_keycode_string(InputMap.action_get_events(action)[0].physical_keycode)
		var button := _button(stack,captions[action]+"  /  "+key_name,func(): rebind_action = action; bind_help.text = "새 키를 누르세요. Esc 취소")
		button.set_meta("caption",captions[action])
		rebind_buttons[action] = button
	_button(stack,"닫기",func(): rebind_action = ""; binding_panel.hide())
	binding_panel.hide()

func _rebind(event: InputEventKey) -> void:
	if event.keycode in [KEY_F5,KEY_F9,KEY_SPACE,KEY_ESCAPE,KEY_SHIFT,KEY_M]:
		_toast("이 키는 메뉴·저장·지도 조작에 사용 중입니다")
		return
	for action: String in rebind_buttons:
		if action == rebind_action: continue
		for old_event in InputMap.action_get_events(action):
			if old_event is InputEventKey and old_event.physical_keycode == event.physical_keycode:
				_toast("다른 동작에 사용 중인 키입니다")
				return
	InputMap.action_erase_events(rebind_action)
	var key := InputEventKey.new()
	key.physical_keycode = event.physical_keycode
	InputMap.action_add_event(rebind_action,key)
	(rebind_buttons[rebind_action] as Button).text = str((rebind_buttons[rebind_action] as Button).get_meta("caption")) + "  /  " + OS.get_keycode_string(event.physical_keycode)
	var config := ConfigFile.new()
	for action: String in rebind_buttons:
		config.set_value("keys",action,InputMap.action_get_events(action)[0].physical_keycode)
	config.save("user://controls.cfg")

func _add_ground_details() -> void:
	# Low tufts and snow patches break up large flat surfaces without hiding the route.
	for i in range(140):
		var x := rng.randf_range(-map_size.x/2+1,map_size.x/2-1)
		var z := rng.randf_range(-map_size.y/2+1,map_size.y/2-1)
		var point := Vector2(x,z)
		var on_path := false
		for rect in map_paths:
			if rect.grow(0.6).has_point(point): on_path = true
		if on_path: continue
		if _blocked(Vector3(x,0,z),0.1) and map_id != 2: continue
		for j in range(3):
			var grass := _box(Vector3(x+j*0.065,0.12,z),Vector3(0.035,0.24+rng.randf()*0.12,0.035),Color("8a9478"))
			grass.rotation.z = rng.randf_range(-0.3,0.3)
	for i in range(55):
		var x := rng.randf_range(-map_size.x/2+1,map_size.x/2-1)
		var z := rng.randf_range(-map_size.y/2+1,map_size.y/2-1)
		var on_path := false
		for rect in map_paths:
			if rect.has_point(Vector2(x,z)): on_path = true
		if not on_path:
			_cylinder(Vector3(x,0.025,z),rng.randf_range(0.25,0.9),0.025,Color("c6d2cd"))

func _key_name(action: String) -> String:
	return OS.get_keycode_string(InputMap.action_get_events(action)[0].physical_keycode)
