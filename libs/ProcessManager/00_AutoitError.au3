#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo /rsln
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <Date.au3>
#include <File.au3>
#include <Constants.au3>
#include <MsgBoxConstants.au3>

; --- Конфигурация для Watchdog (независимая от ProcessManager) ---
Global $sMainExeName = "ProcessManager.exe"
Global $sMainExePath = @ScriptDir & "\" & $sMainExeName
Global $sWatchdogLogPath = @ScriptDir & "\log\Watchdog.log"
Global $sWatchdogIniPath = @ScriptDir & "\config\WatchdogConfig.ini"
Global $iWatchdogLogCounter = 0
Global $process_timer = TimerInit()

; Старая система логирования AutoIt ошибок (независимая)
Global $sAutoitErrorPath = @ScriptDir & "\log\AutoitErrors.txt"

; 🔥 WMI СИСТЕМА МОНИТОРИНГА ProcessManager.exe (ОТКЛЮЧЕНА для стабильности)
Global $bWMIEnabled = True
Global $oWMIService = 0
Global $oWMIEventSink = 0
Global $wmi_timer = TimerInit()
Global $iWMIErrors = 0
Global $bWMIInitialized = False
Global $bWMIEventsActive = False

; 🔄 УПРАВЛЕНИЕ РЕЖИМАМИ WMI
Global $iWMIEventFailures = 0
Global $bWMIEventsMode = False ; True = Events, False = Polling
Global $bWMIReinitInProgress = False

; 🛡️ ЗАЩИТА ОТ ДВОЙНОГО ЗАПУСКА (УСИЛЕННАЯ)
Global $last_restart_timer = 0
Global $sLastRestartSource = ""
Global $iMinRestartInterval = 1000 ; Минимум 1 секунда между запусками (ускорено для WMI)

; Старая система логирования (оставляем для совместимости)
Global $sFilePath = $sAutoitErrorPath

; 🛡️ ГЛОБАЛЬНЫЙ ПЕРЕХВАТ ОШИБОК COM/WMI
Global $oMyError = ObjEvent("AutoIt.Error", "_WMIErrorHandler")

; 🧹 ПЕРЕМЕННЫЕ ДЛЯ ОЧИСТКИ WMI РЕСУРСОВ
Global $wmi_cleanup_timer = TimerInit()
Global $iWMICleanupInterval = 300000 ; 5 минут между проверками
Global $sWMIInstanceID = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC & @MSEC ; Уникальный ID экземпляра

; --- ФУНКЦИИ ЛОГИРОВАНИЯ ДЛЯ WATCHDOG ---

; Инициализация логирования для watchdog
Func InitializeWatchdogLogging()
    If Not FileExists(@ScriptDir & "\log") Then DirCreate(@ScriptDir & "\log")
    $iWatchdogLogCounter = LoadWatchdogLogCounter()
    WriteWatchdogLog("ВКЛЮЧЕНИЕ", "WATCHDOG", "⚡ AutoIt Error Watchdog запущен (БЫСТРЫЙ СТАРТ)")
    WriteWatchdogLog("СИСТЕМА", "OPTIMIZATION", "⚡ CPU оптимизация: WMI ОТКЛЮЧЕН, Polling режим, Sleep 100мс")
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚡ WMI очистка: БЫСТРЫЙ режим, только завершение процессов")
EndFunc

; Загрузка счетчика логов watchdog
Func LoadWatchdogLogCounter()
    Local $savedCounter = Int(IniRead($sWatchdogIniPath, "Watchdog", "LogCounter", "1"))
    Local $maxEntries = Int(IniRead($sWatchdogIniPath, "Logs", "MaxEntries", "1000"))

    If $savedCounter >= $maxEntries Then
        $savedCounter = 1
        IniWrite($sWatchdogIniPath, "Watchdog", "LogCounter", $savedCounter)
    ElseIf $savedCounter <= 0 Then
        $savedCounter = 1
    EndIf
    Return $savedCounter
EndFunc

; Сохранение счетчика логов watchdog
Func SaveWatchdogLogCounter()
    IniWrite($sWatchdogIniPath, "Watchdog", "LogCounter", $iWatchdogLogCounter)
EndFunc

; Функция записи логов для watchdog (по аналогии с ProcessManager)
Func WriteWatchdogLog($sGroup1, $sGroup2, $sMessage)
    ; 🛡️ ЗАЩИЩЕННАЯ СИСТЕМА ЗАПИСИ ЛОГОВ С RETRY
    Local $iMaxRetries = 5
    Local $iRetryDelay = 50  ; 50мс между попытками
    Local $bSuccess = False
    
    $iWatchdogLogCounter += 1

    ; Циклический счетчик от 1 до 10000 (как в ProcessManager)
    If $iWatchdogLogCounter > 10000 Then
        $iWatchdogLogCounter = 1
    EndIf

    ; Сохраняем текущий счетчик в INI
    SaveWatchdogLogCounter()

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
        Case "ПРЕДУПРЕЖДЕНИЕ"
            $sMarker = "[!]"
        Case Else
            $sMarker = "[?]"
    EndSwitch

    Local $sDateTime = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    ; Форматируем строку с выравниванием (используем 4-значный ID)
    Local $sLogEntry = StringFormat("%s %04d | %s | %-12s | %-15s | %s", $sMarker, $iWatchdogLogCounter, $sDateTime, $sGroup1, $sGroup2, $sMessage)

    ; Проверяем лимит записей в файле (не влияет на счетчик ID)
    Local $currentFileEntries = GetWatchdogLogEntriesCount()
    Local $maxEntries = Int(IniRead($sWatchdogIniPath, "Logs", "MaxEntries", "1000"))
    If $currentFileEntries > $maxEntries Then TrimWatchdogLogFile()

    ; 🔄 RETRY МЕХАНИЗМ: Пытаемся записать 5 раз
    For $iAttempt = 1 To $iMaxRetries
        Local $hFile = FileOpen($sWatchdogLogPath, 1) ; Режим добавления
        
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
        _WriteFatalErrorLogWatchdog($sLogEntry, "Не удалось записать в основной лог после " & $iMaxRetries & " попыток")
    EndIf
EndFunc

; 🚨 Функция записи в резервный лог Watchdog при критических ошибках
Func _WriteFatalErrorLogWatchdog($sOriginalEntry, $sErrorReason)
    Local $sFatalLogPath = @ScriptDir & "\log\Fatal_Error_Watchdog.log"
    Local $sFatalEntry = "[FATAL] " & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & " | ПРИЧИНА: " & $sErrorReason & @CRLF & "ПОТЕРЯННАЯ ЗАПИСЬ: " & $sOriginalEntry & @CRLF & "====================" & @CRLF
    
    ; Пытаемся записать в резервный файл (без retry, чтобы не зациклиться)
    Local $hFatalFile = FileOpen($sFatalLogPath, 1)
    If $hFatalFile <> -1 Then
        FileWrite($hFatalFile, $sFatalEntry)
        FileClose($hFatalFile)
    EndIf
EndFunc

; Подсчет записей в файле Watchdog логов
Func GetWatchdogLogEntriesCount()
    If Not FileExists($sWatchdogLogPath) Then Return 0
    Local $iCount = 0
    Local $hFile = FileOpen($sWatchdogLogPath, 0)
    If $hFile = -1 Then Return 0

    While 1
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop
        If StringLen(StringStripWS($sLine, 3)) > 0 Then $iCount += 1
    WEnd
    FileClose($hFile)
    Return $iCount
EndFunc

