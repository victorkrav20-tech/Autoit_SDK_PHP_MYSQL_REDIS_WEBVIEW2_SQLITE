# Redis TCP Library v1.1

Библиотека для работы с Redis 7.0+ через прямой TCP-протокол (RESP) на языке AutoIt. Часть AutoIt SDK.

## 📋 Содержание

- [Обзор](#обзор)
- [Архитектура](#архитектура)
- [Интеграция с SDK](#интеграция-с-sdk)
- [Быстрый старт](#быстрый-старт)
- [API Документация](#api-документация)
- [Производительность](#производительность)
- [Примеры использования](#примеры-использования)
- [Тестирование](#тестирование)
- [Известные проблемы](#известные-проблемы)

## 🔍 Обзор

Библиотека предоставляет полнофункциональный клиент Redis для AutoIt с поддержкой:

- ✅ **Прямой TCP соединение** без внешних зависимостей
- ✅ **Полная поддержка RESP протокола** (Redis Serialization Protocol)
- ✅ **UTF-8 кодировка** для русского языка через SDK Utils
- ✅ **Автовосстановление соединения** при разрыве
- ✅ **Высокая производительность** (~25,000 операций/сек)
- ✅ **Массовые операции** MSET/MGET
- ✅ **Работа с массивами** 1D и 2D
- ✅ **Функции мониторинга** состояния Redis
- ✅ **Система Pub/Sub** для real-time уведомлений
- ✅ **Интеграция с SDK** - единое логирование через Utils

## 🏗️ Архитектура

### Структура модуля
```
libs/Redis_TCP/
├── Redis_Core_TCP.au3    # Основная библиотека Redis
├── Redis_PubSub.au3      # Система Pub/Sub для real-time
├── Redis_AutoTest.au3    # Автоматическое тестирование
├── Utils.au3             # (Устарел - используется SDK Utils)
└── README.md             # Документация
```

### Основные компоненты

1. **Redis_Core_TCP.au3** - Главная библиотека (SET/GET/HSET/MSET/массивы)
2. **Redis_PubSub.au3** - Система подписок и уведомлений
3. **Redis_AutoTest.au3** - Комплексное тестирование

### Зависимости

- **Utils** - логирование через `_Logger_Write()` (SDK Utils v2.0)
- **WinHttp** - не требуется (прямой TCP)
- **json** - не требуется для базовых операций

## 🔗 Интеграция с SDK

### Подключение через SDK_Init

```autoit
#include "..\..\libs\SDK_Init.au3"

; Инициализация SDK (включает Utils, MySQL)
_SDK_Init("MyApp", True, 1, 3, True)

; Инициализация Redis (опционально)
_SDK_Redis_Init("127.0.0.1", 6379)

; Теперь можно использовать Redis
_Redis_Set("mykey", "myvalue")
```

### Прямое подключение (без SDK)

```autoit
#include "libs\Redis_TCP\Redis_Core_TCP.au3"
#include "libs\Redis_TCP\Redis_PubSub.au3"

; Подключение к Redis
_Redis_Connect("127.0.0.1", 6379)
```

### Логирование

Все логи Redis пишутся через SDK Utils с префиксом `[Redis]`:

```
✅ [Redis] Подключение успешно: 127.0.0.1:6379
📤 [Redis] Pub/Sub: Опубликовано в [channel], получателей: 2
❌ [Redis] Ошибка подключения к 127.0.0.1:6379
```

Логи сохраняются в: `logs/AppName/AppName_Main.log` (или другой модуль)

## ⚡ Быстрый старт

### Вариант 1: Через SDK (рекомендуется)

```autoit
#include "..\..\libs\SDK_Init.au3"

; Инициализация SDK
_SDK_Init("MyApp", True, 1, 3, True)

; Инициализация Redis
_SDK_Redis_Init("127.0.0.1", 6379)

; Простые операции
_Redis_Set("mykey", "myvalue")
Local $sValue = _Redis_Get("mykey")

; Работа с хешами
_Redis_HSet("user:1", "name", "John")
_Redis_HSet("user:1", "age", "30")
Local $aUserData = _Redis_HGetAll("user:1")

; Массовые операции
Local $aData[4] = ["key1", "value1", "key2", "value2"]
_Redis_MSet($aData)

; Отключение
_Redis_Disconnect()
```

### Вариант 2: Прямое подключение

```autoit
#include "libs\Redis_TCP\Redis_Core_TCP.au3"

; Подключение к Redis
_Redis_Connect("127.0.0.1", 6379)

; Простые операции
_Redis_Set("mykey", "myvalue")
Local $sValue = _Redis_Get("mykey")

; Отключение
_Redis_Disconnect()
```

## 🔔 Pub/Sub система (Real-time уведомления)

```autoit
#include "..\..\libs\SDK_Init.au3"

; Инициализация SDK
_SDK_Init("MyApp", True, 1, 3, True)
_SDK_Redis_Init("127.0.0.1", 6379)

; Подключение Pub/Sub (отдельное соединение)
_Redis_PubSub_Connect("127.0.0.1", 6379)

; Подписка на каналы
_Redis_Subscribe("sensor_updates")
_Redis_Subscribe("alarms")

; Запуск фонового слушателя
_Redis_PubSub_StartListener()

; Отправка уведомлений (из другого процесса)
_Redis_Publish("sensor_updates", "Temperature: 25.5°C")
_Redis_Publish("alarms", "High pressure detected!")

; Основной цикл приложения
While 1
    ; Ваш код приложения
    ; Pub/Sub сообщения обрабатываются автоматически в фоне
    Sleep(100)
WEnd

; Очистка
_Redis_PubSub_StopListener()
_Redis_PubSub_Disconnect()
_Redis_Disconnect()
```
_Redis_Publish("alarms", "High pressure detected!")

; Основной цикл приложения
While 1
    ; Ваш код приложения
    ; Pub/Sub сообщения обрабатываются автоматически в фоне
    Sleep(100)
WEnd

; Очистка
_Redis_PubSub_StopListener()
_Redis_PubSub_Disconnect()
```

## 📚 API Документация

### 🔍 Полный список функций (AI Reference)

#### Redis_Core_TCP.au3 - Основная библиотека

**Подключение:**
- `_Redis_Connect($sHost, $iPort)` - Подключение к Redis
- `_Redis_ConnectNonBlocking($sHost, $iPort, $iTimeoutMs)` - Неблокирующее подключение
- `_Redis_Disconnect()` - Отключение

**Строковые операции:**
- `_Redis_Set($sKey, $sValue)` - Установка значения (SET)
- `_Redis_Get($sKey)` - Получение значения (GET)

**Хеши:**
- `_Redis_HSet($sKey, $sField, $sValue)` - Установка поля хеша (HSET)
- `_Redis_HGet($sKey, $sField)` - Получение поля хеша (HGET)
- `_Redis_HGetAll($sKey)` - Получение всех полей хеша (HGETALL)

**Управление ключами:**
- `_Redis_Del($sKeys)` - Удаление ключей (DEL)
- `_Redis_Exists($sKey)` - Проверка существования (EXISTS)
- `_Redis_Expire($sKey, $iSeconds)` - Установка TTL (EXPIRE)
- `_Redis_TTL($sKey)` - Получение TTL (TTL)

**Массовые операции:**
- `_Redis_MSet($aKeyValuePairs)` - Массовая установка (MSET)
- `_Redis_MGet($aKeys)` - Массовое получение (MGET)

**Массивы:**
- `_Redis_SetArray1D($sKey, $aArray)` - Сохранение 1D массива
- `_Redis_GetArray1D($sKey)` - Получение 1D массива
- `_Redis_SetArray2D($sKey, $aArray)` - Сохранение 2D массива
- `_Redis_GetArray2D($sKey)` - Получение 2D массива
- `_Redis_SetArray1D_Fast($sPrefix, $aArray)` - Быстрое сохранение 1D (MSET)
- `_Redis_GetArray1D_Fast($sPrefix, $iSize)` - Быстрое получение 1D (MGET)
- `_Redis_SetArray2D_Fast($sPrefix, $aArray)` - Быстрое сохранение 2D (MSET)
- `_Redis_GetArray2D_Fast($sPrefix)` - Быстрое получение 2D (MGET)

**Кольцевой буфер (LIST):**
- `_Redis_ListPush($sKey, $sValue, $iMaxSize)` - Добавление в буфер (LPUSH+LTRIM)
- `_Redis_ListGet($sKey, $iIndex)` - Получение по индексу (LINDEX)
- `_Redis_ListGetAll($sKey)` - Получение всех элементов (LRANGE)
- `_Redis_ListSize($sKey)` - Размер списка (LLEN)
- `_Redis_ListClear($sKey)` - Очистка списка (DEL)

**Persistence (Сохранение):**
- `_Redis_Save()` - Синхронное сохранение на диск (SAVE)
- `_Redis_BgSave()` - Фоновое сохранение (BGSAVE)
- `_Redis_LastSave()` - Время последнего сохранения (LASTSAVE)

**Counters (Счетчики):**
- `_Redis_Incr($sKey)` - Увеличение на 1 (INCR)
- `_Redis_IncrBy($sKey, $iValue)` - Увеличение на N (INCRBY)
- `_Redis_Decr($sKey)` - Уменьшение на 1 (DECR)
- `_Redis_DecrBy($sKey, $iValue)` - Уменьшение на N (DECRBY)

**Мониторинг:**
- `_Redis_Keys($sPattern)` - Поиск ключей (KEYS)
- `_Redis_Info($sSection)` - Информация о сервере (INFO)
- `_Redis_Ping()` - Проверка соединения (PING)
- `_Redis_PingNonBlocking($iTimeoutMs)` - Неблокирующий PING
- `_Redis_DBSize()` - Количество ключей (DBSIZE)
- `_Redis_FlushDB()` - Очистка БД (FLUSHDB)

#### Redis_PubSub.au3 - Pub/Sub система

**Подключение Pub/Sub:**
- `_Redis_PubSub_Connect($sHost, $iPort)` - Отдельное Pub/Sub соединение
- `_Redis_PubSub_Disconnect()` - Отключение Pub/Sub
- `_Redis_PubSub_IsConnected()` - Проверка соединения

**Pub/Sub операции:**
- `_Redis_Publish($sChannel, $sMessage)` - Отправка сообщения (PUBLISH)
- `_Redis_Subscribe($sChannel)` - Подписка на канал (SUBSCRIBE)
- `_Redis_Unsubscribe($sChannel)` - Отписка от канала (UNSUBSCRIBE)

**Слушатель:**
- `_Redis_PubSub_StartListener()` - Запуск фонового слушателя
- `_Redis_PubSub_StopListener()` - Остановка слушателя
- `_Redis_PubSub_CheckMessages()` - Неблокирующая проверка сообщений
- `_Redis_PubSub_ProcessMessage($aMessage)` - Обработка сообщения

**Двойная отправка (_Plus):**
- `_Redis_Publish_Plus($sChannel, $sMessage, $sTablePrefix)` - Pub/Sub + таблица
- `_Redis_SetArray1D_Plus($sChannel, $aArray, $sTablePrefix)` - Массив в Pub/Sub + таблицу
- `_Redis_MSet_Plus($aChannels, $aKeyValuePairs, $sTablePrefix)` - Множественная отправка

**Восстановление данных:**
- `_Redis_GetAutoItDataKeys()` - Получение ключей autoit_data
- `_Redis_RestoreFromAutoItData($sPattern)` - Восстановление после перезагрузки

**Статистика:**
- `_Redis_PubSub_GetStats()` - Статистика Pub/Sub
- `_Redis_PubSub_TestArray($aArray)` - Тест массива

---

### Основные функции

#### Подключение
```autoit
_Redis_Connect($sHost = "127.0.0.1", $iPort = 6379)
```
- **Описание:** Подключение к Redis серверу
- **Параметры:** 
  - `$sHost` - IP адрес сервера
  - `$iPort` - Порт сервера
- **Возврат:** `True` при успехе, `False` при ошибке

#### Отключение
```autoit
_Redis_Disconnect()
```
- **Описание:** Корректное отключение от сервера
- **Возврат:** Нет

### Строковые операции

#### SET
```autoit
_Redis_Set($sKey, $sValue)
```
- **Описание:** Установка значения ключа
- **Параметры:**
  - `$sKey` - Ключ
  - `$sValue` - Значение
- **Возврат:** `True` при успехе

#### GET
```autoit
_Redis_Get($sKey)
```
- **Описание:** Получение значения ключа
- **Параметры:** `$sKey` - Ключ
- **Возврат:** Значение или `False` при ошибке

### Операции с хешами

#### HSET
```autoit
_Redis_HSet($sKey, $sField, $sValue)
```
- **Описание:** Установка поля в хеше
- **Возврат:** `True` при успехе

#### HGET
```autoit
_Redis_HGet($sKey, $sField)
```
- **Описание:** Получение поля из хеша
- **Возврат:** Значение поля

#### HGETALL
```autoit
_Redis_HGetAll($sKey)
```
- **Описание:** Получение всех полей хеша
- **Возврат:** Массив полей и значений

### Управление ключами

#### DEL
```autoit
_Redis_Del($sKeys)
```
- **Описание:** Удаление ключей
- **Параметры:** `$sKeys` - Ключ или массив ключей
- **Возврат:** Количество удаленных ключей

#### EXISTS
```autoit
_Redis_Exists($sKey)
```
- **Описание:** Проверка существования ключа
- **Возврат:** `True` если существует

#### EXPIRE
```autoit
_Redis_Expire($sKey, $iSeconds)
```
- **Описание:** Установка времени жизни ключа
- **Параметры:** `$iSeconds` - Время в секундах
- **Возврат:** `True` при успехе

#### TTL
```autoit
_Redis_TTL($sKey)
```
- **Описание:** Получение оставшегося времени жизни
- **Возврат:** Время в секундах (-1 если без TTL, -2 если ключ не существует)

### Массовые операции

#### MSET
```autoit
_Redis_MSet($aKeyValuePairs)
```
- **Описание:** Массовая установка ключей
- **Параметры:** `$aKeyValuePairs` - Массив [ключ1, значение1, ключ2, значение2, ...]
- **Возврат:** `True` при успехе

#### MGET
```autoit
_Redis_MGet($aKeys)
```
- **Описание:** Массовое получение значений
- **Параметры:** `$aKeys` - Массив ключей
- **Возврат:** Массив значений

### Работа с массивами

#### Одномерные массивы
```autoit
_Redis_SetArray1D($sKey, $aArray, $sDelimiter = "|")
_Redis_GetArray1D($sKey, $sDelimiter = "|")
```
- **Принцип:** Сериализация массива в строку с разделителем
- **Производительность:** Быстрая запись, медленный парсинг

#### Двумерные массивы
```autoit
_Redis_SetArray2D($sKey, $aArray, $sRowDelim = "||", $sColDelim = "|")
_Redis_GetArray2D($sKey, $sRowDelim = "||", $sColDelim = "|")
```
- **Принцип:** Сериализация с разделителями строк и столбцов
- **Формат:** "10x100||строка0||строка1||..."

#### Быстрые массивы (экспериментальные)
```autoit
_Redis_SetArray1D_Fast($sKeyPrefix, $aArray)
_Redis_GetArray1D_Fast($sKeyPrefix, $iSize)
_Redis_SetArray2D_Fast($sKeyPrefix, $aArray)
_Redis_GetArray2D_Fast($sKeyPrefix)
```
- **Принцип:** Каждый элемент = отдельный ключ
- **Проблема:** Некоторые элементы теряются при MSET (требует исследования)

### Кольцевой буфер (LIST)

Функции для работы с Redis LIST как кольцевым буфером (например, для логов датчиков).

#### LISTPUSH
```autoit
_Redis_ListPush($sKey, $sValue, $iMaxSize)
```
- **Описание:** Добавление элемента в начало списка с автоматической обрезкой
- **Параметры:**
  - `$sKey` - Ключ списка
  - `$sValue` - Значение для добавления
  - `$iMaxSize` - Максимальный размер буфера
- **Возврат:** `True` при успехе
- **Применение:** Логи датчиков, история событий

#### LISTGET
```autoit
_Redis_ListGet($sKey, $iIndex)
```
- **Описание:** Получение элемента по индексу (0 = самый новый)
- **Возврат:** Значение элемента

#### LISTGETALL
```autoit
_Redis_ListGetAll($sKey)
```
- **Описание:** Получение всех элементов списка
- **Возврат:** Массив элементов

#### LISTSIZE
```autoit
_Redis_ListSize($sKey)
```
- **Описание:** Получение размера списка
- **Возврат:** Количество элементов

#### LISTCLEAR
```autoit
_Redis_ListClear($sKey)
```
- **Описание:** Очистка списка (удаление ключа)
- **Возврат:** `True` при успехе

### Persistence (Сохранение на диск)

Функции для контролируемого сохранения данных Redis на диск.

#### SAVE
```autoit
_Redis_Save()
```
- **Описание:** Синхронное (блокирующее) сохранение всех данных на диск
- **Возврат:** `True` при успехе
- **Применение:** Контрольные точки перед критическими операциями
- **Внимание:** Блокирует Redis до завершения сохранения
- **Производительность:** ~2мс

#### BGSAVE
```autoit
_Redis_BgSave()
```
- **Описание:** Асинхронное (фоновое) сохранение данных на диск
- **Возврат:** `True` при успешном запуске
- **Применение:** Регулярные бэкапы без блокировки
- **Производительность:** Мгновенный запуск

#### LASTSAVE
```autoit
_Redis_LastSave()
```
- **Описание:** Получение времени последнего успешного сохранения
- **Возврат:** Unix timestamp
- **Применение:** Проверка актуальности бэкапа

### Counters (Атомарные счетчики)

Функции для атомарных операций со счетчиками (без race condition).

#### INCR
```autoit
_Redis_Incr($sKey)
```
- **Описание:** Атомарное увеличение значения на 1
- **Возврат:** Новое значение счетчика
- **Применение:** Счетчики деталей, ID генераторы
- **Производительность:** 0.04мс/операция

#### INCRBY
```autoit
_Redis_IncrBy($sKey, $iValue)
```
- **Описание:** Атомарное увеличение значения на N
- **Параметры:** `$iValue` - Число для прибавления
- **Возврат:** Новое значение счетчика

#### DECR
```autoit
_Redis_Decr($sKey)
```
- **Описание:** Атомарное уменьшение значения на 1
- **Возврат:** Новое значение счетчика

#### DECRBY
```autoit
_Redis_DecrBy($sKey, $iValue)
```
- **Описание:** Атомарное уменьшение значения на N
- **Параметры:** `$iValue` - Число для вычитания
- **Возврат:** Новое значение счетчика

### Мониторинг

#### PING
```autoit
_Redis_Ping()
```
- **Описание:** Проверка соединения
- **Возврат:** `True` если сервер отвечает

#### KEYS
```autoit
_Redis_Keys($sPattern = "*")
```
- **Описание:** Поиск ключей по шаблону
- **Возврат:** Массив найденных ключей

#### INFO
```autoit
_Redis_Info($sSection = "")
```
- **Описание:** Информация о сервере
- **Возврат:** Строка с информацией

#### DBSIZE
```autoit
_Redis_DBSize()
```
- **Описание:** Количество ключей в БД
- **Возврат:** Число ключей

#### FLUSHDB
```autoit
_Redis_FlushDB()
```
- **Описание:** Очистка текущей БД
- **Возврат:** `True` при успехе

## 📊 Производительность

### Результаты тестирования (v1.1)

| Операция | Время | Примечание |
|----------|-------|------------|
| Подключение | 1мс | Быстрое TCP соединение |
| SET/GET | 0-1мс | Одиночные операции |
| HASH операции | 0мс | HSET/HGET/HGETALL |
| MSET/MGET (5000 ключей) | 21мс/29мс | ~100,000 операций/сек |
| Массивы 1D[1000] | 0мс/239мс | Быстрая запись, парсинг |
| Массивы 2D[10x100] | 0мс/231мс | Аналогично 1D |
| Быстрые массивы 1D[1000] | 4мс/7мс | Через MSET/MGET |
| Быстрые массивы 2D[10x100] | 4мс/7мс | Через MSET/MGET |
| Pub/Sub (1000 элементов) | ~1мс/цикл | Real-time уведомления |
| Кольцевой буфер (LIST) | 0.21мс/запись | 100 записей за 21мс |
| SAVE (синхронное) | 2.17мс | Принудительное сохранение |
| BGSAVE (фоновое) | мгновенно | Асинхронное сохранение |
| INCR/DECR | 0.04мс/операция | Атомарные счетчики |
| Переподключение | <1сек | Автовосстановление

### Рекомендации по производительности

1. **Используйте MSET/MGET** для массовых операций
2. **Избегайте частых подключений** - держите соединение открытым
3. **Для больших массивов** рассмотрите разбиение на части
4. **Мониторинг производительности** через функции INFO и DBSIZE

## 💡 Примеры использования

### Пример 1: Простое кеширование
```autoit
#include "core/Redis_Core_TCP.au3"

; Подключение
_Redis_Connect()

; Кеширование данных
_Redis_Set("cache:user:123", "John Doe")
_Redis_Expire("cache:user:123", 3600) ; TTL 1 час

; Получение из кеша
Local $sUser = _Redis_Get("cache:user:123")
If $sUser <> False Then
    ConsoleWrite("Пользователь из кеша: " & $sUser & @CRLF)
EndIf

_Redis_Disconnect()
```

### Пример 2: Работа с массивами данных
```autoit
#include "core/Redis_Core_TCP.au3"

_Redis_Connect()

; Сохранение массива датчиков
Local $aSensors[5] = ["Temp:25.5", "Humidity:60", "Pressure:1013", "Light:800", "Motion:0"]
_Redis_SetArray1D("sensors:data", $aSensors)

; Получение данных датчиков
Local $aData = _Redis_GetArray1D("sensors:data")
For $i = 0 To UBound($aData) - 1
    ConsoleWrite("Датчик " & $i & ": " & $aData[$i] & @CRLF)
Next

_Redis_Disconnect()
```

### Пример 3: Массовые операции
```autoit
#include "core/Redis_Core_TCP.au3"

_Redis_Connect()

; Подготовка данных для массовой записи
Local $aData[1000] ; 500 пар ключ-значение
For $i = 0 To 499
    $aData[$i * 2] = "metric:" & $i
    $aData[$i * 2 + 1] = Random(0, 100, 2)
Next

; Массовая запись
_Redis_MSet($aData)

; Массовое чтение
Local $aKeys[500]
For $i = 0 To 499
    $aKeys[$i] = "metric:" & $i
Next

Local $aValues = _Redis_MGet($aKeys)
ConsoleWrite("Получено " & UBound($aValues) & " значений" & @CRLF)

_Redis_Disconnect()
```

## 🧪 Тестирование

### Запуск автотестов
```autoit
; Запустите файл
core/Redis_AutoTest.au3
```

### Тестовые сценарии
1. **Подключение к Redis** - проверка TCP соединения
2. **Строковые операции** - SET/GET с случайными данными
3. **Хеш операции** - HSET/HGET/HGETALL
4. **Массивы** - сериализация/десериализация 1D и 2D
5. **Целостность данных** - проверка сохранности
6. **Базовые операции** - DEL/EXISTS/EXPIRE/TTL
7. **Производительность** - тест на 5000 ключей
8. **Мониторинг** - PING/KEYS/INFO/DBSIZE

### Интерпретация результатов
- ✅ **Зеленые сообщения** - тесты пройдены
- ❌ **Красные сообщения** - ошибки требуют внимания
- 📊 **Время выполнения** - в миллисекундах

## ⚠️ Известные проблемы

### 1. Быстрые массивы (Fast Arrays)
**Проблема:** При использовании `_Redis_SetArray1D_Fast()` некоторые элементы теряются
```
🔧 DEBUG: Получено 1000 элементов, пустых: 563
```
**Статус:** Требует исследования
**Обходной путь:** Используйте обычные функции массивов

### 2. Производительность парсинга
**Проблема:** Чтение больших массивов медленное (250мс для 1000 элементов)
**Причина:** Парсинг строки с разделителями
**Решение:** Рассмотрите разбиение на меньшие части

### 3. Ограничения RESP протокола
**Проблема:** Некоторые специальные символы могут вызывать проблемы
**Рекомендация:** Тестируйте с вашими данными

## 🔧 Техническая информация

### RESP Протокол
Библиотека полностью реализует Redis Serialization Protocol:
- **Simple Strings** (+OK\r\n)
- **Errors** (-ERR message\r\n)
- **Integers** (:1000\r\n)
- **Bulk Strings** ($6\r\nfoobar\r\n)
- **Arrays** (*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n)

### UTF-8 Поддержка
Все строковые данные обрабатываются через:
```autoit
StringToBinary($sData, 4)  ; Для отправки
BinaryToString($vData, 4)  ; Для получения
```

### Автовосстановление соединения
При разрыве соединения библиотека автоматически:
1. Обнаруживает разрыв через PING
2. Переподключается к серверу
3. Продолжает выполнение операций

## 🤝 Разработка

### Добавление новых функций
1. Добавьте функцию в `Redis_Core_TCP.au3`
2. Обновите список функций в начале файла
3. Добавьте тест в `Redis_AutoTest.au3`
4. Обновите документацию

### Структура функции Redis
```autoit
Func _Redis_NewCommand($sParam1, $sParam2)
    If Not _Redis_CheckConnection() Then
        Return False
    EndIf
    
    Local $aCommand[3] = ["COMMAND", $sParam1, $sParam2]
    
    If _Redis_SendCommand($aCommand) Then
        Local $vResponse = _Redis_ReceiveResponse()
        Return $vResponse ; или обработанный результат
    EndIf
    
    Return False
EndFunc
```

### Отладка
Для отладки используйте SDK логирование:
```autoit
; Логи автоматически пишутся через _Logger_Write()
; Все логи Redis имеют префикс [Redis]
; Проверьте файл: logs/AppName/AppName_Main.log
```

---

## 📝 История изменений

### v1.1 (Persistence & Counters)
- ✅ Добавлены функции сохранения: SAVE, BGSAVE, LASTSAVE
- ✅ Добавлены атомарные счетчики: INCR, INCRBY, DECR, DECRBY
- ✅ Обновлены автотесты (17 тестов)
- ✅ Обновлена документация с полным списком функций
- ✅ Производительность: INCR 0.04мс/операция, SAVE 2.17мс
- ✅ Дата: 17.02.2026

### v1.0 (SDK Integration)
- ✅ Интеграция с AutoIt SDK
- ✅ Обновлено логирование на SDK Utils v2.0
- ✅ Добавлен префикс `[Redis]` ко всем логам
- ✅ Убран собственный Utils.au3 (используется SDK Utils)
- ✅ Обновлены глобальные переменные с префиксом `$g_Redis_`
- ✅ Убран ReDim из Redis_PubSub.au3
- ✅ Добавлена функция `_SDK_Redis_Init()` в SDK_Init.au3
- ✅ Обновлена документация

---

**Версия:** 1.1 (Persistence & Counters)  
**Дата обновления:** 17.02.2026  
**Совместимость:** AutoIt SDK v0.1+  
**Лицензия:** Open Source  
**Поддержка:** Через GitHub Issues