; ===============================================
; ProcessManager_Core.au3
; Основная логика и мониторинг процессов
; ===============================================

; Функция инициализации реальных статусов при запуске менеджера
Func InitializeProcessStatuses()
    If $aProcesses[0][0] = 0 Then Return
    
    For $i = 1 To $aProcesses[0][0]
        Local $exeName = StringRegExpReplace($aProcesses[$i][1], ".*\\", "")
        ; Определяем реальный статус без логирования
        $aProcesses[$i][5] = ProcessExists($exeName) ? "Runned" : "Stopped"
        ; Обновляем GUI без логирования
        If IsArray($aProcessRows) And UBound($aProcessRows, 1) > $i And $aProcessRows[$i][7] <> 0 Then
            GUICtrlSetData($aProcessRows[$i][7], $aProcesses[$i][5])
            GUICtrlSetColor($aProcessRows[$i][7], ($aProcesses[$i][5] = "Runned") ? $color_run : $color_stop)
        EndIf
    Next
EndFunc

; Функция для проверки таймаутов первого запуска
Func RunStartupProcessesOnce()
    If $aProcesses[0][0] = 0 Then Return

    For $i = 1 To $aProcesses[0][0]
        ; Условие: Чекбокс включен И флаг "первого запуска" (on_start) равен 1
        If $aProcesses[$i][2] = 1 And $aProcesses[$i][12] = 1 Then
            Local $exeName = StringRegExpReplace($aProcesses[$i][1], ".*\\", "")

            ; Если процесс уже кем-то запущен, просто гасим флаг, чтобы не трогать его
            If ProcessExists($exeName) Then
                $aProcesses[$i][12] = 0
                ContinueLoop
            EndIf

            ; Задержка первого запуска (Таймер 2)
            Local $firstLaunchDelay = TimeStringToSec($aProcesses[$i][8]) * 1000

            ; Если время вышло - ЗАПУСКАЕМ ОДИН РАЗ
            If TimerDiff($aProcesses[$i][11]) > $firstLaunchDelay Then
                RunProcessLogic($i)
                $aProcesses[$i][12] = 0 ; КЛЮЧЕВОЙ МОМЕНТ: сбрасываем флаг, больше сюда не зайдем

                ; Обновляем GUI счетчик
                If IsArray($aProcessRows) And UBound($aProcessRows, 1) > $i Then
                    GUICtrlSetData($aProcessRows[$i][6], $aProcesses[$i][4])
                EndIf
            EndIf
        EndIf
    Next
EndFunc

Func UpdateWorkTime(ByRef $allProcs)
    If $aProcesses[0][0] = 0 Then Return

    For $i = 1 To $aProcesses[0][0]
        ; Безопасная проверка существования GUI элементов
        If IsArray($aProcessRows) And UBound($aProcessRows, 1) > $i And $aProcessRows[$i][9] <> 0 Then

            Local $path = $aProcesses[$i][1]
            If $path = "" Then ContinueLoop

            Local $exeName = StringRegExpReplace($path, ".*\\", "")

            ; ШАГ 1: Используем тот же кэш, что и MonitorProcesses
            Local $exists = (_CheckProcessInList($allProcs, $exeName) > 0) ? 1 : 0

            ; ШАГ 2: ЛОГИКА ОПРЕДЕЛЕНИЯ ВРЕМЕНИ
            If $exists Then
                ; Процесс работает: считаем время от Даты Старта до "Сейчас"
                Local $workTimeStr = CalculateWorkTime($aProcesses[$i][10])
                GUICtrlSetData($aProcessRows[$i][9], $workTimeStr)
            Else
                ; Процесс НЕ работает: показываем нули
                GUICtrlSetData($aProcessRows[$i][9], "00:00:00")
            EndIf
        EndIf
    Next
EndFunc

Func AutoKill()
    $PIDs = ProcessList('00_AutoitError.exe')
    For $i = 1 To $PIDs[0][0]
        If ProcessExists($PIDs[$i][1]) Then ProcessClose($PIDs[$i][1])
    Next
EndFunc

