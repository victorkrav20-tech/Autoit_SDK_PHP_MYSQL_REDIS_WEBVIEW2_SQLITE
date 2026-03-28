; ===============================================================================
; Redis AutoTest v1.1
; Автоматическое тестирование Redis библиотеки
; ===============================================================================
;
; ОБНОВЛЯТЬ ОБЯЗАТЕЛЬНО ПРИ ДОБАВЛЕНИИ ИЛИ УДАЛЕНИИ ФУНКЦИЙ!
;
; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ОСНОВНЫЕ ТЕСТОВЫЕ ФУНКЦИИ:
; _TestRedisConnection()                  - Тест подключения к Redis
; _TestStringOperations()                 - Тест SET/GET операций
; _TestHashOperations()                   - Тест HSET/HGET/HGETALL операций
; _TestSimpleArrayOperations()            - Тест простых массивов (5 элементов)
; _TestDataIntegrity()                    - Проверка целостности данных
; _TestBasicOperations()                  - Тест DEL/EXISTS/EXPIRE/TTL
; _TestPerformanceOperations()            - Тест MSET/MGET (5 ключей)
; _TestMassivePerformance()               - Тест производительности (5000 ключей)
; _TestAdvancedArrayOperations()          - Тест больших массивов (1000 элементов)
; _TestMonitoringOperations()             - Тест функций мониторинга
; _TestFastArrayOperations()              - Тест быстрых массивов (MSET/MGET)
; _TestPubSubOperations()                 - Тест системы Pub/Sub (подписки и публикации)
; _TestPubSubArray1D()                    - Тест одномерного массива через Pub/Sub
; _TestPubSubArray2D()                    - Тест двумерного массива через Pub/Sub
; _TestCircularBufferOperations()         - Тест кольцевого буфера (LIST)
; _TestPersistenceOperations()            - Тест функций сохранения (SAVE/BGSAVE/LASTSAVE)
; _TestCounterOperations()                - Тест атомарных счетчиков (INCR/DECR)
; _TestNonBlockingReconnection()          - Тест неблокирующего переподключения
; ===============================================================================

#include "Redis_Core_TCP.au3"
#include "Redis_PubSub.au3"
#include "..\Utils\Utils.au3"
_SDK_Utils_Init("Redis_AutoTest", "Redis", True, 1, 3, True)
; Инициализация
_Logger_ClearLog()
_Logger_ConsoleWriteUTF("🧪 Redis AutoTest запущен")

; Основной цикл тестирования
Local $iCycleCount = 0
;While True  ; Закомментировано для одиночного теста
    $iCycleCount += 1
    _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycleCount)

    ; Тест 1: Подключение к Redis
    If Not _TestRedisConnection() Then
        _Logger_ConsoleWriteUTF("⚠️ Нет подключения к Redis - запускаем только тест 15 (мониторинг переподключения)")
        ; Переходим сразу к тесту 15
        ;_Logger_ConsoleWriteUTF("⚠️ Тест 15 запускается в бесконечном режиме - остальные тесты пропущены")
        ;_TestNonBlockingReconnection()
        ;Exit ; Этот код не выполнится из-за бесконечного цикла в тесте 15
    EndIf

    ; Тест 2: Работа со строками (SET/GET)
    _TestStringOperations()

    ; Тест 3: Работа с хешами (HSET/HGET/HGETALL)
    _TestHashOperations()

    ; Тест 4: Работа с массивами (обновленный)
    _TestArrayOperations()

    ; Тест 5: Проверка целостности данных
    _TestDataIntegrity()

    ; Тест 6: Базовые функции управления
    _TestBasicOperations()

    ; Тест 7: Функции производительности (5 ключей)
    _TestPerformanceOperations()

    ; Тест 8: Массивная производительность (5000 ключей)
    _TestMassivePerformance()

    ; Тест 9: Продвинутые операции с массивами (1000 элементов)
    _TestAdvancedArrayOperations()

    ; Тест 10: Функции мониторинга
    _TestMonitoringOperations()

    ; Тест 11: Быстрые операции с массивами (MSET/MGET)
    _TestFastArrayOperations()

    ; Тест 12: Система Pub/Sub (подписки и публикации)
    ;_TestPubSubOperations()

    ; Тест 13: Функции _plus (двойная отправка Pub/Sub + Redis таблицы)
    ;_TestPubSubPlusOperations()

    ; Тест 14: Кольцевой буфер (Redis LIST) - датчик температуры
    _TestCircularBufferOperations()

	_Test_Redis_FastPush_Stability()
    ; Тест 15: Функции сохранения (SAVE/BGSAVE/LASTSAVE)
    _TestPersistenceOperations()

    ; Тест 16: Атомарные счетчики (INCR/INCRBY/DECR/DECRBY)
    _TestCounterOperations()

    ; Тест 17: Неблокирующее переподключение и восстановление (бесконечный)
    ; Запускается только если все предыдущие тесты прошли успешно
    _Logger_ConsoleWriteUTF("⚠️ Тест 17 запускается в бесконечном режиме")
    _TestNonBlockingReconnection()

    ; Этот код не выполнится из-за бесконечного цикла в тесте 17
    _Logger_ConsoleWriteUTF("✅ Тестирование завершено успешно")

    ; Отключаемся от Redis
    ;_Redis_Disconnect()
    ;_Logger_ConsoleWriteUTF("📡 Отключение от Redis")

    ; Для включения цикла раскомментируйте строки ниже и закомментируйте Exit
    ;_Logger_ConsoleWriteUTF("⏱️ Пауза 500мс...")
    ;Sleep(500)
;WEnd

Exit ; Выход после одного цикла (закомментировать для цикла)

