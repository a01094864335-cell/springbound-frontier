extends RefCounted
## First playable battle. Timing/damage are prototype tuning, not verified PC-CD values.
const GridWalker = preload("res://scripts/grid_walker.gd")
const MAX_HP := 48
const ENEMY_HP := 84
const HERO_DAMAGE := 6
const HERO_WINDUP := 0.45
const HERO_RECOVERY := 1.55
const ENEMY_WINDUP := 0.85
const ENEMY_RECOVERY := 2.0
const REACH := 1.3
const ITEM_HEAL := 24
const ITEM_RECOVERY := 1.2

var player = GridWalker.new()
var enemy = GridWalker.new()
var hp := MAX_HP
var mp := 0
var enemy_hp := ENEMY_HP
var potions := 2
var mode := "story"
var active := false
var paused := true
var outcome := ""
var order := "wait"
var destination := Vector3.ZERO
var hero_cooldown := 0.0
var enemy_cooldown := 0.0
var hero_windup := 0.0
var enemy_windup := 0.0
var pending_item := false
var snapshot: Dictionary = {}
var events: Array[Dictionary] = []
var blocked: Callable
var pathfinder: Callable
var line_clear: Callable
var elapsed := 0.0
var commands_used: Dictionary = {}

func setup(hero_position: Vector3, enemy_position: Vector3, health: int, mana: int, items: int, difficulty: String, wall: Callable, path: Callable, sight: Callable) -> void:
	blocked = wall
	pathfinder = path
	line_clear = sight
	mode = difficulty
	potions = items
	snapshot = {"hero":hero_position,"enemy":enemy_position,"hp":health,"mp":mana}
	retry()

func retry() -> void:
	# Consumables deliberately remain at the current count.
	player.reset(snapshot.hero)
	enemy.reset(snapshot.enemy)
	hp = int(snapshot.hp)
	mp = int(snapshot.mp)
	enemy_hp = ENEMY_HP
	active = true
	paused = true
	outcome = ""
	order = "wait"
	destination = player.position
	hero_cooldown = 0
	enemy_cooldown = 0.8
	hero_windup = 0
	enemy_windup = 0
	pending_item = false
	elapsed = 0
	events.clear()
	commands_used.clear()

func select_order(value: String, target := Vector3.ZERO) -> bool:
	if not active or value not in ["attack","move","wait"]: return false
	if value == "move" and blocked.call(target): return false
	paused = true
	pending_item = false
	# A changed order may cancel preparation, but never erases recovery.
	if order != value or value == "move": hero_windup = 0
	order = value
	destination = player.from_grid(Vector2(roundf(target.x),roundf(target.z)))
	commands_used[value] = true
	return true

func select_item() -> bool:
	if not active or hp <= 0 or hp >= MAX_HP or potions <= 0 or hero_cooldown > 0 or pending_item: return false
	paused = true
	pending_item = true
	commands_used.item = true
	return true

func toggle_time() -> void:
	if active: paused = not paused

func in_reach() -> bool:
	# A sword connects only between settled cardinal neighbours.
	if player.moving or enemy.moving: return false
	var offset: Vector3 = player.position-enemy.position
	return is_equal_approx(absf(offset.x)+absf(offset.z),1.0) and line_clear.call(player.position,enemy.position)

func advance(delta: float) -> void:
	if not active or paused or delta <= 0: return
	# Fixed substeps keep attack events/collision stable on slow frames and in QA.
	var left := minf(delta,0.5)
	while left > 0.000001 and active:
		var dt := minf(left,1.0/60.0)
		_tick(dt)
		left -= dt

func _tick(dt: float) -> void:
	elapsed += dt
	if pending_item:
		pending_item = false
		if potions > 0 and hp > 0 and hp < MAX_HP and hero_cooldown <= 0:
			potions -= 1
			var before := hp
			hp = mini(MAX_HP,hp+ITEM_HEAL)
			hero_windup = 0
			hero_cooldown = ITEM_RECOVERY
			commands_used.item_used = true
			events.append({"kind":"item","amount":hp-before})
	hero_cooldown = maxf(0,hero_cooldown-dt)
	enemy_cooldown = maxf(0,enemy_cooldown-dt)
	player.advance(dt)
	enemy.advance(dt)
	if hero_windup > 0:
		hero_windup = maxf(0,hero_windup-dt)
		if hero_windup <= 0:
			hero_cooldown = HERO_RECOVERY
			if in_reach():
				commands_used.attack_hit = true
				enemy_hp = maxi(0,enemy_hp-HERO_DAMAGE)
				events.append({"kind":"enemy_hit","amount":HERO_DAMAGE})
			else: events.append({"kind":"hero_miss"})
	if enemy_hp <= 0:
		_finish("victory")
		return
	if enemy_windup > 0:
		enemy_windup = maxf(0,enemy_windup-dt)
		if enemy_windup <= 0:
			enemy_cooldown = ENEMY_RECOVERY
			if in_reach():
				var damage := 4 if mode == "story" else 6
				hp = maxi(0,hp-damage)
				events.append({"kind":"hero_hit","amount":damage})
			else:
				commands_used.dodge = true
				events.append({"kind":"enemy_miss"})
	if hp <= 0:
		_finish("defeat")
		return
	if not player.moving and hero_windup <= 0:
		if order == "move":
			if player.position.distance_to(destination) < 0.01:
				order = "wait"
				commands_used.move_completed = true
				events.append({"kind":"arrived"})
			else: _walk_toward(player,destination,true)
		elif order == "attack" and hero_cooldown <= 0:
			if in_reach():
				hero_windup = HERO_WINDUP
				events.append({"kind":"hero_prepare"})
			else: _walk_toward(player,enemy.position,true)
	if not enemy.moving and enemy_windup <= 0 and enemy_cooldown <= 0:
		if in_reach():
			enemy_windup = ENEMY_WINDUP
			events.append({"kind":"enemy_prepare"})
		else: _walk_toward(enemy,player.position,false)

func _walk_toward(actor: RefCounted, target: Vector3, is_hero: bool) -> void:
	var points: Array = pathfinder.call(actor.position,target)
	for point: Vector3 in points:
		var diff: Vector3 = point-actor.position
		if diff.length() < 0.01: continue
		var direction := Vector2i(signi(roundi(diff.x)),0) if absf(diff.x) > 0.01 else Vector2i(0,signi(roundi(diff.z)))
		# No diagonal shortcuts or crossing the other actor's reserved cell.
		var other = enemy if is_hero else player
		var collision := func(pos: Vector3) -> bool:
			return blocked.call(pos) or Vector2(pos.x-other.position.x,pos.z-other.position.z).length() < 0.65 or Vector2(pos.x-other.target.x,pos.z-other.target.z).length() < 0.65
		actor.begin(direction,collision,GridWalker.STEP_SECONDS if is_hero else 0.45)
		return
	if is_hero and order == "move":
		order = "wait"
		events.append({"kind":"blocked"})

func _finish(result: String) -> void:
	active = false
	paused = true
	outcome = result
	pending_item = false
	hero_windup = 0
	enemy_windup = 0
	order = "wait"
	events.append({"kind":result})
