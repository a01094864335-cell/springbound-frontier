extends RefCounted
## Event-driven pauses teach actual commands without changing health or damage.
var view: Node
var stage := "off"
var panel: PanelContainer
var title: Label
var text: Label
var next_button: Button
var skip_button: Button
var dodge_prompted := false
var wait_selected := false
var shown: Dictionary = {}

func setup(owner_view: Node, layout: Control) -> void:
	view = owner_view
	panel = view._window(layout,Vector2(24,110),Vector2(330,170),Control.PRESET_TOP_LEFT)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8)
	panel.add_child(stack)
	title = view.world._label(stack,"",19,Color("efd492"))
	text = view.world._label(stack,"",16)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 300
	next_button = view._small_button(stack,"회복약은 아끼고 계속",finish)
	skip_button = view._small_button(stack,"안내 종료 · 자유롭게 전투",finish)
	panel.hide()

func start() -> void:
	stage = "resume"
	shown.clear()
	wait_selected = false
	view.model.tutorial_hold = true
	view.model.paused = true
	panel.show()
	refresh()
	_say("tutorial_pause")

func finish() -> void:
	stage = "off"
	view.model.tutorial_hold = false
	panel.hide()
	for button in [view.attack_button,view.move_button,view.item_button]: button.modulate = Color.WHITE
	view._log("자유 전투 · Space로 재개. 회복약 사용은 선택입니다.")

func time_changed() -> void:
	if stage == "resume" and not view.model.paused:
		stage = "pause"
	elif stage == "pause" and view.model.paused:
		stage = "move"
		_say("tutorial_move")
	elif stage == "wait" and not view.model.paused and wait_selected and view.model.order == "wait" and not view.model.player.moving:
		stage = "dodge"
		view.model.begin_leap()
		view.model.paused = true
		_say("tutorial_dodge")
	refresh()

func event(kind: String) -> void:
	if stage == "off": return
	if stage == "move" and kind == "arrived":
		stage = "wait"
		view.model.paused = true
		_say("tutorial_wait")
	elif stage == "dodge" and kind == "leap_miss":
		stage = "attack"
		view.model.tutorial_hold = false
		view.model.paused = true
		_say("tutorial_dodged",func(): _say("tutorial_attack"))
	elif stage == "dodge" and kind == "hero_hit":
		view.model.paused = true
		stage = "dodge_retry"
	elif stage == "attack" and kind == "enemy_hit":
		stage = "heal"
		view.model.paused = true
		_say("tutorial_hit",func(): _say("tutorial_item"))
	elif stage == "heal" and kind == "item": finish()
	refresh()

func tick() -> void:
	if stage == "dodge_retry" and not view.model.paused:
		view.model.begin_leap()
		stage = "dodge"
		view.model.paused = true
		refresh()

func refresh() -> void:
	var data := {
		"resume":["1 / 6 · 멈추고 살피기", "Space로 재개한 뒤 다시 Space로 멈춰보세요. 입력 학습 중에는 마물이 공격하지 않습니다."],
		"pause":["1 / 6 · 다시 멈추기", "시간이 흐르고 있습니다. Space로 다시 멈춰보세요."],
		"move":["2 / 6 · 실제로 이동하기", "빈 칸을 우클릭하거나 이동 → 방향키 → Enter로 선택한 뒤 Space. 안전한 칸에 도착해야 다음으로 갑니다."],
		"wait":["3 / 6 · 기다림도 명령", "대기를 선택하고 Space로 실행하세요. 대기는 공격을 멈추는 명령이며 무적이나 방어가 아닙니다."],
		"dodge":["4 / 6 · 범위 도약 피하기", "붉은 칸은 도약의 위험 범위입니다. 두 칸 이상 옆으로 이동을 지정하고 Space로 재개하세요. 일반 물기에는 바닥 예고가 없습니다."],
		"dodge_retry":["범위에 닿았습니다", "실제 피해가 반영됐습니다. Space를 누르면 다시 위험 범위를 확인하고 이동을 고를 수 있습니다."],
		"attack":["5 / 6 · 첫 유효 타격", "공격 → 마물 선택 → Space. 사거리 안에 접근해 실제로 검이 맞으면 다음 안내로 넘어갑니다."],
		"heal":["6 / 6 · 회복은 선택", "개인 회복약만 사용할 수 있습니다. 사용한 약은 패배·재도전에도 돌아오지 않습니다. 약을 아끼고 계속해도 됩니다."]}
	if not data.has(stage): return
	title.text = data[stage][0]
	text.text = data[stage][1]
	next_button.visible = stage == "heal"
	skip_button.visible = false
	view.attack_button.modulate = Color("ffe2a0") if stage == "attack" else Color.WHITE
	view.move_button.modulate = Color("ffe2a0") if stage in ["move","dodge"] else Color.WHITE
	view.item_button.modulate = Color("ffe2a0") if stage == "heal" else Color.WHITE

func allows(command: String) -> bool:
	if stage in ["off", "heal", "attack"]: return true
	if stage in ["resume", "pause", "wait"]: return command == "wait"
	return command == "move"

func command_selected(command: String) -> void:
	if stage=="wait" and command=="wait": wait_selected=true

func _say(scene: String, after := Callable()) -> void:
	if shown.has(scene): return
	shown[scene]=true
	view.world._dialog(view.world.story.lines(scene),after,scene)
