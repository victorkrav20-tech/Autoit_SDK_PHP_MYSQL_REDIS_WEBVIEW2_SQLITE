; ===============================================
; ProcessManager_ProcessDialog.au3
; Диалоги добавления и удаления процессов
; ===============================================

Func AddProcess()
    If $active_on <> 0 Then Return
    $active_on = 10

    ; 🎨 Создаем красивое окно диалога
    $okno_dobavlenie = GUICreate("➕ Добавить новый процесс", 600, 450, -1, -1, BitOR($WS_BORDER, $SS_CENTER), $WS_EX_TOPMOST)
    GUISetBkColor($color_dialog_bg)  ; 🎨 Темно-синий фон

    ; 🎨 Заголовок диалога
    Local $lblTitle = GUICtrlCreateLabel("Настройка нового процесса", 20, 15, 560, 35, BitOR($SS_CENTER, $SS_CENTERIMAGE))
    GUICtrlSetFont($lblTitle, 16, 800, 0, $Font_all)
    GUICtrlSetColor($lblTitle, $color_dialog_label)
    GUICtrlSetBkColor($lblTitle, $color_dialog_bg)

    ; 🎨 Разделительная линия
    Local $separator1 = GUICtrlCreateLabel("", 20, 55, 560, 2)
    GUICtrlSetBkColor($separator1, $color_separator)

    ; 🎨 Имя процесса
    Local $lblName = GUICtrlCreateLabel("📝 Имя процесса:", 30, 80, 180, 25, $SS_CENTERIMAGE)
    GUICtrlSetFont($lblName, 11, 600, 0, $Font_all)
    GUICtrlSetColor($lblName, $color_dialog_label)
    GUICtrlSetBkColor($lblName, $color_dialog_bg)
    
    $input_process_name = GUICtrlCreateInput('', 220, 78, 350, 28);570 Закрытие
    GUICtrlSetFont($input_process_name, 11, 400, 0, $Font_all)
    GUICtrlSetBkColor($input_process_name, $color_dialog_input_bg)
    GUICtrlSetColor($input_process_name, $color_dialog_input_text)

    ; 🎨 Путь к exe
    Local $lblPath = GUICtrlCreateLabel("📂 Путь к exe файлу:", 30, 125, 180, 25, $SS_CENTERIMAGE)
    GUICtrlSetFont($lblPath, 11, 600, 0, $Font_all)
    GUICtrlSetColor($lblPath, $color_dialog_label)
    GUICtrlSetBkColor($lblPath, $color_dialog_bg)
    
    $input_process_path = GUICtrlCreateInput('', 220, 123, 260, 28)
    GUICtrlSetFont($input_process_path, 11, 400, 0, $Font_all)
    GUICtrlSetBkColor($input_process_path, $color_dialog_input_bg)
    GUICtrlSetColor($input_process_path, $color_dialog_input_text)
    
    $btn_browse = GUICtrlCreateButton("📁 Обзор", 490, 122, 80, 30)
    GUICtrlSetFont($btn_browse, 10, 600, 0, $Font_all)
    GUICtrlSetBkColor($btn_browse, $color_dialog_button_browse)
    GUICtrlSetColor($btn_browse, 0xFFFFFF)
    GUICtrlSetOnEvent($btn_browse, "BrowseForProcess")

    ; 🎨 Разделительная линия
    Local $separator2 = GUICtrlCreateLabel("", 20, 170, 560, 2)
    GUICtrlSetBkColor($separator2, $color_separator)

    ; 🎨 Настройки запуска
    Local $lblSettings = GUICtrlCreateLabel("⚙️ Настройки запуска", 30, 185, 200, 25, $SS_CENTERIMAGE)
    GUICtrlSetFont($lblSettings, 12, 700, 0, $Font_all)
    GUICtrlSetColor($lblSettings, $color_dialog_label)
    GUICtrlSetBkColor($lblSettings, $color_dialog_bg)

    ; 🎨 Чекбокс "При запуске"
    $radio_loop = GUICtrlCreateCheckbox("🔄 Запускать при старте системы", 50, 220, 300, 25)
    GUICtrlSetFont($radio_loop, 11, 500, 0, $Font_all)
    GUICtrlSetColor($radio_loop, $color_dialog_label)
    GUICtrlSetBkColor($radio_loop, $color_dialog_bg)
    GUICtrlSetState(-1, $GUI_UNCHECKED)

    ; 🎨 Таймер старта
    Local $lblTimerStart = GUICtrlCreateLabel("⏱️ Задержка старта (сек):", 50, 260, 220, 25, $SS_CENTERIMAGE)
    GUICtrlSetFont($lblTimerStart, 11, 600, 0, $Font_all)
    GUICtrlSetColor($lblTimerStart, $color_dialog_label)
    GUICtrlSetBkColor($lblTimerStart, $color_dialog_bg)
    
    $input_timer_start = GUICtrlCreateInput('5', 280, 258, 80, 28, $ES_CENTER)
    GUICtrlSetFont($input_timer_start, 11, 400, 0, $Font_all)
    GUICtrlSetBkColor($input_timer_start, $color_dialog_input_bg)
    GUICtrlSetColor($input_timer_start, $color_dialog_input_text)

    ; 🎨 Таймер рестарта
    Local $lblTimerRestart = GUICtrlCreateLabel("🔄 Интервал рестарта (сек):", 50, 300, 220, 25, $SS_CENTERIMAGE)
    GUICtrlSetFont($lblTimerRestart, 11, 600, 0, $Font_all)
    GUICtrlSetColor($lblTimerRestart, $color_dialog_label)
    GUICtrlSetBkColor($lblTimerRestart, $color_dialog_bg)
    
    $input_timer_restart = GUICtrlCreateInput('10', 280, 298, 80, 28, $ES_CENTER)
    GUICtrlSetFont($input_timer_restart, 11, 400, 0, $Font_all)
    GUICtrlSetBkColor($input_timer_restart, $color_dialog_input_bg)
    GUICtrlSetColor($input_timer_restart, $color_dialog_input_text)

    ; 🎨 Разделительная линия
    Local $separator3 = GUICtrlCreateLabel("", 20, 345, 560, 2)
    GUICtrlSetBkColor($separator3, $color_separator)

    ; 🎨 Кнопки управления
    $btn_add_confirm = GUICtrlCreateButton("✅ Добавить процесс", 80, 365, 180, 40)
    GUICtrlSetFont($btn_add_confirm, 12, 700, 0, $Font_all)
    GUICtrlSetBkColor($btn_add_confirm, $color_dialog_button_ok)
    GUICtrlSetColor($btn_add_confirm, 0xFFFFFF)
    GUICtrlSetOnEvent($btn_add_confirm, "ConfirmAddProcess")

    $btn_add_cancel = GUICtrlCreateButton("❌ Отмена", 340, 365, 180, 40)
    GUICtrlSetFont($btn_add_cancel, 12, 700, 0, $Font_all)
    GUICtrlSetBkColor($btn_add_cancel, $color_dialog_button_cancel)
    GUICtrlSetColor($btn_add_cancel, 0xFFFFFF)
    GUICtrlSetOnEvent($btn_add_cancel, "CancelAddProcess")

    GUISetState(@SW_SHOW, $okno_dobavlenie)
