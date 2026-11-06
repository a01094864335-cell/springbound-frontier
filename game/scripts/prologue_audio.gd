extends Node
## Original generated loops; independent music/effects volume and no game-time changes.
const Bank = preload("res://assets/production/audio/audio_bank.gd")
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var track := ""
var streams := {}
var music_level := 0.55
var effects_level := 0.7

func _ready() -> void:
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -12
	add_child(music)
	effects = AudioStreamPlayer.new()
	effects.bus = "Effects"
	effects.volume_db = -25
	add_child(effects)
	set_levels(music_level,effects_level)

func set_levels(bgm: float, sfx: float) -> void:
	music_level = clampf(bgm,0,1)
	effects_level = clampf(sfx,0,1)
	for pair in [["Music",music_level],["Effects",effects_level]]:
		var index := AudioServer.get_bus_index(pair[0])
		if index < 0: continue
		AudioServer.set_bus_mute(index,float(pair[1]) <= 0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.001,float(pair[1]))))

func select(next: String) -> void:
	if track == next: return
	track = next
	var ids := {"hearth":"audio-2-02","trail":"audio-2-03","arrival":"audio-2-04","battle":"audio-2-15"}
	var stream: AudioStreamWAV = Bank.stream(ids.get(next,"audio-2-01"))
	if stream==null: return
	music.stream = stream
	if DisplayServer.get_name() != "headless": music.play()

func cue(kind: String) -> void:
	if not streams.has(kind):
		var ids := {"step":"audio-0-04","talk":"audio-0-32","pickup":"audio-0-30","complete":"audio-0-36","rope":"audio-0-39","cloth":"audio-0-06"}
		streams[kind]=Bank.stream(ids.get(kind,"audio-0-33"))
	effects.stream = streams[kind]
	if DisplayServer.get_name() != "headless": effects.play()

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	if is_instance_valid(effects):
		effects.stop()
		effects.stream = null
	streams.clear()