; Функция обрезки файла логов Watchdog (по аналогии с ProcessManager)
Func TrimWatchdogLogFile()
    If Not FileExists($sWatchdogLogPath) Then Return
    Local $aLines = FileReadToArray($sWatchdogLogPath)
    If @error Then Return

    Local $maxEntries = Int(IniRead($sWatchdogIniPath, "Logs", "MaxEntries", "1000"))
    Local $iKeepLines = $maxEntries
    Local $iStartIndex = UBound($aLines) - $iKeepLines
    If $iStartIndex < 0 Then $iStartIndex = 0

    Local $hFile = FileOpen($sWatchdogLogPath, 2) ; Режим перезаписи (Write)
    If $hFile <> -1 Then
        For $i = $iStartIndex To UBound($aLines) - 1
            FileWriteLine($hFile, $aLines[$i])
        Next
        FileClose($hFile)
    EndIf
    ; ВАЖНО: $iWatchdogLogCounter НЕ сбрасывается - продолжает инкрементироваться для уникальных ID
    ; Счетчик ID независим от количества записей в файле
EndFunc

; Функция синхронизации настроек логов из ProcessManager
Func SyncLogsSettingsFromProcessManager()
    Local $sProcessManagerIni = @ScriptDir & "\config\ProcessConfig.ini"

    ; Синхронизируем только настройки отображения логов
    If FileExists($sProcessManagerIni) Then
        Local $maxEntries = IniRead($sProcessManagerIni, "Logs", "MaxEntries", "1000")
        Local $maxDisplayEntries = IniRead($sProcessManagerIni, "Logs", "MaxDisplayEntries", "500")
        Local $maxLogSize = IniRead($sProcessManagerIni, "Logs", "MaxLogSize", "2097152")

        ; Записываем в наш конфиг
        IniWrite($sWatchdogIniPath, "Logs", "MaxEntries", $maxEntries)
        IniWrite($sWatchdogIniPath, "Logs", "MaxDisplayEntries", $maxDisplayEntries)
        IniWrite($sWatchdogIniPath, "Logs", "MaxLogSize", $maxLogSize)

        WriteWatchdogLog("СИСТЕМА", "SYNC", "📋 Настройки логов синхронизированы с ProcessManager")
    EndIf
EndFunc

; --- 🧹 ФУНКЦИИ ОЧИСТКИ WMI РЕСУРСОВ ---

; Функция быстрой очистки WMI ресурсов при запуске (БЕЗ ЗАДЕРЖЕК)
Func WMI_ForceCleanupOnStartup()
    ; Проверяем настройку принудительной очистки
    Local $bForceCleanup = Int(IniRead($sWatchdogIniPath, "WMICleanup", "ForceCleanupOnStartup", "1"))

    If Not $bForceCleanup Then Return

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚡ БЫСТРАЯ очистка WMI при запуске...")

    ; 🔄 Перезапускаем службу WMI только если WMI система будет использоваться
    If $bWMIEnabled Then
        WMI_FastRestartService()
    Else
        ; Если WMI отключен, просто завершаем процессы без перезапуска службы
        WMI_KillAllWMIProcesses()
        WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "ℹ️ WMI отключен, только завершение процессов")
    EndIf

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "✅ Быстрая очистка WMI завершена")
EndFunc

; ⚡ Функция БЫСТРОЙ очистки WMI ресурсов (БЕЗ ЛОГОВ)
Func WMI_CleanupResources()
    ; Отключаем Events если активны
    $bWMIEventsActive = False

    ; Очищаем объекты
    $oWMIEventSink = 0
    $oWMIService = 0

    ; Сбрасываем флаги
    $bWMIInitialized = False
    $bWMIReinitInProgress = False
EndFunc

; Функция поиска и завершения "зомби" WMI процессов
Func WMI_KillZombieProcesses()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "🔍 Поиск зомби WMI процессов...")

    ; Читаем настройки из конфига
    Local $iWarningWMI = Int(IniRead($sWatchdogIniPath, "WMICleanup", "WarningWMIProcesses", "3"))

    ; Ищем процессы связанные с WMI которые могли остаться
    Local $aWMIProcesses = ProcessList("wmiprvse.exe")
    Local $iKilledCount = 0

    If $aWMIProcesses[0][0] > $iWarningWMI Then ; Если больше настроенного лимита - подозрительно
        WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚠️ Найдено подозрительно много WMI процессов: " & $aWMIProcesses[0][0] & " (лимит: " & $iWarningWMI & ")")

        ; Завершаем лишние процессы (оставляем первые 2)
        For $i = 3 To $aWMIProcesses[0][0]
            If ProcessClose($aWMIProcesses[$i][1]) Then
                $iKilledCount += 1
                WriteWatchdogLog("ОТКЛЮЧЕНИЕ", "WMI_CLEANUP", "❌ Завершен WMI процесс PID: " & $aWMIProcesses[$i][1])
                Sleep(100) ; Небольшая пауза между завершениями
            EndIf
        Next
    EndIf

    If $iKilledCount > 0 Then
        WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "🧹 Завершено зомби WMI процессов: " & $iKilledCount)
        Sleep(1000) ; Пауза для стабилизации системы
    Else
        WriteWatchdogLog("КОНСОЛЬ", "WMI_CLEANUP", "✅ Зомби WMI процессы не найдены")
    EndIf
EndFunc

; Функция периодической проверки WMI ресурсов (ОПТИМИЗИРОВАННАЯ)
Func WMI_PeriodicCleanupCheck()
    ; Читаем настройки из конфига
    Local $iCheckInterval = Int(IniRead($sWatchdogIniPath, "WMICleanup", "PeriodicCheckInterval", "600000")) ; Увеличил до 10 минут
    Local $iMaxWMI = Int(IniRead($sWatchdogIniPath, "WMICleanup", "MaxWMIProcesses", "8")) ; Увеличил лимит
    Local $iWarningWMI = Int(IniRead($sWatchdogIniPath, "WMICleanup", "WarningWMIProcesses", "5")) ; Увеличил предупреждение

    ; Проверяем по настраиваемому интервалу (реже для снижения нагрузки)
    If TimerDiff($wmi_cleanup_timer) < $iCheckInterval Then Return

    ; 📊 ЛЕГКОВЕСНАЯ проверка без нагрузки на систему
    Local $iWMICount = WMI_CountProcessesLightweight()

    ; Логируем только при превышении лимитов
    If $iWMICount > $iMaxWMI Then ; Критично
        WriteWatchdogLog("ОШИБКА", "WMI_CLEANUP", "🚨 Критическое количество WMI процессов: " & $iWMICount & " (макс: " & $iMaxWMI & ")")

        ; Полная переинициализация WMI системы
        WMI_ForceReinitialize()
    ElseIf $iWMICount > $iWarningWMI Then ; Предупреждение
        WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚠️ Повышенное количество WMI процессов: " & $iWMICount & " (предупреждение: " & $iWarningWMI & ")")
        WMI_KillZombieProcesses()
    EndIf

    $wmi_cleanup_timer = TimerInit()
EndFunc

; Функция принудительной переинициализации WMI
Func WMI_ForceReinitialize()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "🔄 Принудительная переинициализация WMI системы...")

    ; Полная очистка
    WMI_CleanupResources()

    ; Завершаем зомби процессы
    WMI_KillZombieProcesses()

    ; Пауза для стабилизации
    Sleep(3000)

    ; Переинициализация (только если WMI включен)
    If $bWMIEnabled Then
        InitializeWMISystem()
    EndIf

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "✅ Принудительная переинициализация завершена")
EndFunc

