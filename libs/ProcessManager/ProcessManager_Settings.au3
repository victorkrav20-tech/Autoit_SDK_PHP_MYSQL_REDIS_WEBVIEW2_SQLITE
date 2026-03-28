; ===============================================
; ProcessManager_Settings.au3
; Загрузка и сохранение настроек
; ===============================================

Func LoadSettingsFromINI()
    ; 🛡️ ЗАЩИТА: Проверка и восстановление из бэкапа
    If Not FileExists($sIniPath) Then
        ; Пытаемся восстановить из бэкапа
        If FileExists($sIniPath & ".backup") Then
            FileCopy($sIniPath & ".backup", $sIniPath, 1)
            WriteLog("СИСТЕМА", "RESTORE", "✅ Настройки восстановлены из backup")
        Else
            CreateDefaultINI()
            Return
        EndIf
    EndIf

    Local $count = Int(IniRead($sIniPath, "Settings", "ProcessCount", "0"))
    $aProcesses[0][0] = $count

    If $count > 0 Then
        ReDim $aProcesses[$count + 1][14]
        For $i = 1 To $count
            $aProcesses[$i][0] = IniRead($sIniPath, "Process_" & $i, "Name", "Процесс " & $i)
            $aProcesses[$i][1] = IniRead($sIniPath, "Process_" & $i, "ExePath", "")
            $aProcesses[$i][2] = Int(IniRead($sIniPath, "Process_" & $i, "IsLooped", "0"))
            $aProcesses[$i][3] = Int(IniRead($sIniPath, "Process_" & $i, "IsAutorun", "0"))
            $aProcesses[$i][4] = Int(IniRead($sIniPath, "Process_" & $i, "RestartCount", "0"))
            ; Статус не загружаем из INI файла, так как он определяется динамически
            ; Устанавливаем в "Stop" по умолчанию, MonitorProcesses определит реальный статус
            $aProcesses[$i][5] = "Stop"
            $aProcesses[$i][6] = Int(IniRead($sIniPath, "Process_" & $i, "KillDuplicates", "0"))
            $aProcesses[$i][8] = IniRead($sIniPath, "Process_" & $i, "TimerStart", "00:00:05")
            $aProcesses[$i][9] = IniRead($sIniPath, "Process_" & $i, "TimerRestart", "00:00:10")
            $aProcesses[$i][10] = IniRead($sIniPath, "Process_" & $i, "DateTime_last_start", _NowCalc())
            $aProcesses[$i][11] = TimerInit() ; Инициализация таймера при загрузке
            $aProcesses[$i][12] = 1 ; Устанавливаем флаг on_start в 1 при загрузке (означает, что это первый запуск с момента запуска менеджера)
            $aProcesses[$i][13] = "" ; Время остановки инициализируем пустой строкой
        Next
    EndIf
EndFunc

Func CreateDefaultINI()
    IniWrite($sIniPath, "Settings", "ProcessCount", "0")
    IniWrite($sIniPath, "Settings", "AutostartWithSystem", "0")
    
    ; 🛡️ ЗАЩИТА: Устанавливаем разумные лимиты логов
    IniWrite($sIniPath, "Logs", "MaxEntries", "1000")        ; Максимум записей в файле
    IniWrite($sIniPath, "Logs", "MaxDisplayEntries", "500")  ; Максимум для отображения
    IniWrite($sIniPath, "Logs", "LogCounter", "1")           ; Начальный счетчик
    
    WriteLog("СИСТЕМА", "CONFIG", "✅ Создан INI файл с настройками по умолчанию")
EndFunc

Func SaveSettingsToINI()
    ; 🛡️ ЗАЩИТА: Создаем бэкап перед сохранением
    If FileExists($sIniPath) Then
        FileCopy($sIniPath, $sIniPath & ".backup", 1)
    EndIf
    
    Local $sections = IniReadSectionNames($sIniPath)
    If Not @error Then
        For $i = 1 To $sections[0]
            If StringLeft($sections[$i], 8) = "Process_" Then IniDelete($sIniPath, $sections[$i])
        Next
    EndIf

    IniWrite($sIniPath, "Settings", "ProcessCount", $aProcesses[0][0])
    ; 🚫 Убрал сохранение AutostartWithSystem, так как чекбокс удален

    For $i = 1 To $aProcesses[0][0]
        Local $s = "Process_" & $i
        IniWrite($sIniPath, $s, "Name", $aProcesses[$i][0])
        IniWrite($sIniPath, $s, "ExePath", $aProcesses[$i][1])
        IniWrite($sIniPath, $s, "IsLooped", $aProcesses[$i][2])
        IniWrite($sIniPath, $s, "IsAutorun", $aProcesses[$i][3])
        IniWrite($sIniPath, $s, "RestartCount", $aProcesses[$i][4])
        IniWrite($sIniPath, $s, "KillDuplicates", $aProcesses[$i][6])
        IniWrite($sIniPath, $s, "TimerStart", $aProcesses[$i][8])
        IniWrite($sIniPath, $s, "TimerRestart", $aProcesses[$i][9])
        IniWrite($sIniPath, $s, "DateTime_last_start", $aProcesses[$i][10])
    Next
    
    ; 🛡️ ЗАЩИТА: Проверяем что файл сохранился корректно
    If Not FileExists($sIniPath) Then
        WriteLog("ОШИБКА", "SETTINGS", "❌ Не удалось сохранить настройки, восстанавливаем из backup")
        If FileExists($sIniPath & ".backup") Then
            FileCopy($sIniPath & ".backup", $sIniPath, 1)
        EndIf
    EndIf
EndFunc

Func SaveSettings()
    SaveSettingsToINI()
    ; 🎯 НЕБЛОКИРУЮЩИЙ MsgBox с таймаутом 3 секунды
    ;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''Успех'', ''Настройки сохранены!'', 3)"', '', @SW_SHOW)
	_ExternalMsg("✅ Успешно", "Настройки сохранены!",10)

EndFunc