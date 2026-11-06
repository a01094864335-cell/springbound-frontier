"""Update the finite registry only from existing files and passing engine QA reports."""
from pathlib import Path
import json,hashlib,collections,shutil
ROOT=Path(__file__).resolve().parents[1];D=ROOT/'docs/asset-production-2026-11-03';D.mkdir(exist_ok=True)
def read(path):return json.loads((ROOT/path).read_text())
for name in ['motion','event','recreated','icon']:
 report=read('game/tests/asset_production/'+name+'-verification.json');assert report['passed'],name
 shutil.copyfile(ROOT/('game/tests/asset_production/'+name+'-verification.json'),D/('godot-'+name+'-verification.json'))
registry=read('docs/full-asset-registry.json')['entries'];baseline={x['id']:x for x in registry};manifest=read('game/assets/production/manifest.json');entries={x['id']:x for x in manifest['entries']}
motion=read('game/assets/production/motions/catalog.json');assert len(motion['sheets'])==98 and not motion['missing_sheets'];added=[]
for group in ['props','ui','events','world_states','icons','motions']:
 data=read('game/assets/production/'+group+'/catalog.json');data=data['entries'] if group=='motions' else data
 for x in data:
  if x['id'] not in baseline:continue # auxiliary first-victory clip is documented, not double-counted
  p=ROOT/x['file'];assert p.is_file(),x['id']
  entry={'id':x['id'],'file':x['file'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'stage':x['stage'],'runtime_connected':False,'validation':'Godot load and type-specific checks passed; final art and gameplay integration pending'}
  if x.get('recreated'):entry['recreated_from_unavailable_draft']=True
  if group=='motions':entry['atlas']=x['atlas'];entry['review_notes']=x['review_notes']
  entries[x['id']]=entry;added.append(x['id'])
manifest['entries']=list(entries.values());manifest['count']=len(entries);manifest['date']='2026-11-03';manifest['scope']='All finite baseline IDs now have a first-pass file, existing reference, or appearance board. Motion prototypes and field/state blockouts are not final art or gameplay integration.'
assert manifest['count']==1993,manifest['count']
(ROOT/'game/assets/production/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
queue=read('docs/asset-resume-queue-2026-11-03.json')
for x in queue['entries']:
 assert x['id'] in entries,x['id']
 entry=entries[x['id']];x.update(state=entry['stage'],file=entry['file'],next_action='최종 미술·원점·규격·플레이 연결 검수')
 if entry.get('recreated_from_unavailable_draft'):x['recreated']=True;x['previous_external_checkpoint_restored']=False
queue['current_counts']=dict(collections.Counter(x['state'] for x in queue['entries']));queue['file_missing_count']=0;queue['scope_note']='Current first-pass file coverage only. Existing old external checkpoint remains unavailable; its184items were newly recreated.'
(ROOT/'docs/asset-resume-queue-2026-11-03.json').write_text(json.dumps(queue,ensure_ascii=False,indent=2)+'\n')
# Preserve source prompts and jobs so packaging can be repeated in a fresh clone.
previous=read('docs/asset-production-2026-11-03/full-generation-inputs.json') if (D/'full-generation-inputs.json').exists() else {}
job_path=Path('/workspace/artifacts/full-motion-jobs.json');jobs=json.loads(job_path.read_text()) if job_path.exists() else previous['motion_jobs']
records=[]
for p in sorted(Path('/workspace/artifacts/full-remainder-records').glob('*.json')):
 x=json.loads(p.read_text());x['file']='game/assets/production/motions/'+x['id']+'.png';records.append(x)
if len(records)!=98:records=previous['motion_records']
icons=[]
for p in sorted(Path('/workspace/artifacts/full-icon-records').glob('*.json')):
 x=json.loads(p.read_text());x['file']='game/assets/production/icons/'+x['id']+'.png';icons.append(x)
if len(icons)!=36:icons=previous['icon_records']
extra_path=Path('/workspace/artifacts/additional-motion-jobs.json');extra=json.loads(extra_path.read_text()) if extra_path.exists() else previous.get('additional_motion_jobs',[])
icon_path=Path('/workspace/artifacts/recreated-icon-jobs.json');icon_jobs=json.loads(icon_path.read_text()) if icon_path.exists() else previous['icon_jobs']
inputs={'date':'2026-11-03','motion_jobs':jobs,'additional_motion_jobs':extra,'motion_records':records,'icon_jobs':icon_jobs,'icon_records':icons}
(D/'full-generation-inputs.json').write_text(json.dumps(inputs,ensure_ascii=False,indent=2)+'\n')
(D/'motion-cell-review.json').write_text(json.dumps({'count':len(motion['review_flags']),'scope':'Cell-edge proximity flags; this is a review list, not an automatic art approval. All directions, anatomy, grips and gait still need art review.','entries':motion['review_flags']},ensure_ascii=False,indent=2)+'\n')
summary={'date':'2026-11-03','baseline_count':2412,'existing_references':205,'appearance_boards':214,'first_pass_file_ids':1993,'newly_requested_ids_created':1764,'auxiliary_clips':1,'first_pass_file_missing':0,'final_art_approved':False,'gameplay_integrated':False,'motion_sheets':len(motion['sheets']),'motion_clips':len(motion['entries']),'motion_frame_references':len(motion['entries'])*4,'cell_review_flags':len(motion['review_flags']),'prior_external_drafts_recreated':184,'prior_external_checkpoint_restored':False,'stages':dict(collections.Counter(x['stage'] for x in entries.values()))}
(D/'full-remainder-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n');print(json.dumps(summary,ensure_ascii=False))
