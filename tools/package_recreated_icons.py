"""Package regenerated missing icons, preserving the previous 49 original PNGs."""
from pathlib import Path
from PIL import Image
import json,shutil,hashlib,html
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'game/assets/production/icons';records=Path('/workspace/artifacts/full-icon-records');archive_path=ROOT/'docs/asset-production-2026-11-03/full-generation-inputs.json';archive=json.loads(archive_path.read_text()) if archive_path.exists() else {};jobs_path=Path('/workspace/artifacts/recreated-icon-jobs.json');jobs=json.loads(jobs_path.read_text()) if jobs_path.exists() else archive['icon_jobs'];catalog=json.loads((OUT/'catalog.json').read_text());replaced={x['id'] for x in jobs};catalog=[x for x in catalog if x['id'] not in replaced]
for job in jobs:
 recpath=records/(job['id']+'.json');rec=json.loads(recpath.read_text()) if recpath.exists() else next(x for x in archive['icon_records'] if x['id']==job['id']);dest=OUT/(job['id']+'.png');source=Path(rec['source'])
 if not source.exists():source=ROOT/rec['file']
 if source.resolve()!=dest.resolve():shutil.copyfile(source,dest)
 image=Image.open(dest);assert image.mode=='RGBA';alpha=image.getchannel('A');assert alpha.getextrema()[0]==0 and alpha.getextrema()[1]>=200
 catalog.append(dict(id=job['id'],name=job['name'],file=str(dest.relative_to(ROOT)),path='res://assets/production/icons/'+dest.name,width=image.width,height=image.height,sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),reference=job['reference'],prompt=rec['prompt'],stage='native_first_pass',runtime_connected=False,recreated=True,review_notes=['고해상도 생성 원본. 최종 픽셀 아이콘·48px 가독성·반투명 테두리 검수 필요.']))
assert len(catalog)==85 and len({x['id'] for x in catalog})==85
catalog.sort(key=lambda x:x['id']);(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
page=ROOT/'docs/item-icons/index.html';s=page.read_text();start=s.index('<main>');end=s.index('</main>',start)
cards=[]
for x in catalog:
 path='../../'+x['file'];name=html.escape(x['name']);cards.append(f'<article data-id="{x["id"]}"><h2>{name}</h2><small>{x["id"]}</small><div class="sizes">'+''.join(f'<img src="{path}" width="{size}" height="{size}" alt="{name} {size}px">' for size in [48,64,96])+f'</div><a href="{path}" target="_blank" rel="noopener">PNG 원본</a></article>')
s=s[:start]+'<main>'+''.join(cards)+s[end:];s=s.replace('재개 아이템 아이콘49종','전체 아이템 아이콘85종').replace('아이템 아이콘49종 · 2026-11-03 재개분','아이템 아이콘85종 · 전체 1차 제작본').replace('기존 로컬36종은 이 묶음에 없음.','미확보됐던36종은 현재 환경에서 재제작.');page.write_text(s)
p=ROOT/'game/tests/asset_production/verify_icons.gd';p.write_text(p.read_text().replace('!= 49','!= 85').replace('the 49 resumed icons','all 85 icons'))
print('Packaged85 icons (49 preserved +36 recreated)')
