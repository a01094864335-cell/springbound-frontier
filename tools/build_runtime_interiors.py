"""Author reusable native Godot furniture and furnished interiors, with grid collision metadata."""
from pathlib import Path
import json, math
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'game/assets/production/interiors'
OUT.mkdir(exist_ok=True)
def vec(v):return 'Vector3('+', '.join(f'{n:.6g}' for n in v)+')'
class Scene:
 def __init__(self,key,name):
  self.key,self.name=key,name;self.resources=[];self.nodes=[];self.ext={};self.obstacles=[];self.count=0
 def material(self,name):
  if name not in self.ext:self.ext[name]=len(self.ext)+1
  return 'ExtResource("m'+str(self.ext[name])+'")'
 def sub(self,kind,props):
  self.count+=1;k='r'+str(self.count);self.resources.append('[sub_resource type="'+kind+'" id="'+k+'"]\n'+props+'\n');return 'SubResource("'+k+'")'
 def node(self,kind,name,props='',parent='.'):
  self.nodes.append('[node name="'+name+'" type="'+kind+'" parent="'+parent+'"]\n'+props+'\n')
 def box(self,name,pos,size,mat,rot=None):
  mesh=self.sub('BoxMesh','size = '+vec(size));props='position = '+vec(pos)+'\nmesh = '+mesh+'\nmaterial_override = '+self.material(mat)
  if rot:props+='\nrotation_degrees = '+vec(rot)
  self.node('MeshInstance3D',name,props)
 def cyl(self,name,pos,radius,height,mat,top=None,rot=None):
  mesh=self.sub('CylinderMesh',f'top_radius = {radius if top is None else top}\nbottom_radius = {radius}\nheight = {height}\nradial_segments = 12\nrings = 1')
  props='position = '+vec(pos)+'\nmesh = '+mesh+'\nmaterial_override = '+self.material(mat)
  if rot:props+='\nrotation_degrees = '+vec(rot)
  self.node('MeshInstance3D',name,props)
 def collide(self,rect,height=1.2):
  x,z,w,d=rect;self.obstacles.append(rect);index=len(self.obstacles);shape=self.sub('BoxShape3D','size = '+vec((w,height,d)))
  self.node('StaticBody3D','Body'+str(index),'position = '+vec((x+w/2,height/2,z+d/2)))
  self.node('CollisionShape3D','Shape','shape = '+shape,parent='Body'+str(index))
 def instance(self,name,path,pos,rot=0,scale=None):
  eid='instance'+str(len(self.ext)+1);self.ext[eid]=(path,'PackedScene');props='position = '+vec(pos)+'\nrotation_degrees = '+vec((0,rot,0))
  if scale:props+='\nscale = '+vec(scale)
  self.nodes.append('[node name="'+name+'" parent="." instance=ExtResource("'+eid+'") ]\n'+props+'\n')
 def save(self):
  ex=[]
  for k,v in self.ext.items():
   if isinstance(v,tuple):ex.append('[ext_resource type="'+v[1]+'" path="'+v[0]+'" id="'+k+'"]\n')
   else:ex.append('[ext_resource type="Material" path="res://assets/production/interiors/materials/'+k+'.tres" id="m'+str(v)+'"]\n')
  root='[node name="'+self.key.replace('-','_')+'" type="Node3D"]\nmetadata/asset_id = "'+self.key+'"\nmetadata/display_name = '+json.dumps(self.name,ensure_ascii=False)+'\nmetadata/grid_obstacles = '+json.dumps(self.obstacles)+'\nmetadata/origin = "ground center; entry +Z"\n'
  text='[gd_scene format=3]\n\n'+ '\n'.join(ex+self.resources+[root]+self.nodes)
  path=OUT/(self.key+'.tscn');path.write_text(text);return path
