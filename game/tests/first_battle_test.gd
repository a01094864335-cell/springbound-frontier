extends SceneTree
const Battle = preload("res://scripts/first_battle.gd")
const Progress = preload("res://scripts/combat_progress.gd")
var errors: Array[String] = []

func _wall(point: Vector3) -> bool:
	return absf(point.x) > 12 or absf(point.z) > 12

func _path(from: Vector3, to: Vector3) -> Array:
	var result: Array = [Vector3(roundf(from.x),0,roundf(from.z))]
	var cell: Vector3 = result[0]
	var target := Vector3(roundf(to.x),0,roundf(to.z))
	while cell.distance_to(target) > 0.01:
		if cell.x != target.x: cell.x += signf(target.x-cell.x)
		else: cell.z += signf(target.z-cell.z)
		result.append(cell)
	return result

func _new(mode := "story", items := 2):
	var battle = Battle.new()
	battle.setup(Vector3.ZERO,Vector3(0,0,-4),48,0,items,mode,_wall,_path,func(_a,_b): return true)
	return battle

func _initialize() -> void:
	var b = _new()
	b.enemy.reset(Vector3(1,0,1))
	if b.in_reach(): errors.append("Diagonal cells allow sword attack")
	b.enemy.reset(Vector3.RIGHT)
	if not b.in_reach(): errors.append("Cardinal adjacent cell cannot be attacked")
	b.player.begin(Vector2i.LEFT,_wall)
	if b.in_reach(): errors.append("Moving actor can attack between cells")
	b = _new()
	b.select_order("attack")
	b.advance(2)
	if b.player.position != Vector3.ZERO or b.enemy_hp != Battle.ENEMY_HP or b.elapsed != 0: errors.append("Paused simulation advances")
	b.toggle_time()
	for i in range(4000):
		b.advance(0.02)
		if not b.active: break
	if b.outcome != "victory" or b.hp <= 0: errors.append("Story battle cannot be won with basic attack")
	if b.elapsed < 20 or b.elapsed > 60: errors.append("First fight pacing out of target")
	var story_seconds: float = b.elapsed
	var survivor_hp: int = b.hp
	var wins: int = b.events.filter(func(event): return event.kind == "victory").size()
	b.advance(0.5)
	if wins != 1 or b.events.filter(func(event): return event.kind == "victory").size() != 1: errors.append("Victory duplicates")
	b = _new()
	b.hp = 20
	if not b.select_item(): errors.append("Item cannot be selected")
	b.advance(0.5)
	if b.hp != 20 or b.potions != 2: errors.append("Paused item consumed before resume")
	b.toggle_time()
	b.advance(0.02)
	if b.hp != 44 or b.potions != 1: errors.append("Immediate heal or inventory incorrect")
	var cooldown: float = b.hero_cooldown
	b.select_order("wait")
	b.select_order("attack")
	if b.hero_cooldown != cooldown or b.select_item(): errors.append("Order changes bypass recovery")
	b.advance(0.5)
	if b.potions != 1: errors.append("Item consumed more than once")
	b.retry()
	if b.hp != 48 or b.mp != 0 or b.potions != 1 or b.player.position != Vector3.ZERO: errors.append("Retry refunds items or fails to restore state")
	b = _new("tactical",0)
	b.select_order("wait")
	b.toggle_time()
	for i in range(4000):
		b.advance(0.02)
		if not b.active: break
	if b.outcome != "defeat" or b.hp != 0 or b.select_item(): errors.append("Defeat state invalid")
	b.retry()
	if b.potions != 0 or b.hp != 48: errors.append("Empty inventory retry incorrect")
	b = _new()
	b.select_order("move",Vector3(3,0,2))
	b.toggle_time()
	var prior: Vector3 = b.player.position
	for i in range(100):
		b.advance(0.02)
		var diff: Vector3 = b.player.target-b.player.origin
		if absf(diff.x)>0.001 and absf(diff.z)>0.001: errors.append("Diagonal movement")
		prior = b.player.position
	if b.player.position != Vector3(3,0,2) or b.order != "wait": errors.append("Movement endpoint or wait state incorrect")
	b = Battle.new()
	b.setup(Vector3.ZERO,Vector3(0,0,-1),48,0,2,"story",_wall,_path,func(_a,_b): return false)
	b.select_order("attack")
	b.toggle_time()
	for i in range(100): b.advance(0.02)
	if b.enemy_hp != Battle.ENEMY_HP or b.hp != 48: errors.append("Attacks pass through blocked sight")
	var save := Progress.fresh()
	if Progress.decode(save,3,false,false,0).is_empty(): errors.append("Fresh v3 save rejected")
	save.potions = -1
	if not Progress.decode(save,3,false,false,0).is_empty(): errors.append("Corrupt item count accepted")
	if not Progress.decode(null,2,true,false,2).won: errors.append("Legacy journey forced to replay")
	# A no-item tactical retry is winnable by moving away during the visible windup.
	b = _new("tactical",0)
	b.select_order("attack")
	b.toggle_time()
	for i in range(18000):
		if not b.active: break
		if b.enemy_windup > 0.4 and b.order == "attack" and not b.player.moving:
			var away := Vector3(0,0,2) if b.player.position.z >= b.enemy.position.z else Vector3(0,0,-2)
			if _wall(b.player.position+away): away = Vector3(2,0,0)
			b.select_order("move",b.player.position+away)
			b.toggle_time()
		elif b.order == "wait" and b.enemy_windup <= 0:
			b.select_order("attack")
			b.toggle_time()
		b.advance(0.02)
	if b.outcome != "victory": errors.append("Tactical retry with zero items is unwinnable")
	print("STORY_BATTLE_RESULT: %.2fs, HP %d/48" % [story_seconds,survivor_hp])
	print("FIRST_BATTLE_QA: %s %s" % ["PASS" if errors.is_empty() else "FAIL",errors])
	quit(0 if errors.is_empty() else 1)
