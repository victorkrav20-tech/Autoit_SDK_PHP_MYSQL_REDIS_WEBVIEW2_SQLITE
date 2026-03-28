; ===============================================
; ProcessManager_Actions.au3
; Обработка действий пользователя и логика процессов
; ===============================================

; --- !!! САМОЕ ВАЖНОЕ: ОБРАБОТЧИК ДЕЙСТВИЙ !!! ---
Func ActionHandler()
    Local $id = @GUI_CtrlId ; Какая кнопка нажата?

    ; Ищем, к какой строке (процессу) относится кнопка
    For $i = 1 To $aProcesses[0][0]
        Switch $id
            Case $aProcessRows[$i][1] ; --- ЧЕКБОКС "При запуске" (Одноразовый) ---
                ; Просто записываем состояние в массив.
                ; Логика запуска сработает в Adlib-функции RunStartupProcessesOnce
                $aProcesses[$i][2] = (GUICtrlRead($id) = $GUI_CHECKED) ? 1 : 0
                SaveSettingsToINI() ; Сохраняем настройки в INI

            Case $aProcessRows[$i][2] ; --- AUTO ON ---
                $aProcesses[$i][3] = 1
                $aProcesses[$i][11] = TimerInit()

                ; Логируем переключение ТОЛЬКО при нажатии пользователем
                WriteLog("КОНСОЛЬ", $aProcesses[$i][0], "AUTO включен пользователем")

                ; Обновляем кнопки через функцию с логированием
                UpdateAutoStopButtonsWithLogging($i)

                SaveSettingsToINI()

            Case $aProcessRows[$i][3] ; --- AUTO OFF ---
                $aProcesses[$i][3] = 0

                ; Логируем переключение ТОЛЬКО при нажатии пользователем
                WriteLog("КОНСОЛЬ", $aProcesses[$i][0], "AUTO выключен пользователем")

                ; Обновляем кнопки через функцию с логированием
                UpdateAutoStopButtonsWithLogging($i)

                SaveSettingsToINI()

            Case $aProcessRows[$i][4] ; --- КНОПКА "Run" (Ручной запуск) ---
                RunProcessLogic($i)

            Case $aProcessRows[$i][5] ; --- КНОПКА "Exit" (Ручное закрытие) ---
                StopProcessLogic($i)

            Case $aProcessRows[$i][8] ; --- ЧЕКБОКС "Удалять дубли" ---
                $aProcesses[$i][6] = (GUICtrlRead($id) = $GUI_CHECKED) ? 1 : 0
                
                ; 📝 Логируем изменение настройки дубликатов
                Local $sStatus = ($aProcesses[$i][6] = 1) ? "ВКЛЮЧЕНО" : "ОТКЛЮЧЕНО"
                WriteLog("КОНСОЛЬ", $aProcesses[$i][0], "🔄 Удаление дубликатов " & $sStatus & " (новые процессы будут выживать)")
                
                SaveSettingsToINI()

        EndSwitch
    Next
EndFunc

