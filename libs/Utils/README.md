# Utils Library v2.1

## 📋 КРАТКОЕ ОПИСАНИЕ
Универсальная библиотека утилит для SDK: логирование, работа с данными, UUID v7, SQLite.

## 🔗 ЗАВИСИМОСТИ
Нет зависимостей - базовая библиотека SDK.

## 📦 ФАЙЛЫ МОДУЛЯ
- `Utils.au3` - основная библиотека (включает Utils_SQLite)
- `Utils_SQLite.au3` - работа с SQLite (Config, Logs, Tables)
- `Utils_AutoTest.au3` - автоматические тесты (35 тестов)
- `udf/` - родная SQLite библиотека v3.28.0 (100% совместимость)
- `README.md` - документация

---

## 🚀 БЫСТРЫЙ СТАРТ

```autoit
#include "..\..\libs\Utils\Utils.au3"

; Инициализация
_SDK_Utils_Init("MyApp", "Main")

; Логирование
_Logger_Write("Приложение запущено", 1)
_Logger_Write("Ошибка подключения", 2)
_Logger_Write("Операция успешна", 3)
```

---

## 🎯 ОСНОВНЫЕ ФУНКЦИИ

### 📌 ИНИЦИАЛИЗАЦИЯ SDK

#### `_SDK_Utils_Init($sAppName, $sModuleName, $bDebugMode, $iLogFilter, $iLogTarget, $bClearLog)`
Инициализация SDK - настройка логирования и создание папок.

**Параметры:**
- `$sAppName` - имя приложения (по умолчанию "DefaultApp")
- `$sModuleName` - имя модуля (по умолчанию "Main")
- `$bDebugMode` - режим отладки: True/False (по умолчанию True)
- `$iLogFilter` - фильтр: 1=все, 2=только ошибки, 3=только успех (по умолчанию 1)
- `$iLogTarget` - куда: 1=консоль, 2=файл, 3=оба (по умолчанию 3)
- `$bClearLog` - очищать лог при запуске: True/False (по умолчанию True)

---

### 📝 ЛОГИРОВАНИЕ V2

#### `_Logger_Write($sText, $iLogType, $iTarget)`
Универсальная функция логирования с фильтрацией.

**Параметры:**
- `$sText` - текст для логирования
- `$iLogType` - тип: 1=INFO, 2=ERROR, 3=SUCCESS
- `$iTarget` - куда: 1=консоль, 2=файл, 3=оба

**Примеры:**
```autoit
_Logger_Write("Информация", 1)
_Logger_Write("Ошибка", 2)
_Logger_Write("Успех", 3)
```

---

### 🆔 UUID V7 (для SCADA систем)

#### `_Utils_GenerateUUIDv7()`
Генерация UUID v7 (time-based, RFC 9562).

**Возврат:** Строка UUID

**Пример:**
```autoit
Local $sUUID = _Utils_GenerateUUIDv7()
; Результат: "018d5e8a-1234-7abc-9def-123456789abc"
```

**Преимущества:**
- ✅ Естественная сортировка по времени
- ✅ Оптимальная вставка в индексы MySQL
- ✅ Уникальность (2^74 вариантов на миллисекунду)

---

#### `_Utils_GetDateOnly()` / `_Utils_GetDateTimeMS()`
Получение даты и времени для MySQL.

**Примеры:**
```autoit
Local $sDate = _Utils_GetDateOnly()        ; "2026-02-17"
Local $sDateTime = _Utils_GetDateTimeMS()  ; "2026-02-17 14:35:22.456"
```

---

#### `_Utils_ParseUUIDv7Timestamp($sUUID)`
Извлечение timestamp из UUID v7.

**Пример:**
```autoit
Local $sTime = _Utils_ParseUUIDv7Timestamp($sUUID)
; Результат: "2026-02-17 20:10:25.423"
```

---

### 💾 SQLITE (Utils_SQLite.au3)

**Автоматически подключается через Utils.au3**

#### БАЗОВЫЕ ФУНКЦИИ:
```autoit
; Инициализация
_Utils_SQLite_Startup()
_Utils_SQLite_Shutdown()

; Работа с БД
$hDB = _Utils_SQLite_Open($sDBPath)
_Utils_SQLite_Close($hDB)
_Utils_SQLite_Exec($hDB, $sSQL)
$aResult = _Utils_SQLite_Query($hDB, $sSQL)
```

