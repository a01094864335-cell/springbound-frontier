"""Author shader-native, controllable 3D VFX resources without raster placeholders."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'game/assets/production/vfx';OUT.mkdir(exist_ok=True)
shader='''shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform int effect = 0;
uniform float density = 1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float line_segment(vec2 p,vec2 a,vec2 b,float w){vec2 ab=b-a;return 1.0-smoothstep(w,w+0.015,length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0)));}
void vertex(){
 vec4 center=VIEW_MATRIX*MODEL_MATRIX[3];
 vec3 scl=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=mat4(vec4(scl.x,0.0,0.0,0.0),vec4(0.0,scl.y,0.0,0.0),vec4(0.0,0.0,scl.z,0.0),center);
}
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);float t=progress;float mask=0.0;float fade=sin(3.14159265*t);
 if(effect==0){ // sweeping crescent, stage progression is controlled by playback
  float sweep=-2.5+t*5.0;float delta=mod(a-sweep+9.42477796,6.2831853)-3.14159265;
  mask=(1.0-smoothstep(0.0,0.07,abs(r-0.65)))*smoothstep(-1.2,-0.1,delta)*(1.0-smoothstep(0.0,0.2,delta));
 }else if(effect==1){ // directed thrust / projectile trail
  float head=-0.8+1.6*t;mask=line_segment(p,vec2(max(-.9,head-.65),0.0),vec2(head,0.0),.025)*(1.0-smoothstep(.0,.3,abs(p.y)));
  mask+=1.0-smoothstep(.03,.12,length(p-vec2(head,0.0)));
 }else if(effect==2){ // expanding shock ring and six rays
  mask=(1.0-smoothstep(.025,.09,abs(r-(.05+.78*t))))*(1.0-t);
  mask+=pow(max(0.0,cos(a*6.0)),20.0)*(1.0-smoothstep(.12,.5,r))*fade;
 }else if(effect==3){ // restorative upward motes and gentle rings
  for(int i=0;i<12;i++){float k=float(i);vec2 c=vec2(sin(k*2.4)*.65,.8-fract(t+k/12.0)*1.6);mask+=1.0-smoothstep(.01,.06,length(p-c));}
  mask+=(1.0-smoothstep(.025,.06,abs(length(p*vec2(1.0,2.5))-(.3+.4*t))))*.35;
 }else if(effect==4){ // web spokes + concentric threads
  float spokes=pow(abs(cos(a*6.0)),70.0);float rings=1.0-smoothstep(.012,.025,abs(fract(r*5.0)-.5)/5.0);
  mask=max(spokes,rings)*(1.0-smoothstep(.65,.9,r))*smoothstep(0.0,.2,t);
 }else if(effect==5){ // powder / dust / sparks
  for(int i=0;i<24;i++){float k=float(i);float angle=k*2.39996;float speed=.2+hash(vec2(k,3.0))*.65;vec2 c=vec2(cos(angle),sin(angle))*speed*t;mask+=1.0-smoothstep(.008,.045*(1.0-t*.6),length(p-c));}
 }else if(effect==6){ // root / fungal branching, reveal from bottom
  for(int i=0;i<7;i++){float k=float(i);vec2 b=vec2(sin(k*2.5)*.8,-.7+k*.22);mask+=line_segment(p,vec2(0.0,.85),b,.015)*smoothstep(.0,.15,t-k*.09);}
 }else if(effect==7){ // status / defeat pillar
  float ellipse=length(p*vec2(1.0,2.8));mask=(1.0-smoothstep(.025,.06,abs(ellipse-.5)))*fade;
  mask+=max(0.0,1.0-abs(p.x)*8.0)*(1.0-smoothstep(.1,.9,abs(p.y)))*fade;
 }else if(effect==8){ // snow, rain, embers, leaves: periodic deterministic particles
  float clock=t*6.0;
  for(int i=0;i<48;i++){float k=float(i);float speed=.4+hash(vec2(k,4.0));vec2 c=vec2(-.95+hash(vec2(k,1.0))*1.9,.95-fract(clock*speed+k*.618)*1.9);c.x+=sin(clock+k)*.06;vec2 q=p-c;mask+=1.0-smoothstep(.006,.02*density,length(q*vec2(1.0,1.0/density)));}
 }else if(effect==9){ // layered fog and smoke, soft hashed billows
  for(int i=0;i<7;i++){float k=float(i);vec2 c=vec2(sin(k*2.4+t*6.283)*.6,cos(k*1.7+t*6.283)*.3);mask+=exp(-dot(p-c,p-c)*7.0)*.1;}
  mask*=1.0-smoothstep(.55,1.05,r);
 }else if(effect==10){ // water ripples and waves
  float phase=r*14.0-t*12.566;mask=pow(max(0.0,sin(phase)),9.0)*(1.0-smoothstep(.5,1.0,r))*.6;
 }else if(effect==11){ // flame silhouette, continuous flicker
  float width=UV.y*.4;float sway=sin(UV.y*10.0+t*37.699)*.08*(1.0-UV.y);
  mask=(1.0-smoothstep(max(.001,width*.4),max(.002,width),abs(p.x-sway)))*smoothstep(0.0,.2,UV.y)*(1.0-smoothstep(.85,1.0,UV.y));
 }
 if(effect==12){
  vec2 left=p-vec2(-.24,-.2);vec2 right=p-vec2(.24,.2);
  mask=(1.0-smoothstep(.15,.22,length(left*vec2(1.0,.5))))+(1.0-smoothstep(.15,.22,length(right*vec2(1.0,.5))));
  mask*=1.0-t;
 }
 float envelope=(effect>=8)?1.0:fade;
 ALBEDO=tint.rgb;EMISSION=tint.rgb*1.8;ALPHA=clamp(mask*envelope*tint.a,0.0,1.0);
}
'''
(OUT/'effect.gdshader').write_text(shader)
(OUT/'effect_player.gd').write_text('''extends Node3D
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
''')
# mode, color, duration, width, height, density
combat=[(0,'d7e4e5',.36,2,2,1),(0,'cbd8d3',.22,1.2,1.2,1),(1,'d6e7e9',.32,2.5,.9,1),(2,'e2b86d',.35,1.8,1.8,1),(2,'c8d9e8',.38,1.6,1.6,1),(5,'e3bd92',.32,1.1,1.1,1),(1,'cab78a',.25,1.8,.45,1),(2,'d5c396',.28,1,1,1),(2,'73cbd0',.8,3,3,1),(3,'a5c4dc',1,1.5,2,1),(3,'8bcfa5',1.2,2,2.5,1),(7,'a2a6b9',1,1.5,2.5,1),(5,'a8b6b5',.8,2.5,2.5,1),(4,'d0d7d7',.8,2.5,2.5,1),(5,'b3adcf',1,2.8,2.8,1),(6,'a9b49a',.75,2.8,2.8,1),(6,'7b9d76',.6,2.8,2.8,1)]
weather=[(8,'d9e6ef',8,14,10,1),(8,'839bad',2,14,10,5),(9,'aabac3',18,16,6,1),(10,'92b9bf',4,5,2,1),(10,'b4d4d8',8,9,3,1),(9,'7b838c',8,2,4,1),(11,'f5a94d',2,1.6,2.4,1),(11,'ef9940',1.5,.7,1.2,1),(8,'76c5d0',9,5,5,.7),(9,'78c1cb',6,3,3,1),(8,'bb8b54',10,10,7,1.6),(12,'d0e4ec',1,1,.6,1)]
base=json.loads((ROOT/'docs/full-asset-registry.json').read_text());entries=[e for e in base['entries'] if e['category'] in ['전투 VFX','환경 VFX']]
catalog=[]
for e,cfg in zip(entries,combat+weather):
 mode,color,duration,w,h,density=cfg;rgb=[int(color[i:i+2],16)/255 for i in [0,2,4]];loop=e['category']=='환경 VFX' and e['name']!='눈 발자국'
 key=e['id'];prefix='res://assets/production/vfx/'
 scene=f'''[gd_scene load_steps=5 format=3]
[ext_resource type="Shader" path="{prefix}effect.gdshader" id="1"]
[ext_resource type="Script" path="{prefix}effect_player.gd" id="2"]
[sub_resource type="ShaderMaterial" id="Material"]
resource_local_to_scene = true
shader = ExtResource("1")
shader_parameter/effect = {mode}
shader_parameter/tint = Color({rgb[0]}, {rgb[1]}, {rgb[2]}, 0.8)
shader_parameter/density = {density}
[sub_resource type="QuadMesh" id="Quad"]
size = Vector2({w}, {h})
[node name="{key.replace('-','_')}" type="Node3D"]
script = ExtResource("2")
duration = {duration}
loop = {str(loop).lower()}
metadata/asset_id = "{key}"
metadata/display_name = "{e['name']}"
[node name="Visual" type="MeshInstance3D" parent="."]
position = Vector3(0, {h/2}, 0)
mesh = SubResource("Quad")
material_override = SubResource("Material")
cast_shadow = 0
'''
 (OUT/(key+'.tscn')).write_text(scene)
 catalog.append(dict(id=key,name=e['name'],path=prefix+key+'.tscn',duration=duration,loop=loop,stage='native shader effect; gameplay connection pending'))
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
print('Authored',len(catalog),'controllable native VFX scenes')