Func RunProcessLogic($index)
    ; 🛡️ ЗАЩИЩЕННАЯ ФУНКЦИЯ ЗАПУСКА ПРОЦЕССОВ
    
    ; Проверка индекса
    If $index <= 0 Or $index > $aProcesses[0][0] Then Return

    Local $path = $aProcesses[$index][1]
    Local $processName = $aProcesses[$index][0]

    ; 🔍 ПРОВЕРКА 1: Существование файла
    If Not FileExists($path) Then
        Local $errorMsg = "❌ Файл не найден: " & $path
        ; Запуск MsgBox как отдельного процесса с таймаутом 3 секунды
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''' & "Ошибка запуска" & ''', ''' & "Ошибка = " & $errorMsg & "  " & ''', 5)"')
		_ExternalMsg("Ошибка запуска", "Ошибка = " & $errorMsg & "",10)
        WriteLog("ОШИБКА", $processName, $errorMsg)
        Return
    EndIf

    ; 🔍 ПРОВЕРКА 2: Доступность файла для чтения
    Local $hFile = FileOpen($path, 0)
    If $hFile = -1 Then
        Local $errorMsg = "❌ Файл заблокирован или недоступен: " & $path
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''' & "Ошибка запуска" & ''', ''' & "Ошибка = " & $errorMsg & "  " & ''', 5)"')
		_ExternalMsg("Ошибка запуска", "Ошибка = " & $errorMsg & "",10)
        WriteLog("ОШИБКА", $processName, $errorMsg)
        Return
    EndIf
    FileClose($hFile)

    Local $workdir = StringLeft($path, StringInStr($path, "\", 0, -1))

    ; 🚀 ЗАПУСК ПРОЦЕССА С RETRY МЕХАНИЗМОМ
    Local $iMaxRetries = 3
    Local $iPID = 0
    Local $bSuccess = False
    
    For $iAttempt = 1 To $iMaxRetries
        ; Попытка 1-2: Через Run() с кавычками (основной метод)
        If $iAttempt <= 2 Then
            $iPID = Run('"' & $path & '"', $workdir, @SW_SHOW)
            
            If $iPID > 0 Then
                $bSuccess = True
                WriteLog("КОНСОЛЬ", $processName, "✅ Процесс запущен через Run() (PID: " & $iPID & ", попытка: " & $iAttempt & ")")
                ExitLoop
            EndIf
        ; Попытка 3: Через ShellExecute с кавычками (fallback)
        Else
            WriteLog("СИСТЕМА", $processName, "⚠️ Run() не сработал, используем ShellExecute (попытка: " & $iAttempt & ")")
            ; 🛡️ ИСПРАВЛЕНО: Добавлены кавычки в ShellExecute
            ShellExecute('"' & $path & '"', "", $workdir)
            $bSuccess = True ; ShellExecute не возвращает PID, считаем успешным
            ExitLoop
        EndIf
        
        ; Задержка между попытками
        If $iAttempt < $iMaxRetries Then Sleep(200)
    Next
    
    ; Проверка результата
    If Not $bSuccess Then
        WriteLog("ОШИБКА", $processName, "❌ Не удалось запустить процесс после " & $iMaxRetries & " попыток")
        Return
    EndIf

    ; Логируем успешный запуск
    WriteLog("ВКЛЮЧЕНИЕ", $processName, "Процесс запущен: " & $path)

    ; --- ОБНОВЛЕНИЕ ДАННЫХ В МАССИВЕ ---
    Local $currentTime = _NowCalc()
    $aProcesses[$index][11] = TimerInit() ; Сбрасываем таймер ожидания
    $aProcesses[$index][10] = $currentTime ; Обновляем дату запуска в массиве
    $aProcesses[$index][13] = ""          ; Сбрасываем время остановки

    ; --- МГНОВЕННАЯ ЗАПИСЬ В INI ---
    ; Записываем дату старта прямо в конфиг, чтобы данные не потерялись
    IniWrite($sIniPath, "Process_" & $index, "DateTime_last_start", $currentTime)

    ; --- ОБНОВЛЕНИЕ ГРАФИЧЕСКОГО ИНТЕРФЕЙСА ---
    ; УБИРАЕМ принудительное изменение статуса - пусть Core.au3 сам определит статус
    ; Это предотвратит двойные переключения статуса в логах
EndFunc

Func StopProcessLogic($index)
    Local $exeName = StringRegExpReplace($aProcesses[$index][1], ".*\\", "") ; Получаем имя exe
    Local $processName = $aProcesses[$index][0]

    ; Твоя логика AutoKill (убивает все процессы с таким именем)
    Local $PIDs = ProcessList($exeName)
    Local $killedCount = 0
    For $j = 1 To $PIDs[0][0]
        If ProcessClose($PIDs[$j][1]) Then $killedCount += 1
    Next

    ; Логируем остановку процесса
    If $killedCount > 0 Then
        WriteLog("ОТКЛЮЧЕНИЕ", $processName, "Остановлено процессов: " & $killedCount & " (" & $exeName & ")")
    Else
        WriteLog("ОТКЛЮЧЕНИЕ", $processName, "Процесс не найден для остановки: " & $exeName)
    EndIf

    ; Сохраняем время остановки
    $aProcesses[$index][13] = _NowCalc()
EndFunc

Func UpdateProcessStatusGUI($pIdx)
    ; Проверяем, существует ли вообще элемент GUI для этого процесса
    If Not IsArray($aProcessRows) Or $pIdx >= UBound($aProcessRows) Then Return
    If $aProcessRows[$pIdx][7] = 0 Then Return ; Элемент не создан

    Local $currentStatus = $aProcesses[$pIdx][5]
    
    ; Обновляем текст статуса
    GUICtrlSetData($aProcessRows[$pIdx][7], $currentStatus)
    
    ; ЯВНОЕ определение цвета строго по тексту статуса
    Local $statusText = GUICtrlRead($aProcessRows[$pIdx][7])
    If $statusText = "Runned" Then
        GUICtrlSetColor($aProcessRows[$pIdx][7], $color_run) ; Зеленый для работающих
    ElseIf $statusText = "Stopped" Or $statusText = "Stop" Then
        GUICtrlSetColor($aProcessRows[$pIdx][7], $color_stop) ; Красный для остановленных
    Else
        GUICtrlSetColor($aProcessRows[$pIdx][7], $color_stop) ; По умолчанию красный
    EndIf

    ; УБИРАЕМ автоматическое обновление кнопок - они обновляются только при нажатии пользователем
EndFunc

Func UpdateAutoStopButtons($pIdx)
    ; Проверяем существование кнопок
    If Not IsArray($aProcessRows) Or $pIdx >= UBound($aProcessRows) Then Return
    If $aProcessRows[$pIdx][2] = 0 Or $aProcessRows[$pIdx][3] = 0 Then Return

    ; УБИРАЕМ избыточное логирование - логируем только при реальных нажатиях пользователем

    ; Обновляем кнопку Auto
    If $aProcesses[$pIdx][3] = 1 Then
        ; AUTO ВКЛЮЧЕН
        GUICtrlSetColor($aProcessRows[$pIdx][2], 0xFFFFFF) ; Белый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][2], 0x8E44AD) ; Фиолетовый фон
        GUICtrlSetState($aProcessRows[$pIdx][2], $GUI_ENABLE)
    Else
        ; AUTO ВЫКЛЮЧЕН
        GUICtrlSetColor($aProcessRows[$pIdx][2], 0x8E44AD) ; Фиолетовый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][2], 0xE0E0E0) ; Серый фон
        GUICtrlSetState($aProcessRows[$pIdx][2], $GUI_ENABLE)
    EndIf

    ; Обновляем кнопку Stop
    If $aProcesses[$pIdx][3] = 1 Then
        ; AUTO ВКЛЮЧЕН - Stop активна
        GUICtrlSetColor($aProcessRows[$pIdx][3], 0xFFFFFF) ; Белый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][3], 0xC0392B) ; Красный фон
        GUICtrlSetState($aProcessRows[$pIdx][3], $GUI_ENABLE)
    Else
        ; AUTO ВЫКЛЮЧЕН - Stop неактивна
        GUICtrlSetColor($aProcessRows[$pIdx][3], 0x7F8C8D) ; Серый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][3], $color_separator) ; Темно-серый фон
        GUICtrlSetState($aProcessRows[$pIdx][3], $GUI_DISABLE)
    EndIf

    ; Принудительная перерисовка кнопок
    _WinAPI_InvalidateRect(GUICtrlGetHandle($aProcessRows[$pIdx][2]), 0, True)
    _WinAPI_InvalidateRect(GUICtrlGetHandle($aProcessRows[$pIdx][3]), 0, True)
    _WinAPI_UpdateWindow(GUICtrlGetHandle($aProcessRows[$pIdx][2]))
    _WinAPI_UpdateWindow(GUICtrlGetHandle($aProcessRows[$pIdx][3]))
    
    ; Поднимаем кнопки поверх фона
    BringButtonsToFront($pIdx)
