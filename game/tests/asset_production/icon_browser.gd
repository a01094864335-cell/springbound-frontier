extends Control
const Bank = preload("res://assets/production/icons/icon_bank.gd")
func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var title := Label.new()
	title.text = "49 resumed inventory icons - first pass / gameplay not connected"
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	column.add_child(grid)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/icons/catalog.json"))
	for entry in entries:
		var card := VBoxContainer.new()
		grid.add_child(card)
		var icon := TextureRect.new()
		icon.texture = Bank.texture(entry.id)
		icon.custom_minimum_size = Vector2(180,150)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(icon)
		var label := Label.new()
		label.text = entry.name
		card.add_child(label)
