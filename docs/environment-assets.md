# 프롤로그 환경 에셋 팩

2026-10-28 · Godot 4.6.3 · 43개 개별 PackedScene

현재 실행 화면 `docs/screenshots/01-map.png`부터 `04-map.png` 및 `game/scripts/prologue.gd`의 배치와 치수를 참고했습니다. 기존 겨울 재질·침엽수 이미지를 재사용하고, 원래 코드 안에 있던 구조물을 개별 3D 장면으로 구성했습니다. 상자·가구·창틀 등은 독립 재사용할 수 있도록 디테일을 추가했습니다. 43종 모두 새로운 AI 이미지라는 의미는 아닙니다.

## 사용

- 개별 에셋: `game/assets/environment/scenes/*.tscn`. Godot의 파일 시스템에서 맵에 끌어다 놓습니다.
- 한 개씩 확인: `game/tools/environment_viewer.tscn`을 열고 F6. 좌우 키로 43종을 넘기고 휠로 확대합니다.
- 원점: 지면 기준 중심, 정면은 +Z. 벽 창문은 아래쪽 중심이 기준입니다. 재질은 공유하며, 텍스처는 기존 픽셀 재질에서 분리했습니다.
- 목록: `game/assets/environment/catalog.json`. 기존 좌표 참고: `placement-reference.json`.
- 3D 건물·소품은 편집 가능한 메시이고, 나무는 기존 이미지 기반 Sprite3D입니다. 눈더미와 일부 재질 타일은 길 막음이 없습니다.

## 현재 맵과 연결할 때

실행 중인 맵은 기존 생성 함수를 그대로 사용합니다. 이번 작업은 개별 에셋 제작과 분리이며 **현재 맵 전체를 새 장면으로 교체한 상태는 아닙니다**.

장면에는 StaticBody3D 충돌과 `grid_obstacles` 메타데이터가 함께 있습니다. 현재 GridWalker는 물리 충돌을 직접 읽지 않으므로, 기존 `_house`, `_tree` 등의 생성 호출을 해당 장면으로 교체할 때 루트의 로컬 사각형 목록을 맵의 `obstacles` 배열에 변환해 등록해야 합니다. 기본 스케일과 회전 없는 배치를 기준으로 했으며 회전·비균일 스케일을 적용하면 충돌 사각형도 변환해야 합니다. 기존 생성물과 중복 배치하지 마세요.

건물에는 기존 화면처럼 통 2개와 간판이 포함됩니다. 별도 통을 더 놓으면 중복될 수 있습니다. 가려짐 처리는 현재 `occluders` 구조에 새 인스턴스를 등록해야 합니다. 상호작용 영역·출구·NPC·퀘스트는 에셋에 포함하지 않았으므로 기존 좌표와 로직을 유지합니다. 에셋을 바꿨다고 출구나 대화가 자동 생성되지 않습니다.

## 에셋 목록

| ID | 개별 에셋 | 분류 | 사용 장소 |
|---|---|---|---|

| `herbalist_house` | 마르타의 약초사 집 | buildings | 서리골 |
| `village_cottage` | 서리골 민가 | buildings | 서리골 |
| `village_inn` | 서리골 여관 | buildings | 서리골 |
| `village_store` | 서리골 잡화점 | buildings | 서리골 |
| `border_office` | 돌샘 연락소 | buildings | 돌샘 |
| `mountain_cottage` | 돌샘 산촌 민가 | buildings | 돌샘 |
| `snow_spruce_tall` | 눈 덮인 침엽수 | vegetation | 서리골, 산길, 돌샘 |
| `snow_spruce_small` | 눈 덮인 침엽수 | vegetation | 서리골, 산길, 돌샘 |
| `snow_spruce_wide` | 눈 덮인 침엽수 | vegetation | 서리골, 산길, 돌샘 |
| `snow_boulder` | 적설 바위 | landscape | 서리골, 산길 |
| `snow_pebble` | 적설 바위 | landscape | 서리골, 산길 |
| `cliff_rock` | 적설 바위 | landscape | 서리골, 산길 |
| `frozen_stream_segment` | 얼어붙은 계류 모듈 | landscape | 산길 |
| `snow_drift` | 길 가장자리 눈더미 | landscape | 서리골, 산길, 돌샘 |
| `herb_patch` | 약초 군락 | vegetation | 산길 |
| `village_well` | 마을 우물 | street | 서리골 |
| `covered_well` | 지붕 우물 | street | 돌샘 |
| `border_gate` | 북쪽 국경문 | street | 서리골 |
| `wood_fence` | 3m 목책 모듈 | street | 서리골, 산길, 돌샘 |
| `lantern_post` | 따뜻한 가로등 | street | 서리골, 산길, 돌샘 |
| `notice_board` | 마을 게시판 | street | 서리골 |
| `trail_sign` | 산길 방향 표지 | street | 산길 |
| `snow_barrel` | 눈 덮인 나무통 | supplies | 서리골, 돌샘 |
| `supply_crate` | 보급 상자 | supplies | 돌샘 |
| `stacked_crates` | 적재한 보급품 | supplies | 돌샘 |
| `firewood_stack` | 쌓아둔 장작 | supplies | 서리골 |
| `traveler_pack` | 레온 곁 여행 짐 | supplies | 산길 |
| `wood_table` | 마르타의 작업 탁자 | interior | 집 |
| `wood_chair` | 작업 의자 | interior | 집 |
| `herbalist_bed` | 에일의 침대 | interior | 집 |
| `medicine_shelf` | 약병 선반 | interior | 집 |
| `medicine_parcel` | 돌샘에 전할 약 꾸러미 | interior | 집 |
| `medicine_stand` | 약 꾸러미 받침 상자 | interior | 집 |
| `mortar_and_pestle` | 약초 절구 | interior | 집 |
| `medicine_bottle` | 약병 | interior | 집 |
| `woven_rug` | 작업실 깔개 | interior | 집 |
| `interior_window` | 작업실 창문 | interior | 집 |
| `cobblestone_tile` | 돌길 바닥 | modules | 집, 서리골, 산길, 돌샘 |
| `snow_tile` | 눈 바닥 | modules | 집, 서리골, 산길, 돌샘 |
| `stone_wall_panel` | 돌벽 모듈 | modules | 집, 서리골, 산길, 돌샘 |
| `wood_floor_tile` | 목재 바닥 | modules | 집, 서리골, 산길, 돌샘 |
| `slate_roof_panel` | 슬레이트 지붕면 | modules | 집, 서리골, 산길, 돌샘 |
| `plaster_wall_panel` | 회벽 모듈 | modules | 집, 서리골, 산길, 돌샘 |


## 제작·검증

재생성(기존 43개 산출물을 덮어씀):

```sh
godot --headless --path game res://tools/build_environment_pack.tscn
```

로드·메타데이터·충돌 검증:

```sh
godot --headless --path game --script res://tests/environment_pack_test.gd
```

43개 장면의 인스턴스 생성, 노드·ID·충돌 메타데이터를 검증했습니다. 뷰어 시작도 헤드리스로 확인했습니다. 이번 환경에서는 그래픽 화면을 직접 렌더링해 시각 검수하지 못했으므로 Godot 뷰어에서 실제 조명·재질·크기를 확인한 뒤 배치해야 합니다.

슬레이트 지붕면은 평평한 재질 모듈이며, 완성 경사 지붕은 건물과 덮개 우물 장면에 포함됩니다. 캐릭터·적·UI·음향·추후 챕터의 건물은 이번 환경 에셋 범위에 포함하지 않습니다.