colors={'wood':(0.25,.16,.10),'trim':(.14,.09,.06),'linen':(.71,.68,.56),'blue':(.19,.29,.37),'stone':(.40,.43,.44),'iron':(.14,.17,.18),'brass':(.56,.43,.23),'clay':(.48,.30,.19),'green':(.28,.38,.23),'glass':(.28,.45,.40),'paper':(.76,.71,.55),'fire':(.94,.48,.14)}
(OUT/'materials').mkdir(exist_ok=True)
for name,c in colors.items():
 (OUT/'materials'/(name+'.tres')).write_text('[gd_resource type="StandardMaterial3D" format=3]\n\n[resource]\nalbedo_color = Color('+', '.join(map(str,c))+', 1)\nroughness = 0.9\n'+('emission_enabled = true\nemission = Color(0.8, 0.2, 0.04, 1)\nemission_energy_multiplier = 1.5\n' if name=='fire' else ''))
NAMES='침대|이층 침대|탁자|긴 식탁|의자|벤치|찬장|책장|진열 선반|계산대|책상|옷장|난로|벽난로|세면대|커튼|깔개|식기 세트|촛대|벽등'.split('|')
bounds={}
def furniture(i):
 s=Scene(f'prop-1-{i:02}',NAMES[i-1]);w,d=1.,1.;h=1.2
 def leg(x,z,height=.75):s.box('Leg'+str(len(s.nodes)),(x,height/2,z),(.11,height,.11),'trim')
 def table(width,depth,y=.78):
  s.box('Top',(0,y,0),(width,.12,depth),'wood')
  for x in [-width/2+.15,width/2-.15]:
   for z in [-depth/2+.15,depth/2-.15]:leg(x,z,y)
 def bed(y):
  s.box('Frame'+str(y),(0,y+.35,0),(1.15,.18,2.0),'wood');s.box('Mattress'+str(y),(0,y+.52,0),(1.05,.18,1.88),'linen')
  s.box('Blanket'+str(y),(0,y+.63,.3),(1.06,.06,1.2),'blue');s.box('Pillow'+str(y),(0,y+.65,-.65),(.72,.16,.4),'linen')
  for z in [-.98,.98]:s.box('Rail'+str(y)+str(z),(0,y+.55,z),(1.2,.5,.12),'wood')
 if i in [1,2]:
  w,d=1.2,2.05;h=1.9 if i==2 else .9;bed(0)
  if i==2:
   bed(1.25)
   for x in [-.55,.55]:
    for z in [-.94,.94]:s.box('Post'+str(x)+str(z),(x,1.05,z),(.1,2.1,.1),'trim')
   for k in range(5):s.box('Rung'+str(k),(.76,.25+k*.27,.65),(.36,.06,.06),'wood')
   for z in [.5,.8]:s.box('Ladder'+str(z),(.76,.85,z),(.06,1.7,.06),'trim')
 elif i in [3,4,11]:
  w,d=(2.8,1.05) if i==4 else (1.6,.85);table(w,d)
  if i==11:
   for z in [-.25,.1]:s.box('Drawer'+str(z),(.5,.58,z),(.5,.22,.3),'trim');s.cyl('Handle'+str(z),(.5,.58,z+.16),.035,.08,'brass',rot=(90,0,0))
 elif i in [5,6]:
  w,d=(1.8,.5) if i==6 else (.65,.65);table(w,d,.48)
  s.box('Back',(0,.9,-d/2+.04),(w,.8,.09),'wood')
 elif i in [7,8,9,12]:
  w,d=(1.5,.48) if i!=12 else (1.35,.7);h=1.9
  for x in [-w/2,w/2]:s.box('Side'+str(x),(x,.95,0),(.1,1.9,d),'wood')
  s.box('Back',(0,.95,-d/2),(w,1.9,.06),'trim')
  for y in [.1,.55,1.0,1.45,1.9]:s.box('Shelf'+str(y),(0,y,0),(w,.08,d),'wood')
  if i in [7,12]:
   for x in [-w/4,w/4]:
    s.box('Door'+str(x),(x,.95,d/2+.03),(w/2-.04,1.78,.07),'wood');s.cyl('Pull'+str(x),(x*.2,1.05,d/2+.1),.035,.07,'brass',rot=(90,0,0))
  elif i==8:
   for row,y in enumerate([.15,.6,1.05,1.5]):
    for j in range(8):s.box('Book'+str(row)+'_'+str(j),(-.55+j*.15,y+.15,0),(.09,.3+(j%3)*.04,.28),['blue','green','paper'][j%3])
 elif i==10:
  w,d=2.5,.7;h=1.1;s.box('Counter',(0,.52,0),(w,1.04,d),'wood');s.box('CounterTop',(0,1.1,.04),(w+.12,.14,d+.15),'trim')
  for x in [-1,-.5,0,.5,1]:s.box('Panel'+str(x),(x,.54,.36),(.04,.85,.025),'brass')
 elif i in [13,14]:
  w,d=(.75,.75) if i==13 else (1.8,.85);h=1.8
  if i==13:s.cyl('Stove',(0,.55,0),.34,.95,'iron');s.cyl('Pipe',(0,1.5,-.15),.10,1.1,'iron');s.box('Door',(0,.55,.31),(.33,.38,.08),'trim')
  else:
   for x in [-.68,.68]:s.box('Jamb'+str(x),(x,.65,0),(.3,1.3,d),'stone')
   s.box('Hood',(0,1.4,-.12),(1.8,.5,.62),'stone');s.box('Hearth',(0,.1,.08),(1.9,.2,1.0),'stone');s.box('Back',(0,.65,-.32),(1.3,1.1,.12),'stone')
  s.box('Coals',(0,.23,.1),(.5,.09,.4),'fire')
 elif i==15:
  w,d=.9,.6;table(w,d,.8);s.cyl('Basin',(0,.91,0),.27,.12,'linen',top=.31);s.cyl('Water',(0,.978,0),.24,.01,'glass');s.cyl('Jug',(.30,1.0,-.12),.09,.3,'clay',top=.06)
 elif i==16:
  w,d=2.0,.16;h=2.0
  for x in [-.95,.95]:s.box('Pole'+str(x),(x,1,0),(.08,2,.08),'wood')
  s.box('Rod',(0,2.02,0),(2.05,.07,.07),'iron')
  for k in range(16):s.box('Cloth'+str(k),(-.88+k*.117,1.02,.03 if k%2 else -.03),(.12,1.85,.05),'linen')
 elif i==17:
  w,d=2.4,1.5;h=.025;s.box('Rug',(0,.012,0),(w,.024,d),'blue')
  for x in [-1.1,1.1]:s.box('RugBorder'+str(x),(x,.026,0),(.06,.008,1.35),'linen')
  for z in [-.65,.65]:s.box('RugBorderZ'+str(z),(0,.026,z),(2.2,.008,.06),'linen')
 elif i==18:
  w,d=.65,.45;h=.25
  s.cyl('Plate',(0,.025,0),.22,.05,'linen');s.cyl('Cup',(.23,.12,-.12),.07,.2,'clay',top=.085);s.box('Spoon',(-.25,.035,0),(.035,.025,.28),'wood')
 elif i in [19,20]:
  w,d=.28,.3;h=.6
  s.cyl('Base',(0,.03,0),.14,.06,'iron');s.cyl('Stem',(0,.2,0),.025,.32,'brass');s.cyl('Cup',(0,.36,0),.09,.035,'brass');s.cyl('Wax',(0,.46,0),.045,.18,'linen');s.cyl('Flame',(0,.58,0),.035,.08,'fire',top=.0)
  if i==20:s.box('WallMount',(0,.25,-.16),(.15,.4,.06),'iron');s.box('Bracket',(0,.1,-.07),(.04,.05,.25),'iron')
 if i in [3,4,11]:
  for z in [-d/2+.12,d/2-.12]:s.box('Apron'+str(z),(0,.6,z),(w-.18,.2,.08),'trim')
 if i in [7,12]:
  for x in [-w/4,w/4]:
   for y in [.16,1.74]:s.box('DoorTrim'+str(x)+str(y),(x,y,d/2+.075),(w/2-.12,.05,.025),'trim')
 if i not in [16,17,18,19,20]:s.collide([-w/2,-d/2,w,d],h)
 bounds[s.key]=(w,d,h)
 s.save();return s
