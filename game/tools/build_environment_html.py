"""Build a self-contained offline HTML from exported Godot meshes and textures."""
from pathlib import Path
import base64,json
root=Path(__file__).resolve().parents[2]
viewer=root/'docs/assets-viewer'
assets=json.loads((viewer/'geometry.json').read_text())
paths=[root/f'game/assets/environment/textures/material_{i}.png' for i in range(6)]+[root/'game/assets/snow-spruce.png']
textures=['data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode() for p in paths]
payload=json.dumps({'assets':assets,'textures':textures},ensure_ascii=False,separators=(',',':')).replace('</','<\\/')
html=(viewer/'template.html').read_text().replace('__PAYLOAD__',payload)
(viewer/'index.html').write_text(html)
print('Built',viewer/'index.html',len(html.encode()),'bytes;',len(assets),'assets')
