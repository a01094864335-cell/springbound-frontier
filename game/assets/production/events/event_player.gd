extends Node3D
## Pure visual timelines. Signals request no inventory, reward, damage or quest mutation.
signal finished(event_id: String)
const Bank = preload("res://assets/production/motions/motion_bank.gd")
var timeline: Dictionary
var elapsed: float = 0
var playing: bool = false
var reported: bool = false
var actors: Array = []
func _ready() -> void:
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/production/events/catalog.json"))
	for entry in catalog:
		if entry.id==get_meta("asset_id"):
			timeline = entry
			break
	for entry in timeline.get("props",[]):
		var packed: PackedScene = load("res://assets/production/props/"+entry.id+".tscn")
		var prop := packed.instantiate() as Node3D
		prop.name = entry.node
		add_child(prop)
		prop.position = vector(entry.position)
	for entry in timeline.get("actors",[]):
		var sprite: AnimatedSprite3D = Bank.sprite(entry.clip)
		if sprite == null:
			push_error("Missing event actor clip: "+entry.clip)
			continue
		sprite.name = entry.node
		add_child(sprite)
		sprite.position = vector(entry.position)
		actors.append({"node":sprite,"clip":entry.clip})
	seek(0)
func vector(value: Array) -> Vector3:
	return Vector3(float(value[0]),float(value[1]),float(value[2]))
func play() -> void:
	elapsed=0
	reported=false
	playing=true
	seek(0)
func stop() -> void:
	playing=false
func seek(time: float) -> void:
	elapsed=clampf(time,0,float(timeline.duration))
	for actor in actors:
		var row := Bank.entry(actor.clip)
		var frame: int = int(elapsed*float(row.fps))
		actor.node.frame = frame%4 if row.loop else mini(frame,3)
	for track in timeline.get("tracks",[]):
		var target: Node = get_node_or_null(track.node)
		if target==null:continue
		var keys: Array=track.keys
		var value: Variant = keys[0].value
		for i in range(keys.size()-1):
			var a: Dictionary=keys[i]
			var b: Dictionary=keys[i+1]
			if elapsed>=float(a.time):
				var t: float=clampf((elapsed-float(a.time))/maxf(.001,float(b.time)-float(a.time)),0,1)
				value = vector(a.value).lerp(vector(b.value),t) if a.value is Array else lerpf(float(a.value),float(b.value),t)
		target.set(track.property,vector(value) if value is Array else value)
func skip() -> void:
	seek(float(timeline.duration))
	complete()
func complete() -> void:
	playing=false
	if not reported:
		reported=true
		finished.emit(timeline.id)
func _process(delta: float) -> void:
	if playing:
		seek(elapsed+delta)
		if elapsed>=float(timeline.duration):complete()