#### РАБОТА С ТАБЛИЦАМИ:
```autoit
; Создание и проверка
_Utils_SQLite_CreateTable($hDB, $sTable, $sSchema)
_Utils_SQLite_TableExists($hDB, $sTable)

; Загрузка и сохранение
$aData = _Utils_SQLite_LoadTable($hDB, $sTable, $sWhere)
_Utils_SQLite_SaveTable($hDB, $sTable, $aData)

; Добавление и удаление
_Utils_SQLite_AppendRow($hDB, $sTable, $aRow)
_Utils_SQLite_DeleteRow($hDB, $sTable, $iID)
_Utils_SQLite_ClearTable($hDB, $sTable)

; Утилиты
$iCount = _Utils_SQLite_Count($hDB, $sTable, $sWhere)
$iLastID = _Utils_SQLite_GetLastID($hDB)
```

#### CONFIG (INI ЗАМЕНА):
```autoit
; Установка и чтение
_Utils_SQLite_SetConfig($hDB, $sSection, $sKey, $sValue)
$sValue = _Utils_SQLite_GetConfig($hDB, $sSection, $sKey, $sDefault)

; Удаление и секции
_Utils_SQLite_DeleteConfig($hDB, $sSection, $sKey)
$aSection = _Utils_SQLite_GetSection($hDB, $sSection)
```

**Пример:**
```autoit
$hDB = _Utils_SQLite_Open("config.db")

; Установка настроек
_Utils_SQLite_SetConfig($hDB, "Database", "Host", "localhost")
_Utils_SQLite_SetConfig($hDB, "Database", "Port", "3306")

; Чтение настроек
Local $sHost = _Utils_SQLite_GetConfig($hDB, "Database", "Host", "")
Local $sPort = _Utils_SQLite_GetConfig($hDB, "Database", "Port", "3306")

; Чтение всей секции
Local $aDB = _Utils_SQLite_GetSection($hDB, "Database")

_Utils_SQLite_Close($hDB)
```

#### LOGS (ЛОГИРОВАНИЕ В БД):
```autoit
; Добавление логов
_Utils_SQLite_AddLog($hDB, $sLevel, $sMessage, $sModule)

; Чтение логов
$aLogs = _Utils_SQLite_GetLogs($hDB, $sLevel, $sModule, $iLimit)

; Очистка и подсчет
_Utils_SQLite_ClearOldLogs($hDB, $iDaysOld)
$iCount = _Utils_SQLite_CountLogs($hDB, $sLevel, $sModule)
```

**Пример:**
```autoit
$hDB = _Utils_SQLite_Open("logs.db")

; Добавление логов
_Utils_SQLite_AddLog($hDB, "INFO", "Приложение запущено", "Main")
_Utils_SQLite_AddLog($hDB, "ERROR", "Ошибка подключения", "MySQL")
_Utils_SQLite_AddLog($hDB, "SUCCESS", "Данные сохранены", "MySQL")

; Чтение только ошибок
Local $aErrors = _Utils_SQLite_GetLogs($hDB, "ERROR", "", 100)

; Подсчет логов MySQL
Local $iMySQL = _Utils_SQLite_CountLogs($hDB, "", "MySQL")

; Очистка логов старше 7 дней
_Utils_SQLite_ClearOldLogs($hDB, 7)

_Utils_SQLite_Close($hDB)
```

**Преимущества SQLite:**
- ✅ Атомарность операций (транзакции)
- ✅ Быстрый поиск (индексы, WHERE)
- ✅ Надежность при перезагрузках
- ✅ Замена INI файлов (Config)
- ✅ Замена текстовых логов (Logs)
- ✅ Работа с 2D массивами

**Технические детали:**
- Версия SQLite: 3.28.0 (фиксированная, 100% совместимость)
- Расположение: `libs/Utils/udf/` (родная библиотека + DLL)
- Автоматическое определение архитектуры (x86/x64)
- Тесты: 35 автотестов в `Utils_AutoTest.au3`

---

