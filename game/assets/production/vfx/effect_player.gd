extends Node3D
## Presentation only: no damage, inventory, reward or quest events.
@export var duration: float = 0.7
@export var loop: bool = false
@export var autoplay: bool = true
@export var free_when_finished: bool = false
var elapsed: float = 0.0
var playing: bool = false
var material: ShaderMaterial
signal finished
func _ready() -> void:
 material = $Visual.material_override.duplicate() as ShaderMaterial
 $Visual.material_override = material
 if autoplay: play()
func play() -> void:
 elapsed=0.0
 playing=true
 show()
 seek(0.0)
func stop() -> void:
 playing=false
 hide()
func seek(fraction: float) -> void:
 if material: material.set_shader_parameter("progress",clampf(fraction,0.0,1.0))
func _process(delta: float) -> void:
 if not playing:return
 elapsed+=delta
 var fraction: float=elapsed/maxf(duration,0.001)
 if fraction>=1.0:
  if loop:
   elapsed=fmod(elapsed,duration)
   fraction=elapsed/duration
  else:
   seek(1.0)
   playing=false
   hide()
   finished.emit()
   if free_when_finished: queue_free()
   return
 seek(fraction)