; Функция корректного завершения WMI при выходе
Func WMI_GracefulShutdown()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "🛑 Корректное завершение WMI системы...")

    ; Отключаем все WMI активности
    $bWMIEnabled = False
    $bWMIEventsActive = False
    $bWMIInitialized = False

    ; Очищаем ресурсы
    WMI_CleanupResources()

    ; Дополнительная пауза для завершения
    Sleep(1000)

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "✅ WMI система корректно завершена")
EndFunc

; ⚡ Функция БЫСТРОГО завершения WMI процессов (БЕЗ ЗАДЕРЖЕК)
Func WMI_KillAllWMIProcesses()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚡ БЫСТРОЕ завершение WMI процессов...")

    ; Список всех WMI-связанных процессов для завершения
    Local $aWMIProcessNames = ["wmiprvse.exe", "wmiapsrv.exe", "wmiadap.exe", "scrcons.exe"]

    ; Принудительное завершение через taskkill БЕЗ ОЖИДАНИЯ
    For $sProcessName In $aWMIProcessNames
        Run(@ComSpec & " /c taskkill /f /im " & $sProcessName & " >nul 2>&1", "", @SW_HIDE)
    Next

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚡ Команды завершения WMI процессов отправлены")
EndFunc

; ⚡ Функция БЫСТРОГО перезапуска службы WMI (с настраиваемой задержкой)
Func WMI_FastRestartService()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "⚡ Быстрый перезапуск службы WMI...")

    ; Читаем настраиваемую задержку стабилизации
    Local $iStabilizationDelay = Int(IniRead($sWatchdogIniPath, "WMICleanup", "WMIStabilizationDelay", "1500"))

    ; Останавливаем службу WMI БЕЗ ОЖИДАНИЯ
    Run(@ComSpec & " /c net stop winmgmt /y >nul 2>&1", "", @SW_HIDE)

    ; Минимальная задержка для остановки службы
    Sleep(500)

    ; Запускаем службу WMI БЕЗ ОЖИДАНИЯ
    Run(@ComSpec & " /c net start winmgmt >nul 2>&1", "", @SW_HIDE)

    ; Настраиваемая задержка для стабилизации WMI
    Sleep($iStabilizationDelay)

    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "✅ Служба WMI перезапущена (задержка: " & $iStabilizationDelay & "мс)")
EndFunc

; 🔄 Функция перезапуска службы WMI
Func WMI_RestartWMIService()
    WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "🔄 Перезапуск службы Windows Management Instrumentation...")

    ; Останавливаем службу WMI
    Local $iResult1 = RunWait(@ComSpec & " /c net stop winmgmt /y >nul 2>&1", "", @SW_HIDE)
    Sleep(2000)

    ; Запускаем службу WMI
    Local $iResult2 = RunWait(@ComSpec & " /c net start winmgmt >nul 2>&1", "", @SW_HIDE)
    Sleep(2000)

    If $iResult2 = 0 Then
        WriteWatchdogLog("СИСТЕМА", "WMI_CLEANUP", "✅ Служба WMI успешно перезапущена")
    Else
        WriteWatchdogLog("ОШИБКА", "WMI_CLEANUP", "❌ Ошибка перезапуска службы WMI (код: " & $iResult2 & ")")
    EndIf
EndFunc

; 📊 Оптимизированная функция подсчета WMI процессов (без нагрузки)
Func WMI_CountProcessesLightweight()
    ; Быстрый подсчет только основных WMI процессов
    Local $aWMIProcesses = ProcessList("wmiprvse.exe")
    Return $aWMIProcesses[0][0]
EndFunc

; --- КОНЕЦ ФУНКЦИЙ ОЧИСТКИ WMI ---

; --- ПРОСТЫЕ ФУНКЦИИ ДЛЯ РАБОТЫ СО STRIPPED ФАЙЛОМ ---

; Улучшенная функция извлечения имени процесса и пути из текста ошибки
Func _ExtractProcessName($sErrorText)
    ; Ищем строку вида: (File "C:\path\ProcessManager.exe")
    Local $aMatches = StringRegExp($sErrorText, '\(File\s+"([^"]+)"\)', 3)
    If UBound($aMatches) > 0 Then
        Local $sFullPath = $aMatches[0]
        Local $sFileName = StringRegExpReplace($sFullPath, ".*\\", "") ; Извлекаем только имя файла
        Return $sFileName & "|FULLPATH:" & $sFullPath  ; 🎯 Возвращаем и имя файла и полный путь
    EndIf

    ; По умолчанию возвращаем ProcessManager.exe
    Return "ProcessManager.exe"
EndFunc

; Улучшенная функция получения строки из stripped файла с поиском в двух местах
Func GetSimpleLineFromStripped($sProcessInfo, $iLineNumber)
    ; Защита от пустых параметров
    If $sProcessInfo = "" Or $iLineNumber <= 0 Then Return ""

    ; 🎯 Парсим информацию о процессе (имя файла и полный путь)
    Local $sProcessName = "", $sFullPath = ""
    If StringInStr($sProcessInfo, "|FULLPATH:") > 0 Then
        Local $aParts = StringSplit($sProcessInfo, "|FULLPATH:", 1)
        If IsArray($aParts) And $aParts[0] = 2 Then
            $sProcessName = $aParts[1]
            $sFullPath = $aParts[2]
        Else
            $sProcessName = $sProcessInfo  ; Fallback на старый формат
        EndIf
    Else
        $sProcessName = $sProcessInfo  ; Старый формат без пути
    EndIf

    ; Определяем имя stripped файла
    Local $sStrippedFile = StringReplace($sProcessName, ".exe", "_stripped.au3")

    ; 🔍 СИСТЕМА ДВОЙНОГО ПОИСКА STRIPPED ФАЙЛОВ
    Local $sStrippedPath = ""
    Local $sSearchLocation = ""

    ; 1️⃣ Сначала ищем в папке Watchdog (текущее поведение)
    Local $sWatchdogPath = @ScriptDir & "\" & $sStrippedFile
    If FileExists($sWatchdogPath) Then
        $sStrippedPath = $sWatchdogPath
        $sSearchLocation = "WATCHDOG_DIR"
    ; 2️⃣ Если не найден и есть полный путь к exe - ищем рядом с exe файлом
    ElseIf $sFullPath <> "" Then
        Local $sExeDir = StringRegExpReplace($sFullPath, "\\[^\\]*$", "") ; Получаем папку exe файла
        Local $sExePath = $sExeDir & "\" & $sStrippedFile
        If FileExists($sExePath) Then
            $sStrippedPath = $sExePath
            $sSearchLocation = "EXE_DIR"
        EndIf
    EndIf

    ; Если stripped файл не найден нигде
    If $sStrippedPath = "" Then
        ; 📝 Логируем информацию о поиске для отладки
        If $sFullPath <> "" Then
            WriteWatchdogLog("СИСТЕМА", "STRIPPED", "🔍 Stripped файл не найден: " & $sStrippedFile)
            WriteWatchdogLog("КОНСОЛЬ", "STRIPPED", "📂 Искали в: " & @ScriptDir & " и " & StringRegExpReplace($sFullPath, "\\[^\\]*$", ""))
        Else
            WriteWatchdogLog("СИСТЕМА", "STRIPPED", "🔍 Stripped файл не найден: " & $sStrippedFile & " (только в Watchdog папке)")
        EndIf
        Return ""
    EndIf

    ; 📝 Логируем где нашли файл
    WriteWatchdogLog("КОНСОЛЬ", "STRIPPED", "✅ Найден " & $sStrippedFile & " в " & ($sSearchLocation = "WATCHDOG_DIR" ? "папке Watchdog" : "папке exe файла"))

    ; Читаем весь файл с защитой от ошибок
    Local $aLines = FileReadToArray($sStrippedPath)
    If @error Or Not IsArray($aLines) Or UBound($aLines) = 0 Then
        WriteWatchdogLog("ОШИБКА", "STRIPPED", "❌ Не удалось прочитать " & $sStrippedPath)
        Return ""
    EndIf

    ; Проверяем, что номер строки в пределах файла
    If $iLineNumber <= 0 Or $iLineNumber > UBound($aLines) Then
        WriteWatchdogLog("СИСТЕМА", "STRIPPED", "⚠️ Строка " & $iLineNumber & " вне диапазона файла " & $sStrippedFile & " (макс: " & UBound($aLines) & ")")
        Return ""
    EndIf

    ; Получаем строку с ошибкой (массив начинается с 0, поэтому -1)
    Local $sErrorLine = ""
    If $iLineNumber - 1 >= 0 And $iLineNumber - 1 < UBound($aLines) Then
        $sErrorLine = StringStripWS($aLines[$iLineNumber - 1], 3)
    EndIf

    ; Если строка пустая, возвращаем пустую строку
    If $sErrorLine = "" Then Return ""

    ; Ищем имя функции, идя вверх от строки ошибки (с защитой от ошибок)
    Local $sFunctionName = FindFunctionName($aLines, $iLineNumber - 1)

    ; Возвращаем строку с именем функции (если найдена)
    If $sFunctionName <> "" Then
        Return $sErrorLine & "|FUNC:" & $sFunctionName
    Else
        Return $sErrorLine
    EndIf
