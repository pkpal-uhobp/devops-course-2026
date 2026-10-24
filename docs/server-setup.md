
# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины

- ОС: Ubuntu Server 24.04 LTS
- Виртуализация: Oracle VirtualBox
- Оперативная память: 2048 МБ
- Процессоры: 2 ядра
- Виртуальный диск: 25 ГБ
- Тип диска: динамически расширяемый

## 2. Сетевые интерфейсы

Адаптер 1:
- Тип подключения: NAT
- Интерфейс Ubuntu: enp0s3
- IP: 10.0.2.15
- Назначение: доступ в Интернет

Адаптер 2:
- Тип подключения: Host-only
- Интерфейс Ubuntu: enp0s8
- IP Ubuntu: 192.168.56.101/24
- IP Windows: 192.168.56.1/24
- Назначение: соединение между Windows и Ubuntu

## 3. Правило проброса портов

- Название правила: ssh
- Протокол: TCP
- Host IP: 127.0.0.1
- Host Port: 2222
- Guest Port: 2222

Подключение из Windows:
ssh devops

Файл конфигурации SSH-клиента Windows:
C:\Users\User\.ssh\config

## 4. Учётные записи

student:
- Первоначальная учётная запись
- Использовалась для установки и настройки системы
- Имеет права sudo

devops:
- Основная административная учётная запись
- Группы: devops, sudo, users
- Аутентификация SSH по ключу Ed25519
- Закрытый ключ: ~/.ssh/devops_vm на Windows
- Открытый ключ установлен на сервере
- Каталог ~/.ssh имеет права 700
- Файл authorized_keys имеет права 600

## 5. Служба SSH

Файл настроек:
/etc/ssh/sshd_config.d/99-hardening.conf

Параметры:

Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
AllowUsers devops
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2

Дополнительные изменения:
- В 50-cloud-init.conf закомментирована строка PasswordAuthentication yes.
- Сокет ssh.socket отключён.
- Служба ssh.service включена.

Проверка:
sudo sshd -t
sudo sshd -T
sudo ss -tlnp | grep sshd

## 6. Правила межсетевого экрана

Используется UFW.

- Status: active
- Default incoming: deny
- Default outgoing: allow
- 2222/tcp: LIMIT IN (SSH)
- 80/tcp: ALLOW IN (HTTP)
- 443/tcp: ALLOW IN (HTTPS)
- Logging: medium

Проверка:
sudo ufw status verbose

## 7. Снимки состояния

01-clean-install
- 24.10.2026
- После установки и обновления Ubuntu Server

02-keys-configured
- 24.10.2026
- После настройки пользователя devops и SSH-ключей

03-ssh-hardened
- 24.10.2026
- После усиления защиты SSH

## Восстановление конфигурации

После возврата к 01-clean-install необходимо:

1. Войти под первоначальным пользователем student.
2. Создать пользователя devops и добавить его в sudo.
3. Настроить ключевую аутентификацию SSH.
4. Создать файл 99-hardening.conf с параметрами раздела 5.
5. Устранить конфликт PasswordAuthentication в 50-cloud-init.conf.
6. Проверить конфигурацию через sudo sshd -t.
7. Перевести SSH на порт 2222.
8. Изменить проброс портов VirtualBox.
9. Настроить UFW, сначала разрешив SSH-порт 2222.
10. Добавить запись devops.local в hosts Windows.
11. Настроить полное имя devops-vm.devops.local.
12. Проверить SSH, UFW и сетевую связность.

Текущую работающую машину без необходимости не восстанавливать из снимка.


## 9. Контейнеризация

### 9.1. Установка Docker

Docker Engine установлен на Ubuntu Server 24.04
из официального APT-репозитория Docker.

Docker Engine: 29.9.2.
Docker Compose: v5.6.1.

Служба docker.service активна и запускается
через systemd.

Пользователь devops входит в группу docker
и может запускать контейнеры без sudo.
Группа docker предоставляет административные
возможности, поэтому доступ к ней ограничен.

### 9.2. Расположение проекта

Каталог приложения на сервере:
/home/devops/app/

Исходный код хранится в репозитории:
https://github.com/pkpal-uhobp/devops-course-2026

Рабочая ветка практической работы:
feature/docker

Исходники доставляются из WSL через rsync:

rsync -avz --delete --exclude=.env app/ devops:app/

Файл .env исключается из передачи.

### 9.3. Переменные окружения

Файл с параметрами PostgreSQL:
/home/devops/app/.env

Владелец: devops.
Права: 600.

Пароль создан командой openssl rand -hex 16.
Настоящий пароль не хранится в GitHub.

В репозиторий включён только шаблон
app/.env.example без настоящего пароля.

### 9.4. Docker Compose

Файл конфигурации:
/home/devops/app/docker-compose.yml

Сервисы:
- app: Flask, Gunicorn, образ devops-app:1.0;
- db: PostgreSQL, образ postgres:16-alpine.

Оба сервиса подключены к сети app_backend.
Внутри сети приложение обращается к СУБД
по имени db.

Готовность PostgreSQL проверяется командой
pg_isready через healthcheck.

Приложение запускается после перехода
СУБД в состояние healthy.

### 9.5. Порты и безопасность

Flask опубликован только по адресу:
127.0.0.1:5000

Порт PostgreSQL 5432 наружу не публикуется.

Процесс Flask внутри контейнера работает
от имени непривилегированного пользователя app.

### 9.6. Хранение данных

Именованный том PostgreSQL:
app_db_data

Команда docker compose down удаляет контейнеры,
но сохраняет данные в томе.

Команда docker compose down -v удаляет также том
и приводит к потере данных PostgreSQL.

Сохранность данных проверена счётчиком посещений:
до пересоздания контейнеров Visits: 4,
после пересоздания Visits: 5.

После удаления тома счётчик начался с Visits: 1.

### 9.7. Обратный прокси Nginx

Конфигурационный файл:
/etc/nginx/sites-available/devops-site

Статический сайт:
https://devops.local/

Контейнерное приложение:
https://devops.local/app/

Маршрут /app/ передаётся через proxy_pass
на http://127.0.0.1:5000/.

Nginx принимает HTTPS-соединение и передаёт
приложению заголовки Host, X-Real-IP,
X-Forwarded-For и X-Forwarded-Proto.

При остановке контейнера app сервер возвращает
502 Bad Gateway. Причина фиксируется в
/var/log/nginx/devops-site.error.log.

### 9.8. Управление контейнерами

Запуск проекта:
cd ~/app && docker compose up -d --wait

Проверка состояния:
docker compose ps

Просмотр журналов:
docker compose logs

Остановка приложения:
docker compose stop app

Запуск приложения:
docker compose start app

Обновление проекта:
docker compose up -d --build
