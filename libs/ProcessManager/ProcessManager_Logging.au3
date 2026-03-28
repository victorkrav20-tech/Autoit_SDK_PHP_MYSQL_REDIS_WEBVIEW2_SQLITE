; ===============================================
; ProcessManager_Logging.au3
; Система логирования и отображения логов
; ===============================================

; Глобальные переменные для фильтров логов
Global $sCurrentTypeFilter = "Все"
Global $sCurrentProcessFilter = "Все"

; Улучшенная инициализация шрифтов для логов (одинакового размера)
Func InitLogFonts()
    ; Основной шрифт для обычных записей
    $hFont_Default = _WinAPI_CreateFont(13, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 2, 0, "Segoe UI")
    ; Жирный шрифт для важных записей
    $hFont_Bold = _WinAPI_CreateFont(13, 0, 0, 0, 700, 0, 0, 0, 1, 0, 0, 2, 0, "Segoe UI")
    ; Шрифт для ошибок (моноширинный, увеличен до 13)
    $hFont_Error = _WinAPI_CreateFont(13, 0, 0, 0, 500, 0, 0, 0, 1, 0, 0, 2, 0, "Consolas")
    ; Шрифт для консоли (увеличен до 13, обычная толщина)
    $hFont_Small = _WinAPI_CreateFont(13, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 2, 0, "Segoe UI")
EndFunc

; Очистка всех созданных шрифтов
Func CleanupLogFonts()
    ; Удаляем все созданные шрифты
    If $hFont_Default Then _WinAPI_DeleteObject($hFont_Default)
    If $hFont_Bold Then _WinAPI_DeleteObject($hFont_Bold)
    If $hFont_Error Then _WinAPI_DeleteObject($hFont_Error)
    If $hFont_Small Then _WinAPI_DeleteObject($hFont_Small)
EndFunc

; --- Инициализация ---
Func InitializeLogging()
    Global $iLogCounter, $sLogPath
    If Not FileExists(@ScriptDir & "\log") Then DirCreate(@ScriptDir & "\log")
    InitLogFonts() ; Initialize fonts for color coding
    $iLogCounter = LoadLogCounter() ; Загружаем счетчик из INI файла
    WriteLog("ВКЛЮЧЕНИЕ", "СИСТЕМА", "Process Manager запущен")
EndFunc

; --- Загрузка счетчика логов из INI ---
Func LoadLogCounter()
    Global $sIniPath
    Local $savedCounter = Int(IniRead($sIniPath, "Logs", "LogCounter", "0"))
    ; Если счетчик достиг 10000 или больше, сбрасываем на 1
    If $savedCounter >= 10000 Then
        $savedCounter = 1
        IniWrite($sIniPath, "Logs", "LogCounter", $savedCounter)
    ElseIf $savedCounter <= 0 Then
        $savedCounter = 1
    EndIf
    Return $savedCounter
EndFunc

; --- Сохранение счетчика логов в INI ---
Func SaveLogCounter()
    Global $sIniPath, $iLogCounter
    IniWrite($sIniPath, "Logs", "LogCounter", $iLogCounter)
EndFunc

; --- Подсчет записей ---
Func GetLogEntriesCount()
    If Not FileExists($sLogPath) Then Return 0
    Local $iCount = 0
    Local $hFile = FileOpen($sLogPath, 0)
    If $hFile = -1 Then Return 0

    While 1
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop
        If StringLen(StringStripWS($sLine, 3)) > 0 Then $iCount += 1
    WEnd
    FileClose($hFile)
    Return $iCount
EndFunc

Func RefreshLogsNew()
    If $listViewLogs Then LoadLogsToListView($listViewLogs)
EndFunc

