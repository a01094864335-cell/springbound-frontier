extends PanelContainer
signal action_requested(action: String, payload: Dictionary)
signal value_changed(key: String, value: Variant)
signal closed
@export var asset_id: String = "presentation-2-01"
var body: VBoxContainer
var content: Dictionary = {}
var kind: String
func _ready() -> void:
	theme = preload("res://assets/production/ui/frontier_theme.tres")
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/ui/catalog.json"))
	for e in rows:
		if e.id == asset_id:
			kind = e.kind
			break
	render()
func configure(data: Dictionary) -> void:
	content = data.duplicate(true)
	if is_node_ready():
		render()
func line(text: String, size: int = 19) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	return label
func button(text: String, action: String, payload: Dictionary = {}) -> Button:
	var control := Button.new()
	control.text = text
	control.set_meta("action",action)
	control.set_meta("payload",payload)
	control.pressed.connect(func():
		action_requested.emit(action,payload.duplicate(true))
		if action == "close":
			closed.emit())
	body.add_child(control)
	return control
func meter(key: String, label: String, current: float, maximum: float) -> void:
	line(label)
	var bar := ProgressBar.new()
	bar.name = key
	bar.max_value = maxf(.001,maximum)
	bar.value = current
	bar.show_percentage = false
	bar.custom_minimum_size.y = 22
	body.add_child(bar)
func render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation",10)
	add_child(body)
	match kind:
		"dialogue":
			line(str(content.get("speaker","레온")),22)
			line(str(content.get("text","내 검을 써. 내가 알려줄게.")))
			button("계속","advance")
		"nameplate":line(str(content.get("speaker","에일")),24)
		"choices":
			var choices: Array = content.get("choices",["해볼게요.","검을 잡는 건 처음이에요."])
			for i in range(choices.size()):button(str(choices[i]),"choice",{"index":i})
		"portrait":
			var portrait := TextureRect.new()
			var texture: Texture2D = load(str(content.get("portrait","res://assets/ael-portrait.png")))
			if not content.has("portrait"):
				var region := AtlasTexture.new()
				region.atlas = texture
				region.region = Rect2(555,613,230,324)
				texture = region
			portrait.texture = texture
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.custom_minimum_size = Vector2(180,200)
			body.add_child(portrait)
		"interaction":button(str(content.get("prompt","말 걸기")),"interact",{"target_id":content.get("target_id","")})
		"quest_accept","quest_update","quest_complete","objective":
			line({"quest_accept":"새로운 부탁","quest_update":"목표 갱신","quest_complete":"부탁 완료","objective":"현재 목표"}[kind],24)
			line(str(content.get("title","산길에서 발견한 기사")))
			line(str(content.get("objective","부상당한 레온에게 다가가자.")))
			button("확인","acknowledge",{"quest_id":content.get("quest_id","")})
		"local_map","world_map":
			line("지역 지도" if kind=="local_map" else "세계 지도",24)
			var map: Control=load("res://assets/production/ui/map_view.gd").new()
			map.custom_minimum_size=Vector2(580,230)
			body.add_child(map)
			map.configure(content.get("destinations",["서리골","산길","돌샘"]))
			map.destination_selected.connect(func(id):action_requested.emit("destination",{"id":id}))
		"destination","move_target":button(str(content.get("label","목적지")),"select_position",{"position":content.get("position",Vector2.ZERO)})
		"commands":
			for command in ["이동","공격","마법","아이템","대기"]:button(command,"command",{"command":command})
		"target":
			line("대상 선택",24)
			for target in content.get("targets",["가시털 들쥐"]):button(str(target),"target",{"target_id":target})
		"range","danger":
			line("사거리" if kind=="range" else "위험 범위",24)
			var grid := GridContainer.new()
			grid.columns = 7
			body.add_child(grid)
			for i in range(35):
				var cell := ColorRect.new()
				var x: int = i%7-3
				var y: int = int(i/7)-2
				cell.color = Color("b75b54") if kind=="danger" else Color("5b8aa0")
				cell.modulate.a = .8 if abs(x)+abs(y)<=2 else .15
				cell.custom_minimum_size = Vector2(28,28)
				cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
				grid.add_child(cell)
		"hp","mp":meter(kind,kind.to_upper(),float(content.get("value",70)),float(content.get("max",100)))
		"status":
			for status in content.get("statuses",["부상","방어"]):line(str(status))
		"equipment":
			line("장비",24)
			for slot in ["무기","방패","방어구","장신구"]:button(slot+" · "+str(content.get(slot,"—")),"equipment_slot",{"slot":slot})
		"inventory","buy","sell":
			line({"inventory":"가방","buy":"구매","sell":"판매"}[kind],24)
			for item in content.get("items",[{"id":"item-recovery-and-cures-01","name":"회복약","count":3,"price":40}]):button(str(item.name)+" × "+str(item.get("count",1))+(" · "+str(item.get("price",0))+" G" if kind!="inventory" else ""),"item_selected",{"item_id":item.id,"mode":kind})
		"item_detail":
			line(str(content.get("name","회복약")),24)
			line(str(content.get("description","약초로 만든 작은 회복약.")))
			button("선택","item_confirm",{"item_id":content.get("item_id","")})
		"relations":
			line("동료와의 기록",24)
			for entry in content.get("entries",["레온 · 산길에서의 만남"]):button(str(entry),"record_selected",{"id":entry})
		"save","load":
			line("기록하기" if kind=="save" else "기록 불러오기",24)
			for i in range(3):button("기록 "+str(i+1)+" · "+str(content.get("slot_"+str(i),"빈 기록")),kind+"_slot",{"slot":i})
		"settings":
			line("설정",24)
			for key in ["master_volume","music_volume","sfx_volume"]:
				line({"master_volume":"전체 음량","music_volume":"음악","sfx_volume":"효과음"}[key])
				var slider := HSlider.new()
				slider.min_value = 0
				slider.max_value = 1
				slider.step = .01
				slider.value = float(content.get(key,.7))
				slider.value_changed.connect(func(value):value_changed.emit(key,value))
				body.add_child(slider)
		"keys":
			line("키 설정",24)
			for key in ["위","아래","왼쪽","오른쪽","확인","취소"]:button(key+" · "+str(content.get(key,"—")),"rebind",{"key":key})
		"pause":
			line("잠시 쉬기",24)
			button("계속","close")
			button("설정","settings")
			button("타이틀로","title_requested")
		"results":
			line("전투 종료",24)
			line(str(content.get("summary","모두 무사하다.")))
			line("경험치 "+str(content.get("experience",0))+" · "+str(content.get("gold",0))+" G")
			button("계속","results_acknowledged")
		"retry":
			line("다시 시도할까요?",24)
			button("전투 직전부터","retry_requested")
			button("기록 불러오기","load_requested")
		"title":
			line("봄을 기다리는 국경",32)
			button("새 이야기","new_game_requested")
			button("이어하기","continue_requested")
			button("설정","settings")
		"credits":
			line("봄을 기다리는 국경",28)
			line(str(content.get("credits","제작진")))
			button("돌아가기","close")
		"loading":meter("loading",str(content.get("label","불러오는 중…")),float(content.get("progress",0)),1)
