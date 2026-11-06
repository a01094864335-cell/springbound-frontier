"""Build 29 distinct field layout blockouts; no final-art or gameplay completion claim."""
from pathlib import Path
import json,hashlib,collections,html
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'game/assets/production/fields'; OUT.mkdir(parents=True,exist_ok=True)
# name, biome, route control points, authored exclusion rectangles (x,z,w,d), landmark
SPECS=[
('산길 확장','mountain',[(0,17),(0,7),(7,7),(7,-6),(-3,-6),(-3,-17)],[(-15,-15,7,24),(11,-8,4,22)],'헤어핀 쉼터'),
('국경 숲길','forest',[(0,17),(0,8),(-7,8),(-7,-5),(3,-5),(3,-17)],[(-15,-15,4,28),(8,-12,7,25)],'숲길 공터'),
('농경지','farm',[(0,17),(0,-17)],[(-13,-12,8,8),(5,-12,8,8),(-13,4,8,9),(5,4,8,9)],'관개 수로 옆 쉼터'),
('국경 도로','road',[(0,17),(0,-17)],[(-15,-10,9,5),(6,3,9,5)],'국경 이정표'),
('폐초소','ruin',[(0,17),(0,4),(6,4),(6,-9),(0,-9),(0,-17)],[(-12,-11,5,13),(-7,-11,4,2),(10,-11,3,14)],'초소 잔벽'),
('교량 양안','river',[(0,17),(0,-17)],[(-16,-3,13,6),(3,-3,13,6)],'중앙 교량'),
('우회 협곡','canyon',[(0,17),(-6,17),(-6,4),(6,4),(6,-14),(0,-14),(0,-17)],[(-2,8,18,7),(-16,-11,17,9)],'협곡 회랑'),
('강변 야영지','river',[(0,17),(0,5),(-5,5),(-5,-7),(0,-7),(0,-17)],[(9,-18,7,36),(-14,-12,5,6),(-14,4,5,6)],'강변 휴식 공터'),
('왕도 대로','city',[(0,17),(0,-17)],[(-15,-15,8,10),(7,-15,8,10),(-15,5,8,10),(7,5,8,10)],'대로 중앙 광장'),
('성벽 외곽','city',[(0,17),(-5,17),(-5,-10),(0,-10),(0,-17)],[(5,-18,3,36),(-15,-5,5,8)],'성벽 순찰길'),
('남방 구릉','hill',[(0,17),(0,7),(7,7),(7,-7),(-2,-7),(-2,-17)],[(-15,-12,8,14),(11,-3,4,18)],'구릉 전망 공터'),
('습지','marsh',[(0,17),(0,9),(-6,9),(-6,-3),(5,-3),(5,-17)],[(-16,-17,7,19),(-2,2,18,4),(9,-17,7,15)],'습지 건조 지대'),
('하천 나루','river',[(0,17),(0,-17)],[(-16,-4,12,8),(4,-4,12,8)],'나루 연결 판교'),
('해안길','coast',[(0,17),(0,8),(-4,8),(-4,-8),(0,-8),(0,-17)],[(8,-18,8,36),(-15,-8,6,12)],'해안 휴식 공터'),
('동굴','cave',[(0,17),(0,8),(6,8),(6,-5),(-4,-5),(-4,-17)],[(-16,-18,6,36),(11,-18,5,36),(-10,0,11,4)],'동굴 넓은 방'),
('폐광','mine',[(0,17),(0,7),(-6,7),(-6,-6),(4,-6),(4,-17)],[(-16,-18,6,36),(10,-18,6,36),(-2,-1,12,4)],'폐광 작업 공간'),
('버려진 저장 시설','ruin',[(0,17),(0,9),(-6,9),(-6,-9),(0,-9),(0,-17)],[(-12,-5,3,10),(-2,-4,13,8),(10,-13,3,8)],'저장 시설 통로'),
('설원','snow',[(0,17),(0,-17)],[(-14,-12,7,7),(7,4,7,8)],'설원 바람막이'),
('얼어붙은 협곡','ice',[(0,17),(-6,17),(-6,2),(6,2),(6,-15),(0,-15),(0,-17)],[(-1,6,17,9),(-16,-13,17,10)],'빙설 협곡'),
('북방 접근로','snow',[(0,17),(0,5),(5,5),(5,-7),(0,-7),(0,-17)],[(-15,-14,8,12),(10,-2,5,17)],'북방 관측 공터'),
('해양국 상륙지','coast',[(0,17),(0,6),(-5,6),(-5,-7),(0,-7),(0,-17)],[(8,-18,8,36),(-15,7,8,9)],'상륙 집결 공터'),
('순례길','sanctuary',[(0,17),(0,-17)],[(-13,-14,5,10),(8,-14,5,10),(-13,4,5,10),(8,4,5,10)],'순례 쉼터'),
('오래된 묘역','sanctuary',[(0,17),(0,7),(6,7),(6,-7),(0,-7),(0,-17)],[(-12,-13,5,6),(-12,0,5,6),(-4,-4,6,5),(9,-13,5,6)],'묘역 중앙 공터'),
('지하 기록고','ancient',[(0,17),(0,9),(-6,9),(-6,-9),(0,-9),(0,-17)],[(-13,-6,3,12),(-2,-6,5,12),(9,-6,4,12)],'기록고 열람 공간'),
('유적 입구','ancient',[(0,17),(0,-17)],[(-15,-14,10,6),(5,-14,10,6),(-13,4,5,9),(8,4,5,9)],'유적 전면 광장'),
('유적 회랑','ancient',[(0,17),(0,8),(6,8),(6,-8),(0,-8),(0,-17)],[(-15,-18,6,36),(11,-18,5,36),(-9,-3,11,6)],'회랑 분기 공간'),
('장치실','ancient',[(0,17),(0,8),(-7,8),(-7,-8),(0,-8),(0,-17)],[(-3,-3,6,6),(10,-12,3,24)],'중앙 장치 기단'),
('붕괴 구역','ruin',[(0,17),(0,9),(-6,9),(-6,-2),(6,-2),(6,-17),(0,-17)],[(3,5,12,10),(-16,-15,16,8)],'붕괴 우회로'),
('중추 연결로','core',[(0,17),(0,-17)],[(-16,-18,9,36),(7,-18,9,36)],'중추 진입 플랫폼')]
PALETTE={'mountain':'6c7565','forest':'425d43','farm':'927c49','road':'8d806b','ruin':'74746b','river':'728878','canyon':'8e7056','city':'97968c','hill':'7c9255','marsh':'526c58','coast':'b4a783','cave':'595f66','mine':'635d58','snow':'c2cbd0','ice':'a2bdca','sanctuary':'a49e88','ancient':'647c7e','core':'566c7b'}
def v(a):return 'Vector3('+','.join(map(str,a))+')'
entries=[]; previews=[]
for n,(name,biome,route,obstacles,landmark) in enumerate(SPECS,1):
 key=f'field-{n:02}'; resource=[];nodes=[]
 def box(label,x,z,w,d,height,color,collision=True):
  i=len(resource)+1;mat=f'm{i}';mesh=f'b{i}'
  rgb=[int(color[j:j+2],16)/255 for j in (0,2,4)]
  resource.extend([f'[sub_resource type="StandardMaterial3D" id="{mat}"]\nalbedo_color = Color({rgb[0]},{rgb[1]},{rgb[2]},1)\nroughness = 0.95',f'[sub_resource type="BoxMesh" id="{mesh}"]\nsize = {v((w,height,d))}'])
  nodes.append(f'[node name="{label}" type="MeshInstance3D" parent="."]\nposition = {v((x+w/2,height/2,z+d/2))}\nmesh = SubResource("{mesh}")\nmaterial_override = SubResource("{mat}")')
  if collision:
   collision_height = max(height,2.2) if label.startswith('Obstacle') else height
   resource.append(f'[sub_resource type="BoxShape3D" id="s{i}"]\nsize = {v((w,collision_height,d))}')
   nodes.extend([f'[node name="{label}Body" type="StaticBody3D" parent="."]\nposition = {v((x+w/2,collision_height/2,z+d/2))}',f'[node name="Shape" type="CollisionShape3D" parent="{label}Body"]\nshape = SubResource("s{i}")'])
 box('Ground',-16,-18,32,36,.2,PALETTE[biome])
 for i,(x,z,w,d) in enumerate(obstacles):box('Obstacle'+str(i),x,z,w,d,.25 if biome in ['river','marsh','coast'] else 2.2,'3b6072' if biome in ['river','marsh','coast'] else '454e50')
 # Side boundaries; end boundaries leave a 6m gate around both endpoint markers.
 for i,(x,z,w,d) in enumerate([(-17,-19,1,38),(16,-19,1,38)]):box('Boundary'+str(i),x,z,w,d,2,'343f43')
 for end,z in [('Entry',18),('Exit',-19)]:
  cx=route[0 if end=='Entry' else -1][0]
  box(end+'Left',-16,z,cx+13,1,2,'343f43');box(end+'Right',cx+3,z,13-cx,1,2,'343f43')
 for i,((x1,z1),(x2,z2)) in enumerate(zip(route,route[1:])):
  box('Route'+str(i),min(x1,x2)-1.4,min(z1,z2)-1.4,abs(x2-x1)+2.8,abs(z2-z1)+2.8,.23,'ad9b76',False)
 for label,(x,z) in [('Entry',route[0]),('Exit',route[-1]),('Objective',route[len(route)//2])]:nodes.append(f'[node name="{label}" type="Marker3D" parent="."]\nposition = {v((x,.3,z))}')
 root=f'[node name="{key.replace("-","_")}" type="Node3D"]\nmetadata/asset_id = "{key}"\nmetadata/display_name = "{name}"\nmetadata/stage = "layout_blockout"'
 scene='[gd_scene format=3]\n\n'+'\n\n'.join(resource+[root]+nodes)+'\n'
 (OUT/(key+'.tscn')).write_text(scene)
 entry=dict(id=key,name=name,biome=biome,file=f'game/assets/production/fields/{key}.tscn',path=f'res://assets/production/fields/{key}.tscn',stage='layout_blockout',runtime_connected=False,route=route,obstacles=obstacles,bounds=[-16,-18,32,36],landmark=landmark,player_radius=.4,combat_clearance=2.8,notes='평면 동선 검증용. 최종 지형 미술·지역 간 연결·적 배치는 미완료.')
 # Independent 4-neighbor path validation, with expanded collision footprint.
 def blocked(x,z):return any(a-.4<x<a+w+.4 and b-.4<z<b+d+.4 for a,b,w,d in obstacles)
 start=tuple(route[0]); goals=[tuple(p) for p in route];seen={start};todo=collections.deque([start])
 while todo:
  x,z=todo.popleft()
  for p in [(x+1,z),(x-1,z),(x,z+1),(x,z-1)]:
   if -15<=p[0]<=15 and -17<=p[1]<=17 and p not in seen and not blocked(*p):seen.add(p);todo.append(p)
 assert all(p in seen for p in goals),(key,'unreachable route')
 assert all(not blocked(x,z) for (x1,z1),(x2,z2) in zip(route,route[1:]) for x in range(min(x1,x2),max(x1,x2)+1) for z in range(min(z1,z2),max(z1,z2)+1)),key
 entry['reachable_grid_cells']=len(seen);entries.append(entry)
 svg=f'<svg viewBox="-17 -19 34 38" role="img" aria-label="{name} 동선"><rect x="-16" y="-18" width="32" height="36" fill="#{PALETTE[biome]}"/>'
 for x,z,w,d in obstacles:svg+=f'<rect x="{x}" y="{z}" width="{w}" height="{d}" fill="#334850"/>'
 svg+='<polyline points="'+' '.join(f'{x},{z}' for x,z in route)+'" fill="none" stroke="#f3cf79" stroke-width=".7"/>'
 for (x,z),c in [(route[0],'#85dfb4'),(route[-1],'#f38c8c')]:svg+=f'<circle cx="{x}" cy="{z}" r="1" fill="{c}"/>'
 svg+='</svg>';previews.append(f'<article><h2>{key} · {name}</h2>{svg}<p>{landmark} · 도착 가능 셀 {len(seen)}</p><a href="../../{entry["file"]}">Godot 장면</a></article>')
(OUT/'catalog.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
p=ROOT/'docs/field-layouts';p.mkdir(exist_ok=True);(p/'index.html').write_text('<!doctype html><html lang="ko"><meta charset="utf-8"><title>필드29 동선 초안</title><style>body{background:#17272e;color:#eee;font:15px system-ui;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px}article{background:#293d47;padding:16px}svg{width:100%;height:300px}h2{font-size:17px}a{color:#eed08d}</style><h1>필드29 · 동선 블록아웃</h1><p>초록=입구, 빨강=출구, 금색=주요 동선, 어두운 영역=이동 차단. 평면 배치 검증용이며 최종 지형 미술·지역 연결·적 배치는 별도입니다.</p><main>'+''.join(previews)+'</main></html>')
print('Built',len(entries),'distinct field layout blockouts; grid paths pass')
