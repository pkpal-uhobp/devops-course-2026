
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