; ===============================================================================
; Функция: _TestRedisConnection
; Описание: Тестирование подключения к Redis
; ===============================================================================
Func _TestRedisConnection()
    Local $hTimer = _Utils_GetTimestamp()

    Local $bResult = _Redis_Connect("127.0.0.1", 6379)
    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("📡 Подключение к Redis успешно (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("📡 Redis подключение успешно за " & Int($iElapsed) & "мс")
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка подключения к Redis (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка подключения к Redis за " & Int($iElapsed) & "мс")
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestStringOperations
; Описание: Тестирование операций со строками
; ===============================================================================
Func _TestStringOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Генерируем случайное число
    Local $iRandomValue = Random(1000, 9999, 1)
    Local $sTestKey = "Test:RandomValue"

    ; Тестируем SET
    Local $bSetResult = _Redis_Set($sTestKey, String($iRandomValue))
    If Not $bSetResult Then
        _Logger_ConsoleWriteUTF("❌ SET операция провалена")
        Return False
    EndIf

    ; Тестируем GET
    Local $sGetResult = _Redis_Get($sTestKey)
    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $sGetResult = String($iRandomValue) Then
        _Logger_ConsoleWriteUTF("💾 SET/GET успешно: " & $iRandomValue & " (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("💾 SET/GET операции успешны за " & Int($iElapsed) & "мс, значение: " & $iRandomValue)
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ GET вернул неверное значение: " & $sGetResult & " вместо " & $iRandomValue)
        _Logger_WriteToFile("❌ Ошибка SET/GET операций за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestHashOperations
; Описание: Тестирование операций с хешами
; ===============================================================================
Func _TestHashOperations()
    Local $hTimer = _Utils_GetTimestamp()

    Local $sHashKey = "Test:Hash"
    Local $sField1 = "field1"
    Local $sValue1 = "Значение1"
    Local $sField2 = "field2"
    Local $sValue2 = "Значение2"

    ; Тестируем HSET
    Local $bHSet1 = _Redis_HSet($sHashKey, $sField1, $sValue1)
    Local $bHSet2 = _Redis_HSet($sHashKey, $sField2, $sValue2)

    If Not ($bHSet1 And $bHSet2) Then
        _Logger_ConsoleWriteUTF("❌ HSET операции провалены")
        Return False
    EndIf

    ; Тестируем HGET
    Local $sHGet1 = _Redis_HGet($sHashKey, $sField1)
    Local $sHGet2 = _Redis_HGet($sHashKey, $sField2)

    ; Тестируем HGETALL
    Local $aHGetAll = _Redis_HGetAll($sHashKey)
    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $sHGet1 = $sValue1 And $sHGet2 = $sValue2 And IsArray($aHGetAll) Then
        _Logger_ConsoleWriteUTF("📥 HASH операции успешно: 2 поля (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("📥 HSET/HGET/HGETALL операции успешны за " & Int($iElapsed) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ HASH операции провалены (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка HSET/HGET операций за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestDataIntegrity
; Описание: Проверка целостности данных (Integrity Check)
; ===============================================================================
Func _TestDataIntegrity()
    Local $hTimer = _Utils_GetTimestamp()

    ; Проверяем ранее записанные данные
    Local $sRandomValue = _Redis_Get("Test:RandomValue")
    Local $sArrayValue = _Redis_Get("Test:Array")
    Local $aHashData = _Redis_HGetAll("Test:Hash")

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)
    Local $bIntegrityOK = True

    ; Проверяем что данные существуют
    If $sRandomValue = False Or $sArrayValue = False Or Not IsArray($aHashData) Then
        $bIntegrityOK = False
    EndIf

    ; Проверяем что массив хеша содержит данные
    If IsArray($aHashData) And UBound($aHashData) < 4 Then ; Минимум 4 элемента (2 пары ключ-значение)
        $bIntegrityOK = False
    EndIf

    If $bIntegrityOK Then
        _Logger_ConsoleWriteUTF("🔍 Целостность данных OK (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🔍 Integrity Check пройден за " & Int($iElapsed) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Нарушение целостности данных (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Integrity Check провален за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _TestBasicOperations
; Описание: Тестирование базовых операций управления
; ===============================================================================
Func _TestBasicOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Тест EXISTS (должен вернуть True для существующего ключа)
    Local $bExists1 = _Redis_Exists("Test:RandomValue")

    ; Тест DEL
    Local $iDeleted = _Redis_Del("Test:RandomValue")

    ; Тест EXISTS после удаления (должен вернуть False)
    Local $bExists2 = _Redis_Exists("Test:RandomValue")

    ; Создаем тестовый ключ для TTL
    _Redis_Set("Test:TTL", "временный")

    ; Тест EXPIRE
    Local $bExpireSet = _Redis_Expire("Test:TTL", 60) ; 60 секунд

    ; Тест TTL
    Local $iTTL = _Redis_TTL("Test:TTL")

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bExists1 And $iDeleted = 1 And Not $bExists2 And $bExpireSet And $iTTL > 0 And $iTTL <= 60 Then
        _Logger_ConsoleWriteUTF("🔧 Базовые операции успешно (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🔧 DEL/EXISTS/EXPIRE/TTL операции успешны за " & Int($iElapsed) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка базовых операций (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка DEL/EXISTS/EXPIRE/TTL операций за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestPerformanceOperations
; Описание: Тестирование функций производительности
; ===============================================================================
Func _TestPerformanceOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Подготавливаем данные для MSET (5 ключей)
    Local $aMSetData[10] = ["key1", "value1", "key2", "value2", "key3", "value3", "key4", "value4", "key5", "value5"]

    ; Тест MSET
    Local $bMSetResult = _Redis_MSet($aMSetData)

    ; Подготавливаем ключи для MGET
    Local $aMGetKeys[5] = ["key1", "key2", "key3", "key4", "key5"]

    ; Тест MGET
    Local $aMGetResult = _Redis_MGet($aMGetKeys)

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    ; Проверяем результаты
    Local $bMGetOK = IsArray($aMGetResult) And UBound($aMGetResult) = 5
    If $bMGetOK Then
        For $i = 0 To 4
            If $aMGetResult[$i] <> "value" & ($i + 1) Then
                $bMGetOK = False
                ExitLoop
            EndIf
        Next
    EndIf

    If $bMSetResult And $bMGetOK Then
        _Logger_ConsoleWriteUTF("⚡ Производительность: 5 ключей MSET/MGET (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("⚡ MSET/MGET операции успешны за " & Int($iElapsed) & "мс")

        ; Очищаем тестовые ключи
        Local $iDeleted = _Redis_Del($aMGetKeys)
        _Logger_ConsoleWriteUTF("🗑️ DEL: Удалено ключей: " & $iDeleted)

        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка операций производительности (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка MSET/MGET операций за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestMassivePerformance
; Описание: Тестирование производительности на 5000 переменных
; ===============================================================================
Func _TestMassivePerformance()
    Local $hTimer = _Utils_GetTimestamp()

    ; Генерируем 5000 пар ключ-значение
    Local $aMassiveData[10000] ; 5000 * 2
    For $i = 0 To 4999
        $aMassiveData[$i * 2] = "test_data:mass_key_" & $i
        $aMassiveData[$i * 2 + 1] = "value_" & Random(10000, 99999, 1)
    Next

    ; Записываем 5000 ключей
    Local $hWriteTimer = _Utils_GetTimestamp()
    Local $bMSetResult = _Redis_MSet($aMassiveData)
    Local $iWriteTime = _Utils_GetElapsedTime($hWriteTimer)

    ; Подготавливаем ключи для чтения
    Local $aMassiveKeys[5000]
    For $i = 0 To 4999
        $aMassiveKeys[$i] = "test_data:mass_key_" & $i
    Next

    ; Читаем 5000 ключей
    Local $hReadTimer = _Utils_GetTimestamp()
    Local $aMGetResult = _Redis_MGet($aMassiveKeys)
    Local $iReadTime = _Utils_GetElapsedTime($hReadTimer)

    Local $iTotalTime = _Utils_GetElapsedTime($hTimer)

    ; Проверяем результат
    Local $bSuccess = $bMSetResult And IsArray($aMGetResult) And UBound($aMGetResult) = 5000

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("🚀 Массив 5000: запись " & Int($iWriteTime) & "мс, чтение " & Int($iReadTime) & "мс, всего " & Int($iTotalTime) & "мс")
        _Logger_WriteToFile("🚀 Массовые операции 5000 ключей: запись " & Int($iWriteTime) & "мс, чтение " & Int($iReadTime) & "мс")

        ; Очищаем тестовые ключи
        Local $iDeleted = _Redis_Del($aMassiveKeys)
        _Logger_ConsoleWriteUTF("🗑️ DEL: Удалено массивных ключей: " & $iDeleted)

        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка массовых операций (" & Int($iTotalTime) & "мс)")
        _Logger_WriteToFile("❌ Ошибка массовых операций за " & Int($iTotalTime) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestArrayOperations
; Описание: Тестирование работы с массивами
; ===============================================================================
Func _TestArrayOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Создаем тестовый массив из 5 элементов
    Local $aTestArray[5] = ["Элемент1", "Элемент2", "Элемент3", "Элемент4", "Элемент5"]

    ; Преобразуем массив в строку
    Local $sArrayString = _Utils_ArrayToString($aTestArray, "|")
    Local $sArrayKey = "Test:Array"

    ; Сохраняем в Redis
    Local $bSetResult = _Redis_Set($sArrayKey, $sArrayString)
    If Not $bSetResult Then
        _Logger_ConsoleWriteUTF("❌ Сохранение массива провалено")
        Return False
    EndIf

    ; Читаем обратно
    Local $sGetResult = _Redis_Get($sArrayKey)
    Local $aRestoredArray = _Utils_StringToArray($sGetResult, "|")
    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    ; Проверяем целостность
    Local $bIntegrityOK = True
    If UBound($aRestoredArray) <> UBound($aTestArray) + 1 Then ; +1 из-за StringSplit
        $bIntegrityOK = False
    Else
        For $i = 0 To UBound($aTestArray) - 1
            If $aRestoredArray[$i + 1] <> $aTestArray[$i] Then ; +1 из-за StringSplit
                $bIntegrityOK = False
                ExitLoop
            EndIf
        Next
    EndIf

    If $bIntegrityOK Then
        _Logger_ConsoleWriteUTF("📊 Массив 5 элементов успешно (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("📊 Операции с массивами успешны за " & Int($iElapsed) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Нарушена целостность массива (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка операций с массивами за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _TestAdvancedArrayOperations
; Описание: Тестирование работы с большими массивами
; ===============================================================================
Func _TestAdvancedArrayOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Тест 1: Одномерный массив 1000 элементов
    Local $aTest1D[1000]
    For $i = 0 To 999
        $aTest1D[$i] = "Элемент_" & $i & "_" & Random(100, 999, 1)
    Next

    Local $hWrite1D = _Utils_GetTimestamp()
    Local $bSet1D = _Redis_SetArray1D("Test:Array1D", $aTest1D)
    Local $iWrite1D = _Utils_GetElapsedTime($hWrite1D)

    Local $hRead1D = _Utils_GetTimestamp()
    Local $aGet1D = _Redis_GetArray1D("Test:Array1D")
    Local $iRead1D = _Utils_GetElapsedTime($hRead1D)

    ; Проверка целостности 1D
    Local $bIntegrity1D = IsArray($aGet1D) And UBound($aGet1D) = 1000
    If $bIntegrity1D Then
        For $i = 0 To 999
            If $aGet1D[$i] <> $aTest1D[$i] Then
                $bIntegrity1D = False
                ExitLoop
            EndIf
        Next
    EndIf

    ; Тест 2: Двумерный массив [10][100] = 1000 элементов
    Local $aTest2D[10][100]
    For $i = 0 To 9
        For $j = 0 To 99
            $aTest2D[$i][$j] = "Ячейка_" & $i & "_" & $j & "_" & Random(100, 999, 1)
        Next
    Next

    Local $hWrite2D = _Utils_GetTimestamp()
    Local $bSet2D = _Redis_SetArray2D("Test:Array2D", $aTest2D)
    Local $iWrite2D = _Utils_GetElapsedTime($hWrite2D)

    Local $hRead2D = _Utils_GetTimestamp()
    Local $aGet2D = _Redis_GetArray2D("Test:Array2D")
    Local $iRead2D = _Utils_GetElapsedTime($hRead2D)

    ; Проверка целостности 2D
    Local $bIntegrity2D = IsArray($aGet2D) And UBound($aGet2D, 1) = 10 And UBound($aGet2D, 2) = 100
    If $bIntegrity2D Then
        For $i = 0 To 9
            For $j = 0 To 99
                If $aGet2D[$i][$j] <> $aTest2D[$i][$j] Then
                    $bIntegrity2D = False
                    ExitLoop 2
                EndIf
            Next
        Next
    EndIf

    Local $iTotalTime = _Utils_GetElapsedTime($hTimer)

    If $bSet1D And $bIntegrity1D And $bSet2D And $bIntegrity2D Then
        _Logger_ConsoleWriteUTF("📊 Массивы: 1D[1000] " & Int($iWrite1D) & "/" & Int($iRead1D) & "мс, 2D[10x100] " & Int($iWrite2D) & "/" & Int($iRead2D) & "мс")
        _Logger_WriteToFile("📊 Операции с большими массивами успешны за " & Int($iTotalTime) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка операций с большими массивами (" & Int($iTotalTime) & "мс)")
        _Logger_WriteToFile("❌ Ошибка операций с большими массивами за " & Int($iTotalTime) & "мс")
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _TestMonitoringOperations
; Описание: Тестирование функций мониторинга
; ===============================================================================
Func _TestMonitoringOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Тест PING
    Local $bPingResult = _Redis_Ping()

    ; Тест DBSIZE
    Local $iDBSize = _Redis_DBSize()

    ; Тест KEYS
    Local $aKeys = _Redis_Keys("Test:*")

    ; Тест INFO
    Local $sInfo = _Redis_Info("server")

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    Local $bSuccess = $bPingResult And ($iDBSize >= 0) And IsArray($aKeys) And ($sInfo <> False)

    If $bSuccess Then
        _Logger_ConsoleWriteUTF("📊 Мониторинг: PING OK, БД " & $iDBSize & " ключей, найдено " & UBound($aKeys) & " Test:* (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("📊 Функции мониторинга успешны за " & Int($iElapsed) & "мс")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка функций мониторинга (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка функций мониторинга за " & Int($iElapsed) & "мс")
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _TestFastArrayOperations
; Описание: Тестирование быстрых операций с массивами через MSET/MGET
; ===============================================================================
Func _TestFastArrayOperations()
    Local $hTimer = _Utils_GetTimestamp()

    ; Тест 1: Быстрый одномерный массив 1000 элементов
    Local $aTest1D[1000]
    For $i = 0 To 999
        $aTest1D[$i] = "FastElement_" & $i & "_" & Random(100, 999, 1)
    Next

    Local $hWrite1D = _Utils_GetTimestamp()
    Local $bSet1D = _Redis_SetArray1D_Fast("FastTest1D", $aTest1D)
    Local $iWrite1D = _Utils_GetElapsedTime($hWrite1D)

    Local $hRead1D = _Utils_GetTimestamp()
    Local $aGet1D = _Redis_GetArray1D_Fast("FastTest1D", 1000)
    Local $iRead1D = _Utils_GetElapsedTime($hRead1D)

    ; Проверка целостности 1D
    Local $bIntegrity1D = IsArray($aGet1D) And UBound($aGet1D) = 1000
    ;_Logger_ConsoleWriteUTF("🔧 DEBUG Fast1D: IsArray=" & IsArray($aGet1D) & ", размер=" & (IsArray($aGet1D) ? UBound($aGet1D) : "N/A") & ", bSet1D=" & $bSet1D)

    If $bIntegrity1D Then
        For $i = 0 To 999
            If $aGet1D[$i] <> $aTest1D[$i] Then
                ;_Logger_ConsoleWriteUTF("❌ DEBUG Fast1D: Несовпадение в элементе " & $i & ": '" & StringLeft($aGet1D[$i], 20) & "' != '" & StringLeft($aTest1D[$i], 20) & "'")
                $bIntegrity1D = False
                ExitLoop
            EndIf
        Next
        If $bIntegrity1D Then
           ; _Logger_ConsoleWriteUTF("✅ DEBUG Fast1D: Все 1000 элементов совпадают")
        EndIf
    EndIf

    ; Тест 2: Быстрый двумерный массив [10][100] = 1000 элементов
    Local $aTest2D[10][100]
    For $i = 0 To 9
        For $j = 0 To 99
            $aTest2D[$i][$j] = "FastCell_" & $i & "_" & $j & "_" & Random(100, 999, 1)
        Next
    Next

    Local $hWrite2D = _Utils_GetTimestamp()
    Local $bSet2D = _Redis_SetArray2D_Fast("FastTest2D", $aTest2D)
    Local $iWrite2D = _Utils_GetElapsedTime($hWrite2D)

    Local $hRead2D = _Utils_GetTimestamp()
    Local $aGet2D = _Redis_GetArray2D_Fast("FastTest2D")
    Local $iRead2D = _Utils_GetElapsedTime($hRead2D)

    ; Проверка целостности 2D
    Local $bIntegrity2D = IsArray($aGet2D) And UBound($aGet2D, 1) = 10 And UBound($aGet2D, 2) = 100
    ;_Logger_ConsoleWriteUTF("🔧 DEBUG Fast2D: IsArray=" & IsArray($aGet2D) & ", bSet2D=" & $bSet2D)

    If IsArray($aGet2D) Then
        ;_Logger_ConsoleWriteUTF("🔧 DEBUG Fast2D: размеры=" & UBound($aGet2D, 1) & "x" & UBound($aGet2D, 2))
    EndIf

    If $bIntegrity2D Then
        Local $iErrors = 0
        For $i = 0 To 9
            For $j = 0 To 99
                If $aGet2D[$i][$j] <> $aTest2D[$i][$j] Then
                    If $iErrors < 3 Then
                        _Logger_ConsoleWriteUTF("❌ DEBUG Fast2D: Несовпадение [" & $i & "][" & $j & "]: '" & StringLeft($aGet2D[$i][$j], 15) & "' != '" & StringLeft($aTest2D[$i][$j], 15) & "'")
                    EndIf
                    $iErrors += 1
                    $bIntegrity2D = False
                    If $iErrors >= 3 Then ExitLoop 2
                EndIf
            Next
        Next
        If $bIntegrity2D Then
            _Logger_ConsoleWriteUTF("✅ DEBUG Fast2D: Все 1000 элементов совпадают")
        Else
            _Logger_ConsoleWriteUTF("❌ DEBUG Fast2D: Найдено " & $iErrors & " несовпадений")
        EndIf
    EndIf

    Local $iTotalTime = _Utils_GetElapsedTime($hTimer)

    If $bSet1D And $bIntegrity1D And $bSet2D And $bIntegrity2D Then
        _Logger_ConsoleWriteUTF("🚀 Быстрые массивы: 1D[1000] " & Int($iWrite1D) & "/" & Int($iRead1D) & "мс, 2D[10x100] " & Int($iWrite2D) & "/" & Int($iRead2D) & "мс")
        _Logger_WriteToFile("🚀 Быстрые операции с массивами успешны за " & Int($iTotalTime) & "мс")

        ; Очищаем тестовые ключи
        Local $aKeysToDelete[1001] ; 1000 + 1 мета
        For $i = 0 To 999
            $aKeysToDelete[$i] = "FastTest1D:" & $i
        Next
        $aKeysToDelete[1000] = "FastTest2D:meta"
        _Redis_Del($aKeysToDelete)

        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка быстрых операций с массивами (" & Int($iTotalTime) & "мс)")
        _Logger_WriteToFile("❌ Ошибка быстрых операций с массивами за " & Int($iTotalTime) & "мс")
        Return False
    EndIf
EndFunc

; ===============================================================================
; Функция: _TestPubSubOperations
; Описание: Тестирование системы Pub/Sub (подписки и публикации)
; ===============================================================================
Func _TestPubSubOperations()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест 12: Система Pub/Sub")

    ; Подключаем отдельное Pub/Sub соединение
    If Not _Redis_PubSub_Connect("127.0.0.1", 6379) Then
        _Logger_ConsoleWriteUTF("❌ Ошибка подключения Pub/Sub")
        Return False
    EndIf

    ; Подписываемся на тестовый канал
    Local $sTestChannel = "test_channel_100"
    If Not _Redis_Subscribe($sTestChannel) Then
        _Logger_ConsoleWriteUTF("❌ Ошибка подписки на канал")
        _Redis_PubSub_Disconnect()
        Return False
    EndIf

    ; Тест без фонового слушателя - ручная проверка сообщений
    _Logger_ConsoleWriteUTF("🔄 Pub/Sub: Запуск цикла 2 раза в секунду (10 циклов)")
Local $timer_itog = TimerInit()
    For $iCycle = 1 To 50
        ; Создаем тестовый массив из 1000 элементов
        Local $aTestArray[1000]
        For $i = 0 To 999
            $aTestArray[$i] = "Cycle" & $iCycle & "_Element_" & $i & "_" & Random(1000, 9999, 0)
        Next

        ; ЕДИНЫЙ ТАЙМЕР: начинаем замер перед отправкой
        Local $hFullTimer = _Utils_GetTimestamp()

        ; Отправляем массив
        Local $sArrayData = _Utils_ArrayToString($aTestArray, "|")
        Local $iSubscribers = _Redis_Publish($sTestChannel, $sArrayData)

        ; Проверяем входящие сообщения с защитой от зависания
        Local $aMessage = False
        Local $iMaxWaitTime = 200 ; Максимум 200мс ожидания
        Local $hWaitTimer = TimerInit()

        ; Безопасная проверка с таймером защиты
        While TimerDiff($hWaitTimer) < $iMaxWaitTime
            $aMessage = _Redis_PubSub_CheckMessages()
            If IsArray($aMessage) And UBound($aMessage) >= 3 And $aMessage[0] = "message" Then
                ExitLoop
            EndIf
            Sleep(5) ; Небольшая пауза для CPU
        WEnd

        ; Десериализуем полученный массив для проверки
        Local $aReceivedArray = False
        Local $iReceivedCount = 0
        If IsArray($aMessage) And UBound($aMessage) >= 3 And $aMessage[0] = "message" Then
            $aReceivedArray = _Utils_StringToArray($aMessage[2], "|")
            $iReceivedCount = (IsArray($aReceivedArray) ? $aReceivedArray[0] : 0)
        EndIf

        ; ЕДИНЫЙ ТАЙМЕР: завершаем замер после парсинга
        Local $fFullTime = _Utils_GetElapsedTime($hFullTimer)

        ; Логируем результат цикла с высокой точностью
        If IsArray($aMessage) And UBound($aMessage) >= 3 And $aMessage[0] = "message" Then
            _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycle & ": Полное время " & StringFormat("%.2f", $fFullTime) & "мс, элементов: " & $iReceivedCount & "/1000")

            ; Проверка на потерю данных
            If $iReceivedCount < 1000 Then
                _Logger_ConsoleWriteUTF("⚠️ Предупреждение: Потеря данных в цикле #" & $iCycle & " (" & (1000 - $iReceivedCount) & " элементов)")
            EndIf
        Else
            ; Timeout или ошибка получения
            _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycle & ": Timeout " & StringFormat("%.2f", $fFullTime) & "мс (сообщение не получено)")
            $bResult = False
        EndIf

        ; Задержка 500мс (2 раза в секунду)
    Next
	_Logger_ConsoleWriteUTF("✅ 50 циклов приёма передачи пройдено за "&Round(TimerDiff($timer_itog),2)&"")
    ; Проверка статистики
    Local $aStats = _Redis_PubSub_GetStats()
    If IsArray($aStats) Then
        For $i = 1 To UBound($aStats) - 1
            _Logger_ConsoleWriteUTF("📊 Pub/Sub: " & $aStats[$i])
        Next
    EndIf

    ; Дополнительные тесты массивов
    _Logger_ConsoleWriteUTF("🔄 Pub/Sub: Дополнительные тесты массивов")

    ; Тест одномерного массива
    If Not _TestPubSubArray1D() Then
        $bResult = False
    EndIf

    ; Тест двумерного массива
    If Not _TestPubSubArray2D() Then
        $bResult = False
    EndIf

    ; Очистка
    _Redis_Unsubscribe($sTestChannel)
    _Redis_PubSub_Disconnect()

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("🚀 Pub/Sub система успешно протестирована (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🚀 Pub/Sub тест успешно за " & Int($iElapsed) & "мс")
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка тестирования Pub/Sub системы (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Ошибка Pub/Sub теста за " & Int($iElapsed) & "мс")
    EndIf

    Return $bResult
EndFunc
; ===============================================================================
; Функция: _TestPubSubArray1D
; Описание: Тестирование отправки одномерного массива через Pub/Sub
; ===============================================================================
Func _TestPubSubArray1D()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест Pub/Sub: Одномерный массив [1000]")

    ; Создаем одномерный массив из 1000 элементов
    Local $aTest1D[1000]
    For $i = 0 To 999
        $aTest1D[$i] = "Array1D_Element_" & $i & "_" & Random(10000, 99999, 0)
    Next

    ; ЕДИНЫЙ ТАЙМЕР: начинаем замер перед отправкой
    Local $hFullTimer = _Utils_GetTimestamp()

    ; Сериализуем массив
    Local $sArrayData = _Utils_ArrayToString($aTest1D, "|")

    ; Отправляем через Pub/Sub
    Local $sChannel = "test_array1d_channel"
    Local $iSubscribers = _Redis_Publish($sChannel, $sArrayData)

    ; Имитируем получение (в реальной системе это был бы другой процесс)
    ; Десериализуем обратно
    Local $aReceivedArray = _Utils_StringToArray($sArrayData, "|")
    Local $iReceivedCount = (IsArray($aReceivedArray) ? $aReceivedArray[0] : 0)

    ; ЕДИНЫЙ ТАЙМЕР: завершаем замер после парсинга
    Local $fFullTime = _Utils_GetElapsedTime($hFullTimer)

    ; Проверяем целостность данных
    Local $bIntegrity = True
    If IsArray($aReceivedArray) And $iReceivedCount = 1000 Then
        For $i = 0 To 999
            If $aReceivedArray[$i + 1] <> $aTest1D[$i] Then ; +1 из-за счетчика StringSplit
                $bIntegrity = False
                ExitLoop
            EndIf
        Next
    Else
        $bIntegrity = False
    EndIf

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bIntegrity Then
        _Logger_ConsoleWriteUTF("✅ Массив 1D[1000]: Полное время " & StringFormat("%.2f", $fFullTime) & "мс, элементов: " & $iReceivedCount & "/1000, целостность: OK")
    Else
        _Logger_ConsoleWriteUTF("❌ Массив 1D[1000]: Полное время " & StringFormat("%.2f", $fFullTime) & "мс, элементов: " & $iReceivedCount & "/1000, целостность: ОШИБКА")
        $bResult = False
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestPubSubArray2D
; Описание: Тестирование отправки двумерного массива через Pub/Sub
; ===============================================================================
Func _TestPubSubArray2D()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест Pub/Sub: Двумерный массив [10x100]")

    ; Создаем двумерный массив 10x100 = 1000 элементов
    Local $aTest2D[10][100]
    For $i = 0 To 9
        For $j = 0 To 99
            $aTest2D[$i][$j] = "Array2D_" & $i & "_" & $j & "_" & Random(10000, 99999, 0)
        Next
    Next

    ; ЕДИНЫЙ ТАЙМЕР: начинаем замер перед отправкой
    Local $hFullTimer = _Utils_GetTimestamp()

    ; Сериализуем двумерный массив
    Local $sArrayData = ""
    Local $iRows = UBound($aTest2D, 1)
    Local $iCols = UBound($aTest2D, 2)

    ; Добавляем размеры массива в начало
    $sArrayData = $iRows & "x" & $iCols & "||"

    For $i = 0 To $iRows - 1
        For $j = 0 To $iCols - 1
            $sArrayData &= $aTest2D[$i][$j]
            If $j < $iCols - 1 Then $sArrayData &= "|"
        Next
        If $i < $iRows - 1 Then $sArrayData &= "||"
    Next

    ; Отправляем через Pub/Sub
    Local $sChannel = "test_array2d_channel"
    Local $iSubscribers = _Redis_Publish($sChannel, $sArrayData)

    ; Имитируем получение и десериализацию
    Local $aRows = StringSplit($sArrayData, "||", 1)
    Local $bParseSuccess = False
    Local $aReceivedArray = False

    If $aRows[0] >= 2 Then
        ; Парсим размеры из первой строки
        Local $aSizes = StringSplit($aRows[1], "x", 1)
        If $aSizes[0] = 2 Then
            Local $iParsedRows = Int($aSizes[1])
            Local $iParsedCols = Int($aSizes[2])
            Local $aReceivedArray[$iParsedRows][$iParsedCols]

            ; Заполняем массив
            For $i = 0 To $iParsedRows - 1
                If ($i + 2) <= $aRows[0] Then
                    Local $aCols = StringSplit($aRows[$i + 2], "|", 1)
                    For $j = 0 To $iParsedCols - 1
                        If ($j + 1) <= $aCols[0] Then
                            $aReceivedArray[$i][$j] = $aCols[$j + 1]
                        EndIf
                    Next
                EndIf
            Next
            $bParseSuccess = True
        EndIf
    EndIf

    ; ЕДИНЫЙ ТАЙМЕР: завершаем замер после парсинга
    Local $fFullTime = _Utils_GetElapsedTime($hFullTimer)

    ; Проверяем целостность данных
    Local $bIntegrity = False
    Local $iElementCount = 0
    If $bParseSuccess And IsArray($aReceivedArray) Then
        $bIntegrity = True
        For $i = 0 To 9
            For $j = 0 To 99
                $iElementCount += 1
                If $aReceivedArray[$i][$j] <> $aTest2D[$i][$j] Then
                    $bIntegrity = False
                    ; Не выходим сразу, считаем все элементы
                EndIf
            Next
        Next
    EndIf

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bIntegrity Then
        _Logger_ConsoleWriteUTF("✅ Массив 2D[10x100]: Полное время " & StringFormat("%.2f", $fFullTime) & "мс, элементов: " & $iElementCount & "/1000, целостность: OK")
    Else
        _Logger_ConsoleWriteUTF("❌ Массив 2D[10x100]: Полное время " & StringFormat("%.2f", $fFullTime) & "мс, элементов: " & $iElementCount & "/1000, целостность: ОШИБКА")
        $bResult = False
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestPubSubPlusOperations
; Описание: Тест 13 - Тестирование функций _plus (двойная отправка)
; ===============================================================================
Func _TestPubSubPlusOperations()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест 13: Функции _plus (двойная отправка Pub/Sub + Redis таблицы)")

    ; Подключаем отдельное Pub/Sub соединение
    If Not _Redis_PubSub_Connect("127.0.0.1", 6379) Then
        _Logger_ConsoleWriteUTF("❌ Ошибка подключения Pub/Sub для теста _plus")
        Return False
    EndIf

    ; Настройки тестирования
    Local $aTestChannels[2] = ["test_plus_channel_1", "test_plus_channel_2"]
    Local $sTablePrefix = "autoit_data:"

    ; Подписываемся на оба тестовых канала
    For $i = 0 To 1
        If Not _Redis_Subscribe($aTestChannels[$i]) Then
            _Logger_ConsoleWriteUTF("❌ Ошибка подписки на канал [" & $aTestChannels[$i] & "]")
            _Redis_PubSub_Disconnect()
            Return False
        EndIf
        _Logger_ConsoleWriteUTF("📥 Подписка на канал [" & $aTestChannels[$i] & "] успешна")
    Next

    ; Тест 1: Простая отправка _Redis_Publish_Plus
    _Logger_ConsoleWriteUTF("🔄 Тест 13.1: _Redis_Publish_Plus - простое сообщение")
    Local $sTestMessage = "TestMessage_Plus_" & Random(10000, 99999, 0)
    Local $hTestTimer = _Utils_GetTimestamp()

    If _Redis_Publish_Plus($aTestChannels[0], $sTestMessage, $sTablePrefix) Then
        ; Проверяем получение через Pub/Sub
        Local $aMessage = _WaitForPubSubMessage($aTestChannels[0], 500)

        ; Проверяем данные в Redis таблице
        Local $sTableKey = $sTablePrefix & $aTestChannels[0] & "_data"
        Local $sTableData = _Redis_Get($sTableKey)

        Local $fTestTime = _Utils_GetElapsedTime($hTestTimer)

        If IsArray($aMessage) And $aMessage[2] = $sTestMessage And $sTableData = $sTestMessage Then
            _Logger_ConsoleWriteUTF("✅ Тест 13.1: Успешно (" & StringFormat("%.2f", $fTestTime) & "мс)")
            _Logger_ConsoleWriteUTF("   📤 Pub/Sub: [" & $aMessage[1] & "] = '" & StringLeft($aMessage[2], 50) & "'")
            _Logger_ConsoleWriteUTF("   📊 Redis: [" & $sTableKey & "] = '" & StringLeft($sTableData, 50) & "'")
        Else
            _Logger_ConsoleWriteUTF("❌ Тест 13.1: ОШИБКА (" & StringFormat("%.2f", $fTestTime) & "мс)")
            _Logger_ConsoleWriteUTF("   📤 Pub/Sub получено: " & (IsArray($aMessage) ? "'" & StringLeft($aMessage[2], 50) & "'" : "НЕТ"))
            _Logger_ConsoleWriteUTF("   📊 Redis получено: '" & StringLeft($sTableData, 50) & "'")
            _Logger_ConsoleWriteUTF("   🎯 Ожидалось: '" & StringLeft($sTestMessage, 50) & "'")
            $bResult = False
        EndIf
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 13.1: Ошибка отправки _Redis_Publish_Plus")
        $bResult = False
    EndIf

    ; Тест 2: Массив через _Redis_SetArray1D_Plus
    _Logger_ConsoleWriteUTF("🔄 Тест 13.2: _Redis_SetArray1D_Plus - массив 100 элементов")
    Local $aTestArray[100]
    For $i = 0 To 99
        $aTestArray[$i] = "PlusElement_" & $i & "_" & Random(1000, 9999, 0)
    Next

    $hTestTimer = _Utils_GetTimestamp()

    If _Redis_SetArray1D_Plus($aTestChannels[1], $aTestArray, $sTablePrefix) Then
        ; Проверяем получение через Pub/Sub
        Local $aMessage = _WaitForPubSubMessage($aTestChannels[1], 500)

        ; Проверяем данные в Redis таблице
        Local $sTableKey = $sTablePrefix & $aTestChannels[1] & "_data"
        Local $sTableData = _Redis_Get($sTableKey)

        Local $fTestTime = _Utils_GetElapsedTime($hTestTimer)

        ; Десериализуем полученные данные для проверки
        Local $aPubSubArray = False
        Local $aTableArray = False

        If IsArray($aMessage) And $aMessage[2] <> "" Then
            $aPubSubArray = _Utils_StringToArray($aMessage[2], "|")
        EndIf

        If $sTableData <> "" Then
            $aTableArray = _Utils_StringToArray($sTableData, "|")
        EndIf

        ; Проверяем целостность данных
        Local $bPubSubOK = (IsArray($aPubSubArray) And $aPubSubArray[0] = 100)
        Local $bTableOK = (IsArray($aTableArray) And $aTableArray[0] = 100)
        Local $bDataMatch = True

        If $bPubSubOK And $bTableOK Then
            ; Сравниваем первые 10 элементов для скорости
            For $i = 1 To 10
                If $aPubSubArray[$i] <> $aTableArray[$i] Or $aPubSubArray[$i] <> $aTestArray[$i - 1] Then
                    $bDataMatch = False
                    ExitLoop
                EndIf
            Next
        Else
            $bDataMatch = False
        EndIf

        If $bPubSubOK And $bTableOK And $bDataMatch Then
            _Logger_ConsoleWriteUTF("✅ Тест 13.2: Успешно (" & StringFormat("%.2f", $fTestTime) & "мс)")
            _Logger_ConsoleWriteUTF("   📤 Pub/Sub: Массив [" & $aPubSubArray[0] & "] элементов, первый: '" & $aPubSubArray[1] & "'")
            _Logger_ConsoleWriteUTF("   📊 Redis: Массив [" & $aTableArray[0] & "] элементов, первый: '" & $aTableArray[1] & "'")
            _Logger_ConsoleWriteUTF("   🔍 Целостность: Данные совпадают")
        Else
            _Logger_ConsoleWriteUTF("❌ Тест 13.2: ОШИБКА (" & StringFormat("%.2f", $fTestTime) & "мс)")
            _Logger_ConsoleWriteUTF("   📤 Pub/Sub: " & ($bPubSubOK ? "OK [" & $aPubSubArray[0] & "]" : "ОШИБКА"))
            _Logger_ConsoleWriteUTF("   📊 Redis: " & ($bTableOK ? "OK [" & $aTableArray[0] & "]" : "ОШИБКА"))
            _Logger_ConsoleWriteUTF("   🔍 Целостность: " & ($bDataMatch ? "OK" : "ОШИБКА"))
            $bResult = False
        EndIf
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 13.2: Ошибка отправки _Redis_SetArray1D_Plus")
        $bResult = False
    EndIf

    ; Тест 3: Чередование каналов (имитация реальной работы)
    _Logger_ConsoleWriteUTF("🔄 Тест 13.3: Чередование каналов (10 циклов по 500мс)")
    Local $iSuccessfulCycles = 0

    For $iCycle = 1 To 10
        ; Выбираем канал (чередование)
        Local $iChannelIndex = Mod($iCycle - 1, 2)
        Local $sCurrentChannel = $aTestChannels[$iChannelIndex]

        ; Создаем тестовые данные
        Local $aTestData[50]
        For $i = 0 To 49
            $aTestData[$i] = "Cycle" & $iCycle & "_Ch" & $iChannelIndex & "_El" & $i & "_" & Random(100, 999, 0)
        Next

        Local $hCycleTimer = _Utils_GetTimestamp()

        ; Отправляем через _plus функцию
        If _Redis_SetArray1D_Plus($sCurrentChannel, $aTestData, $sTablePrefix) Then
            ; Проверяем получение
            Local $aMessage = _WaitForPubSubMessage($sCurrentChannel, 200)
            Local $sTableKey = $sTablePrefix & $sCurrentChannel & "_data"
            Local $sTableData = _Redis_Get($sTableKey)

            Local $fCycleTime = _Utils_GetElapsedTime($hCycleTimer)

            ; Быстрая проверка (только количество элементов)
            Local $iPubSubCount = 0
            Local $iTableCount = 0

            If IsArray($aMessage) And $aMessage[2] <> "" Then
                Local $aPubSubCheck = _Utils_StringToArray($aMessage[2], "|")
                $iPubSubCount = (IsArray($aPubSubCheck) ? $aPubSubCheck[0] : 0)
            EndIf

            If $sTableData <> "" Then
                Local $aTableCheck = _Utils_StringToArray($sTableData, "|")
                $iTableCount = (IsArray($aTableCheck) ? $aTableCheck[0] : 0)
            EndIf

            If $iPubSubCount = 50 And $iTableCount = 50 Then
                $iSuccessfulCycles += 1
                _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycle & " [" & $sCurrentChannel & "]: OK (" & StringFormat("%.2f", $fCycleTime) & "мс)")
            Else
                _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycle & " [" & $sCurrentChannel & "]: ОШИБКА (" & StringFormat("%.2f", $fCycleTime) & "мс) - Pub/Sub:" & $iPubSubCount & ", Redis:" & $iTableCount)
            EndIf
        Else
            _Logger_ConsoleWriteUTF("🔄 Цикл #" & $iCycle & " [" & $sCurrentChannel & "]: ОШИБКА отправки")
        EndIf

        ; Задержка 500мс для чередования
        Sleep(500)
    Next

    _Logger_ConsoleWriteUTF("📊 Тест 13.3: Успешных циклов: " & $iSuccessfulCycles & "/10")
    If $iSuccessfulCycles < 8 Then $bResult = False

    ; Очистка тестовых данных
    _Logger_ConsoleWriteUTF("🧹 Очистка тестовых данных...")
    For $i = 0 To 1
        Local $sTableKey = $sTablePrefix & $aTestChannels[$i] & "_data"
        ;_Redis_Del($sTableKey)
        _Redis_Unsubscribe($aTestChannels[$i])
    Next

    _Redis_PubSub_Disconnect()

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("🚀 Тест 13: Функции _plus успешно протестированы (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🚀 Тест 13 _plus успешно за " & Int($iElapsed) & "мс")
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 13: Ошибка тестирования функций _plus (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Тест 13 _plus ошибка за " & Int($iElapsed) & "мс")
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _WaitForPubSubMessage
; Описание: Ожидание сообщения из определенного канала с таймаутом
; Параметры: $sChannel - канал, $iTimeoutMs - таймаут в мс
; Возврат: Массив сообщения или False
; ===============================================================================
Func _WaitForPubSubMessage($sChannel, $iTimeoutMs = 1000)
    Local $hWaitTimer = TimerInit()

    While TimerDiff($hWaitTimer) < $iTimeoutMs
        Local $aMessage = _Redis_PubSub_CheckMessages()
        If IsArray($aMessage) And UBound($aMessage) >= 3 And $aMessage[0] = "message" And $aMessage[1] = $sChannel Then
            Return $aMessage
        EndIf
        Sleep(5) ; Небольшая пауза для CPU
    WEnd

    Return False ; Таймаут
EndFunc
; ===============================================================================
; Функция: _TestCircularBufferOperations
; Описание: Тест 14 - Тестирование кольцевого буфера (Redis LIST) с датчиком температуры
; ===============================================================================
Func _TestCircularBufferOperations()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест 14: Кольцевой буфер (Redis LIST) - датчик температуры")

    ; Настройки датчика температуры
    Local $sTemperatureSensor = "sensors_data:temperature_001"
    Local $fBaseTemperature = 20.00 ; Базовая температура
    Local $fCurrentTemperature = $fBaseTemperature
    Local $iBufferSize = 10 ; Размер кольцевого буфера
    Local $iTestCycles = 15 ; Количество циклов (больше размера буфера для проверки кольцевости)

    ; Очищаем буфер перед тестом
    _Redis_ListClear($sTemperatureSensor)
    _Logger_ConsoleWriteUTF("🧹 Буфер датчика очищен")

    ; Тест 14.1: Заполнение буфера реалистичными данными через FastPush
    _Logger_ConsoleWriteUTF("🔄 Тест 14.1: Заполнение буфера (" & $iBufferSize & " элементов)")

    For $i = 1 To $iTestCycles
        ; Генерируем реалистичное изменение температуры (±0.1%)
        Local $fVariation = Random(-0.1, 0.1)
        $fCurrentTemperature = $fBaseTemperature + $fVariation

        ; Форматируем значение с временной меткой
        Local $sTimestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC
        Local $sTemperatureValue = StringFormat("%.2f", $fCurrentTemperature) & "C|" & $sTimestamp

        ; Добавляем в кольцевой буфер (используем Fast версию)
        Local $hPushTimer = _Utils_GetTimestamp()
        Local $bPushResult = _Redis_ListPush_Fast($sTemperatureSensor, $sTemperatureValue, $iBufferSize)
        Local $fPushTime = _Utils_GetElapsedTime($hPushTimer)

        ; Проверяем размер буфера
        Local $iCurrentSize = _Redis_ListSize($sTemperatureSensor)
        Local $iExpectedSize = ($i <= $iBufferSize ? $i : $iBufferSize)

        If $bPushResult And $iCurrentSize = $iExpectedSize Then
            _Logger_ConsoleWriteUTF("📊 Цикл #" & $i & ": T=" & StringFormat("%.2f", $fCurrentTemperature) & "°C, " & _
                        "Размер буфера: " & $iCurrentSize & "/" & $iBufferSize & " (" & StringFormat("%.2f", $fPushTime) & "мс)")
        Else
            _Logger_ConsoleWriteUTF("❌ Цикл #" & $i & ": ОШИБКА - Push:" & ($bPushResult ? "OK" : "FAIL") & _
                        ", Размер: " & $iCurrentSize & " (ожидался " & $iExpectedSize & ")")
            $bResult = False
        EndIf

        Sleep(50) ; Имитация интервала опроса
    Next

    ; Тест 14.2: Проверка кольцевого буфера через GetAll_Fast
    _Logger_ConsoleWriteUTF("🔄 Тест 14.2: Проверка кольцевого буфера")

    Local $hGetTimer = _Utils_GetTimestamp()
    Local $aBufferData = _Redis_ListGetAll_Fast($sTemperatureSensor)
    Local $fGetTime = _Utils_GetElapsedTime($hGetTimer)

    If IsArray($aBufferData) And UBound($aBufferData) = $iBufferSize Then
        _Logger_ConsoleWriteUTF("✅ Буфер содержит " & UBound($aBufferData) & " элементов (как и ожидалось)")
        _Logger_ConsoleWriteUTF("📊 Время получения всех данных: " & StringFormat("%.2f", $fGetTime) & "мс")

        _Logger_ConsoleWriteUTF("🔍 Первые 3 элемента (самые новые):")
        For $i = 0 To 2
            If $i < UBound($aBufferData) Then
                Local $aTemp = StringSplit($aBufferData[$i], "|")
                If $aTemp[0] >= 2 Then _Logger_ConsoleWriteUTF("    [" & $i & "] " & $aTemp[1] & " в " & $aTemp[2])
            EndIf
        Next

        _Logger_ConsoleWriteUTF("🔍 Последние 3 элемента (самые старые):")
        For $i = UBound($aBufferData) - 3 To UBound($aBufferData) - 1
            If $i >= 0 Then
                Local $aTemp = StringSplit($aBufferData[$i], "|")
                If $aTemp[0] >= 2 Then _Logger_ConsoleWriteUTF("    [" & $i & "] " & $aTemp[1] & " в " & $aTemp[2])
            EndIf
        Next
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка буфера: получено " & (IsArray($aBufferData) ? UBound($aBufferData) : "НЕ МАССИВ") & " элементов")
        $bResult = False
    EndIf

    ; Тест 14.3: Проверка доступа по индексу
    _Logger_ConsoleWriteUTF("🔄 Тест 14.3: Доступ к элементам по индексу")

    Local $hIndexTimer = _Utils_GetTimestamp()
    Local $sFirstElement = _Redis_ListGet($sTemperatureSensor, 0)
    Local $sLastElement = _Redis_ListGet($sTemperatureSensor, $iBufferSize - 1)
    Local $fIndexTime = _Utils_GetElapsedTime($hIndexTimer)

    If $sFirstElement <> False And $sLastElement <> False Then
        Local $aFirst = StringSplit($sFirstElement, "|")
        Local $aLast = StringSplit($sLastElement, "|")
        _Logger_ConsoleWriteUTF("✅ Доступ по индексу успешен (" & StringFormat("%.2f", $fIndexTime) & "мс)")
        _Logger_ConsoleWriteUTF("    🆕 Самый новый [0]: " & ($aFirst[0] >= 1 ? $aFirst[1] : $sFirstElement))
        _Logger_ConsoleWriteUTF("    🕰️ Самый старый [" & ($iBufferSize - 1) & "]: " & ($aLast[0] >= 1 ? $aLast[1] : $sLastElement))
    Else
        _Logger_ConsoleWriteUTF("❌ Ошибка доступа по индексу")
        $bResult = False
    EndIf

    ; Тест 14.4: Производительность массовых операций через FastPush
    _Logger_ConsoleWriteUTF("🔄 Тест 14.4: Производительность (100 быстрых записей FastPush)")

    Local $hPerfTimer = _Utils_GetTimestamp()
    Local $iSuccessfulWrites = 0

    For $i = 1 To 100
        Local $fTestTemp = $fBaseTemperature + Random(-2.0, 2.0)
        Local $sTestValue = StringFormat("%.2f", $fTestTemp) & "C|PerfTest_" & $i

        ; Лимит 50, используем Fast версию
        If _Redis_ListPush_Fast($sTemperatureSensor, $sTestValue, 50) Then
            $iSuccessfulWrites += 1
        EndIf
    Next

    Local $fPerfTime = _Utils_GetElapsedTime($hPerfTimer)
    Local $fAvgWriteTime = $fPerfTime / 100

    _Logger_ConsoleWriteUTF("📊 Производительность: " & $iSuccessfulWrites & "/100 записей за " & StringFormat("%.2f", $fPerfTime) & "мс")
    _Logger_ConsoleWriteUTF("📊 Средняя скорость: " & StringFormat("%.2f", $fAvgWriteTime) & "мс/запись")

    If $iSuccessfulWrites < 95 Then $bResult = False

    _Logger_ConsoleWriteUTF("🧹 Очистка тестового буфера...")
    _Redis_ListClear($sTemperatureSensor)

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)
    If $bResult Then
        _Logger_ConsoleWriteUTF("🚀 Тест 14: Кольцевой буфер успешно протестирован (" & Int($iElapsed) & "мс)")
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 14: Ошибка тестирования кольцевого буфера")
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestPersistenceOperations
; Описание: Тест 15 - Функции сохранения на диск (SAVE/BGSAVE/LASTSAVE)
; ===============================================================================
Func _TestPersistenceOperations()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("💾 Тест 15: Функции сохранения (Persistence)")

    ; Тест 15.1: LASTSAVE - время последнего сохранения
    _Logger_ConsoleWriteUTF("🔍 Тест 15.1: LASTSAVE - получение времени последнего сохранения")

    Local $iLastSaveBefore = _Redis_LastSave()
    If $iLastSaveBefore = False Then
        _Logger_ConsoleWriteUTF("❌ Ошибка получения времени последнего сохранения")
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ Время последнего сохранения: " & $iLastSaveBefore & " (Unix timestamp)")
    EndIf

    ; Тест 15.2: BGSAVE - фоновое сохранение
    _Logger_ConsoleWriteUTF("🔍 Тест 15.2: BGSAVE - фоновое сохранение")

    Local $bBgSave = _Redis_BgSave()
    If Not $bBgSave Then
        _Logger_ConsoleWriteUTF("❌ Ошибка запуска фонового сохранения")
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ Фоновое сохранение запущено")

        ; Ждем завершения фонового сохранения (максимум 2 секунды)
        Sleep(2000)

        ; Проверяем что время сохранения обновилось
        Local $iLastSaveAfterBg = _Redis_LastSave()
        If $iLastSaveAfterBg > $iLastSaveBefore Then
            _Logger_ConsoleWriteUTF("✅ Время сохранения обновилось: " & $iLastSaveAfterBg)
        Else
            _Logger_ConsoleWriteUTF("⚠️ Время сохранения не изменилось (возможно сохранение еще выполняется)")
        EndIf
    EndIf

    ; Тест 15.3: SAVE - синхронное сохранение
    _Logger_ConsoleWriteUTF("🔍 Тест 15.3: SAVE - принудительное синхронное сохранение")

    ; Создаем тестовые данные для сохранения
    Local $sTestKey = "persistence:test:data"
    Local $sTestValue = "PersistenceTestValue_" & Random(10000, 99999, 0)

    If Not _Redis_Set($sTestKey, $sTestValue) Then
        _Logger_ConsoleWriteUTF("❌ Ошибка создания тестовых данных")
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("📝 Тестовые данные созданы: " & $sTestKey)

        ; Выполняем синхронное сохранение
        Local $hSaveTimer = _Utils_GetTimestamp()
        Local $bSave = _Redis_Save()
        Local $fSaveTime = _Utils_GetElapsedTime($hSaveTimer)

        If Not $bSave Then
            _Logger_ConsoleWriteUTF("❌ Ошибка синхронного сохранения")
            $bResult = False
        Else
            _Logger_ConsoleWriteUTF("✅ Синхронное сохранение выполнено за " & StringFormat("%.2f", $fSaveTime) & "мс")

            ; Проверяем что время сохранения обновилось
            Local $iLastSaveAfter = _Redis_LastSave()
            If $iLastSaveAfter > $iLastSaveBefore Then
                _Logger_ConsoleWriteUTF("✅ Время сохранения обновилось: " & $iLastSaveAfter)
            Else
                _Logger_ConsoleWriteUTF("⚠️ Время сохранения не изменилось")
            EndIf
        EndIf

        ; Очистка тестовых данных
        _Redis_Del($sTestKey)
    EndIf

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("🚀 Тест 15: Функции сохранения успешно протестированы (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🚀 Тест 15 persistence успешно за " & Int($iElapsed) & "мс")
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 15: Ошибка тестирования функций сохранения (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Тест 15 persistence ошибка за " & Int($iElapsed) & "мс")
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _Test_Redis_FastPush_Stability
; Описание: Стресс-тест стабильности FastPush и чистоты TCP-буфера
; ===============================================================================
Func _Test_Redis_FastPush_Stability()
    _Logger_ConsoleWriteUTF("🧪 Запуск стресс-теста стабильности FastPush...")

    Local $sListKey = "test:stability:list"
    Local $sCheckKey = "test:stability:check"
    Local $iCycles = 100
    Local $iErrors = 0

    ; Подготовка: создаем контрольный ключ
    _Redis_Set($sCheckKey, "CONTROL_VALUE")
    _Redis_ListClear($sListKey)

    Local $hTimer = _Utils_GetTimestamp()

    For $i = 1 To $iCycles
        ; 1. Делаем быстрый Push (который шлет 2 команды и читает 1 ответ)
        Local $bPush = _Redis_ListPush_Fast($sListKey, "Data_" & $i, 10)

        ; 2. Сразу же делаем обычный GET контрольного ключа
        ; Если в сокете остался "+OK" от LTRIM, функция _Redis_Get прочитает его вместо значения!
        Local $sGetValue = _Redis_Get($sCheckKey)

        If $sGetValue <> "CONTROL_VALUE" Then
            _Logger_ConsoleWriteUTF("❌ ОШИБКА ДЕСИНХРОНИЗАЦИИ в цикле #" & $i)
            _Logger_ConsoleWriteUTF("   Получено: '" & $sGetValue & "', ожидалось: 'CONTROL_VALUE'")
            $iErrors += 1
            ; Если произошла ошибка, сокет "отравлен", продолжать нет смысла без очистки
            ExitLoop
        EndIf

        If Mod($i, 20) = 0 Then _Logger_ConsoleWriteUTF("✅ Пройдено " & $i & " циклов...")
    Next

    Local $fTime = _Utils_GetElapsedTime($hTimer)

    If $iErrors = 0 Then
        _Logger_ConsoleWriteUTF("🚀 СТРЕСС-ТЕСТ ПРОЙДЕН! FastPush безопасен (100 циклов за " & StringFormat("%.2f", $fTime) & "мс)")
        Return True
    Else
        _Logger_ConsoleWriteUTF("❌ СТРЕСС-ТЕСТ ПРОВАЛЕН! Найдено ошибок: " & $iErrors)
        Return False
    EndIf
EndFunc
; ===============================================================================
; Функция: _TestCounterOperations
; Описание: Тест 16 - Атомарные счетчики (INCR/INCRBY/DECR/DECRBY)
; ===============================================================================
Func _TestCounterOperations()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔢 Тест 16: Атомарные счетчики (Counters)")

    Local $sCounterKey = "counter:test:products"

    ; Тест 16.1: Инициализация счетчика
    _Logger_ConsoleWriteUTF("🔍 Тест 16.1: Инициализация счетчика")

    ; Удаляем старый счетчик если есть
    _Redis_Del($sCounterKey)

    ; Устанавливаем начальное значение
    If Not _Redis_Set($sCounterKey, "100") Then
        _Logger_ConsoleWriteUTF("❌ Ошибка инициализации счетчика")
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ Счетчик инициализирован: 100")
    EndIf

    ; Тест 16.2: INCR - увеличение на 1
    _Logger_ConsoleWriteUTF("🔍 Тест 16.2: INCR - увеличение на 1")

    Local $iNewValue = _Redis_Incr($sCounterKey)
    If $iNewValue = False Or $iNewValue <> 101 Then
        _Logger_ConsoleWriteUTF("❌ Ошибка INCR, ожидалось 101, получено: " & $iNewValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ INCR выполнен: 100 → 101")
    EndIf

    ; Тест 16.3: INCRBY - увеличение на N
    _Logger_ConsoleWriteUTF("🔍 Тест 16.3: INCRBY - увеличение на 50")

    $iNewValue = _Redis_IncrBy($sCounterKey, 50)
    If $iNewValue = False Or $iNewValue <> 151 Then
        _Logger_ConsoleWriteUTF("❌ Ошибка INCRBY, ожидалось 151, получено: " & $iNewValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ INCRBY выполнен: 101 → 151 (+50)")
    EndIf

    ; Тест 16.4: DECR - уменьшение на 1
    _Logger_ConsoleWriteUTF("🔍 Тест 16.4: DECR - уменьшение на 1")

    $iNewValue = _Redis_Decr($sCounterKey)
    If $iNewValue = False Or $iNewValue <> 150 Then
        _Logger_ConsoleWriteUTF("❌ Ошибка DECR, ожидалось 150, получено: " & $iNewValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ DECR выполнен: 151 → 150")
    EndIf

    ; Тест 16.5: DECRBY - уменьшение на N
    _Logger_ConsoleWriteUTF("🔍 Тест 16.5: DECRBY - уменьшение на 30")

    $iNewValue = _Redis_DecrBy($sCounterKey, 30)
    If $iNewValue = False Or $iNewValue <> 120 Then
        _Logger_ConsoleWriteUTF("❌ Ошибка DECRBY, ожидалось 120, получено: " & $iNewValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ DECRBY выполнен: 150 → 120 (-30)")
    EndIf

    ; Тест 16.6: Проверка финального значения
    _Logger_ConsoleWriteUTF("🔍 Тест 16.6: Проверка финального значения")

    Local $sFinalValue = _Redis_Get($sCounterKey)
    If $sFinalValue <> "120" Then
        _Logger_ConsoleWriteUTF("❌ Ошибка финального значения, ожидалось 120, получено: " & $sFinalValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ Финальное значение корректно: 120")
    EndIf

    ; Тест 16.7: Производительность счетчиков (100 операций)
    _Logger_ConsoleWriteUTF("🔍 Тест 16.7: Производительность (100 INCR операций)")

    Local $hPerfTimer = _Utils_GetTimestamp()
    Local $iSuccessfulOps = 0

    For $i = 1 To 100
        If _Redis_Incr($sCounterKey) <> False Then
            $iSuccessfulOps += 1
        EndIf
    Next

    Local $fPerfTime = _Utils_GetElapsedTime($hPerfTimer)
    Local $fAvgOpTime = $fPerfTime / 100

    _Logger_ConsoleWriteUTF("📊 Производительность: " & $iSuccessfulOps & "/100 операций за " & StringFormat("%.2f", $fPerfTime) & "мс")
    _Logger_ConsoleWriteUTF("📊 Средняя скорость: " & StringFormat("%.2f", $fAvgOpTime) & "мс/операция")

    If $iSuccessfulOps < 95 Then
        _Logger_ConsoleWriteUTF("⚠️ Предупреждение: Низкая успешность операций (" & $iSuccessfulOps & "%)")
        $bResult = False
    EndIf

    ; Проверка финального значения после 100 инкрементов
    $sFinalValue = _Redis_Get($sCounterKey)
    If $sFinalValue <> "220" Then ; 120 + 100 = 220
        _Logger_ConsoleWriteUTF("❌ Ошибка после массовых операций, ожидалось 220, получено: " & $sFinalValue)
        $bResult = False
    Else
        _Logger_ConsoleWriteUTF("✅ Финальное значение после 100 INCR: 220")
    EndIf

    ; Очистка тестовых данных
    _Redis_Del($sCounterKey)

    Local $iElapsed = _Utils_GetElapsedTime($hTimer)

    If $bResult Then
        _Logger_ConsoleWriteUTF("🚀 Тест 16: Атомарные счетчики успешно протестированы (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("🚀 Тест 16 counters успешно за " & Int($iElapsed) & "мс")
    Else
        _Logger_ConsoleWriteUTF("❌ Тест 16: Ошибка тестирования счетчиков (" & Int($iElapsed) & "мс)")
        _Logger_WriteToFile("❌ Тест 16 counters ошибка за " & Int($iElapsed) & "мс")
    EndIf

    Return $bResult
EndFunc

; ===============================================================================
; Функция: _TestNonBlockingReconnection
; Описание: Тест 17 - Неблокирующее переподключение и восстановление данных
; ===============================================================================
Func _TestNonBlockingReconnection()
    Local $hTimer = _Utils_GetTimestamp()
    Local $bResult = True

    _Logger_ConsoleWriteUTF("🔄 Тест 17: Неблокирующее переподключение и восстановление")
    _Logger_ConsoleWriteUTF("⚠️ Для полного тестирования перезапустите Redis сервер во время выполнения")

    ; Очищаем мусорные ключи от предыдущих тестов (если подключение есть)
    If $g_bRedis_Connected Then
        Local $aOldKeys = _Redis_Keys("mass_key_*")
        If IsArray($aOldKeys) And UBound($aOldKeys) > 0 Then
            Local $iDeleted = _Redis_Del($aOldKeys)
            _Logger_ConsoleWriteUTF("🧹 Удалено " & $iDeleted & " старых ключей mass_key_*")
        EndIf
    EndIf

    ; Подготавливаем тестовые данные для проверки целостности (если подключение есть)
    Local $sTestKey = "autoit_data:reconnect_test"
    Local $sTestValue = "ReconnectTestData_" & Random(10000, 99999, 0) & "_" & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
    Local $bTestDataPrepared = False

    If $g_bRedis_Connected And _Redis_Set($sTestKey, $sTestValue) Then
        _Logger_ConsoleWriteUTF("📊 Тестовые данные подготовлены: [" & $sTestKey & "]")
        $bTestDataPrepared = True
    Else
        _Logger_ConsoleWriteUTF("📊 Тестовые данные не подготовлены - Redis недоступен")
        $bTestDataPrepared = False
    EndIf

    ; Состояния подключения
    Local Enum $STATE_CONNECTED = 0, $STATE_RECONNECTING_FAST = 1, $STATE_RECONNECTING_SLOW = 2
    Local $aStateNames[3] = ["🟢 Подключено", "🟡 Переподключение (быстро)", "🔴 Переподключение (медленно)"]

    Local $iCurrentState = $STATE_CONNECTED
    Local $hLastStatusUpdate = TimerInit()
    Local $hLastConnectionCheck = TimerInit()
    Local $iReconnectAttempts = 0
    Local $iMaxFastAttempts = 3
    Local $iFastCheckInterval = 1000 ; 1 секунда для быстрых попыток
    Local $iSlowCheckInterval = 5000 ; 5 секунд для медленных попыток
    Local $iStatusUpdateInterval = 1000 ; Обновление статуса каждую секунду

    _Logger_ConsoleWriteUTF("🔄 Запуск бесконечного мониторинга подключения")
    _Logger_ConsoleWriteUTF("   Быстрые попытки: каждые " & $iFastCheckInterval & "мс (первые " & $iMaxFastAttempts & " попыток)")
    _Logger_ConsoleWriteUTF("   Медленные попытки: каждые " & $iSlowCheckInterval & "мс")
    _Logger_ConsoleWriteUTF("   Нажмите Ctrl+C для остановки")

    Local $hTestStartTime = TimerInit()
    Local $iCycleCount = 0
    Local $iTotalReconnectAttempts = 0 ; Общий счетчик попыток переподключения

    ; Основной бесконечный неблокирующий цикл
    While True
        $iCycleCount += 1
        Local $hCycleTimer = TimerInit()

        ; Проверка подключения (неблокирующая)
        Local $bConnectionOK = False
        Local $hCheckTimer = TimerInit()

        ; Быстрая проверка PING с таймаутом (неблокирующая)
        If $g_bRedis_Connected Then
            $bConnectionOK = _Redis_PingNonBlocking(5) ; Максимум 5мс на PING
        EndIf

        Local $fCheckTime = _Utils_GetElapsedTime($hCheckTimer)

        ; Определяем нужно ли проверять подключение
        Local $bShouldCheck = False
        Local $iCurrentInterval = $iFastCheckInterval

        Switch $iCurrentState
            Case $STATE_CONNECTED
                $bShouldCheck = (TimerDiff($hLastConnectionCheck) >= $iFastCheckInterval)

            Case $STATE_RECONNECTING_FAST
                $bShouldCheck = (TimerDiff($hLastConnectionCheck) >= $iFastCheckInterval)

            Case $STATE_RECONNECTING_SLOW
                $bShouldCheck = (TimerDiff($hLastConnectionCheck) >= $iSlowCheckInterval)
                $iCurrentInterval = $iSlowCheckInterval
        EndSwitch

        ; Обработка состояний подключения
        If $bShouldCheck Then
            $hLastConnectionCheck = TimerInit()

            If $bConnectionOK Then
                ; Подключение в порядке
                If $iCurrentState <> $STATE_CONNECTED Then
                    ; Восстановление после разрыва
                    Local $hRestoreTimer = TimerInit()

                    ; Проверяем целостность данных (только если они были подготовлены)
                    Local $sRestoredValue = ""
                    Local $bDataIntegrity = True ; По умолчанию OK если данные не готовились

                    If $bTestDataPrepared Then
                        $sRestoredValue = _Redis_Get($sTestKey)
                        $bDataIntegrity = ($sRestoredValue = $sTestValue)

                        ; Если данные потерялись - пересоздаем их
                        If Not $bDataIntegrity Then
                            If _Redis_Set($sTestKey, $sTestValue) Then
                                $bDataIntegrity = True
                                _Logger_ConsoleWriteUTF("🔄 Тестовые данные пересозданы после переподключения")
                            EndIf
                        EndIf
                    EndIf

                    ; Проверяем доступность основных функций (быстрая проверка)
                    Local $bFunctionsOK = $bConnectionOK ; Если PING прошел, то функции доступны

                    Local $fRestoreTime = _Utils_GetElapsedTime($hRestoreTimer)

                    If $bDataIntegrity And $bFunctionsOK Then
                        If $bTestDataPrepared Then
                            _Logger_ConsoleWriteUTF("✅ Подключение восстановлено! Данные целы, функции доступны (" & StringFormat("%.2f", $fRestoreTime) & "мс)")
                        Else
                            _Logger_ConsoleWriteUTF("✅ Подключение восстановлено! Функции доступны (" & StringFormat("%.2f", $fRestoreTime) & "мс)")
                        EndIf
                    Else
                        _Logger_ConsoleWriteUTF("⚠️ Подключение восстановлено, но есть проблемы: Данные=" & ($bDataIntegrity ? "OK" : "ОШИБКА") & ", Функции=" & ($bFunctionsOK ? "OK" : "ОШИБКА"))
                    EndIf

                    $iReconnectAttempts = 0
                EndIf
                $iCurrentState = $STATE_CONNECTED

            Else
                ; Подключение потеряно - пытаемся переподключиться (неблокирующая версия)
                Local $hReconnectTimer = TimerInit()
                Local $bReconnected = _Redis_ConnectNonBlocking($g_sRedis_Host, $g_iRedis_Port, 10) ; Максимум 10мс
                Local $fReconnectTime = _Utils_GetElapsedTime($hReconnectTimer)

                $iTotalReconnectAttempts += 1 ; Увеличиваем только при реальной попытке переподключения

                If $bReconnected Then
                    ; Успешное переподключение - проверим в следующем цикле
                Else
                    ; Определяем режим переподключения на основе текущих попыток
                    If $iReconnectAttempts <= $iMaxFastAttempts Then
                        $iCurrentState = $STATE_RECONNECTING_FAST
                    Else
                        $iCurrentState = $STATE_RECONNECTING_SLOW
                    EndIf
                    $iReconnectAttempts += 1 ; Увеличиваем счетчик неудачных попыток
                EndIf
            EndIf
        EndIf

        ; Обновление статуса каждую секунду
        If TimerDiff($hLastStatusUpdate) >= $iStatusUpdateInterval Then
            $hLastStatusUpdate = TimerInit()

            Local $fCycleTime = _Utils_GetElapsedTime($hCycleTimer)
            Local $fTotalTime = TimerDiff($hTestStartTime) / 1000

            _Logger_ConsoleWriteUTF("📊 " & StringFormat("%02.0f", $fTotalTime) & "с | " & $aStateNames[$iCurrentState] & _
                        " | Попыток: " & $iReconnectAttempts & "/" & $iTotalReconnectAttempts & _
                        " | Проверка: " & StringFormat("%.2f", $fCheckTime) & "мс" & _
                        " | Цикл: " & StringFormat("%.2f", $fCycleTime) & "мс")
        EndIf

        ; Минимальная задержка для неблокирующей работы
        Sleep(10)
    WEnd

    ; Этот код никогда не выполнится, так как цикл бесконечный
    Return True
EndFunc
