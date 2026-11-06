"""Recreate the 112 unavailable props as authored low-poly first-pass Godot scenes."""
from native_scene import Scene,ROOT
import json,math
rows=json.loads((ROOT/'docs/full-asset-registry.json').read_text())['entries'];rows=[x for x in rows if x['category'] in ['생활 소품','직업 소품','군사·피난','항만·운송','유적 장치','자연']]
assert len(rows)==112
catalog=[]
for e in rows:
 s=Scene(e['id'],e['name']);group,i=map(int,e['id'].split('-')[1:]);w,d,h=1.,1.,1.;solid=True
 def box(name,pos,size,mat='wood',rot=None):s.box(name,pos,size,mat,rot)
 def cyl(name,pos,r,height,mat='wood',top=None,rot=None):s.cyl(name,pos,r,height,mat,top,rot)
 def sphere(name,pos,r,mat='stone',scale=(1,1,1)):s.sphere(name,pos,r,mat,scale)
 def crate(prefix='Crate',x=0,z=0,open=False,size=1):
  box(prefix+'Bottom',(x,.06,z),(size,.12,size))
  for k in range(3):
   y=.2+k*.26
   for side in [-1,1]:box(prefix+f'WallX{k}{side}',(x+side*(size/2-.05),y,z),(.1,.22,size));box(prefix+f'WallZ{k}{side}',(x,y,z+side*(size/2-.05)),(size,.22,.1))
  if not open:box(prefix+'Lid',(x,.9,z),(size+.04,.1,size+.04))
  for side in [-1,1]:box(prefix+'Band'+str(side),(x+side*size*.3,.5,z),(size*.08,1,size+.02),'iron')
 def barrel(prefix='Barrel',x=0,z=0,opened=False):
  cyl(prefix+'Body',(x,.5,z),.42,1,'wood',.36)
  for y in [.14,.85]:cyl(prefix+'Band'+str(y),(x,y,z),.435,.08,'iron',.39)
  cyl(prefix+'Top',(x,1.01,z),.35,.04,'trim' if opened else 'wood')
 def tabletop(width=1.8,depth=.8,height=.8):
  box('Top',(0,height,0),(width,.12,depth))
  for x in [-width/2+.12,width/2-.12]:
   for z in [-depth/2+.12,depth/2-.12]:box(f'Leg{x}{z}',(x,height/2,z),(.12,height,.12),'trim')
 def paper(prefix,x=0,y=.9,z=0):box(prefix,(x,y,z),(.35,.025,.48),'paper')
 def post(prefix,x,z,height=1.4):cyl(prefix,(x,height/2,z),.08,height)
 def roof():
  for side in [-1,1]:box('Canvas'+str(side),(side*.6,1.35,0),(1.5,.05,2.7),'linen',(0,0,side*48))
 def rocks(prefix='Rock',n=4):
  for k in range(n):sphere(prefix+str(k),((k%2-.5)*.55,.3,(k//2-.5)*.5),.45,'stone',(1,.7,1))
 if group==2:
  if i in [1,2,17,18,19]:
   crate(open=i in [2,17,19]);
   if i in [18,19]:
    for z in [-.52,.52]:box('ChestRim'+str(z),(0,.95,z),(1.05,.1,.08),'brass')
    if i==19:box('RaisedLid',(0,1.25,-.52),(1.05,.65,.1),'wood',(-15,0,0))
    else:box('Latch',(0,.65,.53),(.16,.18,.06),'brass')
  elif i in [3,4]:barrel(opened=i==4)
  elif i==5:
   cyl('Basket',(0,.3,0),.38,.6,'wood',.48);cyl('Interior',(0,.61,0),.41,.03,'trim');post('HandleL',-.4,0,.9);post('HandleR',.4,0,.9);box('Handle',(0,.9,0),(.8,.06,.08))
  elif i==6:cyl('Jar',(0,.4,0),.38,.8,'clay',.24);cyl('Rim',(0,.82,0),.27,.07,'clay');cyl('Opening',(0,.86,0),.19,.01,'trim')
  elif i==7:sphere('Sack',(0,.4,0),.45,'linen',(1,1.1,.8));cyl('Tie',(0,.85,0),.14,.1,'wood')
  elif i==8:
   w,d,h=1.5,1.4,.7
   for k in range(6):cyl('Log'+str(k),((k%3-1)*.42,.2+(k//3)*.35,0),.19,1.3,'wood',rot=(90,0,0))
  elif i==9:cyl('WellCover',(0,.12,0),.75,.24);w=d=1.5;h=.3
  elif i==10:
   w,d,h=3,.6,2;post('Left',-1.4,0,2);post('Right',1.4,0,2);box('Rope',(0,1.9,0),(2.8,.03,.03),'linen')
   for k in range(3):box('Cloth'+str(k),(-.9+k*.9,1.35,0),(.55,.9,.025),'linen' if k%2 else 'blue')
  elif i==11:post('BroomHandle',0,0,1.6);box('Bristles',(0,.23,0),(.48,.45,.16),'linen');w,d,h=.5,.2,1.6
  elif i in [12,13,14]:
   w,d,h=(1.7,.25,1.7);post('Post',0,0,1.5);box('Sign',(0,1.3,0),(1.6,.65,.12),'wood')
   if i==13:
    for k in range(3):box('Notice'+str(k),(-.5+k*.5,1.3,.071),(.35,.4,.015),'paper')
   if i==14:box('Hanger',(0,1.75,0),(1.8,.1,.18),'iron')
  elif i==15:cyl('Wheel',(0,.6,0),.6,.12,'trim',rot=(90,0,0));cyl('Hub',(0,.6,.09),.13,.22,'wood',rot=(90,0,0));w,d,h=1.2,.3,1.2
  elif i==16:
   w,d,h=1.8,2.6,1.1;box('CartBed',(0,.65,0),(1.7,.15,2.2));
   for side in [-1,1]:box('CartWall'+str(side),(side*.8,.95,0),(.12,.55,2.2));cyl('Wheel'+str(side),(side*1,.5,0),.5,.16,'trim',rot=(0,0,90));box('Handle'+str(side),(side*.55,.55,1.5),(.1,.12,1.3))
 elif group==3:
  if i==1:
   w,d,h=1.6,.8,1.8
   for x in [-.7,.7]:post('Rack'+str(x),x,0,1.7)
   for y in [.6,1.1,1.6]:
    box('Rail'+str(y),(0,y,0),(1.5,.06,.08));
    for k in range(4):sphere(f'Herb{y}{k}',(-.55+k*.36,y-.13,0),.13,'green',(1,1.5,1))
  elif i==2:cyl('Mortar',(0,.2,0),.28,.4,'stone',.36);cyl('Bowl',(0,.41,0),.26,.02,'trim');cyl('Pestle',(.13,.58,0),.06,.6,'stone',rot=(0,0,-25));w=d=.8;h=.9
  elif i==3:cyl('Bottle',(0,.25,0),.18,.5,'glass');cyl('Neck',(0,.56,0),.08,.15,'glass');cyl('Cork',(0,.66,0),.085,.06,'wood');w=d=.5;h=.7
  elif i in [4,6]:
   w,d,h=1.1,2.2,.8;box('Canvas',(0,.7,0),(1,.15,2),'linen')
   for x in [-.55,.55]:box('Rail'+str(x),(x,.6,0),(.08,.1,2.4))
   if i==4:
    for x in [-.5,.5]:
     for z in [-.9,.9]:box(f'Leg{x}{z}',(x,.3,z),(.08,.6,.08),'iron')
  elif i==5:
   for k in range(3):cyl('Roll'+str(k),((k-1)*.25,.18,0),.14,.45,'linen',rot=(90,0,0))
   w,d,h=.9,.6,.4
  elif i==7:
   w=d=1.5;h=1.5;box('Hearth',(0,.4,0),(1.4,.8,1.3),'stone');box('Fire',(0,.83,0),(.75,.08,.6),'fire');box('Chimney',(0,1.2,-.4),(.5,.8,.5),'stone')
  elif i==8:box('Base',(0,.35,0),(.7,.7,.6),'wood');box('Anvil',(0,.85,0),(1.1,.3,.5),'iron');cyl('Horn',(.65,.85,0),.18,.5,'iron',0,(0,0,90));w,d,h=1.5,.7,1
  elif i==9:box('HammerHandle',(-.2,.08,0),(.07,.08,.8));box('HammerHead',(-.2,.15,-.3),(.4,.2,.17),'iron');box('TongsA',(.2,.08,0),(.04,.08,.8),'iron',(0,15,0));box('TongsB',(.25,.08,0),(.04,.08,.8),'iron',(0,-15,0));w,d,h=.8,1,.3
  elif i==10:tabletop(2.2,1);w,d,h=2.3,1.1,1.1;crate('Display',size=.6)
  elif i==11:
   w,d,h=1.6,1.4,.2
   for k in range(6):box('MeshX'+str(k),(-.75+k*.3,.08,0),(.025,.025,1.4),'linen');box('MeshZ'+str(k),(0,.08,-.65+k*.26),(1.5,.025,.025),'linen')
   solid=False
  elif i==12:box('Rod',(0,.06,0),(.04,.04,2),'wood');cyl('Reel',(0,.14,.45),.12,.12,'iron',rot=(0,0,90));w,d,h=.4,2.2,.3
  elif i in [13,14]:
   w=d=1.3;h=1.7
   for k in range(3):a=k*math.tau/3;box('Leg'+str(k),(math.cos(a)*.35,.7,math.sin(a)*.35),(.06,1.4,.06),'wood',(math.sin(a)*24,0,math.cos(a)*24))
   cyl('Instrument',(0,1.5,0),.18,.25,'brass');cyl('Lens',(0,1.6,0),.09,.6,'iron',rot=(90,0,0))
  elif i==15:tabletop(1.6,1);paper('Map',0,.88,0);w,d,h=1.8,1.1,1
  elif i==16:
   for k in range(5):paper('Paper'+str(k),0,.04+k*.04,0)
   box('Tie',(0,.25,0),(.06,.03,.5),'blue');w,d,h=.5,.6,.3
  elif i==17:cyl('Seal',(0,.2,0),.1,.4,'brass');box('InkPad',(.3,.06,0),(.3,.12,.3),'trim');w,d,h=.7,.5,.4
  elif i==18:box('Book',(0,.07,0),(.55,.14,.7),'blue');box('Pages',(0,.075,.015),(.52,.09,.68),'paper');w,d,h=.6,.8,.2
  elif i==19:crate(size=.8);box('Relic',(0,1.02,0),(.25,.1,.25),'brass');w=d=1;h=1.1
 elif group==4:
  if i in [1,12]:
   w,d,h=3,.8,1.2
   for x in [-1.2,1.2]:box('Foot'+str(x),(x,.25,0),(.15,.15,1),'wood');post('Post'+str(x),x,0,1.2)
   for y in [.45,.95]:box('Crossbar'+str(y),(0,y,0),(3,.14,.14),'wood')
  elif i in [2,3]:
   w,d,h=2.4,2.7,2.1
   for z in [-1.2,1.2]:
    for side in [-1,1]:box(f'Pole{z}{side}',(side*.6,1,z),(.08,2.2,.08),'wood',(0,0,side*33))
    box('Ridge'+str(z),(0,1.9,0),(.08,.08,2.7),'wood')
   if i==3:roof()
  elif i==4:crate('Luggage',size=.65);sphere('Bundle',(.5,.25,.3),.3,'linen');w,d,h=1.5,1.2,1
  elif i==5:crate();box('SupplyMark',(0,1,0),(.5,.02,.12),'linen');w=d=1.1;h=1.1
  elif i==6:post('Pole',0,0,2.7);box('Banner',(.5,2,0),(1,.8,.035),'blue');w,d,h=1.2,.4,2.8
  elif i in [7,8]:
   w,d,h=2,.8,1.6;post('StandL',-.9,0,1.5);post('StandR',.9,0,1.5);box('Rail',(0,1.2,0),(2,.08,.1))
   for k in range(4):
    if i==7:box('Weapon'+str(k),(-.65+k*.43,.85,0),(.08,1.5,.08),'iron')
    else:cyl('Shield'+str(k),(-.65+k*.43,.85,0),.25,.08,'blue',rot=(90,0,0))
  elif i==9:post('Pole',0,0,1.6);cyl('Target',(0,1.35,0),.5,.16,'linen',rot=(90,0,0));cyl('Center',(0,1.35,.1),.16,.03,'clay',rot=(90,0,0));w,d,h=1.2,.5,2
  elif i==10:box('Hearth',(0,.3,0),(1,.6,.9),'stone');box('Embers',(0,.65,0),(.7,.08,.6),'fire');cyl('Pot',(0,.9,0),.32,.4,'iron');w,d,h=1.2,1.1,1.1
  elif i==11:box('Cot',(0,.55,0),(1,.15,2),'linen');w,d,h=1.1,2.2,.7
 elif group==5:
  if i in [1,2,3,9,10,11,15]:
   w,d,h=(3,3,.5) if i in [1,2] else (2.2,3,.5)
   if i==9:w,d,h=3,6,1.5;box('Hull',(0,.6,0),(3,1.2,6),'wood');box('Bow',(0,.65,-3), (2,.8,1),'wood');box('Cabin',(0,1.7,.8),(2,1.6,2),'blue')
   elif i==3:
    h=1.2
    for k in range(4):box('Step'+str(k),(0,.15+k*.25,-1.1+k*.7),(2.2,.3+k*.5,.7))
   elif i==11:
    h=1.4
    for k in range(4):post('RailPost'+str(k),-1+k*.67,0,1.2)
    box('Handrail',(0,1.2,0),(2.2,.12,.12));d=.4
   else:
    for k in range(10):box('Plank'+str(k),(0,.25,-1.35+k*.3),(w,.18,.27))
    if i==2:box('CornerExtension',(1.6,.25,.65),(1,.18,1.6));w=4.5
    for x in [-w/2+.2,w/2-.2]:post('Support'+str(x),x,0,.4)
  elif i==4:cyl('MooringPost',(0,.6,0),.23,1.2);cyl('Cap',(0,1.2,0),.3,.12,'iron');w=d=.7;h=1.3
  elif i in [5,6]:
   w,d,h=1.4,1.1,.3
   for k in range(5):cyl('Rope'+str(k),((k-2)*.2,.12,0),.25,.06,'linen',rot=(90,0,0))
   if i==6:box('RopeSpan',(0,.2,0),(3,.05,.05),'linen');w=3
  elif i==7:
   w,d,h=2.5,2,3.3;box('Base',(0,.2,0),(1.4,.4,1.4),'stone');box('Upright',(0,1.6,0),(.3,3,.3));box('Jib',(.8,3,0),(2,.2,.25));box('Cable',(1.6,2.2,0),(.03,1.6,.03),'iron');cyl('Hook',(1.6,1.4,0),.15,.2,'iron')
  elif i==8:crate('A',-.55,0);crate('B',.55,0);barrel('C',0,1);w,d,h=2.3,2.3,1.1
  elif i==12:cyl('Mast',(0,2,0),.12,4);box('Yard',(0,3,0),(3,.1,.1));w,d,h=3,.4,4
  elif i==13:box('Sail',(0,1.5,0),(2.5,2.8,.035),'linen');box('Yard',(0,3,0),(2.8,.1,.1));w,d,h=2.8,.2,3
  elif i==14:box('Keel',(0,.15,0),(.7,.3,2.2));box('Port',(-.45,.4,0),(.15,.5,2));box('Starboard',(.45,.4,0),(.15,.5,2));box('Seat',(0,.4,0),(.9,.08,.4));w,d,h=1.1,2.5,.7
 elif group==6:
  if i in [1,2]:
   w,d,h=3,.7,3
   for x in [-1.4,1.4]:box('Pillar'+str(x),(x,1.5,0),(.4,3,.6),'stone')
   box('Lintel',(0,2.9,0),(3,.3,.65),'stone')
   if i==1:box('Door',(0,1.35,0),(2.4,2.7,.35),'stone')
   else:solid=False;s.collide((-1.6,-.35,.4,.7),3);s.collide((1.2,-.35,.4,.7),3)
  elif i in [3,4]:cyl('Base',(0,.15,0),.55,.3,'stone');cyl('Switch',(0,.4,0),.25,.2,'brass',rot=(0,45 if i==4 else 0,0));w=d=1.2;h=.6
  elif i in [5,6]:
   w,d,h=2,.5,.5;cyl('Pipe',(0,.3,0),.16,2,'brass',rot=(0,0,90))
   if i==6:cyl('Elbow',(.85,.3,.65),.16,1.3,'brass',rot=(90,0,0));d=1.6
  elif i in [7,8]:box('Console',(0,.6,0),(1.5,1.2,.7),'stone');box('Display',(0,1.23,0),(1.1,.05,.5),'glass' if i==7 else 'fire');w,d,h=1.6,.9,1.3
  elif i in [9,10]:
   size=.5 if i==9 else 1.1;w=d=size*2.5;h=size*2.5;cyl('Pedestal',(0,.2,0),size,.4,'stone');sphere('Core',(0,size+.4,0),size*.7,'glass');
   for k in range(3):a=k*math.tau/3;box('Brace'+str(k),(math.cos(a)*size,size+.3,math.sin(a)*size),(.12,size*1.8,.12),'brass')
  elif i==11:cyl('SealBase',(0,.18,0),1,.36,'stone');box('SealedSlab',(0,1.2,0),(1.2,2,.4),'stone');box('SealLine',(0,1.3,.22),(.1,1.6,.04),'glass');w=d=2.2;h=2.3
  elif i==12:box('Platform',(0,.25,0),(2.5,.5,2.5),'stone');w=d=2.5;h=.5
  elif i==13:box('SlabL',(-.4,.2,0),(.7,.4,1.3),'stone',(0,12,0));box('SlabR',(.45,.15,.1),(.65,.3,1.1),'stone',(0,-15,0));w,d,h=1.8,1.5,.5
  elif i==14:cyl('Stump',(0,.5,0),.4,1,'stone');cyl('Fallen',(.7,.35,0),.35,1.6,'stone',rot=(0,0,80));w,d,h=2,.9,1.1
  elif i==15:box('Inscription',(0,.7,0),(1.1,1.4,.25),'stone');
  # lines are carved geometric marks, not invented readable lore.
  if i==15:
   for k in range(4):box('Mark'+str(k),(0,.4+k*.2,.14),(.6,.025,.02),'trim')
   w,d,h=1.2,.4,1.5
 elif group==7:
  if i in [1,2,3,4]:
   w=d=2.4;h=4;cyl('Trunk',(0,1.3,0),.2,2.6,'wood',.13)
   if i in [1,4]:
    for k in range(3):cyl('Crown'+str(k),(0,1.8+k*.7,0),1.2-k*.28,1.7,'linen' if i==4 else 'green',0)
   elif i==2:
    for k in range(5):a=k*math.tau/5;sphere('Leaves'+str(k),(math.cos(a)*.6,2.5+(k%2)*.5,math.sin(a)*.6),.95,'green')
   else:
    for k in range(4):box('Branch'+str(k),((1 if k%2 else -1)*.4,1.8+k*.4,0),(.12,1.1,.12),'wood',(0,0,(1 if k%2 else -1)*40))
   s.collide((-.25,-.25,.5,.5),2);solid=False
  elif i==5:cyl('Stump',(0,.3,0),.45,.6,'wood',.4);cyl('Cut',(0,.61,0),.37,.02,'linen');w=d=1;h=.7
  elif i==6:cyl('Log',(0,.3,0),.3,2.5,'wood',rot=(0,0,90));w,d,h=2.5,.7,.7
  elif i in [7,8,9,10,11]:
   w=d=1.5;h=1.3 if i==8 else .6;solid=False
   for k in range(7):
    a=k*2.4;x=math.cos(a)*.5;z=math.sin(a)*.5
    if i==11:cyl('Stem'+str(k),(x,.16,z),.04,.3,'linen');sphere('Cap'+str(k),(x,.32,z),.18,'clay',(1,.4,1))
    elif i==8:cyl('Reed'+str(k),(x,.6,z),.025,1.2,'green');cyl('Seed'+str(k),(x,1.1,z),.05,.2,'wood')
    else:sphere('Foliage'+str(k),(x,.25,z),.3 if i==7 else .14,'green',(1,1.4,1))
  elif i in [12,13]:rocks(n=2 if i==12 else 6);w=d=1.3 if i==12 else 2;h=.8
  elif i in [14,15,16,17,30]:
   w,d,h=3,.8,3 if i in [14,15,30] else .7;box('RockWall',(0,h/2,0),(w,h,d),'stone')
   if i in [15,17]:box('Corner',(1.1,h/2,1.1),(.8,h,3),'stone');d=3
  elif i in [18,19,20,21,22,23,24,25,26,27,28,29]:
   w=d=3;h=.1;solid=False;mat='glass' if i in [18,19,20,22] else 'linen' if i==21 else 'stone' if i in [25,26,27,28] else 'clay';box('Tile',(0,.05,0),(3,.1,3),mat)
   if i in [23,24,25,26,27,28]:
    box('Path',(0,.11,0),(1.5,.04,3),'wood' if i in [23,24] else 'stone')
    if i in [24,26,28]:box('Turn',(.75,.11,.75),(1.5,.04,1.5),'wood' if i==24 else 'stone')
   if i in [18,20,22]:
    for k in range(4):box('SurfaceLine'+str(k),(-.9+k*.6,.115,0),(.02,.015,2.5),'blue')
   # Tiles are surfaces with physics floors, not navigation obstacles.
   shape=s.sub('BoxShape3D','size = Vector3(3,0.1,3)');s.node('StaticBody3D','SurfaceBody','position = Vector3(0,0.05,0)');s.node('CollisionShape3D','Shape','shape = '+shape,'SurfaceBody')
  elif i==31:
   w,d,h=4,1,3
   for x in [-1.65,1.65]:box('Jamb'+str(x),(x,1.2,0),(.7,2.4,1),'stone')
   box('Lintel',(0,2.7,0),(4,.6,1),'stone');s.collide((-2,-.5,.7,1),3);s.collide((1.3,-.5,.7,1),3);solid=False
  elif i==32:rocks();
  if i==32:
   for k in range(3):box('Ore'+str(k),((k-1)*.35,.65,0),(.18,.6,.18),'glass',(0,0,(k-1)*20))
   w=d=1.4;h=1.1
 if solid:s.collide((-w/2,-d/2,w,d),h)
 path=s.save({'origin':'ground center','bounds':[w,h,d],'recreated_from':'unavailable external draft; newly authored in this environment','final_art_approved':False})
 catalog.append({'id':e['id'],'name':e['name'],'category':e['category'],'file':str(path.relative_to(ROOT)),'path':'res://assets/production/props/'+e['id']+'.tscn','bounds':[w,h,d],'stage':'native_first_pass','runtime_connected':False,'recreated':True,'collision_obstacles':s.obstacles})
out=ROOT/'game/assets/production/props/catalog.json';out.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n');print('Created',len(catalog),'newly authored props; engine and visual review pending')