; 📊 Функция мониторинга изменений файла Watchdog.log
Func CheckWatchdogLogChanges()
    ; Проверяем только если открыто окно логов и выбран WATCHDOG
    If Not $bLogWindowActive Or $sCurrentProcessFilter <> "WATCHDOG" Then Return
    
    ; Проверяем существование файла
    If Not FileExists($sWatchdogLogPath) Then Return
    
    ; Получаем текущий размер и время модификации
    Local $iCurrentSize = FileGetSize($sWatchdogLogPath)
    Local $sCurrentModified = FileGetTime($sWatchdogLogPath, 0, 1) ; Время модификации в формате YYYYMMDDHHMMSS
    
    ; Если файл изменился - обновляем GUI
    If $iCurrentSize <> $iWatchdogLastSize Or $sCurrentModified <> $sWatchdogLastModified Then
        $iWatchdogLastSize = $iCurrentSize
        $sWatchdogLastModified = $sCurrentModified
        RefreshLogsNew()
    EndIf
EndFunc

; --- Основная функция записи ---
Func WriteLog($sGroup1, $sGroup2, $sMessage)
    ; 🛡️ ЗАЩИЩЕННАЯ СИСТЕМА ЗАПИСИ ЛОГОВ С RETRY
    Global $iLogCounter, $sLogPath, $iMaxLogEntries
    
    Local $iMaxRetries = 5
    Local $iRetryDelay = 50  ; 50мс между попытками
    Local $bSuccess = False
    
    $iLogCounter += 1

    ; Циклический счетчик от 1 до 10000
    If $iLogCounter > 10000 Then
        $iLogCounter = 1
    EndIf

    ; Сохраняем текущий счетчик в INI
    SaveLogCounter()

    Local $sMarker = ""
    Switch $sGroup1
        Case "ВКЛЮЧЕНИЕ", "ЗАПУСК"
            $sMarker = "[+]"
        Case "ОТКЛЮЧЕНИЕ", "ОСТАНОВКА"
            $sMarker = "[-]"
        Case "ОШИБКА"
            $sMarker = "[!]"
        Case "КОНСОЛЬ"
            $sMarker = "[*]"
        Case "СИСТЕМА"
            $sMarker = "[#]"
        Case "ИЗМЕНЕНИЕ"
            $sMarker = "[~]"
        Case Else
            $sMarker = "[?]"
    EndSwitch

    Local $sDateTime = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    ; Форматируем строку с выравниванием (используем 4-значный ID)
    Local $sLogEntry = StringFormat("%s %04d | %s | %-12s | %-15s | %s", $sMarker, $iLogCounter, $sDateTime, $sGroup1, $sGroup2, $sMessage)

    ; Проверяем лимит записей в файле (не влияет на счетчик ID)
    Local $currentFileEntries = GetLogEntriesCount()
    If $currentFileEntries > $iMaxLogEntries Then TrimLogFile()

    ; 🔄 RETRY МЕХАНИЗМ: Пытаемся записать 5 раз
    For $iAttempt = 1 To $iMaxRetries
        Local $hFile = FileOpen($sLogPath, 1) ; Режим добавления
        
        If $hFile <> -1 Then
            ; Пытаемся записать
            Local $iBytesWritten = FileWriteLine($hFile, $sLogEntry)
            FileClose($hFile)
            
            If $iBytesWritten > 0 Then
                $bSuccess = True
                ExitLoop ; Успешно записали, выходим
            EndIf
        EndIf
        
        ; Если не удалось, ждем и пробуем снова
        If $iAttempt < $iMaxRetries Then Sleep($iRetryDelay)
    Next
    
    ; 🚨 РЕЗЕРВНАЯ СИСТЕМА: Если все попытки провалились
    If Not $bSuccess Then
        _WriteFatalErrorLog("ProcessManager", $sLogEntry, "Не удалось записать в основной лог после " & $iMaxRetries & " попыток")
    EndIf

    ; If log window is open - update it on the fly (только для соответствующего файла)
    If $bLogWindowActive And $listViewLogs Then
        ; Обновляем только если просматриваем ProcessManager логи (не WATCHDOG)
        If $sCurrentProcessFilter <> "WATCHDOG" Then
            RefreshLogsNew()
        EndIf
    EndIf
EndFunc

