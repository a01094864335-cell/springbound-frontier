extends Node3D

const PrologueStory = preload("res://scripts/prologue_story.gd")
const CAST := {"오르만":"orman", "니아":"nia", "도렌":"doren", "베라":"vera", "로크":"roke", "에다":"eda", "할벤":"halven"}

const MapView = preload("res://scripts/map_view.gd")
const SAVE_PATH := "user://prologue_save.json"
const NAMES := ["마르타의 집", "서리골", "고요한 산길", "돌샘 연락소"]
const CHAPTERS := ["01 / 집 안의 아침", "02 / 봄을 기다리는 마을", "03 / 눈 아래의 길", "04 / 국경의 작은 불빛"]
const MAP_SIZES := [Vector2(18, 16), Vector2(40, 38), Vector2(34, 54), Vector2(36, 34)]
const GridWalker = preload("res://scripts/grid_walker.gd")
const CAMERA_OFFSET := Vector3(0,22,18)

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
var story = PrologueStory.new()
var dialogue_history: Array = []
var history_panel: PanelContainer
var history_text: RichTextLabel
var history_return_focus: Control
var dialog_progress: Label
var dialog_next: Button
var dialogue_total := 0
var dialogue_index := 0
var active_scene := ""
var cast_textures := {}
var current_interaction: Dictionary = {}
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var walker = GridWalker.new()
var pending_step := Vector2i.ZERO
var last_input_axis := 0
var step_settle_remaining := 0.0
var walk_atlas: Texture2D
var terrain_atlas: Texture2D
var terrain_materials: Array[StandardMaterial3D] = []
var foot_offsets: Array[float] = []
var leon_texture: Texture2D
var tree_texture: Texture2D
var tree_used := Rect2i()
var facing := 0
var walk_target := Vector3.ZERO
var has_walk_target := false
var zoom := 17.5
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
	if ResourceLoader.exists("res://assets/ael-walk.png"):
		walk_atlas = load("res://assets/ael-walk.png")
	if ResourceLoader.exists("res://assets/winter-materials.png"):
		terrain_atlas = load("res://assets/winter-materials.png")
	if ResourceLoader.exists("res://assets/leon-sprite.png"):
		leon_texture = load("res://assets/leon-sprite.png")
	if ResourceLoader.exists("res://assets/snow-spruce.png"):
		tree_texture = load("res://assets/snow-spruce.png")
		tree_used = tree_texture.get_image().get_used_rect()
	_prepare_surface_materials()
	_setup_world()
	_setup_ui()
	_load_map(1, Vector3(0, 0, 9))
	hud.hide()
	title_screen.show()
	if qa_mode:
		call_deferred("_run_qa")
	elif "--story-capture" in OS.get_cmdline_user_args():
		call_deferred("_run_story_capture")
	elif "--compare-capture" in OS.get_cmdline_user_args():
		call_deferred("_run_compare_capture")
	elif "--walk-capture" in OS.get_cmdline_user_args():
		call_deferred("_run_walk_capture")
	elif "--capture" in OS.get_cmdline_user_args():
		call_deferred("_run_capture")

func _setup_world() -> void:
	atmosphere = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("c3cce7")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c2c9ed")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	atmosphere.environment = environment
	add_child(atmosphere)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.far = 150
	add_child(camera)
	# Controls and navigation use screen-facing ground axes, not the rotated map axes.
	walker.axis_z = Vector3(CAMERA_OFFSET.x,0,CAMERA_OFFSET.z).normalized()
	walker.axis_x = Vector3(walker.axis_z.z,0,-walker.axis_z.x)
	hero = _actor(0)
	add_child(hero)
	hero_sprite = hero.get_node("Sprite") as Sprite3D
	if walk_atlas:
		hero_sprite.texture = walk_atlas
		hero_sprite.hframes = 4
		hero_sprite.vframes = 4
		_anchor_sprite_feet(hero_sprite,4,4)
		_prepare_walk_offsets()

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
	if color.r > 0.8 and color.g > 0.8: _texture_surface(mesh,1)
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
	_texture_surface(rock,2)
	map_root.add_child(rock)
	if scale_value.x > 1.0:
		obstacles.append(Rect2(Vector2(pos.x-scale_value.x*0.4,pos.z-scale_value.z*0.4),Vector2(scale_value.x*0.8,scale_value.z*0.8)))
	if snow:
		_cylinder(pos + Vector3(0, scale_value.y * 0.35, 0), scale_value.x * 0.44, 0.12, Color("dce9de"))

func _tree(x: float, z: float, tree_scale := 1.0) -> void:
	if not tree_texture: return
	var tree := Sprite3D.new()
	tree.texture = tree_texture
	tree.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tree.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	tree.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	tree.shaded = false
	tree.position = Vector3(x,0.025,z)
	tree.pixel_size = 5.8*tree_scale/maxf(1,tree_used.size.y)
	tree.offset.y = float(tree_texture.get_height())/2-(tree_texture.get_height()-tree_used.end.y)
	map_root.add_child(tree)
	obstacles.append(Rect2(Vector2(x-0.42,z-0.42),Vector2(0.84,0.84)))
	occluders.append({"pos":Vector2(x,z),"width":1.7*tree_scale,"sprite":tree,"height":5.8*tree_scale})

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
	_texture_surface(mesh,1 if color.r > 0.8 else 4)
	map_root.add_child(mesh)
	return mesh

func _house(x: float, z: float, width: float, depth: float, roof_color: Color) -> void:
	var walls := _box(Vector3(x, 1.55, z), Vector3(width, 3.1, depth), Color("d8d0b5"), true)
	_texture_surface(walls,3)
	var base := _box(Vector3(x, 0.4, z), Vector3(width + 0.25, 0.8, depth + 0.25), Color("7c8274"))
	_texture_surface(base,2)
	var roof := _roof(Vector3(x, 3.1, z), width + 1.0, depth + 0.9, 2.15, roof_color)
	var snow := _roof(Vector3(x - 0.06, 3.24, z), width + 0.65, depth * 0.78, 2.15, Color("e1ebe0"))
	for offset in [-width * 0.32, width * 0.32]:
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.04), Vector3(0.85, 0.95, 0.12), Color("6c5744"))
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.11), Vector3(0.63, 0.73, 0.04), Color("e6c888"))
		_box(Vector3(x + offset, 1.6, z + depth/2 + 0.15), Vector3(0.06, 0.75, 0.04), Color("6c5744"))
	_box(Vector3(x, 1.0, z + depth/2 + 0.1), Vector3(1.05, 2, 0.18), Color("655744"))
	_box(Vector3(x + width*0.25, 4.45, z - 0.9), Vector3(0.65, 1.6, 0.7), Color("9c9985"))
	for offset in [-width/2 + 0.12, width/2 - 0.12]:
		_box(Vector3(x + offset, 1.5, z + depth/2 + 0.08), Vector3(0.15, 3.1, 0.15), Color("6c6754"))
	var details := _house_details(x,z,width,depth)
	details.append_array([walls,roof,snow])
	occluders.append({"pos": Vector2(x,z), "width": width/2 + 0.6, "meshes": details})

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
	var road := _box(Vector3(rect.get_center().x, 0.035, rect.get_center().y),Vector3(rect.size.x,0.05,rect.size.y),color)
	_texture_surface(road,3 if map_id == 0 else 0)
	for i in range(int(rect.get_area() / 6.0)):
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
	label.visibility_range_end = 65.0
	map_root.add_child(label)

