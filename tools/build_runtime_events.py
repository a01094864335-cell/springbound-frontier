"""Author visual event timelines and four environment-state scenes, isolated from save/game logic."""
from native_scene import Scene,ROOT,vec
import json
OUT=ROOT/'game/assets/production/events';OUT.mkdir(exist_ok=True)
NAMES='문 개폐|상자 개폐|약 전달|레온 발견|검 대여|응급처치|첫 승리 떨림|부상자 부축|천막 설치|장치 활성화|배 출항|배 입항|교량 손상|교량 복구'.split('|')
configs=[]
def track(node,prop,values):return {'node':node,'property':prop,'keys':values}
def key(t,value):return {'time':t,'value':value}
for i,name in enumerate(NAMES,1):
 s=Scene(f'presentation-3-{i:02}',name,'events');actors=[];props=[];tracks=[];duration=2.4
 def prop(node,id,pos=(0,0,0)):props.append({'node':node,'id':id,'position':pos})
 def actor(node,id,clip,pos):actors.append({'node':node,'actor':id,'clip':clip,'position':pos})
 if i==1:
  s.node('Node3D','DoorPivot','position = Vector3(-.6,0,0)');mesh=s.sub('BoxMesh','size = Vector3(1.2,2.1,0.12)');s.node('MeshInstance3D','Door','position = Vector3(.6,1.05,0)\nmesh = '+mesh+'\nmaterial_override = '+s.material('wood'),'DoorPivot')
  tracks=[track('DoorPivot','rotation_degrees',[key(0,[0,0,0]),key(.8,[0,-95,0]),key(1.5,[0,-95,0]),key(2.4,[0,0,0])])]
 elif i==2:
  prop('Chest','prop-2-17');s.node('Node3D','LidPivot','position = Vector3(0,.9,-.5)');mesh=s.sub('BoxMesh','size = Vector3(1.05,.1,1.05)');s.node('MeshInstance3D','Lid','position = Vector3(0,0,.5)\nmesh = '+mesh+'\nmaterial_override = '+s.material('wood'),'LidPivot');tracks=[track('LidPivot','rotation_degrees',[key(0,[0,0,0]),key(.9,[-100,0,0]),key(1.5,[-100,0,0]),key(2.4,[0,0,0])])]
 elif i==3:
  actor('Ael','pc-ael','motion-pc-ael-2-3',[-1,0,0]);actor('Marta','npc-marta','motion-npc-marta-2-2',[1,0,0]);prop('Medicine','prop-3-03',[-.7,1,0]);tracks=[track('Medicine','position',[key(0,[-.7,1,0]),key(1.2,[.7,1,0]),key(2.4,[.7,1,0])])]
 elif i in [4,5,6,7,8]:
  duration=3.2;actor('Ael','pc-ael',{4:'motion-pc-ael-0-3',5:'event-pc-ael-07',6:'event-pc-ael-06',7:'party-0-0-5-0',8:'motion-pc-ael-1-3'}[i],[-1,0,0]);actor('Leon','npc-leon','event-npc-leon-04' if i==5 else 'event-npc-leon-03',[1,0,0])
  if i==4:tracks=[track('Ael','position',[key(0,[-3,0,0]),key(1.5,[-1,0,0]),key(3.2,[-1,0,0])])]
  if i==5:
   s.box('BorrowedSword',(0,.9,0),(.08,.9,.04),'iron');tracks=[track('BorrowedSword','position',[key(0,[.6,.9,0]),key(1.7,[-.6,.9,0]),key(3.2,[-.6,.9,0])])]
  if i==6:prop('Bandages','prop-3-05',[0,0,.4])
  if i==7:
   # Dedicated trembling clip is selected in packaging overrides; no jubilant ceremony.
   actors[0]['clip']='event-first-victory-tremble';actors.pop();tracks=[track('Ael','rotation_degrees',[key(0,[0,0,0]),key(.3,[0,2,0]),key(.6,[0,-2,0]),key(.9,[0,1,0]),key(1.3,[0,-1,0]),key(2,[0,0,0]),key(3.2,[0,0,0])])]
  if i==8:
   actors[0]['position']=[-.45,0,0];actors[1]['position']=[.45,0,0];actors[1]['clip']='event-npc-leon-05'
   tracks=[track('Ael','position',[key(0,[-.45,0,0]),key(3.2,[1.55,0,0])]),track('Leon','position',[key(0,[.45,0,0]),key(3.2,[2.45,0,0])])]
 elif i==9:
  prop('Tent','prop-4-03');tracks=[track('Tent','scale',[key(0,[1,.03,1]),key(1.8,[1,1,1]),key(2.4,[1,1,1])])]
 elif i==10:
  prop('Console','prop-6-08');s.node('OmniLight3D','ActivationLight','position = Vector3(0,1.6,0)\nlight_color = Color(.25,.8,.65,1)\nlight_energy = 0.0\nomni_range = 3.0');tracks=[track('ActivationLight','light_energy',[key(0,0),key(1.2,2),key(2.4,1)])]
 elif i in [11,12]:
  prop('Ship','prop-5-09');duration=4;tracks=[track('Ship','position',[key(0,[0,0,0] if i==11 else [0,0,-6]),key(4,[0,0,-6] if i==11 else [0,0,0])])]
 elif i in [13,14]:
  for k in range(5):
   s.node('Node3D','PlankPivot'+str(k),f'position = Vector3(0,0,{(k-2)*.5})');mesh=s.sub('BoxMesh','size = Vector3(2.8,.15,.45)');s.node('MeshInstance3D','Plank','mesh = '+mesh+'\nmaterial_override = '+s.material('wood'),'PlankPivot'+str(k))
   initial=[0,0,0] if i==13 else [0,0,50 if k%2 else -50];final=[0,0,50 if k%2 else -50] if i==13 else [0,0,0];tracks.append(track('PlankPivot'+str(k),'rotation_degrees',[key(0,initial),key(.6+k*.25,initial),key(1.4+k*.25,final),key(2.4,final)]))
 config={'id':s.key,'name':name,'duration':duration,'actors':actors,'props':props,'tracks':tracks,'runtime_connected':False,'stage':'event_visual_prototype','gameplay_effects':False}
 path=s.save({'duration':duration,'gameplay_effects':False,'stage':'event_visual_prototype'},'res://assets/production/events/event_player.gd');config.update(file=str(path.relative_to(ROOT)),path='res://assets/production/events/'+s.key+'.tscn');configs.append(config)