; 🚨 Функция записи в резервный лог при критических ошибках
Func _WriteFatalErrorLog($sSystem, $sOriginalEntry, $sErrorReason)
    Local $sFatalLogPath = @ScriptDir & "\log\Fatal_Error_" & $sSystem & ".log"
    Local $sFatalEntry = "[FATAL] " & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " | ПРИЧИНА: " & $sErrorReason & @CRLF & "ПОТЕРЯННАЯ ЗАПИСЬ: " & $sOriginalEntry & @CRLF & "====================" & @CRLF
    
    ; Пытаемся записать в резервный файл (без retry, чтобы не зациклиться)
    Local $hFatalFile = FileOpen($sFatalLogPath, 1)
    If $hFatalFile <> -1 Then
        FileWrite($hFatalFile, $sFatalEntry)
        FileClose($hFatalFile)
    EndIf
EndFunc

; --- Обрезка файла логов ---
Func TrimLogFile()
    If Not FileExists($sLogPath) Then Return
    Local $aLines = FileReadToArray($sLogPath)
    If @error Then Return

    Local $iKeepLines = $iMaxLogEntries
    Local $iStartIndex = UBound($aLines) - $iKeepLines
    If $iStartIndex < 0 Then $iStartIndex = 0

    Local $hFile = FileOpen($sLogPath, 2) ; Режим перезаписи (Write)
    If $hFile <> -1 Then
        For $i = $iStartIndex To UBound($aLines) - 1
            FileWriteLine($hFile, $aLines[$i])
        Next
        FileClose($hFile)
    EndIf
    ; IMPORTANT: $iLogCounter is NOT reset - it continues incrementing for unique IDs
    ; Counter ID is independent of the number of entries in the file