func _actor(row: int) -> Node3D:
	var actor := Node3D.new()
	var sprite := Sprite3D.new()
	sprite.name = "Sprite"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.position.y = 0.04
	if sprite_atlas:
		sprite.texture = sprite_atlas
		sprite.hframes = 3
		sprite.vframes = 3
		sprite.frame = row * 3
		sprite.pixel_size = 2.5 / (sprite_atlas.get_height() / 3.0)
		_anchor_sprite_feet(sprite,3,3)
	if row == 1 and leon_texture:
		sprite.texture = leon_texture
		sprite.hframes = 3
		sprite.vframes = 1
		sprite.frame = 0
		_anchor_sprite_feet(sprite,3,1)
		sprite.pixel_size *= 1.05
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
	actor.name = npc_name
	actor.position = pos
	map_root.add_child(actor)
	_marker(pos + Vector3(0,4.2,0),npc_name)
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
	var ground := _box(Vector3(0,-0.45,0),Vector3(map_size.x if index == 0 else map_size.x+40,0.9,map_size.y if index == 0 else map_size.y+40),ground_color)
	_texture_surface(ground,3 if index == 0 else 1)
	_box(Vector3(0,-1.1,0),Vector3(map_size.x+0.2,0.7,map_size.y+0.2),Color("536d64"))
	match index:
		0: _build_home()
		1: _build_village()
		2: _build_trail()
		3: _build_well()
	_build_navigation()
	walker.reset(spawn)
	hero.position = walker.position
	pending_step = Vector2i.ZERO
	step_settle_remaining = 0.0
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
	_interact(Vector2(-5.6,-3),"침대 옆 지도 살피기","room_map")
	_interact(Vector2(-2.5,-6.4),"창가의 약초 살피기","window")
	_interact(Vector2(0,6.7),"서리골로","exit",{"map":1,"spawn":Vector3(-7,0,7)})
	_path(Rect2(-1.4,4.8,2.8,3.0),Color("b3a17b"))

func _build_village() -> void:
	_path(Rect2(-2.6,-17,5.2,35))
	_path(Rect2(-16,4,32,4.5))
	_path(Rect2(-10,0,4,7))
	_house(-8,-2,6,5,Color("6d7f75"))
	_house(9,-8,6.5,5.5,Color("6c7c7c"))
	_house(-10,-12,5.5,4.5,Color("7d7568"))
	_house(10,9,6,5,Color("707f6a"))
	_stone_well(Vector2(0,6.2),false)
	obstacles.append(Rect2(-1,5.2,2,2))
	_border_gate(Vector2(0,-15.2))
	_lantern(-3.8,8.8)
	_lantern(3.6,-9)
	_fence(Vector2(-17,10),Vector2(-5,10))
	_fence(Vector2(5,-17),Vector2(16,-17))
	for p in [Vector2(-17,-15),Vector2(-17,-7),Vector2(-17,1),Vector2(-16,15),Vector2(17,15),Vector2(17,-2),Vector2(17,-13),Vector2(9,17),Vector2(-7,17)]:
		_tree(p.x,p.y,rng.randf_range(0.8,1.15))
	for i in range(35):
		var x := rng.randf_range(-18,18)
		var z := rng.randf_range(-17,17)
		if abs(x) > 3 and not _blocked(Vector3(x,0,z),0.6) and not _near_story_cast(Vector2(x,z)):
			_rock(Vector3(x,0.1,z),Vector3(0.4,0.35,0.4))
	_story_npc("오르만",Vector3(-12,0,-7),"inn")
	_story_npc("니아",Vector3(5,0,12),"nia")
	_story_npc("도렌",Vector3(-5,0,6.5),"doren")
	_story_npc("베라",Vector3(12,0,-3.5),"vera")
	_story_npc("로크",Vector3(3.5,0,-13),"roke")
	# Keep the well and all residents reachable from the village road.
	_interact(Vector2(0,6.2),"우물에서 물 긷기","water")
	for p in [Vector2(4.6,12),Vector2(5.3,12),Vector2(6,12)]:
		_cylinder(Vector3(p.x,0.32,p.y),0.38,0.6,Color("e0e8e1"),0.23)
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
	_interact(Vector2(2,9),"산길 표지 살피기","trail_sign")
	_interact(Vector2(8,6.5),"눈 위의 발자국 살피기","tracks")
	_lantern(5.4,9.4)
	_fence(Vector2(10.8,-4),Vector2(10.8,-12))

func _build_well() -> void:
	_path(Rect2(-4,-13,5,29),Color("a5ac91"))
	_path(Rect2(-13,-1,27,5),Color("a5ac91"))
	_house(8,-6,8,6,Color("6a7b70"))
	_house(-10,-8,5,5,Color("7b7461"))
	_stone_well(Vector2(-1,0),true)
	obstacles.append(Rect2(-2.4,-1.4,2.8,2.8))
	_lantern(2.0,6)
	_lantern(5.4,-1)
	for x in [-15,15]:
		for z in [-13,-5,8,13]: _tree(x,z,0.95)
	_fence(Vector2(-15,-14),Vector2(15,-14))
	_box(Vector3(3,0.6,6),Vector3(2,1.2,1.2),Color("8b7857"),true)
	_box(Vector3(5.3,0.4,6),Vector3(1.5,0.8,1.1),Color("a28a64"),true)
	_environment_prop("wood_table",Vector3(-6.5,0,7))
	_cylinder(Vector3(-7.1,1.25,7),0.16,0.2,Color("c6b393"))
	_cylinder(Vector3(-5.8,1.25,7),0.16,0.2,Color("c6b393"))
	_npc(1,Vector3(-5,0,4),"레온")
	_interact(Vector2(-5,4),"레온과 쉬어 가기","leon_arrival")
	_story_npc("할벤",Vector3(8,0,1.5),"halven")
	_story_npc("에다",Vector3(11,0,1.5),"eda")
	_interact(Vector2(6,1.5),"약 꾸러미 전달하기","delivery")
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
	if not started or paused or transitioning or dialog_panel.visible or history_panel.visible:
		return
	step_settle_remaining = maxf(0,step_settle_remaining-delta)
	var input_direction := _cardinal_input()
	if input_direction != Vector2i.ZERO:
		has_walk_target = false
		route.clear()
	if not walker.moving and step_settle_remaining <= 0:
		var requested := pending_step if pending_step != Vector2i.ZERO else input_direction
		pending_step = Vector2i.ZERO
		if requested == Vector2i.ZERO and has_walk_target:
			while not route.is_empty() and hero.position.distance_to(route[0]) < 0.01:
				route.pop_front()
			if route.is_empty():
				has_walk_target = false
			else:
				var difference: Vector2 = walker.to_grid(route[0]-hero.position)
				requested = Vector2i(signi(roundi(difference.x*100)),0) if abs(difference.x)>0.01 else Vector2i(0,signi(roundi(difference.y*100)))
		if requested != Vector2i.ZERO:
			if not walker.begin(requested,_blocked,0.14 if Input.is_key_pressed(KEY_SHIFT) else GridWalker.STEP_SECONDS):
				route.clear()
				has_walk_target = false
	var was_moving: bool = walker.moving
	walker.advance(delta)
	if was_moving and not walker.moving:
		step_settle_remaining = 0.06
	hero.position = walker.position
	_set_walk_frame()
	_update_camera(delta)
	_update_nearest()
	_update_occlusion()
	minimap.queue_redraw()