EndFunc

; Функция поиска имени функции, идя вверх от указанной строки (с защитой от ошибок)
Func FindFunctionName($aLines, $iStartIndex)
    ; Защита от некорректных параметров
    If Not IsArray($aLines) Or UBound($aLines) = 0 Or $iStartIndex < 0 Then Return ""

    ; Ограничиваем поиск разумными пределами (не более 1000 строк вверх)
    Local $iMaxSearch = ($iStartIndex > 1000) ? ($iStartIndex - 1000) : 0

    ; Идем вверх от строки ошибки
    For $i = $iStartIndex To $iMaxSearch Step -1
        ; Защита от выхода за границы массива
        If $i < 0 Or $i >= UBound($aLines) Then ContinueLoop

        Local $sLine = StringStripWS($aLines[$i], 3)

        ; Пропускаем пустые строки и комментарии
        If $sLine = "" Or StringLeft($sLine, 1) = ";" Then ContinueLoop

        ; Ищем строку, начинающуюся с "Func "
        If StringRegExp($sLine, "^Func\s+(\w+)", 0) Then
            ; Извлекаем имя функции с защитой от ошибок
            Local $aMatches = StringRegExp($sLine, "^Func\s+(\w+)", 3)
            If IsArray($aMatches) And UBound($aMatches) > 0 And $aMatches[0] <> "" Then
                Return $aMatches[0]
            EndIf
        EndIf

        ; Если встретили EndFunc, значит мы вышли за пределы текущей функции
        If StringRegExp($sLine, "^EndFunc", 0) Then ExitLoop
    Next

    ; Если функция не найдена, возвращаем пустую строку
    Return ""
EndFunc

; WMI EVENTS СИСТЕМА МОНИТОРИНГА ProcessManager.exe

; Инициализация WMI системы с Events
Func InitializeWMISystem()
    WriteWatchdogLog("СИСТЕМА", "WMI", "🔄 Инициализация WMI Events для ProcessManager.exe (интервал: 0.1 сек)...")

    ; Попытка подключения к WMI
    $oWMIService = ObjGet("winmgmts:\\.\root\cimv2")

    If IsObj($oWMIService) Then
        WriteWatchdogLog("ВКЛЮЧЕНИЕ", "WMI", "✅ WMI служба успешно подключена")

        ; Делаем первоначальную проверку ProcessManager.exe
        WMI_InitialCheck()

        ; Инициализируем WMI Events
        WMI_InitializeEvents()

        $bWMIInitialized = True
        WriteWatchdogLog("СИСТЕМА", "WMI", "🎯 WMI Events система готова к работе")
    Else
        WriteWatchdogLog("ОШИБКА", "WMI", "❌ Не удалось подключиться к WMI службе")
        $bWMIEnabled = False

        ; Показываем пользователю как отключить WMI для тестирования
 ;       MsgBox(48, "⚠️ WMI Недоступен", _
 ;           "WMI служба недоступна!" & @CRLF & @CRLF & _
 ;           "🔧 Для тестирования отказа WMI:" & @CRLF & _
 ;           "1️⃣ Откройте services.msc" & @CRLF & _
 ;           "2️⃣ Найдите 'Windows Management Instrumentation'" & @CRLF & _
 ;           "3️⃣ Остановите службу" & @CRLF & @CRLF & _
 ;           "🔄 Система продолжит работу через ProcessExists")

    EndIf
EndFunc

; 🔍 Первоначальная проверка ProcessManager.exe через WMI
Func WMI_InitialCheck()
    If Not $bWMIEnabled Or Not IsObj($oWMIService) Then Return

    WriteWatchdogLog("СИСТЕМА", "WMI", "🔍 Проверяем ProcessManager.exe через WMI...")

    Local $colProcesses = $oWMIService.ExecQuery("SELECT Name, ProcessId FROM Win32_Process WHERE Name = '" & $sMainExeName & "'")

    If IsObj($colProcesses) Then
        Local $iProcessCount = 0
        For $oProcess In $colProcesses
            $iProcessCount += 1
        Next

        If $iProcessCount > 0 Then
            WriteWatchdogLog("КОНСОЛЬ", "WMI", "✅ ProcessManager.exe найден (" & $iProcessCount & " экземпляров)")
        Else
            WriteWatchdogLog("КОНСОЛЬ", "WMI", "❌ ProcessManager.exe не найден через WMI")

            ; 🚀 Если процесс не найден при старте - запускаем его
            If CanRestartProcess("WMI_INITIAL") Then
                WriteWatchdogLog("СИСТЕМА", "WMI", "🚀 Запускаем ProcessManager.exe при инициализации")
                RestartProcessManager("WMI_INITIAL")
            EndIf
        EndIf

        WriteWatchdogLog("СИСТЕМА", "WMI", "📊 WMI проверка завершена")
    Else
        WriteWatchdogLog("ОШИБКА", "WMI", "❌ Ошибка выполнения WMI запроса")
        $iWMIErrors += 1
    EndIf
EndFunc

; 📡 Инициализация WMI Events
Func WMI_InitializeEvents()
    If Not $bWMIEnabled Or Not IsObj($oWMIService) Then Return

    WriteWatchdogLog("СИСТЕМА", "WMI", "📡 Инициализация WMI Events...")

    ; Создаем подписку на события завершения процессов (0.1 секунды для мгновенной реакции)
    Local $sQuery = "SELECT * FROM __InstanceDeletionEvent WITHIN 1.0 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = '" & $sMainExeName & "'"

    $oWMIEventSink = $oWMIService.ExecNotificationQuery($sQuery)

    If IsObj($oWMIEventSink) Then
        $bWMIEventsActive = True
        WriteWatchdogLog("ВКЛЮЧЕНИЕ", "WMI", "🎯 WMI Events активированы для ProcessManager.exe")
    Else
        WriteWatchdogLog("ОШИБКА", "WMI", "❌ Не удалось создать WMI Event подписку")
        $iWMIErrors += 1
    EndIf
