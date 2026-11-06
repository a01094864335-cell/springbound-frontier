extends Node
## Click a person or doorway to approach a reachable cell, then interact normally.
var world: Node
var pending: Dictionary = {}
var marker: MeshInstance3D
var lifetime := 0.0
var breadcrumbs: Node3D

func setup(owner_world: Node) -> void:
	world = owner_world

func cancel() -> void:
	pending = {}
	if is_instance_valid(breadcrumbs): breadcrumbs.queue_free()
	breadcrumbs = null
	if is_instance_valid(marker): marker.hide()

func show_marker(pos: Vector3, valid: bool) -> void:
	if not is_instance_valid(marker) or marker.get_parent() != world.map_root:
		marker = MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.30
		mesh.outer_radius = 0.39
		marker.mesh = mesh
		world.map_root.add_child(marker)
	marker.position = pos + Vector3(0,0.12,0)
	marker.material_override = world._material(Color("efd492") if valid else Color("e98278"))
	marker.show()
	lifetime = 4.0
	if is_instance_valid(breadcrumbs): breadcrumbs.queue_free()
	breadcrumbs = Node3D.new()
	world.map_root.add_child(breadcrumbs)
	if valid:
		for i in range(1,mini(world.route.size(),40),2):
			var dot := MeshInstance3D.new()
			var shape := CylinderMesh.new()
			shape.top_radius = 0.07
			shape.bottom_radius = 0.07
			shape.height = 0.015
			dot.mesh = shape
			dot.material_override = marker.material_override
			dot.position = world.route[i]+Vector3(0,0.09,0)
			breadcrumbs.add_child(dot)

func approach(point: Dictionary) -> bool:
	var origin: Vector3 = world.walker.target if world.walker.moving else world.hero.position
	var start := Vector2i(roundi(origin.x),roundi(origin.z))
	var best := Vector3.INF
	var score := INF
	for x in range(floori(point.pos.x)-3,ceili(point.pos.x)+4):
		for z in range(floori(point.pos.y)-3,ceili(point.pos.y)+4):
			var cell := Vector2i(x,z)
			var distance := Vector2(x,z).distance_to(point.pos)
			if distance > 2.1 or not world.navigation.is_in_boundsv(cell) or world.navigation.is_point_solid(cell): continue
			var path: PackedVector2Array = world.navigation.get_point_path(start,cell)
			if path.is_empty(): continue
			var cost := path.size()+distance*0.2
			if cost < score:
				score = cost
				best = Vector3(x,0,z)
	if best == Vector3.INF:
		world._toast("그곳에는 다가갈 수 없어요. 다른 쪽에서 접근해 보세요.")
		return false
	world._set_click_route(best)
	pending = point
	show_marker(best,true)
	world._toast(point.title + " · 다가가는 중")
	return true

func click(screen: Vector2) -> void:
	cancel()
	var chosen: Dictionary = {}
	var nearest := 52.0
	for point in world.interactions:
		var pos := Vector3(point.pos.x,0.8,point.pos.y)
		var pixel: Vector2 = world.camera.unproject_position(pos)
		var distance := screen.distance_to(pixel)
		if distance < nearest:
			chosen = point
			nearest = distance
	if not chosen.is_empty():
		approach(chosen)
		return
	var ground = Plane(Vector3.UP,0).intersects_ray(world.camera.project_ray_origin(screen),world.camera.project_ray_normal(screen))
	if ground == null: return
	world._set_click_route(ground)
	if world.has_walk_target:
		show_marker(world.route.back(),true)
	else:
		show_marker(ground,false)
		world._toast("지나갈 수 없는 곳이에요. 길이나 사람을 클릭해 주세요.")

func tick(delta: float) -> void:
	lifetime -= delta
	if is_instance_valid(marker) and lifetime <= 0:
		marker.hide()
		if is_instance_valid(breadcrumbs): breadcrumbs.hide()
	if pending.is_empty() or world.walker.moving or world.has_walk_target: return
	var target := pending
	pending = {}
	if Vector2(world.hero.position.x,world.hero.position.z).distance_to(target.pos) < 2.35:
		world.current_interaction = target
		world._activate_interaction()
	else:
		approach(target)

func _process(_delta: float) -> void:
	if world == null or not world.started or world.paused or world.dialog_panel.visible or world.transitioning or world.battle_view.busy() or world.history_panel.visible or world.completion_panel.visible:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	var mouse: Vector2 = world.get_viewport().get_mouse_position()
	var over := false
	for point in world.interactions:
		var screen: Vector2 = world.camera.unproject_position(Vector3(point.pos.x,0.8,point.pos.y))
		if screen.distance_to(mouse) < 52.0: over = true; break
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if over else Input.CURSOR_ARROW)
