extends RefCounted

const CELL := 0.5
const STEP_SECONDS := 0.20

var position := Vector3.ZERO
var origin := Vector3.ZERO
var target := Vector3.ZERO
var direction := Vector2i.DOWN
var progress := 0.0
var moving := false
var duration := STEP_SECONDS
var axis_x := Vector3.RIGHT
var axis_z := Vector3.BACK

func reset(value: Vector3) -> void:
	var logical := to_grid(value)
	position = from_grid(Vector2(snappedf(logical.x,CELL),snappedf(logical.y,CELL)))
	origin = position
	target = position
	progress = 0
	moving = false

func begin(value: Vector2i, blocked: Callable, seconds := STEP_SECONDS) -> bool:
	if moving or absi(value.x)+absi(value.y) != 1:
		return false
	direction = value
	var destination := position + (axis_x*value.x+axis_z*value.y)*CELL
	# Check the swept segment as well as the endpoint to avoid stepping through thin rails.
	for fraction in [0.25,0.5,0.75,1.0]:
		if blocked.call(position.lerp(destination,fraction)):
			return false
	origin = position
	target = destination
	progress = 0
	duration = seconds
	moving = true
	return true

func advance(delta: float) -> void:
	if not moving:
		return
	progress = minf(1.0,progress+delta/duration)
	position = origin.lerp(target,progress)
	if progress >= 1.0:
		position = target
		moving = false

func animation_column() -> int:
	if not moving:
		return 0
	# Actual leg poses, not vertical movement of a still image.
	return [1,2,3,2][mini(3,int(progress*4))]

func to_grid(value: Vector3) -> Vector2:
	return Vector2(value.dot(axis_x),value.dot(axis_z))

func from_grid(value: Vector2) -> Vector3:
	return axis_x*value.x+axis_z*value.y
