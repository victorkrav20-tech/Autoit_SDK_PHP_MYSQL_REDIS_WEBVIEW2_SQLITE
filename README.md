# AutoIt SDK v0.4 - Модульная экосистема для разработки

**Версия SDK:** v0.4  
**Дата обновления:** 23.02.2026  
**Статус:** Стабильная версия (Utils + MySQL v2.0 + Redis + WebView2 готовы и протестированы)

---

## 🗺️ БЫСТРАЯ НАВИГАЦИЯ (AI START HERE - первые 30 строк)

Это SDK для разработки масштабируемых приложений на AutoIt с использованием модульной архитектуры. Каждый модуль независим, имеет свою документацию и может переиспользоваться в разных проектах.

### 📦 Краткая сводка библиотек:
- ✅ **Utils v2.1** (Logger V2 + UUID v7 + SQLite) - базовые утилиты и логирование
- ✅ **MySQL_PHP v2.0** (CRUD + SQLite очереди + UUID v7 + SCADA) - работа с MySQL через PHP API
- ✅ **Redis_TCP v1.1** (60+ функций + Pub/Sub) - прямой TCP клиент Redis
- ✅ **WebView2 v1.4.2** (COM обёртка + события) - HTML/CSS/JS интерфейсы
- ✅ **PHP API v1.3** - серверная часть для MySQL

### 🔗 Дополнительные документы:
- **План развития:** [ROADMAP.md](ROADMAP.md) - текущие и запланированные задачи
- **Завершённые задачи:** [FINISH_SDK.md](FINISH_SDK.md) - архив выполненных этапов
- **Правила разработки:** [_ПРАВИЛА_РАЗРАБОТКИ.md](_ПРАВИЛА_РАЗРАБОТКИ.md) - стандарты кода
- **MCP серверы:** [mcp_servers/README.md](mcp_servers/README.md) - AI инструменты для Kiro IDE
---

<!-- ОСНОВНОЙ КОНТЕНТ НАЧИНАЕТСЯ ЗДЕСЬ (после строки 30) -->

## 📚 БИБЛИОТЕКИ (libs/)

Переиспользуемые модули для различных задач. Каждая библиотека имеет свой README с полной документацией API.

| Модуль | Описание | Ключевые функции | README | Зависимости |
|--------|----------|------------------|--------|--------------|
| **SDK_Init** | Единая точка инициализации всех модулей SDK | `_SDK_Init()`, `_SDK_MySQL_Init()`, `_SDK_Redis_Init()` | [libs/SDK_Init.au3](libs/SDK_Init.au3) | Utils, MySQL_PHP, Redis_TCP |
| **Utils** | Утилиты + интеллектуальное логирование (Logger V2) | `_SDK_Utils_Init()`, `_Logger_Write()`, `_Utils_GetTimestamp()` | [libs/Utils/README.md](libs/Utils/README.md) | - |
| **MySQL_PHP** | HTTP API для работы с MySQL через PHP посредник + SQLite очереди FIFO + UUID v7 | `_MySQL_Select()`, `_MySQL_InsertSCADA()`, `_MySQL_UpdateSCADA()`, `_MySQL_Update()`, `_MySQL_Delete()` | [libs/MySQL_PHP/Readme_Mysql.md](libs/MySQL_PHP/Readme.md) | Utils, Utils_SQLite, WinHttp, json |
| **Redis_TCP** | Прямой TCP клиент Redis 7.0+ (v1.1: 60+ функций, Pub/Sub, Persistence, Counters) | `_Redis_Set()`, `_Redis_Get()`, `_Redis_Publish()`, `_Redis_Subscribe()` | [libs/Redis_TCP/README.md](libs/Redis_TCP/README.md) | Utils |
| **WebView2** | COM обёртка для Microsoft Edge WebView2 (GUI, HTML/CSS/JS интерфейсы, событийная модель) | `Initialize()`, `Navigate()`, `ExecuteScript()`, `InjectCss()` | [libs/WebView2/README.md](libs/WebView2/README.md) | .NET Framework 4.8, WebView2 Runtime |
| **json** | Парсер JSON для AutoIt (сторонняя библиотека) | `Json_Encode()`, `Json_Decode()` | [libs/json/README.md](libs/json/README.md) | - |
| **WinHttp** | HTTP клиент для AutoIt (сторонняя библиотека) | `_WinHttpRequest()`, `_WinHttpSimpleRequest()` | [libs/WinHttp/README.md](libs/WinHttp/README.md) | - |