EndFunc
; --- GUI Логов ---
Func ShowLogsNew()
    If $bLogWindowActive Then
        WinActivate($hLogWindow)
        Return
    EndIf

    $bLogWindowActive = True
    Local $logWindowWidth = $iClientHeight
    Local $logWindowHeight = 700

    $hLogWindow = GUICreate("Система логирования Process Manager", $logWindowWidth, $logWindowHeight,  ((@DesktopWidth - $logWindowWidth) / 2)+10, ((@DesktopHeight - $logWindowHeight) / 2)-10, BitOR($WS_OVERLAPPEDWINDOW, $WS_VISIBLE), -1, $hGUI)
	_WinAPI_SetClassLongEx($hLogWindow, -26, BitAND(_WinAPI_GetClassLongEx($hLogWindow, -26), BitNOT(1), BitNOT(2)))
    Local $logFon = GUICtrlCreatePic('Includes\4.jpg', 0, 0, $logWindowWidth, $logWindowHeight, $WS_CLIPSIBLINGS)
    GUICtrlSetState($logFon, $GUI_DISABLE)
    Local $hFonHandle = GUICtrlGetHandle($logFon)
    _WinAPI_SetWindowPos($hFonHandle, $HWND_BOTTOM, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE))

    Local $lblLogTitle = GUICtrlCreateLabel("📋   Система логирования событий и отображение в виде списка", (($logWindowWidth - ($logWindowWidth*0.98)) / 2), 15, $logWindowWidth*0.98, 45, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 20, 1000, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xFC9726)

    Local $lblLimit = GUICtrlCreateLabel("Лимит записей:", 20, 70, 140, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)

    Global $inputMaxEntries = GUICtrlCreateInput($iMaxLogEntries, 170, 69, 80, 27,BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0x6AD4FE)
    Local $btnApplyLimit = GUICtrlCreateButton("  Применить", 260, 69, 140, 27)
    GUICtrlSetFont(-1, 11, 600, 0, "Segoe UI")

    Local $lblDisplayLimit = GUICtrlCreateLabel("Лимит показа:", 20, 103, 140, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)

    Global $inputMaxDisplay = GUICtrlCreateInput($iMaxDisplayEntries, 170, 102, 80, 27, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0x6AD4FE)
    Local $btnApplyDisplay = GUICtrlCreateButton("  Применить", 260, 102, 140, 27)
    GUICtrlSetFont(-1, 11, 600, 0, "Segoe UI")

    Local $lblFilterType = GUICtrlCreateLabel("Фильтр по типу:", 450, 70, 180, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)

    Global $comboFilterType = GUICtrlCreateCombo("Все", 640, 69, 200, 27, 0x0003)
    GUICtrlSetData(-1, "ВКЛЮЧЕНИЕ|ОТКЛЮЧЕНИЕ|ОШИБКА|КОНСОЛЬ|СИСТЕМА|ИЗМЕНЕНИЕ")
    GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)
    GUICtrlSetOnEvent(-1, "OnFilterChange")

    Local $lblFilterProcess = GUICtrlCreateLabel("Фильтр по процессу:", 450, 103, 180, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)

    Global $comboFilterProcess = GUICtrlCreateCombo("Все", 640, 103, 200, 27, 0x0003)
    GUICtrlSetFont(-1, 11, 800, 0, "Segoe UI")
    GUICtrlSetColor(-1, 0x740E68)
    GUICtrlSetBkColor(-1, 0xA2F630)
    GUICtrlSetOnEvent(-1, "OnFilterChange")

    UpdateProcessFilter()

    Local $listViewWidth = $logWindowWidth - 40
    Global $listViewLogs = GUICtrlCreateListView("ID|Время|Тип|Группа|Процесс|Сообщение", 20, 138, $listViewWidth, 470, _
        BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS), BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))

    Local $idWidth = 60
    Local $timeWidth = 160
    Local $typeWidth = 140
    Local $groupWidth = 120
    Local $processWidth = 140
    Local $messageWidth = $listViewWidth - ($idWidth + $timeWidth + $typeWidth + $groupWidth + $processWidth)

    _GUICtrlListView_SetColumnWidth($listViewLogs, 0, $idWidth)
    _GUICtrlListView_SetColumnWidth($listViewLogs, 1, $timeWidth)
    _GUICtrlListView_SetColumnWidth($listViewLogs, 2, $typeWidth)
    _GUICtrlListView_SetColumnWidth($listViewLogs, 3, $groupWidth)
    _GUICtrlListView_SetColumnWidth($listViewLogs, 4, $processWidth)
    _GUICtrlListView_SetColumnWidth($listViewLogs, 5, $messageWidth)

    If $hFont_Default Then GUICtrlSetFont($listViewLogs, 13, 400, 0, "Segoe UI")

    LoadLogsToListView($listViewLogs)
    GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY_Handler")

    Local $btnRefresh = GUICtrlCreateButton(" Обновить", 20, 620, 130, 40)
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")

    Local $btnClearLogs = GUICtrlCreateButton(" Очистить", 160, 620, 130, 40)
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")

    Local $btnSyncWatchdog = GUICtrlCreateButton("  Синхр.", 300, 620, 130, 40)
    GUICtrlSetFont(-1, 12, 600, 0, "Segoe UI")
    GUICtrlSetOnEvent($btnSyncWatchdog, "SyncWatchdogSettings")

    GUICtrlSetOnEvent($btnApplyLimit, "ApplyLogLimit")
    GUICtrlSetOnEvent($btnApplyDisplay, "ApplyDisplayLimit")
    GUICtrlSetOnEvent($btnRefresh, "RefreshLogsNew")
    GUICtrlSetOnEvent($btnClearLogs, "ClearLogs")
    GUICtrlSetOnEvent($btnSyncWatchdog, "SyncWatchdogSettings")
    GUISetOnEvent($GUI_EVENT_CLOSE, "CloseLogWindow")
    GUISetState(@SW_SHOW, $hLogWindow)
EndFunc

; Функция определения пути к файлу логов в зависимости от выбранного процесса
Func GetLogPathByProcess($sProcessFilter)
    If $sProcessFilter = "WATCHDOG" Then
        Return @ScriptDir & "\log\Watchdog.log"  ; Независимые логи Watchdog
    Else
        Return $sLogPath ; ProcessManager.log по умолчанию
    EndIf
EndFunc

