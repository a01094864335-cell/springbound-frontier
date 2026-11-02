"""Original sample-free synthesized JRPG audio. Reproducible, with loop and gain metadata."""
from pathlib import Path
import array, hashlib, json, math, random, struct, wave, sys
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'game/assets/production/audio';OUT.mkdir(exist_ok=True)
RATE=22050;TAU=math.tau
registry=json.loads((ROOT/'docs/full-asset-registry.json').read_text())
def write(entry,data,loop=False):
 peak=max(abs(v) for v in data) or 1.;gain=min(.85/peak,1.0)
 samples=array.array('h',(int(max(-1,min(1,x*gain))*32767) for x in data))
 path=OUT/(entry['id']+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(samples.tobytes())
 duration=len(data)/RATE;rms=math.sqrt(sum((x*gain)**2 for x in data)/len(data))
 return dict(id=entry['id'],name=entry['name'],path='res://assets/production/audio/'+path.name,category=entry['category'],sample_rate=RATE,channels=1,bits=16,duration=duration,loop=loop,loop_start=0,loop_end=len(data),peak=peak*gain,rms=rms,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),source='Original deterministic synthesis; no external samples',review='File and signal checks only; in-game listening review pending')
def noise(n,seed):
 rng=random.Random(seed);return [rng.uniform(-1,1) for _ in range(n)]
def filt(data,alpha):
 out=[];state=0.
 for v in data:state+=alpha*(v-state);out.append(state)
 return out
def sfx(entry,i):
 duration=1.2 if i in [17,18,19,20,21,22,23,24,25,26,38,39,40] else .5
 n=int(duration*RATE);raw=noise(n,i*113);low=filt(raw,.045);mid=filt(raw,.25);out=[]
 for j in range(n):
  t=j/RATE;p=t/duration;attack=min(1,t/.006);env=attack*(1-p)**3
  if i<=5: # Foot surface: broad thump, separate grit/crunch/splash spectra.
   impact=math.sin(TAU*(72-30*p)*t)*math.exp(-t*22)
   texture=[mid[j]*.28,(raw[j]-mid[j])*.2,mid[j]*.14,raw[j]*.15,low[j]*.65][i-1]
   v=(impact*.38+texture*math.exp(-t*(13 if i!=5 else 7)))*attack
  elif i==6:v=mid[j]*.35*math.sin(math.pi*p)**2
  elif i in [7,8,9]:v=(raw[j]-low[j])*.32*math.sin(math.pi*p)**3*(1 if i!=8 else .8)
  elif i==10:v=(raw[j]-mid[j])*.4*env+math.sin(TAU*(380-240*p)*t)*.16*env
  elif i in [11,12,13,14]:
   f=[160,95,64,115][i-11];v=(math.sin(TAU*f*t)*.5+math.sin(TAU*f*2.73*t)*.18+mid[j]*.35)*env
  elif i in [15,16,30,31,32,33,34,35,36,37]:
   f={15:660,16:330,30:784,31:660,32:440,33:880,34:440,35:175,36:660,37:523}[i]
   sign=-1 if i in [34,35] else 1
   if i==15: f+=220*int(p*3)
   elif i==31:f+=173*int(p*2)
   elif i==36:f+=110*int(p*4)
   v=(math.sin(TAU*(f+sign*110*p)*t)*.4+math.sin(TAU*f*1.5*t)*.11)*env
  elif i in [17,18,19,22]: # Stylized creature vocal, AM/formant rather than stock samples.
   f={17:260,18:83,19:960,22:180}[i];pitch=f*(1+.13*math.sin(TAU*3*t)+.3*math.sin(math.pi*p))
   v=(math.sin(TAU*pitch*t)*.35+math.sin(TAU*pitch*2*t)*.1+mid[j]*.10)*math.sin(math.pi*p)**2
  elif i in [20,21,23,24,25,26]:
   pulse=max(0,math.sin(TAU*({20:18,21:24,23:7,24:3,25:5,26:2}[i])*t))**4
   v=(mid[j]*.32+math.sin(TAU*(110+i*7)*t)*.12)*pulse*math.sin(math.pi*p)**2
  elif i in [27,28,29]:
   creak=math.sin(TAU*(180-80*p)*t)*math.sin(TAU*13*t)*.14
   v=(creak+mid[j]*.28)*math.sin(math.pi*p)**2
  elif i==38:v=low[j]*.55+raw[j]*.06*max(0,math.sin(TAU*27*t))**20
  elif i==39:v=math.sin(TAU*(140+35*math.sin(TAU*2*t))*t)*.26*math.sin(math.pi*p)**2
  else:v=(low[j]*.35+math.sin(TAU*98*t)*.12)*math.sin(math.pi*p)**2
  # Exact zero endpoints prevent clicks. In-world triggers choose their own gain.
  out.append(v*min(1,j/60,(n-1-j)/60))
 return out
