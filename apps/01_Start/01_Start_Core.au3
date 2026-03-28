; ===============================================================================
; 01_Start_Core.au3
; Описание: Ядро приложения 01_Start - система точного таймера
; Версия: 1.0.0
; ===============================================================================

; ===============================================================================
; СПИСОК ФУНКЦИЙ:
; - _Core_Timer_Init() - Инициализация системы таймера
; - _Core_Timer_Check() - Проверка интервала и запуск цикла
; - _Core_Timer_End() - Завершение цикла, замер нагрузки, логирование
; - _Core_Timer_Task() - Тестовая функция с рандомной задержкой
; - _Core_Timer_TestDLL() - Тест точности _HighPrecisionSleep
; - _HighPrecisionSleep($iMicroSeconds, $hDll) - Микрозадержка через ntdll.dll
; ===============================================================================

#include-once
#include "..\..\libs\Utils\Utils.au3"



; === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ТАЙМЕРА ===
Global $g_hCore_DLL = 0                            ; Handle DLL для точного Sleep
Global $g_iCore_Interval = 1000                    ; Текущий интервал (мс)
Global $g_iCore_IntervalOriginal = 1000            ; Оригинальный интервал (мс)
Global $g_iCore_SyncOffset = 100                   ; Смещение синхронизации (мс) - привязка к .100
Global $g_iCore_Counter = 0                        ; Счётчик итераций
Global $g_iCore_StartTime = 0                      ; Время входа в цикл (мс)
Global $g_iCore_LastTickTime = 0                   ; Время предыдущего такта (для расчёта интервала)
Global $g_aCore_IntervalHistory[10]               ; Массив последних 10 интервалов
Global $g_iCore_HistoryIndex = 0                   ; Индекс для записи в массив
Global $g_fCore_TotalLoad = 0                      ; Сумма времени обработки (мс)
Global $g_iCore_Iterations = 0                     ; Количество замеров для статистики
Global $g_iCore_LastLogTime = 0                    ; Время последнего лога (мс)
Global $g_iCore_LogInterval = 10000                ; Интервал логов 10 сек
Global $g_iCore_PredictiveThreshold = 10           ; Порог активного ожидания (мс)

; === НАГОНКА ТАКТОВ (CatchUp) ===
Global $g_bCore_CatchUp = False                    ; Флаг нагонки (включить через _Core_Timer_Init)
Global $g_iCore_StartUnixMS = 0                    ; Unix timestamp старта в мс
Global $g_iCore_CatchUp_Count = 0                  ; Счётчик нагнанных тактов (для лога)

