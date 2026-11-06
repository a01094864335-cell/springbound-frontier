extends Node
## Presentation only: never writes quest, inventory or combat progress.
const Motion = preload("res://scripts/prologue_motion.gd")
var world: Node
var focus := Vector3.ZERO
var focused := false
var bands: Node3D
var action_prop: Node3D

func setup(owner_world: Node) -> void:
	world = owner_world

func map_ready() -> void:
	focused = false
	if world.map_id == 1:
		world._marker(Vector3(7,3,-4),"여관 · 오르만")
		world._marker(Vector3(-8,3,1),"마르타의 집")
		world._marker(Vector3(0,2,6.2),"마을 우물")
	if world.map_id == 2 and is_instance_valid(world.injured_leon):
		var sprite: Sprite3D = world.injured_leon.get_node("Sprite")
		Motion.render(sprite,"event-npc-leon-03",0.0,2.3)
		sprite.scale.y = 1.0
		sprite.rotation.z = 0.0
		bands = Node3D.new()
		world.injured_leon.add_child(bands)
		var band := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.32,0.13,0.15)
		band.mesh = mesh
		band.position = Vector3(-0.13,0.29,0.08)
		band.material_override = world._material(Color("d4b4a4"))
		bands.add_child(band)
		world._box(Vector3(10.5,0.15,3.1),Vector3(0.9,0.3,0.8),Color("748282"))

func begin(scene: String) -> void:
	focused = false
	var point: Dictionary = {}
	var kinds := {"opening":"marta","request":"marta","farewell":"marta","well_first":"water","inn_first":"inn","delivery":"delivery","closing":"leon_arrival"}
	var kind: String = kinds.get(scene, "leon" if scene.begins_with("leon_") or scene == "sword_loan" else "")
	for p in world.interactions:
		if p.kind == kind: point = p; break
	if not point.is_empty():
		focus = (world.hero.position+Vector3(point.pos.x,0,point.pos.y))*0.5
		focused = true
		var diff: Vector2 = point.pos-Vector2(world.hero.position.x,world.hero.position.z)
		world.walker.direction = (Vector2i.LEFT if diff.x < 0 else Vector2i.RIGHT) if absf(diff.x)>absf(diff.y) else (Vector2i.UP if diff.y<0 else Vector2i.DOWN)
		world._set_walk_frame()
	if scene == "sword_loan" and is_instance_valid(world.injured_leon):
		Motion.render(world.injured_leon.get_node("Sprite"),"event-npc-leon-04",0.6,2.3)
	if scene == "well_first":
		action_prop = world._box(world.hero.position+Vector3(0.4,0.35,0),Vector3(0.45,0.6,0.45),Color("9f8566"))
		var tween := create_tween().set_loops(2)
		tween.tween_property(action_prop,"position:y",0.1,0.35)
		tween.tween_property(action_prop,"position:y",0.55,0.35)
	elif scene in ["inn_first","medicine","delivery","leon_bridge","sword_loan"]:
		var color := Color("eee5cf") if scene in ["inn_first","leon_bridge"] else Color("b1bdab")
		action_prop = world._box(world.hero.position+Vector3(0.3,0.9,0),Vector3(0.4,0.18,0.3),color)
		var tween := create_tween()
		tween.tween_property(action_prop,"position",focus+Vector3(0,0.9,0),0.65)

func finish() -> void:
	focused = false
	if is_instance_valid(action_prop): action_prop.queue_free()
	action_prop = null
