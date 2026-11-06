extends SceneTree
const Story = preload("res://scripts/prologue_story.gd")

func _initialize() -> void:
	var errors: Array[String] = []
	var story = Story.new()
	for order in [["well_first","inn_first"],["inn_first","well_first"]]:
		story.reset()
		story.finish("opening")
		story.finish(order[0])
		if story.errands_done(): errors.append("One errand completed both")
		story.finish(order[1])
		if not story.errands_done(): errors.append("Order-dependent errands")
		story.finish("request")
		story.finish("farewell")
		story.finish("leon_first")
		story.finish("closing")
		var snapshot: Dictionary = story.flags.duplicate()
		if not story.restore(2,true,true,true,snapshot): errors.append("V2 roundtrip rejected")
		if story.restore(2,true,true,true,{"morning":"true"}): errors.append("Malformed flags accepted")
		if story.flags != snapshot: errors.append("Failed load changed live state")
		var impossible := snapshot.duplicate()
		impossible.water = false
		if story.restore(2,true,true,true,impossible): errors.append("Impossible progress accepted")
	for progressed in [false,true]:
		if not story.restore(1,progressed,progressed,progressed,null): errors.append("V1 rejected")
		if story.done("farewell") != progressed or story.done("closing"): errors.append("V1 migration incorrect")
	story.reset()
	var medicine := false
	var leon := false
	var delivered := false
	for scene in ["opening","well_first","inn_first","request","medicine","farewell","leon_first","leon_bridge","delivery","closing"]:
		story.finish(scene)
		medicine = medicine or scene == "medicine"
		leon = leon or scene == "leon_bridge"
		delivered = delivered or scene == "delivery"
		var restored = Story.new()
		if not restored.restore(2,medicine,leon,delivered,story.flags.duplicate()): errors.append("Stage load rejected: "+scene)
		if restored.flags != story.flags: errors.append("Stage load changed progress: "+scene)
	var historical: Dictionary = story.flags.duplicate()
	historical.erase("leon_found")
	if not story.restore(2,true,true,true,historical) or not story.done("leon_found"): errors.append("Existing V2 save migration failed")
	story.reset()
	if story.scene_for("nia",false,false,false) != "nia": errors.append("Early Nia mentions departure")
	if story.scene_for("roke",false,false,false) != "roke_before_trip": errors.append("Early gate dialogue assumes delivery")
	story.finish("opening")
	story.finish("well_first")
	if story.scene_for("marta",false,false,false) != "marta_towels_left": errors.append("Wrong remaining errand")
	story.finish("inn_first")
	story.finish("request")
	if story.scene_for("medicine",false,false,false) != "medicine": errors.append("Parcel not available after request")
	story.finish("farewell")
	story.finish("leon_first")
	if story.scene_for("leon",true,false,false) != "leon_bridge": errors.append("Encounter does not return control before aid")
	if story.scene_for("tracks",true,false,false) != "tracks_after": errors.append("Known footprints treated as unknown")
	if story.scene_for("tracks",true,true,true) != "tracks_return": errors.append("Delivered medicine still described as pending")
	if story.scene_for("medicine",true,true,true) != "parcel_delivered": errors.append("Delivered parcel still needs packing")
	for kind in ["marta","medicine","water","inn","leon","leon_arrival","delivery","halven","eda","room_map","nia","roke","doren","vera","tracks","window","notice","trail_sign"]:
		for state in [[false,false,false],[true,false,false],[true,true,false],[true,true,true]]:
			var selected: String = story.scene_for(kind,state[0],state[1],state[2])
			if story.lines(selected).is_empty() or selected in story.data.planned_scenes: errors.append("Invalid runtime scene: "+selected)
	var line_count := 0
	for scene in story.data.scenes:
		if story.lines(scene).is_empty() or story.title(scene).is_empty(): errors.append("Empty scene: "+scene)
		for line in story.lines(scene):
			line_count += 1
			if line.size() != 3 or line[0].is_empty() or line[1].is_empty(): errors.append("Invalid dialogue")
			if line[0] == "서술": errors.append("Novel prose in game dialogue: "+scene)
			if line[1].length() > 100: errors.append("Page too long: "+scene)
			if int(line[2]) not in [-1,0,1,2]: errors.append("Invalid portrait")
	print("PROLOGUE_STORY_QA: %s (%d scenes / %d lines) %s" % ["PASS" if errors.is_empty() else "FAIL",story.data.scenes.size(),line_count,errors])
	quit(0 if errors.is_empty() else 1)