func _cardinal_input() -> Vector2i:
	var x := int(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"))
	var z := int(Input.get_action_strength("move_down")-Input.get_action_strength("move_up"))
	if x != 0 and z != 0:
		return Vector2i(x,0) if last_input_axis == 0 else Vector2i(0,z)
	return Vector2i(x,z)

func _set_walk_frame() -> void:
	var direction: Vector2i = walker.direction
	if direction.y > 0: facing = 0
	elif direction.y < 0: facing = 1
	elif direction.x > 0: facing = 2
	else: facing = 3
	hero_sprite.position = Vector3(0,0.04,0)
	hero_sprite.rotation = Vector3.ZERO
	hero_sprite.flip_h = facing == 3
	if walk_atlas:
		# Reuse the same gait and foot registration for both horizontal directions.
		var animation_row := 2 if facing == 3 else facing
		hero_sprite.frame = animation_row*4 + walker.animation_column()
		if not foot_offsets.is_empty(): hero_sprite.offset.y = foot_offsets[hero_sprite.frame]
	else:
		hero_sprite.frame = mini(facing,2)
		hero_sprite.flip_h = facing == 3

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
	var desired := focus + CAMERA_OFFSET
	camera.position = desired if snap else camera.position.lerp(desired,1-exp(-delta*6))
	camera.look_at(camera.position-CAMERA_OFFSET,Vector3.UP)
	camera.size = lerpf(camera.size,zoom,1-exp(-delta*8))

func _update_occlusion() -> void:
	var hero_screen := camera.unproject_position(hero.position+Vector3(0,0.9,0))
	for item in occluders:
		var p: Vector2 = item.pos
		var base := Vector3(p.x,0,p.y)
		var behind := camera.global_position.distance_squared_to(hero.position) > camera.global_position.distance_squared_to(base)
		if item.has("sprite"):
			var tree: Sprite3D = item.sprite
			var foot := camera.unproject_position(base)
			var pixels := get_viewport().get_visible_rect().size.y/camera.size
			var bounds := Rect2(foot-Vector2(item.width*pixels,item.height*pixels),Vector2(item.width*2*pixels,item.height*pixels))
			tree.modulate.a = 0.32 if behind and bounds.has_point(hero_screen) else 1.0
			continue
		var screen_bounds := Rect2()
		var initial := true
		for mesh: MeshInstance3D in item.meshes:
			var aabb := mesh.get_aabb()
			for i in range(8):
				var point := camera.unproject_position(mesh.global_transform*aabb.get_endpoint(i))
				if initial:
					screen_bounds = Rect2(point,Vector2.ZERO)
					initial = false
				else:
					screen_bounds = screen_bounds.expand(point)
		var hidden := behind and screen_bounds.has_point(hero_screen)
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
		if history_panel.visible:
			if event.keycode in [KEY_ESCAPE,KEY_TAB]: _toggle_history()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB and started and not transitioning:
			_toggle_history()
			return
		for action in ["move_left","move_right","move_up","move_down"]:
			if event.is_action_pressed(action) and started and not paused and not dialog_panel.visible:
				pending_step = {"move_left":Vector2i.LEFT,"move_right":Vector2i.RIGHT,"move_up":Vector2i.UP,"move_down":Vector2i.DOWN}[action]
				last_input_axis = 0 if pending_step.x != 0 else 1
		if event.keycode == KEY_F5 and started and not dialog_panel.visible and not transitioning:
			_save_game()
			return
		if event.keycode == KEY_F9 and not transitioning and not dialog_panel.visible:
			_load_game()
			return
		if dialog_panel.visible:
			get_viewport().set_input_as_handled()
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
			minimap.get_parent().visible = not minimap.get_parent().visible
	if event is InputEventMouseButton and started and not paused and not dialog_panel.visible and not transitioning and not history_panel.visible:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom = clampf(zoom-1,13,24)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom = clampf(zoom+1,13,24)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var ray_origin := camera.project_ray_origin(event.position)
			var ray_direction := camera.project_ray_normal(event.position)
			var ground = Plane(Vector3.UP,0.0).intersects_ray(ray_origin,ray_direction)
			if ground != null and not _blocked(ground):
				_set_click_route(ground)

func _activate_interaction() -> void:
	if current_interaction.is_empty() or walker.moving or dialog_panel.visible or transitioning: return
	var point := current_interaction.duplicate()
	match point.kind:
		"exit":
			if map_id == 0 and not story.done("morning"):
				_play_scene("opening")
				return
			if point.get("requires_medicine",false) and not has_medicine:
				_dialog([["에일","마르타와 준비를 마친 뒤 출발하자. 아직 돌샘에 전할 약이 가방에 없어.",0]])
				return
			if point.get("requires_medicine",false) and not story.done("farewell"):
				_dialog([["에일","마르타가 출발 전에 한 번 더 보자고 했지. 집에 들러 인사하고 가자.",0]])
				return
			if point.get("requires_leon",false) and not met_leon:
				_dialog([["에일","한쪽 발을 끈 자국이 저 굽이로 이어져. 다친 사람이 있는지 살펴보고 가자.",0]])
				return
			_transition(point.map,point.spawn)
		"medicine":
			if has_medicine:
				_dialog([["에일","배달 꾸러미는 가방 안쪽에, 여분 붕대는 바깥쪽에. 빠뜨린 건 없어.",0]])
			elif not story.done("request"):
				_dialog([["에일","마르타가 묶어 둔 약이야. 받는 사람이 따로 있을 테니 먼저 여쭤보자.",0]])
			else: _play_scene("medicine")
		"marta":
			if arrived: _play_scene("marta_return")
			elif not story.done("morning"): _play_scene("opening")
			elif not story.errands_done(): _play_scene("marta_wait")
			elif not story.done("request"): _play_scene("request")
			elif not has_medicine: _dialog([["마르타","문 옆 받침대의 꾸러미를 챙기렴. 끈 색과 쪽지가 있는지 같이 확인하자.",2]])
			elif not story.done("farewell"): _play_scene("farewell")
			else: _play_scene("marta_departed")
		"water", "inn":
			if not story.done("morning"):
				_dialog([["에일","마르타가 아침에 부탁할 일이 있다고 했지. 먼저 집에 들러 보자.",0]])
			else:
				var flag: String = "water" if point.kind == "water" else "towels"
				var prefix: String = "well" if point.kind == "water" else "inn"
				_play_scene(prefix + ("_again" if story.done(flag) else "_first"))
		"leon": _play_scene("leon_again" if met_leon else "leon_first")
		"leon_arrival":
			_play_scene(("rest_again" if story.done("closing") else "closing") if arrived else ("leon_arrival_again" if story.done("leon_arrival") else "leon_arrival"))
		"delivery", "halven", "eda":
			if not has_medicine or not met_leon:
				_dialog([["에다","배달과 치료는 여기서 맡고 있어. 준비가 되면 연락소 앞에서 불러 줘.",-1]])
			elif not arrived: _play_scene("delivery")
			else: _play_scene("delivery_again" if point.kind == "delivery" else (point.kind+"_again" if story.done(point.kind) else point.kind))
		"room_map": _play_scene("map_after" if arrived else "map")
		"nia":
			_play_scene(("nia_return" if story.done("nia") else "nia_late") if arrived else ("nia_again" if story.done("nia") else "nia"))
		"doren", "vera", "roke": _play_scene(point.kind+"_again" if story.done(point.kind) else point.kind)
		"tracks": _play_scene("tracks_after" if met_leon else "tracks")
		_: _play_scene(point.kind)

func _play_scene(scene: String) -> void:
	_dialog(story.lines(scene),func():
		story.finish(scene)
		if scene == "medicine": has_medicine = true
		if scene == "leon_first":
			_play_scene("leon_bridge")
			return
		if scene == "leon_bridge": met_leon = true
		if scene == "delivery": arrived = true
		_update_quest()
		if not qa_mode: _save_game(false)
	,scene)

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

func _dialog(lines: Array, action := Callable(), scene := "") -> void:
	active_scene = scene
	dialog_lines = lines.duplicate(true)
	dialogue_total = lines.size()
	dialogue_index = 0
	pending_step = Vector2i.ZERO
	route.clear()
	dialog_action = action
	has_walk_target = false
	prompt_label.hide()
	dialog_panel.show()
	_advance_dialog()

func _advance_dialog() -> void:
	if history_panel.visible: return
	if dialog_lines.is_empty():
		dialog_panel.hide()
		var completion := dialog_action
		dialog_action = Callable()
		if completion.is_valid(): completion.call()
		return
	var line: Array = dialog_lines.pop_front()
	dialogue_index += 1
	dialog_progress.text = "%d / %d" % [dialogue_index,dialogue_total]
	dialog_next.text = ("대화 마치기" if dialog_lines.is_empty() else "다음") + "  ·  " + _key_name("interact") + " / Enter"
	dialogue_history.append({"speaker":line[0],"text":line[1],"scene":active_scene})
	if dialogue_history.size() > 400: dialogue_history.pop_front()
	speaker_label.text = line[0]
	dialog_label.text = line[1]
	portrait.visible = int(line[2]) >= 0 or CAST.has(line[0])
	if CAST.has(line[0]):
		var cast_portrait := AtlasTexture.new()
		cast_portrait.atlas = load("res://story/cast/" + CAST[line[0]] + "-board-v1.png")
		cast_portrait.region = Rect2(590,640,220,335)
		portrait.texture = cast_portrait
		return
	if portrait.visible:
		var files := ["ael-portrait.png","leon-portrait.png","marta-portrait.png"]
		var path: String = "res://assets/" + files[int(line[2])]
		if ResourceLoader.exists(path):
			var atlas := AtlasTexture.new()
			atlas.atlas = load(path)
			atlas.region = Rect2(560,615,225,320) if int(line[2]) != 2 else Rect2(600,640,220,310)
			portrait.texture = atlas

func _update_quest() -> void:
	if story.done("closing"):
		objective_label.text = "오늘의 배달을 마쳤다\n돌샘에서 쉬거나 마을을 둘러보자"
	elif arrived:
		objective_label.text = "전달을 마쳤다\n레온과 따뜻한 차 한 잔 나누기"
	elif met_leon:
		objective_label.text = "에다에게 약과 환자 인계하기\n돌샘 우물 오른편 연락소" if map_id == 3 else "레온과 돌샘으로 향하기\n북쪽 굽이를 따라 천천히 이동"
	elif has_medicine:
		objective_label.text = "마르타에게 출발 인사하기" if not story.done("farewell") else ("돌샘으로 향하기\n산길의 흔적도 살펴보자" if map_id == 2 else "돌샘에 약 전하기\n서리골 북문으로 이동")
	elif story.done("request"):
		objective_label.text = "돌샘에 갈 준비\n집 문 옆의 약 꾸러미 챙기기"
	elif story.errands_done():
		objective_label.text = "아침 심부름 완료\n집으로 돌아가 마르타와 이야기하기"
	elif story.done("morning"):
		objective_label.text = "아침 심부름 · 순서 자유\n%s 물 긷기  /  %s 여관 수건" % ["✓" if story.done("water") else "○","✓" if story.done("towels") else "○"]
	else:
		objective_label.text = "서리골의 아침\n마르타와 아침 이야기 나누기"

func _save_game(notify := true) -> bool:
	var save := {"version":2,"story":story.flags.duplicate(),"map":map_id,"position":[walker.target.x,walker.target.z],"medicine":has_medicine,"leon":met_leon,"arrived":arrived}
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
	if not value is Dictionary or (value.get("version") != 1 and value.get("version") != 2):
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
	if not story.restore(int(value.version),value.medicine,value.leon,value.arrived,value.get("story")):
		_toast("이야기 진행 기록을 읽을 수 없습니다")
		return
	history_panel.hide()
	dialogue_history.clear()
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
	if _blocked(hero.position):
		walker.reset(_safe_spawn(index))
		hero.position = walker.position
	_update_camera(1.0,true)
	_toast("기록한 여행을 이어갑니다")

func _safe_spawn(index: int) -> Vector3:
	return [Vector3(0,0,4),Vector3(0,0,12),Vector3(0,0,23),Vector3(-2,0,13)][index]

func _new_game() -> void:
	story.reset()
	dialogue_history.clear()
	history_panel.hide()
	dialog_panel.hide()
	dialog_lines.clear()
	dialog_action = Callable()
	has_medicine = false
	met_leon = false
	arrived = false
	started = true
	paused = false
	title_screen.hide()
	pause_screen.hide()
	hud.show()
	_load_map(0,Vector3(-3,0,3.8))
	_play_scene("opening")

func _set_pause(value: bool) -> void:
	paused = value
	if not value:
		binding_panel.hide()
		rebind_action = ""
	pause_screen.visible = value
	prompt_label.visible = false

func _toast(message: String) -> void:
	if qa_mode: print("QA_NOTICE: ",message)
	toast_label.text = message
	toast_label.modulate.a = 1
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(toast_label,"modulate:a",0.0,0.6)

func _panel_style(color: Color, border := Color("c1ac78")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
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
	button.add_theme_stylebox_override("normal",_panel_style(Color("101d39"),Color("b7a06e")))
	button.add_theme_stylebox_override("hover",_panel_style(Color("233459"),Color("d5ba80")))
	button.add_theme_stylebox_override("pressed",_panel_style(Color("344465"),Color("e8d39d")))
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
	location.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.065,0.16,0.96)))
	hud.add_child(location)
	var location_stack := VBoxContainer.new()
	location.add_child(location_stack)
	chapter_label = _label(location_stack,"",12,Color("b8c6ae"))
	location_label = _label(location_stack,"",27,Color("f0e6c9"))
	var quest := PanelContainer.new()
	quest.position = Vector2(30,132)
	quest.custom_minimum_size = Vector2(290,96)
	quest.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.065,0.16,0.91),Color("8b7c57")))
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
	map_container.hide()
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 30
	bottom.anchor_right = 0
	bottom.offset_right = 330
	bottom.offset_top = -82
	bottom.offset_bottom = -24
	bottom.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.065,0.16,0.96),Color("b7a06e")))
	hud.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation",20)
	bottom.add_child(bottom_row)
	_label(bottom_row,"エイル".replace("エイル","에일") + "   /   여행자",18,Color("e4d2a1"))
	var face := TextureRect.new()
	var face_atlas := AtlasTexture.new()
	face_atlas.atlas = load("res://assets/ael-portrait.png")
	face_atlas.region = Rect2(560,615,225,250)
	face.texture = face_atlas
	face.custom_minimum_size = Vector2(45,48)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bottom_row.add_child(face)
	bottom_row.move_child(face,0)
	var controls := _label(hud,"WASD 한 걸음 이동   ·   E 대화   ·   Esc 메뉴",13,Color("f0e6cf"))
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.position = Vector2(-470,-42)
	controls.size = Vector2(440,24)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.add_theme_color_override("font_shadow_color",Color("101a36"))
	controls.add_theme_constant_override("shadow_outline_size",6)
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
	_make_history_ui()
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
	dialog_panel.offset_top = -270
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
	var actions := HBoxContainer.new()
	stack.add_child(actions)
	dialog_progress = _label(actions,"",14,Color("49624e"))
	dialog_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var history_button := _button(actions,"지난 대화 · Tab",_toggle_history)
	history_button.custom_minimum_size = Vector2(180,36)
	history_button.focus_mode = Control.FOCUS_NONE
	dialog_next = _button(actions,"다음",_advance_dialog)
	dialog_next.custom_minimum_size = Vector2(240,36)
	dialog_next.focus_mode = Control.FOCUS_NONE
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
	stack.position = Vector2(-180,-260)
	stack.size = Vector2(360,520)
	stack.add_theme_constant_override("separation",12)
	pause_screen.add_child(stack)
	_label(stack,"잠시 쉬어 가기",30,Color("e8dbb4"))
	_label(stack,"F5 저장   ·   F9 불러오기   ·   M 지도\n우클릭 목적지 이동   ·   휠 화면 확대",15,Color("aebfa9"))
	_button(stack,"여행 계속하기",func(): _set_pause(false))
	_button(stack,"지난 대화 보기 · Tab",_toggle_history)
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
	if story.done("morning"): errors.append("Opening committed before conversation finished")
	_qa_finish_dialog()
	if not story.done("morning"): errors.append("Opening did not complete")
	_qa_interact("medicine")
	if has_medicine: errors.append("Parcel available before request")
	_load_map(1,_safe_spawn(1))
	_qa_interact("inn")
	if not story.done("towels") or story.done("water"): errors.append("Inn errand state incorrect")
	_qa_interact("water")
	if not story.errands_done(): errors.append("Morning errands did not complete")
	_qa_interact("water")
	if active_scene != "well_again": errors.append("Repeat errand repeats first scene")
	_load_map(0,_safe_spawn(0))
	_qa_interact("marta")
	if not story.done("request"): errors.append("Delivery request not connected")
	if not _blocked(Vector3(0,0,0)): errors.append("Home table collision missing")
	if _blocked(hero.position): errors.append("Home spawn blocked")
	current_interaction = interactions.filter(func(p): return p.kind == "medicine")[0]
	_activate_interaction()
	while dialog_panel.visible: _advance_dialog()
	if not has_medicine: errors.append("Medicine interaction failed")
	_qa_interact("marta")
	if not story.done("farewell"): errors.append("Farewell missing")
	walker.direction = Vector2i.LEFT
	_set_walk_frame()
	if not hero_sprite.flip_h or hero_sprite.frame < 8 or hero_sprite.frame > 11: errors.append("Left walk does not reuse right gait")
	walker.direction = Vector2i.RIGHT
	_set_walk_frame()
	if not is_equal_approx(hero_sprite.position.y,0.04) or hero_sprite.rotation != Vector3.ZERO: errors.append("Sprite is not foot anchored")
	var prior := hero.position
	Input.action_press("move_right")
	Input.action_press("move_up")
	_physics_process(0.05)
	Input.action_release("move_right")
	Input.action_release("move_up")
	var difference: Vector2 = walker.to_grid(hero.position-prior)
	if abs(difference.x)>0.01 and abs(difference.y)>0.01: errors.append("Diagonal keyboard movement")
	var screen_delta := camera.unproject_position(hero.position)-camera.unproject_position(prior)
	if abs(screen_delta.x)>0.1 and abs(screen_delta.y)>0.1: errors.append("Keyboard movement is diagonal on screen")
	for i in range(5): _physics_process(0.05)
	if not is_equal_approx(prior.distance_to(hero.position),GridWalker.CELL): errors.append("One tap did not finish exactly one step")
	walker.reset(prior)
	hero.position = walker.position
	var before_move := hero.position
	Input.action_press("move_right")
	_physics_process(0.1)
	Input.action_release("move_right")
	if walker.to_grid(hero.position-before_move).x <= 0: errors.append("WASD movement failed")
	_set_click_route(Vector3(6,0,4))
	if not has_walk_target or route.is_empty(): errors.append("Click route missing")
	for waypoint in route:
		if _blocked(waypoint): errors.append("Click route crosses collider")
	for index in range(4):
		_load_map(index,_safe_spawn(index))
		if _blocked(hero.position): errors.append("Blocked map spawn " + str(index))
		for road in map_paths:
			var center := Vector3(road.get_center().x,0,road.get_center().y)
			var right := camera.unproject_position(center+Vector3.RIGHT)-camera.unproject_position(center)
			var down := camera.unproject_position(center+Vector3.BACK)-camera.unproject_position(center)
			if abs(right.y)>0.1 or abs(down.x)>0.1: errors.append("Background roads are diagonal on screen")
		# Every exit must have a reachable approach, not a collider covering its marker.
		for point in interactions:
			if point.kind == "exit" and _blocked(Vector3(point.pos.x,0,point.pos.y),0.1): errors.append("Blocked exit: " + point.title)
		if not _route_reachable(): errors.append("Disconnected route in map " + str(index))
		_set_click_route(hero.position+Vector3(2,0,2))
		var previous := hero.position
		for point in route:
			var route_delta: Vector2 = walker.to_grid(point-previous)
			if abs(route_delta.x)>0.01 and abs(route_delta.y)>0.01: errors.append("Diagonal click route in map " + str(index))
			previous = point
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
	_qa_interact("leon_arrival")
	if not story.done("closing"): errors.append("Closing scene missing")
	var history_key := InputEventKey.new()
	history_key.keycode = KEY_TAB
	history_key.pressed = true
	_input(history_key)
	if not history_panel.visible or not dialogue_history.any(func(line): return line.scene == "delivery") or history_text.text.is_empty(): errors.append("Dialogue history missing")
	_input(history_key)
	if history_panel.visible: errors.append("Tab failed to close history")
	if not _save_game(false): errors.append("Save failed")
	_load_map(0,_safe_spawn(0))
	_load_game()
	if map_id != 3 or not arrived or not has_medicine or not met_leon or not story.done("closing"): errors.append("Save roundtrip failed")
	if old_save.is_empty():
		DirAccess.remove_absolute(SAVE_PATH)
	else:
		var restore := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
		restore.store_string(old_save)
	print("PROLOGUE_QA: ","PASS" if errors.is_empty() else "FAIL", " ",errors)
	get_tree().quit(0 if errors.is_empty() else 1)