; ===============================================================================
; Функция: _Core_Timer_Init
; Описание: Инициализация системы таймера с синхронизацией по .100
; Параметры:
;   $iInterval - интервал такта в мс (по умолчанию 1000)
;   $bCatchUp  - включить нагонку пропущенных тактов (по умолчанию False)
; Возврат: True при успехе, False при ошибке
; Пример: _Core_Timer_Init(1000, True)
; ===============================================================================
Func _Core_Timer_Init($iInterval = 1000, $bCatchUp = False)
	; Применяем переданный интервал
	$g_iCore_Interval = $iInterval
	$g_iCore_IntervalOriginal = $iInterval

	; Режим нагонки
	$g_bCore_CatchUp = $bCatchUp
	; === УСТАНАВЛИВАЕМ ВЫСОКОЕ РАЗРЕШЕНИЕ ТАЙМЕРА (1мс) ===
	DllCall("winmm.dll", "uint", "timeBeginPeriod", "uint", 1)
	_Logger_Write("[Core] Установлено разрешение таймера: 1мс (timeBeginPeriod)", 1)

	; Открываем DLL для точного Sleep
	$g_hCore_DLL = DllOpen("ntdll.dll")
	If $g_hCore_DLL = -1 Then
		_Logger_Write("❌ Ошибка открытия ntdll.dll для точного Sleep", 2)
		Return False
	EndIf

	; === ТЕСТ ТОЧНОСТИ DLL ===
	If Not _Core_Timer_TestDLL() Then
		_Logger_Write("⚠️ Предупреждение: точность _HighPrecisionSleep может быть недостаточной", 2)
	EndIf

	; === СИНХРОНИЗАЦИЯ С ЭТАЛОНОМ .100 ===
	Local $iNow = _Utils_GetUnixTimestampMS()
	Local $iMs = Mod($iNow, 1000)
	Local $iWaitTime = 0

	If $iMs < $g_iCore_SyncOffset Then
		$iWaitTime = $g_iCore_SyncOffset - $iMs
	Else
		$iWaitTime = (1000 - $iMs) + $g_iCore_SyncOffset
	EndIf

	_Logger_Write(StringFormat("[Core] Синхронизация с эталоном .%d (ожидание %dмс)", $g_iCore_SyncOffset, $iWaitTime), 1)
	Sleep($iWaitTime)

	; Инициализируем переменные
	$g_iCore_LastLogTime = _Utils_GetUnixTimestampMS()
	$g_iCore_LastTickTime = 0
	$g_iCore_Counter = 0
	$g_iCore_HistoryIndex = 0
	$g_iCore_CatchUp_Count = 0
	$g_iCore_StartUnixMS = _Utils_GetUnixTimestampMS() ; Точка отсчёта для нагонки

	For $i = 0 To 9
		$g_aCore_IntervalHistory[$i] = 0
	Next

	; Регистрируем функцию очистки при выходе
	OnAutoItExitRegister("_Core_Timer_Cleanup")

	_Logger_Write("✅ Core Timer инициализирован (интервал: " & $g_iCore_Interval & "мс, метод: ntdll+timeBeginPeriod)", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Core_Timer_Check
; Описание: Проверка интервала с привязкой к .100 каждой секунды
; Параметры: Нет
; Возврат: True если пора выполнять код, False если ещё рано
; Пример: If _Core_Timer_Check() Then ... EndIf
; ===============================================================================
Func _Core_Timer_Check()
	Local $iNow = _Utils_GetUnixTimestampMS()

	; === РЕЖИМ НАГОНКИ (CatchUp) ===
	; Считаем сколько тактов должно было произойти с момента старта
	; Если реальный счётчик отстаёт — нагоняем немедленно без ожидания
	If $g_bCore_CatchUp Then
		Local $iElapsed = $iNow - $g_iCore_StartUnixMS
		Local $iExpected = Floor($iElapsed / $g_iCore_IntervalOriginal)
		If $iExpected > $g_iCore_Counter Then
			; Есть отставание — нагоняем
			$g_iCore_CatchUp_Count += 1
			$g_iCore_LastTickTime = $iNow
			$g_iCore_StartTime = $iNow
			$g_iCore_Counter += 1
			If $g_iCore_CatchUp_Count > 1 Then
				_Logger_Write(StringFormat("[Core] ⚡ Нагонка такта #%d (отставание: %d тактов)", $g_iCore_Counter, $iExpected - $g_iCore_Counter + 1), 1)
			EndIf
			Return True
		EndIf
		; Счётчик в норме — ждём следующего такта как обычно
		$g_iCore_CatchUp_Count = 0
	EndIf

	; Вычисляем следующий такт: ближайшая .100 через интервал от последнего такта
	Local $iNextTick = 0
	If $g_iCore_LastTickTime = 0 Then
		; Первый такт - берём текущее время
		$iNextTick = $iNow
	Else
		; Следующий такт = последний + интервал
		$iNextTick = $g_iCore_LastTickTime + $g_iCore_IntervalOriginal

		; Корректируем к ближайшей .SyncOffset только если интервал кратен секунде
		If $g_iCore_IntervalOriginal >= 1000 And Mod($g_iCore_IntervalOriginal, 1000) = 0 Then
			Local $iMs = Mod($iNextTick, 1000)
			Local $iDrift = $iMs - $g_iCore_SyncOffset
			$iNextTick = $iNextTick - $iDrift
		EndIf
	EndIf

	Local $iTimeLeft = $iNextTick - $iNow

	; Если до такта больше порога - возвращаемся в цикл
	If $iTimeLeft > $g_iCore_PredictiveThreshold Then
		Return False
	EndIf

	; === ПРЕДИКТИВНОЕ ОЖИДАНИЕ (последние 10мс) ===
	If $iTimeLeft > 0 Then
		_HighPrecisionSleep($iTimeLeft * 1000, $g_hCore_DLL)  ; Точное ожидание в микросекундах
		$iNow = _Utils_GetUnixTimestampMS()  ; Обновляем время после ожидания
	EndIf

	; Вычисляем реальный интервал с предыдущего такта
	If $g_iCore_LastTickTime > 0 Then
		Local $iRealInterval = $iNow - $g_iCore_LastTickTime
		$g_aCore_IntervalHistory[$g_iCore_HistoryIndex] = $iRealInterval
		$g_iCore_HistoryIndex = Mod($g_iCore_HistoryIndex + 1, 10)
	EndIf

	$g_iCore_LastTickTime = $iNow
	$g_iCore_StartTime = $iNow  ; Запоминаем время входа
	$g_iCore_Counter += 1

	Return True
EndFunc

; ===============================================================================
; Функция: _Core_Timer_End
; Описание: Завершение цикла, замер нагрузки, логирование
; Параметры: Нет
; Возврат: Нет
; Пример: _Core_Timer_End()
; ===============================================================================
Func _Core_Timer_End()
	Local $iNow = _Utils_GetUnixTimestampMS()
	Local $iExecutionTime = $iNow - $g_iCore_StartTime

	; === НАКОПЛЕНИЕ СТАТИСТИКИ ===
	$g_fCore_TotalLoad += $iExecutionTime
	$g_iCore_Iterations += 1

	; === ЛОГИРОВАНИЕ (каждые 10 секунд) ===
	If ($iNow - $g_iCore_LastLogTime) >= $g_iCore_LogInterval Then
		Local $fAvgLoad = $g_fCore_TotalLoad / $g_iCore_Iterations
		Local $fCpuLoad = ($fAvgLoad / $g_iCore_IntervalOriginal) * 100

		; Вычисляем среднее значение интервала за последние 10 тактов
		Local $fAvgInterval = 0
		Local $iValidCount = 0
		For $i = 0 To 9
			If $g_aCore_IntervalHistory[$i] > 0 Then
				$fAvgInterval += $g_aCore_IntervalHistory[$i]
				$iValidCount += 1
			EndIf
		Next
		If $iValidCount > 0 Then
			$fAvgInterval = $fAvgInterval / $iValidCount
		EndIf

		; Проверяем текущее смещение от .100
		Local $iCurrentMs = Mod($iNow, 1000)
		Local $iSyncDrift = $iCurrentMs - $g_iCore_SyncOffset

		;_Logger_Write(StringFormat("[Core] CPU: %.1f%% | Avg: %.1fms | Interval: %.1fms | Sync: .%d (%+dms) | Iter: %d", _
		;	$fCpuLoad, $fAvgLoad, $fAvgInterval, $g_iCore_SyncOffset, $iSyncDrift, $g_iCore_Iterations), 1)

		; Сбрасываем статистику
		$g_fCore_TotalLoad = 0
		$g_iCore_Iterations = 0
		$g_iCore_LastLogTime = $iNow
	EndIf
EndFunc

; ===============================================================================
; Функция: _Core_Timer_Task
; Описание: Тестовая функция с рандомной задержкой для имитации нагрузки
; Параметры: Нет
; Возврат: Нет
; Пример: _Core_Timer_Task()
; ===============================================================================
Func _Core_Timer_Task()
	; Рандомная задержка 1-75мс для имитации нагрузки
	Local $iDelay = Random(1, 75, 1)
	Sleep($iDelay)
EndFunc

; ===============================================================================
; Функция: _Core_Timer_TestDLL
; Описание: Тест точности _HighPrecisionSleep для определения минимальной задержки
; Параметры: Нет
; Возврат: True если тест пройден, False при ошибке
; Пример: _Core_Timer_TestDLL()
; ===============================================================================
Func _Core_Timer_TestDLL()
	_Logger_Write("[Core] Тестирование точности _HighPrecisionSleep...", 1)

	; Тестируем разные задержки: 1мс, 5мс, 10мс
	Local $aTestDelays[3] = [1000, 5000, 10000]  ; В микросекундах
	Local $aResults[3]
	Local $iTestIterations = 10

	For $i = 0 To 2
		Local $iDelayUs = $aTestDelays[$i]
		Local $fTotalDiff = 0

		; Делаем 10 замеров для каждой задержки
		For $j = 0 To $iTestIterations - 1
			Local $hTimer = TimerInit()
			_HighPrecisionSleep($iDelayUs, $g_hCore_DLL)
			Local $fElapsed = TimerDiff($hTimer)
			$fTotalDiff += $fElapsed
		Next

		; Вычисляем среднюю задержку
		Local $fAvgDelay = $fTotalDiff / $iTestIterations
		Local $fExpectedMs = $iDelayUs / 1000
		Local $fError = Abs($fAvgDelay - $fExpectedMs)

		$aResults[$i] = $fAvgDelay

		_Logger_Write(StringFormat("[Core] Test %dмкс: ожидалось %.2fмс, получено %.2fмс (погрешность: %.2fмс)", _
			$iDelayUs, $fExpectedMs, $fAvgDelay, $fError), 1)
	Next

	; Проверяем результаты
	Local $bPassed = True
	For $i = 0 To 2
		Local $fExpectedMs = $aTestDelays[$i] / 1000
		Local $fError = Abs($aResults[$i] - $fExpectedMs)

		; Если погрешность больше 5мс - тест не пройден
		If $fError > 5 Then
			$bPassed = False
			_Logger_Write(StringFormat("[Core] ⚠️ Тест не пройден: погрешность %.2fмс превышает 5мс", $fError), 2)
		EndIf
	Next

	If $bPassed Then
		_Logger_Write("[Core] ✅ Тест _HighPrecisionSleep пройден успешно", 3)
	Else
		_Logger_Write("[Core] ❌ Тест _HighPrecisionSleep не пройден - возможны проблемы с точностью", 2)
	EndIf

	Return $bPassed
EndFunc

; ===============================================================================
; Функция: _HighPrecisionSleep
; Описание: Функция для точной микрозадержки через ntdll.dll с компенсацией +1мс
; Параметры:
;   $iMicroSeconds - задержка в микросекундах (1000 мкс = 1 мс)
;   $hDll - handle DLL (опционально, если не передан - открывает/закрывает)
; Возврат: Нет
; Пример: _HighPrecisionSleep(10000, $g_hCore_DLL) ; 10мс задержка
; ===============================================================================
Func _HighPrecisionSleep($iMicroSeconds, $hDll = False)
	; Если задержка меньше 1мс - не спим
	If $iMicroSeconds <= 1000 Then Return

	Local $hStruct, $bLoaded
	If Not $hDll Then
		$hDll = DllOpen("ntdll.dll")
		$bLoaded = True
	EndIf

	; Компенсируем системную погрешность +1мс
	Local $iAdjusted = $iMicroSeconds - 1000  ; Вычитаем 1мс (1000 мкс)

	$hStruct = DllStructCreate("int64 time;")
	DllStructSetData($hStruct, "time", -1 * ($iAdjusted * 10))
	DllCall($hDll, "dword", "ZwDelayExecution", "int", 0, "ptr", DllStructGetPtr($hStruct))

	If $bLoaded Then DllClose($hDll)
EndFunc

; ===============================================================================
; Функция: _Core_Timer_Cleanup
; Описание: Очистка ресурсов при выходе из программы
; Параметры: Нет
; Возврат: Нет
; Пример: OnAutoItExitRegister("_Core_Timer_Cleanup")
; ===============================================================================
Func _Core_Timer_Cleanup()
	; Закрываем DLL
	If $g_hCore_DLL <> 0 And $g_hCore_DLL <> -1 Then
		DllClose($g_hCore_DLL)
	EndIf

	; Восстанавливаем стандартное разрешение таймера
	DllCall("winmm.dll", "uint", "timeEndPeriod", "uint", 1)
	_Logger_Write("[Core] Восстановлено стандартное разрешение таймера", 1)
EndFunc