EndFunc

; 🔄 Переинициализация WMI Events при ошибках (улучшенная)
Func WMI_ReinitializeEvents()
    ; Защита от множественных вызовов
    If $bWMIReinitInProgress Then
        WriteWatchdogLog("КОНСОЛЬ", "WMI", "⚠️ Переинициализация уже выполняется, пропускаем...")
        Return
    EndIf

    $bWMIReinitInProgress = True
    WriteWatchdogLog("СИСТЕМА", "WMI", "🔄 Переинициализация WMI Events...")

    ; Отменяем все предыдущие AdlibRegister
    AdlibUnRegister("WMI_ReinitializeEvents")

    ; Отключаем старые события
    $bWMIEventsActive = False
    $oWMIEventSink = 0

    ; Задержка перед переинициализацией
    Sleep(2000)

    ; Проверяем соединение с WMI
    If Not IsObj($oWMIService) Then
        WriteWatchdogLog("СИСТЕМА", "WMI", "🔄 Переподключение к WMI службе...")
        $oWMIService = ObjGet("winmgmts:\\.\root\cimv2")

        If Not IsObj($oWMIService) Then
            WriteWatchdogLog("ОШИБКА", "WMI", "❌ Не удалось переподключиться к WMI")
            $bWMIEnabled = False
            $bWMIReinitInProgress = False
            Return
        EndIf
    EndIf

    ; Пытаемся заново создать подписку на события
    WMI_InitializeEvents()

    ; Если Events не удалось создать - переключаемся на опрос
    If Not $bWMIEventsActive Then
        WriteWatchdogLog("СИСТЕМА", "WMI", "⚠️ Events не удалось восстановить, переключение на опрос")
        WMI_SwitchToPolling()
    Else
        ; Сбрасываем счетчики ошибок только при успешной инициализации
        $iWMIErrors = 0
        $iWMIEventFailures = 0
        WriteWatchdogLog("СИСТЕМА", "WMI", "✅ Переинициализация WMI Events завершена")
    EndIf

    $bWMIReinitInProgress = False
EndFunc

; ⚡ Проверка WMI Events (ОПТИМИЗИРОВАННАЯ - снижена нагрузка на CPU)
Func WMI_CheckEvents()
    If Not $bWMIEventsActive Or Not IsObj($oWMIEventSink) Then Return

    ; 📊 Читаем настраиваемый таймаут из конфига
    Local $iWMITimeout = Int(IniRead($sWatchdogIniPath, "Optimization", "WMIEventTimeout", "100"))

    ; 🛡️ Пытаемся получить событие с настраиваемым таймаутом для снижения нагрузки
    Local $oEvent = $oWMIEventSink.NextEvent($iWMITimeout)

    ; Если объекта нет, просто выходим (это нормальный таймаут)
    If Not IsObj($oEvent) Then
        Return
    EndIf

    ; Получаем TargetInstance
    Local $oTargetInstance = $oEvent.TargetInstance

    ; Переменные по умолчанию
    Local $sProcessName = ""
    Local $iPID = 0
    Local $iExitCode = -1

    ; 🛡️ Пытаемся безопасно прочитать свойства WMI события
    If IsObj($oTargetInstance) Then
        ; Используем конструкцию, которая не упадет при ошибке COM (благодаря обработчику)
        $sProcessName = $oTargetInstance.Name
        If @error Then
            ; Если не удалось прочитать имя - это подозрительно, но мы знаем что кто-то умер
            WriteWatchdogLog("СИСТЕМА", "WMI_EVENT", "⚠️ Не удалось прочитать имя процесса из WMI события (ошибка: " & @error & ")")
            $sProcessName = "Unknown"
        EndIf

        $iPID = $oTargetInstance.ProcessId
        If @error Then $iPID = 0

        $iExitCode = $oTargetInstance.ExitStatus
        If @error Then $iExitCode = -1
    Else
        WriteWatchdogLog("ОШИБКА", "WMI_EVENT", "💥 Получен невалидный TargetInstance объект")
        $oEvent = 0 ; Очищаем объект
        Return
    EndIf

    ; 🔍 ЛОГИКА "СЛЕПОГО" ПЕРЕЗАПУСКА (Если WMI глючит, но событие пришло)
    If $sProcessName = "Unknown" Or $sProcessName = "" Then
         WriteWatchdogLog("СИСТЕМА", "WMI_EVENT", "💀 Получено событие завершения, но имя процесса не читается")

         ; Если мы получили событие смерти, но не поняли кого - проверим ProcessManager
         If ProcessExists($sMainExeName) = 0 Then
             WriteWatchdogLog("СИСТЕМА", "WMI_EVENT", "💀 ProcessManager.exe тоже мертв -> Слепой перезапуск!")

             ; 🛡️ Проверяем защиту от двойного запуска
             If CanRestartProcess("WMI_EVENT_BLIND") Then
                WriteWatchdogLog("СИСТЕМА", "WMI_EVENT_BLIND", "🚀 Слепой перезапуск ProcessManager.exe через WMI Events")
                RestartProcessManager("WMI_EVENT_BLIND")
             EndIf
         Else
             WriteWatchdogLog("КОНСОЛЬ", "WMI_EVENT", "ℹ️ ProcessManager.exe жив, событие касалось другого процесса")
         EndIf

    ; 🎯 ЛОГИКА НОРМАЛЬНОГО ПЕРЕЗАПУСКА (Если удалось прочитать имя)
    ElseIf StringUpper($sProcessName) = StringUpper($sMainExeName) Then
         WriteWatchdogLog("ИЗМЕНЕНИЕ", "WMI_EVENT", "💥 Обнаружено завершение: " & $sProcessName & " (PID: " & $iPID & ", ExitCode: " & $iExitCode & ")")

         ; 🛡️ Проверяем защиту от двойного запуска
         If CanRestartProcess("WMI_EVENT") Then
            WriteWatchdogLog("СИСТЕМА", "WMI_EVENT", "🚀 Перезапуск ProcessManager.exe через WMI Events")
            RestartProcessManager("WMI_EVENT")
         EndIf
    Else
         WriteWatchdogLog("КОНСОЛЬ", "WMI_EVENT", "ℹ️ Завершился другой процесс: " & $sProcessName & " (PID: " & $iPID & ")")
    EndIf

    ; Сбрасываем счетчики ошибок при успешном получении события
    If $iWMIErrors > 0 Or $iWMIEventFailures > 0 Then
        WriteWatchdogLog("СИСТЕМА", "WMI_EVENT", "✅ WMI Events восстановлены после ошибок")
        $iWMIErrors = 0
        $iWMIEventFailures = 0
    EndIf

    ; ВАЖНО: Очищаем объект события в конце
    $oEvent = 0
EndFunc

