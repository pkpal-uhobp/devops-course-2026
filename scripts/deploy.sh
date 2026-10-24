#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$PROJECT_DIR/site/"
DESTINATION="devops:/var/www/devops-site/"

if [[ ! -f "${SOURCE}index.html" || ! -f "${SOURCE}404.html" ]]; then
    echo "[ERROR] Файлы сайта не найдены"
    exit 1
fi

echo "Начинаем развёртывание сайта..."

if [[ "${1:-}" == "--dry-run" ]]; then
    echo "Режим проверки без передачи файлов"
    rsync -avz --delete --chmod=D755,F644 --dry-run "$SOURCE" "$DESTINATION"
elif [[ $# -eq 0 ]]; then
    rsync -avz --delete --chmod=D755,F644 "$SOURCE" "$DESTINATION"
    echo "[OK] Сайт успешно опубликован"
else
    echo "Использование: $0 [--dry-run]"
    exit 2
fi
