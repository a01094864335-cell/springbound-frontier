"""Small Godot text-scene authoring helper. No generation side effects on import."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
def vec(v):return 'Vector3('+', '.join(f'{n:.6g}' for n in v)+')'
class Scene:
 def __init__(self,key,name,folder='props'):
  self.key,self.name,self.folder=key,name,folder;self.resources=[];self.nodes=[];self.ext={};self.obstacles=[];self.count=0
 def material(self,name):
  if name not in self.ext:self.ext[name]=len(self.ext)+1
  return 'ExtResource("m'+str(self.ext[name])+'")'
 def sub(self,kind,props):
  self.count+=1;k='r'+str(self.count);self.resources.append(f'[sub_resource type="{kind}" id="{k}"]\n{props}\n');return 'SubResource("'+k+'")'
 def node(self,kind,name,props='',parent='.'):
  self.nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n{props}\n')
 def mesh(self,kind,name,pos,props,mat,rot=None):
  mesh=self.sub(kind,props);p='position = '+vec(pos)+'\nmesh = '+mesh+'\nmaterial_override = '+self.material(mat)
  if rot:p+='\nrotation_degrees = '+vec(rot)
  self.node('MeshInstance3D',name,p)
 def box(self,name,pos,size,mat='wood',rot=None):self.mesh('BoxMesh',name,pos,'size = '+vec(size),mat,rot)
 def cyl(self,name,pos,radius,height,mat='wood',top=None,rot=None):self.mesh('CylinderMesh',name,pos,f'top_radius = {radius if top is None else top}\nbottom_radius = {radius}\nheight = {height}\nradial_segments = 12\nrings = 1',mat,rot)
 def sphere(self,name,pos,radius,mat='stone',scale=(1,1,1)):
  self.mesh('SphereMesh',name,pos,f'radius = {radius}\nheight = {radius*2}\nradial_segments = 12\nrings = 6',mat)
  self.nodes[-1]+='scale = '+vec(scale)+'\n'
 def collide(self,rect,height=1.2):
  x,z,w,d=rect;self.obstacles.append(rect);index=len(self.obstacles);shape=self.sub('BoxShape3D','size = '+vec((w,height,d)))
  self.node('StaticBody3D','Body'+str(index),'position = '+vec((x+w/2,height/2,z+d/2)))
  self.node('CollisionShape3D','Shape','shape = '+shape,'Body'+str(index))
 def save(self,meta=None,script=None):
  out=ROOT/'game/assets/production'/self.folder;out.mkdir(parents=True,exist_ok=True)
  ex=[f'[ext_resource type="Material" path="res://assets/production/interiors/materials/{k}.tres" id="m{v}"]\n' for k,v in self.ext.items()]
  if script:ex.append(f'[ext_resource type="Script" path="{script}" id="script"]')
  root=f'[node name="{self.key.replace("-","_")}" type="Node3D"]\nmetadata/asset_id = "{self.key}"\nmetadata/display_name = {json.dumps(self.name,ensure_ascii=False)}\nmetadata/grid_obstacles = {json.dumps(self.obstacles)}\nmetadata/stage = "native_first_pass"\n'
  if meta and 'stage' in meta:root=root.replace('metadata/stage = "native_first_pass"','metadata/stage = '+json.dumps(meta['stage']))
  if script:root+='script = ExtResource("script")\n'
  for k,v in (meta or {}).items():
   if k!='stage':root+='metadata/'+k+' = '+json.dumps(v,ensure_ascii=False)+'\n'
  path=out/(self.key+'.tscn');text='[gd_scene format=3]\n\n'+'\n'.join(ex+self.resources+[root]+self.nodes);path.write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)',r'\g<1>0.\2',text));return path