func _route_reachable() -> bool:
	# Test the actual screen-aligned navigation grid used by click movement.
	var logical: Vector2 = walker.to_grid(hero.position)/GridWalker.CELL
	var start := Vector2i(roundi(logical.x),roundi(logical.y))
	if navigation.is_point_solid(start): return false
	for point in interactions:
		var center: Vector2 = walker.to_grid(Vector3(point.pos.x,0,point.pos.y))/GridWalker.CELL
		var reachable := false
		for dx in range(-4,5):
			if reachable: break
			for dz in range(-4,5):
				var cell := Vector2i(roundi(center.x)+dx,roundi(center.y)+dz)
				if not navigation.is_in_boundsv(cell) or navigation.is_point_solid(cell): continue
				var world: Vector3 = walker.from_grid(Vector2(cell)*GridWalker.CELL)
				if Vector2(world.x,world.z).distance_to(point.pos) >= 2.2: continue
				if not navigation.get_id_path(start,cell).is_empty():
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
	_load_map(2,Vector3(8,0,3))
	walker.direction = Vector2i.DOWN
	_set_walk_frame()
	toast_label.modulate.a = 0
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var foot := camera.unproject_position(hero.position)
	var compare := Rect2i(clampi(int(foot.x)-120,0,860),clampi(int(foot.y)-210,0,400),420,310)
	get_viewport().get_texture().get_image().get_region(compare).save_png(output+"/06-proportions.png")
	print("CAPTURE_COMPLETE: ",output)
	get_tree().quit()

