extends Control
signal destination_selected(id: String)
var destinations: Array=[]
func configure(values: Array) -> void:
	destinations=values.duplicate(true)
	for child in get_children():child.queue_free()
	for i in range(destinations.size()):
		var button:=Button.new()
		button.text=str(destinations[i])
		button.position=point(i)+Vector2(-55,14)
		button.custom_minimum_size=Vector2(110,36)
		var id: String=str(destinations[i])
		button.pressed.connect(func():destination_selected.emit(id))
		add_child(button)
	queue_redraw()
func point(i: int) -> Vector2:
	return Vector2(75+(i%4)*140,55+floori(i/4.0)*90+(i%2)*40)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("263b3e"))
	for i in range(destinations.size()-1):draw_line(point(i),point(i+1),Color("bba36e"),3)
	for i in range(destinations.size()):
		draw_circle(point(i),8,Color("d3c29c"))
		draw_circle(point(i),4,Color("355e59"))