; 📊 WMI опрос ProcessManager.exe (fallback режим)
Func WMI_CheckProcessManager()
    If Not $bWMIEnabled Or Not IsObj($oWMIService) Then Return

    ; Быстрый запрос только для ProcessManager.exe
    Local $colProcesses = $oWMIService.ExecQuery("SELECT Name, ProcessId FROM Win32_Process WHERE Name = '" & $sMainExeName & "'")

    If @error Then
        $iWMIErrors += 1
        WriteWatchdogLog("ОШИБКА", "WMI_POLL", "❌ WMI опрос неудачен (ошибка #" & $iWMIErrors & ")")

        ; Если слишком много ошибок опроса - отключаем WMI полностью
        If $iWMIErrors >= 10 Then
            WriteWatchdogLog("ОШИБКА", "WMI_POLL", "🚫 Отключение WMI после " & $iWMIErrors & " ошибок опроса")
            $bWMIEnabled = False
        EndIf
        Return
    EndIf

    If IsObj($colProcesses) Then
        Local $iProcessCount = 0
        For $oProcess In $colProcesses
            $iProcessCount += 1
        Next

        ; Если ProcessManager.exe не найден через WMI опрос
        If $iProcessCount = 0 Then
            WriteWatchdogLog("ИЗМЕНЕНИЕ", "WMI_POLL", "🔄 ProcessManager.exe не обнаружен через WMI опрос")

            ; 🛡️ Проверяем защиту от двойного запуска
            If CanRestartProcess("WMI_POLL") Then
                WriteWatchdogLog("СИСТЕМА", "WMI_POLL", "🚀 Перезапуск ProcessManager.exe через WMI опрос")
                RestartProcessManager("WMI_POLL")
            EndIf
        EndIf

        ; Сбрасываем счетчик ошибок при успешном опросе
        If $iWMIErrors > 0 Then
            WriteWatchdogLog("СИСТЕМА", "WMI_POLL", "✅ WMI опрос восстановлен после " & $iWMIErrors & " ошибок")
            $iWMIErrors = 0
        EndIf

        ; 🔄 ПОПЫТКА ВОССТАНОВЛЕНИЯ EVENTS: Если 10 раз успешно опросили - пробуем восстановить Events
        Static $iSuccessfulPolls = 0
        $iSuccessfulPolls += 1

        If $iSuccessfulPolls >= 10 Then
            WriteWatchdogLog("СИСТЕМА", "WMI_POLL", "🔄 Попытка восстановления WMI Events после 10 успешных опросов...")
            WMI_TryRestoreEvents()
            $iSuccessfulPolls = 0 ; Сбрасываем счетчик
        EndIf
    EndIf
EndFunc

; 🔄 Переключение на режим WMI опроса
Func WMI_SwitchToPolling()
    WriteWatchdogLog("СИСТЕМА", "WMI", "🔄 Переключение с Events на Polling режим")

    ; Отключаем Events
    $bWMIEventsActive = False
    $bWMIEventsMode = False
    $oWMIEventSink = 0

    ; Отменяем все AdlibRegister для переинициализации
    AdlibUnRegister("WMI_ReinitializeEvents")
    $bWMIReinitInProgress = False

    ; Сбрасываем счетчики
    $iWMIErrors = 0
    $iWMIEventFailures = 0

    WriteWatchdogLog("ВКЛЮЧЕНИЕ", "WMI", "📊 WMI переключен на режим опроса (каждые 0.1 секунды)")
EndFunc

; 🔄 Попытка восстановления WMI Events из режима Polling
Func WMI_TryRestoreEvents()
    WriteWatchdogLog("СИСТЕМА", "WMI", "🔄 Попытка восстановления WMI Events...")

    ; Проверяем соединение с WMI
    If Not IsObj($oWMIService) Then
        $oWMIService = ObjGet("winmgmts:\\.\root\cimv2")
        If Not IsObj($oWMIService) Then
            WriteWatchdogLog("ОШИБКА", "WMI", "❌ WMI служба недоступна для восстановления Events")
            Return
        EndIf
    EndIf

    ; Пытаемся создать подписку на события
    WMI_InitializeEvents()

    ; Если удалось - переключаемся обратно на Events режим
    If $bWMIEventsActive Then
        $bWMIEventsMode = True
        $iWMIErrors = 0
        $iWMIEventFailures = 0
        WriteWatchdogLog("ВКЛЮЧЕНИЕ", "WMI", "🎯 WMI Events успешно восстановлены из режима опроса!")
    Else
        WriteWatchdogLog("ОШИБКА", "WMI", "❌ Не удалось восстановить WMI Events, остаемся в режиме опроса")
    EndIf
EndFunc

; 🛡️ Проверка возможности перезапуска (УСИЛЕННАЯ защита от двойного запуска)
Func CanRestartProcess($sSource)
    ; Проверяем, прошло ли достаточно времени с последнего перезапуска (3 секунды)
    If TimerDiff($last_restart_timer) < $iMinRestartInterval Then
        WriteWatchdogLog("КОНСОЛЬ", $sSource, "🛡️ Блокировка перезапуска: последний запуск " & $sLastRestartSource & " менее " & ($iMinRestartInterval/1000) & " сек назад")
        Return False
    EndIf

    Return True
EndFunc

; 🚀 Функция перезапуска ProcessManager.exe
; 🚀 Функция перезапуска ProcessManager.exe (УСИЛЕННАЯ с дополнительными проверками)
Func RestartProcessManager($sSource)
    Local $bDisableAutostart = Int(IniRead($sWatchdogIniPath, "Watchdog", "DisableAutostart", "0"))

    If $bDisableAutostart = 1 Then
        WriteWatchdogLog("КОНСОЛЬ", $sSource, "🚫 Автозапуск отключен в настройках Watchdog")
        Return False
    EndIf

    ; 🛡️ ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: Убеждаемся что процесс действительно не запущен
    If ProcessExists($sMainExeName) > 0 Then
        WriteWatchdogLog("КОНСОЛЬ", $sSource, "🛡️ ProcessManager.exe уже существует, запуск отменен")

        ; Обновляем таймер чтобы избежать повторных попыток
        $last_restart_timer = TimerInit()
        $sLastRestartSource = $sSource & "_CANCELLED"
        Return False
    EndIf

    If FileExists($sMainExePath) Then
        ; Запускаем процесс
        Run($sMainExePath, @ScriptDir)

        ; Обновляем таймер защиты от двойного запуска
        $last_restart_timer = TimerInit()
        $sLastRestartSource = $sSource

        WriteWatchdogLog("ВКЛЮЧЕНИЕ", $sSource, "✅ ProcessManager.exe запущен: " & $sMainExePath)
        Return True
    Else
        WriteWatchdogLog("ОШИБКА", $sSource, "❌ Файл ProcessManager.exe не найден: " & $sMainExePath)
        Return False
    EndIf
EndFunc

