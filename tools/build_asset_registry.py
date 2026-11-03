"""Rebuild the finite full-game asset baseline from existing catalogs and explicit proposals."""
from pathlib import Path
import json,csv,collections,html
ROOT=Path(__file__).resolve().parents[1]; rows=[]
def read(p):return json.loads((ROOT/p).read_text())
def add(id,name,category,phase,region='공용',deliverable='개별 외형 보드 → 제작용 파일',source='',deps=(),note='',status=None):
 rows.append(dict(id=id,name=name,category=category,phase=phase,region=region,deliverable=deliverable,design_status=status or ('기존 시안' if source else '대기'),runtime_status='별도 검증 필요' if source else '미연결',source=source,dependencies=list(deps),notes=note))
modules=[('wall-straight','목조 석벽 직선','straight rectangular plaster wall bay with plain dark timber uprights and low grey stone base; no window no door'),('wall-corner','목조 석벽 모서리','two same wall bays meeting at a right angle, interior and exterior corner visible'),('door-frame','목재 출입문 틀','one rectangular timber door frame in short plaster wall with grey stone threshold, opening empty'),('door-leaf','목재 문짝','one plain vertical plank wooden door leaf with two simple black iron hinges and small round handle, detached'),('window-frame','목재 창틀','one small square timber window frame set into short plaster wall, simple wooden crossbar no glass reflections'),('window-shutters','목재 덧문','one matched pair plain small wooden shutter leaves, detached, small black iron hinges'),('roof-slope','짙은 청색 지붕 경사면','one rectangular sloped dark slate blue roof shingle module with simple timber eave, no snow'),('roof-corner','짙은 청색 지붕 모서리','one convex hipped right-angle dark slate blue shingle roof corner module matching slope piece'),('roof-ridge','짙은 청색 지붕 용마루','one short horizontal dark slate blue roof ridge cap module with both sloped sides'),('timber-pillar','목재 지지 기둥','one square weathered timber upright post on small grey stone foot, simple top joint'),('stone-foundation','석조 기단','one low rectangular grey rubble-stone building foundation block, flat top and straight edges'),('stone-stairs','석조 계단','one straight short flight of exactly four modest grey stone steps with no railings')]
for i,(id,name,brief) in enumerate(modules):add('kit-'+id,name,'공용 건축 부품',1,note=brief)
for e in read('game/assets/environment/catalog.json'):
 add('existing-env-'+e['id'],e['name'],'기존 환경',0,'·'.join(e['maps']),'기존 Godot 장면 → 배치 검증','game/'+e['scene'].replace('res://',''),note='장면 존재. 보드·배치·시각 승인 완료와 구분.')
regions=[('frost','서리골','약초사 집|일반 주택|마을 상점|공용 창고|마을 입구'),('border','돌샘·국경 연락소','여관|보급 상점|진료소|연락소|초소|훈련장'),('refugee','피난 교량','교량|검문소|구호소|천막|보급소'),('capital','아르덴 왕도','성문|성벽|주택|무기 상점|방어구 상점|여관|병영|행정청|왕성 접견동'),('academy','남방 학술도시','학술원|도서관|연구실 동|기숙사|유물 보관소|주택|여관'),('south-port','남방 항구','부두|시장 점포|선술집|여관|화물 창고|조선 작업장|주택'),('north','북방 시설','외곽 기지|관측동|동력실|통제동|시설 입구'),('sea','해양国'.replace('国','국 항만 도시'),'부두|주택|교역소|선원 회관|관측소|여관'),('sanctuary','교단 성역','성역 문|숙소|진료소|예배당|회랑|기록실'),('core','고대 중추','진입문|연결 회랑|분기실|제어실|중심 구조물'),('leon-home','레온의 고향','마을 입구|레온의 옛집|기억의 장소')]
for key,name,buildings in regions:
 add('map-'+key,name+' 전체 배치도','맵 배치',2,name,'출입구·상호작용·전투 공간 배치도',note='기존 본편 경로 기반. 건물 수·배치·세부 이름은 제작 초안.')
 for j,b in enumerate(buildings.split('|'),1):add(f'building-{key}-{j:02}',name+' '+b,'건물·시설',3,name,deps=('map-'+key,'kit-wall-straight'),note='서리골 등 기존 장면과 중복되는 기능은 새 제작 전 재사용 여부 검토.')
 for variant in ['광장 바닥','주요 길','지역 표지','가로 조명','경계 울타리']:
  add('district-'+key+'-'+str(['광장 바닥','주요 길','지역 표지','가로 조명','경계 울타리'].index(variant)+1),name+' '+variant,'지역 환경 변형',3,name,deps=('map-'+key,))