Func LoadLogsToListView($listViewControl)
    ; Определяем какой файл логов читать в зависимости от фильтра процесса
    Local $sCurrentLogPath = GetLogPathByProcess($sCurrentProcessFilter)
    
    If Not FileExists($sCurrentLogPath) Then Return
    _GUICtrlListView_DeleteAllItems($listViewControl)

    Local $aLogLines = FileReadToArray($sCurrentLogPath)
    If @error Then Return

    _GUICtrlListView_BeginUpdate($listViewControl)

    Local $iDisplayedCount = 0
    For $i = UBound($aLogLines) - 1 To 0 Step -1
        If $iDisplayedCount >= $iMaxDisplayEntries Then ExitLoop

        Local $sLine = StringStripWS($aLogLines[$i], 3)
        If StringLen($sLine) > 0 Then
            Local $aParts = StringSplit($sLine, "|", 1)
            If $aParts[0] >= 5 Then
                Local $sFirstPart = StringStripWS($aParts[1], 3)
                Local $sMarker = StringLeft($sFirstPart, 3)
                Local $sID = StringStripWS(StringMid($sFirstPart, 5), 3)
                Local $sGroup = StringStripWS($aParts[3], 3)
                Local $sProcess = StringStripWS($aParts[4], 3)

                If PassesFilters($sGroup, $sProcess) Then
                    Local $iItem = _GUICtrlListView_AddItem($listViewControl, $sID)
                    _GUICtrlListView_SetItemText($listViewControl, $iItem, StringStripWS($aParts[2], 3), 1)
                    _GUICtrlListView_SetItemText($listViewControl, $iItem, $sMarker & " " & $sGroup, 2)
                    _GUICtrlListView_SetItemText($listViewControl, $iItem, $sGroup, 3)
                    _GUICtrlListView_SetItemText($listViewControl, $iItem, $sProcess, 4)
                    _GUICtrlListView_SetItemText($listViewControl, $iItem, StringStripWS($aParts[5], 3), 5)
                    $iDisplayedCount += 1
                EndIf
            EndIf
        EndIf
    Next
    _GUICtrlListView_EndUpdate($listViewControl)
	Local $hHeader = _GUICtrlListView_GetHeader($listViewLogs)
	_WinAPI_RedrawWindow($hHeader)
EndFunc

Func OnFilterChange()
    $sCurrentTypeFilter = GUICtrlRead($comboFilterType)
    $sCurrentProcessFilter = GUICtrlRead($comboFilterProcess)
    RefreshLogsNew()
EndFunc

Func UpdateProcessFilter()
    If Not $comboFilterProcess Then Return

    Local $sProcessList = "Все"

    For $i = 1 To $aProcesses[0][0]
        If $aProcesses[$i][0] <> "" Then
            If $sProcessList = "" Then
                $sProcessList = $aProcesses[$i][0]
            Else
                $sProcessList &= "|" & $aProcesses[$i][0]
            EndIf
        EndIf
    Next

    If $sProcessList = "" Then
        $sProcessList = "СИСТЕМА|WATCHDOG"
    Else
        $sProcessList &= "|СИСТЕМА|WATCHDOG"
    EndIf

    GUICtrlSetData($comboFilterProcess, "|" & $sProcessList)
	GUICtrlSetData($comboFilterProcess,'Все')
EndFunc

Func PassesFilters($sGroup, $sProcess)
    ; Фильтр по типу (группе) - работает всегда
    If $sCurrentTypeFilter <> "Все" Then
        Local $bTypeMatch = False

        Switch $sCurrentTypeFilter
            Case "ВКЛЮЧЕНИЕ"
                If $sGroup = "ВКЛЮЧЕНИЕ" Or $sGroup = "ЗАПУСК" Then $bTypeMatch = True
            Case "ОТКЛЮЧЕНИЕ"
                If $sGroup = "ОТКЛЮЧЕНИЕ" Or $sGroup = "ОСТАНОВКА" Then $bTypeMatch = True
            Case Else
                If $sGroup = $sCurrentTypeFilter Then $bTypeMatch = True
        EndSwitch

        If Not $bTypeMatch Then Return False
    EndIf

    ; Фильтр по процессу - НЕ работает для WATCHDOG (показываем все записи из Watchdog.log)
    If $sCurrentProcessFilter <> "Все" And $sCurrentProcessFilter <> "WATCHDOG" Then
        If $sProcess <> $sCurrentProcessFilter Then Return False
    EndIf

    Return True