### ⏱️ РАБОТА СО ВРЕМЕНЕМ

```autoit
; Таймер
$hTimer = _Utils_GetTimestamp()
$fElapsed = _Utils_GetElapsedTime($hTimer)

; Unix timestamp
$iTimestamp = _Utils_GetUnixTimestampMS()
```

---

### 📊 РАБОТА С МАССИВАМИ

```autoit
; Преобразование
$sString = _Utils_ArrayToString($aArray, "|")
$aArray = _Utils_StringToArray($sString, "|")
```

---

### 🔧 РАБОТА С UTF-8

```autoit
; Консоль
_Logger_ConsoleWriteUTF("Привет, мир!")

; Преобразование
$bData = _Utils_StringToUTF8($sText)
$sText = _Utils_UTF8ToString($bData)
```

---

## 🎨 ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ

```autoit
; Настройки логирования
$g_sUtils_SDK_AppName = "DefaultApp"
$g_sUtils_SDK_ModuleName = "Main"
$g_bUtils_SDK_DebugMode = True
$g_iUtils_SDK_LogFilter = 1  ; 1=все, 2=ошибки, 3=успех
$g_iUtils_SDK_LogTarget = 3  ; 1=консоль, 2=файл, 3=оба
```

---

## 💡 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ

### Смена модуля на лету:
```autoit
_SDK_Utils_Init("MyApp", "Main")
_Logger_Write("Основной модуль", 1)

$g_sUtils_SDK_ModuleName = "MySQL"
_Logger_Write("Модуль MySQL", 1)

; Результат:
; logs/MyApp/MyApp_Main.log
; logs/MyApp/MyApp_MySQL.log
```

### UUID v7 для SCADA:
```autoit
Local $sUUID = _Utils_GenerateUUIDv7()
Local $sDate = _Utils_GetDateOnly()
Local $sDateTime = _Utils_GetDateTimeMS()

_MySQL_Insert("sensors", _
    "uuid=" & $sUUID & _
    "|event_date=" & $sDate & _
    "|event_datetime=" & $sDateTime & _
    "|temp=25.5")
```

### SQLite Config:
```autoit
$hDB = _Utils_SQLite_Open("app.db")

_Utils_SQLite_SetConfig($hDB, "App", "Version", "1.0.0")
_Utils_SQLite_SetConfig($hDB, "App", "Name", "SCADA System")

Local $sVersion = _Utils_SQLite_GetConfig($hDB, "App", "Version", "")

_Utils_SQLite_Close($hDB)
```

---

## 📁 СТРУКТУРА ЛОГОВ

```
logs/
└── AppName/
    ├── AppName_Main.log
    ├── AppName_MySQL.log
    └── AppName_Redis.log
```

---

## 📊 ПРОИЗВОДИТЕЛЬНОСТЬ

- **Инициализация:** ~1-2мс
- **Запись лога:** ~0.5-1мс
- **UUID v7 генерация:** ~0.03мс (33000+ UUID/сек)
- **SQLite операции:** ~0.5-2мс (зависит от операции)

---

## 🧪 АВТОТЕСТЫ

**Файл:** `Utils_AutoTest.au3`

**Тесты:**
- 1-14: Логирование, массивы, время
- 15-20: UUID v7 функции
- 21-33: SQLite базовые функции
- 34: SQLite Config (INI замена)
- 35: SQLite Logs (логирование в БД)

**Запуск:**
```
autoit3.exe Utils_AutoTest.au3
```

**Результат:**
- Все тесты пройдены успешно
- БД `test_config_logs.db` сохраняется для проверки
- Логи в `logs/Utils_AutoTest/`

---

## 🎯 СТАНДАРТ ТАБЛИЦ ДЛЯ SCADA (MySQL v2.0)

```sql
CREATE TABLE sensor_data (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL,
    event_date DATE NOT NULL,
    event_datetime DATETIME(3) NOT NULL,
    sensor_id VARCHAR(50) NOT NULL,
    temperature DOUBLE(15,4),
    UNIQUE KEY idx_date_uuid (event_date, uuid),
    INDEX idx_date (event_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

**Версия:** 2.1 (добавлены SQLite функции)  
**Дата обновления:** 18.02.2026  
**Статус:** Стабильная версия
