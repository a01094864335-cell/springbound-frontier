extends Node
## Follow traversed cells; never interpolate across walls or change story progress.
const Motion = preload("res://scripts/prologue_motion.gd")
const Walker = preload("res://scripts/grid_walker.gd")
var world: Node
var actor: Node3D
var sprite: Sprite3D
var walker = Walker.new()
var trail: Array[Vector3] = []
var last_hero := Vector3.INF
var active := false
var resting := false
var rest_destination := Vector3.ZERO

func setup(owner_world: Node) -> void:
	world = owner_world

func reset_for_map() -> void:
	if is_instance_valid(actor): actor.queue_free()
	actor = null
	trail.clear()
	resting = false
	active = world.met_leon and not world.arrived and world.map_id in [1,2,3]
	if not active: return
	actor = world._actor(1)
	actor.name = "LeonCompanion"
	world.map_root.add_child(actor)
	sprite = actor.get_node("Sprite")
	Motion.render(sprite,"event-npc-leon-03",0.0,2.3)
	walker.axis_x = world.walker.axis_x
	walker.axis_z = world.walker.axis_z
	var origin: Vector3 = world.hero.position
	var spawn := origin
	for direction in [Vector3.BACK,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD]:
		var candidate: Vector3 = origin+direction*2.0
		if not world._blocked(candidate):
			spawn = candidate
			break
	walker.reset(spawn)
	actor.position = walker.position
	last_hero = origin

func tick(delta: float) -> void:
	if not active or not is_instance_valid(actor): return
	if resting:
		_tick_rest(delta)
		return
	var hero_pos: Vector3 = world.walker.position
	if not world.walker.moving and hero_pos.distance_to(last_hero) > 0.1:
		trail.append(last_hero)
		last_hero = hero_pos
	if not walker.moving and trail.size() > 1:
		if walker.position.distance_to(trail[0]) < 0.1:
			trail.pop_front()
		if trail.size() > 1:
			var destination := trail[0]
			var grid: AStarGrid2D = world.navigation
			var start := Vector2i(roundi(walker.position.x),roundi(walker.position.z))
			var finish := Vector2i(roundi(destination.x),roundi(destination.z))
			var path := grid.get_point_path(start,finish)
			if path.size() > 1:
				var step := Vector2i(roundi(path[1].x-path[0].x),roundi(path[1].y-path[0].y))
				walker.begin(step,world._blocked,0.24)
	walker.advance(delta)
	actor.position = walker.position
	if walker.moving:
		sprite.position.y = sin(walker.progress*PI)*0.035
	else:
		sprite.position.y = 0
	var direction_id := Motion.direction(Vector3(walker.direction.x,0,walker.direction.y))
	var clip := "motion-npc-leon-1-%d" % direction_id if walker.moving else "event-npc-leon-03"
	Motion.render(sprite,clip,walker.progress if walker.moving else 0.0,2.3)
	sprite.rotation.z=sin(walker.progress*TAU)*0.025 if walker.moving else 0.0

func rest_at(destination: Vector3) -> void:
	if not is_instance_valid(actor): return
	resting = true
	rest_destination = destination
	trail.clear()

func _tick_rest(delta: float) -> void:
	if not walker.moving and walker.position.distance_to(rest_destination) > 0.1:
		var start := Vector2i(roundi(walker.position.x),roundi(walker.position.z))
		var finish := Vector2i(roundi(rest_destination.x),roundi(rest_destination.z))
		var path: PackedVector2Array = world.navigation.get_point_path(start,finish)
		if path.size() > 1:
			walker.begin(Vector2i(roundi(path[1].x-path[0].x),roundi(path[1].y-path[0].y)),world._blocked,0.3)
	walker.advance(delta)
	actor.position = walker.position
	var clip := "motion-npc-leon-1-%d" % Motion.direction(Vector3(walker.direction.x,0,walker.direction.y)) if walker.moving else "event-npc-leon-03"
	Motion.render(sprite,clip,walker.progress if walker.moving else 0.0,2.3)
