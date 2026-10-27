extends Control

var world: Node

func _draw() -> void:
	if world == null:
		return
	var box := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	var bounds: Vector2 = world.map_size
	var scale_map: Vector2 = box.size / bounds
	for path: Rect2 in world.map_paths:
		var p: Vector2 = (path.position + bounds / 2.0) * scale_map + box.position
		draw_rect(Rect2(p, path.size * scale_map), Color("8d9d8e"))
	for block: Rect2 in world.obstacles:
		var p: Vector2 = (block.position + bounds / 2.0) * scale_map + box.position
		draw_rect(Rect2(p, block.size * scale_map), Color("455b54"))
	for point: Dictionary in world.interactions:
		var p: Vector2 = (point.pos + bounds / 2.0) * scale_map + box.position
		draw_circle(p, 3.0, Color("d8b374") if point.kind == "exit" else Color("a8d4b7"))
	var player_pos: Vector2 = (Vector2(world.hero.position.x, world.hero.position.z) + bounds / 2.0) * scale_map + box.position
	draw_circle(player_pos, 5.0, Color("fff3d9"))
	draw_arc(player_pos, 8, 0, TAU, 24, Color("e6be79"), 1.2)

func _panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("233d38")
	style.border_color = Color("8f9b7a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style