Func MonitorProcesses(ByRef $allProcs)
    If $aProcesses[0][0] = 0 Then Return

    For $i = 1 To $aProcesses[0][0]
        ; Безопасная проверка существования GUI элементов
        If IsArray($aProcessRows) And UBound($aProcessRows, 1) > $i And $aProcessRows[$i][7] <> 0 Then

            Local $path = $aProcesses[$i][1]
            If $path = "" Then ContinueLoop

            Local $exeName = StringRegExpReplace($path, ".*\\", "")

            ; ШАГ 1: Используем кэш ProcessList для проверки существования
            Local $exists = (_CheckProcessInList($allProcs, $exeName) > 0) ? 1 : 0

            ; ШАГ 2: ЛОГИКА АВТОЗАПУСКА (только если включен Auto)
            If $aProcesses[$i][3] = 1 Then ; Если кнопка Auto включена
                If $exists = 0 Then
                    ; Определение задержки (Старт или Рестарт)
                    Local $currentDelay = 0
                    If $aProcesses[$i][12] = 1 Then
                        $currentDelay = TimeStringToSec($aProcesses[$i][8]) * 1000 ; Таймер старта (первый запуск)
                    Else
                        $currentDelay = TimeStringToSec($aProcesses[$i][9]) * 1000 ; Таймер рестарта
                    EndIf

                    ; Инициализация таймера, если он пустой
                    If $aProcesses[$i][11] = "" Or $aProcesses[$i][11] = 0 Then $aProcesses[$i][11] = TimerInit()

                    ; ПРОВЕРКА ТАЙМЕРА
                    If TimerDiff($aProcesses[$i][11]) > $currentDelay Then
                        ; ЗАПУСК
                        RunProcessLogic($i)

                        ; Логика после запуска
                        If $aProcesses[$i][12] = 1 Then
                            $aProcesses[$i][12] = 0 ; Сбрасываем флаг "первого запуска"
                        Else
                            $aProcesses[$i][4] += 1 ; Инкремент счетчика рестартов
                            IniWrite($sIniPath, "Process_" & $i, "RestartCount", $aProcesses[$i][4])
                        EndIf

                        ; Обновляем счетчик в GUI
                        If IsArray($aProcessRows) And UBound($aProcessRows) > $i Then
                            GUICtrlSetData($aProcessRows[$i][6], $aProcesses[$i][4])
                        EndIf

                        $aProcesses[$i][11] = TimerInit() ; Сброс таймера ожидания
                    EndIf
                Else
                    ; Если процесс работает, держим таймер сброшенным
                    $aProcesses[$i][11] = TimerInit()
                    ; Если запустили руками - сбрасываем триггер первого запуска
                    If $aProcesses[$i][12] = 1 Then $aProcesses[$i][12] = 0
                EndIf
            EndIf

            ; ШАГ 3: ОБНОВЛЕНИЕ СТАТУСА В GUI
            Local $currentStatus = $aProcesses[$i][5]
            Local $newStatus = $exists ? "Runned" : "Stopped"

            If $currentStatus <> $newStatus Then
                ; Если упал - фиксируем время остановки
                If $aProcesses[$i][5] = "Runned" And $newStatus = "Stopped" Then
                    $aProcesses[$i][13] = _NowCalc()
                EndIf

                $aProcesses[$i][5] = $newStatus

                ; Логируем изменение статуса
                Local $processName = $aProcesses[$i][0]
                WriteLog("ИЗМЕНЕНИЕ", $processName, "Статус изменен: " & $currentStatus & " → " & $newStatus & " (" & ($exists ? "процесс запущен" : "процесс остановлен") & ")")

                ; Обновляем GUI
                UpdateProcessStatusGUI($i)
            EndIf

            ; ШАГ 4: ЛОГИКА УДАЛЕНИЯ ДУБЛИКАТОВ (НОВЫЙ остается, СТАРЫЕ закрываются)
            Local $existsCount = _CheckProcessInList($allProcs, $exeName)
            If $aProcesses[$i][6] = 1 And $existsCount > 1 Then
                ; 🎯 НОВАЯ ЛОГИКА: Находим процесс с максимальным PID (самый новый)
                Local $iNewestPID = 0
                Local $iMaxPID = 0
                
                ; Ищем максимальный PID среди процессов с данным именем
                For $p = 1 To $allProcs[0][0]
                    If StringUpper($allProcs[$p][0]) = StringUpper($exeName) Then
                        If $allProcs[$p][1] > $iMaxPID Then
                            $iMaxPID = $allProcs[$p][1]
                            $iNewestPID = $allProcs[$p][1]
                        EndIf
                    EndIf
                Next
                
                ; Закрываем все процессы кроме самого нового
                Local $iClosedCount = 0
                For $p = 1 To $allProcs[0][0]
                    If StringUpper($allProcs[$p][0]) = StringUpper($exeName) Then
                        If $allProcs[$p][1] <> $iNewestPID Then
                            ; Закрываем старые процессы
                            If ProcessClose($allProcs[$p][1]) Then
                                $iClosedCount += 1
                                WriteLog("ОТКЛЮЧЕНИЕ", $aProcesses[$i][0], "❌ Закрыт СТАРЫЙ дубликат PID: " & $allProcs[$p][1])
                            EndIf
                        Else
                            ; Логируем что оставили новый процесс
                            WriteLog("КОНСОЛЬ", $aProcesses[$i][0], "✅ Оставлен НОВЫЙ процесс PID: " & $allProcs[$p][1])
                        EndIf
                    EndIf
                Next
                
                If $iClosedCount > 0 Then
                    WriteLog("СИСТЕМА", $aProcesses[$i][0], "🧹 Закрыто дубликатов: " & $iClosedCount & ", оставлен новый: " & $iNewestPID)
                EndIf
            EndIf
        EndIf
    Next
EndFunc

; Вспомогательная функция (Должна быть в коде!)
Func _CheckProcessInList(ByRef $list, $name)
    Local $count = 0
    For $j = 1 To $list[0][0]
        If $list[$j][0] = $name Then $count += 1
    Next
    Return $count
EndFunc

; Вспомогательная: "00:00:10" -> 10 сек
Func TimeStringToSec($sTime)
    Local $aSplit = StringSplit($sTime, ":")
    If $aSplit[0] < 3 Then Return 5 ; Дефолт
    Return $aSplit[1] * 3600 + $aSplit[2] * 60 + $aSplit[3]
EndFunc