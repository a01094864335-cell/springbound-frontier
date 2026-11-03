extends RefCounted
static var _entries: Dictionary = {}
static var _resources: Dictionary = {}
static func entry(id: String) -> Dictionary:
	if _entries.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/motions/catalog.json"))
		for row in data.entries:
			_entries[row.id] = row
	return _entries.get(id,{})
static func frames(id: String) -> SpriteFrames:
	var row := entry(id)
	if row.is_empty():return null
	if not _resources.has(row.path):_resources[row.path] = load(row.path)
	return _resources[row.path]
static func sprite(id: String) -> AnimatedSprite3D:
	var data: SpriteFrames = frames(id)
	if data==null:return null
	var node := AnimatedSprite3D.new()
	node.sprite_frames = data
	node.animation = id
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.shaded = false
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var row := entry(id)
	node.pixel_size = 1.6/(float(row.height)/float(row.rows)*.75)
	var align := func():
		var rect: Array = row.rects[node.frame]
		var anchor: Array = row.anchors[node.frame]
		node.offset = Vector2(float(rect[2])/2-float(anchor[0]),float(anchor[1])-float(rect[3])/2)
	node.frame_changed.connect(align)
	align.call()
	if id in ["event-npc-leon-03","event-npc-leon-04"]:node.pixel_size *= .72
	return node