(OUT/'catalog.json').write_text(json.dumps(configs,ensure_ascii=False,indent=2)+'\n')
# Native environment-state variations: open travel lanes and different spatial storytelling.
STATES=[('서리골 출발',[('prop-2-12',[-4,0,0]),('prop-3-01',[4,0,2]),('prop-7-04',[-5,0,-5])]),('서리골 귀환 피난 준비',[('prop-4-03',[-4,0,-3]),('prop-4-04',[-4,0,3]),('prop-4-05',[4,0,3]),('prop-4-10',[4,0,-3])]),('서리골 에필로그 복구',[('prop-2-13',[-4,0,0]),('prop-3-10',[4,0,-3]),('prop-7-02',[-5,0,-5]),('prop-2-16',[4,0,4])]),('레온의 고향 에필로그',[('prop-2-12',[-4,0,0]),('prop-7-02',[-5,0,-5]),('prop-7-07',[4,0,-3]),('prop-3-18',[4,0,2])])]
world=[]
for i,(name,props) in enumerate(STATES,1):
 s=Scene('world-state-'+str(i),name,'world_states');s.box('Ground',(0,-.1,0),(16,.2,16),'linen' if i<3 else 'green');floor_shape=s.sub('BoxShape3D','size = Vector3(16,0.2,16)');s.node('StaticBody3D','GroundBody','position = Vector3(0,-0.1,0)');s.node('CollisionShape3D','Shape','shape = '+floor_shape,'GroundBody')
 for index,(id,pos) in enumerate(props):
  eid='p'+str(index);s.resources.insert(0,f'[ext_resource type="PackedScene" path="res://assets/production/props/{id}.tscn" id="{eid}"]');s.nodes.append(f'[node name="Prop{index}" parent="." instance=ExtResource("{eid}")]\nposition = {vec(pos)}\n')
 s.node('Marker3D','Entry','position = Vector3(0,0,6)');s.node('Marker3D','Exit','position = Vector3(0,0,-6)')
 path=s.save({'variation_only':True,'final_layout':False,'route_clearance':4,'stage':'world_state_blockout'});world.append({'id':s.key,'name':name,'file':str(path.relative_to(ROOT)),'path':'res://assets/production/world_states/'+s.key+'.tscn','stage':'world_state_blockout','runtime_connected':False,'props':props})
(ROOT/'game/assets/production/world_states/catalog.json').write_text(json.dumps(world,ensure_ascii=False,indent=2)+'\n')
print('Created 14 event visual timelines and 4 state blockouts')