for i,name in enumerate('국경 산촌|왕도|학술도시|남방 항만|해양국|성역|북방 시설|고대 중추'.split('|'),1):
 for j,part in enumerate('벽 직선|벽 모서리|문|창|바닥|기둥|계단|난간|천장·지붕'.split('|'),1):add(f'architecture-{i:02}-{j:02}',name+' '+part,'지역 건축 부품',3,name,note='공용 부품과 중복되면 재사용·재질 변형으로 처리.')
for i,name in enumerate('약초사 집|주민 주택|상점|여관 객실|여관 식당|진료실|연락소|병영 침실|지휘실|왕성 접견실|행정청 집무실|도서관|연구실|기숙사|유물 보관실|창고|선술집|선실|화물칸|예배당|기록실|유적 통제실'.split('|'),1):add(f'interior-{i:02}',name+' 실내 세트','실내 배치',4,deliverable='실내 배치도·공용 부품 조립',deps=('kit-wall-straight',))
props={
'가구':'침대|이층 침대|탁자|긴 식탁|의자|벤치|찬장|책장|진열 선반|계산대|책상|옷장|난로|벽난로|세면대|커튼|깔개|식기 세트|촛대|벽등',
'생활 소품':'나무 상자|뚜껑 열린 상자|나무 통|뚜껑 열린 통|바구니|물동이|자루|장작 더미|우물 덮개|빨랫줄|빗자루|표지판|게시판|점포 간판|수레바퀴|공용 수레|빈 보물상자|닫힌 보물상자|열린 보물상자',
'직업 소품':'약초 건조대|약절구|약재 병|진료 침상|붕대 묶음|들것|대장간 화덕|모루|망치·집게|시장 진열대|어망|낚시 도구|측량 삼각대|측량 기기|지도 펼침|문서 묶음|인장 도구|연구 노트|유물 보관함',
'군사·피난':'목재 바리케이드|천막 골조|완성 천막|피난민 짐|보급 상자|군 깃발|무기 거치대|방패 거치대|훈련 표적|야전 취사대|야전 침상|검문 차단봉',
'항만·운송':'부두 직선|부두 모서리|부두 계단|계류 말뚝|밧줄 뭉치|밧줄 연결|선적 크레인|화물 더미|정박선 외관|선박 갑판|선박 난간|선박 돛대|선박 돛|구명정|승선 발판',
'유적 장치':'유적 문 닫힘|유적 문 열림|누름 스위치|회전 스위치|동력관 직선|동력관 굽힘|제어대 꺼짐|제어대 가동|소형 공명핵|대형 공명핵|봉인 구조물|승강대|붕괴 석판|부서진 기둥|조각 비문',
'자연':'침엽수|활엽수|마른 나무|눈 덮인 침엽수|그루터기|쓰러진 통나무|관목|갈대|풀 무더기|약초 군락|버섯 군락|작은 바위|큰 바위|절벽 직선|절벽 모서리|강둑 직선|강둑 모서리|강물 표면|얕은 물|습지 표면|눈 바닥|얼음 바닥|흙길 직선|흙길 모서리|돌길 직선|돌길 모서리|포장도로 직선|포장도로 모서리|모래 해변|동굴 벽|동굴 입구|광석 지형'}
for c,names in props.items():
 for i,name in enumerate(names.split('|'),1):add('prop-'+str(list(props).index(c)+1)+f'-{i:02}',name,c,5,note='기존 환경 43종과 대조 후 동일 물품은 재사용. 별도 신규 모델로 중복 집계하지 않음.')