EndFunc

Func CloseLogWindow()
    $bLogWindowActive = False
    $sCurrentTypeFilter = "Все"
    $sCurrentProcessFilter = "Все"
    $comboFilterType = 0
    $comboFilterProcess = 0
    GUIRegisterMsg($WM_NOTIFY, "")
    GUIDelete($hLogWindow)
    $hLogWindow = 0
EndFunc
Func WM_NOTIFY_Handler($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $wParam ; Suppress unused parameter warnings
    Local $tNMHDR, $hWndFrom, $iCode
    $tNMHDR = DllStructCreate("hwnd hWndFrom;uint_ptr IDFrom;int Code", $lParam)
    $hWndFrom = DllStructGetData($tNMHDR, "hWndFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")

    Local $hListViewHandle = GUICtrlGetHandle($listViewLogs)
    If $hWndFrom <> $hListViewHandle Or $iCode <> -12 Then Return $GUI_RUNDEFMSG

    Local $tNMLVCD = DllStructCreate("hwnd hWndFrom;uint_ptr IDFrom;int Code;dword dwDrawStage;hwnd hdc;long left;long top;long right;long bottom;uint_ptr dwItemSpec;uint uItemState;uint_ptr lItemlParam;dword clrText;dword clrTextBk;int iSubItem;dword dwItemType;dword clrFace;int iIconEffect;int iIconPhase;int iPartId;int iStateId;long left2;long top2;long right2;long bottom2;uint uAlign", $lParam)
    Local $dwDrawStage = DllStructGetData($tNMLVCD, "dwDrawStage")

    If $dwDrawStage = 0x00000001 Then Return 0x00000020

    If $dwDrawStage = 0x00010001 Then
        Local $dwItemSpec = DllStructGetData($tNMLVCD, "dwItemSpec")
        Local $hDC = DllStructGetData($tNMLVCD, "hdc")

        Local $sGroup = _GUICtrlListView_GetItemText($listViewLogs, $dwItemSpec, 3)

        Switch $sGroup
            Case "ВКЛЮЧЕНИЕ", "ЗАПУСК"
                DllStructSetData($tNMLVCD, "clrText", 0x006400)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xF0FFF0)
                _WinAPI_SelectObject($hDC, $hFont_Bold)
            Case "ОТКЛЮЧЕНИЕ", "ОСТАНОВКА"
                DllStructSetData($tNMLVCD, "clrText", 0x8B0000)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xFFF0F0)
                _WinAPI_SelectObject($hDC, $hFont_Bold)
            Case "ОШИБКА"
                DllStructSetData($tNMLVCD, "clrText", 0xFFFFFF)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xFF4500)
                _WinAPI_SelectObject($hDC, $hFont_Error)
            Case "КОНСОЛЬ"
                DllStructSetData($tNMLVCD, "clrText", 0x696969)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xFFFFFF)
                _WinAPI_SelectObject($hDC, $hFont_Default)
            Case "СИСТЕМА"
                DllStructSetData($tNMLVCD, "clrText", 0x800080)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xFFFFFF)
                _WinAPI_SelectObject($hDC, $hFont_Bold)
            Case "ИЗМЕНЕНИЕ"
                DllStructSetData($tNMLVCD, "clrText", 0x008B8B)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xF0FFFF)
                _WinAPI_SelectObject($hDC, $hFont_Default)
            Case Else
                DllStructSetData($tNMLVCD, "clrText", 0x000000)
                DllStructSetData($tNMLVCD, "clrTextBk", 0xFFFFFF)
        EndSwitch

        Return 0x00000002
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc

Func ApplyLogLimit()
    Local $newLimit = Int(GUICtrlRead($inputMaxEntries))
    If $newLimit > 0 And $newLimit <= 10000 Then
        $iMaxLogEntries = $newLimit
        IniWrite($sIniPath, "Logs", "MaxEntries", $iMaxLogEntries)
        ; 🎯 НЕБЛОКИРУЮЩИЙ MsgBox с таймаутом 3 секунды
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''' & "Информация" & ''', ''' & "Лимит записей изменен на: " & $iMaxLogEntries & " записей " & ''', 5)"')
		_ExternalMsg("Информация", "Лимит записей изменен на: " & $iMaxLogEntries & " записей ",5)
        Local $currentFileEntries = GetLogEntriesCount()
        If $currentFileEntries > $iMaxLogEntries Then
            TrimLogFile()
            RefreshLogsNew()
        EndIf
    Else
        ; 🎯 НЕБЛОКИРУЮЩИЙ MsgBox с таймаутом 3 секунды
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "ConsoleWriteError(MsgBox(4096, ''Ошибка'', ''Введите корректное значение (1-10000)''))"', '', '', 4)
		_ExternalMsg("Информация", "Введите корректное значение (1-10000)",5)
    EndIf
EndFunc

Func ApplyDisplayLimit()
    Local $newDisplayLimit = Int(GUICtrlRead($inputMaxDisplay))
    If $newDisplayLimit > 0 And $newDisplayLimit <= 10000 Then
        $iMaxDisplayEntries = $newDisplayLimit
        IniWrite($sIniPath, "Logs", "MaxDisplayEntries", $iMaxDisplayEntries)
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(0, ''Информация'', ''Лимит показа изменен на: ' & $iMaxDisplayEntries & ''', 3)"', '', @SW_SHOW)
		_ExternalMsg("Информация", "Лимит показа изменен на: " & $iMaxDisplayEntries & "",3)
        RefreshLogsNew()
    Else
		;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(0, ''Информация'', ''Введите корректное значение (1-10000)'', 3)"', '', @SW_SHOW)
		_ExternalMsg("Информация", "Введите корректное значение (1-10000)",3)
    EndIf
EndFunc

Func ClearLogs()
    Local $iResult = MsgBox(4, "Подтверждение", "Вы уверены, что хотите очистить все логи?",10)
    If $iResult = 6 Then
        FileDelete($sLogPath)
        $iLogCounter = 0
        WriteLog("СИСТЕМА", "СИСТЕМА", "Логи очищены пользователем")
        RefreshLogsNew()
    EndIf
EndFunc

Func SaveLogSettings()
    IniWrite($sIniPath, "Logs", "MaxEntries", $iMaxLogEntries)
	Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(0, ''Информация'', ''Настройки логирования сохранены!'', 3)"', '', @SW_SHOW)
	_ExternalMsg("Информация", "Настройки логирования сохранены!",3)
EndFunc

; Функция синхронизации настроек с Watchdog
Func SyncWatchdogSettings()
    Local $sWatchdogIni = @ScriptDir & "\config\WatchdogConfig.ini"
    
    ; Синхронизируем настройки логов из ProcessManager в Watchdog
    IniWrite($sWatchdogIni, "Logs", "MaxEntries", $iMaxLogEntries)
    IniWrite($sWatchdogIni, "Logs", "MaxDisplayEntries", $iMaxDisplayEntries)
    IniWrite($sWatchdogIni, "Logs", "MaxLogSize", IniRead($sIniPath, "Logs", "MaxLogSize", "2097152"))
    
    ; Синхронизируем настройки отображения
    IniWrite($sWatchdogIni, "Logs", "ShowInclusions", IniRead($sIniPath, "Logs", "ShowInclusions", "1"))
    IniWrite($sWatchdogIni, "Logs", "ShowExclusions", IniRead($sIniPath, "Logs", "ShowExclusions", "1"))
    IniWrite($sWatchdogIni, "Logs", "ShowErrors", IniRead($sIniPath, "Logs", "ShowErrors", "1"))
    IniWrite($sWatchdogIni, "Logs", "ShowConsole", IniRead($sIniPath, "Logs", "ShowConsole", "1"))
    IniWrite($sWatchdogIni, "Logs", "ShowOther", IniRead($sIniPath, "Logs", "ShowOther", "1"))
    
    WriteLog("СИСТЕМА", "SYNC", "📋 Настройки синхронизированы с Watchdog")
 ;   MsgBox(0, "Синхронизация", "Настройки логов успешно синхронизированы с Watchdog!" & @CRLF & @CRLF & _
 ;          "Синхронизированы:" & @CRLF & _
 ;          "• Лимиты записей и отображения" & @CRLF & _
 ;          "• Размер файла логов" & @CRLF & _
 ;          "• Настройки фильтров отображения")
    
    ; Обновляем отображение если выбран Watchdog
    If $sCurrentProcessFilter = "WATCHDOG" Then
        RefreshLogsNew()
    EndIf
