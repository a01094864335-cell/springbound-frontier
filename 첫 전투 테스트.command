#!/bin/zsh
set -e
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$PROJECT_ROOT/.local/Godot.app/Contents/MacOS/Godot" ]]; then
  GAME_ENGINE="$PROJECT_ROOT/.local/Godot.app/Contents/MacOS/Godot"
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  GAME_ENGINE=/Applications/Godot.app/Contents/MacOS/Godot
elif command -v godot >/dev/null 2>&1; then
  GAME_ENGINE="$(command -v godot)"
else
  echo 'Godot 4.6.3이 필요합니다. https://godotengine.org/download/archive/4.6.3-stable/'
  read '?Enter를 누르면 종료합니다.'
  exit 1
fi
exec "$GAME_ENGINE" --path "$PROJECT_ROOT/game" -- --battle-test