---

## 🔧 ПРАВИЛА РАСШИРЕНИЯ БИБЛИОТЕК

### Дополнительные модули:
Когда основная библиотека разрастается, создаются отдельные .au3 файлы для дополнительного функционала.

**Правила:**
- Создаются в папке библиотеки как отдельные .au3 файлы
- Префикс функций совпадает с основной библиотекой
- Подключаются опционально в приложениях
- Имеют свой AutoTest файл (опционально)

**Пример:** Utils
```
libs/Utils/
├── Utils.au3              # Основной функционал (логирование, утилиты)
├── Utils_SQLite.au3       # Расширение для работы с SQLite
├── Utils_AutoTest.au3     # Тесты основного модуля
└── README.md              # Документация всех файлов
```

**Использование:**
```autoit
#include "..\..\libs\Utils\Utils.au3"         # Основной модуль
#include "..\..\libs\Utils\Utils_SQLite.au3"  # Расширение (опционально)
```

### Динамические модули для приложений:
Переиспользуемые модули, которые подходят для множества приложений, но не являются частью основной библиотеки.

**Правила:**
- Размещаются в папке библиотеки
- Не раздувают основной код библиотеки
- Подключаются только когда нужны
- Документируются в README библиотеки

**Пример:** WebView2
```
libs/WebView2/
├── WebView2_Core.au3       # Основная COM обёртка
├── WebView2_Scraping.au3   # Модуль для парсинга веб-страниц
├── WebView2_Automation.au3 # Модуль для автоматизации действий
└── README.md               # Документация всех модулей
```

**Использование:**
```autoit
#include "..\..\libs\WebView2\WebView2_Core.au3"      # Основной
#include "..\..\libs\WebView2\WebView2_Scraping.au3"  # Только для парсинга
```

**Преимущества:**
- Основной код приложения остаётся чистым
- Легко масштабировать функционал
- Переиспользование кода между приложениями
- Модульная архитектура

---

## 🚀 ШАБЛОН ПРИЛОЖЕНИЯ

Универсальный шаблон для всех приложений SDK с поддержкой событийной модели и COM объектов.

```autoit
#AutoIt3Wrapper_UseX64=y
#include "..\..\libs\SDK_Init.au3"

; COM обработчик (ОБЯЗАТЕЛЬНО если используются COM объекты: WebView2, Excel, Word и т.д.)
Global $g_oCOMError = ObjEvent("AutoIt.Error", "_COM_ErrorHandler")
OnAutoItExitRegister("_COM_Exit")

; Инициализация SDK
_SDK_Init("MyApp", True, 1, 3, True)
; Опционально: _SDK_MySQL_Init()
; Опционально: _SDK_Redis_Init("127.0.0.1", 6379)

; Событийная модель (ОБЯЗАТЕЛЬНО для неблокирующей работы)
Opt("GUIOnEventMode", 1)

; Создание GUI (если нужен)
Global $g_hGUI = GUICreate("MyApp", 800, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

; Основной цикл (неблокирующий)
While 1
    ; Обработка модулей через таймеры
    _ProcessModules()
    Sleep(1)  ; Минимальная задержка, освобождает CPU
WEnd

; Обработчик закрытия
Func _OnExit()
    _Logger_Write("Приложение завершено", 1)
    Exit
EndFunc

; Обработчик COM ошибок (НЕ прерывает выполнение)
Func _COM_ErrorHandler()
    Local $sError = "COM Error: " & @error & " | Line: " & $g_oCOMError.scriptline
    _Logger_Write($sError, 2)
    Return  ; НЕ используем SetError() - это прервёт выполнение
EndFunc

; Очистка COM объектов при выходе
Func _COM_Exit()
    ; Освобождаем COM объекты
    $g_oCOMError = 0
EndFunc

; Обработка модулей (пример)
Func _ProcessModules()
    ; Здесь вызовы функций модулей через таймеры
    ; Пример: _Redis_PubSub_ProcessMessages()
EndFunc
```

---

## 📖 WEBVIEW2 - БЫСТРАЯ СПРАВКА

**Описание:** COM обёртка для Microsoft Edge WebView2. Позволяет создавать GUI с HTML/CSS/JS интерфейсами.

**Требования:**
- .NET Framework 4.8
- WebView2 Runtime 109.0.1518.140
- Регистрация COM: `bin/Register_web2.au3`

