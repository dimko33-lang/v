
```
curl -s https://raw.githubusercontent.com/dimko33-lang/v/main/install.sh | sudo bash -s -- "sk-2"
```


```
# 1. Останавливаем всё, что могло быть запущено
pkill -f "python.*v.py" 2>/dev/null || true
pkill -f "python.*void.py" 2>/dev/null || true
pkill -f "python.*room.py" 2>/dev/null || true
systemctl stop v 2>/dev/null || true
systemctl stop void 2>/dev/null || true
systemctl stop room 2>/dev/null || true

# 2. Удаляем ВСЕ директории проектов
rm -rf /opt/v
rm -rf /opt/void
rm -rf /opt/room
rm -rf /opt/empty-room

# 3. Удаляем глобальные команды
rm -f /usr/local/bin/v
rm -f /usr/local/bin/void
rm -f /usr/local/bin/room

# 4. Чистим systemd-сервисы
rm -f /etc/systemd/system/v.service
rm -f /etc/systemd/system/void.service
rm -f /etc/systemd/system/room.service
rm -f /etc/systemd/system/empty-room.service
systemctl daemon-reload

# 5. (Опционально, но радикально) Сбрасываем Python-окружение до заводского
apt purge -y python3-venv python3-pip
apt autoremove -y
apt install -y python3 python3-venv python3-pip

echo "✅ Всё чисто. Как в первый день творения."
```