EndFunc

Func BrowseForProcess()
    Local $sOriginalDir = @WorkingDir
    Local $sFile = FileOpenDialog("📂 Выберите исполняемый файл процесса", @ScriptDir, "Исполняемые файлы (*.exe)", 1)
    If Not @error Then
        GUICtrlSetData($input_process_path, $sFile)
        ; 🎨 Автоматически заполняем имя процесса если поле пустое
        If GUICtrlRead($input_process_name) = "" Then
            Local $processName = StringRegExpReplace($sFile, ".*\\(.*)\.exe$", "$1")
            GUICtrlSetData($input_process_name, $processName)
        EndIf
    EndIf
    FileChangeDir($sOriginalDir) ; Возвращаем исходную рабочую директорию
EndFunc

Func ConfirmAddProcess()
    Local $name = StringStripWS(GUICtrlRead($input_process_name), 3)  ; Убираем лишние пробелы
    Local $path = StringStripWS(GUICtrlRead($input_process_path), 3)
    
    ; 🎨 Улучшенная валидация
    If $name = "" Or $path = "" Then 
        ; 🎯 НЕБЛОКИРУЮЩИЙ MsgBox с таймаутом 5 секунд
        ;Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(48, ''⚠️ Внимание'', ''Пожалуйста, заполните все обязательные поля:'' & @CRLF & @CRLF & ''• Имя процесса'' & @CRLF & ''• Путь к exe файлу'', 5)"', '', @SW_SHOW)
		_ExternalMsg("⚠️ Внимание", "Пожалуйста, заполните все обязательные поля:" & @CRLF & @CRLF & "• Имя процесса" & @CRLF & "• Путь к exe файлу",10)
        Return
    EndIf
    
    ; Проверяем существование файла
    If Not FileExists($path) Then
        ; 🎯 НЕБЛОКИРУЮЩИЙ MsgBox с таймаутом 5 секунд
        Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(16, ''❌ Ошибка'', ''Указанный файл не существует:'' & @CRLF & @CRLF & ''' & $path & ''', 5)"', '', @SW_SHOW)
        Return
    EndIf

    $aProcesses[0][0] += 1
    ReDim $aProcesses[$aProcesses[0][0] + 1][14]
    Local $idx = $aProcesses[0][0]

    $aProcesses[$idx][0] = $name
    $aProcesses[$idx][1] = $path
    $aProcesses[$idx][2] = (GUICtrlRead($radio_loop) = $GUI_CHECKED) ? 1 : 0 ; Зацикливание
    $aProcesses[$idx][3] = 0 ; Autorun (автозапуск выключен по умолчанию)
    $aProcesses[$idx][4] = 0 ; Restarts
    $aProcesses[$idx][5] = "Stop"
    $aProcesses[$idx][6] = 0 ; Duplicates
    $aProcesses[$idx][8] = StringFormat("00:00:%02d", Int(GUICtrlRead($input_timer_start)))
    $aProcesses[$idx][9] = StringFormat("00:00:%02d", Int(GUICtrlRead($input_timer_restart)))
    $aProcesses[$idx][10] = _NowCalc()
    $aProcesses[$idx][11] = TimerInit() ; Инициализация таймера

    ; Логируем добавление процесса
    WriteLog("КОНСОЛЬ", $name, "✅ Процесс добавлен в систему: " & $path)

    CancelAddProcess()
    SaveSettingsToINI()
    CreateProcessRows()

    ; Обновляем фильтр процессов в окне логов, если оно открыто
    If $bLogWindowActive Then UpdateProcessFilter()
    
    ; 🎨 Показываем уведомление об успешном добавлении (НЕБЛОКИРУЮЩЕЕ)
   ; Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''✅ Успешно'', ''Процесс '''' & ''' & $name & ''' & '''' успешно добавлен в систему!'', 2)"', '', @SW_SHOW)
	_ExternalMsg("✅ Успешно", "Процесс " & $name & " успешно добавлен в систему!",10)
