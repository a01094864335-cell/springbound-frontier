"""Recreate 36 native, signal-based UI widgets; no game state is mutated."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'game/assets/production/ui';OUT.mkdir(exist_ok=True)
rows=[x for x in json.loads((ROOT/'docs/full-asset-registry.json').read_text())['entries'] if x['category']=='UI']
assert len(rows)==36
kinds=['dialogue','nameplate','choices','portrait','interaction','quest_accept','quest_update','quest_complete','objective','local_map','world_map','destination','commands','target','move_target','range','danger','hp','mp','status','equipment','inventory','item_detail','buy','sell','relations','save','load','settings','keys','pause','results','retry','title','credits','loading']
entries=[]
for e,kind in zip(rows,kinds):
 entry={'id':e['id'],'name':e['name'],'kind':kind,'path':'res://assets/production/ui/'+e['id']+'.tscn','file':'game/assets/production/ui/'+e['id']+'.tscn','stage':'native_first_pass','runtime_connected':False,'recreated':True};entries.append(entry)
 (OUT/(e['id']+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://assets/production/ui/asset_widget.gd" id="1"]\n\n[node name="'+kind+'" type="PanelContainer"]\ncustom_minimum_size = Vector2(640, 360)\nscript = ExtResource("1")\nasset_id = "'+e['id']+'"\n')
(OUT/'catalog.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
(OUT/'frontier_theme.tres').write_text('''[gd_resource type="Theme" load_steps=5 format=3]
[sub_resource type="StyleBoxFlat" id="panel"]
bg_color = Color(0.075,0.12,0.16,0.97)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.65,0.52,0.31,1)
content_margin_left = 20.0
content_margin_right = 20.0
content_margin_top = 16.0
content_margin_bottom = 16.0
[sub_resource type="StyleBoxFlat" id="normal"]
bg_color = Color(0.16,0.23,0.27,1)
content_margin_left = 14.0
content_margin_right = 14.0
content_margin_top = 8.0
content_margin_bottom = 8.0
[sub_resource type="StyleBoxFlat" id="focus"]
bg_color = Color(0.32,0.37,0.35,1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.95,0.78,0.43,1)
[sub_resource type="StyleBoxFlat" id="fill"]
bg_color = Color(0.26,0.63,0.44,1)
[resource]
default_font_size = 19
PanelContainer/styles/panel = SubResource("panel")
Button/styles/normal = SubResource("normal")
Button/styles/hover = SubResource("focus")
Button/styles/focus = SubResource("focus")
Button/styles/pressed = SubResource("focus")
Button/colors/font_color = Color(0.94,0.90,0.80,1)
Label/colors/font_color = Color(0.94,0.90,0.80,1)
ProgressBar/styles/background = SubResource("normal")
ProgressBar/styles/fill = SubResource("fill")
''')
print('Created UI scenes:',len(entries))
