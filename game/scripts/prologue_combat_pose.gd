extends RefCounted
const Battle = preload("res://scripts/first_battle.gd")
const Motion = preload("res://scripts/prologue_motion.gd")
var world: Node
var overlay: Sprite3D
var victory_time := 0.0
func setup(owner_world: Node) -> void:
	world=owner_world
	overlay=Sprite3D.new()
	overlay.name="ActiveCombatMotion"
	overlay.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	overlay.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	overlay.shaded=false
	overlay.position.y=0.04
	world.hero.add_child(overlay)
	overlay.hide()
func clear() -> void:
	overlay.hide()
	world.hero_sprite.show()
	victory_time=0
func render(model, flash: float) -> void:
	if not model.active and model.outcome!="defeat": return
	var direction := Motion.direction(model.enemy.position-model.player.position)
	var action := 1 if model.player.moving else 0
	var phase: float = model.player.progress if model.player.moving else fmod(model.elapsed,1.0)
	if model.hero_windup>0:
		action=2
		phase=1.0-model.hero_windup/Battle.HERO_WINDUP
	elif model.hero_cooldown>Battle.HERO_RECOVERY*.75:
		action=2
		phase=0.99
	if flash>0: action=3; phase=0.5
	if model.outcome=="defeat": action=4; phase=0.99
	Motion.render(overlay,"party-0-0-%d-%d" % [action,direction],phase)
	overlay.modulate=Color("ffb0a0") if flash>0 else Color.WHITE
	overlay.show()
	world.hero_sprite.hide()
func victory() -> void:
	victory_time=1.2
	Motion.render(overlay,"event-first-victory-tremble",0.0)
	overlay.modulate=Color.WHITE
	overlay.show()
	world.hero_sprite.hide()
func tick(delta: float) -> void:
	if victory_time<=0: return
	victory_time-=delta
	Motion.render(overlay,"event-first-victory-tremble",clampf(1.0-victory_time/1.2,0,0.99))
	if victory_time<=0: clear()
