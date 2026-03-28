; ===============================================
; ProcessManager_Utils.au3
; Вспомогательные функции и утилиты
; ===============================================

; --- СИСТЕМА ОБРАБОТКИ ОШИБОК ---
; OnAutoItExitRegister("_OnExit")


; Обработчик критических ошибок COM/Объектов
Func _MyErrorHandler()
    ; Объект ошибки передается в функцию автоматически в некоторых версиях,
    ; но для надежности логируем через @error или свойства объекта
    Local $sErrorMsg = "КРИТИЧЕСКАЯ ОШИБКА COM: Код: " & Hex($oMyError.number, 8) & " Описание: " & StringStripWS($oMyError.description, 3)

    ; Записываем ошибку в лог
    WriteLog("ОШИБКА", "СИСТЕМА", $sErrorMsg)

    ; Перезапуск
    _RestartApplication()
EndFunc

; Функция перезапуска приложения с использованием внешнего менеджера
Func _RestartApplication()
    WriteLog("СИСТЕМА", "АВТОЗАПУСК", "Инициирован процесс самовосстановления...")

    Local $sManagerPath = @ScriptDir & "\ProcessManager.exe"
    Local $sCurrentExe = @ScriptFullPath

    ; Если мы запущены как скрипт .au3, пробуем найти скомпилированный .exe
    If StringRight($sCurrentExe, 4) = ".au3" Then
        $sCurrentExe = StringReplace($sCurrentExe, ".au3", ".exe")
    EndIf

If FileExists($sManagerPath) Then
        ; Запускаем менеджер и просим его запустить нас с флагом перехвата ошибок
        ; Мы передаем флаг /ErrorStdOut как часть аргумента для будущей команды Run
        Run('"' & $sManagerPath & '" /restart "' & $sCurrentExe & ' /ErrorStdOut"', @ScriptDir)
        WriteLog("СИСТЕМА", "АВТОЗАПУСК", "Вызван внешний менеджер с перехватом потока.")
    Else
        ; Резервный запуск самого себя с перехватом (если запуск идет через CMD или другой логгер)
        If FileExists($sCurrentExe) Then
            Run('"' & $sCurrentExe & '" /ErrorStdOut', @ScriptDir)
            WriteLog("СИСТЕМА", "АВТОЗАПУСК", "Менеджер не найден. Прямой запуск с /ErrorStdOut.")
        Else
            WriteLog("ОШИБКА", "АВТОЗАПУСК", "Файл не найден: " & $sCurrentExe)
        EndIf
    EndIf

    ; Небольшая пауза для записи логов перед выходом
    Sleep(1000)
    Exit
EndFunc

; Функция при выходе из программы
Func _OnExit()
    ; Проверяем причину выхода через @exitMethod (1 - закроет пользователь, 0 - Exit в коде)
    Local $iMethod = @exitMethod
    WriteLog("ОТКЛЮЧЕНИЕ", "СИСТЕМА", "Завершение работы (Код выхода: " & @exitCode & ", Метод: " & $iMethod & ")")

    ; 🎯 Выгружаем иконку из трея
    TraySetState(2) ; 2 = скрыть иконку

    ; Если это не запланированный выход (например, падение или закрытие процесса),
    ; можно вызвать перезапуск прямо отсюда, но в данном случае логируем и чистим.
    SaveLogCounter()
    CleanupLogFonts()

    If IsDeclared("bLogWindowActive") And $bLogWindowActive Then
        GUIDelete($hLogWindow)
        $bLogWindowActive = False
    EndIf
EndFunc

; --- ФУНКЦИЯ ДЛЯ ТЕСТИРОВАНИЯ ОШИБОК ---
Func debug_error()
    WriteLog("СИСТЕМА", "DEBUG", "Запуск функции тестирования ошибок")

    ; Создаем массив с 10 элементами (индексы 0-9)
    Local $aTestArray[10]

    ; Заполняем массив
    For $i = 0 To 9
        $aTestArray[$i] = "Элемент " & $i
    Next

    WriteLog("СИСТЕМА", "DEBUG", "Массив создан, начинаем цикл с ошибкой")

    ; ОШИБОЧНЫЙ цикл - пытаемся обратиться к индексу 10, которого нет
    For $i = 0 To 10 ; ОШИБКА: должно быть 0 To 9
        WriteLog("СИСТЕМА", "DEBUG", "Обработка элемента " & $i & ": " & $aTestArray[$i])
        Sleep(1000) ; Задержка 1 секунда
		if $i=4 then
			Local $oTest = ObjCreate("Shell.Application")
			$oTest.NonExistentMethod() ; Это ДОЛЖНО вызвать обработчик
		EndIf
    Next

    WriteLog("СИСТЕМА", "DEBUG", "Функция завершена (этого сообщения не должно быть)")