EndFunc

; Функция обновления кнопок С логированием (только для пользовательских действий)
Func UpdateAutoStopButtonsWithLogging($pIdx)
    ; Проверяем существование кнопок
    If Not IsArray($aProcessRows) Or $pIdx >= UBound($aProcessRows) Then Return
    If $aProcessRows[$pIdx][2] = 0 Or $aProcessRows[$pIdx][3] = 0 Then Return

    ; Логируем текущее состояние ТОЛЬКО при пользовательских действиях
    WriteLog("КОНСОЛЬ", $aProcesses[$pIdx][0], "Обновление кнопок: AUTO=" & $aProcesses[$pIdx][3])

    ; Обновляем кнопку Auto
    If $aProcesses[$pIdx][3] = 1 Then
        ; AUTO ВКЛЮЧЕН
        GUICtrlSetColor($aProcessRows[$pIdx][2], 0xFFFFFF) ; Белый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][2], 0x8E44AD) ; Фиолетовый фон
        GUICtrlSetState($aProcessRows[$pIdx][2], $GUI_ENABLE)
        WriteLog("КОНСОЛЬ", $aProcesses[$pIdx][0], "AUTO кнопка: фиолетовая с белым текстом")
    Else
        ; AUTO ВЫКЛЮЧЕН
        GUICtrlSetColor($aProcessRows[$pIdx][2], 0x8E44AD) ; Фиолетовый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][2], 0xE0E0E0) ; Серый фон
        GUICtrlSetState($aProcessRows[$pIdx][2], $GUI_ENABLE)
        WriteLog("КОНСОЛЬ", $aProcesses[$pIdx][0], "AUTO кнопка: серая с фиолетовым текстом")
    EndIf

    ; Обновляем кнопку Stop
    If $aProcesses[$pIdx][3] = 1 Then
        ; AUTO ВКЛЮЧЕН - Stop активна
        GUICtrlSetColor($aProcessRows[$pIdx][3], 0xFFFFFF) ; Белый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][3], 0xC0392B) ; Красный фон
        GUICtrlSetState($aProcessRows[$pIdx][3], $GUI_ENABLE)
        WriteLog("КОНСОЛЬ", $aProcesses[$pIdx][0], "STOP кнопка: красная с белым текстом (активна)")
    Else
        ; AUTO ВЫКЛЮЧЕН - Stop неактивна
        GUICtrlSetColor($aProcessRows[$pIdx][3], 0x7F8C8D) ; Серый текст
        GUICtrlSetBkColor($aProcessRows[$pIdx][3], $color_separator) ; Темно-серый фон
        GUICtrlSetState($aProcessRows[$pIdx][3], $GUI_DISABLE)
        WriteLog("КОНСОЛЬ", $aProcesses[$pIdx][0], "STOP кнопка: серая (неактивна)")
    EndIf

    ; Принудительная перерисовка кнопок
    _WinAPI_InvalidateRect(GUICtrlGetHandle($aProcessRows[$pIdx][2]), 0, True)
    _WinAPI_InvalidateRect(GUICtrlGetHandle($aProcessRows[$pIdx][3]), 0, True)
    _WinAPI_UpdateWindow(GUICtrlGetHandle($aProcessRows[$pIdx][2]))
    _WinAPI_UpdateWindow(GUICtrlGetHandle($aProcessRows[$pIdx][3]))