### Минимальный пример:
```autoit
#AutoIt3Wrapper_UseX64=y
#include <GUIConstantsEx.au3>

Global $g_oManager, $g_oEvtManager, $g_hGUI
Global $g_oCOMError = ObjEvent("AutoIt.Error", "_COM_ErrorHandler")

Opt("GUIOnEventMode", 1)

$g_hGUI = GUICreate("WebView2", 800, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

$g_oManager = ObjCreate("NetWebView2.Manager")
$g_oEvtManager = ObjEvent($g_oManager, "WebView_", "IWebViewEvents")
$g_oManager.Initialize($g_hGUI, "", 10, 10, 780, 580)

While 1
    Sleep(10)
WEnd

Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        $g_oManager.Navigate("https://example.com")
    EndIf
EndFunc

Func _OnExit()
    $g_oManager.Cleanup()
    Sleep(100)
    $g_oManager = 0
    $g_oEvtManager = 0
    Exit
EndFunc

Func _COM_ErrorHandler()
    Return
EndFunc
```

### Полный список методов COM объекта:

**Инициализация:**
- `Initialize(hGUI, sUserDataFolder, iX, iY, iWidth, iHeight)` - Инициализация WebView2
- `IsReady()` → Boolean - Проверка готовности
- `Cleanup()` - Освобождение ресурсов

**Навигация:**
- `Navigate(sUrl)` - Переход по URL
- `NavigateToString(sHtml)` - Загрузка HTML из строки
- `GoBack()` - Назад в истории
- `GoForward()` - Вперёд в истории
- `Reload()` - Перезагрузка
- `Stop()` - Остановка загрузки
- `GetSource()` → String - Текущий URL
- `GetDocumentTitle()` → String - Заголовок страницы
- `GetCanGoBack()` → Boolean - Можно ли назад
- `GetCanGoForward()` → Boolean - Можно ли вперёд

**JavaScript:**
- `ExecuteScript(sScript)` - Выполнение JS без возврата
- `ExecuteScriptWithResult(sScript)` - Выполнение JS с возвратом через событие `SCRIPT_RESULT|`
- `AddInitializationScript(sScript)` - Регистрация скрипта для каждой страницы

**CSS и стилизация:**
- `InjectCss(sCssCode)` - Внедрение CSS
- `ClearInjectedCss()` - Удаление CSS

**Получение данных (через события):**
- `GetHtmlSource()` - HTML код → событие `HTML_SOURCE|`
- `GetInnerText()` - Текст страницы → событие `INNER_TEXT|`
- `GetSelectedText()` - Выделенный текст → событие `SELECTED_TEXT|`
- `CapturePreview(sFilePath, sFormat)` - Скриншот → событие `CAPTURE_SUCCESS|`

**Cookies:**
- `GetCookies(sChannelId)` - Получение cookies → событие `COOKIES_B64|channelId|data`
- `AddCookie(sName, sValue, sDomain, sPath)` - Добавление cookie
- `DeleteCookie(sName, sDomain, sPath)` - Удаление cookie
- `DeleteAllCookies()` - Удаление всех cookies

**Настройки:**
- `SetZoom(fFactor)` - Масштаб (1.0 = 100%)
- `ResetZoom()` - Сброс масштаба
- `SetMuted(bMuted)` - Вкл/выкл звук
- `IsMuted()` → Boolean - Проверка звука
- `SetUserAgent(sUserAgent)` - User-Agent
- `Resize(iWidth, iHeight)` - Изменение размера

**Очистка данных:**
- `ClearBrowserData()` - Очистка всех данных → событие `DATA_CLEARED`
- `ClearCache()` - Очистка только кеша

**Утилиты:**
- `EncodeURI(sValue)` → String - Кодирование URL
- `DecodeURI(sValue)` → String - Декодирование URL
- `EncodeB64(sValue)` → String - Base64 кодирование
- `DecodeB64(sValue)` → String - Base64 декодирование

**Детальная документация:** [libs/WebView2/README.md](libs/WebView2/README.md) (обязательно читать при работе с WebView2)

---

## 🎯 БЫСТРЫЙ СТАРТ И ИНИЦИАЛИЗАЦИЯ SDK

SDK использует единую точку входа через файл `libs/SDK_Init.au3`, который упрощает подключение и настройку всех модулей.

### Три функции инициализации:

**1. `_SDK_Init()` - Базовая инициализация (ОБЯЗАТЕЛЬНАЯ)**

Инициализирует Utils и систему логирования. Должна вызываться первой.

