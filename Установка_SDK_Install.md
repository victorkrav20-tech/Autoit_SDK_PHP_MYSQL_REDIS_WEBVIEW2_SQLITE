# 🚀 AutoIt SDK — Руководство по установке

**SDK версия:** v0.4  
**Дата:** 2026  
**Статус:** Стабильная версия

---

## 📋 Содержание

1. [Установка AutoIt и SciTE](#1-установка-autoit-и-scite)
2. [Установка Visual C++ Runtime и .NET Framework](#2-установка-visual-c-runtime-и-net-framework)
3. [Установка и регистрация WebView2](#3-установка-и-регистрация-webview2)
4. [Проверка на базовых примерах](#4-проверка-на-базовых-примерах)
5. [Настройка MySQL](#5-настройка-mysql)
6. [Установка OpenServer (Redis + MySQL)](#6-установка-openserver-redis--mysql)
7. [Развёртывание PHP API](#7-развёртывание-php-api)
8. [Настройка и сборка Preact проекта](#8-настройка-и-сборка-preact-проекта)
9. [Настройка MCP сервера для Kiro IDE](#9-настройка-mcp-сервера-для-kiro-ide)
10. [Дополнительные инструменты](#10-дополнительные-инструменты)

---

## 1. Установка AutoIt и SciTE

Из папки `install\` запустить по порядку:

**1.1 AutoIt v3.3.16.1:**
```
install\autoit-v3.3.16.1-setup.exe
```
Установить с настройками по умолчанию.

**1.2 SciTE4AutoIt3 (редактор + компилятор):**
```
install\SciTE4AutoIt3.exe
```
Установить после AutoIt. SciTE — основной редактор для разработки на AutoIt.

> ⚠️ **Важно:** SciTE должен устанавливаться ПОСЛЕ AutoIt, иначе интеграция не настроится автоматически.

> 📝 **Заметка по UTF-8:** Читай `install\SciteUTF.md` если есть проблемы с кодировкой в SciTE.

**1.3 Notepad++ (опционально, для просмотра файлов):**
```
install\npp.8.9.1.Installer.x64.exe
```

---

## 2. Установка Visual C++ Runtime и .NET Framework

**2.1 Visual C++ Runtimes (все версии одним пакетом):**
```
install\Visual-C-Runtimes-All-in-One-Dec-2025\install_all.bat
```
Запустить от имени администратора. Установит все версии VC++ от 2005 до 2022.

> Если нужна только версия для XP совместимости:
> ```
> install\Visual C++ Redist 2015-2019 (XP)\VC_redist.x86.exe
> ```

**2.2 .NET Framework 4.8 (обязательно для WebView2):**
```
install\NDP48-x86-x64-AllOS-ENU.exe
```
Установить и перезагрузить компьютер если потребуется.

---

## 3. Установка и регистрация WebView2

WebView2 нужен для приложений с HTML/CSS/JS интерфейсом.

**3.1 Установить Microsoft Edge WebView2 Runtime:**
```
install\MicrosoftEdgeWebview2Setup.exe
```

**3.2 Зарегистрировать DLL в системе:**

После установки запустить скрипт регистрации от имени администратора:
```
libs\WebView2\bin\Register_dll.au3
```

> ⚠️ Запускать от имени администратора (ПКМ → Запуск от имени администратора)

**3.3 Проверка регистрации:**

Если нужно скопировать DLL в папку приложения — использовать:
```
libs\WebView2\CopyDLL.au3
```

Подробнее о DLL: `libs\WebView2\README_dll.md`

---

## 4. Проверка на базовых примерах

После установки всех зависимостей проверить работу SDK:

**4.1 Базовый старт (Utils + логирование):**
```
libs\Utils\Utils_AutoTest.au3
```
Должны пройти все тесты без ошибок.

**4.2 Пример WebView2 приложения:**
```
apps\WebView2_Test\
```
Запустить главный .au3 файл приложения.

**4.3 Пример SCADA графики:**
```
apps\ScadaGraphics\
```

**4.4 Стартовый шаблон приложения:**
```
apps\01_Start\
```
Минимальный шаблон для создания нового приложения на базе SDK.

---

## 5. Настройка MySQL

Если нужна работа с MySQL базой данных:

**5.1 Настроить подключение в AutoIt библиотеке:**
```
libs\MySQL_PHP\MySQL_Core_API.au3
```
Открыть файл и найти секцию с настройками серверов:
- `$g_MySQL_Host_Local` — адрес локального сервера (обычно `127.0.0.1`)
- `$g_MySQL_Host_Remote` — адрес удалённого хостинга
- `$g_MySQL_API_Key` — ключ доступа к PHP API

**5.2 Настроить PHP конфигурацию:**
```
php\mysql_config.php
```
Указать:
- `DB_HOST` — хост MySQL
- `DB_NAME` — имя базы данных
- `DB_USER` — пользователь
- `DB_PASS` — пароль
- `API_KEY` — ключ доступа (должен совпадать с AutoIt настройкой)

**5.3 Проверить MySQL API:**
```
libs\MySQL_PHP\MySQL_AutoTest.au3
```

---

## 6. Установка OpenServer (Redis + MySQL)

OpenServer — локальный веб-сервер для разработки.

**6.1 Скачать OpenServer 5.4.3 (рекомендуемая версия):**
- Прямая ссылка: https://asia2.ospanel.io/archive/open_server_panel_5_4_3_setup.exe
- Официальный сайт: https://ospanel.io/download/

**6.2 Настроить модули (вкладка Настройки → Модули):**

> 📸 Скрин настроек модулей: `install\openserver_modules.png`

| Модуль | Значение |
|--------|----------|
| HTTP | `Apache_2.4-PHP_7.2` ✅ Вести лог запросов |
| PHP | `PHP_7.2` |
| MySQL / MariaDB | `MySQL-5.7-Win10` ✅ Вести лог запросов |
| Redis | `Redis-7.0` |
| PostgreSQL | Не использовать |
| MongoDB | Не использовать |
| Memcached | Не использовать |
| DNS | Не использовать |

Нажать **Сохранить** и перезапустить OpenServer.

**6.3 Настроить алиасы (вкладка Настройки → Алиасы):**

> 📸 Скрин настроек алиасов: `install\openserver_aliases.png`

Добавить три алиаса (Исходный домен → Конечный домен):

| Исходный домен | Конечный домен |
|----------------|----------------|
| `*.localhost` | `localhost` |
| `127.0.0.1` | `localhost` |
| `192.168.100.6` | `localhost` |

> 💡 Третий алиас `192.168.100.6` — это IP локального модема/роутера. Замени на свой IP если отличается. Это позволяет обращаться к серверу с других устройств в локальной сети.

Нажать **Сохранить** и перезапустить OpenServer.

**6.4 Проверить Redis:**
```
libs\Redis_TCP\Redis_AutoTest.au3
```
Все тесты должны пройти успешно.

---

## 7. Развёртывание PHP API

**7.1 Скопировать папку `php\` в localhost OpenServer:**

Скопировать содержимое папки `php\` в:
```
[OpenServer]\domains\localhost\php\
```

Итоговая структура:
```
localhost\
└── php\
    ├── mysql_api.php          ← точка входа MySQL API
    ├── mysql_config.php       ← конфигурация (настроить!)
    ├── mysql_functions.php    ← функции
    ├── Redis_Preact_api.php   ← API для Preact + Redis
    ├── redis_api.php          ← базовый Redis API
    ├── redis_read.php         ← чтение из Redis
    ├── redis_write.php        ← запись в Redis
    └── ...
```

**7.2 Проверить доступность API:**
```
http://localhost/php/mysql_api.php?ping=1&key=ВАШ_КЛЮЧ
```
Должен вернуть: `{"status":"pong"}`

**7.3 Развёртывание на хостинге (опционально):**

Скопировать те же файлы на удалённый хостинг. В `mysql_config.php` настроить отдельные ключи для хостинга. В `MySQL_Core_API.au3` указать URL удалённого API в `$g_MySQL_Host_Remote`.

---

## 8. Настройка и сборка Preact проекта

Preact проект находится в `apps\NewPreact1\gui\`

**8.1 Установить Node.js:**
- Скачать с https://nodejs.org (версия 18+ LTS)

**8.2 Настроить конфигурацию:**
```
apps\NewPreact1\gui\src\config.ts
```
Указать:
- URL Redis PHP API
- URL MySQL API
- Другие параметры подключения

**8.3 Прочитать README проекта:**
```
apps\NewPreact1\gui\README.md
```
Там описаны все команды для установки зависимостей и сборки.

**8.4 Установить зависимости и собрать:**
```bash
cd apps\NewPreact1\gui
npm install
npm run build
```

**8.5 Запустить AutoIt приложение:**
```
apps\NewPreact1\NewPreact1_Main.au3
```

---

## 9. Настройка MCP сервера для Kiro IDE

MCP сервер даёт AI-ассистенту (Kiro) доступ к инструментам работы с AutoIt кодом.

**9.1 Требования:**
- Python 3.10+
- Kiro IDE

**9.2 Настроить пути в mcp.json для своего IDE:**

Каждый IDE имеет свой файл конфигурации MCP в папках:
```
.kiro\settings\mcp.json     ← Kiro IDE
.agent\mcp.json             ← Agent IDE
.cortex\mcp.json            ← Cortex IDE
.qwen\mcp.json              ← Qwen IDE
```

> ⚠️ **Важно:** В каждом файле `mcp.json` нужно заменить все пути на свои!

Открыть нужный `mcp.json` и заменить `D:/OSPanel/domains/localhost` на реальный путь к SDK на твоём компьютере:

```json
{
  "mcpServers": {
    "sdk-universal": {
      "command": "C:/ВАШ_ПУТЬ/mcp_servers/venv/Scripts/python.exe",
      "args": [
        "C:/ВАШ_ПУТЬ/mcp_servers/SDK_Universal_MCP/mcp_server.py"
      ],
      "cwd": "C:/ВАШ_ПУТЬ",
      "disabled": false,
      "autoApprove": ["SDK_Mcp_Tool"]
    }
  }
}
```

Заменить `C:/ВАШ_ПУТЬ` на реальный путь, например:
- `D:/OSPanel/domains/localhost` — если используешь OpenServer
- `C:/Projects/AutoitSDK` — если положил SDK в другое место

**9.3 Настроить пути внутри Python файлов MCP сервера:**

> ⚠️ При первом запуске MCP сервера может потребоваться проверить пути в конфигурации сервера.

Открыть файл конфигурации сервера:
```
mcp_servers\SDK_Universal_MCP\config.json
```

Проверить и при необходимости исправить пути к проекту — они должны указывать на реальное расположение SDK на диске.

**9.4 Перезапуск MCP сервера:**

Если сервер завис или не отвечает — запустить скрипт перезапуска:
```bash
python restart_mcp.py
```
Скрипт переключает `disabled: true → false` в `mcp.json` что заставляет IDE переподключиться к серверу.

**9.5 Шаблон конфигурации:**
```
mcp_servers\SDK_Universal_MCP\mcp_config_template.json
```

**9.6 Подробная инструкция по настройке IDE:**
```
mcp_servers\SDK_Universal_MCP\MCP_IDE_SETUP.md
```

> ⚠️ MCP сервер использует Python venv из папки `mcp_servers\venv\` — переустановка зависимостей не требуется, всё включено.

---

## 10. Дополнительные инструменты

**WinRAR (архиватор):**
```
install\WinRAR_7_20_key.zip
```
Распаковать и установить.

**ProcessManager (менеджер процессов AutoIt):**
```
libs\ProcessManager\ProcessManager.au3
```
Утилита для управления запущенными AutoIt процессами. Инструкция: `libs\ProcessManager\_ИНСТРУКЦИЯ_ProcessManager.md`

**Rs485 / Modbus библиотека:**
```
libs\Rs485\Rs485_Example.au3
```
Пример работы с RS485/Modbus устройствами. Конфиг: `libs\Rs485\config_Rs485_Example.json`

---

## ✅ Чеклист установки

- [ ] AutoIt v3.3.16.1 установлен
- [ ] SciTE4AutoIt3 установлен
- [ ] Visual C++ Runtimes установлены
- [ ] .NET Framework 4.8 установлен
- [ ] WebView2 Runtime установлен
- [ ] WebView2 DLL зарегистрирована (`libs\WebView2\bin\Register_dll.au3`)
- [ ] `libs\Utils\Utils_AutoTest.au3` — все тесты пройдены
- [ ] OpenServer запущен (MySQL + Redis + PHP)
- [ ] `php\` скопирована в localhost
- [ ] `libs\MySQL_PHP\MySQL_AutoTest.au3` — все тесты пройдены
- [ ] `libs\Redis_TCP\Redis_AutoTest.au3` — все тесты пройдены
- [ ] `apps\WebView2_Test\` — приложение запускается

---

**SDK готов к работе! 🎉**
