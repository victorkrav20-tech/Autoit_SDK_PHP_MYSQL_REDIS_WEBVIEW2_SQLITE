# RS-485 / Modbus RTU — Библиотека SDK

**Версия плана:** v1.0  
**Дата:** 28.03.2026  
**Статус:** 📋 Планирование завершено, начинаем реализацию

---

## 🎯 ЦЕЛЬ

Создать универсальный SDK-модуль для работы с RS-485 / Modbus RTU, который:
- Содержит все низкоуровневые функции в одном файле библиотеки
- Рядом лежит автотест (без GUI, без Redis) — для проверки библиотеки и порта
- Рядом лежит Example-приложение — полноценный модуль с GUI, config, Redis, трей
- Example копируется в любую папку проекта, меняются только настройки через GUI
- Один запущенный файл = один COM-порт, своя конфигурация, своя статистика

---

## 📁 СТРУКТУРА ПАПКИ

```
libs/Rs485/
├── Rs485.au3                  ; Ядро: низкоуровневые функции (порт, CRC, отправка, приём, парсинг)
├── Rs485_AutoTest.au3         ; Автотест: последовательные тесты всех функций, без GUI, без Redis
├── Rs485_Example.au3          ; Example-приложение: GUI + config + Redis + трей + цикл опроса
├── config_example.ini         ; Шаблон конфига для Example (копируется вместе с Example)
├── Arduino/
│   └── SDK_Device/
│       └── SDK_Device.ino     ; Arduino Mega 2560 Slave — тестовый набор всех типов данных
└── README_PLAN.md             ; Этот файл
```

---

## 📦 ЭТАП 0 — Arduino Slave (SDK_Device.ino)

**Цель:** Прошить Arduino Mega 2560 тестовым набором регистров всех типов для автотеста библиотеки.

**Параметры подключения:**
- Плата: Arduino Mega 2560
- Serial порт: Serial1 (пины TX1/RX1)
- DE/RE пин: 13
- Baudrate: 19200
- Slave ID: 1
- COM порт на ПК: COM7

**Набор регистров modbus_array[20] — для ЧТЕНИЯ (регистры 0–9):**

| Индекс | Имя ключа | Тип | Тестовое значение | Описание |
|--------|-----------|-----|-------------------|----------|
| 0 | temp_int16 | INT16 | -150 (0xFF6A) | Температура со знаком ×10 = -15.0°C |
| 1 | status_uint16 | UINT16 | 0x00A5 | Битовые флаги статуса |
| 2 | counter_uint16 | UINT16 | 1000 | Счётчик циклов |
| 3 | pressure_f32_hi | FLOAT32 hi | 0x4048 | Float 3.14159, раскладка ABCD, старший word |
| 4 | pressure_f32_lo | FLOAT32 lo | 0xF5C3 | Float 3.14159, раскладка ABCD, младший word |
| 5 | weight_f32_hi | FLOAT32 hi | 0x4461 | Float 897.5, раскладка CDAB, старший word |
| 6 | weight_f32_lo | FLOAT32 lo | 0xC000 | Float 897.5, раскладка CDAB, младший word |
| 7 | long_int32_hi | INT32 hi | 0x0001 | INT32 = 100000, старший word |
| 8 | long_int32_lo | INT32 lo | 0x86A0 | INT32 = 100000, младший word |
| 9 | uint32_hi | UINT32 hi | 0x000F | UINT32 = 1000000, старший word |

**Регистры 10–19 — для ЗАПИСИ (master пишет, arduino применяет):**

| Индекс | Имя ключа | Тип | Описание |
|--------|-----------|-----|----------|
| 10 | uint32_lo | UINT32 lo | UINT32 = 1000000, младший word |
| 11 | rw_int16 | INT16 | Регистр записи INT16 (master пишет, arduino отражает в [0]) |
| 12 | rw_uint16 | UINT16 | Регистр записи UINT16 |
| 13 | rw_f32_hi | FLOAT32 hi | Регистр записи Float ABCD старший |
| 14 | rw_f32_lo | FLOAT32 lo | Регистр записи Float ABCD младший |
| 15 | rw_f32_cdab_hi | FLOAT32 hi | Регистр записи Float CDAB старший |
| 16 | rw_f32_cdab_lo | FLOAT32 lo | Регистр записи Float CDAB младший |
| 17 | rw_int32_hi | INT32 hi | Регистр записи INT32 старший |
| 18 | rw_int32_lo | INT32 lo | Регистр записи INT32 младший |
| 19 | rw_uint32_hi | UINT32 hi | Регистр записи UINT32 старший (lo в [10] переиспользуем) |

Arduino при записи в регистры 11–19 применяет значения и отражает их обратно в регистры 0–9 для подтверждения записи.

