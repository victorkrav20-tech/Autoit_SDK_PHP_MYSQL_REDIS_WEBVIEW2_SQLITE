# MySQL API Library для AutoIt (SDK Module)

Модуль для работы с MySQL через HTTP API с поддержкой локального сервера (OpenServer) и хостинга. Интегрирован в SDK систему для использования в множестве приложений.

## 🚀 Текущая версия: v2.0-stable (SQLite + UUID v7)

### ✅ Реализованные функции:
- ✅ Модульная архитектура (один файл разбит на 4 части для удобства)
- ✅ HTTP запросы через WinHTTP с POST методом и таймаутом 0.5 секунды
- ✅ Полный CRUD набор wrapper-функций (Create, Read, Update, Delete)
- ✅ **SCADA функции:** `_MySQL_InsertSCADA`, `_MySQL_UpdateSCADA` с автоматическим UUID v7
- ✅ UUID v7 (time-based) для точного времени событий
- ✅ Утилитарные функции (_MySQL_Count, _MySQL_Exists, _MySQL_GetLastInsertID)
- ✅ Безопасность API (проверка ключей доступа, обязательное WHERE для UPDATE/DELETE)
- ✅ SELECT запросы (простой и JSON формат)
- ✅ UPDATE/DELETE операции с проверкой безопасности
- ✅ INSERT операции с парсингом строковых данных
- ✅ **Система автоматических очередей FIFO на SQLite** (транзакции, защита от дубликатов)
- ✅ **UUID v7 в очередях** для точного времени события
- ✅ **Base64 кодирование** SQL запросов в очередях (поддержка всех символов)
- ✅ Индивидуальные очереди для каждого приложения
- ✅ Один файл базы на приложение: `AppName_queue.db` (SQLite)
- ✅ Обработка ошибок и детальное логирование производительности
- ✅ Автоматическое тестирование (22 теста)
- ✅ Логирование через Logger V2 (интеграция SDK)
- ✅ Чистая проверка Au3Check (0 ошибок, 0 предупреждений)

---

## 📁 Структура модуля (SDK) - Модульная архитектура

Библиотека разделена на несколько файлов для удобства разработки и поддержки:

```
📁 libs/MySQL_PHP/
├── 📄 Readme_Mysql.md              # Документация модуля (этот файл)
│
├── 📄 MySQL_Core_API.au3           # 🎯 ГЛАВНЫЙ ФАЙЛ (подключать только его!)
│   ├── Глобальные переменные и константы
│   ├── Wrapper-функции (Select, Insert, Update, Delete)
│   ├── SCADA функции (_MySQL_InsertSCADA, _MySQL_UpdateSCADA)
│   ├── Утилитарные функции (_MySQL_Count, _MySQL_Exists, _MySQL_GetLastInsertID)
│   ├── Основная функция _MySQL_Query()
│   └── Функции очередей (InitQueue, AddToQueue, ProcessQueue)
│
└── 📄 MySQL_AutoTest.au3           # ✅ Автоматические тесты (22 теста)

📁 @ScriptDir/MySQL_PHP_queue/      # Папка очередей (создаётся автоматически)
└── 📄 AppName_queue.db             # SQLite база очередей для приложения
```

### 💡 Важно понимать:

**Как использовать:**
```autoit
; ✅ ПРАВИЛЬНО - подключаем только главный файл
#include "..\..\libs\MySQL_PHP\MySQL_Core_API.au3"
```

**Очереди SQLite (рядом с приложением):**
- `@ScriptDir\MySQL_PHP_queue\AppName_queue.db` - SQLite база с таблицами `queue` и `errors`
- Таблица `queue`: id, uuid (v7), server, sql_query (Base64), params (Base64), retry_count, created_at, status
- Таблица `errors`: id, uuid, server, sql_query (Base64), error_message, retry_count, created_at

### 🔗 Зависимости:
- **Utils** - логирование через Logger V2, UUID v7, SQLite, вспомогательные функции
- **WinHttp** - HTTP клиент для AutoIt (libs/WinHttp/)
- **json** - парсер JSON для AutoIt (libs/json/)

---

## 🔧 Основные функции

### CRUD Wrapper-функции:

#### _MySQL_Select
```autoit
_MySQL_Select($sTable, $sColumns = "*", $sWhere = "", $sOrderBy = "", $iLimit = 0, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **Возврат:** массив данных или False при ошибке
- **Пример:** `_MySQL_Select("users", "id,name", "status='active'", "name ASC", 10)`

#### _MySQL_Insert
```autoit
_MySQL_Insert($sTable, $sData, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **$sData:** данные в формате "key1=val1|key2=val2"
- **Возврат:** True при успехе, False при ошибке
- **Пример:** `_MySQL_Insert("users", "name=John|email=john@test.com|status=active")`

#### _MySQL_Update
```autoit
_MySQL_Update($sTable, $sData, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **$sWhere:** условие WHERE (обязательный для безопасности)
- **Возврат:** True при успехе, False при ошибке
- **Пример:** `_MySQL_Update("users", "status=inactive|score=100", "name = 'John'")`

#### _MySQL_Delete
```autoit
_MySQL_Delete($sTable, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **$sWhere:** условие WHERE (обязательный для безопасности)
- **Возврат:** True при успехе, False при ошибке
- **Пример:** `_MySQL_Delete("users", "status='inactive' AND last_login < '2025-01-01'")`

---

### SCADA функции (v2.0):

#### _MySQL_InsertSCADA
```autoit
_MySQL_InsertSCADA($sTable, $sData, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **$sData:** данные БЕЗ uuid/event_date/event_datetime
- **Возврат:** True при успехе, False при ошибке
- **Пример:** `_MySQL_InsertSCADA("sensors", "sensor_id=001|temp=25.5|status=online")`
- **Автоматически добавляет:**
  - `uuid` - UUID v7 (time-based, сортируемый)
  - `event_date` - текущая дата (YYYY-MM-DD)
  - `event_datetime` - точное время с миллисекундами (YYYY-MM-DD HH:MM:SS.mmm)

#### _MySQL_UpdateSCADA
```autoit
_MySQL_UpdateSCADA($sTable, $sData, $sWhere, $iServer = $MYSQL_SERVER_LOCAL, $bJSON = False)
```
- **$sData:** данные БЕЗ event_datetime
- **$sWhere:** условие WHERE (обязательный)
- **Возврат:** True при успехе, False при ошибке
- **Пример:** `_MySQL_UpdateSCADA("sensors", "temp=26.5|status=online", "sensor_id='001'")`
- **Автоматически добавляет:**
  - `event_datetime` - точное время обновления с миллисекундами

**Требует таблицу со структурой:**
```sql
CREATE TABLE sensors (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL,
    event_date DATE NOT NULL,
    event_datetime DATETIME(3) NOT NULL,
    sensor_id VARCHAR(50) NOT NULL,
    temperature DOUBLE(15,4),
    status VARCHAR(20),
    UNIQUE KEY idx_date_uuid (event_date, uuid),
    INDEX idx_date (event_date),
    INDEX idx_sensor (sensor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

### Утилитарные функции:

#### _MySQL_Count
```autoit
_MySQL_Count($sTable, $sWhere = "", $iServer = $MYSQL_SERVER_LOCAL)
```
- **Возврат:** количество записей (Int) или -1 при ошибке
- **Пример:** `_MySQL_Count("sensors", "status='online'")`

#### _MySQL_Exists
```autoit
_MySQL_Exists($sTable, $sWhere, $iServer = $MYSQL_SERVER_LOCAL)
```
- **Возврат:** True если запись существует, False если нет
- **Пример:** `_MySQL_Exists("users", "email='test@test.com'")`

#### _MySQL_GetLastInsertID
```autoit
_MySQL_GetLastInsertID($iServer = $MYSQL_SERVER_LOCAL)
```
- **Возврат:** ID последней вставки (Int) или -1 при ошибке
- **Примечание:** Работает только сразу после INSERT в той же сессии

---

### Функции очередей (v2.0 - SQLite):

#### _MySQL_InitQueue
```autoit
_MySQL_InitQueue()
```
- Инициализирует SQLite базу очередей
- Создаёт таблицы `queue` и `errors` с UUID v7
- Вызывается автоматически при подключении библиотеки

#### _MySQL_GetQueueStatus
```autoit
_MySQL_GetQueueStatus()
```
- **Возврат:** массив [LocalCount, RemoteCount]
- **Пример:** `Local $aStatus = _MySQL_GetQueueStatus()`

#### _MySQL_ClearQueues
```autoit
_MySQL_ClearQueues()
```
- Очищает все очереди (локальную и удалённую)

---

## 🎯 Примеры использования

### Подключение модуля:
```autoit
#include "..\..\libs\Utils\Utils.au3"
#include "..\..\libs\MySQL_PHP\MySQL_Core_API.au3"

; Инициализация логирования для MySQL модуля
_SDK_Utils_Init("MyApp", "MySQL")
_Logger_Write("MySQL модуль инициализирован", 1)
```

### CRUD операции:
```autoit
; CREATE (Вставка)
_MySQL_Insert("users", "name=John|email=john@example.com|status=active")

; READ (Чтение)
Local $aUsers = _MySQL_Select("users", "*", "status='active'", "name ASC", 10)

; UPDATE (Обновление)
_MySQL_Update("users", "status=inactive", "email = 'john@example.com'")

; DELETE (Удаление)
_MySQL_Delete("users", "status='inactive' AND last_login < '2025-01-01'")
```

### SCADA системы:
```autoit
; Вставка с автоматическим UUID v7
_MySQL_InsertSCADA("sensors", "sensor_id=TEMP_001|temperature=25.5|humidity=60.2|status=online")

; Обновление с автоматическим временем
_MySQL_UpdateSCADA("sensors", "temperature=26.5|status=online", "sensor_id='TEMP_001'")

; Извлечение времени из UUID
Local $sUUID = "019c8bc8-06bf-74cd-aa29-4ac342ad35ff"
Local $sEventTime = _Utils_ParseUUIDv7Timestamp($sUUID)
_Logger_Write("Событие произошло: " & $sEventTime, 1)
; Результат: "2026-02-23 18:34:27.941"
```

### Утилитарные функции:
```autoit
; Подсчет записей
Local $iTotal = _MySQL_Count("sensors")
Local $iOnline = _MySQL_Count("sensors", "status='online'")

; Проверка существования
If _MySQL_Exists("users", "email='test@test.com'") Then
    _Logger_Write("Email уже зарегистрирован", 2)
EndIf

; Получение LastInsertID
_MySQL_Insert("users", "name=John|email=john@test.com")
Local $iUserID = _MySQL_GetLastInsertID()
```

---

## 📝 Логирование (Logger V2)

### Инициализация:
```autoit
_SDK_Utils_Init("MyApp", "MySQL")
; Логи автоматически пишутся в: logs/MyApp/MyApp_MySQL.log
```

### Управление логированием:
```autoit
; Включить/выключить логи MySQL модуля
$g_bMySQL_DebugMode = True   ; Включить логи
$g_bMySQL_DebugMode = False  ; Выключить логи
```

---

## 🔄 Система очередей SQLite (v2.0)

### Как работает:
1. При недоступности сервера запросы добавляются в SQLite очередь с UUID v7
2. SQL запросы кодируются в Base64 для безопасного хранения
3. При восстановлении связи очередь обрабатывается автоматически (агрессивная обработка)
4. SELECT запросы НЕ добавляются в очередь (нужны немедленно)

### Преимущества SQLite очередей:
- ✅ Транзакции (атомарность операций)
- ✅ UUID v7 для точного времени события
- ✅ UNIQUE constraint на UUID (защита от дубликатов)
- ✅ Base64 кодирование (поддержка всех символов в SQL)
- ✅ Индексы для быстрого поиска
- ✅ Таблица errors для логирования проблемных запросов

### Структура SQLite базы:
```sql
-- Таблица очередей
CREATE TABLE queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT UNIQUE NOT NULL,
    server TEXT NOT NULL,
    sql_query TEXT NOT NULL,
    params TEXT,
    is_json INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    last_attempt TEXT,
    status TEXT DEFAULT 'pending'
);

-- Таблица ошибок
CREATE TABLE errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid TEXT,
    server TEXT NOT NULL,
    sql_query TEXT NOT NULL,
    error_message TEXT NOT NULL,
    retry_count INTEGER,
    created_at TEXT NOT NULL
);
```

---

## 🔧 Настройка и установка

### Требования:
- **AutoIt:** 3.3.16.1+
- **SDK:** AutoIt SDK v0.1+ (модульная система)
- **Веб-сервер:** OpenServer 5.4.3+ (для локального тестирования)
- **PHP:** 7.0+ с поддержкой MySQLi
- **База данных:** MySQL/MariaDB

### Настройка PHP API:
1. **База данных:** Создайте БД `test_mysql_api`
2. **Конфигурация:** Настройте `php/mysql_config.php` (в корне SDK)
3. **Тестирование:** Запустите `libs/MySQL_PHP/MySQL_AutoTest.au3`

---

## 📊 Результаты тестирования

### Последний запуск тестов:
- ✅ **22 из 22 тестов пройдены** 🎉
- ✅ Базовые операции: 3/3 тестов
- ✅ CRUD операции: 6/6 тестов
- ✅ JSON формат: 2/2 тестов
- ✅ Безопасность: 4/4 тестов
- ✅ Wrapper-функции: 3/3 тестов
- ✅ SCADA функции: 1/1 тест (UUID v7)
- ✅ Утилитарные функции: 3/3 теста

### Производительность:
- **Базовые запросы:** 10-35мс (отличная скорость)
- **Wrapper-функции:** 15-40мс в реальном использовании
- **Таймаут WinHTTP:** 500мс (0.5 секунды)
- **Очереди SQLite:** < 5мс на операцию

---

## 🎯 Преимущества UUID v7 для SCADA

- ✅ **Точное время события:** timestamp в UUID = время на датчике, не время вставки в БД
- ✅ **Сортировка:** UUID v7 естественно сортируются по времени создания
- ✅ **Партиционирование:** составной индекс `(event_date, uuid)` для максимальной производительности
- ✅ **Защита от дубликатов:** UNIQUE индекс исключает повторную вставку при обрывах связи
- ✅ **Восстановление времени:** можно извлечь timestamp из UUID через `_Utils_ParseUUIDv7Timestamp()`

---

## 📚 Дополнительная документация

- **SDK Главная:** [README_SDK.md](../../README_SDK.md)
- **Правила разработки:** [_ПРАВИЛА_РАЗРАБОТКИ.md](../../_ПРАВИЛА_РАЗРАБОТКИ.md)
- **Utils (логирование, UUID v7, SQLite):** [libs/Utils/README.md](../Utils/README.md)

---

**Версия модуля:** 2.0-stable (SQLite + UUID v7)  
**Дата обновления:** 23.02.2026  
**Статус:** Стабильная версия с SQLite очередями и UUID v7 (0 ошибок, 0 предупреждений Au3Check)