fields='산길 확장|국경 숲길|농경지|국경 도로|폐초소|교량 양안|우회 협곡|강변 야영지|왕도 대로|성벽 외곽|남방 구릉|습지|하천 나루|해안길|동굴|폐광|버려진 저장 시설|설원|얼어붙은 협곡|북방 접근로|해양국 상륙지|순례길|오래된 묘역|지하 기록고|유적 입구|유적 회랑|장치실|붕괴 구역|중추 연결로'.split('|')
for i,name in enumerate(fields,1):add(f'field-{i:02}',name,'필드 배치',6,name,'공용 부품 기반 지형·동선·전투 공간 배치')
for e in read('docs/npc-registry.json')['entries']:
 add('appearance-'+e['id'],e['display_name']+' 외형','인물 보드',0,'·'.join(e['regions']),'기존 외형 보드',e.get('board_path',''))
 # Motion clips are distinct production units; characters are not individual placed instances.
 for motion in ['대기','걷기','대화']:
  for direction in ['아래','위','왼쪽','오른쪽']:
   add('motion-'+e['id']+'-'+str(['대기','걷기','대화'].index(motion))+'-'+str(['아래','위','왼쪽','오른쪽'].index(direction)),e['display_name']+' '+direction+' '+motion,'인물 기본 동작',7,deliverable='방향별 투명 프레임 클립',deps=('appearance-'+e['id'],),note='프레임 수는 제작 검증 후 결정. 기존 에일 이동 시제품은 정합화 후 재사용.')
 for i,motion in enumerate(e.get('required_motion_plan',[])):
  if motion not in ['대기','걷기','대화']:add('event-'+e['id']+f'-{i:02}',e['display_name']+' '+motion,'인물 사건 동작',8,deliverable='사건 동작 클립',deps=('appearance-'+e['id'],),note='무기·이벤트 중복은 실제 연결 시 한 원본을 참조.')
for family,path in [('enemy','assets/enemy-boards/manifest.json'),('monster','assets/monster-boards/manifest.json')]:
 for e in read(path)['boards']:
  source=str(Path(path).parent/e['file']);key=family+'-'+e['id'];add('appearance-'+key,e['name']+' 외형','적군·몬스터 외형',0,deliverable='기존 개별 보드',source=source)
  for i,motion in enumerate(['대기','이동','공격','피격','전투 불능']):
   for j,direction in enumerate(['아래','위','왼쪽','오른쪽']):add(f'combat-{key}-{i}-{j}',e['name']+' '+direction+' '+motion,'적군·몬스터 동작',9,deliverable='방향별 투명 프레임 클립',deps=('appearance-'+key,),note='부유체·보스는 원점·크기 별도 검토. 병종 무장은 기존 보드 기준.')
  add('special-'+key,e['name']+' 특수 행동','적군·몬스터 동작',9,deliverable='행동별 연출 클립',deps=('appearance-'+key,),note='기술·보스 페이즈·효과 수치는 미정. 필요 행동 확정 후 제작.')
for c,weaponlist in [('에일',['검','창','활','단검','지팡이','검+방패','단검+버클러']),('레온',['검']),('리아',['창']),('세나',['지팡이']),('카이',['단검','활']),('이리스',['지팡이'])]:
 for wi,w in enumerate(weaponlist):
  for mi,motion in enumerate(['대기','이동','공격','피격','전투 불능','승리']):
   for di,d in enumerate(['아래','위','왼쪽','오른쪽']):add(f'party-{["에일","레온","리아","세나","카이","이리스"].index(c)}-{wi}-{mi}-{di}',c+' '+w+' '+d+' '+motion,'동료 무장 동작',8,deliverable='무장별 방향 클립',note='동료별 허용 무기는 초안. 공용 몸체 클립을 참조하는 조합도 포함하며 모든 조합에 별도 그림을 중복 생성하지 않음. 에일 보드는 기존 시안 재사용.')
for e in read('assets/item-boards/manifest.json')['items']:
 source='assets/item-boards/'+e['board'];add(e['id'],e['name'],'아이템 도안',0,deliverable='기존 보드 내 도안',source=source,note='보드의 '+str(e['board_position'])+'번째 도안. 독립 파일 아님.')
 add('icon-'+e['id'],e['name']+' 아이콘','아이템 아이콘',10,deliverable='개별 투명 인벤토리 아이콘',deps=(e['id'],))
shields=read('assets/shield-boards/manifest.json')
for i,n in enumerate(shields['designs'],1):
 add(f'shield-{i}',n,'아이템 도안',0,deliverable='기존 보드 내 도안',source='assets/shield-boards/'+shields['file']);add(f'icon-shield-{i}',n+' 아이콘','아이템 아이콘',10,deliverable='개별 투명 아이콘',deps=(f'shield-{i}',))
