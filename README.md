# 봄을 기다리는 국경

Springbound Frontier · 가제

동료와의 관계와 탄탄한 이야기를 중심에 둔 판타지 RPG 기획입니다. 캐릭터 기획과 시각 보드를 바탕으로, Godot에서 프롤로그 이동·대화·첫 전투·재도전을 연결했습니다. 전투 수치와 연출은 첫 플레이 검증 단계이며 최종 배경 아트·장면 BGM·Windows 검증은 후속 작업입니다.

## 프롤로그 플레이

현재 Mac에서 `프롤로그 플레이.command`를 실행하거나, Godot 4.6.3으로 `game/project.godot`를 열어 실행합니다.

마르타와 아침 이야기를 나누고 물 긷기·여관 심부름을 마친 뒤, 약을 챙겨 서리골 → 산길 → 돌샘으로 이동합니다. 상황별 대화와 완료 알림·목표 갱신이 연결되어 있습니다. WASD 상하좌우 한 걸음 이동 · E 대화/조사 · 우클릭 목적지 이동 · Esc 메뉴 · F5 저장 · F9 불러오기.

[첫 전투 실행·조작·검증](docs/first-battle.md) — `첫 전투 테스트.command`로 바로 시작.

[실행 방법·구현 범위·실제 화면](docs/prologue-spaces.md) · [프롤로그 대화·진행·전체 원고](docs/prologue-dialogue.md)

## 작업자 시작 문서

[전투 장비 권한·모션 기획](docs/combat-equipment-and-motion-spec.md) · [에셋 기획·구현 가드레일](docs/asset-planning-guardrails.md)

[에일 무기별 전투·승리 키포즈 시안](docs/ael-combat-motion-boards.md)
[아이템 외형 80종](docs/item-design-boards.md) — 장비 각 5종 변형과 기본 물품, 보드 15장
[NPC 전체 제작 목록](docs/npc-registry.md) · [이름 없는 NPC 14종 보드](docs/generic-npc-boards.md)

[조연 캐릭터 보드 26명](docs/supporting-cast-boards.md)
[프롤로그 완성도 개선·구현 계획](docs/prologue-completion-plan.md) — 서리골 배치부터 첫 전투·완주·Windows 검증까지 단계별 작업 순서
[환경 에셋 HTML 도감](docs/assets-viewer/index.html) — 다운로드 후 브라우저에서 열기

[환경 에셋 43종과 배치 가이드](docs/environment-assets.md) — 개별 3D 장면·나무 스프라이트·검수 뷰어

[구현 전 확정한 게임 기획](docs/confirmed-design.md)

[다음 질문과 미정 사항](docs/next-design-questions.md) — 전투는 그로우랜서 1편 Windows PC CD판 기준 · 추가 전투 설계 3개 완료 · 프롤로그 준비 9개 항목 완료

[최신 이미지 시안 4장](docs/visual-concepts.md) — 주인공·세계관 표지·인게임 화면·월드맵

2026-10-27까지의 질의응답에서 확정한 조작·전투·성장·탐험·관계·제작 범위를 정리했습니다. 미정 사항을 분리했으며, Godot 제작·Steam용 PC 출시 목표, 4방향 도트 스프라이트와 추가 전투 규칙까지 반영했습니다.

첫 제작본은 서리골의 아침부터 레온과의 첫 전투를 거쳐 돌샘에 도착하는 프롤로그 전체입니다.

## 저장소 수록 범위

확정 기획 문서, 캐릭터·적군·몬스터·아이템·모션 보드, 환경 팩과 검토 뷰어, Godot 프롤로그 코드를 수록합니다. 월드맵의 미수정 경로는 이미지 안내문에 정정했습니다. 과거 개인 대화 원문은 포함하지 않습니다. 현재 게임 대사는 별도 JSON과 프롤로그 대화 문서에 수록합니다.

[그로우랜서 전투 참고 및 검증 현황](docs/growlanser-combat-reference.md)

출시 목표는 Steam용 Windows PC 게임입니다. 개발 중 현재 Mac에서 같은 프로젝트를 실행해 플레이 테스트하며, Windows 빌드는 별도 검증합니다. 기존 웹 우선 테스트 계획은 필수 기준에서 제외하며, 첫 테스트는 데스크톱 실행 빌드를 기준으로 준비합니다.

[캐릭터 설정 — 에일 성격 및 동료 후보 전체 초안](docs/characters.md)

[캐릭터 보드 7장](docs/character-boards.md)

[에일 이동 동작 시제품](docs/ael-movement-assets.md) — 8개 장비 상태·4방향·256칸. [조작 가능한 이동 뷰어](assets/ael-movement/index.html).
[몬스터 보드 16종](docs/monster-boards.md) — 일반 12종·보스 4종. [HTML 갤러리](assets/monster-boards/index.html).
[인간 적군 보드 14종](docs/enemy-character-boards.md) — 주요 인물 6명·일반 병종 8종. [HTML 갤러리](assets/enemy-boards/index.html).
[방패 조합 기획과 시안](docs/shield-loadouts.md) — 한손검+방패·단검+버클러 각 16포즈, 방패 외형 5종. [통합 HTML 갤러리](assets/combat-motion-boards/ael/index.html).
