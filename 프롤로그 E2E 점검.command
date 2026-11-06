#!/bin/zsh
set -e
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
python3 "$PROJECT_ROOT/tools/verify_prologue.py" --native
read '?검수가 끝났습니다. Enter를 누르면 종료합니다.'