EndFunc

Func CalculateWorkTime($startDateTime, $endDateTime = "")
    If $startDateTime = "" Then Return "00:00:00"
    
    Local $endTime = ($endDateTime = "") ? _NowCalc() : $endDateTime
    Local $diffSeconds = _DateDiff('s', $startDateTime, $endTime)
    
    If $diffSeconds < 0 Then Return "00:00:00"
    
    Local $hours = Int($diffSeconds / 3600)
    Local $minutes = Int(($diffSeconds - $hours * 3600) / 60)
    Local $seconds = $diffSeconds - $hours * 3600 - $minutes * 60
    
    Return StringFormat("%02d:%02d:%02d", $hours, $minutes, $seconds)
EndFunc

Func ResetCounters()
    If MsgBox(36, "Обнулить счётчики", "Вы уверены, что хотите обнулить все счётчики?",10) = 6 Then
        For $i = 1 To $aProcesses[0][0]
            $aProcesses[$i][4] = 0 ; Обнуляем счетчик
            If IsArray($aProcessRows) And UBound($aProcessRows, 1) > $i Then
                GUICtrlSetData($aProcessRows[$i][6], "0") ; Обновляем GUI
            EndIf
        Next
        SaveSettingsToINI() ; Сохраняем изменения
        WriteLog("КОНСОЛЬ", "СИСТЕМА", "Все счётчики обнулены пользователем")
    EndIf
EndFunc

; Функция поднятия кнопок поверх фонового изображения
Func BringButtonsToFront($pIdx)
    ; Проверяем существование кнопок
    If Not IsArray($aProcessRows) Or $pIdx >= UBound($aProcessRows) Then Return
    
    ; Поднимаем все кнопки строки поверх фона
    Local $aButtonsToElevate[4] = [$aProcessRows[$pIdx][2], $aProcessRows[$pIdx][3], $aProcessRows[$pIdx][4], $aProcessRows[$pIdx][5]]
    
    For $i = 0 To UBound($aButtonsToElevate) - 1
        If $aButtonsToElevate[$i] <> 0 Then
            Local $hButton = GUICtrlGetHandle($aButtonsToElevate[$i])
            If $hButton <> 0 Then
                ; Поднимаем элемент на передний план
                _WinAPI_SetWindowPos($hButton, $HWND_TOP, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOACTIVATE))
            EndIf
        EndIf
    Next
EndFunc