EndFunc

; --- ФУНКЦИИ ДЛЯ РАБОТЫ СО STRIPPED ФАЙЛОМ ---

; Функция получения строки кода из stripped файла
Func GetErrorLineFromStripped($sProcessName, $iLineNumber, $iContextLines = 2)
    ; Определяем имя stripped файла
    Local $sStrippedFile = StringReplace($sProcessName, ".exe", "_stripped.au3")
    Local $sStrippedPath = @ScriptDir & "\" & $sStrippedFile

    WriteLog("КОНСОЛЬ", "STRIPPER", "Ищем строку " & $iLineNumber & " в файле: " & $sStrippedPath)

    ; Проверяем существование stripped файла
    If Not FileExists($sStrippedPath) Then
        WriteLog("ОШИБКА", "STRIPPER", "Stripped файл не найден: " & $sStrippedPath)
        Return False
    EndIf

    ; Читаем весь файл
    Local $aLines = FileReadToArray($sStrippedPath)
    If @error Then
        WriteLog("ОШИБКА", "STRIPPER", "Не удалось прочитать stripped файл: " & $sStrippedPath)
        Return False
    EndIf

    ; Проверяем, что номер строки в пределах файла
    If $iLineNumber <= 0 Or $iLineNumber > UBound($aLines) Then
        WriteLog("ОШИБКА", "STRIPPER", "Номер строки " & $iLineNumber & " вне диапазона файла (1-" & UBound($aLines) & ")")
        Return False
    EndIf

    ; Получаем строку с ошибкой (массив начинается с 0, поэтому -1)
    Local $sErrorLine = $aLines[$iLineNumber - 1]
    WriteLog("КОНСОЛЬ", "STRIPPER", "Найдена строка ошибки: " & StringLeft($sErrorLine, 100) & "...")

    ; Создаем массив с контекстом
    Local $aContext[1]
    $aContext[0] = 0

    ; Добавляем строки до ошибки
    Local $iStartLine = ($iLineNumber - $iContextLines > 1) ? ($iLineNumber - $iContextLines) : 1
    Local $iEndLine = ($iLineNumber + $iContextLines < UBound($aLines)) ? ($iLineNumber + $iContextLines) : UBound($aLines)

    For $i = $iStartLine To $iEndLine
        If $i > 0 And $i <= UBound($aLines) Then
            $aContext[0] += 1
            ReDim $aContext[$aContext[0] + 1]
            $aContext[$aContext[0]] = "Строка " & $i & ": " & $aLines[$i - 1]
        EndIf
    Next

    WriteLog("КОНСОЛЬ", "STRIPPER", "Получен контекст из " & $aContext[0] & " строк")

    ; Возвращаем массив: [0] = строка с ошибкой, [1] = массив контекста
    Local $aResult[2] = [$sErrorLine, $aContext]
    Return $aResult
EndFunc

