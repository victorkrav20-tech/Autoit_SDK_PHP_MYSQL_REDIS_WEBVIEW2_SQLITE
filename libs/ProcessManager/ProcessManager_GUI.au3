; ===============================================
; ProcessManager_GUI.au3
; Создание и управление графическим интерфейсом
; ===============================================

Func CreateMainGUI()
	$hGUI = GUICreate($nameprog, $iClientHeight, $iClientWeight, -1, -1, BitAND($GUI_SS_DEFAULT_GUI,$WS_CAPTION,$WS_MAXIMIZEBOX,$WS_SYSMENU,$WS_EX_TOPMOST,BitNOT($WS_CAPTION)))
	_WinAPI_SetClassLongEx($hGui, -26, BitAND(_WinAPI_GetClassLongEx($hGui, -26), BitNOT(1), BitNOT(2)))
	$fon = GUICtrlCreatePic('Includes\2.jpg', 0, 0, $iClientHeight, $iClientWeight, $WS_CLIPSIBLINGS)
	GUICtrlSetState($fon, $GUI_DISABLE)
    
    ; Заголовок
    Local $lblTitle = GUICtrlCreateLabel("Process Manager v1.0", 20, 15, 350, 30, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont($lblTitle, 18, 900, 0, $Font_all)
    GUICtrlSetColor($lblTitle, 0x000080)

    ; 🚪 Кнопка выхода
    Local $btnExit = GUICtrlCreateButton("✖ Выход", 380, 10, 100, 35)
    GUICtrlSetFont($btnExit, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnExit, 0xE74C3C)  ; Красный фон
    GUICtrlSetColor($btnExit, 0xFFFFFF)    ; Белый текст
    GUICtrlSetOnEvent($btnExit, "TrayExitWithConfirmation")
    GUICtrlSetTip($btnExit, "Закрыть Process Manager" & @CRLF & "Все процессы продолжат работать в фоне")

    $btnLogs = GUICtrlCreateButton(" Логи", $iClientHeight - 310, 10, 120, 35)  ; 🎨 Увеличил на 20px и сдвинул левее на 50px
    GUICtrlSetFont($btnLogs, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnLogs, $color_button_bg)      ; 🎨 Синий фон кнопки
    GUICtrlSetColor($btnLogs, $color_button_text)      ; 🎨 Белый текст
    GUICtrlSetOnEvent($btnLogs, "ShowLogsNew")
    ; 💬 TOOLTIP: Подсказка для кнопки Логи
    GUICtrlSetTip($btnLogs, "Открыть окно просмотра логов" & @CRLF & "Показывает все события ProcessManager и Watchdog" & @CRLF & "Доступна фильтрация по типу и процессу")

    $btnResetCounters = GUICtrlCreateButton("Обнулить счётчики", $iClientHeight - 180, 10, 160, 35)  ; 🎨 Увеличил на 30px и сдвинул левее на 30px
    GUICtrlSetFont($btnResetCounters, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnResetCounters, $color_button_bg)  ; 🎨 Синий фон кнопки
    GUICtrlSetColor($btnResetCounters, $color_button_text)  ; 🎨 Белый текст
    GUICtrlSetOnEvent($btnResetCounters, "ResetCounters")
    ; 💬 TOOLTIP: Подсказка для кнопки Обнулить счётчики
    GUICtrlSetTip($btnResetCounters, "Сбросить счётчики перезапусков всех процессов" & @CRLF & "Устанавливает все счётчики в 0" & @CRLF & "Полезно для отслеживания стабильности")

    ; --- Расчет координат столбцов ---
    Local $yPos = 50, $xStart = 10, $headerHeight = 30
    Local $totalGaps = $ColumnGap * 11
    Local $availableWidth = $iClientHeight - $xStart * 2 - $totalGaps

    Local $col_name_w = Int($availableWidth * $col_name_percent / 100)
    Local $col_loop_w = Int($availableWidth * $col_loop_percent / 100)
    Local $col_autorun_w = Int($availableWidth * $col_autorun_percent / 100)
    Local $col_stop_w = Int($availableWidth * $col_stop_percent / 100)
    Local $col_play_w = Int($availableWidth * $col_play_percent / 100)
    Local $col_pause_w = Int($availableWidth * $col_pause_percent / 100)
    Local $col_counter_w = Int($availableWidth * $col_counter_percent / 100)
    Local $col_status_w = Int($availableWidth * $col_status_percent / 100)
    Local $col_duplicates_w = Int($availableWidth * $col_duplicates_percent / 100)
    Local $col_worktime_w = Int($availableWidth * $col_worktime_percent / 100)
    Local $col_timer1_w = Int($availableWidth * $col_timer1_percent / 100)
    Local $col_timer2_w = Int($availableWidth * $col_timer2_percent / 100)

    Local $col_name_x = $xStart
    Local $col_loop_x = $col_name_x + $col_name_w + $ColumnGap
    Local $col_autorun_x = $col_loop_x + $col_loop_w + $ColumnGap
    Local $col_stop_x = $col_autorun_x + $col_autorun_w + $ColumnGap
    Local $col_play_x = $col_stop_x + $col_stop_w + $ColumnGap
    Local $col_pause_x = $col_play_x + $col_play_w + $ColumnGap
    Local $col_counter_x = $col_pause_x + $col_pause_w + $ColumnGap
    Local $col_status_x = $col_counter_x + $col_counter_w + $ColumnGap
    Local $col_duplicates_x = $col_status_x + $col_status_w + $ColumnGap
    Local $col_worktime_x = $col_duplicates_x + $col_duplicates_w + $ColumnGap
    Local $col_timer1_x = $col_worktime_x + $col_worktime_w + $ColumnGap
    Local $col_timer2_x = $col_timer1_x + $col_timer1_w + $ColumnGap

    ; --- Заголовки ---
    CreateHeaderLabel("Имя процесса", $col_name_x, $yPos, $col_name_w, $headerHeight)
    CreateHeaderLabel("При запуске", $col_loop_x, $yPos, $col_loop_w, $headerHeight)
    CreateHeaderLabel("Auto", $col_autorun_x, $yPos, $col_autorun_w, $headerHeight)
    CreateHeaderLabel("Стоп", $col_stop_x, $yPos, $col_stop_w, $headerHeight)
    CreateHeaderLabel("Run", $col_play_x, $yPos, $col_play_w, $headerHeight)
    CreateHeaderLabel("Exit", $col_pause_x, $yPos, $col_pause_w, $headerHeight)
    CreateHeaderLabel("Счетчик", $col_counter_x, $yPos, $col_counter_w, $headerHeight)
    CreateHeaderLabel("Статус", $col_status_x, $yPos, $col_status_w, $headerHeight)
    CreateHeaderLabel("Дубли", $col_duplicates_x, $yPos, $col_duplicates_w, $headerHeight)
    CreateHeaderLabel("Время", $col_worktime_x, $yPos, $col_worktime_w, $headerHeight)
    CreateHeaderLabel("При запуске", $col_timer1_x, $yPos, $col_timer1_w, $headerHeight)
    CreateHeaderLabel("Перезапуск", $col_timer2_x, $yPos, $col_timer2_w, $headerHeight)

    GUICtrlCreateLabel("", $xStart, 85, $iClientHeight - 20, 2)
    GUICtrlSetBkColor(-1, $color_separator)

    ; --- Строки процессов ---
    CreateProcessRows()

    ; --- Нижняя панель (поднята на 40px) ---
    Local $yBottom = $iClientWeight - 120  ; 🎨 Поднял на 40px выше

    $btnAddProcess = GUICtrlCreateButton(" Добавить процесс", 20, $yBottom, 180, 40)
    GUICtrlSetFont($btnAddProcess, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnAddProcess, $color_button_bg)    ; 🎨 Синий фон
    GUICtrlSetColor($btnAddProcess, $color_button_text)    ; 🎨 Белый текст
    GUICtrlSetOnEvent($btnAddProcess, "AddProcess")
    ; 💬 TOOLTIP: Подсказка для кнопки Добавить процесс
    GUICtrlSetTip($btnAddProcess, "Добавить новый процесс в список управления" & @CRLF & "Откроется диалог выбора EXE файла" & @CRLF & "Максимум 15 процессов")

    $btnDeleteProcess = GUICtrlCreateButton(" Удалить выбранные", 210, $yBottom, 180, 40)
    GUICtrlSetFont($btnDeleteProcess, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnDeleteProcess, $color_button_bg) ; 🎨 Синий фон
    GUICtrlSetColor($btnDeleteProcess, $color_button_text) ; 🎨 Белый текст
    GUICtrlSetOnEvent($btnDeleteProcess, "DeleteProcess")
    ; 💬 TOOLTIP: Подсказка для кнопки Удалить выбранные
    GUICtrlSetTip($btnDeleteProcess, "Удалить выбранные процессы из списка" & @CRLF & "Отметьте чекбоксы процессов для удаления" & @CRLF & "Требуется подтверждение")

    ; 🚫 Убрал чекбокс "Запускать с системой"

    $btnSaveSettings = GUICtrlCreateButton(" Сохранить настройки", 400, $yBottom, 200, 40)  ; 🎨 Сдвинул левее
    GUICtrlSetFont($btnSaveSettings, 10, 700, 0, $Font_all)
    GUICtrlSetBkColor($btnSaveSettings, $color_button_bg)  ; 🎨 Синий фон
    GUICtrlSetColor($btnSaveSettings, $color_button_text)  ; 🎨 Белый текст
    GUICtrlSetOnEvent($btnSaveSettings, "SaveSettings")
    ; 💬 TOOLTIP: Подсказка для кнопки Сохранить настройки
    GUICtrlSetTip($btnSaveSettings, "Сохранить все настройки в INI файл" & @CRLF & "Сохраняются: процессы, таймеры, счётчики" & @CRLF & "Настройки загружаются при следующем запуске")

    ; 🎨 Новая информативная строка состояния
    Local $statusY = $yBottom + 50  ; Под кнопками
    $lblStatus = GUICtrlCreateLabel("", 10, $statusY, $iClientHeight - 20, 25, BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont($lblStatus, 11, 700, 0, $Font_all)
    GUICtrlSetBkColor($lblStatus, $color_status_bar_bg)    ; 🎨 Темно-синий фон
    GUICtrlSetColor($lblStatus, $color_status_bar_text)    ; 🎨 Белый текст
    
    ; Обновляем информацию в строке состояния
    UpdateStatusBar()

    GUISetOnEvent($GUI_EVENT_CLOSE, "_hide")  ; 🎯 При закрытии окна - переключаем видимость
    GUISetState(@SW_SHOW, $hGUI)
EndFunc

; Вспомогательная функция для заголовков
Func CreateHeaderLabel($text, $x, $y, $w, $h)
    Local $lbl = GUICtrlCreateLabel($text, $x, $y, $w, $h, BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont($lbl, 11, 800, 0, $Font_all)
    GUICtrlSetColor($lbl, $color_header_text)
    GUICtrlSetBkColor($lbl, $color_header_bg)
    Return $lbl
EndFunc; --- ФУНКЦИЯ СОЗДАНИЯ СТРОК (ИСПРАВЛЕННАЯ) ---

Func CreateProcessRows()
    ; Удаляем старые элементы
    DeleteProcessRows()

    If $aProcesses[0][0] = 0 Then Return

    ; Расчет координат (копируем логику для синхронизации с заголовками)
    Local $yStart = 95, $xStart = 10, $rowHeight = $ProcessRowHeight
    Local $totalGaps = $ColumnGap * 11
    Local $availableWidth = $iClientHeight - $xStart * 2 - $totalGaps

    Local $col_name_w = Int($availableWidth * $col_name_percent / 100)
    Local $col_loop_w = Int($availableWidth * $col_loop_percent / 100)
    Local $col_autorun_w = Int($availableWidth * $col_autorun_percent / 100)
    Local $col_stop_w = Int($availableWidth * $col_stop_percent / 100)
    Local $col_play_w = Int($availableWidth * $col_play_percent / 100)
    Local $col_pause_w = Int($availableWidth * $col_pause_percent / 100)
    Local $col_counter_w = Int($availableWidth * $col_counter_percent / 100)
    Local $col_status_w = Int($availableWidth * $col_status_percent / 100)
    Local $col_duplicates_w = Int($availableWidth * $col_duplicates_percent / 100)
    Local $col_worktime_w = Int($availableWidth * $col_worktime_percent / 100)
    Local $col_timer1_w = Int($availableWidth * $col_timer1_percent / 100)
    Local $col_timer2_w = Int($availableWidth * $col_timer2_percent / 100)

    Local $col_name_x = $xStart
    Local $col_loop_x = $col_name_x + $col_name_w + $ColumnGap
    Local $col_autorun_x = $col_loop_x + $col_loop_w + $ColumnGap
    Local $col_stop_x = $col_autorun_x + $col_autorun_w + $ColumnGap
    Local $col_play_x = $col_stop_x + $col_stop_w + $ColumnGap
    Local $col_pause_x = $col_play_x + $col_play_w + $ColumnGap
    Local $col_counter_x = $col_pause_x + $col_pause_w + $ColumnGap
    Local $col_status_x = $col_counter_x + $col_counter_w + $ColumnGap
    Local $col_duplicates_x = $col_status_x + $col_status_w + $ColumnGap
    Local $col_worktime_x = $col_duplicates_x + $col_duplicates_w + $ColumnGap
    Local $col_timer1_x = $col_worktime_x + $col_worktime_w + $ColumnGap
    Local $col_timer2_x = $col_timer1_x + $col_timer1_w + $ColumnGap

    ; Инициализация массивов
    Local $additionalElements = 12 ; Дополнительные элементы (горизонтальная линия + 11 вертикальных линий)
    Local $totalElements = $aProcesses[0][0] * ($ElementsPerRow + $additionalElements)
    ReDim $aProcessElements[$totalElements + 1]
    $aProcessElements[0] = $totalElements
    ReDim $aProcessRows[$aProcesses[0][0] + 1][14]

    For $i = 1 To $aProcesses[0][0]
        Local $yPos = $yStart + ($i - 1) * ($rowHeight + 2)
        Local $elementIndex = ($i - 1) * ($ElementsPerRow + $additionalElements) + 1

        Local $rowBgColor = (Mod($i, 2) = 0) ? $color_row_even : $color_row_odd

        ; Создаем массив координат столбцов
        Local $col_coords[11] = [$col_loop_x, $col_autorun_x, $col_stop_x, $col_play_x, $col_pause_x, $col_counter_x, $col_status_x, $col_duplicates_x, $col_worktime_x, $col_timer1_x, $col_timer2_x]

        CreateProcessRowElements($i, $yPos, $rowBgColor, $elementIndex, _
            $col_name_x, $col_name_w, $col_loop_x, $col_loop_w, $col_autorun_x, $col_autorun_w, _
            $col_stop_x, $col_stop_w, $col_play_x, $col_play_w, $col_pause_x, $col_pause_w, _
            $col_counter_x, $col_counter_w, $col_status_x, $col_status_w, $col_duplicates_x, $col_duplicates_w, _
            $col_worktime_x, $col_worktime_w, $col_timer1_x, $col_timer1_w, $col_timer2_x, $col_timer2_w, _
            $rowHeight, $xStart, $col_coords)
	Next
	_WinAPI_RedrawWindow($hGUI, 0, 0, BitOR($RDW_INVALIDATE, $RDW_UPDATENOW, $RDW_ALLCHILDREN))
	
	; Обновляем состояние всех кнопок Auto/Stop после создания
	For $i = 1 To $aProcesses[0][0]
		UpdateAutoStopButtons($i)
	Next
EndFunc

Func DeleteProcessRows()
    If UBound($aProcessElements) > 1 Then
        For $i = 1 To $aProcessElements[0]
            If $aProcessElements[$i] <> 0 Then
                GUICtrlDelete($aProcessElements[$i])
                $aProcessElements[$i] = 0
            EndIf
        Next
    EndIf
    
    ; Сбрасываем массивы
    ReDim $aProcessElements[1]
    $aProcessElements[0] = 0
    ReDim $aProcessRows[1][14]
EndFunc

Func DeleteLastProcessRow()
    ; Удаление через перерисовку проще и надежнее
    CreateProcessRows()
EndFunc

Func CreateProcessRowElements($pIdx, $y, $bg, $eIdx, $x1, $w1, $x2, $w2, $x3, $w3, $x4, $w4, $x5, $w5, $x6, $w6, $x7, $w7, $x8, $w8, $x9, $w9, $x10, $w10, $x11, $w11, $x12, $w12, $rH, $xS, $col_coords_array)
    ; Распаковываем координаты из массива
    Local $col_loop_x = $col_coords_array[0]
    Local $col_autorun_x = $col_coords_array[1]
    Local $col_stop_x = $col_coords_array[2]
    Local $col_play_x = $col_coords_array[3]
    Local $col_pause_x = $col_coords_array[4]
    Local $col_counter_x = $col_coords_array[5]
    Local $col_status_x = $col_coords_array[6]
    Local $col_duplicates_x = $col_coords_array[7]
    Local $col_worktime_x = $col_coords_array[8]
    Local $col_timer1_x = $col_coords_array[9]
    Local $col_timer2_x = $col_coords_array[10]

    ; 1. Имя
    Local $label_width = Int($w1 * 0.95)
    Local $label_height = Int($rH * 0.95)
    Local $label_x = $x1 + Int(($w1 - $label_width) / 2)
    Local $label_y = $y + Int(($rH - $label_height) / 2)
    $aProcessRows[$pIdx][0] = GUICtrlCreateLabel($aProcesses[$pIdx][0], $label_x, $label_y, $label_width, $label_height,BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont(-1, 12, 2000, 0, "@Arial Unicode MS")
    GUICtrlSetColor(-1, 0xD9F523)
    GUICtrlSetBkColor(-1, 0x483A57)


    $aProcessElements[$eIdx] = $aProcessRows[$pIdx][0]

    ; 2. Checkbox Цикл
    $aProcessRows[$pIdx][1] = GUICtrlCreateCheckbox("", $x2 + ($w2-$CheckBoxSize)/2, $y + ($rH-$CheckBoxSize)/2, $CheckBoxSize, $CheckBoxSize, BitOR($BS_CENTER, $BS_VCENTER))
    If $aProcesses[$pIdx][2] = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для чекбокса "При запуске"
    GUICtrlSetTip(-1, "Запустить процесс один раз при старте ProcessManager" & @CRLF & "После запуска чекбокс автоматически отключится")
    $aProcessElements[$eIdx+1] = $aProcessRows[$pIdx][1]

    ; 3. Auto (Autorun)
    Local $sAutoText = "⚡ AUTO"
    $aProcessRows[$pIdx][2] = GUICtrlCreateButton($sAutoText, $x3 + 2, $y + 5, $w3 - 4, $rH - 10)
    GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")

    If $aProcesses[$pIdx][3] = 1 Then
        GUICtrlSetColor(-1, 0xFFFFFF)
        GUICtrlSetBkColor(-1, 0x8E44AD)
    Else
        GUICtrlSetColor(-1, 0x8E44AD)
        GUICtrlSetBkColor(-1, 0xE0E0E0)
    EndIf

    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для кнопки AUTO
    GUICtrlSetTip(-1, "Включить автоматическое управление процессом" & @CRLF & "Процесс будет автоматически перезапускаться при завершении" & @CRLF & "Используются таймеры запуска и перезапуска")
    $aProcessElements[$eIdx+2] = $aProcessRows[$pIdx][2]

    ; 4. Stop
    Local $sStopText = "⏹ STOP"
    $aProcessRows[$pIdx][3] = GUICtrlCreateButton($sStopText, $x4 + 2, $y + 5, $w4 - 4, $rH - 10)
    GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")

    If $aProcesses[$pIdx][3] = 1 Then
        GUICtrlSetColor(-1, 0xFFFFFF)
        GUICtrlSetBkColor(-1, 0xC0392B)
        GUICtrlSetState(-1, $GUI_ENABLE)
    Else
        GUICtrlSetColor(-1, 0x7F8C8D)
        GUICtrlSetBkColor(-1, $color_separator)
        GUICtrlSetState(-1, $GUI_DISABLE)
    EndIf

    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для кнопки STOP
    GUICtrlSetTip(-1, "Выключить автоматическое управление процессом" & @CRLF & "Процесс НЕ будет автоматически перезапускаться" & @CRLF & "Активна только когда включен AUTO")
    $aProcessElements[$eIdx+3] = $aProcessRows[$pIdx][3]

    ; 5. Run
    $aProcessRows[$pIdx][4] = GUICtrlCreateButton("Run", $x5 + 2, $y + 5, $w5 - 4, $rH - 10)
	GUICtrlSetFont(-1, 12, 800, 0, "@Arial Unicode MS")
    GUICtrlSetColor(-1, $color_run)
    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для кнопки Run
    GUICtrlSetTip(-1, "Запустить процесс вручную" & @CRLF & "Процесс запустится немедленно")
    $aProcessElements[$eIdx+4] = $aProcessRows[$pIdx][4]

    ; 6. Exit
    $aProcessRows[$pIdx][5] = GUICtrlCreateButton("Exit", $x6 + 2, $y + 5, $w6 - 4, $rH - 10)
	GUICtrlSetFont(-1, 12, 800, 0, "@Arial Unicode MS")
	GUICtrlSetColor(-1, $color_stop)
    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для кнопки Exit
    GUICtrlSetTip(-1, "Завершить процесс вручную" & @CRLF & "Процесс будет остановлен немедленно" & @CRLF & "Если включен AUTO - процесс перезапустится")
    $aProcessElements[$eIdx+5] = $aProcessRows[$pIdx][5]

    ; 7. Счетчик
    Local $counter_label_width = Int($w7 * 0.8)
    Local $counter_label_height = Int($rH * 0.8)
    Local $counter_label_x = $x7 + Int(($w7 - $counter_label_width) / 2)
    Local $counter_label_y = $y + Int(($rH - $counter_label_height) / 2)
    $aProcessRows[$pIdx][6] = GUICtrlCreateLabel($aProcesses[$pIdx][4], $counter_label_x, $counter_label_y, $counter_label_width, $counter_label_height, BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont(-1, 12, 1200, 0, "@Arial Unicode MS")
    GUICtrlSetColor(-1, 0x67A8FD)
    GUICtrlSetBkColor(-1, 0x483A57)
    ; 💬 TOOLTIP: Подсказка для счётчика перезапусков
    GUICtrlSetTip(-1, "Счётчик автоматических перезапусков процесса" & @CRLF & "Увеличивается при каждом автоматическом запуске" & @CRLF & "Можно обнулить кнопкой 'Обнулить счётчики'")
    $aProcessElements[$eIdx+6] = $aProcessRows[$pIdx][6]

    ; 8. Статус
    Local $status_label_width = Int($w8 * 0.8)
    Local $status_label_height = Int($rH * 0.8)
    Local $status_label_x = $x8 + Int(($w8 - $status_label_width) / 2)
    Local $status_label_y = $y + Int(($rH - $status_label_height) / 2)
    $aProcessRows[$pIdx][7] = GUICtrlCreateLabel($aProcesses[$pIdx][5], $status_label_x, $status_label_y, $status_label_width, $status_label_height, BitOR($SS_CENTERIMAGE, $SS_CENTER))
	GUICtrlSetFont(-1, 14, 1000, 0, "@Arial Unicode MS")
	GUICtrlSetBkColor(-1, 0x483A57)
	
	; ЯВНОЕ определение цвета строго по тексту статуса
	Local $statusText = $aProcesses[$pIdx][5]
	If $statusText = "Runned" Then
		GUICtrlSetColor(-1, $color_run) ; Зеленый для работающих
	ElseIf $statusText = "Stopped" Or $statusText = "Stop" Then
		GUICtrlSetColor(-1, $color_stop) ; Красный для остановленных
	Else
		GUICtrlSetColor(-1, $color_stop) ; По умолчанию красный
	EndIf
	
    ; 💬 TOOLTIP: Подсказка для статуса процесса
    GUICtrlSetTip(-1, "Текущий статус процесса" & @CRLF & "Runned (зелёный) - процесс запущен" & @CRLF & "Stopped (красный) - процесс остановлен")
    $aProcessElements[$eIdx+7] = $aProcessRows[$pIdx][7]

    ; 9. Дубли
    $aProcessRows[$pIdx][8] = GUICtrlCreateCheckbox("", $x9 + ($w9-$CheckBoxSize)/2, $y + ($rH-$CheckBoxSize)/2, $CheckBoxSize, $CheckBoxSize, BitOR($BS_CENTER, $BS_VCENTER))
    If $aProcesses[$pIdx][6] = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
    GUICtrlSetOnEvent(-1, "ActionHandler")
    ; 💬 TOOLTIP: Подсказка для чекбокса Дубли
    GUICtrlSetTip(-1, "Контроль дублирующихся процессов" & @CRLF & "Автоматически завершает лишние экземпляры" & @CRLF & "Оставляет только один запущенный процесс")
    $aProcessElements[$eIdx+8] = $aProcessRows[$pIdx][8]

    ; 10. Время работы
    Local $worktime_label_width = Int($w10 * 0.8)
    Local $worktime_label_height = Int($rH * 0.9)
    Local $worktime_label_x = $x10 + Int(($w10 - $worktime_label_width) / 2)
    Local $worktime_label_y = $y + Int(($rH - $worktime_label_height) / 2)
    $aProcessRows[$pIdx][9] = GUICtrlCreateInput(CalculateWorkTime($aProcesses[$pIdx][10]), $worktime_label_x, $worktime_label_y, $worktime_label_width, $worktime_label_height, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetBkColor(-1, 0x483A57)
    GUICtrlSetFont(-1, 16, 800, 0, $Font_all)
    GUICtrlSetColor(-1, 0x00AF00)
    ; 💬 TOOLTIP: Подсказка для поля Время работы
    GUICtrlSetTip(-1, "Общее время работы процесса" & @CRLF & "Считается с момента последнего запуска" & @CRLF & "Формат: ЧЧ:ММ:СС")
    $aProcessElements[$eIdx+9] = $aProcessRows[$pIdx][9]

    ; 11. Timer Start
    Local $timer1_label_width = Int($w11 * 0.8)
    Local $timer1_label_height = Int($rH * 0.8)
    Local $timer1_label_x = $x11 + Int(($w11 - $timer1_label_width) / 2)
    Local $timer1_label_y = $y + Int(($rH - $timer1_label_height) / 2)
    $aProcessRows[$pIdx][10] = GUICtrlCreateLabel($aProcesses[$pIdx][8], $timer1_label_x, $timer1_label_y, $timer1_label_width, $timer1_label_height, BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont(-1, 12, 1000, 0, $Font_all)
    GUICtrlSetColor(-1, 0x43F6A5)
    GUICtrlSetBkColor(-1, 0x483A57)
    ; 💬 TOOLTIP: Подсказка для таймера При запуске
    GUICtrlSetTip(-1, "Задержка перед первым запуском процесса" & @CRLF & "Используется при включенном 'При запуске'" & @CRLF & "Формат: ЧЧ:ММ:СС (например 00:00:05)")
    $aProcessElements[$eIdx+10] = $aProcessRows[$pIdx][10]

    ; 12. Timer Restart
    Local $timer2_label_width = Int($w12 * 0.8)
    Local $timer2_label_height = Int($rH * 0.8)
    Local $timer2_label_x = $x12 + Int(($w12 - $timer2_label_width) / 2)
    Local $timer2_label_y = $y + Int(($rH - $timer2_label_height) / 2)
    $aProcessRows[$pIdx][11] = GUICtrlCreateLabel($aProcesses[$pIdx][9], $timer2_label_x, $timer2_label_y, $timer2_label_width, $timer2_label_height, BitOR($SS_CENTERIMAGE, $SS_CENTER))
    GUICtrlSetFont(-1, 12, 1000, 0, $Font_all)
    GUICtrlSetColor(-1, 0x43F6A5)
    GUICtrlSetBkColor(-1, 0x483A57)
    ; 💬 TOOLTIP: Подсказка для таймера Перезапуск
    GUICtrlSetTip(-1, "Интервал между автоматическими перезапусками" & @CRLF & "Используется при включенном AUTO" & @CRLF & "Формат: ЧЧ:ММ:СС (например 00:00:10)")
    $aProcessElements[$eIdx+11] = $aProcessRows[$pIdx][11]

    ; Горизонтальные и вертикальные разделители
    $aProcessElements[$eIdx+12] = GUICtrlCreateLabel("", $xS, $y + $rH, $iClientHeight - 20, 2)
    GUICtrlSetBkColor(-1, 0x808080)

    ; Вертикальные разделители между столбцами
    Local $vLines[11]
    $vLines[0] = GUICtrlCreateLabel("", $col_loop_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+13] = $vLines[0]

    $vLines[1] = GUICtrlCreateLabel("", $col_autorun_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+14] = $vLines[1]

    $vLines[2] = GUICtrlCreateLabel("", $col_stop_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+15] = $vLines[2]

    $vLines[3] = GUICtrlCreateLabel("", $col_play_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+16] = $vLines[3]

    $vLines[4] = GUICtrlCreateLabel("", $col_pause_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+17] = $vLines[4]

    $vLines[5] = GUICtrlCreateLabel("", $col_counter_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+18] = $vLines[5]

    $vLines[6] = GUICtrlCreateLabel("", $col_status_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+19] = $vLines[6]

    $vLines[7] = GUICtrlCreateLabel("", $col_duplicates_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+20] = $vLines[7]

    $vLines[8] = GUICtrlCreateLabel("", $col_worktime_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+21] = $vLines[8]

    $vLines[9] = GUICtrlCreateLabel("", $col_timer1_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+22] = $vLines[9]

    $vLines[10] = GUICtrlCreateLabel("", $col_timer2_x - 6, $y, 2, $rH + 2)
    GUICtrlSetBkColor(-1, 0x808080)
    $aProcessElements[$eIdx+23] = $vLines[10]
EndFunc
; 🎨 Функция обновления информативной строки состояния (без мерцания)
Func UpdateStatusBar()
    If Not $lblStatus Then Return
    
    Local $runningCount = 0, $autostartCount = 0, $totalProcesses = $aProcesses[0][0]
    
    ; Подсчитываем статистику
    For $i = 1 To $totalProcesses
        If $aProcesses[$i][5] = "Runned" Then $runningCount += 1
        If $aProcesses[$i][3] = 1 Then $autostartCount += 1
    Next
    
    ; 📝 Получаем ПОЛНУЮ информацию о последней записи лога
    Local $lastLogInfo = "Нет записей"
    Local $logFile = @ScriptDir & "\log\ProcessManager.log"
    If FileExists($logFile) Then
        Local $aLogLines = FileReadToArray($logFile)
        If IsArray($aLogLines) And UBound($aLogLines) > 0 Then
            Local $sLastLogLine = $aLogLines[UBound($aLogLines) - 1]
            
            ; Парсим строку лога: [*] 0123 | 2026-01-13 19:12:44 | КОНСОЛЬ | ProcessName | Сообщение
            Local $aLogParts = StringSplit($sLastLogLine, "|", 1)
            If IsArray($aLogParts) And $aLogParts[0] >= 4 Then
                Local $sTime = StringStripWS($aLogParts[2], 3)  ; Время
                Local $sType = StringStripWS($aLogParts[3], 3)  ; Тип (КОНСОЛЬ, СИСТЕМА и т.д.)
                Local $sProcess = StringStripWS($aLogParts[4], 3) ; Имя процесса
                Local $sMessage = ""
                
                ; Собираем сообщение из оставшихся частей
                If $aLogParts[0] >= 5 Then
                    For $i = 5 To $aLogParts[0]
                        $sMessage &= StringStripWS($aLogParts[$i], 3)
                        If $i < $aLogParts[0] Then $sMessage &= "|"
                    Next
                EndIf
                
                ; Формируем информативную строку: Процесс → Тип → Сообщение (Время)
                $lastLogInfo = $sProcess & " → " & $sType & " → " & StringLeft($sMessage, 60) & " (" & StringRight($sTime, 8) & ")"
            Else
                ; Если не удалось распарсить, показываем последние 80 символов
                $lastLogInfo = StringRight($sLastLogLine, 80)
            EndIf
        EndIf
    EndIf
    
    ; 📊 Формируем РАСШИРЕННУЮ строку состояния с полной информацией
    Local $newStatusText = "📊 Всего: " & $totalProcesses & " | ▶️ Активно: " & $runningCount & " | ⚡ Авто: " & $autostartCount & " | 📝 " & $lastLogInfo
    
    ; 🚫 Обновляем только если текст изменился (избегаем мерцания)
    Local $currentText = GUICtrlRead($lblStatus)
    If $currentText <> $newStatusText Then
        GUICtrlSetData($lblStatus, $newStatusText)
    EndIf
EndFunc