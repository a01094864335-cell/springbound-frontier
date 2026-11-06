"""Package generated original atlases without altering image pixels, as 1562 SpriteFrames clips."""
from pathlib import Path
from PIL import Image
import json,hashlib,shutil,math
import numpy as np
def splits(counts,number):
 counts=np.asarray(counts,dtype=float);length=len(counts);positions=np.arange(length,dtype=float);centers=(np.arange(number)+.5)*length/number
 for _ in range(40):
  labels=np.argmin(np.abs(positions[:,None]-centers[None,:]),axis=1);updated=[]
  for index in range(number):
   weights=counts*(labels==index);updated.append(float((weights*positions).sum()/weights.sum()) if weights.sum()>0 else centers[index])
  updated=np.asarray(updated)
  if np.max(np.abs(updated-centers))<.01:break
  centers=updated
 boundaries=[0]
 for left,right in zip(centers,centers[1:]):
  gap=right-left;lo=max(boundaries[-1]+1,int(left+gap*.24));hi=min(length-1,int(right-gap*.24))
  segment=counts[lo:hi+1];minimum=segment.min();quiet=segment<=minimum+max(1,counts.max()*.003);runs=[];start=None
  for index,value in enumerate(list(quiet)+[False]):
   if value and start is None:start=index
   elif not value and start is not None:runs.append((start,index));start=None
  start,end=max(runs,key=lambda run:run[1]-run[0]);boundaries.append(lo+round((start+end)/2))
 boundaries.append(length);return boundaries
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'game/assets/production/motions';OUT.mkdir(exist_ok=True)
archive_path=ROOT/'docs/asset-production-2026-11-03/full-generation-inputs.json'
archive=json.loads(archive_path.read_text()) if archive_path.exists() else {}
job_path=Path('/workspace/artifacts/full-motion-jobs.json')
jobs=json.loads(job_path.read_text()) if job_path.exists() else archive['motion_jobs'];entries=[];sheets=[];flags=[];missing=[]
override=Path('/workspace/artifacts/full-remainder-records/event-overrides.json')
if override.exists() or any(x['id']=='event-overrides' for x in archive.get('motion_records',[])):jobs.append({'id':'event-overrides','name':'부상·검 대여·첫 승리 전용','reference':'assets/character-boards/leon-board-v2.png','clips':[{'id':id,'name':name} for id,name in [('event-npc-leon-03','레온 부상 대기'),('event-npc-leon-04','레온 검 건네기'),('event-npc-leon-05','레온 느린 동행'),('event-first-victory-tremble','에일 첫 승리 떨림')]]})
extra_path=Path('/workspace/artifacts/additional-motion-jobs.json')
jobs.extend(json.loads(extra_path.read_text()) if extra_path.exists() else archive.get('additional_motion_jobs',[]))
for job in jobs:
 recpath=Path('/workspace/artifacts/full-remainder-records')/(job['id']+'.json')
 rec=json.loads(recpath.read_text()) if recpath.exists() else next((x for x in archive.get('motion_records',[]) if x['id']==job['id']),None)
 if rec is None:missing.append(job['id']);continue
 source=Path(rec['source']);dest=OUT/(job['id']+'.png')
 if not source.exists():source=ROOT/rec['file']
 if source.resolve()!=dest.resolve():shutil.copyfile(source,dest)
 image=Image.open(dest);assert image.mode=='RGBA',(job['id'],image.mode)
 width,height=image.size;cols=rec.get('columns',8);rows=rec.get('rows',math.ceil(len(job['clips'])/2));cw,ch=width/cols,height/rows
 alpha=image.getchannel('A');assert alpha.getextrema()[0]==0
 mask=np.asarray(alpha)>=180;ys=splits(mask.sum(axis=1),rows);xbase=splits(mask[ys[0]:ys[1]].sum(axis=0),cols);xs=[xbase for row in range(rows)]
 resources=[];animations=[]
 for index,clip in enumerate(job['clips']):
  refs=[];cells=[];warnings=[];boxes=[];rects=[];anchors=[]
  for frame in range(4):
   n=index*4+frame;col=n%cols;row=n//cols;x=xs[row][col];y=ys[row];rw=xs[row][col+1]-x;rh=ys[row+1]-y;rid=f'frame_{n}'
   region=alpha.crop((round(x),round(y),round(x+rw),round(y+rh)))
   bbox=region.point(lambda a:255 if a>=180 else 0).getbbox();assert bbox is not None,(job['id'],clip['id'],frame,'blank')
   left,top,right,bottom=bbox
   if min(left,top,region.width-right,region.height-bottom)<2:warnings.append('셀 경계 근접: 위치·잘림 검토')
   boxes.append(list(bbox));rects.append([x,y,rw,rh]);anchors.append([rw/2,bottom+1])
   resources.append(f'[sub_resource type="AtlasTexture" id="{rid}"]\natlas = ExtResource("atlas")\nregion = Rect2({x:.6f}, {y:.6f}, {rw:.6f}, {rh:.6f})\nfilter_clip = true\n')
   refs.append('{"duration": 1.0, "texture": SubResource("'+rid+'")}');cells.append(n)
  name=clip['name'];loop=any(t in name for t in ['대기','걷기','이동','대화','느린 동행']) and not any(t in name for t in ['전투 불능','특수'])
  speed=6 if '대기' in name else 8
  animations.append('{"frames": ['+', '.join(refs)+'], "loop": '+str(loop).lower()+', "name": &"'+clip['id']+'", "speed": '+str(speed)+'.0}')
  entry={'id':clip['id'],'name':name,'actor':job['id'],'path':'res://assets/production/motions/'+job['id']+'.tres','file':'game/assets/production/motions/'+job['id']+'.tres','atlas':'game/assets/production/motions/'+job['id']+'.png','cells':cells,'rects':rects,'anchors':anchors,'columns':cols,'rows':rows,'width':width,'height':height,'fps':speed,'loop':loop,'foot_anchor':[.5,.85],'stage':'motion_prototype','runtime_connected':False,'art_approved':False,'review_notes':sorted(set(warnings))+['생성 프레임의 방향·해부·발 원점·장비 일관성은 미술 검토 대상.']}
  entries.append(entry)
  flags.append({'id':clip['id'],'notes':sorted(set(warnings)),'bounds':boxes})
 header='[gd_resource type="SpriteFrames" format=3]\n\n[ext_resource type="Texture2D" path="res://assets/production/motions/'+job['id']+'.png" id="atlas"]\n\n'
 (OUT/(job['id']+'.tres')).write_text(header+'\n'.join(resources)+'\n[resource]\nanimations = [\n'+',\n'.join(animations)+'\n]\n')
 sheets.append({'id':job['id'],'name':job['name'],'reference':job['reference'],'atlas':'game/assets/production/motions/'+job['id']+'.png','path':'res://assets/production/motions/'+job['id']+'.tres','clip_count':len(job['clips']),'columns':cols,'rows':rows,'width':width,'height':height,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'prompt':rec['prompt']})
entries=list({entry['id']:entry for entry in entries}.values())
flags=[x for x in {x['id']:x for x in flags}.values() if x['notes']]
(OUT/'catalog.json').write_text(json.dumps({'count':len(entries),'sheets':sheets,'entries':entries,'missing_sheets':missing,'review_flags':flags},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'sheets':len(sheets),'clips':len(entries),'missing':missing,'boundary_review_flags':len(flags)},ensure_ascii=False))