def ambient(entry,i):
 duration=16;n=RATE*duration;raw=noise(n,700+i);lo=filt(raw,.012);mi=filt(raw,.11);out=[]
 wind=i in [1,2,3,4,8,11,13];water=i in [7,8,13,14]
 for j in range(n):
  t=j/RATE;p=t/duration
  slow=.65+.25*math.sin(TAU*p)+.1*math.sin(TAU*3*p+i)
  v=lo[j]*(1.3 if wind else .45)*slow+mi[j]*(.15 if water else .035)
  if i in [9,10,12,16,17]:v+=.035*math.sin(TAU*(55 if i!=17 else 82.5)*t)+.018*math.sin(TAU*110*t)
  if i in [5,6,7,14,15]:
   # Soft distant activity pulses, kept abstract instead of fake spoken dialogue.
   pulse=max(0,math.sin(TAU*(.25+i*.0625)*t))**24
   v+=mi[j]*pulse*.16
  if i==2:v+=.045*math.sin(TAU*1760*t)*max(0,math.sin(TAU*.5*t))**40
  if i in [7,13,14]:v+=.06*mi[j]*(.5+.5*math.sin(TAU*.25*t))
  out.append(v)
 # Periodic crossfade uses a copied head/tail seam; no end-to-end discontinuity.
 fade=RATE
 for j in range(fade):
  a=j/fade;mix=out[j]*a+out[n-fade+j]*(1-a)
  out[j]=mix;out[n-fade+j]=mix
 # Trim duplicated overlap. First and last values follow the same time window.
 return out[:-fade]
def freq(note):return 440*2**((note-69)/12)
def note(buf,start,duration,pitch,gain,instrument):
 begin=int(start*RATE);length=int(duration*RATE);frequency=freq(pitch)
 for j in range(length):
  k=begin+j
  if k>=len(buf):break
  t=j/RATE;p=j/max(1,length-1);attack=min(1,t/.02);release=min(1,(duration-t)/.09)
  if instrument=='bell':env=attack*release*math.exp(-t*3.5);tone=math.sin(TAU*frequency*t)+.25*math.sin(TAU*frequency*2.76*t)
  elif instrument=='flute':env=attack*release*(.8+.2*math.sin(TAU*4*t));tone=math.sin(TAU*frequency*t)+.08*math.sin(TAU*frequency*2*t)
  else:env=attack*release*math.exp(-t*2);tone=math.sin(TAU*frequency*t)+.27*math.sin(TAU*frequency*2*t)+.1*math.sin(TAU*frequency*3*t)
  buf[k]+=tone*env*gain