; Функция поиска строки кода в пользовательских файлах
Func FindLineInUserFiles($sCodeLine, $iOriginalLine)
    WriteLog("КОНСОЛЬ", "STRIPPER", "Ищем строку в пользовательских файлах: " & StringLeft($sCodeLine, 50) & "...")

    ; Список пользовательских файлов для поиска
    Local $aUserFiles[9] = ["ProcessManager.au3", "ProcessManager_Config.au3", "ProcessManager_Core.au3", _
                           "ProcessManager_GUI.au3", "ProcessManager_Actions.au3", "ProcessManager_Settings.au3", _
                           "ProcessManager_ProcessDialog.au3", "ProcessManager_Logging.au3", "ProcessManager_Utils.au3"]

    ; Очищаем строку от лишних пробелов для поиска
    Local $sCleanLine = StringStripWS($sCodeLine, 3)
    If $sCleanLine = "" Then
        WriteLog("ОШИБКА", "STRIPPER", "Пустая строка для поиска")
        Return False
    EndIf

    ; Ищем в каждом пользовательском файле
    For $i = 0 To UBound($aUserFiles) - 1
        Local $sFilePath = @ScriptDir & "\" & $aUserFiles[$i]
        If FileExists($sFilePath) Then
            Local $aFileLines = FileReadToArray($sFilePath)
            If Not @error Then
                ; Ищем точное совпадение строки
                For $j = 0 To UBound($aFileLines) - 1
                    Local $sFileLineClean = StringStripWS($aFileLines[$j], 3)
                    If $sFileLineClean = $sCleanLine Then
                        WriteLog("КОНСОЛЬ", "STRIPPER", "Найдено совпадение в " & $aUserFiles[$i] & " на строке " & ($j + 1))
                        Local $aResult[2] = [$aUserFiles[$i], $j + 1]
                        Return $aResult
                    EndIf
                Next

                ; Если точного совпадения нет, ищем частичное (для случаев с переменными)
                For $j = 0 To UBound($aFileLines) - 1
                    Local $sFileLineClean = StringStripWS($aFileLines[$j], 3)
                    ; Ищем совпадение по ключевым словам (функции, операторы)
                    If StringLen($sFileLineClean) > 10 And StringLen($sCleanLine) > 10 Then
                        If StringInStr($sFileLineClean, StringLeft($sCleanLine, 20)) > 0 Or _
                           StringInStr($sCleanLine, StringLeft($sFileLineClean, 20)) > 0 Then
                            WriteLog("КОНСОЛЬ", "STRIPPER", "Найдено частичное совпадение в " & $aUserFiles[$i] & " на строке " & ($j + 1))
                            Local $aResult[2] = [$aUserFiles[$i], $j + 1]
                            Return $aResult
                        EndIf
                    EndIf
                Next
            EndIf
        EndIf
    Next

    WriteLog("ОШИБКА", "STRIPPER", "Строка не найдена в пользовательских файлах")
    Return False
EndFunc

; Функция для отображения массива в виде таблицы
Func ShowArrayTable()
    _ArrayDisplay($aProcesses)
EndFunc

Func CloseArrayTable()
    ; Эта функция вызывается при закрытии окна
    GUIDelete(@GUI_WinHandle)
EndFunc

Func ExitApp()
    WriteLog("ОТКЛЮЧЕНИЕ", "СИСТЕМА", "Process Manager завершает работу")

    ; Устанавливаем флаг для watchdog, чтобы он не перезапускал программу при нормальном выходе
    ;IniWrite($sIniPath, "Watchdog", "DisableAutostart", "1")

    SaveLogCounter() ; Сохраняем текущий счетчик логов
    CleanupLogFonts() ; Очищаем шрифты
    ; Закрываем окно логов, если оно открыто
    If $bLogWindowActive Then
        GUIDelete($hLogWindow)
        $bLogWindowActive = False
    EndIf

    ; Через 3 секунды сбрасываем флаг, чтобы watchdog снова мог запускать программу
    AdlibRegister("_ResetWatchdogFlag", 3000)

    Exit
EndFunc

; Функция сброса флага watchdog (вызывается через 3 секунды после выхода)
Func _ResetWatchdogFlag()
    IniWrite($sIniPath, "Watchdog", "DisableAutostart", "0")
    AdlibUnRegister("_ResetWatchdogFlag")
EndFunc
; --- Сама функция ---
Func _RegisterMyHotKeys_Async()
    $iHK_Tries += 1

    ; 🎯 Пытаемся занять обе клавиши
    Local $bF2Success = HotKeySet("{F2}", "_hide")
    Local $bF5Success = HotKeySet("{F5}", "debug_error")

    If $bF2Success And $bF5Success Then
        WriteLog("СИСТЕМА", "HOTKEY", "✅ F2 и F5 успешно перехвачены на попытке " & $iHK_Tries)
        AdlibUnRegister("_RegisterMyHotKeys_Async") ; Снимаем задачу, всё готово
        Return True
    EndIf

    ; Если не удалось и прошло уже 10 попыток (10 секунд)
    If $iHK_Tries >= 10 Then
        Local $sFailedKeys = ""
        If Not $bF2Success Then $sFailedKeys &= "F2 "
        If Not $bF5Success Then $sFailedKeys &= "F5 "
        WriteLog("ОШИБКА", "HOTKEY", "❌ Не удалось занять " & $sFailedKeys & "за 10 попыток (10 секунд). Самоотключение.")
        AdlibUnRegister("_RegisterMyHotKeys_Async") ; Снимаем задачу, чтобы не висела вечно
        Return False
    EndIf

    ; Логируем неудачную попытку только каждые 3 попытки чтобы не спамить
    If Mod($iHK_Tries, 3) = 0 Then
        Local $sFailedKeys = ""
        If Not $bF2Success Then $sFailedKeys &= "F2 "
        If Not $bF5Success Then $sFailedKeys &= "F5 "
        WriteLog("СИСТЕМА", "HOTKEY", "⚠️ " & $sFailedKeys & "всё еще занят старым процессом... Попытка " & $iHK_Tries & "/10")
    EndIf
