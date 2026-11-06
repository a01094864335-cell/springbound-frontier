extends RefCounted
## Dismissible contextual guidance; never pauses or gates the fight.
var view: Node
var stage := "off"
var panel: PanelContainer
var title: Label
var text: Label
var next_button: Button
var skip_button: Button
func setup(owner_view: Node, layout: Control) -> void:
	view=owner_view
	panel=view._window(layout,Vector2(24,110),Vector2(310,148),Control.PRESET_TOP_LEFT)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",6)
	panel.add_child(stack)
	title=view.world._label(stack,"",17,Color("efd492"))
	text=view.world._label(stack,"",15)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x=286
	next_button=view._small_button(stack,"알겠어요 · 안내 닫기",finish)
	skip_button=next_button
	panel.hide()
func start() -> void:
	stage="attack"
	panel.show()
	refresh()
func finish() -> void:
	stage="off"
	panel.hide()
	view.model.tutorial_hold=false
func event(kind: String) -> void:
	if stage=="off":return
	if kind=="enemy_hit" and stage=="attack":stage="dodge"
	elif kind=="leap_miss":stage="heal"
	refresh()
func time_changed() -> void:refresh()
func tick() -> void:refresh()
func allows(_command: String) -> bool:return true
func command_selected(_command: String) -> void:pass
func refresh() -> void:
	if stage=="off":return
	if view.model.leap_windup>0:
		title.text="범위 도약 · 옆으로 비키기"
		text.text="붉은 범위 밖을 우클릭하세요. 이동 명령은 바로 실행됩니다. Space로 멈춰 생각할 수도 있어요."
	elif view.model.enemy_cooldown>1.7:
		title.text="착지 뒤 빈틈"
		text.text="마물이 다시 자세를 잡고 있어요. 적을 클릭하면 접근해서 계속 공격합니다."
	else:
		title.text="레온의 짧은 안내"
		text.text={"attack":"적 클릭: 추적·반복 공격\n빈 곳 우클릭: 이동\nSpace: 전술 정지·재개", "dodge":"공격은 계속 이어집니다. 물기 준비와 붉은 도약 범위를 살펴보고, 위험할 때 위치를 바꾸세요.", "heal":"개인 회복약 사용은 선택입니다. 사용한 약은 재도전해도 돌아오지 않아요. 배달 약은 사용할 수 없습니다."}.get(stage,"")