func _build_navigation() -> void:
	var half_x: float = (abs(walker.axis_x.x)*map_size.x+abs(walker.axis_x.z)*map_size.y)/2.0
	var half_z: float = (abs(walker.axis_z.x)*map_size.x+abs(walker.axis_z.z)*map_size.y)/2.0
	var extent_x := ceili(half_x/GridWalker.CELL)
	var extent_z := ceili(half_z/GridWalker.CELL)
	navigation.region = Rect2i(-extent_x,-extent_z,extent_x*2+1,extent_z*2+1)
	navigation.cell_size = Vector2.ONE*GridWalker.CELL
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in range(navigation.region.position.x,navigation.region.end.x):
		for y in range(navigation.region.position.y,navigation.region.end.y):
			var world_point: Vector3 = walker.from_grid(Vector2(x,y)*GridWalker.CELL)
			navigation.set_point_solid(Vector2i(x,y),_blocked(world_point,0.37))

func _set_click_route(target: Vector3) -> void:
	var start_position: Vector3 = walker.target if walker.moving else hero.position
	var logical_start: Vector2 = walker.to_grid(start_position)/GridWalker.CELL
	var logical_end: Vector2 = walker.to_grid(target)/GridWalker.CELL
	var start := Vector2i(roundi(logical_start.x),roundi(logical_start.y))
	var end := Vector2i(roundi(logical_end.x),roundi(logical_end.y))
	if not navigation.is_in_boundsv(start) or not navigation.is_in_boundsv(end): return
	if navigation.is_point_solid(start) or navigation.is_point_solid(end): return
	var points := navigation.get_point_path(start,end)
	route.clear()
	for point in points: route.append(walker.from_grid(point))
	if not route.is_empty():
		has_walk_target = true

