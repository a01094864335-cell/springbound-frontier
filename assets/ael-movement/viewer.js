'use strict';
const boards=window.MOVEMENT_DATA.boards;
const select=document.querySelector('#loadout'),canvas=document.querySelector('#stage'),ctx=canvas.getContext('2d');
const sheet=document.querySelector('#sheet'),status=document.querySelector('#status'),fps=document.querySelector('#fps');
const images=boards.map(b=>{const im=new Image();im.src=b.file;return im;});
boards.forEach((b,i)=>select.add(new Option(b.name,i)));
let x=384,y=288,dir=0,step=null,settle=0,paused=false,last=0,held=[],pending=null,loadFailed=false;
const vectors=[[0,1],[0,-1],[-1,0],[1,0]],keys={s:0,ArrowDown:0,w:1,ArrowUp:1,a:2,ArrowLeft:2,d:3,ArrowRight:3};
function clearInput(){held=[];pending=null;}
function reset(){x=384;y=288;dir=0;step=null;settle=0;clearInput();}
function updateSheet(){const b=boards[Number(select.value)];sheet.src=b.file;document.querySelector('#download').href=b.file;reset();}
select.onchange=updateSheet;updateSheet();
images.forEach(im=>im.onerror=()=>{loadFailed=true;status.textContent='이미지를 불러오지 못했습니다. PNG와 HTML을 함께 압축 해제해주세요.';});
document.querySelector('#reset').onclick=reset;
document.querySelector('#pause').onclick=e=>{paused=!paused;clearInput();e.target.textContent=paused?'재개':'일시 정지';};
fps.oninput=()=>document.querySelector('#speed').textContent=fps.value;
function editable(t){return ['INPUT','SELECT','TEXTAREA','BUTTON'].includes(t.tagName);}
window.addEventListener('keydown',e=>{if(editable(e.target))return;const key=e.key.length===1?e.key.toLowerCase():e.key;if(!(key in keys))return;e.preventDefault();if(paused)return;if(!held.some(k=>k.key===key)){held.push({key,dir:keys[key]});pending=keys[key];}});
window.addEventListener('keyup',e=>{const key=e.key.length===1?e.key.toLowerCase():e.key;held=held.filter(k=>k.key!==key);});
window.addEventListener('blur',clearInput);document.addEventListener('visibilitychange',()=>{if(document.hidden)clearInput();last=0;});
for(const b of document.querySelectorAll('[data-dir]'))b.onclick=()=>{if(!paused)pending=Number(b.dataset.dir);};
function begin(d){dir=d;const [dx,dy]=vectors[d],nx=x+dx*48,ny=y+dy*48;if(nx<48||nx>720||ny<144||ny>480){settle=0;return;}step={sx:x,sy:y,tx:nx,ty:ny,t:0,duration:6/Number(fps.value)};settle=0;}
function tick(dt){if(paused)return;if(step){step.t+=dt;const p=Math.min(1,step.t/step.duration);x=step.sx+(step.tx-step.sx)*p;y=step.sy+(step.ty-step.sy)*p;if(p===1){x=step.tx;y=step.ty;step=null;settle=.12;}}else{settle=Math.max(0,settle-dt);const next=pending??(held.length?held[held.length-1].dir:null);if(next!==null){pending=null;begin(next);}}}
function draw(){ctx.clearRect(0,0,768,512);ctx.fillStyle='#758568';ctx.fillRect(0,0,768,512);ctx.strokeStyle='#88977b';for(let gx=0;gx<=768;gx+=48){ctx.beginPath();ctx.moveTo(gx,0);ctx.lineTo(gx,512);ctx.stroke();}for(let gy=0;gy<=512;gy+=48){ctx.beginPath();ctx.moveTo(0,gy);ctx.lineTo(768,gy);ctx.stroke();}
 const col=step?1+Math.min(5,Math.floor(step.t/step.duration*6)):settle>0?7:0;
 const im=images[Number(select.value)];if(im.complete&&im.naturalWidth){ctx.imageSmoothingEnabled=false;ctx.drawImage(im,col*192,dir*256,192,256,Math.round(x-48),Math.round(y-128),96,128);}
 ctx.strokeStyle='#f0dfac';ctx.beginPath();ctx.moveTo(x-6,y);ctx.lineTo(x+6,y);ctx.stroke();
 if(!loadFailed)status.textContent=`${boards[Number(select.value)].name} · ${['아래','위','왼쪽','오른쪽'][dir]} · ${paused?'정지 중':step?'걷기':settle>0?'착지':'대기'} · 프레임 ${col+1}/8`;
}
function frame(now){const dt=last?Math.min(.05,(now-last)/1000):0;last=now;tick(dt);draw();requestAnimationFrame(frame);}requestAnimationFrame(frame);
