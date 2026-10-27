extends SceneTree

const Walker = preload("res://scripts/grid_walker.gd")

func _initialize() -> void:
	var walker = Walker.new()
	walker.reset(Vector3(0,0,0))
	var empty := func(_point): return false
	assert(not walker.begin(Vector2i(1,1),empty),"Diagonal steps must be rejected")
	assert(walker.begin(Vector2i.RIGHT,empty))
	assert(not walker.begin(Vector2i.UP,empty),"Cannot turn in the middle of a step")
	var frames := {}
	for i in range(12):
		walker.advance(0.02)
		frames[walker.animation_column()] = true
		assert(is_zero_approx(walker.position.y),"Feet cannot bob vertically")
		assert(is_zero_approx(walker.position.z),"Right step cannot drift on the other axis")
	assert(walker.position == Vector3(Walker.CELL,0,0),"Tap must complete exactly one grid step")
	assert(not walker.moving)
	assert(walker.animation_column() == 0,"Stopped character must use idle pose")
	assert(frames.has(1) and frames.has(2) and frames.has(3),"Walk must use distinct leg frames")
	var wall := func(point): return point.x > Walker.CELL+0.1
	assert(not walker.begin(Vector2i.RIGHT,wall),"Cannot cross a collider")
	assert(walker.position == Vector3(Walker.CELL,0,0))
	for direction in [Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN]:
		assert(walker.begin(direction,empty))
		walker.advance(1.0)
	assert(walker.position == Vector3.ZERO,"Four cardinal steps must return exactly to origin")
	print("GRID_WALKER_QA: PASS (cardinal steps, collision, exact endpoints, grounded feet, leg frames)")
	quit()
