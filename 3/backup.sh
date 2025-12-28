#!/bin/bash

SOURCE_DIR="/home/ayrat"
TARGET_DIR="/tmp/backup"

rsync -av --delete "$SOURCE_DIR" "$TARGET_DIR" > /dev/null 2>> /var/log/backup.log

if [ $? -eq 0 ]; then
    echo "[$(date)] Резервное копирование успешно выполнено" >> /var/log/backup.log
else
    echo "[$(date)] Ошибка при выполнении резервного копирования" >> /var/log/backup.log
fi
