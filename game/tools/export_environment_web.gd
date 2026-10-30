extends SceneTree

var all_assets: Array = []

func _initialize() -> void:
	var entries = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/catalog.json"))
	for entry in entries:
		var root: Node3D = load(entry.scene).instantiate()
		var parts: Array = []
		collect(root, Transform3D.IDENTITY, parts)
		entry["parts"] = parts
		all_assets.append(entry)
		root.free()
	var file := FileAccess.open("res://../docs/assets-viewer/geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(all_assets))
	print("WEB_EXPORT: %d assets" % all_assets.size())
	quit()

func collect(node: Node, parent: Transform3D, parts: Array) -> void:
	var xf := parent
	if node is Node3D: xf = parent * node.transform
	if node is MeshInstance3D and node.mesh:
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals = arrays[Mesh.ARRAY_NORMAL]
			var uvs = arrays[Mesh.ARRAY_TEX_UV]
			var indices = arrays[Mesh.ARRAY_INDEX]
			var positions: Array = []
			var ns: Array = []
			var uv: Array = []
			var count: int = indices.size() if indices != null and indices.size() > 0 else verts.size()
			for i in range(count):
				var j: int = indices[i] if indices != null and indices.size() > 0 else i
				var v: Vector3 = xf * verts[j]
				var n: Vector3 = (xf.basis.inverse().transposed() * normals[j]).normalized() if normals != null and normals.size() > j else Vector3.UP
				positions.append_array([snappedf(v.x,0.0001),snappedf(v.y,0.0001),snappedf(v.z,0.0001)])
				ns.append_array([snappedf(n.x,0.0001),snappedf(n.y,0.0001),snappedf(n.z,0.0001)])
				var t: Vector2 = uvs[j] if uvs != null and uvs.size() > j else Vector2.ZERO
				uv.append_array([t.x,t.y])
			var mat: Material = node.material_override if node.material_override else node.mesh.surface_get_material(surface)
			var color := Color.WHITE
			var tex := -1
			var unlit := false
			if mat is StandardMaterial3D:
				color = mat.albedo_color
				unlit = mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
				for k in range(6):
					if mat.resource_path.ends_with("surface_%d.tres" % k): tex = k
			parts.append({"p":positions,"n":ns,"uv":uv,"color":[color.r,color.g,color.b,color.a],"texture":tex,"unlit":unlit})
	if node is Sprite3D and node.texture:
		var w: float = node.texture.get_width()*node.pixel_size
		var h: float = node.texture.get_height()*node.pixel_size
		var y: float = node.offset.y*node.pixel_size
		var x: float = node.offset.x*node.pixel_size
		var points: Array = []
		for p in [Vector3(x-w/2,y-h/2,0),Vector3(x+w/2,y-h/2,0),Vector3(x+w/2,y+h/2,0),Vector3(x-w/2,y-h/2,0),Vector3(x+w/2,y+h/2,0),Vector3(x-w/2,y+h/2,0)]:
			var v: Vector3 = xf*p
			points.append_array([v.x,v.y,v.z])
		parts.append({"p":points,"n":[0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1],"uv":[0,1,1,1,1,0,0,1,1,0,0,0],"color":[1,1,1,1],"texture":6,"unlit":true,"billboard":true})
	for child in node.get_children(): collect(child,xf,parts)
