# 조사 방법·근거·한계

## 고정 기준

- 기획/시나리오: `e2bfe5a25b49b9129bc3629041d5de00cfda1e50` — PR19.
- 에셋: `63ae017a26d036c2fba002fe79ac2393d1bcd8ee` — PR14.
- 원격 main: `991614382ffdc36c529a0294eaa3fdc79b253b4a`. 조사 시 두 기준 커밋은 main의 조상이 아니다. 다른 로컬은 main만 받아 최신 에셋/기획이 모두 왔다고 생각하면 안 된다.
- 현재 다른 로컬의 미업로드 코드·이미지·검수 결과는 확인하지 않았다. GitHub의 고정 커밋에 대한 결과다.

## 실제 수행한 조사

1. 대장2412개 ID·source 전체를 Git 트리와 대조했다. 고유 경로879개에 등록 경로 누락은0이다. 스토리 기준 경로 존재205참조와 에셋 기준을 구분했다.
2. 각 원본의 고정 커밋 파일을 임시 조사 폴더로 읽고, 네이티브 source와 literal `res://` 의존을 재귀로 추적했다.2476개의 참조에 누락0. 동적 props 폴더 조합은 event catalog의 실제14사건에서 actor clip/prop ID를 별도로 대조해 누락0을 확인했다. 임의의 런타임 payload·에디터 import cache·셰이더 컴파일까지 증명하지 않는다.
추가로 source와 하위 참조 이미지 492개를 전부 디코딩 검사하고 모션98/아이콘85의 manifest SHA256을 원본과 대조했다. 디코딩 오류와 해시 불일치는0이다. 이 검사는 미술 품질·발/손 정합을 승인하는 검사가 아니다. [이미지 무결성](image-integrity.json)에 파일별 결과를 기록했다.

3. 활성 motion catalog의98아틀라스/1563클립/6252프레임 참조를 전부 읽었다. 각 사각형의 PNG 경계·alpha32 기준 빈 셀·해당 SpriteFrames의 클립 이름·프레임 픽셀 동일성 후보를 확인했다. 스프라이트 애니메이션을 엔진에서 실행하지 않았다.
4. 상단/좌우 alpha32 실루엣이 셀 경계1px 이내인 후보를 추렸다. 바닥 경계는 의도된 발 접지일 수 있어 따로 기록했다. 이번283클립과 기존260플래그는 기준이 다르며212교집합/71이번만/48기존만/합집합331이다.331개 모두 잘렸다는 뜻이 아니다.
5.13개 무장 시안의 대기/이동/공격/피격/전투불능/승리×4방향을 ID 기준으로 대조해312슬롯 모두 있음을 확인했다. 원본 atlas의 옛 승리 포즈보다 활성 ID가 가리키는 보완 리소스를 우선했다. 카이 활24슬롯은 시안 후보로 분리했다.
6.85아이콘의 크기·알파·실루엣 영역을 읽었다. 고해상도 원본이며32/48/64 별도 최종 파일은0이다. 작은 화면에서 식별되는지는 실제 UI에서 별도 확인해야 한다.
7.80WAV를 전부 읽어 샘플레이트/채널/비트/길이/peak/RMS·무음/하드클리핑을 조사했다.80개 모두 mono,0.5~60초다. 무음/하드클리핑0이며 곡의 질·루프 체감·게임 믹스는 실청취하지 않았다.
8.29논리맵과52플레이 요구를 원본 카탈로그/기획과 다시 대조하고46개 작업 묶음으로 연결했다. 모든 대장 ID에도 해당 묶음과 원본 근거를 연결했다.

## 근거 위치