# Distinct composed motifs, not copies or sampled melodies. Four-bar phrases repeat with response variation.
profiles=[
(76,48,[0,5,7,0],[0,4,7,11,9,7,4,2],'bell'),
(84,48,[0,5,0,7],[4,7,9,7,4,2,0,2],'pluck'),
(98,45,[0,5,7,0],[0,3,7,10,7,5,3,2],'flute'),
(88,50,[0,7,5,0],[0,7,5,4,2,4,7,9],'pluck'),
(72,45,[0,8,5,7],[0,3,2,0,7,5,3,2],'flute'),
(104,48,[0,5,7,0],[0,4,7,12,11,9,7,4],'bell'),
(92,53,[0,7,5,0],[4,2,0,7,9,7,4,2],'bell'),
(108,50,[0,5,7,0],[0,7,4,9,7,2,4,0],'pluck'),
(78,42,[0,3,8,7],[0,3,7,8,7,3,2,0],'bell'),
(80,48,[0,5,9,7],[7,4,0,2,5,9,7,4],'flute'),
(112,53,[0,7,5,0],[0,4,7,9,12,9,7,4],'pluck'),
(68,50,[0,5,7,0],[0,7,12,11,7,5,4,2],'flute'),
(70,45,[0,8,5,7],[0,7,3,2,5,3,0,-2],'bell'),
(64,42,[0,8,3,7],[0,3,7,10,8,7,3,2],'bell'),
(136,45,[0,5,8,7],[0,7,3,10,7,5,3,2],'pluck'),
(144,42,[0,3,8,7],[0,3,7,6,3,10,7,2],'pluck'),
(128,38,[0,8,5,7],[0,7,10,7,3,5,2,0],'bell'),
(116,42,[0,3,8,7],[0,7,12,10,7,8,3,2],'bell'),
(120,48,[0,5,7,0],[0,4,7,12,11,7,9,12],'bell'),
(126,45,[0,8,5,7],[0,3,2,-1,0,7,6,2],'pluck'),
(66,45,[0,8,5,7],[7,5,3,2,0,2,3,0],'flute'),
(82,48,[0,5,0,7],[0,4,7,9,7,4,2,0],'flute'),
(74,48,[0,5,7,0],[4,7,12,11,9,7,4,0],'bell')]
def music(entry,i):
 bpm,root,chords,motif,inst=profiles[i-1];beat=60/bpm;bar=beat*4;bars=16
 # Reserve short natural decay tails for the mix before wrapping into loop start.
 n=int(bars*bar*RATE);buf=[0.]*(n+RATE*2)
 for b in range(bars):
  chord=root+chords[b%4];minor=i in [3,5,9,13,14,15,16,17,18,20,21]
  triad=[chord,chord+(3 if minor else 4),chord+7]
  for step in range(8):
   start=b*bar+step*beat*.5
   note(buf,start,beat*.9,triad[step%3]+12,.065,'pluck')
   melody=root+12+motif[(step+(b//4)*2)%8]+(12 if b>=12 and step in [0,4] else 0)
   note(buf,start,beat*.47,melody,.10,inst)
  for step in [0,2]:note(buf,b*bar+step*beat,beat*1.8,chord-12,.12,'pluck')
  if i in [8,11,15,16,17,18,19,20]:
   for step in range(4):
    start=int((b*bar+step*beat)*RATE)
    for j in range(int(.12*RATE)):
     buf[start+j]+=.12*math.sin(TAU*(70-35*j/(.12*RATE))*j/RATE)*math.exp(-j/(RATE*.025))
 # Loop tail wraps musically rather than dropping decay at the seam.
 for j in range(RATE*2):buf[j]+=buf[n+j]
 return buf[:n]
selected=set(sys.argv[1:])
catalog=json.loads((OUT/'catalog.json').read_text()) if selected and (OUT/'catalog.json').exists() else []
catalog=[e for e in catalog if e['id'] not in selected]
for e in [x for x in registry['entries'] if x['category'] in ['효과음','환경음','음악']]:
 if selected and e['id'] not in selected:continue
 i=int(e['id'].rsplit('-',1)[1]);category=e['category']
 data=sfx(e,i) if category=='효과음' else ambient(e,i) if category=='환경음' else music(e,i)
 row=write(e,data,category!='효과음');catalog.append(row)
 print(e['id'],e['name'],round(row['duration'],2),flush=True)
catalog.sort(key=lambda e:e['id'])
(OUT/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
(OUT/'PROVENANCE.txt').write_text('All recordings are original deterministic synthesis by build_runtime_audio.py. No sampled recordings, external melodies, licensed music, or voice performers. 23 original four-phrase instrumental themes; 40 stylized synthesized effects; 17 synthesized environmental beds. WAV PCM16 mono 22050 Hz. File/signal checks do not replace listening review.\n')
print('Authored',len(catalog),'WAV sources')