```autoit
#include "..\..\libs\SDK_Init.au3"

; Полная инициализация
_SDK_Init("MyApp", True, 1, 3, True)
; Параметры:
;   "MyApp" - имя приложения
;   True - режим отладки (True/False)
;   1 - фильтр логов (1=все, 2=только ошибки, 3=только успех)
;   3 - цель логов (1=консоль, 2=файл, 3=оба)
;   True - очищать лог при запуске (True/False)

; Минимальная инициализация (с дефолтами)
_SDK_Init("MyApp")
```

**2. `_SDK_MySQL_Init()` - Инициализация MySQL (ОПЦИОНАЛЬНАЯ)**

```autoit
_SDK_MySQL_Init()
; Без параметров - использует настройки из MySQL_Core_API.au3
```

**3. `_SDK_Redis_Init()` - Инициализация Redis (ОПЦИОНАЛЬНАЯ)**

```autoit
_SDK_Redis_Init("127.0.0.1", 6379)
; Параметры:
;   "127.0.0.1" - адрес Redis сервера (по умолчанию "127.0.0.1")
;   6379 - порт Redis сервера (по умолчанию 6379)
```

### Примеры использования:

**Сценарий 1: Приложение с MySQL**
```autoit
#include "..\..\libs\SDK_Init.au3"

_SDK_Init("MyApp", True, 1, 3, True)
_SDK_MySQL_Init()

; Работа с MySQL
Local $aData = _MySQL_Select("users", "*", "status='active'")
_Logger_Write("Получено записей: " & UBound($aData), 1)

; Вставка данных (обычная)
_MySQL_Insert("users", "name=John|email=john@example.com")

; Вставка SCADA (автоматический UUID v7 + event_datetime)
_MySQL_InsertSCADA("sensors", "sensor_id=001|temp=25.5|status=online")

; Обновление SCADA (автоматический event_datetime)
_MySQL_UpdateSCADA("sensors", "temp=26.5", "sensor_id='001'")

; Подсчёт записей
Local $iCount = _MySQL_Count("users", "status='active'")
_Logger_Write("Активных пользователей: " & $iCount, 1)
```

**Сценарий 2: Приложение с Redis**
```autoit
#include "..\..\libs\SDK_Init.au3"

_SDK_Init("MyApp", True, 1, 3, True)
_SDK_Redis_Init("127.0.0.1", 6379)

; Работа с Redis
_Redis_Set("counter", "0")
Local $iCount = _Redis_Incr("counter")
_Logger_Write("Счетчик: " & $iCount, 1)

; Кеширование данных
_Redis_Set("user:1:name", "John")
_Redis_Expire("user:1:name", 60)  ; TTL 60 секунд

; Pub/Sub
_Redis_Publish("notifications", "New message!")
```

**Сценарий 3: Полное приложение (MySQL + Redis + WebView2)**
```autoit
#include "..\..\libs\SDK_Init.au3"

; COM обработчик для WebView2
Global $g_oCOMError = ObjEvent("AutoIt.Error", "_COM_ErrorHandler")
OnAutoItExitRegister("_COM_Exit")

; Инициализация всех модулей
_SDK_Init("FullApp", True, 1, 3, True)
_SDK_MySQL_Init()
_SDK_Redis_Init("127.0.0.1", 6379)

; Событийная модель
Opt("GUIOnEventMode", 1)

; Создание GUI с WebView2
Global $g_hGUI = GUICreate("Full App", 1024, 768)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)

Global $g_oManager = ObjCreate("NetWebView2.Manager")
Global $g_oEvtManager = ObjEvent($g_oManager, "WebView_", "IWebViewEvents")
$g_oManager.Initialize($g_hGUI, "", 10, 10, 1004, 748)

; Основной цикл
While 1
    Sleep(1)
WEnd

Func WebView_OnMessageReceived($sMessage)
    If StringInStr($sMessage, "INIT_READY") Then
        ; Загружаем данные из MySQL
        Local $aUsers = _MySQL_Select("users", "*", "status='active'")
        
        ; Кешируем в Redis
        _Redis_Set("users:active", Json_Encode($aUsers))
        
        ; Отображаем в WebView2
        $g_oManager.Navigate("file://" & @ScriptDir & "\index.html")
    EndIf
EndFunc

Func _OnExit()
    $g_oManager.Cleanup()
    Sleep(100)
    $g_oManager = 0
    $g_oEvtManager = 0
    Exit
EndFunc

Func _COM_ErrorHandler()
    _Logger_Write("COM Error: " & @error, 2)
    Return
EndFunc

Func _COM_Exit()
    $g_oCOMError = 0
EndFunc
```

