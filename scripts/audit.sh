
#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo " [OK]   $desc"
        ((PASS++))
    else
        echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"
        ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"

check "Вход от имени root запрещён" "no" \
    "$(sudo sshd -T | awk '/^permitrootlogin /{print $2}')"

check "Парольная аутентификация отключена" "no" \
    "$(sudo sshd -T | awk '/^passwordauthentication /{print $2}')"

# TODO 1: порт SSH должен отличаться от 22
check "Порт SSH отличается от 22" "yes" \
    "$(sudo sshd -T | awk '$1=="port"{found=1; if ($2=="22") bad=1} END {print (found && !bad ? "yes" : "no")}')"

# TODO 2: MaxAuthTries должен равняться 3
check "MaxAuthTries равен 3" "3" \
    "$(sudo sshd -T | awk '/^maxauthtries /{print $2}')"

echo "[2] Межсетевой экран"

check "Межсетевой экран активен" "active" \
    "$(sudo ufw status | awk '/^Status:/{print $2}')"

# TODO 3: политика входящего трафика равна deny
check "Политика входящего трафика deny" "deny" \
    "$(sudo ufw status verbose | sed -nE 's/^Default: *([^ ]+) \(incoming\).*/\1/p')"

echo "[3] Учётные записи"

awk -F: '$3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd


# Docker checks PR7
echo "[5] Контейнеризация"

check "Служба Docker активна" "active" \
    "$(systemctl is-active docker 2>/dev/null || true)"

check "PostgreSQL имеет статус healthy" "healthy" \
    "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null || true)"

check "Порты 5000 и 5432 не открыты наружу" "yes" \
    "$(ss -tlnH | awk '$4 ~ /:(5000|5432)$/ && $4 !~ /^127[.]0[.]0[.]1:(5000|5432)$/ {bad=1} END {print bad?"no":"yes"}')"

check "Права файла .env равны 600" "600" \
    "$(stat -c '%a' "$HOME/app/.env" 2>/dev/null || true)"

echo "Пройдено: $PASS, не пройдено: $FAIL"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1

