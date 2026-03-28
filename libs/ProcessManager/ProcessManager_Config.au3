; ===============================================
; ProcessManager_Config.au3
; Конфигурация и глобальные переменные
; ===============================================

; --- Глобальные переменные (Загрузка размеров из INI) ---
Global $sIniPath = @ScriptDir & "\config\ProcessConfig.ini"

Global $iClientHeight = Int(IniRead($sIniPath, "Settings", "WindowWidth", 1300))
Global $iClientWeight = Int(IniRead($sIniPath, "Settings", "WindowHeight", 800))

Global $nameprog = "Process Manager v1.0"
Global $hGUI, $fon
Global $MaxProcesses = 15
Global $ProcessRowHeight = 32
Global $ColumnGap = 5
Global $CheckBoxSize = 13 ; Размер checkbox'ов (квадратный)

; Глобальные переменные для шрифтов
Global $hFont_Default, $hFont_Bold, $hFont_Error, $hFont_Small

; --- Цветовая схема ---
Global $color_header_text = 0xFFFFFF
Global $color_header_bg = 0x34495E
Global $color_title_text = 0x2C3E50
Global $color_status_text = 0x27AE60
Global $color_separator = 0xBDC3C7
Global $color_row_even = 0xF8F9FA
Global $color_row_odd = 0xFFFFFF
Global $color_text_main = 0x2C3E50
Global $color_run = 0x27AE60
Global $color_stop = 0xE74C3C
Global $Font_all = "Arial" ; Изменил на обычный Arial для совместимости, если нет Unicode MS

; 🎨 Новые цвета для улучшенного оформления таблицы
Global $color_process_name = 0x2C3E50      ; Темно-синий для имен процессов
Global $color_process_name_bg = 0xECF0F1   ; Светло-серый фон для имен
Global $color_counter_text = 0x8E44AD      ; Фиолетовый для счетчиков
Global $color_counter_bg = 0xF4ECF7        ; Светло-фиолетовый фон
Global $color_timer_text = 0xD35400        ; Оранжевый для таймеров
Global $color_timer_bg = 0xFDF2E9          ; Светло-оранжевый фон
Global $color_worktime_text = 0x16A085     ; Бирюзовый для времени работы
Global $color_worktime_bg = 0xE8F8F5       ; Светло-бирюзовый фон

; 🎨 Цвета для строки состояния и кнопок
Global $color_status_bar_bg = 0x34495E     ; Темно-синий фон строки состояния
Global $color_status_bar_text = 0xFFFFFF   ; Белый текст строки состояния
Global $color_button_bg = 0x3498DB         ; Синий фон кнопок
Global $color_button_text = 0xFFFFFF       ; Белый текст кнопок

; 🎨 Цвета для диалогов
Global $color_dialog_bg = 0x2C3E50         ; Темно-синий фон диалога
Global $color_dialog_label = 0xFFFFFF      ; Белый текст меток
Global $color_dialog_input_bg = 0xFFFFFF   ; Белый фон полей ввода
Global $color_dialog_input_text = 0x2C3E50 ; Темно-синий текст в полях
Global $color_dialog_button_ok = 0x27AE60  ; Зеленый для кнопки OK
Global $color_dialog_button_cancel = 0xE74C3C ; Красный для кнопки Отмена
Global $color_dialog_button_browse = 0x9B59B6 ; Фиолетовый для кнопки обзора

; --- Процентное распределение ширины столбцов ---
Global $col_name_percent = 16
Global $col_loop_percent = 12
Global $col_autorun_percent = 6
Global $col_stop_percent = 6
Global $col_play_percent = 5
Global $col_pause_percent = 5
Global $col_counter_percent = 8
Global $col_status_percent = 8
Global $col_duplicates_percent = 6
Global $col_worktime_percent = 12
Global $col_timer1_percent = 8
Global $col_timer2_percent = 8

; --- Массивы ---
; [0]Имя [1]ExePath [2]IsLooped [3]IsAutorun [4]RestartCount [5]Status [6]KillDuplicates [7]Mode [8]TimerStart_first_launch [9]TimerRestart_frequency_limit [10]DateTime_last_start [11]TimerHandle [12]OnStartFlag [13]DateTime_last_stop
; TimerStart_first_launch - таймаут для первого запуска приложений (таймаут 2)
; TimerRestart_frequency_limit - максимальная частота перезапусков в зацикленном режиме (таймаут 1)
; OnStartFlag - флаг для отслеживания первого запуска приложения (1 - первый запуск, 0 - уже запускалось)
; DateTime_last_stop - дата и время пос ; Увеличено до 14 колонок для хранения времени остановки
Global $aProcesses[1][14] ; Увеличено до 14 колонок для хранения времени остановки
$aProcesses[0][0] = 0

Global $aProcessRows[1][14]
Global $aProcessElements[1]
Global $ElementsPerRow = 13 ; Основные элементы (имя, чекбоксы, кнопки и т.д.)
$aProcessElements[0] = 0

; --- Переменные GUI ---
Global $active_on = 0
Global $okno_dobavlenie, $input_process_path, $input_process_name, $input_timer_start, $input_timer_restart
Global $radio_single, $radio_loop, $btn_browse, $btn_add_confirm, $btn_add_cancel
Global $btnAddProcess, $btnDeleteProcess, $btnLogs, $btnSaveSettings, $lblStatus, $btnResetCounters

; --- Переменные системы логирования ---
Global $sLogPath = @ScriptDir & "\log\ProcessManager.log"
Global $iMaxLogEntries = Int(IniRead($sIniPath, "Logs", "MaxEntries", "1000"))
Global $iMaxDisplayEntries = Int(IniRead($sIniPath, "Logs", "MaxDisplayEntries", "500"))
Global $iLogCounter = 0
Global $hLogWindow = 0
Global $bLogWindowActive = False
Global $inputMaxEntries = 0, $inputMaxDisplay = 0, $listViewLogs = 0

; --- Переменные системы горячих клавиш ---
Global $iHK_Tries = 0  ; Счетчик попыток регистрации F5

; --- Переменные фильтрации логов ---
Global $comboFilterType = 0, $comboFilterProcess = 0
Global $sCurrentTypeFilter = "Все", $sCurrentProcessFilter = "Все"
Global $allProcs

; --- Переменные мониторинга Watchdog.log ---
Global $sWatchdogLogPath = @ScriptDir & "\log\Watchdog.log"
Global $iWatchdogLastSize = 0
Global $sWatchdogLastModified = ""

; --- Переменные ресайза ---
Global $fResizeTriggered = False, $iResizeTimer = 0
