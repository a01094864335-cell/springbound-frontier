extends SceneTree
const Bank = preload("res://assets/production/motions/motion_bank.gd")
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/motions/catalog.json"))
	var ids: Dictionary={}
	var frame_count: int=0
	if data.entries.size()!=1563:failures.append("Expected 1562 baseline clips + one first-victory clip")
	for row in data.entries:
		if ids.has(row.id):failures.append(row.id+" duplicate")
		ids[row.id]=true
		var frames: SpriteFrames=Bank.frames(row.id)
		if frames==null or not frames.has_animation(row.id):
			failures.append(row.id+" missing resource/animation")
			continue
		if frames.get_frame_count(row.id)!=4:failures.append(row.id+" must have 4 frames")
		if frames.get_animation_loop(row.id)!=bool(row.loop):failures.append(row.id+" loop mismatch")
		for n in range(4):
			var tex: AtlasTexture=frames.get_frame_texture(row.id,n)
			if tex==null or tex.atlas==null or tex.region.size.x<=0 or tex.region.size.y<=0:
				failures.append(row.id+" invalid texture")
			elif tex.region.end.x>tex.atlas.get_width()+.01 or tex.region.end.y>tex.atlas.get_height()+.01:
				failures.append(row.id+" region outside source")
			frame_count+=1
		if Bank.frames(row.id)!=frames:failures.append(row.id+" cache mismatch")
	if Bank.frames("missing-motion")!=null:failures.append("Unknown ID must return null")
	var sprite:=Bank.sprite("motion-pc-ael-1-0")
	if sprite==null:failures.append("3D sprite construction failed")
	else:sprite.free()
	var f:=FileAccess.open("res://tests/asset_production/motion-verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":failures.is_empty(),"clip_count":ids.size(),"frames":frame_count,"art_approved":false,"failures":failures},"\t"))
	print("MOTION_QA ",failures.is_empty()," clips=",ids.size()," frames=",frame_count," failures=",failures)
	quit(0 if failures.is_empty() else 1)
