extends SceneTree
const Bank = preload("res://assets/production/icons/icon_bank.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var entries: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/icons/catalog.json"))
	var failures: Array = []
	var results: Array = []
	if not entries is Array or entries.size() != 49:
		push_error("Expected the 49 resumed icons")
		quit(1)
		return
	for entry in entries:
		var tex: Texture2D = Bank.texture(entry.id)
		if tex == null:
			failures.append(entry.id + ": texture missing")
			continue
		var img: Image = tex.get_image()
		var has_alpha: bool = img.detect_alpha() != Image.ALPHA_NONE
		var clear_corners: bool = true
		for xy in [Vector2i.ZERO, Vector2i(img.get_width()-1,0), Vector2i(0,img.get_height()-1), Vector2i(img.get_width()-1,img.get_height()-1)]:
			clear_corners = clear_corners and img.get_pixelv(xy).a < 0.01
		if not has_alpha or not clear_corners:
			failures.append(entry.id + ": transparency invalid")
		if Bank.texture(entry.id) != tex:
			failures.append(entry.id + ": cache mismatch")
		results.append({"id": entry.id, "width": img.get_width(), "height": img.get_height(), "has_alpha": has_alpha, "clear_corners": clear_corners})
	if Bank.texture("not-a-real-item") != null:
		failures.append("Unknown ID must return null")
	var report: Dictionary = {"count": results.size(), "passed": failures.is_empty(), "gameplay_connected": false, "results": results, "failures": failures}
	var file: FileAccess = FileAccess.open("res://tests/asset_production/icon-verification.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("ICON_ASSET_QA ", failures.is_empty(), " count=", results.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