EndFunc

; ===============================================
; 🎯 СИСТЕМА ТРЕЯ
; ===============================================

; Функция инициализации иконки трея
Func InitializeTrayIcon()
    ; Устанавливаем иконку трея
    TraySetIcon(@ScriptDir & "\img\note.ico")

    ; Устанавливаем начальную подсказку
    UpdateTrayTooltip()

    ; 🎯 Устанавливаем действие при клике на иконку трея (отпускание левой кнопки)
    TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "_hide")

    ; Показываем иконку трея
    TraySetState(1) ; 1 = показать иконку

    WriteLog("СИСТЕМА", "TRAY", "✅ Иконка трея инициализирована")
EndFunc

; 🎯 Функция переключения видимости окна (клик по трею или F2)
Func _hide()
    ; Проверяем состояние окна (видимо ли оно)
    Local $iState = WinGetState($hGUI)

    ; Если окно видимо (бит 2 = SW_SHOW)
    If BitAND($iState, 2) Then
        ; Окно видимо - скрываем
        GUISetState(@SW_HIDE, $hGUI)
    Else
        ; Окно скрыто - показываем и активируем
        GUISetState(@SW_RESTORE, $hGUI)
        GUISetState(@SW_SHOW, $hGUI)
        WinActivate($hGUI)
    EndIf
EndFunc

; 🎯 Функция обновления подсказки трея с информацией о процессах
Func UpdateTrayTooltip()
    Local $runningCount = 0, $autostartCount = 0, $totalProcesses = $aProcesses[0][0]

    ; Подсчитываем статистику
    For $i = 1 To $totalProcesses
        If $aProcesses[$i][5] = "Runned" Then $runningCount += 1
        If $aProcesses[$i][3] = 1 Then $autostartCount += 1
    Next

    ; 📝 Получаем информацию о последней записи лога и вычисляем время с последнего лога
    Local $sTimeSinceLastLog = "N/A"
    Local $logFile = @ScriptDir & "\log\ProcessManager.log"

    If FileExists($logFile) Then
        Local $aLogLines = FileReadToArray($logFile)
        If IsArray($aLogLines) And UBound($aLogLines) > 0 Then
            Local $sLastLogLine = $aLogLines[UBound($aLogLines) - 1]

            ; Парсим строку лога для получения времени
            Local $aLogParts = StringSplit($sLastLogLine, "|", 1)
            If IsArray($aLogParts) And $aLogParts[0] >= 2 Then
                Local $lastLogTime = StringStripWS($aLogParts[2], 3)  ; Дата и время: "2026-01-14 17:37:18"

                ; 🕐 Вычисляем разницу времени
                Local $sCurrentTime = @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & " " & @HOUR & ":" & @MIN & ":" & @SEC

                ; Преобразуем строки времени в секунды
                Local $iLastLogSeconds = _TimeStringToSeconds($lastLogTime)
                Local $iCurrentSeconds = _TimeStringToSeconds($sCurrentTime)

                If $iLastLogSeconds > 0 And $iCurrentSeconds > 0 Then
                    Local $iDiffSeconds = $iCurrentSeconds - $iLastLogSeconds

                    ; Преобразуем в формат "X дней HH:MM:SS"
                    Local $iDays = Int($iDiffSeconds / 86400)
                    Local $iHours = Int(Mod($iDiffSeconds, 86400) / 3600)
                    Local $iMinutes = Int(Mod($iDiffSeconds, 3600) / 60)
                    Local $iSeconds = Mod($iDiffSeconds, 60)

                    $sTimeSinceLastLog = $iDays & " дн " & StringFormat("%02d:%02d:%02d", $iHours, $iMinutes, $iSeconds)
                EndIf
            EndIf
        EndIf
    EndIf

    ; 📊 Формируем компактную подсказку трея (с учетом лимита Windows ~127 символов)
    Local $sTooltip = "Process Manager v1.0" & @CRLF & _
                      "Процессов: " & $totalProcesses & " | Активно: " & $runningCount & " | Авто: " & $autostartCount & @CRLF & _
                      "С последнего лога: " & $sTimeSinceLastLog & @CRLF & _
                      "Клик/F2 - показать/скрыть"

    TraySetToolTip($sTooltip)
