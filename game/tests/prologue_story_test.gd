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
	for scene in ["opening","well_first","inn_first","request","medicine","farewell","leon_bridge","delivery","closing"]:
		story.finish(scene)
		medicine = medicine or scene == "medicine"
		leon = leon or scene == "leon_bridge"
		delivered = delivered or scene == "delivery"
		var restored = Story.new()
		if not restored.restore(2,medicine,leon,delivered,story.flags.duplicate()): errors.append("Stage load rejected: "+scene)
		if restored.flags != story.flags: errors.append("Stage load changed progress: "+scene)
	var line_count := 0
	for scene in story.data.scenes:
		if story.lines(scene).is_empty() or story.title(scene).is_empty(): errors.append("Empty scene: "+scene)
		for line in story.lines(scene):
			line_count += 1
			if line.size() != 3 or line[0].is_empty() or line[1].is_empty(): errors.append("Invalid dialogue")
			if line[1].length() > 130: errors.append("Page too long: "+scene)
			if int(line[2]) not in [-1,0,1,2]: errors.append("Invalid portrait")
	print("PROLOGUE_STORY_QA: %s (%d scenes / %d lines) %s" % ["PASS" if errors.is_empty() else "FAIL",story.data.scenes.size(),line_count,errors])
	quit(0 if errors.is_empty() else 1)