for c,names in {'전투 VFX':'검 베기|단검 베기|창 찌르기|둔기 충격|방패 충격|일반 피격|화살|화살 명중|공명 펄스|시전 준비|회복|전투 불능 표시|몬스터 소멸|거미줄|나방 가루|균사 뻗기|뿌리 충격', '환경 VFX':'눈 내림|비 내림|낮은 안개|강물 물결|해안 파도|굴뚝 연기|모닥불|횃불|공명 입자|장치 가동 빛|낙엽|눈 발자국', 'UI':'대화창|대화 이름표|선택지|초상화 영역|상호작용 표시|퀘스트 수락|퀘스트 갱신|퀘스트 완료|목표 표시|지역 지도|월드맵|지도 목적지|전투 명령창|대상 선택|이동 목적지|사거리 표시|위험 범위|HP 바|MP 바|상태 아이콘|장비창|가방창|아이템 상세|상점 구매|상점 판매|관계 기록|저장 목록|불러오기 목록|설정|키 설정|일시 정지|전투 결과|전투 재시도|타이틀|크레딧|로딩 표시', '이벤트':'문 개폐|상자 개폐|약 전달|레온 발견|검 대여|응급처치|첫 승리 떨림|부상자 부축|천막 설치|장치 활성화|배 출항|배 입항|교량 손상|교량 복구'}.items():
 for i,name in enumerate(names.split('|'),1):add(f'presentation-{list(["전투 VFX","환경 VFX","UI","이벤트"]).index(c)}-{i:02}',name,c,11,deliverable='UI 리소스' if c=='UI' else '프레임·연출リソース'.replace('リソース',' 리소스'),note='기존 게임 기능 여부와 분리. 효과 그림이 전투 규칙을 확정하지 않음.')
for c,names in {'효과음':'흙 발소리|돌 발소리|목재 발소리|눈 발소리|얕은 물 발소리|옷 스침|검 휘두름|창 휘두름|단검 휘두름|활 발사|화살 명중|방패 충격|석재 충격|일반 피격|회복 도구|공명 펄스|늑대 울음|멧돼지 울음|쥐 울음|거미 마찰|나방 날갯짓|도마뱀 소리|소라게 집게|균사 움직임|수호체 가동|공명체 움직임|문 열림|문 닫힘|상자 열림|물건 획득|상점 거래|UI 이동|UI 결정|UI 취소|오류 알림|퀘스트 갱신|장치 스위치|모닥불|밧줄 삐걱임|배 출항', '환경음':'서리골 바람|산길 숲|돌샘 거점|피난 야영지|왕도 거리|학술도시|남방 항구|습지|동굴|폐광|설원|북방 시설|바다 항해|해양국 항구|성역|유적|고대 중추', '음악':'타이틀|서리골|여행길|국경 거점|피난로|왕도|학술도시|남방 항구|북방 시설|바다|해양국|성역|유적|고대 중추|일반 전투|인간 적군 전투|보스 전투|최종 사건|승리|위기|이별|귀향|에필로그'}.items():
 for i,name in enumerate(names.split('|'),1):add(f'audio-{["효과음","환경음","음악"].index(c)}-{i:02}',name,c,12,deliverable='WAV 원본·게임용 변환',note='음향·음악은 이미지 생성 대상 아님. 별도 음원 제작·청취·루프 검증 필요. 성우 음성은 범위 제외.')
for i,n in enumerate(['서리골 출발','서리골 귀환 피난 준비','서리골 에필로그 복구','레온의 고향 에필로그'],1):add(f'world-state-{i}',n,'지역 상태 변형',13,deliverable='원본 맵 참조 + 변경 소품·NPC 배치',note='같은 마을 전체를 복제하지 않고 상태별 차이로 관리.')
# Resolve completed new boards without changing queue order.
p=ROOT/'assets/world-production/manifest.json'
if p.exists():
 for b in read('assets/world-production/manifest.json')['boards']:
  target=next(x for x in rows if x['id']==b['id']);target.update(design_status='외형 시안 제작',source='assets/world-production/'+b['file'],runtime_status='미연결')
# Native resources have their own stage. Do not mark them as final or connected.
native_manifest=ROOT/'game/assets/production/manifest.json'
if native_manifest.exists():
 for asset in json.loads(native_manifest.read_text())['entries']:
  target=next(x for x in rows if x['id']==asset['id'])
  target.update(design_status='제작 파일 1차',runtime_status='엔진 검증·플레이 미연결',source=asset['file'])
  target['notes']+=' 실제 파일 생성. 최종 미술·청취·게임 통합 검수는 별도.'