**После создания:** скопировать в `C:\Users\Administrator\Documents\Arduino\SDK_Device\` и прошить.

---

## 📦 ЭТАП 1 — Rs485.au3 (ядро библиотеки)

**Файл:** `libs/Rs485/Rs485.au3`  
**Префикс функций:** `_Rs485_`

### Инициализация и порт
- `_Rs485_Init($iPort, $iSpeed, $iMode)` — открытие порта, выбор x32/x64 CommMG, timeBeginPeriod(1)
- `_Rs485_Close()` — закрытие порта, timeEndPeriod(1), освобождение DLL
- `_Rs485_IsOpen()` — проверка открытости порта

### Таймер высокого разрешения
- Использует `DllCall("winmm.dll", "uint", "timeBeginPeriod", "uint", 1)` при Init
- `_Rs485_Sleep($iMs)` — Sleep с высоким разрешением (без ntdll.dll, без _HighPrecisionSleep)
- `_Rs485_Timer_Cleanup()` — восстановление timeEndPeriod при закрытии

### CRC
- `_Rs485_CRC16($sHexString)` — Modbus RTU CRC16, возвращает 2 байта в правильном порядке

### Формирование запросов
- `_Rs485_BuildRequest($iSlaveID, $iFuncCode, $iRegStart, $iRegCount)` — строит hex-строку запроса с CRC
- `_Rs485_BuildWriteSingle($iSlaveID, $iReg, $iValue)` — FC06 запись одного регистра
- `_Rs485_BuildWriteMultiple($iSlaveID, $iRegStart, $aValues)` — FC16 запись нескольких регистров

### Отправка и приём
- `_Rs485_Send($sHexLine)` — отправка байтовой строки в порт
- `_Rs485_Read($iExpectedBytes, $iTimeoutMs)` — чтение с таймаутом, возвращает массив байт
- `_Rs485_SendAndRead($sHexLine, $iExpectedBytes, $iTimeoutMs)` — отправка + чтение + проверка CRC

### Типы данных — парсинг (из массива байт)
Все функции принимают массив байт и смещение:
- `_Rs485_Parse_INT16($aBytes, $iOffset, $sByteOrder)` — 2 байта → INT16 со знаком
- `_Rs485_Parse_UINT16($aBytes, $iOffset, $sByteOrder)` — 2 байта → UINT16
- `_Rs485_Parse_INT32($aBytes, $iOffset, $sByteOrder)` — 4 байта → INT32
- `_Rs485_Parse_UINT32($aBytes, $iOffset, $sByteOrder)` — 4 байта → UINT32
- `_Rs485_Parse_FLOAT32($aBytes, $iOffset, $sByteOrder)` — 4 байта → Float IEEE 754
- `_Rs485_Parse_BOOL($aBytes, $iOffset, $iBit)` — бит из регистра

### Типы данных — упаковка (для записи)
- `_Rs485_Pack_INT16($iValue, $sByteOrder)` — INT16 → 2 hex байта
- `_Rs485_Pack_UINT16($iValue, $sByteOrder)` — UINT16 → 2 hex байта
- `_Rs485_Pack_INT32($iValue, $sByteOrder)` — INT32 → 4 hex байта
- `_Rs485_Pack_UINT32($iValue, $sByteOrder)` — UINT32 → 4 hex байта
- `_Rs485_Pack_FLOAT32($fValue, $sByteOrder)` — Float → 4 hex байта

### Раскладки байт (константы)
```
$RS485_ORDER_ABCD = "ABCD"   ; Big Endian (стандарт Modbus)
$RS485_ORDER_DCBA = "DCBA"   ; Little Endian
$RS485_ORDER_CDAB = "CDAB"   ; Mid-Big (часто у ПЛК)
$RS485_ORDER_BADC = "BADC"   ; Mid-Little
```

### Карта переменных и JSON-результат
Каждый запрос имеет свою карту — массив описаний переменных:
```
; Структура строки карты [6 колонок]:
; [0] sKey        — имя ключа в JSON (например "temp_chan")
; [1] iByteOffset — смещение в байтах данных ответа (от 0, после заголовка)
; [2] sType       — тип: "INT16","UINT16","INT32","UINT32","FLOAT32","BOOL"
; [3] sByteOrder  — раскладка: "ABCD","DCBA","CDAB","BADC"
; [4] fScale      — множитель (1.0 = без изменений, 0.1 = делить на 10)
; [5] sUnit       — единица измерения (для JSON, например "°C", "bar")
```
- `_Rs485_ParseResponse($aBytes, $aVarMap)` — парсит ответ по карте, возвращает JSON строку
- JSON формат: `{"ts":1234567890,"vars":{"temp_chan":-15.0,"status":165,...},"raw":"01 03 14 FF6A..."}`

---

## 📦 ЭТАП 2 — Rs485_AutoTest.au3

**Файл:** `libs/Rs485/Rs485_AutoTest.au3`  
**Без GUI, без Redis. Запускается, тестирует, выводит в ConsoleWrite, завершается.**

### Последовательность тестов:
1. Тест инициализации порта COM7, 19200
2. Тест CRC16 — проверка известных значений
3. Тест BuildRequest — FC03, FC06, FC16
4. Тест чтения регистров 0–9 (все типы данных)
5. Тест парсинга INT16, UINT16, INT32, UINT32, FLOAT32 ABCD, FLOAT32 CDAB
6. Тест записи FC06 — одиночный регистр UINT16
7. Тест записи FC16 — несколько регистров (Float ABCD)
8. Тест записи INT32, UINT32
9. Тест записи Float CDAB
10. Тест `_Rs485_ParseResponse` с картой переменных → JSON строка
11. Итоговый отчёт: сколько тестов прошло / упало

Каждый тест: `ConsoleWrite("[TEST N] Название ... OK/FAIL | ожидалось X, получено Y")`.  
Запускается через `autoit.run_script` — результат виден в MCP.

---

## 📦 ЭТАП 3 — Rs485_Example.au3 + config_example.ini

**Файл:** `libs/Rs485/Rs485_Example.au3`  
**Это готовый модуль — копируется в папку проекта, меняется только config.**

### Возможности:
- Трей-иконка, скрытие/показ окна по клику на трей
- GUI на стандартных контролах AutoIt (совместимость с WinXP)
- 0% CPU в пассивном режиме — только OnEvent, никаких циклов опроса в фоне
- Цикл опроса запускается только когда активен (кнопка Старт/Стоп)
- Все настройки хранятся в `config.ini` рядом с файлом

### GUI — вкладки/секции:
1. **Статус** — последнее считывание, статистика (хорошие/плохие), uptime, кнопка "Обновить"
2. **Запросы** — список запросов (ListView), добавить/удалить/редактировать
3. **Переменные** — карта переменных для выбранного запроса (тип, раскладка, ключ, масштаб)
4. **Redis** — настройки подключения, имя хэша, кнопка "Тест соединения"
5. **Порт** — COM номер, baudrate, таймаут, выбор x32/x64 CommMG
6. **Лог** — последние N строк лога, кнопка "Очистить"

### config.ini структура:
```ini
[Port]
ComPort=7
BaudRate=19200
Timeout=200
CommLib=x64

