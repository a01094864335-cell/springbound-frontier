# 등장인물·NPC 제작 목록

2026-10-29 · **이름 있는 인물 33명(에일 1 + 동료 후보 5 + 이름 있는 NPC 27), 공통형 14종**

에일은 NPC 수에서 제외합니다. 비플레이어 항목은 동료 5 + 이름 있는 NPC 27 + 공통형 14 = 46개이며, 이는 월드에 46명이 배치됐다는 뜻이 아닙니다. 공통형 하나로 여러 개체를 만들 수 있습니다. 이름 있는 NPC 27명은 마르타와 기존 조연 26명입니다.

이 문서는 인물 구성과 에셋 제작 대장입니다. 이름·지역·상호작용·필요 동작은 기존 확정 기획을 우선하는 배치 제안입니다. 새 NPC를 실제 맵에 배치하거나 상점·전투를 구현한 결과가 아닙니다. 보드 속 도트는 개별 48×64 투명 스프라이트나 애니메이션 완성본이 아닙니다.

- [기존 주연 보드](character-boards.md) · [조연 26명 보드](supporting-cast-boards.md) · [공통 NPC 14종 보드](generic-npc-boards.md)
- [JSON 제작 대장](npc-registry.json) · [CSV 내려받기](npc-registry.csv)
- ID는 인물 또는 타입 식별자입니다. 실제 배치 시에는 별도 instance_id와 spawn 조건·좌표·행동 경로가 필요합니다.

## 프롤로그 우선 제작·배치 제안

| 구간 | 핵심 인물 | 선택/생활 인물 후보 | 주의 |
|---|---|---|---|
| 마르타의 집 | 에일·마르타·펠 | 없음 | 배달 요청과 준비 흐름을 우선 |
| 서리골 | 오르만 | 니아·도렌·베라·로크·일반 주민 | 필수 심부름과 선택 이벤트를 구분하고 밀집 배치하지 않음 |
| 산길 | 에일·레온 | 여행자 또는 벌목꾼은 필요한 경우만 | 레온 고립과 첫 전투의 위험을 약화시키는 구조대 NPC를 곁에 두지 않음 |
| 돌샘 도착 | 에다 | 할벤은 연락소 안내가 필요하면 추가 | 약은 의무실, 군 연락은 연락소로 역할 구분 제안 |

P0는 프롤로그 우선 **후보**이며 모두 필수 등장 확정이 아닙니다. 이름 있는 인물과 같은 역할의 공통형을 동시에 넣어 동일 대화·기능을 중복시키지 않습니다. 병사 공통형을 전투 적으로 사용할지는 소속이 아니라 사건별 관계로 결정합니다.


## 주인공 — NPC 집계 제외

| ID | 이름/타입 | 역할 | 등장 지역 제안 | 우선순위 | 보드 |
|---|---|---|---|---|---|
| `pc-ael` | 에일 | 고정 주인공 | 서리골·산길·돌샘 | P0 프롤로그 | [보기](../assets/character-boards/ael-board-v1.png) |

## 동료 후보 5명

| ID | 이름/타입 | 역할 | 등장 지역 제안 | 우선순위 | 보드 |
|---|---|---|---|---|---|
| `npc-leon` | 레온 | 부상당한 기사·동료 후보 | 산길·돌샘·국경 | P0 프롤로그 | [보기](../assets/character-boards/leon-board-v2.png) |
| `npc-ria` | 리아 | 창병·구조 담당 | 피난 교량·아르덴·북방 시설 | P1 본편 | [보기](../assets/character-boards/ria-board-v2.png) |
| `npc-sena` | 세나 | 측량 연구원 | 남방 학술도시·북방 시설·고대 중추 | P1 본편 | [보기](../assets/character-boards/sena-board-v2.png) |
| `npc-kai` | 카이 | 항해·운송 담당 | 남방 항구·해양국·고대 중추 | P1 본편 | [보기](../assets/character-boards/kai-board-v1.png) |
| `npc-iris` | 이리스 | 기록 담당 사제 | 남방 학술도시·성역·고대 중추 | P1 본편 | [보기](../assets/character-boards/iris-board-v1.png) |

