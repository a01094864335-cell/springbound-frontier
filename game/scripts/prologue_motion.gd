extends RefCounted
## Consume PR14's active SpriteFrames/rect/foot-anchor mapping, never raw board cells.
const Bank = preload("res://assets/production/motions/motion_bank.gd")
static func direction(vector: Vector3) -> int:
	if absf(vector.x)>absf(vector.z): return 2 if vector.x<0 else 3
	return 1 if vector.z<0 else 0
static func render(sprite: Sprite3D, id: String, phase: float, height := 2.35) -> void:
	var row := Bank.entry(id)
	var frames := Bank.frames(id)
	if row.is_empty() or frames==null: return
	var count := frames.get_frame_count(id)
	var index := clampi(int(phase*count),0,count-1)
	var rect: Array = row.rects[index]
	var anchor: Array = row.anchors[index]
	sprite.frame = 0
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.texture = frames.get_frame_texture(id,index)
	sprite.pixel_size = height/maxf(1,float(row.rects[0][3])*.90)
	sprite.offset = Vector2(float(rect[2])/2-float(anchor[0]),float(anchor[1])-float(rect[3])/2)
	sprite.flip_h = false
	sprite.set_meta("active_clip",id)