| 근거 | 확인하는 내용 |
|---|---|
| [에셋 제작 대장](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/docs/full-asset-registry.json) | 2412개 ID/카테고리/source/원래 제작 상태 |
| [최종 1차 제작 기록](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/docs/full-remainder-production.md) | 파일 확보0미확보·고해상도 모션 초안·실제 게임 연결 별도 |
| [동작 catalog](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/motions/catalog.json) | 활성 ID→resource→atlas/rect/anchor, art_approved=false |
| [motion bank](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/motions/motion_bank.gd) | frame별 원점/스케일 보정이 이미 존재. 본편 연결/48×64 재정합과 구분 |
| [사건 catalog](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/events/catalog.json) | 14개 기존 배우/소품/타임라인, gameplay_effects=false |
| [UI 구현 틀](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/ui/asset_widget.gd) | 기본 Control·샘플 콘텐츠·action 신호와 실제 상태 변경의 차이 |
| [필드 catalog](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/fields/catalog.json) | 29블록아웃의 실제 좌표·크기·경로·stage |
| [지역 상태 catalog](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/world_states/catalog.json) | 서리골3·레온고향1 소품 블록아웃, 런타임 false |
| [게임 프롤로그 코드](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/scripts/prologue.gd) | 기존 portrait3명+7NPC 보드 고정 크롭. 제작 UI와 표현 재사용의 후보 |
| [이번 정적 결과](static-summary.json) | 검사 수·하드 오류/위험 후보·범위 |
| [대장 전체 판정](full-inventory-review.json) | ID별 source 링크·관련 부족 작업·범위 주의 |

## 직접 본 대표 원본6개

이6개는 시각 샘플이다. 전체6252프레임을 사람 눈으로 승인한 것으로 표시하지 않는다. 이미지의 투명 배경이 뷰어에 어떻게 합성되는지와 실제 알파 검사는 분리했다.

| 원본 | 관찰 | 다음 판단 |
|---|---|---|
| [에일 검 원본 atlas](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/motions/party-0-0.png) | 자세 변화·방향·공격 원본이 있다. 옛 축하 승리는 별도 보완이 활성 경로 | 전체 신규 제작 불필요, 무기손/픽셀·활성 ID 검수 |
| [리아 기본 atlas](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/motions/npc-ria.png) | 캐릭터·창·망토 동작 자료 있음. 작은 실루엣/경계/방향 정합은 남음 | 보드부터 다시 그릴 필요 없음 |
| [부활약 원본](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/icons/icon-item-recovery-and-cures-04.png) | 깔끔한 고해상도 셀 채색형 도안이 있다 | 작은 아이콘에서 실루엣·회복약과 구별되는지 확인 |
| [에일 차분한 승리 보완](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/production/motions/victory-ael-0.png) | 검을 낮추는4방향 포즈가 있음. 상단/셀 여백은 검토 필요 | 성격에 맞는 승리가 없다고 다시 만들지 않음 |
| [리아 보드v2](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/assets/character-boards/ria-board-v2.png) | 주요 표정4칸이 원화 안에 존재 | 추출·크롭/눈높이·대사 감정 매핑부터 |
| [에일 portrait 원본](https://github.com/a01094864335-cell/springbound-frontier/blob/63ae017a26d036c2fba002fe79ac2393d1bcd8ee/game/assets/ael-portrait.png) | 단일 얼굴 파일이 아니라 전신/도트/표정이 함께 든 보드 | portrait명 파일 수를 독립 얼굴 수로 세지 않음 |

## 판정 용어

- **등록 경로 누락**: 대장 source 또는 정적 리소스 참조 파일이 없음. 이번 검사의 범위에서는0.
- **전용 의미 매핑 없음**: 예를 들어 시전 이름 클립이 없지만 기존 자세/VFX를 재사용할 수 있음. 새 그림0/불가능이라는 뜻 아님.
- **최종화 필요**: 보드/고해상도 초안/블록아웃을 실제 규격·장면·음량에 맞춤.
- **연결 필요**: 원점/타격/소비/신호/인수/선택/골드 등 실제 상태와 연동. 그림을 새로 만들면 해결되는 문제가 아님.
- **검수 필요**: Windows·실청취·미술·현재 카메라·자막/폰트·실제 이동을 아직 확인하지 않음. 실패가 확정됐다는 뜻 아님.

확인하지 않은 다른 로컬 작업을 누락/실패로 단정하지 않는다. 보드만 있는214항목은 12공용부품+11배치도+64건물+55환경변형+72지역부품이며, 현재 채택 여부와 재사용을 먼저 정한다. 전체214개를 새로 만들어야 게임이 시작되는 선행 조건으로 만들지 않는다.