---

## 🚀 ПРИЛОЖЕНИЯ (apps/)

Исполняемые программы, использующие библиотеки из libs/. Каждое приложение в своей папке.

См. [apps/README_APPS.md](apps/README_APPS.md) для списка всех приложений.

**Статус:** Приложения в разработке (SDK v0.3)

---

## 🌐 СЕРВЕРНАЯ ЧАСТЬ (php/)

PHP API для работы с базами данных через HTTP. Используется библиотекой MySQL_PHP.

| Файл | Описание |
|------|----------|
| **mysql_api.php** | Точка входа API (Entry Point) |
| **mysql_config.php** | Конфигурация подключений к БД |
| **mysql_functions.php** | Вспомогательные функции для работы с MySQL |
| **PRODUCTION_MODE.md** | Документация по настройке и использованию API |

📖 **Документация:** [php/PRODUCTION_MODE.md](php/PRODUCTION_MODE.md)

---

## 📁 СТРУКТУРА ПАПОК

### 📂 logs/
Централизованное хранилище логов всех приложений.

**Структура:**
```
logs/
└── AppName/
    ├── AppName_Main.log      # Основной лог приложения
    ├── AppName_MySQL.log     # Логи работы с MySQL
    └── AppName_Redis.log     # Логи работы с Redis
```

**Правила:**
- Каждое приложение создаёт свою папку в logs/
- Каждый модуль создаёт свой файл лога
- Логи управляются через Utils (Logger V2)
- Инициализация: `_SDK_Utils_Init("AppName", "ModuleName")`
- Смена модуля: `$g_sUtils_SDK_ModuleName = "NewModule"`
- Формат имени: `AppName_ModuleName.log`

### 📂 tests/
Интеграционные тесты и шаблоны кода.

**Содержимое:**
- `Test_*.au3` - интеграционные тесты всей системы
- `templates/` - шаблоны кода (при необходимости)

### 📂 shared/
Общие ресурсы для всех модулей и приложений.

**Содержимое:**
- `configs/` - конфигурационные файлы
- `docs/` - общая документация

### 📂 mcp_servers/
MCP серверы для интеграции с Kiro IDE (AI инструменты).

**Содержимое:**
- `sdk_codemapper/` - навигация по AutoIt коду (18 функций)
- `sdk_assistant/` - AI помощник для разработки
- `README.md` - документация MCP серверов

📖 **Документация:** [mcp_servers/README.md](mcp_servers/README.md)  
📖 **SDK CodeMapper:** [mcp_servers/sdk_codemapper/README.md](mcp_servers/sdk_codemapper/README.md)

---

## 📐 АРХИТЕКТУРНЫЕ ПРАВИЛА

### ✅ Что ОБЯЗАТЕЛЬНО:
- Каждый модуль имеет свой README.md с полной документацией
- Все функции библиотеки начинаются с префикса `_ModuleName_`
- Глобальные переменные имеют префикс `$g_ModuleName_`
- Каждая библиотека имеет AutoTest файл
- Логи пишутся через Utils: `_SDK_Utils_Init("AppName", "ModuleName")`
- Зависимости указаны в README модуля

### ❌ Что ЗАПРЕЩЕНО:
- Прямые зависимости между приложениями (apps → apps)
- Циклические зависимости между библиотеками
- Хардкод абсолютных путей (только относительные)
- Дублирование кода между модулями (выносить в Utils)
- Прямой ConsoleWrite (только через `_Logger_Write()` из Utils)

---

## 📊 МАТРИЦА ЗАВИСИМОСТЕЙ

```
Utils (базовый, включает Logger V2, без зависимостей)
  ↑
json, WinHttp (сторонние библиотеки, без зависимостей)
  ↑
MySQL_PHP (зависит от Utils, WinHttp, json)
Redis_TCP (зависит от Utils)
WebView2 (зависит от .NET Framework 4.8, WebView2 Runtime, работает через COM)
  ↑
Apps (используют любые библиотеки)
```

---

## 🚀 ВЕРСИОНИРОВАНИЕ

- **SDK версия:** v0.4 (стабильная версия - Utils, MySQL, Redis, WebView2 готовы)
- **Модуль версия:** Каждый модуль имеет свою версию в README
- **Совместимость:** Указывается минимальная версия зависимостей в README модуля

---