EndFunc

Func TestLogCyclicity()
    WriteLog("СИСТЕМА", "ТЕСТ", "🚀 Начало тестирования системы логирования")
    WriteLog("ЗАПУСК", "TestApp1", "Автоматический запуск тестового приложения №1")
    WriteLog("ВКЛЮЧЕНИЕ", "TestApp2", "Ручной запуск тестового приложения №2")
    WriteLog("КОНСОЛЬ", "TestApp3", "Добавлен новый процесс в систему")
    WriteLog("ОШИБКА", "TestApp1", "Файл не найден: C:\test\missing.exe")
    WriteLog("ОСТАНОВКА", "TestApp2", "Автоматическая остановка процесса")
    WriteLog("ОТКЛЮЧЕНИЕ", "TestApp1", "Процесс остановлен пользователем")
    WriteLog("ИЗМЕНЕНИЕ", "TestApp3", "Статус изменен: Stopped → Runned (процесс запущен)")
    WriteLog("ИЗМЕНЕНИЕ", "TestApp1", "Статус изменен: Runned → Stopped (процесс остановлен)")
    WriteLog("СИСТЕМА", "ТЕСТ", "⚡ Проверка автозапуска процессов")
    WriteLog("КОНСОЛЬ", "TestApp4", "Изменены настройки таймеров")
    WriteLog("ОШИБКА", "TestApp3", "Превышено время ожидания запуска")
    WriteLog("ЗАПУСК", "TestApp1", "Повторный автозапуск после ошибки")
    WriteLog("ОСТАНОВКА", "TestApp4", "Автоматическая остановка по расписанию")
    WriteLog("СИСТЕМА", "ТЕСТ", "🔄 Проверка цикличности логов")
    WriteLog("КОНСОЛЬ", "СИСТЕМА", "Применен новый лимит записей: " & $iMaxLogEntries)
    WriteLog("ОШИБКА", "TestApp2", "Критическая ошибка: Access violation")
    WriteLog("ИЗМЕНЕНИЕ", "TestApp2", "Статус изменен: Error → Stopped (процесс аварийно завершен)")
    WriteLog("СИСТЕМА", "ТЕСТ", "✅ Тестирование завершено успешно")

 ;   MsgBox(0, "Тест завершен", "Создано 19 разнообразных тестовых записей с расширенным цветовым кодированием!" & @CRLF & @CRLF & _
 ;          "[+] ЗАПУСК/ВКЛЮЧЕНИЕ - зеленый цвет (автоматический/ручной запуск)" & @CRLF & _
 ;          "[-] ОСТАНОВКА/ОТКЛЮЧЕНИЕ - оранжевый цвет (автоматическая/ручная остановка)" & @CRLF & _
 ;          "[!] ОШИБКА - красный цвет (критические ошибки)" & @CRLF & _
 ;          "[*] КОНСОЛЬ - синий цвет (пользовательские действия)" & @CRLF & _
 ;          "[#] СИСТЕМА - фиолетовый цвет (системные события)" & @CRLF & _
 ;          "[~] ИЗМЕНЕНИЕ - бирюзовый цвет (изменения статуса процессов)" & @CRLF & @CRLF & _
 ;          "Логи отображаются в обратном порядке (новые сверху)" & @CRLF & _
 ;          "Колонка сообщений расширена для лучшей читаемости")
EndFunc