; 🛡️ Глобальный обработчик ошибок WMI/COM (ИСПРАВЛЕННЫЙ - без ложных срабатываний)
Func _WMIErrorHandler()
    Local $sErrorNumber = Hex($oMyError.number, 8)
    Local $sErrorDescription = StringStripWS($oMyError.description, 3)
    Local $sErrorSource = $oMyError.source
    Local $sErrorLine = $oMyError.scriptline

    ; 🛡️ ФИЛЬТР ЛОЖНЫХ СРАБАТЫВАНИЙ
    ; Ошибка 80020009 - нормальный таймаут NextEvent(0)
    ; Ошибка 80020006 - Unknown Name при чтении свойств "битого" WMI события
    If ($sErrorNumber = "80020009" And ( _
       StringInStr($sErrorDescription, "time") > 0 Or _
       StringInStr($sErrorDescription, "время") > 0 Or _
       StringInStr($sErrorDescription, "ожидани") > 0 Or _
       StringInStr($sErrorDescription, "Timed out") > 0 Or _
       StringInStr($sErrorDescription, "Прекращено") > 0)) Or _
       ($sErrorNumber = "80020006") Then
        ; Это нестрашная ошибка чтения свойства или таймаут - просто выходим молча
        SetError(0)
        Return
    EndIf

    $iWMIErrors += 1

    ; Подробное логирование РЕАЛЬНЫХ ошибок
    WriteWatchdogLog("ОШИБКА", "WMI_COM", "💥 COM ошибка #" & $iWMIErrors)
    WriteWatchdogLog("ОШИБКА", "WMI_COM", "📍 Номер: " & $sErrorNumber & " | Описание: " & $sErrorDescription)
    WriteWatchdogLog("ОШИБКА", "WMI_COM", "📍 Источник: " & $sErrorSource & " | Строка: " & $sErrorLine)

    ; Анализируем тип ошибки для принятия решения
    Local $bCriticalError = False

    ; Критические ошибки WMI (RPC сервер недоступен = WMI умер или перезагружается)
    If StringInStr($sErrorDescription, "Invalid class") > 0 Or _
       StringInStr($sErrorDescription, "Provider failure") > 0 Or _
       StringInStr($sErrorDescription, "Access denied") > 0 Or _
       StringInStr($sErrorDescription, "RPC server") > 0 Or _
       StringInStr($sErrorDescription, "RPC Server") > 0 Then
        $bCriticalError = True
        WriteWatchdogLog("ОШИБКА", "WMI_COM", "🚨 Критическая ошибка WMI обнаружена!")
    EndIf

    ; Если критическая ошибка или много ошибок подряд
    If $bCriticalError Or $iWMIErrors >= 3 Then
        If $bWMIEventsMode Then
            WriteWatchdogLog("СИСТЕМА", "WMI_COM", "🔄 Переключение на WMI опрос из-за критических ошибок...")
            WMI_SwitchToPolling()
        Else
            WriteWatchdogLog("СИСТЕМА", "WMI_COM", "⚠️ Ошибки в режиме опроса, продолжаем работу...")
        EndIf
    ElseIf $iWMIErrors >= 10 Then
        ; Если совсем много ошибок - отключаем WMI полностью
        WriteWatchdogLog("ОШИБКА", "WMI_COM", "🚫 Критическое количество ошибок, отключение WMI...")
        $bWMIEventsActive = False
        $bWMIEnabled = False
    EndIf

    ; Небольшая пауза при реальных ошибках
    Sleep(100)

    ; Возвращаем управление программе (не завершаем её)
    SetError(0)
    Return
EndFunc

; Инициализация логирования
InitializeWatchdogLogging()

; Синхронизация настроек с ProcessManager (УСЛОВНАЯ для быстрого запуска)
Local $bFastStartup = Int(IniRead($sWatchdogIniPath, "WMICleanup", "FastStartup", "1"))
If Not $bFastStartup Then
    SyncLogsSettingsFromProcessManager()
EndIf

; 🧹 Принудительная очистка WMI ресурсов при запуске
WMI_ForceCleanupOnStartup()

; 🚀 Инициализация WMI системы
InitializeWMISystem()

; 🛑 Регистрация корректного завершения WMI при выходе
OnAutoItExitRegister("WMI_GracefulShutdown")

; 🛡️ Дополнительная защита - обработчик Ctrl+C и других сигналов завершения
Func _OnExit()
    WriteWatchdogLog("СИСТЕМА", "EXIT", "🛑 Получен сигнал завершения, корректно завершаем WMI...")
    WMI_GracefulShutdown()
EndFunc

OnAutoItExitRegister("_OnExit")


Autoit_Error_Close()

Func Autoit_Error_Close()
; 🎯 Переменные для оптимизации нагрузки CPU (читаем из конфига)
Static $wmi_check_timer = TimerInit()
Static $duplicate_check_timer = TimerInit()

; 📊 Загружаем настройки оптимизации из конфига
Local $iMainLoopSleep = Int(IniRead($sWatchdogIniPath, "Optimization", "MainLoopSleep", "100"))
Local $iWMIEventsInterval = Int(IniRead($sWatchdogIniPath, "Optimization", "WMIEventsCheckInterval", "200"))
Local $iWMIPollingInterval = Int(IniRead($sWatchdogIniPath, "Optimization", "WMIPollingInterval", "1000"))
Local $iDuplicateInterval = Int(IniRead($sWatchdogIniPath, "Optimization", "DuplicateCheckInterval", "2000"))

WriteWatchdogLog("СИСТЕМА", "OPTIMIZATION", "📊 Интервалы: MainLoop=" & $iMainLoopSleep & "мс, WMI Events=" & $iWMIEventsInterval & "мс, WMI Poll=" & $iWMIPollingInterval & "мс")