EndFunc

; 🕐 Вспомогательная функция преобразования строки времени в секунды
Func _TimeStringToSeconds($sTimeString)
    ; Формат: "2026-01-14 17:37:18"
    Local $aDateTime = StringSplit($sTimeString, " ", 1)
    If $aDateTime[0] < 2 Then Return 0

    Local $aDate = StringSplit($aDateTime[1], "-", 1)
    Local $aTime = StringSplit($aDateTime[2], ":", 1)

    If $aDate[0] < 3 Or $aTime[0] < 3 Then Return 0

    ; Вычисляем общее количество секунд с начала эпохи (упрощенно)
    Local $iYear = Int($aDate[1])
    Local $iMonth = Int($aDate[2])
    Local $iDay = Int($aDate[3])
    Local $iHour = Int($aTime[1])
    Local $iMinute = Int($aTime[2])
    Local $iSecond = Int($aTime[3])

    ; Упрощенный расчет (для разницы времени в пределах нескольких дней это достаточно точно)
    Local $iTotalSeconds = ($iYear - 2000) * 31536000 + $iMonth * 2592000 + $iDay * 86400 + $iHour * 3600 + $iMinute * 60 + $iSecond

    Return $iTotalSeconds
EndFunc

; 🚪 Функция выхода с подтверждением (вызывается из меню трея)
Func TrayExitWithConfirmation()
    ; 🎯 БЛОКИРУЮЩИЙ MsgBox с таймаутом 10 секунд (единственное исключение)
    Local $iResponse = MsgBox(4 + 32 + 256, "Подтверждение выхода", "Вы действительно хотите закрыть Process Manager?" & @CRLF & @CRLF & "Все процессы продолжат работать в фоне." & @CRLF & @CRLF & "Автоматически закроется через 10 секунд (Нет)", 10)

    If $iResponse = 6 Then ; 6 = Да
        WriteLog("СИСТЕМА", "TRAY", "🚪 Выход из программы через меню трея")
        ExitApp()
    Else
        WriteLog("КОНСОЛЬ", "TRAY", "❌ Выход отменен пользователем")
    EndIf
EndFunc
Func _NewThread($sCode)
    ; 1. Находим интерпретатор
    Local $sAutoIt = StringReplace(@AutoItExe, "ProcessManager.exe", "AutoIt3.exe")
    If Not FileExists($sAutoIt) Then $sAutoIt = @ProgramFilesDir & "\AutoIt3\AutoIt3.exe"

    ; 2. Создаем временный файл скрипта во временной папке Windows
    Local $sTempFile = @TempDir & "\au3_thread_" & Random(1000, 9999, 1) & ".au3"

    ; Добавляем в начало скрипта команду самоудаления, чтобы он не оставлял мусора
    Local $sFinalCode = 'FileDelete(@ScriptFullPath)' & @CRLF & $sCode

    Local $hFile = FileOpen($sTempFile, 2) ; Режим записи (перезапись)
    If $hFile = -1 Then Return False
    FileWrite($hFile, $sFinalCode)
    FileClose($hFile)

    ; 3. Запускаем как полноценный скрипт (это поддерживает циклы и любой код)
    ; Используем /AutoIt3ExecuteScript вместо /AutoIt3ExecuteLine
    Return Run('"' & $sAutoIt & '" /AutoIt3ExecuteScript "' & $sTempFile & '"')
EndFunc
Func _ExternalMsg($sTitle, $sText, $iTime = 5)
    ; 1. Определяем путь к интерпретатору (чтобы имя процесса было AutoIt3.exe)
    Local $sAutoIt = StringReplace(@AutoItExe, "ProcessManager.exe", "AutoIt3.exe")

    ; 2. Если рядом его нет, ищем в стандартной папке установки
    If Not FileExists($sAutoIt) Then $sAutoIt = @ProgramFilesDir & "\AutoIt3\AutoIt3.exe"

    ; 3. Если и там нет (AutoIt не установлен), используем себя, но это крайний случай
    If Not FileExists($sAutoIt) Then $sAutoIt = @AutoItExe

    ; Запускаем неблокирующее окно
    Return Run('"' & $sAutoIt & '" /AutoIt3ExecuteLine "MsgBox(4160, ''' & $sTitle & ''', ''' & $sText & ''', ' & $iTime & ')"')
EndFunc