func _make_binding_ui() -> void:
	binding_panel = PanelContainer.new()
	binding_panel.position = Vector2(820,120)
	binding_panel.custom_minimum_size = Vector2(380,440)
	binding_panel.add_theme_stylebox_override("panel",_panel_style(Color("101d39")))
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
	if event.keycode in [KEY_F5,KEY_F9,KEY_SPACE,KEY_ESCAPE,KEY_SHIFT,KEY_M,KEY_TAB]:
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
			var patch := _cylinder(Vector3(x,0.025,z),rng.randf_range(0.25,0.9),0.025,Color("c6d2cd"))
			_texture_surface(patch,1)

func _key_name(action: String) -> String:
	return OS.get_keycode_string(InputMap.action_get_events(action)[0].physical_keycode)

func _prepare_surface_materials() -> void:
	if not terrain_atlas: return
	var image := terrain_atlas.get_image()
	if image.is_compressed(): image.decompress()
	var width := image.get_width()/3
	var height := image.get_height()/2
	for index in range(6):
		var region := image.get_region(Rect2i((index%3)*width,(index/3)*height,width,height))
		var material := StandardMaterial3D.new()
		material.albedo_texture = ImageTexture.create_from_image(region)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * (0.24 if index == 1 else 0.42)
		material.roughness = 1.0
		material.metallic_specular = 0.05
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		terrain_materials.append(material)

func _texture_surface(mesh: MeshInstance3D, index: int) -> void:
	if terrain_materials.size() > index:
		mesh.material_override = terrain_materials[index]

func _sprite_bounds(texture: Texture2D, columns: int, rows: int, frame: int) -> Rect2i:
	var image := texture.get_image()
	if image.is_compressed(): image.decompress()
	var width := image.get_width()/columns
	var height := image.get_height()/rows
	var region := Rect2i((frame%columns)*width,(frame/columns)*height,width,height)
	var used := image.get_region(region).get_used_rect()
	return used

func _anchor_sprite_feet(sprite: Sprite3D, columns: int, rows: int) -> void:
	var height := float(sprite.texture.get_height())/rows
	var used := _sprite_bounds(sprite.texture,columns,rows,sprite.frame)
	var padding := height-used.end.y
	sprite.pixel_size = 1.95/maxf(1,used.size.y)
	sprite.offset = Vector2(0,height/2-padding)
	sprite.position = Vector3(0,0.04,0)

func _prepare_walk_offsets() -> void:
	foot_offsets.clear()
	var height := float(walk_atlas.get_height())/4
	for frame in range(16):
		var used := _sprite_bounds(walk_atlas,4,4,frame)
		foot_offsets.append(height/2 - height+used.end.y)

func _beam(a: Vector3, b: Vector3, thickness := 0.16) -> MeshInstance3D:
	var mesh := _box((a+b)/2,Vector3(thickness,a.distance_to(b),thickness),Color("45372c"))
	mesh.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	_texture_surface(mesh,3)
	return mesh

func _barrel(x: float, z: float) -> void:
	obstacles.append(Rect2(x-0.38,z-0.38,0.76,0.76))
	var barrel := _cylinder(Vector3(x,0.44,z),0.4,0.88,Color("67503a"))
	_texture_surface(barrel,3)
	for y in [0.15,0.7]:
		_cylinder(Vector3(x,y,z),0.415,0.055,Color("3e4247"))
	var cap := _cylinder(Vector3(x,0.91,z),0.41,0.08,Color("e2e4ef"))
	_texture_surface(cap,1)