While True
    ; 🛡️ СИСТЕМА УДАЛЕНИЯ ДУБЛИКАТОВ ProcessManager.exe (настраиваемый интервал)
    If TimerDiff($duplicate_check_timer) > $iDuplicateInterval Then
        KillDuplicateProcessManager()
        $duplicate_check_timer = TimerInit()
    EndIf

    ; 🧹 ПЕРИОДИЧЕСКАЯ ПРОВЕРКА WMI РЕСУРСОВ (каждые 5 минут)
    WMI_PeriodicCleanupCheck()

    ; 🔥 WMI СИСТЕМА: Проверка событий или опрос (оптимизированная частота)
    If $bWMIEnabled And $bWMIInitialized Then
        If $bWMIEventsMode And $bWMIEventsActive Then
            ; Режим Events - настраиваемый интервал проверки
            If TimerDiff($wmi_check_timer) > $iWMIEventsInterval Then
                WMI_CheckEvents()  ; Внутри уже есть настраиваемый таймаут
                $wmi_check_timer = TimerInit()
            EndIf
        ElseIf TimerDiff($wmi_timer) > $iWMIPollingInterval Then
            ; Режим Polling - настраиваемый интервал опроса
            WMI_CheckProcessManager()
            $wmi_timer = TimerInit()
        EndIf
    EndIf

    ; --- РЕЗЕРВНАЯ ЛОГИКА: Проверка ProcessManager.exe (5 секунд - дает приоритет WMI) ---
    If (ProcessExists($sMainExeName) = 0) And (TimerDiff($process_timer) > 3000) Then
        ; 🛡️ Проверяем защиту от двойного запуска
        If CanRestartProcess("PROCESSEXISTS") Then
            Local $bDisableAutostart = Int(IniRead($sWatchdogIniPath, "Watchdog", "DisableAutostart", "0"))

            If $bDisableAutostart = 0 Then
                WriteWatchdogLog("СИСТЕМА", "PROCESSEXISTS", "⚠️ РЕЗЕРВНАЯ СИСТЕМА: ProcessManager не найден в последние 3 сек, запускаем: " & $sMainExeName)
                RestartProcessManager("PROCESSEXISTS")
            EndIf
        EndIf

        $process_timer = TimerInit()
    EndIf

    ; --- СТАРАЯ ЛОГИКА: Закрытие окон ошибок AutoIt ---
    $hWnd = WinWait("AutoIt Error", "", 1)
    If $hWnd Then
        Local $sRawText = ControlGetText($hWnd, "", "Static2")
        Local $sAppName = WinGetTitle($hWnd)

        ; --- ПАРСИНГ ОШИБКИ ЧЕРЕЗ REGEXP ---
        ; Ищем номер строки: "Line 1234"
        Local $aLine = StringRegExp($sRawText, "(?i)Line\s+(\d+)", 3)
        Local $sLineNum = (UBound($aLine) > 0) ? $aLine[0] : "Unknown"

        ; Ищем название переменной (обычно начинается с $ и до пробела или скобки)
        Local $aVar = StringRegExp($sRawText, "(\$\w+)", 3)
        Local $sVarName = (UBound($aVar) > 0) ? $aVar[0] : "None"

        ; Ищем описание ошибки (текст после "Error:")
        Local $aDesc = StringRegExp($sRawText, "(?i)Error:\s+(.+)", 3)
        Local $sErrorDesc = (UBound($aDesc) > 0) ? $aDesc[0] : "Unknown Error"

        ; --- ЛОГИРОВАНИЕ В ОТДЕЛЬНЫЙ ФАЙЛ AUTOIT ОШИБОК ---
        Local $sAutoitLogEntry = "--- CRASH REPORT ---" & @CRLF & _
                     "Time: " & @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & @CRLF & _
                     "Process: " & $sAppName & @CRLF & _
                     "Line in EXE: " & $sLineNum & @CRLF & _
                     "Variable: " & $sVarName & @CRLF & _
                     "Description: " & $sErrorDesc & @CRLF & _
                     "Full Raw: " & StringStripWS($sRawText, 3) & @CRLF & _
                     "-----------------------" & @CRLF

        ; Проверяем размер файла AutoIt ошибок
        Local $maxAutoitErrors = Int(IniRead($sWatchdogIniPath, "AutoIt", "MaxErrorEntries", "500"))
        If FileExists($sAutoitErrorPath) And FileGetSize($sAutoitErrorPath) > ($maxAutoitErrors * 200) Then
            FileDelete($sAutoitErrorPath & ".old")
            FileMove($sAutoitErrorPath, $sAutoitErrorPath & ".old")
        EndIf

        FileWrite($sAutoitErrorPath, $sAutoitLogEntry)

        ; --- НОВОЕ УПРОЩЕННОЕ ЛОГИРОВАНИЕ С ЗАЩИТОЙ ОТ ОШИБОК ---
        If IsNumber(Number($sLineNum)) Then
            ; Извлекаем информацию о процессе из текста ошибки с защитой
            Local $sProcessInfo = _ExtractProcessName($sRawText)
            Local $sProcessName = ""

            ; 🎯 Парсим информацию о процессе для логирования
            If StringInStr($sProcessInfo, "|FULLPATH:") > 0 Then
                Local $aParts = StringSplit($sProcessInfo, "|FULLPATH:", 1)
                If IsArray($aParts) And $aParts[0] = 2 Then
                    $sProcessName = $aParts[1]  ; Используем только имя файла для логов
                Else
                    $sProcessName = $sProcessInfo
                EndIf
            Else
                $sProcessName = $sProcessInfo
            EndIf

            If $sProcessName = "" Then $sProcessName = "Unknown.exe"

            ; Получаем строку кода из stripped файла (передаем полную информацию)
            Local $sCodeLine = GetSimpleLineFromStripped($sProcessInfo, Int($sLineNum))
            If $sCodeLine <> "" Then
                ; Проверяем, есть ли информация о функции с дополнительной защитой
                If StringInStr($sCodeLine, "|FUNC:") > 0 Then
                    Local $aParts = StringSplit($sCodeLine, "|FUNC:", 1)
                    If IsArray($aParts) And $aParts[0] = 2 And $aParts[1] <> "" And $aParts[2] <> "" Then
                        Local $sCode = StringStripWS($aParts[1], 3)
                        Local $sFuncName = StringStripWS($aParts[2], 3)
                        WriteWatchdogLog("ОШИБКА", "AUTOIT", $sProcessName & " >> Строка " & $sLineNum & " >> Func " & $sFuncName & " >> " & $sCode & " >> " & $sErrorDesc)
                    Else
                        ; Если разбор не удался, используем исходную строку
                        Local $sCleanCode = StringReplace($sCodeLine, "|FUNC:", " ")
                        WriteWatchdogLog("ОШИБКА", "AUTOIT", $sProcessName & " >> Строка " & $sLineNum & " >> " & $sCleanCode & " >> " & $sErrorDesc)
                    EndIf
                Else
                    WriteWatchdogLog("ОШИБКА", "AUTOIT", $sProcessName & " >> Строка " & $sLineNum & " >> " & $sCodeLine & " >> " & $sErrorDesc)
                EndIf
            Else
                WriteWatchdogLog("ОШИБКА", "AUTOIT", $sProcessName & " >> Строка " & $sLineNum & " >> " & $sErrorDesc & " (stripped файл не найден)")
            EndIf
        Else
            ; Если номер строки не определен, все равно показываем процесс
            Local $sProcessInfo = _ExtractProcessName($sRawText)
            Local $sProcessName = ""

            ; Парсим для получения имени файла
            If StringInStr($sProcessInfo, "|FULLPATH:") > 0 Then
                Local $aParts = StringSplit($sProcessInfo, "|FULLPATH:", 1)
                If IsArray($aParts) And $aParts[0] = 2 Then
                    $sProcessName = $aParts[1]
                Else
                    $sProcessName = $sProcessInfo
                EndIf
            Else
                $sProcessName = $sProcessInfo
            EndIf

            If $sProcessName = "" Then $sProcessName = "Unknown.exe"
            WriteWatchdogLog("ОШИБКА", "AUTOIT", $sProcessName & " >> Строка: " & $sLineNum & " >> " & $sErrorDesc)
        EndIf

        WinClose($hWnd)
    EndIf

    ; 🎯 НАСТРАИВАЕМАЯ ПАУЗА: Читается из конфига для тонкой настройки
    Sleep($iMainLoopSleep)

WEnd
EndFunc; 🛡️ Система удаления дубликатов ProcessManager.exe
; 🛡️ Система удаления дубликатов ProcessManager.exe (НОВЫЙ остается, СТАРЫЕ закрываются)
Func KillDuplicateProcessManager()
    Local $PIDs = ProcessList($sMainExeName)

    ; Если найдено больше одного экземпляра
    If $PIDs[0][0] > 1 Then
        WriteWatchdogLog("СИСТЕМА", "DUPLICATES", "🔍 Найдено дубликатов ProcessManager.exe: " & $PIDs[0][0])

        ; 🎯 УЛУЧШЕННАЯ ЛОГИКА: Находим процесс с максимальным PID (обычно самый новый)
        Local $iNewestPID = 0
        Local $iMaxPID = 0
        
        ; Ищем процесс с максимальным PID
        For $i = 1 To $PIDs[0][0]
            If $PIDs[$i][1] > $iMaxPID Then
                $iMaxPID = $PIDs[$i][1]
                $iNewestPID = $PIDs[$i][1]
            EndIf
        Next
        
        WriteWatchdogLog("КОНСОЛЬ", "DUPLICATES", "🎯 Определен самый новый процесс PID: " & $iNewestPID)
        
        ; Закрываем все процессы кроме самого нового
        Local $iClosedCount = 0
        For $i = 1 To $PIDs[0][0]
            If $PIDs[$i][1] = $iNewestPID Then
                ; Оставляем самый новый процесс
                WriteWatchdogLog("КОНСОЛЬ", "DUPLICATES", "✅ Оставляем НОВЫЙ ProcessManager.exe PID: " & $PIDs[$i][1])
            Else
                ; Закрываем старые процессы
                If ProcessClose($PIDs[$i][1]) Then
                    $iClosedCount += 1
                    WriteWatchdogLog("ОТКЛЮЧЕНИЕ", "DUPLICATES", "❌ Закрыт СТАРЫЙ ProcessManager.exe PID: " & $PIDs[$i][1])
                EndIf
            EndIf
        Next

        WriteWatchdogLog("СИСТЕМА", "DUPLICATES", "🧹 Закрыто старых процессов: " & $iClosedCount & ", оставлен новый: " & $iNewestPID)
    EndIf
EndFunc