# Preserve reported drafts from the other executor without claiming accessible files.
resume_path=ROOT/'docs/asset-resume-queue-2026-11-03.json'
if resume_path.exists():
 for item in json.loads(resume_path.read_text())['entries']:
  if item['state']=='external_draft_unavailable':
   target=next(x for x in rows if x['id']==item['id'])
   if target['design_status']=='대기':
    target.update(design_status='타 환경 초안·복구 대기',runtime_status='파일 미확인')
    target['notes']+=' PR14에서 로컬 초안이 보고됐으나 현재 작업 공간과 원격에 없음. 재제작 전 체크포인트 복구 필요.'

rows.sort(key=lambda x:x['phase'])
for i,x in enumerate(rows,1):x['order']=i
assert len({x['id'] for x in rows})==len(rows)
ids={x['id'] for x in rows}
for x in rows:
 assert all(d in ids for d in x['dependencies']),x['id']
 if x['source']:assert (ROOT/x['source']).is_file(),x['source']
counts=collections.Counter(x['category'] for x in rows);data=dict(date='2026-11-03',scope='Finite proposed full-game baseline. Runtime clips and reuse references are separate from unique artwork counts; new locations and abilities are not automatically approved.',count=len(rows),counts=dict(counts),entries=rows)
(ROOT/'docs/full-asset-registry.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
with (ROOT/'docs/full-asset-registry.csv').open('w',newline='',encoding='utf-8-sig') as f:
 fields=['order','id','name','category','phase','region','deliverable','design_status','runtime_status','source','dependencies','notes'];w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows({**x,'dependencies':' | '.join(x['dependencies'])} for x in rows)
md='# 본편 전체 애셋 개별 제작 대장\n\n2026-11-03 · 총 **'+str(len(rows))+'개 관리 항목**. [검색 HTML](assets-registry/index.html) · [CSV](full-asset-registry.csv) · [JSON](full-asset-registry.json)\n\n## 범위와 집계\n\n본편 경로를 기준으로 기존 시안과 추가 제작 제안을 개별 ID로 기록했습니다. 이 목록은 확정된 출시 견적이 아닌 유한한 제작 기준안이며 새 지역 세부·동료 무기 허용 목록은 기존 기획과 대조 후 확정합니다. 애셋 수는 보드 장수나 고유 그림 수가 아닙니다. 방향별 동작 클립, 동일 원본을 참조하는 장비 조합, 기존 환경과 재사용할 소품, 배치도·음원도 각각 관리 항목입니다. 기존 보드가 있어도 실제 프레임과 런타임 연결은 완료로 표시하지 않습니다. 다중 방향 기본 동작과 무장 동작은 몸체를 공유할 수 있습니다. 상호 참조로 중복 제작을 줄입니다.\n\n## 제작 순서\n\n0. 기존 에셋 재사용 확인\n1. 공용 건축 부품 개별 보드\n2. 지역 전체 배치도\n3. 지역별 건물·건축·환경 변형\n4. 실내 배치\n5. 가구·자연·소품\n6. 필드 배치\n7. 인물 기본 동작\n8. 동료 무장·사건 동작\n9. 적군·몬스터 동작\n10. 아이템 독립 아이콘\n11. UI·VFX·이벤트\n12. 음향·음악\n13. 귀환·에필로그 상태 변화\n\n시안 → 프레임/모델 정리 → 엔진 연결 → 플레이 검증 순서로 관리합니다. 이미지 생성만으로 음향·3D 모델·애니메이션·UI 구현 완료를 선언하지 않습니다. 프롤로그 이후 통합 씬 제작은 배치·공용 부품과 함께 진행하며 이 목록의 존재가 플레이 화면 구현을 의미하지 않습니다.\n\n## 분류별 수량\n\n| 분류 | 관리 항목 수 |\n|---|---:|\n'
for k,v in counts.items():md+=f'| {k} | {v} |\n'
md+='\n## 개별 목록\n\n| 순서 | ID | 이름 | 분류 | 단계 | 외형 상태 |\n|---:|---|---|---|---:|---|\n'
for x in rows:md+=f'| {x["order"]} | {x["id"]} | {x["name"]} | {x["category"]} | {x["phase"]} | {x["design_status"]} |\n'
(ROOT/'docs/full-asset-registry.md').write_text(md)
out=ROOT/'docs/assets-registry';out.mkdir(exist_ok=True);(out/'data.js').write_text('window.ASSET_REGISTRY='+json.dumps(data,ensure_ascii=False)+';\n')
print(json.dumps(dict(total=len(rows),counts=dict(counts)),ensure_ascii=False))