# Match the project's existing textured environment, preserving source textures.
for name,idx,tint in [('wood',3,(.8,.74,.65)),('stone',2,(.86,.86,.85)),('plaster',5,(.86,.85,.77))]:
 (OUT/'materials'/(name+'.tres')).write_text('[gd_resource type="StandardMaterial3D" format=3]\n[ext_resource type="Texture2D" path="res://assets/environment/materials/texture_'+str(idx)+'.res" id="1"]\n[resource]\nalbedo_color = Color('+', '.join(map(str,tint))+', 1)\nalbedo_texture = ExtResource("1")\nuv1_scale = Vector3(0.16, 0.16, 0.16)\nuv1_triplanar = true\nuv1_world_triplanar = true\ntexture_filter = 0\nroughness = 0.9\n')
for i in range(1,21):furniture(i)
# Furniture arrangements are authored in metres; all central entry routes remain free.
# Each tuple: furniture index, x, z, yaw. Root floor is 12 x 12, front entry +Z.
layouts=[
 [(11,-3,-1,0),(5,-3,1,0),(8,-3,-4,0),(1,3,-3,0),(14,4,0,90),(7,3,-5,0),(15,-4,3,0)],
 [(3,-3,0,0),(5,-3,1,0),(1,3,-3,0),(1,3,0,0),(7,-3,-4,0),(14,0,-5,0)],
 [(10,0,-2,0),(9,-4,-1,90),(9,-4,2,90),(9,4,-2,-90),(7,3,-5,0),(11,-3,-4,0)],
 [(1,-3,-3,0),(11,3,0,90),(15,3,-3,0),(7,-3,2,0),(14,0,-5,0)],
 [(4,-3,-1,90),(6,-4.1,-1,90),(6,-1.9,-1,-90),(4,3,-1,90),(6,1.9,-1,90),(6,4.1,-1,-90),(10,0,-4,0)],
 [(1,-3,-3,0),(1,-3,1,0),(15,3,2,0),(7,3,-3,0),(11,0,-4,0)],
 [(10,0,-2,0),(8,0,-5,0),(11,3,-4,0),(6,-4,2,90),(7,4,2,0)],
 [(2,-3,-3,0),(2,3,-3,0),(2,-3,1,0),(2,3,1,0),(6,0,-5,0)],
 [(4,0,-1,0),(11,0,-4,0),(5,0,-5,180),(8,-4,-4,0),(7,4,-4,0),(6,-4,2,90)],
 [(5,-1,-4,0),(5,1,-4,0),(6,-4,0,90),(6,4,0,-90),(17,0,0,0),(19,-2,-4,0),(19,2,-4,0)],
 [(11,0,-2,0),(5,0,-3,0),(5,-1,0,180),(5,1,0,180),(8,-4,-4,0),(7,4,-4,0)],
 [(8,-4,-3,90),(8,-4,0,90),(8,4,-3,-90),(8,4,0,-90),(3,-2,2,0),(3,2,2,0),(11,0,-4,0)],
 [(3,0,0,0),(11,-3,-3,0),(9,3,-4,0),(7,4,2,0),(5,-3,-2,180)],
 [(1,-3,-3,0),(1,3,-3,0),(11,-3,1,0),(11,3,1,0),(7,0,-5,0)],
 [(9,-3,-3,0),(9,3,-3,0),(9,-3,1,0),(9,3,1,0),(11,0,-5,0)],
 [(9,-4,-3,90),(9,-4,0,90),(9,4,-3,-90),(9,4,0,-90),(7,-3,-5,0),(7,3,-5,0),(11,3,3,0)],
 [(3,-3,0,0),(3,-3,3,0),(3,3,3,0),(10,3,-2,0),(7,3,-5,0),(14,-4,-4,0)],
 [(1,-3,-3,0),(11,3,-3,0),(7,3,1,0),(5,3,-2,180)],
 [(7,-3,-3,0),(7,3,-3,0),(7,-3,1,0),(7,3,1,0),(9,-4,-1,90),(9,4,-1,-90)],
 [(6,-3,-2,0),(6,3,-2,0),(6,-3,1,0),(6,3,1,0),(3,0,-5,0),(19,-2,-5,0),(19,2,-5,0)],
 [(8,-4,-3,90),(8,-4,0,90),(8,4,-3,-90),(8,4,0,-90),(4,0,1,0),(7,0,-5,0)],
 [(3,0,-1,0),(9,-4,-3,90),(9,4,-3,-90),(3,0,-5,0),(19,-3,2,0),(19,3,2,0)]
]
room_names='약초사 집|주민 주택|상점|여관 객실|여관 식당|진료실|연락소|병영 침실|지휘실|왕성 접견실|행정청 집무실|도서관|연구실|기숙사|유물 보관실|창고|선술집|선실|화물칸|예배당|기록실|유적 통제실'.split('|')
rooms=[]
for index,(name,layout) in enumerate(zip(room_names,layouts),1):
 s=Scene(f'interior-{index:02}',name+' 실내 세트')
 s.box('Floor',(0,-.12,0),(12,.24,12),'wood' if index not in [6,10,15,20,22] else 'stone')
 # Walls have the same bounds in physics and grid metadata. Front has 2m clear entry.
 for j,(pos,size) in enumerate([((0,1.4,-6),(12.3,2.8,.3)),((-6,1.4,0),(.3,2.8,12)),((6,1.4,0),(.3,2.8,12)),((-3.55,.5,6),(4.9,1,.3)),((3.55,.5,6),(4.9,1,.3))]):
  s.box('Wall'+str(j),pos,size,'stone' if index in [10,15,20,22] else 'plaster');s.collide([pos[0]-size[0]/2,pos[2]-size[2]/2,size[0],size[2]],size[1])
 for x in [-5.75,5.75]:
  for z in [-5.75,0,5.75]:s.box('Beam'+str(x)+str(z),(x,1.4,z),(.2,2.8,.2),'trim')
 for j,(f,x,z,yaw) in enumerate(layout):
  key=f'prop-1-{f:02}';s.instance('Furniture'+str(j),'res://assets/production/interiors/'+key+'.tscn',(x,0,z),yaw)
  if f not in [16,17,18,19,20]:
   w,d,h=bounds[key]
   if yaw%180:w,d=d,w
   # Child contains physics. Root metadata provides only navigation bounds.
   s.obstacles.append([x-w/2,z-d/2,w,d])
 # Timber rails and full-room floor edging maintain readable grounded construction.
 for z in [-5.83,5.83]:
  s.box('FloorEdge'+str(z),(0,.015,z),(11.7,.03,.13),'trim')
 for x in [-5.83,5.83]:
  s.box('FloorEdgeX'+str(x),(x,.015,0),(.13,.03,11.7),'trim')
 s.box('BackRail',(0,2.65,-5.78),(11.7,.16,.18),'trim')
 # Navigation and event anchors do not imply scripted story events.
 s.node('Marker3D','Entry','position = Vector3(0, 0, 5)')
 s.node('Marker3D','Focus','position = Vector3(0, 0, '+('0' if index==11 else '-3')+')')
 s.node('Marker3D','CameraTarget','position = Vector3(0, 0, 0)')
 s.save();rooms.append(dict(id=s.key,name=s.name,path='res://assets/production/interiors/'+s.key+'.tscn',bounds=[-6,-6,12,12],entry=[0,0,5],grid_obstacles=s.obstacles))
(OUT/'catalog.json').write_text(json.dumps(dict(furniture=[dict(id=k,path='res://assets/production/interiors/'+k+'.tscn',bounds=v) for k,v in bounds.items()],rooms=rooms),ensure_ascii=False,indent=2)+'\n')
print('Authored',len(bounds),'furniture scenes and',len(rooms),'interior scenes')