[Redis]
Host=127.0.0.1
Port=6379
HashName=auto_zames_online
DeviceName=Rs485_Port1

[App]
AppName=Rs485_Port1
LogTarget=3
DebugMode=1
```

### Запросы и карта переменных:
- Хранятся в config.ini секциями `[Request_0]`, `[Request_1]` и т.д.
- Карта переменных каждого запроса — секция `[VarMap_0]`, `[VarMap_1]`
- Редактируются через GUI без перезапуска

### Redis запись:
- После каждого успешного опроса пишет JSON строку в хэш
- Ключ: `{HashName}:{DeviceName}` → поле `data` = JSON с ts + vars + raw
- Подключает `libs/Redis_TCP/Redis_TCP.au3` через SDK

---

## 🔄 ПОРЯДОК РЕАЛИЗАЦИИ

```
[✅] Папка создана
[ ] ЭТАП 0  — SDK_Device.ino (Arduino Slave, все типы данных)
[ ] ЭТАП 1  — Rs485.au3 (ядро, низкоуровневые функции)
[ ] ЭТАП 2  — Rs485_AutoTest.au3 (тесты через MCP run_script)
[ ] ЭТАП 3  — Rs485_Example.au3 + config_example.ini
```

---

## 📌 ТЕХНИЧЕСКИЕ РЕШЕНИЯ (зафиксированные)

| Вопрос | Решение |
|--------|---------|
| Таймер высокого разрешения | winmm.dll timeBeginPeriod(1), без ntdll.dll |
| CommMG версия | Параметр при Init: x32 = CommMG.au3, x64 = CommMG64.au3 |
| Redis | Только в AutoTest и Example, не в ядре библиотеки |
| Очередь запросов | Не реализуем пока, цикл по массиву как в текущих проектах |
| Управляющие запросы | Всегда первые, до цикла чтения |
| JSON результат | Библиотека формирует строку, приложение решает куда писать |
| Timestamp | Внутри JSON от библиотеки (`@YEAR&@MON&@MDAY...`) |
| GUI Example | Стандартные контролы AutoIt, WinXP совместимость, OnEventMode |
| CPU в пассиве | 0% — только OnEvent, никаких фоновых таймеров без нужды |
| Трей | Скрытие/показ окна, иконка в трее |
| Config | INI файл рядом с Example, редактируется через GUI |
