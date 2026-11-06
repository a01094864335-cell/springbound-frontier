# 전체 메인 42·서브 24 상세화 범위

이 표는 **대본·명세 위치 색인**이다. 게임 구현 완료율 표가 아니다. 모든 구간의 실제 구현·실행·검수는 다른 로컬의 결과로 별도 확인해야 한다.

| 범위 | 상세 대본 | 연출·진행 명세 | 외부 로컬 완료 기준 |
|---|---|---|---|
| MQ01~05 | [프롤로그](../prologue/full-script.md) | [명세](../prologue/implementation-handoff.md) | [35항목](../prologue/acceptance.md) |
| MQ06~10 | [고향 귀환](../homecoming/full-script.md) | [명세](../homecoming/implementation-handoff.md) | [33항목](../homecoming/acceptance.md) |
| MQ11~15 | [교량 구조](../bridge/full-script.md) | [명세](../bridge/implementation-handoff.md), [전투](../bridge/battle-spec.md) | [36항목](../bridge/acceptance.md) |
| MQ16~20 | [왕도의 대답](chapter-04.md) | [장별 명세](quest-handoff.md) | [50항목](acceptance.md) |
| MQ21~26 | [얼음 아래 연결망](chapter-05.md) | [장별 명세](quest-handoff.md) | 위 잔여 범위 검수표 |
| MQ27~31 | [바다 건너의 겨울](chapter-06.md) | [장별 명세](quest-handoff.md) | 위 잔여 범위 검수표 |
| MQ32~36 | [함께 고치는 방법](chapter-07.md) | [장별 명세](quest-handoff.md) | 위 잔여 범위 검수표 |
| MQ37~42 | [각자의 자리](chapter-08.md) | [장별 명세](quest-handoff.md), [전투·연락·결말](combat-and-contact.md) | 위 잔여 범위 검수표 |

전체 서브 이벤트의 상세 원고 위치·해금·선행은 [서브 전체 표](side-handoff.md)에 있다. SE04/16/19/20/21은 교량/귀환 패키지, 나머지 19종은 [이번 서브 대본](side-scenarios.md)이다.

기존 42개 메인과 24개 서브의 요약 원본 ID를 유지했다. 81개 메인 장면과 57개 서브 장면은 퀘스트/이벤트를 나눈 표현 단위이며 별도 퀘스트 138개를 추가했다는 뜻이 아니다. 기존 구간의 선택 조사·재대화와 이번 원고의 보충 대사는 중복 집계하지 않는다.

현재 전편에서 공통으로 검토해야 할 제작 가정은 실제 지도 거리/이동 시간, 제한 통행·대피소 수용, 시설 안전 여력, 연락 왕복·창구, 적 배치/전투 수치, 동료 편성·역할 인계, 저장 이관, 최종 아트/음원이다. 기획 초안이 있다는 이유로 이러한 구현·산정까지 끝났다고 보고하지 않는다.