## 이름 있는 NPC 27명

| ID | 이름/타입 | 역할 | 등장 지역 제안 | 우선순위 | 보드 |
|---|---|---|---|---|---|
| `npc-marta` | 마르타 | 약초사·양육자·거점 지원 | 서리골 | P0 프롤로그 | [보기](../assets/character-boards/marta-board-v1.png) |
| `npc-orman` | 오르만 | 여관 주인 | 서리골 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/orman-board-v1.png) |
| `npc-nia` | 니아 | 마을 아이 | 서리골 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/nia-board-v1.png) |
| `npc-doren` | 도렌 | 장작꾼 | 서리골 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/doren-board-v1.png) |
| `npc-vera` | 베라 | 잡화점 주인 | 서리골 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/vera-board-v1.png) |
| `npc-roke` | 로크 | 마을 경비병 | 서리골 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/roke-board-v1.png) |
| `npc-pell` | 펠 | 배달꾼 | 돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/pell-board-v1.png) |
| `npc-eda` | 에다 | 의무실 책임자 | 돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/supporting-cast/eda-board-v1.png) |
| `npc-bram` | 브람 | 광산 반장 | 돌샘 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/bram-board-v1.png) |
| `npc-toma` | 토마 | 견습 광부 | 돌샘 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/toma-board-v1.png) |
| `npc-halven` | 할벤 | 연락소 담당관 | 돌샘 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/halven-board-v1.png) |
| `npc-adel` | 아델 | 레온의 부관 | 국경·아르덴·벨크 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/adel-board-v1.png) |
| `npc-grain` | 그레인 | 벨크 군 지휘관 | 국경·아르덴·벨크 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/grain-board-v1.png) |
| `npc-selma` | 셀마 | 북방 구호 행정관 | 국경·아르덴·벨크 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/selma-board-v1.png) |
| `npc-bern` | 베른 | 아르덴 현장 지휘관 | 국경·아르덴·벨크 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/bern-board-v1.png) |
| `npc-raul` | 라울 | 아르덴 협상관 | 국경·아르덴·벨크 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/raul-board-v1.png) |
| `npc-oswin` | 오스윈 | 세나의 스승·연구자 | 남방 도시연맹 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/oswin-board-v1.png) |
| `npc-mirena` | 미레나 | 수리 기술자 | 남방 도시연맹 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/mirena-board-v1.png) |
| `npc-vasco` | 바스코 | 상단 대표 | 남방 도시연맹 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/vasco-board-v1.png) |
| `npc-letia` | 레티아 | 도시 평의원 | 남방 도시연맹 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/letia-board-v1.png) |
| `npc-nadia` | 나디아 | 카이의 누나·함대 장교 | 해양국 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/nadia-board-v1.png) |
| `npc-yuno` | 유노 | 항만 의사 | 해양국 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/yuno-board-v1.png) |
| `npc-sabel` | 사벨 | 조위 관측관 | 해양국 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/sabel-board-v1.png) |
| `npc-teo` | 테오 | 피난선 선장 | 해양국 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/teo-board-v1.png) |
| `npc-estelle` | 에스텔 | 기록원 책임자 | 성역·고대 시설 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/estelle-board-v1.png) |
| `npc-luca` | 루카 | 현장 사제 | 성역·고대 시설 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/luca-board-v1.png) |
| `npc-sever` | 세베르 | 시설 연구 책임자·대립 인물 후보 | 성역·고대 시설 | P1 후속 장 | [보기](../assets/character-boards/supporting-cast/sever-board-v1.png) |

## 이름 없는 공통형 14종

