'use strict';
const entries=window.ASSET_REGISTRY.entries;
const $=s=>document.querySelector(s);
function options(selector,values){for(const v of values)$(selector).add(new Option(v,v));}
options('#category',[...new Set(entries.map(x=>x.category))]);
options('#phase',[...new Set(entries.map(x=>x.phase))]);
options('#status',[...new Set(entries.map(x=>x.design_status))]);
const fresh=entries.filter(x=>x.design_status==='외형 시안 제작');
$('#summary').textContent=`전체 ${entries.length.toLocaleString()}개 관리 항목 · 기존 참고 ${entries.filter(x=>x.design_status==='기존 시안').length}개 · 이번 외형 시안 ${fresh.length}개 · 나머지는 대기. 런타임 완료 수와 다릅니다.`;
function element(tag,text){const e=document.createElement(tag);if(text!==undefined)e.textContent=text;return e;}
function render(){const q=$('#search').value.toLowerCase(),c=$('#category').value,p=$('#phase').value,s=$('#status').value;const found=entries.filter(x=>(!c||x.category===c)&&(!p||String(x.phase)===p)&&(!s||x.design_status===s)&&(!q||[x.id,x.name,x.region,x.notes].join(' ').toLowerCase().includes(q)));$('#count').textContent=`${found.length}개 일치 · 제작 순서 오름차순`;
 const body=$('#rows');body.replaceChildren();const fragment=document.createDocumentFragment();for(const x of found){const tr=element('tr');tr.append(element('td',x.order));const name=element('td',x.name);name.append(element('small',x.id));tr.append(name);const cat=element('td',x.category);cat.append(element('small',x.region));tr.append(cat,element('td',x.phase));const status=element('td',x.design_status);status.append(element('small',x.runtime_status));tr.append(status);const output=element('td',x.deliverable);if(x.source){const a=element('a','참고 파일 열기');a.href=x.source.startsWith('assets/world-production/')?'../../'+x.source:'https://github.com/a01094864335-cell/springbound-frontier/blob/main/'+x.source;a.target='_blank';a.rel='noopener';output.append(element('br'),a);}const details=element('details'),summary=element('summary','제작 메모');details.append(summary,element('p',x.notes||'별도 메모 없음'),element('small','선행 ID: '+(x.dependencies.join(', ')||'없음')));output.append(details);tr.append(output);fragment.append(tr);}body.append(fragment);}
for(const selector of ['#search','#category','#phase','#status'])$(selector).addEventListener('input',render);render();
const dialog=$('dialog');for(const x of fresh){const article=element('article'),button=element('button'),im=element('img');im.src='../../'+x.source;im.alt=x.name;im.loading='lazy';button.setAttribute('aria-label',x.name+' 확대');button.append(im);button.onclick=()=>{$('#full').src=im.src;$('#full').alt=x.name;dialog.showModal();};article.append(element('h3',x.name),element('small',x.id),button);$('#boards').append(article);}
$('#close').onclick=()=>dialog.close();dialog.onclick=e=>{if(e.target===dialog)dialog.close();};