func _house_details(x: float, z: float, width: float, depth: float) -> Array[MeshInstance3D]:
	var pieces: Array[MeshInstance3D] = []
	var front := z+depth/2+0.15
	var triangle := SurfaceTool.new()
	triangle.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [Vector3(x-width/2,3.1,front-0.04),Vector3(x+width/2,3.1,front-0.04),Vector3(x,5.22,front-0.04)]:
		triangle.add_vertex(vertex)
	triangle.generate_normals()
	var gable := MeshInstance3D.new()
	gable.mesh = triangle.commit()
	_texture_surface(gable,5)
	map_root.add_child(gable)
	pieces.append(gable)
	for y in [0.75,2.75,3.1]:
		var horizontal := _box(Vector3(x,y,front),Vector3(width+0.2,0.16,0.22),Color("4a3a2d"))
		_texture_surface(horizontal,3)
		pieces.append(horizontal)
	for offset in [-width/2+0.1,-width/4,0.0,width/4,width/2-0.1]:
		pieces.append(_beam(Vector3(x+offset,0.7,front),Vector3(x+offset,3.1,front),0.14))
	pieces.append(_beam(Vector3(x-width/2-0.35,3.05,front),Vector3(x,5.25,front),0.22))
	pieces.append(_beam(Vector3(x,5.25,front),Vector3(x+width/2+0.35,3.05,front),0.22))
	pieces.append(_beam(Vector3(x,3.1,front),Vector3(x,5.22,front),0.16))
	for offset in [-width*0.32,width*0.32]:
		var window := _box(Vector3(x+offset,1.7,front+0.08),Vector3(0.65,0.9,0.06),Color("f3bd63"))
		var warm := _material(Color("f3bd63")).duplicate() as StandardMaterial3D
		warm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		window.material_override = warm
		pieces.append(window)
		pieces.append(_box(Vector3(x+offset,1.7,front+0.13),Vector3(0.07,0.95,0.08),Color("49392c")))
		pieces.append(_box(Vector3(x+offset,1.7,front+0.14),Vector3(0.7,0.07,0.08),Color("49392c")))
		var sill := _box(Vector3(x+offset,1.17,front+0.14),Vector3(0.9,0.12,0.5),Color("6b6053"))
		_texture_surface(sill,2)
		pieces.append(sill)
	# Side-facing timber and masonry give the fixed oblique camera a readable building volume.
	for side in [-1,1]:
		for offset in [-depth/2+0.2,0.0,depth/2-0.2]:
			pieces.append(_beam(Vector3(x+side*(width/2+0.06),0.7,z+offset),Vector3(x+side*(width/2+0.06),3.1,z+offset),0.16))
		for y in [0.75,2.75]:
			pieces.append(_box(Vector3(x+side*(width/2+0.06),y,z),Vector3(0.17,0.16,depth),Color("4a3a2d")))
	_barrel(x+width/2+0.8,front+0.15)
	_barrel(x-width/2-0.7,front+0.5)
	var sign_post := _box(Vector3(x+width/2+0.5,2.7,front),Vector3(1.4,0.13,0.13),Color("4a3a2d"))
	pieces.append(sign_post)
	var sign_board := _box(Vector3(x+width/2+1,2.1,front),Vector3(0.9,0.6,0.13),Color("67523b"))
	_texture_surface(sign_board,3)
	pieces.append(sign_board)
	return pieces

func _stone_well(center: Vector2, covered: bool) -> void:
	var radius := 1.1 if covered else 0.8
	for layer in range(2):
		for i in range(12):
			var angle := TAU*(float(i)+(0.5 if layer == 1 else 0.0))/12
			var block := _box(Vector3(center.x+cos(angle)*radius,0.25+layer*0.36,center.y+sin(angle)*radius),Vector3(0.55,0.36,0.38),Color("8b8d80"))
			block.rotation.y = -angle+PI/2
			_texture_surface(block,2)
	var water := _cylinder(Vector3(center.x,0.12,center.y),radius,0.08,Color("263e50"))
	water.material_override = _material(Color("263e50"))
	if covered:
		for side in [-1,1]:
			var pole := _box(Vector3(center.x+side*1.45,1.5,center.y),Vector3(0.16,3,0.16),Color("503e31"))
			_texture_surface(pole,3)
		_roof(Vector3(center.x,3,center.y),3.7,2.3,0.9,Color("6d747e"))
		_roof(Vector3(center.x,3.1,center.y),3.5,1.8,0.9,Color("e1ebe0"))

func _border_gate(center: Vector2) -> void:
	for side in [-1,1]:
		var x: float = center.x+side*3.5
		var pillar := _box(Vector3(x,1.3,center.y),Vector3(0.9,2.6,0.9),Color("8c8e88"),true)
		_texture_surface(pillar,2)
		var cap := _box(Vector3(x,2.65,center.y),Vector3(1.1,0.18,1.1),Color("dfe4f5"))
		_texture_surface(cap,1)
		var post := _box(Vector3(x-side*0.7,2.3,center.y),Vector3(0.1,4.6,0.1),Color("554631"))
		_texture_surface(post,3)
		_box(Vector3(x-side*0.7,4.4,center.y),Vector3(0.9,0.1,0.14),Color("bca36a"))
		_box(Vector3(x-side*0.7,3.55,center.y),Vector3(0.8,1.6,0.07),Color("172b59"))
		var emblem := _box(Vector3(x-side*0.7,3.7,center.y+0.06),Vector3(0.2,0.2,0.05),Color("d2b56e"))
		emblem.rotation.z = PI/4

func _run_compare_capture() -> void:
	_new_game()
	_load_map(2,Vector3(8,0,3))
	walker.direction = Vector2i.DOWN
	_set_walk_frame()
	toast_label.modulate.a = 0
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var foot := camera.unproject_position(hero.position)
	var compare := Rect2i(clampi(int(foot.x)-120,0,860),clampi(int(foot.y)-210,0,400),420,310)
	get_viewport().get_texture().get_image().get_region(compare).save_png(ProjectSettings.globalize_path("res://../docs/screenshots/06-proportions.png"))
	print("COMPARE_CAPTURE_COMPLETE")
	get_tree().quit()

func _run_walk_capture() -> void:
	_new_game()
	has_medicine = true
	_load_map(1,Vector3(0,0,10))
	paused = true
	toast_label.modulate.a = 0
	var output := "/private/tmp/springbound-walk-frames"
	DirAccess.make_dir_recursive_absolute(output)
	await get_tree().create_timer(0.3).timeout
	var frame_index := 0
	var center := camera.unproject_position(hero.position+Vector3(0,0.9,0))
	var crop := Rect2i(int(center.x)-240,int(center.y)-170,480,340)
	for direction in [Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN]:
		for step_index in range(2):
			if not walker.begin(direction,_blocked):
				push_error("Walk preview route is blocked")
				get_tree().quit(1)
				return
			for sample in range(8):
				walker.advance(GridWalker.STEP_SECONDS/8.0)
				hero.position = walker.position
				_set_walk_frame()
				_update_occlusion()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().get_region(crop).save_png(output+"/frame-%03d.png"%frame_index)
				frame_index += 1
	print("WALK_CAPTURE_COMPLETE: ",frame_index," frames")
	get_tree().quit()

