"""Validate scenario references and render readable scenario documents. Standard library only."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'docs/scenario'
main = json.loads((DEST / 'main-quests.json').read_text())
side_path = DEST / 'side-events.json'
side = json.loads(side_path.read_text()) if side_path.exists() else []
ids = [q['id'] for q in main]
assert len(main) == 42 and len(set(ids)) == 42
seen = set()
lines = ['# 메인 퀘스트 시나리오', '', '시나리오 초안 · 대사 발췌본. 전체 대화 원고나 구현 완료 목록이 아니다. 연출·분기·조작 연결은 [작업 지침](README.md)을 함께 따른다.', '', '| ID | 장 | 퀘스트 | 장소 |', '|---|---|---|---|']
for q in main:
    assert all(p in seen for p in q['prerequisites']), q['id']
    seen.add(q['id'])
    lines.append(f"| {q['id']} | {q['chapter']} | [{q['title']}](#{q['id'].lower()}) | {q['location']} |")
for q in main:
    lines += ['', f"<a id=\"{q['id'].lower()}\"></a>", f"## {q['id']} · {q['title']}", '', f"{q['chapter']}장 **{q['chapter_title']}** · {q['location']}", '', f"- 진입: {', '.join(q['prerequisites']) or '새 게임 시작'}", f"- 플레이 목표: {q['objective']}", f"- 완료 판정: {q['completion']}", f"- 다음 흐름의 이유: {q['next_reason']}", '', '### 필수 장면 대사 발췌', '', '앞의 두 줄은 상황을 여는 대화, 가운데 두 줄은 갈등·판단, 마지막 두 줄은 다음 행동의 합의로 배치한다. MQ42는 인계와 귀향의 두 장면으로 나눈다.', '']
    lines += [f"- `{d['id']}` **{d['speaker']}**: {d['text']}" for d in q['dialogue']]
(DEST / 'main-scenario.md').write_text('\n'.join(lines)+'\n')
if side:
    assert len(side) == 24 and len({e['id'] for e in side}) == 24
    out=['# 서브 이벤트 시나리오', '', '메인 필수 정보·진행 열쇠를 서브 이벤트 보상으로 숨기지 않는다. 관계 변화는 서술 상태이며 수치·호감도 임계값은 미확정이다.', '', '| ID | 인물 | 이벤트 | 해금 | 선행 이벤트 |', '|---|---|---|---|---|']
    sid=set()
    for e in side:
        assert e['unlock'] in ids
        assert all(p in sid for p in e['prerequisites'])
        assert all(next(x['unlock'] for x in side if x['id']==p) <= e['unlock'] for p in e['prerequisites'])
        sid.add(e['id'])
        if e['deadline']:
            assert e['warning'] in ids and e['deadline'] in ids
            assert ids.index(e['unlock']) <= ids.index(e['warning']) < ids.index(e['deadline'])
        out.append(f"| {e['id']} | {e['character']} | [{e['title']}](#{e['id'].lower()}) | {e['unlock']} 완료 | {', '.join(e['prerequisites']) or '없음'} |")
    for e in side:
        out += ['',f"<a id=\"{e['id'].lower()}\"></a>",f"## {e['id']} · {e['title']}", '',f"- 인물·장소: {e['character']} · {e['location']}", f"- 해금: {e['unlock']} 완료 / 선행: {', '.join(e['prerequisites']) or '없음'}",f"- 플레이: {e['action']}",f"- 갈등과 변화: {e['change']}",f"- 선택과 반영: {e['choice']}",f"- 발생 기간: {e['availability']}",f"- 완료: {e['completion']}"]
        if e['deadline']:
            out += [f"- 사전 경고: {e['warning']} 완료 시 알림. {e['deadline']} 시작 전 재확인 후 해당 장면 종료.",f"- 놓친 경우: {e['fallback']}"]
        out += ['', '### 장면 대사 발췌', '']
        out += [f"- `{e['id']}-D{k:02}` **{d['speaker']}**: {d['text']}" for k,d in enumerate(e['dialogue'],1)]
    (DEST/'side-scenario.md').write_text('\n'.join(out)+'\n')
all_dialogue=[d['id'] for q in main for d in q['dialogue']]
assert len(set(all_dialogue)) == len(all_dialogue)
report=dict(main_quests=len(main),chapters=len({q['chapter'] for q in main}),main_excerpt_lines=len(all_dialogue),side_events=len(side),side_excerpt_lines=sum(len(e['dialogue']) for e in side),checks=['메인 선행 조건 순환·미정의 ID 없음','서브 해금 MQ·선행 이벤트 유효','서브 선행의 해금 시점이 역전되지 않음','기간 한정 이벤트 사전 경고가 종료보다 앞섬','메인 대사 ID 중복 없음'])
(DEST/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False))