EndFunc

Func CancelAddProcess()
    GUIDelete($okno_dobavlenie)
    $active_on = 0
EndFunc

Func DeleteProcess()
    If $aProcesses[0][0] = 0 Then 
        MsgBox(48, "⚠️ Внимание", "Нет процессов для удаления!", 3)
		
        Return
    EndIf

    ; 🎨 Красивое подтверждение удаления
    Local $lastProcessName = $aProcesses[$aProcesses[0][0]][0]
    Local $result = MsgBox(36, "🗑️ Подтверждение удаления", "Вы действительно хотите удалить процесс:" & @CRLF & @CRLF & "📝 " & $lastProcessName & @CRLF & @CRLF & "Это действие нельзя отменить!",10)
    
    If $result = 6 Then  ; Да
        Local $deletedName = $aProcesses[$aProcesses[0][0]][0]
        Local $deletedPath = $aProcesses[$aProcesses[0][0]][1]

        $aProcesses[0][0] -= 1
        If $aProcesses[0][0] = 0 Then
            ReDim $aProcesses[1][14] ; Если нет процессов, оставляем только заголовок
        Else
            ReDim $aProcesses[$aProcesses[0][0] + 1][14]
        EndIf

        ; Логируем удаление процесса
        WriteLog("КОНСОЛЬ", $deletedName, "🗑️ Процесс удален из системы: " & $deletedPath)

        SaveSettingsToINI()
        CreateProcessRows()

        ; Обновляем фильтр процессов в окне логов, если оно открыто
        If $bLogWindowActive Then UpdateProcessFilter()
        
        ; 🎨 Уведомление об успешном удалении (НЕБЛОКИРУЮЩЕЕ)
       ; Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(64, ''✅ Успешно'', ''Процесс '''' & ''' & $deletedName & ''' & '''' успешно удален!'', 2)"', '', @SW_SHOW)
		_ExternalMsg("✅ Успешно", "Процесс " & $deletedName & " успешно удален!",10)
    EndIf
EndFunc