| ID | 이름/타입 | 역할 | 등장 지역 제안 | 우선순위 | 보드 |
|---|---|---|---|---|---|
| `npc-type-village-man` | 마을 주민 남성 | 상점 손님·길 안내 | 서리골·돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/generic-npcs/village-man-board-v1.png) |
| `npc-type-village-woman` | 마을 주민 여성 | 주민 생활·소문 | 서리골·돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/generic-npcs/village-woman-board-v1.png) |
| `npc-type-village-child` | 마을 아이 공통형 | 놀이·짧은 선택 대화 | 서리골·돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/generic-npcs/village-child-board-v1.png) |
| `npc-type-elder-resident` | 노년 주민 공통형 | 마을 기억·계절 이야기 | 서리골·돌샘 | P0 프롤로그 후보 | [보기](../assets/character-boards/generic-npcs/elder-resident-board-v1.png) |
| `npc-type-wood-worker` | 벌목꾼 공통형 | 장작 운반·산길 정보 | 서리골·산길 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/wood-worker-board-v1.png) |
| `npc-type-miner-common` | 광부 공통형 | 광산 노동·구조 대상 | 돌샘 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/miner-common-board-v1.png) |
| `npc-type-merchant-common` | 행상인 공통형 | 노점·통행 소식·판매 후보 | 서리골·돌샘·남방 도시연맹 | P0 프롤로그 후보 | [보기](../assets/character-boards/generic-npcs/merchant-common-board-v1.png) |
| `npc-type-traveler-common` | 여행자 공통형 | 길 안내·여관 손님 | 산길·남방 도시연맹 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/traveler-common-board-v1.png) |
| `npc-type-arden-soldier-common` | 아르덴 일반병 | 검문·경비·호위 후보 | 아르덴·서리골·피난 교량 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/arden-soldier-common-board-v1.png) |
| `npc-type-velk-soldier-common` | 벨크 일반병 | 국경 경비·수색·호위 후보 | 벨크·국경·북방 시설 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/velk-soldier-common-board-v1.png) |
| `npc-type-dock-worker-common` | 항만 인부 | 하역·구조·항로 소식 | 남방 항구·해양국 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/dock-worker-common-board-v1.png) |
| `npc-type-field-acolyte-common` | 구호 사제 공통형 | 구호·피난 안내 | 성역·피난 거점 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/field-acolyte-common-board-v1.png) |
| `npc-type-researcher-common` | 연구 보조원 | 관측·유적 기록 | 남방 학술도시·성역·고대 시설 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/researcher-common-board-v1.png) |
| `npc-type-refugee-common` | 피난민 공통형 | 대피·이송·전쟁 이후 변화 | 서리골·피난 교량·해양국 | P1 지역 확장 | [보기](../assets/character-boards/generic-npcs/refugee-common-board-v1.png) |


## 공통형 재사용 규칙

- 같은 유형을 여러 번 배치할 때 머리·옷색·모자·짐을 조합하되 원형 보드의 역할 실루엣을 유지합니다. 변형안은 JSON의 notes에 기록했습니다. 이번에는 타입별 대표 보드 1장씩이며 모든 변형 PNG를 만든 것은 아닙니다.
- 양국 병사는 복색·표식·장비로 구분합니다. 색만으로 소속을 전달하지 않고 이름표·대화·사건 맥락도 사용합니다.
- 피난민은 새로운 종족이나 고정 외모가 아닌 상황입니다. 기존 주민 개체에 보따리·담요·상태 변화를 연결해 전후를 알아볼 수 있게 합니다.
- 어린이와 노년 인물의 비율·보폭·발 기준점은 성인 템플릿과 구분합니다.
- 일반 민간인에게 전투 모션을 일괄 제작하지 않습니다. 공통형의 표정 보드는 대화 참고이며 모든 군중에게 큰 초상화를 표시하라는 뜻이 아닙니다.
- 공통형의 대표 성별은 제작 예시입니다. 역할을 그 성별로 제한하지 않으며 필요 시 추가 체형·성별 변형을 제작합니다.

## 다음 에셋 단계

외형 검토 → 개별 투명 스프라이트/초상화 제작 → 방향·장비·발 기준점 정리 → 필요한 애니메이션 → 맵 배치·충돌·행동 경로 → 대화·이벤트 연결 순입니다. 실제 등장 개체와 생성 조건은 이 제작 대장과 분리합니다.