func _near_story_cast(pos: Vector2) -> bool:
	for point in [Vector2(-12,-7),Vector2(5,12),Vector2(-5,6.5),Vector2(12,-3.5),Vector2(3.5,-13)]:
		if pos.distance_to(point) < 2.8: return true
	return false

func _story_npc(npc_name: String, pos: Vector3, kind: String) -> void:
	# Import a board's front pose at runtime. Flood only the connected paper
	# background, preserving enclosed cream clothes, then anchor the opaque feet.
	var key: String = CAST[npc_name]
	if not cast_textures.has(key):
		var source: Texture2D = load("res://story/cast/" + key + "-board-v1.png")
		var image := source.get_image().get_region(Rect2i(600,150,295,390))
		image.convert(Image.FORMAT_RGBA8)
		var width := image.get_width()
		var height := image.get_height()
		var visited := PackedByteArray()
		visited.resize(width*height)
		var queue: Array[Vector2i] = []
		for x in range(width):
			queue.append(Vector2i(x,0))
			queue.append(Vector2i(x,height-1))
		for y in range(height):
			queue.append(Vector2i(0,y))
			queue.append(Vector2i(width-1,y))
		var cursor := 0
		while cursor < queue.size():
			var cell := queue[cursor]
			cursor += 1
			if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height: continue
			var index := cell.y*width+cell.x
			if visited[index]: continue
			visited[index] = 1
			var color := image.get_pixelv(cell)
			if color.r < 0.76 or color.g < 0.72 or color.b < 0.62: continue
			image.set_pixelv(cell,Color.TRANSPARENT)
			for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: queue.append(cell+offset)
		var used := image.get_used_rect()
		cast_textures[key] = ImageTexture.create_from_image(image.get_region(used))
	var actor := Node3D.new()
	actor.name = key
	actor.position = pos
	map_root.add_child(actor)
	var sprite := Sprite3D.new()
	sprite.texture = cast_textures[key]
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var character_height := 1.65 if key == "nia" else 2.35
	sprite.pixel_size = character_height / sprite.texture.get_height()
	sprite.offset.y = sprite.texture.get_height()/2.0
	sprite.position.y = 0.04
	actor.add_child(sprite)
	_marker(pos+Vector3(0,character_height*CAMERA_OFFSET.length()/CAMERA_OFFSET.z+0.4,0),npc_name)
	obstacles.append(Rect2(pos.x-0.35,pos.z-0.35,0.7,0.7))
	_interact(Vector2(pos.x,pos.z),npc_name+"와 이야기하기",kind)

func _make_history_ui() -> void:
	history_panel = PanelContainer.new()
	history_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	history_panel.offset_left = 100
	history_panel.offset_top = 70
	history_panel.offset_right = -100
	history_panel.offset_bottom = -70
	history_panel.add_theme_stylebox_override("panel",_panel_style(Color("101d39")))
	ui_root.add_child(history_panel)
	var stack := VBoxContainer.new()
	history_panel.add_child(stack)
	_label(stack,"여행 중 나눈 이야기",27,Color("efddb4"))
	_label(stack,"이번에 이어서 플레이한 대화 기록 · Tab / Esc 닫기",14,Color("b7c5b9"))
	history_text = RichTextLabel.new()
	history_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_text.add_theme_font_override("normal_font",body_font)
	history_text.add_theme_font_size_override("normal_font_size",20)
	history_text.add_theme_color_override("default_color",Color("ece4cf"))
	history_text.add_theme_constant_override("line_separation",8)
	stack.add_child(history_text)
	var close := _button(stack,"이야기로 돌아가기",_toggle_history)
	close.focus_mode = Control.FOCUS_NONE
	history_panel.hide()

func _toggle_history() -> void:
	if history_panel.visible:
		history_panel.hide()
		if is_instance_valid(history_return_focus): history_return_focus.grab_focus()
		return
	history_return_focus = get_viewport().gui_get_focus_owner()
	pending_step = Vector2i.ZERO
	has_walk_target = false
	route.clear()
	var text := ""
	var prior_scene := "__none__"
	for line in dialogue_history:
		if line.scene != prior_scene:
			text += "\n── " + story.title(line.scene) + " ──\n\n"
			prior_scene = line.scene
		text += line.speaker + "\n" + line.text + "\n\n"
	history_text.text = text if not text.is_empty() else "아직 나눈 이야기가 없습니다."
	history_panel.show()
	ui_root.move_child(history_panel,-1)
	history_text.call_deferred("scroll_to_line",maxi(0,history_text.get_line_count()-1))


func _qa_finish_dialog() -> void:
	var budget := 1000
	while dialog_panel.visible and budget > 0:
		_advance_dialog()
		budget -= 1
	assert(budget > 0,"Dialogue callback loop")

func _qa_interact(kind: String) -> void:
	current_interaction = interactions.filter(func(point): return point.kind == kind)[0]
	_activate_interaction()
	_qa_finish_dialog()

func _run_story_capture() -> void:
	qa_mode = true
	_new_game()
	for i in range(5): _advance_dialog()
	await _story_screenshot("07-story-home")
	_qa_finish_dialog()
	_load_map(1,Vector3(-3,0,11))
	await _story_screenshot("08-story-village")
	_play_scene("inn_first")
	for i in range(6): _advance_dialog()
	await _story_screenshot("09-story-orman")
	_qa_finish_dialog()
	_load_map(2,Vector3(8,0,5))
	_play_scene("leon_first")
	for i in range(10): _advance_dialog()
	await _story_screenshot("10-story-leon")
	_qa_finish_dialog()
	_load_map(3,Vector3(5,0,1))
	_play_scene("delivery")
	for i in range(8): _advance_dialog()
	await _story_screenshot("11-story-delivery")
	_qa_finish_dialog()
	_play_scene("closing")
	_qa_finish_dialog()
	_toggle_history()
	await _story_screenshot("12-story-history")
	get_tree().quit()

func _story_screenshot(filename: String) -> void:
	for frame in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../docs/screenshots/"+filename+".png")
	print("STORY_CAPTURE: ",filename)


func _environment_prop(id: String, pos: Vector3) -> void:
	var scene: PackedScene = load("res://assets/environment/scenes/"+id+".tscn")
	var node := scene.instantiate() as Node3D
	node.position = pos
	map_root.add_child(node)
	for rect in node.get_meta("grid_obstacles",[]):
		obstacles.append(Rect2(pos.x+float(rect[0]),pos.z+float(rect[1]),float(rect[2]),float(rect[3])))

func _input(event: InputEvent) -> void:
	# Tab must reach the history action before GUI keyboard focus consumes it.
	if event is InputEventKey and event.pressed and not event.echo and rebind_action.is_empty():
		if (event.keycode == KEY_TAB and started and not transitioning) or (event.keycode == KEY_ESCAPE and history_panel.visible):
			_toggle_history()
			get_viewport().set_input_as_handled()
