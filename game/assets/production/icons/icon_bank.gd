extends RefCounted
## First-pass icons only. Unknown IDs return null; missing prior local drafts are not substituted.
static var _paths: Dictionary = {}
static var _textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if _paths.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/icons/catalog.json"))
		if not data is Array:
			return null
		for entry in data:
			_paths[str(entry.id)] = str(entry.path)
	if not _paths.has(id):
		return null
	if not _textures.has(id):
		_textures[id] = load(_paths[id]) as Texture2D
	return _textures[id] as Texture2D