## 📝 ИСТОРИЯ ИЗМЕНЕНИЙ

### v0.4 (Текущая версия) - 23.02.2026
- ✅ MySQL_PHP v2.0: SQLite очереди FIFO (замена файловых очередей)
- ✅ MySQL_PHP v2.0: UUID v7 для точного времени событий
- ✅ MySQL_PHP v2.0: Base64 кодирование SQL запросов в очередях
- ✅ MySQL_PHP v2.0: SCADA функции `_MySQL_InsertSCADA()`, `_MySQL_UpdateSCADA()`
- ✅ MySQL_PHP v2.0: Индивидуальная SQLite база для каждого приложения
- ✅ MySQL_PHP v2.0: 22/22 автотестов пройдены успешно
- 📊 Производительность: SQLite очереди < 5мс на операцию

### v0.3 - 19.02.2026
- ✅ Добавлена библиотека WebView2 v1.4.2 (COM обёртка для Microsoft Edge WebView2)
- ✅ WebView2: поддержка HTML/CSS/JS интерфейсов, событийная модель (OnEventMode)
- ✅ WebView2: 17 автотестов, полная документация для AI-разработки
- ✅ WebView2: JavaScript выполнение, CSS инъекции, cookies, скриншоты
- ✅ Правила разработки: Протокол работы с новым чатом (автоматическое чтение 3 файлов)
- ✅ Обновлена документация: README_SDK, ROADMAP, создан FINISH_SDK
- ⚠️ Примечание: исходники WebView2 (.NET/C#) можно изменять только после согласования

### v0.2 - 17.02.2026
- ✅ Добавлена библиотека Redis_TCP v1.1 (60+ функций, Pub/Sub, Persistence, Counters)
- ✅ Создан SDK_Init.au3 - единая точка инициализации всех модулей
- ✅ Добавлены функции `_SDK_Init()`, `_SDK_MySQL_Init()`, `_SDK_Redis_Init()`
- ✅ Полностью протестирован Redis (17 автотестов, все успешны)
- ✅ Создан интеграционный тест Start_Test_All.au3 (Utils + MySQL + Redis)
- ✅ Обновлена документация с примерами использования SDK_Init
- ✅ Добавлены сценарии быстрого старта для MySQL, Redis и комбинированных приложений
- 📊 Производительность Redis: INCR 0.04мс/операция, SET/GET ~1мс, Pub/Sub ~1мс/цикл

### v0.1 - 16.02.2026
- ✅ Создана модульная структура SDK
- ✅ Добавлена библиотека Utils v2.0 (утилиты + Logger V2)
- ✅ Добавлена библиотека MySQL_PHP v1.3
- ✅ Добавлены сторонние библиотеки (json, WinHttp)
- ✅ Настроена централизованная система логирования через Utils
- ✅ Подготовлена инфраструктура для тестов (tests/)

---

## 📖 ДОПОЛНИТЕЛЬНАЯ ДОКУМЕНТАЦИЯ

- **Правила разработки:** [_ПРАВИЛА_РАЗРАБОТКИ.md](_ПРАВИЛА_РАЗРАБОТКИ.md)
- **План развития:** [ROADMAP.md](ROADMAP.md)
- **Завершённые задачи:** [FINISH_SDK.md](FINISH_SDK.md)
- **MCP серверы:** [mcp_servers/README.md](mcp_servers/README.md)
- **SDK CodeMapper:** [mcp_servers/sdk_codemapper/README.md](mcp_servers/sdk_codemapper/README.md)
- **SDK инициализация:** [libs/SDK_Init.au3](libs/SDK_Init.au3)
- **Utils (утилиты + логирование):** [libs/Utils/README.md](libs/Utils/README.md)
- **MySQL библиотека:** [libs/MySQL_PHP/README.md](libs/MySQL_PHP/README.md)
- **Redis библиотека:** [libs/Redis_TCP/README.md](libs/Redis_TCP/README.md)
- **WebView2 библиотека:** [libs/WebView2/README.md](libs/WebView2/README.md)
- **PHP API:** [php/PRODUCTION_MODE.md](php/PRODUCTION_MODE.md)
- **Приложения:** [apps/README_APPS.md](apps/README_APPS.md)

---

**Версия SDK:** 0.4  
**Дата создания:** 16.02.2026  
**Последнее обновление:** 23.02.2026  
**Статус:** Стабильная версия (Utils + MySQL v2.0 + Redis + WebView2 полностью готовы и протестированы)
