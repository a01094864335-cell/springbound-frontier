#!/usr/bin/env python3
"""Repeatable MQ01–05 QA. Each run uses isolated saves, settings and engine logs."""
import argparse, json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--engine', default=os.environ.get('GODOT_BIN'))
p.add_argument('--native', action='store_true', help='Also run native input and rendered playthrough checks')
p.add_argument('--output', type=Path)
a=p.parse_args()
candidates=[a.engine, str(ROOT/'.local/Godot.app/Contents/MacOS/Godot'),str(ROOT.parent/'springbound-frontier/.local/Godot.app/Contents/MacOS/Godot'),shutil.which('godot')]
engine=next((x for x in candidates if x and Path(x).is_file()),None)
if not engine: sys.exit('Godot 4.6.3 경로를 --engine 또는 GODOT_BIN으로 지정하세요.')
out=(a.output or Path(tempfile.mkdtemp(prefix='springbound-prologue-qa-'))).resolve()
out.mkdir(parents=True,exist_ok=True)
checks=[('grid',['--script','res://tests/grid_walker_test.gd']),('story',['--script','res://tests/prologue_story_test.gd']),('environment',['--script','res://tests/environment_pack_test.gd']),('battle_core',['--script','res://tests/first_battle_test.gd']),('presentation',['--script','res://tests/presentation_test.gd']),('contracts',['--script','res://tests/prologue_contract_test.gd','--','--playthrough-qa']),('world',['--','--qa']),('battle_integration',['--','--battle-qa'])]
for choice in ['a','b']:checks.append(('e2e_'+choice,['--script','res://tests/prologue_e2e.gd','--','--playthrough-qa','--choice='+choice]+(['--mute','--large-text'] if choice=='b' else [])+['--qa-output='+str(out/('e2e_'+choice))]))
if a.native:
 checks += [('native_input',['--','--battle-input-qa']),('native_e2e',['--script','res://tests/prologue_e2e.gd','--','--playthrough-qa','--qa-output='+str(out/'native_e2e')])]
report={'scope':'MQ01–05; Windows build and independent first-time player review excluded','checks':{}}
for name,args in checks:
 native=name.startswith('native_')
 cmd=[engine]+([] if native else ['--headless'])+['--path',str(ROOT/'game'),'--log-file',str(out/(name+'-engine.log'))]+args
 if '--' in args:cmd+=['--qa-data-dir='+str(out/(name+'-data'))]
 start=time.monotonic()
 try:
  result=subprocess.run(cmd,capture_output=True,text=True,timeout=180)
  text=result.stdout+result.stderr
  passed=result.returncode==0 and 'PASS' in text and 'FAIL' not in text and 'SCRIPT ERROR' not in text
  code=result.returncode
 except subprocess.TimeoutExpired as e:
  text='TIMEOUT\n'+str(e);passed=False;code=None
 (out/(name+'.log')).write_text(text)
 report['checks'][name]={'passed':passed,'exit_code':code,'seconds':round(time.monotonic()-start,2),'summary':[s for s in text.splitlines() if 'PASS' in s or 'FAIL' in s]}
 print(name, 'PASS' if passed else 'FAIL',flush=True)
report['passed']=all(x['passed'] for x in report['checks'].values())
(out/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(out/'verification.json')
sys.exit(0 if report['passed'] else 1)
