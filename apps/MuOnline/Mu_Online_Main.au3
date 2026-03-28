; ===============================================================================
; Приложение: MU Online Auto Reset Bot
; Описание: Фоновый бот для автоматической прокачки ресетов
; Версия: 1.0.0
; Дата: 11.03.2026
; ===============================================================================
; ФУНКЦИИ:
; _GUI_Create() - Создание главного окна
; _GUI_OnExit() - Обработчик закрытия
; _GUI_AddLog() - Добавление строки в лог GUI
; _Button_ReadWindows() - Чтение всех окон main.exe
; _Button_ParseData() - Парсинг данных из окна
; _Button_Screenshot() - Фоновый скриншот окна + OCR
; _CaptureWindowBackground() - Фоновый захват окна через PrintWindow
; _ParseLevelFromTitle() - Парсинг уровня из заголовка окна
; ===============================================================================

#include "..\..\libs\SDK_Init.au3"
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <GDIPlus.au3>
#include <ScreenCapture.au3>
#include "UWPOCR-main\UWPOCR.au3"
#include "Mu_Online_Core.au3"
#include "Mu_Online_Send.au3"
#include "Mu_Online_Markers.au3"

; === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
Global $g_sApp_AppName = "MuOnline_Bot"

; === НАСТРОЙКА ПЕРСОНАЖА (ИЗМЕНИТЬ ДЛЯ КАЖДОЙ КОПИИ) ===
Global $g_sTargetCharacterName = "NanoElf"  ; Ник персонажа для автопоиска
Global $g_bAutoAddStats = True          ; Флаг: включено ли авто-распределение статов
Global $g_iAutoAddStats_STR = 1000          ; Количество очков в STR
Global $g_iAutoAddStats_AGI = 25000          ; Количество очков в AGI
Global $g_iAutoAddStats_VIT = 3000          ; Количество очков в VIT
Global $g_iAutoAddStats_ENE = 8000          ; Количество очков в ENE
Global $g_iAutoAddStats_CMD = 0          ; Количество очков в CMD

#cs
Global $g_sTargetCharacterName = "xishnikMG"  ; Ник персонажа для автопоиска
; === НАСТРОЙКИ АВТО-РАСПРЕДЕЛЕНИЯ СТАТОВ ПОСЛЕ РЕСЕТА ===
Global $g_bAutoAddStats = True          ; Флаг: включено ли авто-распределение статов
Global $g_iAutoAddStats_STR = 2000          ; Количество очков в STR
Global $g_iAutoAddStats_AGI = 20000          ; Количество очков в AGI
Global $g_iAutoAddStats_VIT = 3000          ; Количество очков в VIT
Global $g_iAutoAddStats_ENE = 25000          ; Количество очков в ENE
Global $g_iAutoAddStats_CMD = 0          ; Количество очков в CMD
#ce
Global $g_hTargetWindow = 0                  ; Handle выбранного окна

Global $g_hGUI = 0
Global $g_idBtnReadWindows = 0
Global $g_idBtnParseData = 0
Global $g_idBtnScreenshot = 0
Global $g_idBtnReset = 0
Global $g_idBtnTeleport = 0
Global $g_idBtnMoveWindow = 0
Global $g_idBtnMoveWindowProd = 0
Global $g_idBtnScanMarkers = 0
Global $g_idListView = 0          ; устарело, оставлено для совместимости
Global $g_idCombo_Windows = 0     ; Dropdown выбора окна MU Online
Global $g_idEdit_Log = 0
Global $g_aWindows = ''
Global $g_aFoundWindows[1][3]     ; [HWND, PID, display] — индексированный список найденных окон
Global $g_iFoundWindowsCount = 0  ; Количество найденных окон

; === GUI МЕТКИ ДАННЫХ ПЕРСОНАЖА ===
Global $g_idLabel_WinNick = 0
Global $g_idLabel_WinLevel = 0
Global $g_idLabel_WinMasterLevel = 0
Global $g_idLabel_WinResets = 0

; === GUI ЭЛЕМЕНТЫ ДЛЯ ЗАПИСИ МАРШРУТА ===
Global $g_idCombo_City = 0
Global $g_idInput_RouteName = 0
Global $g_idBtn_StartRecord = 0
Global $g_idBtn_AddPoint = 0
Global $g_idBtn_SaveRoute = 0
Global $g_idBtn_CancelRecord = 0
Global $g_idLabel_PointsCount = 0

; === GUI ЭЛЕМЕНТЫ ДЛЯ НАВИГАЦИИ И ВЫПОЛНЕНИЯ ===
Global $g_idBtn_MoveXPlus = 0
Global $g_idBtn_MoveXMinus = 0
Global $g_idBtn_MoveYPlus = 0
Global $g_idBtn_MoveYMinus = 0
Global $g_idInput_MoveAngle = 0       ; Input угла 0-360
Global $g_idInput_DistMult = 0        ; Input множителя дистанции (float)
Global $g_idBtn_MoveByAngle = 0       ; Кнопка "По углу"
Global $g_idInput_DistMult_AP = 0     ; Input множителя дистанции в группе автопилота
Global $g_idCombo_RouteSelect = 0
Global $g_idBtn_RefreshRoutes = 0
Global $g_idBtn_ExecuteRoute = 0
Global $g_idBtn_StopRoute = 0          ; Кнопка прерывания маршрута
Global $g_idCheck_HelperOnStart = 0    ; Чекбокс активации Helper на старте

; === ФЛАГИ ВЫПОЛНЕНИЯ ===
Global $g_bRouteExecuting = False      ; Флаг выполнения маршрута
Global $g_bRouteStopRequested = False  ; Флаг запроса остановки

; === ДАННЫЕ ТЕКУЩЕГО МАРШРУТА ===
Global $g_oCurrentExecutingRoute = ""  ; Объект маршрута для выполнения
Global $g_iCurrentWaypointIndex = 0    ; Индекс текущей точки
Global $g_iRouteExecutionState = 0     ; Состояние: 0=не активен, 1=телепорт, 2=helper на старте, 3=движение, 4=helper в конце, 5=завершён

; === НАСТРОЙКИ АВТОПИЛОТА ===
Global $g_bAutopilotEnabled = False           ; Флаг включения автопилота
Global $g_iAutopilot_MinLevel = 400           ; Минимальный уровень для авторесета
Global $g_iAutopilot_CorrectionInterval = 5  ; Интервал корректировки (сек)
Global $g_iAutopilot_CorrectionTolerance = 5  ; Допуск для корректировки позиции (3 клика)
Global $g_iAutopilot_ReturnTolerance = 15     ; Допуск для автовозврата (перезапуск маршрута)
Global $g_iAutopilot_ResetWaitTime = 2        ; Задержка после ресета перед запуском маршрута (сек)
Global $g_iAutopilot_ResetCount = 0           ; Счётчик ресетов
Global $g_iAutopilot_LastCheckTime = 0        ; Время последней проверки корректировки
Global $g_iAutopilot_LastLevel = 0            ; Последний уровень для расчёта DPS
Global $g_iAutopilot_LastLevelTime = 0        ; Время последнего изменения уровня
Global $g_fAutopilot_LevelPerMinute = 0       ; Уровней в минуту (DPS)
Global $g_aAutopilot_DPS_History[10]          ; Массив последних 10 измерений DPS для усреднения
Global $g_iAutopilot_DPS_HistoryIndex = 0     ; Индекс для записи в массив
Global $g_iAutopilot_DPS_HistoryCount = 0     ; Количество записей в массиве
Global $g_iAutopilot_RouteFailCount = 0       ; Счётчик неудачных попыток маршрута
Global $g_iAutopilot_MaxRouteFails = 5        ; Максимум неудачных попыток
Global $g_iAutopilot_LastProcessTime = 0      ; Время последнего вызова автопилота



; === СОСТОЯНИЯ АВТОПИЛОТА ===
Global $g_iAutopilot_State = 0
; 0 = Ожидание (на споте, Helper активен)
; 1 = Ожидание выполнения маршрута (после ресета или автовозврата)
; 2 = Корректировка позиции
; 3 = Выполнение авторесета

; === GUI ЭЛЕМЕНТЫ АВТОПИЛОТА ===
Global $g_idBtn_AutopilotStart = 0
Global $g_idBtn_AutopilotStop = 0
Global $g_idCheck_AutoReset = 0
Global $g_idCheck_RestartAfterReset = 0
Global $g_idCheck_PositionCorrection = 0
Global $g_idCheck_AutoReturn = 0
Global $g_idLabel_CurrentLevel = 0
Global $g_idLabel_ResetCount = 0
Global $g_idLabel_LevelPerMin = 0
Global $g_idLabel_AutopilotStatus = 0
Global $g_idInput_MinLevel = 0
Global $g_idInput_ResetWait = 0
Global $g_idInput_CorrInterval = 0
Global $g_idInput_ReturnTolerance = 0
Global $g_idInput_CorrTolerance = 0
Global $g_idInput_MaxRouteFails = 0
Global $g_idInput_ClicksPerCycle = 0
Global $g_idInput_MoveTimeout = 0
Global $g_idInput_CharName = 0
Global $g_idCheck_AutoStats = 0
Global $g_idInput_STR = 0
Global $g_idInput_AGI = 0
Global $g_idInput_VIT = 0
Global $g_idInput_ENE = 0
Global $g_idInput_CMD = 0

; === ПЕРЕМЕННЫЕ ДЛЯ ЗАПИСИ МАРШРУТА ===
Global $g_oCurrentRoute = ""           ; Текущий записываемый маршрут (Map)
Global $g_aWaypoints = ""              ; Массив waypoints
Global $g_sRoutesFolder = @ScriptDir & "\data\routes"  ; Папка с маршрутами
Global $g_aCities = ""                 ; Массив городов из конфига
Global $g_sCitiesFile = @ScriptDir & "\data\cities.json"  ; Файл с городами

; === КООРДИНАТЫ НАВИГАЦИИ (ЦЕНТР ПЕРСОНАЖА) ===
Global $g_iCenter_X = 810              ; X центра персонажа на экране
Global $g_iCenter_Y = 440              ; Y центра персонажа на экране

; === НАПРАВЛЕНИЯ ДВИЖЕНИЯ (ОТНОСИТЕЛЬНО ЦЕНТРА) ===
Global $g_iMove_XPlus_X = 810 + 150    ; X+ направление: X = 960
Global $g_iMove_XPlus_Y = 440 + 140    ; X+ направление: Y = 580
Global $g_iMove_XMinus_X = 810 - 150   ; X- направление: X = 660
Global $g_iMove_XMinus_Y = 440 - 140   ; X- направление: Y = 300
Global $g_iMove_YPlus_X = 810 + 190    ; Y+ направление: X = 1000
Global $g_iMove_YPlus_Y = 440 - 120    ; Y+ направление: Y = 320
Global $g_iMove_YMinus_X = 810 - 190   ; Y- направление: X = 620
Global $g_iMove_YMinus_Y = 440 + 120   ; Y- направление: Y = 560

; === НАСТРОЙКИ НАВИГАЦИИ ===
Global $g_iMove_ClicksPerCycle = 2     ; Кликов за один цикл движения
Global $g_iMove_CoordsTolerance = 3    ; Допуск достижения цели (пикселей)
Global $g_iMove_Timeout = 30           ; Таймаут на одну точку (секунд)
Global $g_iMove_CheckDelay = 200       ; Задержка между проверками (мс)
Global $g_fMove_DistMult = 1.0         ; Множитель дистанции клика (1.0 = стандарт)

; === КООРДИНАТЫ ДЛЯ РАЗРЕЗКИ ИЗОБРАЖЕНИЙ ===
; Основная область (верхний левый угол окна)
Global $g_iCrop_X = 0
Global $g_iCrop_Y = 0
Global $g_iCrop_Width = 340
Global $g_iCrop_Height = 70

; === КООРДИНАТЫ ДЛЯ ТЕЛЕПОРТА (WARPS WINDOW) ===
; Координаты для клика по городам в Favorite List
Global $g_iTeleport_X = 200  ; X координата (левее на 100px от центра)
Global $g_iTeleport_Y1 = 563 ; Первый город (Devias 3)
Global $g_iTeleport_Y2 = 581 ; Второй город (Atlans 3)
Global $g_iTeleport_Y3 = 599 ; Третий город (Karutan 2)
Global $g_iTeleport_Step = 18 ; Шаг между городами

; Координаты окна для продакшена (невидимый режим)
Global $g_iWindow_Prod_X = 1980
Global $g_iWindow_Prod_Y = 0

; === РЕЖИМ OCR ===
; True = читать город+координаты вместе (быстрее, один OCR)
; False = читать раздельно (точнее, два OCR)
Global $g_bUseFullOCR = False

; === ВАРИАНТ 1: Полный OCR (Город + Координаты вместе) ===
Global $g_iCityFull_X = 110
Global $g_iCityFull_Y = 36
Global $g_iCityFull_Width = 180
Global $g_iCityFull_Height = 26

; === ВАРИАНТ 2: Раздельный OCR ===
; Часть 1: Только город (Atlans)
Global $g_iCityOnly_X = 110
Global $g_iCityOnly_Y = 36
Global $g_iCityOnly_Width = 110
Global $g_iCityOnly_Height = 26

; Часть 2: Только координаты (198,66)
Global $g_iCoordsOnly_X = 220
Global $g_iCoordsOnly_Y = 36
Global $g_iCoordsOnly_Width = 70
Global $g_iCoordsOnly_Height = 26

; === ОБЩИЕ КООРДИНАТЫ ===
; Часть 3: Helper Bot (1 или 0) - координаты относительно обрезанной области!
Global $g_iHelper_X = 322
Global $g_iHelper_Y = 35
Global $g_iHelper_Width = 10
Global $g_iHelper_Height = 15


; --- Состояние записи маршрута ---
Global $g_bRecording = False
Global $g_aCurrentRoute = ""
Global $g_iWaypointsCount = 0

; --- Состояние автопилота ---
Global $g_bAutopilotRunning = False
Global $g_sCurrentRouteFile = ""
Global $g_iCurrentWaypoint = 0

; --- Настройки ---
Global $g_iMovementTimeout = 30        ; Таймаут ожидания движения (сек)
Global $g_iCoordsTolerance = 5         ; Допуск координат (пикселей)
Global $g_iObstacleOffset = 30         ; Смещение для обхода препятствий
Global $g_iMaxRetries = 3              ; Максимум попыток телепорта заново

; --- Путь к папке маршрутов ---
Global $g_sRoutesFolder = @ScriptDir & "\data\routes"





; === ИНИЦИАЛИЗАЦИЯ SDK ===
If Not _SDK_Init($g_sApp_AppName, True, 1, 3, True) Then Exit 1

_Logger_Write("========================================", 1)
_Logger_Write("MU Online Auto Reset Bot v1.0.0", 1)
_Logger_Write("========================================", 1)

; === ИНИЦИАЛИЗАЦИЯ ===
_Markers_Init()
_Routes_Init()
_Cities_Load()

; === ЗАПУСК GUI ===
_GUI_Create()

; === ИНИЦИАЛИЗАЦИЯ ТАЙМЕРОВ ===
$g_iAutopilot_LastProcessTime = TimerInit()
_Button_ReadWindows()
; === ОСНОВНОЙ ЦИКЛ ===
While 1
	Sleep(10)

	; Обработка выполнения маршрута
	If $g_bRouteExecuting Then
		_Routes_ExecuteRoute()
		$g_bRouteExecuting = False  ; Сбрасываем флаг после выполнения
	EndIf

	; Обработка автопилота (каждую секунду)
	If TimerDiff($g_iAutopilot_LastProcessTime) >= 1000 Then
		$g_iAutopilot_LastProcessTime = TimerInit()
		If $g_bAutopilotEnabled Then
			_Autopilot_Process()
		EndIf
	EndIf
WEnd

; ===============================================================================
; Функция: _GUI_Create
; Описание: Создание главного окна приложения
; ===============================================================================
Func _GUI_Create()
	_Logger_Write("Создание GUI...", 1)

	; Событийная модель
	Opt("GUIOnEventMode", 1)

	; Создание окна (увеличено для новых элементов)
	$g_hGUI = GUICreate("MU Online Auto Reset Bot v1.0", 1100, 850, -1, -1)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_GUI_OnExit")
	GUISetBkColor(0x1E1E2E)

	; === КНОПКИ УПРАВЛЕНИЯ (ЛЕВАЯ ПОЛОВИНА) ===
	Local $idLblCtrl = GUICtrlCreateLabel("🎮 Управление", 10, 5, 200, 20)
	GUICtrlSetFont($idLblCtrl, 10, 700)
	GUICtrlSetColor($idLblCtrl, 0x7AA2F7)
	GUICtrlSetBkColor($idLblCtrl, 0x1E1E2E)
	Local $idGroup_Ctrl = GUICtrlCreateGroup("", 5, 22, 1090, 85)
	GUICtrlSetBkColor($idGroup_Ctrl, 0x1E1E2E)
	GUICtrlSetColor($idGroup_Ctrl, 0x3A3A5C)

	; Первый ряд кнопок
	$g_idBtnReadWindows = GUICtrlCreateButton("Прочитать окна", 10, 35, 120, 30)
	GUICtrlSetOnEvent($g_idBtnReadWindows, "_Button_ReadWindows")
	GUICtrlSetFont($g_idBtnReadWindows, 9, 700)
	GUICtrlSetBkColor($g_idBtnReadWindows, 0x3A7BD5)
	GUICtrlSetColor($g_idBtnReadWindows, 0xFFFFFF)

	$g_idBtnParseData = GUICtrlCreateButton("Парсинг данных", 140, 35, 120, 30)
	GUICtrlSetOnEvent($g_idBtnParseData, "_Button_ParseData")
	GUICtrlSetFont($g_idBtnParseData, 9, 700)
	GUICtrlSetBkColor($g_idBtnParseData, 0x3A7BD5)
	GUICtrlSetColor($g_idBtnParseData, 0xFFFFFF)

	$g_idBtnScreenshot = GUICtrlCreateButton("Скриншот", 270, 35, 100, 30)
	GUICtrlSetOnEvent($g_idBtnScreenshot, "_Button_Screenshot")
	GUICtrlSetFont($g_idBtnScreenshot, 9, 700)
	GUICtrlSetBkColor($g_idBtnScreenshot, 0x2D5A8E)
	GUICtrlSetColor($g_idBtnScreenshot, 0xFFFFFF)

	$g_idBtnReset = GUICtrlCreateButton("Reset", 380, 35, 100, 30)
	GUICtrlSetOnEvent($g_idBtnReset, "_Button_Reset")
	GUICtrlSetFont($g_idBtnReset, 9, 700)
	GUICtrlSetBkColor($g_idBtnReset, 0xC0392B)
	GUICtrlSetColor($g_idBtnReset, 0xFFFFFF)

	; Второй ряд кнопок
	$g_idBtnTeleport = GUICtrlCreateButton("Телепорт", 10, 70, 100, 30)
	GUICtrlSetOnEvent($g_idBtnTeleport, "_Button_Teleport")
	GUICtrlSetFont($g_idBtnTeleport, 9, 700)
	GUICtrlSetBkColor($g_idBtnTeleport, 0x27AE60)
	GUICtrlSetColor($g_idBtnTeleport, 0xFFFFFF)

	$g_idBtnMoveWindow = GUICtrlCreateButton("Окно 0,0", 120, 70, 90, 30)
	GUICtrlSetOnEvent($g_idBtnMoveWindow, "_Button_MoveWindow")
	GUICtrlSetFont($g_idBtnMoveWindow, 9, 700)
	GUICtrlSetBkColor($g_idBtnMoveWindow, 0x2D5A8E)
	GUICtrlSetColor($g_idBtnMoveWindow, 0xFFFFFF)

	$g_idBtnMoveWindowProd = GUICtrlCreateButton("Окно Prod", 220, 70, 90, 30)
	GUICtrlSetOnEvent($g_idBtnMoveWindowProd, "_Button_MoveWindowProd")
	GUICtrlSetFont($g_idBtnMoveWindowProd, 9, 700)
	GUICtrlSetBkColor($g_idBtnMoveWindowProd, 0x8E44AD)
	GUICtrlSetColor($g_idBtnMoveWindowProd, 0xFFFFFF)

	$g_idBtnScanMarkers = GUICtrlCreateButton("Сканировать маяки", 320, 70, 160, 30)
	GUICtrlSetOnEvent($g_idBtnScanMarkers, "_Button_ScanMarkers")
	GUICtrlSetFont($g_idBtnScanMarkers, 9, 700)
	GUICtrlSetBkColor($g_idBtnScanMarkers, 0xD4AC0D)
	GUICtrlSetColor($g_idBtnScanMarkers, 0x1E1E2E)
	GUICtrlCreateGroup("", -99, -99, 1, 1) ; закрываем группу управления

	; === ГРУППА АВТОПИЛОТА (правая часть, Y=115..240) ===
	Local $idLblAP = GUICtrlCreateLabel("🤖 Автопилот", 560, 115, 200, 20)
	GUICtrlSetFont($idLblAP, 10, 700)
	GUICtrlSetColor($idLblAP, 0x7AA2F7)
	GUICtrlSetBkColor($idLblAP, 0x1E1E2E)
	Local $idGroup_AP = GUICtrlCreateGroup("", 555, 132, 535, 365)
	GUICtrlSetBkColor($idGroup_AP, 0x1E1E2E)
	GUICtrlSetColor($idGroup_AP, 0x3A3A5C)

	; Кнопки старт/стоп
	Global $g_idBtn_AutopilotStart = GUICtrlCreateButton("▶️ Запустить", 562, 145, 120, 30)
	GUICtrlSetOnEvent($g_idBtn_AutopilotStart, "_Button_AutopilotStart")
	GUICtrlSetFont($g_idBtn_AutopilotStart, 9, 700)
	GUICtrlSetBkColor($g_idBtn_AutopilotStart, 0x27AE60)
	GUICtrlSetColor($g_idBtn_AutopilotStart, 0xFFFFFF)

	Global $g_idBtn_AutopilotStop = GUICtrlCreateButton("⏹️ Остановить", 690, 145, 120, 30)
	GUICtrlSetOnEvent($g_idBtn_AutopilotStop, "_Button_AutopilotStop")
	GUICtrlSetFont($g_idBtn_AutopilotStop, 9, 700)
	GUICtrlSetBkColor($g_idBtn_AutopilotStop, 0xC0392B)
	GUICtrlSetColor($g_idBtn_AutopilotStop, 0xFFFFFF)
	GUICtrlSetState($g_idBtn_AutopilotStop, $GUI_DISABLE)

	; Статус автопилота
	Local $idLblStatusTitle = GUICtrlCreateLabel("Статус:", 820, 146, 55, 22)
	GUICtrlSetFont($idLblStatusTitle, 10, 700)
	GUICtrlSetColor($idLblStatusTitle, 0xFFD700)
	GUICtrlSetBkColor($idLblStatusTitle, 0x1E1E2E)
	Global $g_idLabel_AutopilotStatus = GUICtrlCreateLabel("Ожидание...", 878, 146, 205, 22)
	GUICtrlSetFont($g_idLabel_AutopilotStatus, 10, 700)
	GUICtrlSetColor($g_idLabel_AutopilotStatus, 0x00FF88)
	GUICtrlSetBkColor($g_idLabel_AutopilotStatus, 0x1E1E2E)

	; === Настройки — 2 строки × 2 колонки (checkbox + label + input) ===
	; Строка 1, Колонка 1: Авторесет
	Global $g_idCheck_AutoReset = GUICtrlCreateCheckbox("", 562, 190, 20, 20)
	GUICtrlSetState($g_idCheck_AutoReset, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_AutoReset, 0x1E1E2E)
	Local $idLbl_AR = GUICtrlCreateLabel("Авторесет уровень:", 585, 192, 120, 18)
	GUICtrlSetFont($idLbl_AR, 8, 700)
	GUICtrlSetColor($idLbl_AR, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_AR, 0x1E1E2E)
	Global $g_idInput_MinLevel = GUICtrlCreateInput("400", 710, 189, 112, 22)
	GUICtrlSetFont($g_idInput_MinLevel, 9, 400)
	GUICtrlSetBkColor($g_idInput_MinLevel, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_MinLevel, 0xFFD700)

	; Строка 1, Колонка 2: Рестарт маршрута
	Global $g_idCheck_RestartAfterReset = GUICtrlCreateCheckbox("", 829, 190, 20, 20)
	GUICtrlSetState($g_idCheck_RestartAfterReset, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_RestartAfterReset, 0x1E1E2E)
	Local $idLbl_RR = GUICtrlCreateLabel("Рестарт маршрута:", 852, 192, 120, 18)
	GUICtrlSetFont($idLbl_RR, 8, 700)
	GUICtrlSetColor($idLbl_RR, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_RR, 0x1E1E2E)
	Global $g_idInput_ResetWait = GUICtrlCreateInput("2", 977, 189, 100, 22)
	GUICtrlSetFont($g_idInput_ResetWait, 9, 400)
	GUICtrlSetBkColor($g_idInput_ResetWait, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_ResetWait, 0xFFD700)

	; Строка 2, Колонка 1: Корректировка позиции
	Global $g_idCheck_PositionCorrection = GUICtrlCreateCheckbox("", 562, 225, 20, 20)
	GUICtrlSetState($g_idCheck_PositionCorrection, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_PositionCorrection, 0x1E1E2E)
	Local $idLbl_PC = GUICtrlCreateLabel("Корректировка (сек):", 585, 227, 120, 18)
	GUICtrlSetFont($idLbl_PC, 8, 700)
	GUICtrlSetColor($idLbl_PC, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_PC, 0x1E1E2E)
	Global $g_idInput_CorrInterval = GUICtrlCreateInput("5", 710, 224, 112, 22)
	GUICtrlSetFont($g_idInput_CorrInterval, 9, 400)
	GUICtrlSetBkColor($g_idInput_CorrInterval, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_CorrInterval, 0xFFD700)

	; Строка 2, Колонка 2: Автовозврат
	Global $g_idCheck_AutoReturn = GUICtrlCreateCheckbox("", 829, 225, 20, 20)
	GUICtrlSetState($g_idCheck_AutoReturn, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_AutoReturn, 0x1E1E2E)
	Local $idLbl_AV = GUICtrlCreateLabel("Автовозврат допуск:", 852, 227, 120, 18)
	GUICtrlSetFont($idLbl_AV, 8, 700)
	GUICtrlSetColor($idLbl_AV, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_AV, 0x1E1E2E)
	Global $g_idInput_ReturnTolerance = GUICtrlCreateInput("15", 977, 224, 100, 22)
	GUICtrlSetFont($g_idInput_ReturnTolerance, 9, 400)
	GUICtrlSetBkColor($g_idInput_ReturnTolerance, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_ReturnTolerance, 0xFFD700)

	; Строка 3 — разделитель + место для следующих 4 конструкций
	Local $idLblSettings2 = GUICtrlCreateLabel("─────────────────────────────────────────────────────────────────", 562, 255, 520, 12)
	GUICtrlSetFont($idLblSettings2, 6, 400)
	GUICtrlSetColor($idLblSettings2, 0x3A3A5C)
	GUICtrlSetBkColor($idLblSettings2, 0x1E1E2E)

	; (место для 4 дополнительных конструкций — строки Y=270 и Y=300)

	; Строка 3, Колонка 1: Допуск корректировки
	Local $idLbl_CT = GUICtrlCreateLabel("Допуск корректировки:", 562, 272, 148, 18)
	GUICtrlSetFont($idLbl_CT, 8, 700)
	GUICtrlSetColor($idLbl_CT, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_CT, 0x1E1E2E)
	Global $g_idInput_CorrTolerance = GUICtrlCreateInput("5", 715, 269, 107, 22)
	GUICtrlSetFont($g_idInput_CorrTolerance, 9, 400)
	GUICtrlSetBkColor($g_idInput_CorrTolerance, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_CorrTolerance, 0xFFD700)

	; Строка 3, Колонка 2: Макс. попыток маршрута
	Local $idLbl_MF = GUICtrlCreateLabel("Макс. попыток маршрута:", 829, 272, 148, 18)
	GUICtrlSetFont($idLbl_MF, 8, 700)
	GUICtrlSetColor($idLbl_MF, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_MF, 0x1E1E2E)
	Global $g_idInput_MaxRouteFails = GUICtrlCreateInput("5", 982, 269, 95, 22)
	GUICtrlSetFont($g_idInput_MaxRouteFails, 9, 400)
	GUICtrlSetBkColor($g_idInput_MaxRouteFails, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_MaxRouteFails, 0xFFD700)

	; Строка 4, Колонка 1: Кликов за цикл
	Local $idLbl_CC = GUICtrlCreateLabel("Кликов за цикл движения:", 562, 302, 148, 18)
	GUICtrlSetFont($idLbl_CC, 8, 700)
	GUICtrlSetColor($idLbl_CC, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_CC, 0x1E1E2E)
	Global $g_idInput_ClicksPerCycle = GUICtrlCreateInput("2", 715, 299, 107, 22)
	GUICtrlSetFont($g_idInput_ClicksPerCycle, 9, 400)
	GUICtrlSetBkColor($g_idInput_ClicksPerCycle, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_ClicksPerCycle, 0xFFD700)

	; Строка 4, Колонка 2: Таймаут точки
	Local $idLbl_MT = GUICtrlCreateLabel("Таймаут точки (сек):", 829, 302, 148, 18)
	GUICtrlSetFont($idLbl_MT, 8, 700)
	GUICtrlSetColor($idLbl_MT, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_MT, 0x1E1E2E)
	Global $g_idInput_MoveTimeout = GUICtrlCreateInput("30", 982, 299, 95, 22)
	GUICtrlSetFont($g_idInput_MoveTimeout, 9, 400)
	GUICtrlSetBkColor($g_idInput_MoveTimeout, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_MoveTimeout, 0xFFD700)

	; Строка 5: Ник персонажа + чекбокс авто-статов
	Local $idLbl_Nick = GUICtrlCreateLabel("Ник:", 562, 338, 30, 18)
	GUICtrlSetFont($idLbl_Nick, 8, 700)
	GUICtrlSetColor($idLbl_Nick, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_Nick, 0x1E1E2E)
	Global $g_idInput_CharName = GUICtrlCreateInput("NanoElf", 595, 335, 200, 22)
	GUICtrlSetFont($g_idInput_CharName, 9, 400)
	GUICtrlSetBkColor($g_idInput_CharName, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_CharName, 0xE0E0FF)

	Global $g_idCheck_AutoStats = GUICtrlCreateCheckbox("", 808, 335, 20, 20)
	GUICtrlSetState($g_idCheck_AutoStats, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_AutoStats, 0x1E1E2E)
	Local $idLbl_AS = GUICtrlCreateLabel("Авто-распределение статов", 831, 338, 240, 18)
	GUICtrlSetFont($idLbl_AS, 8, 700)
	GUICtrlSetColor($idLbl_AS, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_AS, 0x1E1E2E)

	; Строка 6: 5 input статов STR / AGI / VIT / ENE / CMD
	Local $idLbl_STR = GUICtrlCreateLabel("STR", 562, 368, 30, 16)
	GUICtrlSetFont($idLbl_STR, 7, 700)
	GUICtrlSetColor($idLbl_STR, 0xAAAAAA)
	GUICtrlSetBkColor($idLbl_STR, 0x1E1E2E)
	Global $g_idInput_STR = GUICtrlCreateInput("300", 562, 382, 88, 22)
	GUICtrlSetFont($g_idInput_STR, 9, 400)
	GUICtrlSetBkColor($g_idInput_STR, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_STR, 0xFFD700)

	Local $idLbl_AGI = GUICtrlCreateLabel("AGI", 658, 368, 30, 16)
	GUICtrlSetFont($idLbl_AGI, 7, 700)
	GUICtrlSetColor($idLbl_AGI, 0xAAAAAA)
	GUICtrlSetBkColor($idLbl_AGI, 0x1E1E2E)
	Global $g_idInput_AGI = GUICtrlCreateInput("25000", 658, 382, 88, 22)
	GUICtrlSetFont($g_idInput_AGI, 9, 400)
	GUICtrlSetBkColor($g_idInput_AGI, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_AGI, 0xFFD700)

	Local $idLbl_VIT = GUICtrlCreateLabel("VIT", 754, 368, 30, 16)
	GUICtrlSetFont($idLbl_VIT, 7, 700)
	GUICtrlSetColor($idLbl_VIT, 0xAAAAAA)
	GUICtrlSetBkColor($idLbl_VIT, 0x1E1E2E)
	Global $g_idInput_VIT = GUICtrlCreateInput("1000", 754, 382, 88, 22)
	GUICtrlSetFont($g_idInput_VIT, 9, 400)
	GUICtrlSetBkColor($g_idInput_VIT, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_VIT, 0xFFD700)

	Local $idLbl_ENE = GUICtrlCreateLabel("ENE", 850, 368, 30, 16)
	GUICtrlSetFont($idLbl_ENE, 7, 700)
	GUICtrlSetColor($idLbl_ENE, 0xAAAAAA)
	GUICtrlSetBkColor($idLbl_ENE, 0x1E1E2E)
	Global $g_idInput_ENE = GUICtrlCreateInput("5000", 850, 382, 88, 22)
	GUICtrlSetFont($g_idInput_ENE, 9, 400)
	GUICtrlSetBkColor($g_idInput_ENE, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_ENE, 0xFFD700)

	Local $idLbl_CMD = GUICtrlCreateLabel("CMD", 946, 368, 30, 16)
	GUICtrlSetFont($idLbl_CMD, 7, 700)
	GUICtrlSetColor($idLbl_CMD, 0xAAAAAA)
	GUICtrlSetBkColor($idLbl_CMD, 0x1E1E2E)
	Global $g_idInput_CMD = GUICtrlCreateInput("0", 946, 382, 88, 22)
	GUICtrlSetFont($g_idInput_CMD, 9, 400)
	GUICtrlSetBkColor($g_idInput_CMD, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_CMD, 0xFFD700)

	; Строка 7: Множитель дистанции клика
	Local $idLbl_DM = GUICtrlCreateLabel("📏 Множитель дистанции клика:", 562, 415, 210, 18)
	GUICtrlSetFont($idLbl_DM, 8, 700)
	GUICtrlSetColor($idLbl_DM, 0x7AA2F7)
	GUICtrlSetBkColor($idLbl_DM, 0x1E1E2E)
	Global $g_idInput_DistMult_AP = GUICtrlCreateInput("1.0", 778, 412, 100, 22)
	GUICtrlSetFont($g_idInput_DistMult_AP, 9, 400)
	GUICtrlSetBkColor($g_idInput_DistMult_AP, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_DistMult_AP, 0xFFD700)

	GUICtrlCreateGroup("", -99, -99, 1, 1) ; закрываем группу автопилота

	; === ВЫБОР ОКНА MU ONLINE ===
	Local $idLblWin = GUICtrlCreateLabel("🎮 Окно MU Online", 10, 115, 200, 20)
	GUICtrlSetFont($idLblWin, 10, 700)
	GUICtrlSetColor($idLblWin, 0x7AA2F7)
	GUICtrlSetBkColor($idLblWin, 0x1E1E2E)
	Local $idGroup_Win = GUICtrlCreateGroup("", 5, 132, 545, 95)
	GUICtrlSetBkColor($idGroup_Win, 0x1E1E2E)
	GUICtrlSetColor($idGroup_Win, 0x3A3A5C)

	$g_idCombo_Windows = GUICtrlCreateCombo("", 12, 142, 530, 25, 0x0003)
	GUICtrlSetFont($g_idCombo_Windows, 10, 700)
	GUICtrlSetBkColor($g_idCombo_Windows, 0x2D2D3F)
	GUICtrlSetColor($g_idCombo_Windows, 0xE0E0FF)
	GUICtrlSetOnEvent($g_idCombo_Windows, "_Combo_WindowSelect_Changed")

	; Данные персонажа — 2 ряда по 2 значения
	Global $g_idLabel_WinNick        = GUICtrlCreateLabel("👤 Ник: —",      12,  172, 260, 20)
	Global $g_idLabel_WinLevel       = GUICtrlCreateLabel("📊 Уровень: —",  280, 172, 260, 20)
	Global $g_idLabel_WinMasterLevel = GUICtrlCreateLabel("🏆 Мастер: —",   12,  193, 260, 20)
	Global $g_idLabel_WinResets      = GUICtrlCreateLabel("🔄 Ресеты: —",   280, 193, 260, 20)

	GUICtrlSetFont($g_idLabel_WinNick, 9, 700)
	GUICtrlSetColor($g_idLabel_WinNick, 0x00FF88)
	GUICtrlSetBkColor($g_idLabel_WinNick, 0x1E1E2E)
	GUICtrlSetFont($g_idLabel_WinLevel, 9, 700)
	GUICtrlSetColor($g_idLabel_WinLevel, 0x00FF88)
	GUICtrlSetBkColor($g_idLabel_WinLevel, 0x1E1E2E)
	GUICtrlSetFont($g_idLabel_WinMasterLevel, 9, 700)
	GUICtrlSetColor($g_idLabel_WinMasterLevel, 0x00FF88)
	GUICtrlSetBkColor($g_idLabel_WinMasterLevel, 0x1E1E2E)
	GUICtrlSetFont($g_idLabel_WinResets, 9, 700)
	GUICtrlSetColor($g_idLabel_WinResets, 0x00FF88)
	GUICtrlSetBkColor($g_idLabel_WinResets, 0x1E1E2E)

	GUICtrlCreateGroup("", -99, -99, 1, 1) ; закрываем группу

	; === МАРШРУТЫ (единый блок) ===
	Local $idLblRoutes = GUICtrlCreateLabel("�️ Маршруты", 10, 240, 200, 20)
	GUICtrlSetFont($idLblRoutes, 10, 700)
	GUICtrlSetColor($idLblRoutes, 0x7AA2F7)
	GUICtrlSetBkColor($idLblRoutes, 0x1E1E2E)
	Local $idGroup_Routes = GUICtrlCreateGroup("", 5, 257, 545, 345)
	GUICtrlSetBkColor($idGroup_Routes, 0x1E1E2E)
	GUICtrlSetColor($idGroup_Routes, 0x3A3A5C)

	; --- Запись маршрута ---
	Local $idLblRecord = GUICtrlCreateLabel("📝 Запись маршрута:", 12, 265, 160, 20)
	GUICtrlSetFont($idLblRecord, 9, 700)
	GUICtrlSetColor($idLblRecord, 0xE0E0FF)
	GUICtrlSetBkColor($idLblRecord, 0x1E1E2E)

	; Выбор города
	Local $idLblCity = GUICtrlCreateLabel("Город:", 12, 290, 50, 20)
	GUICtrlSetFont($idLblCity, 9, 700)
	GUICtrlSetColor($idLblCity, 0x7AA2F7)
	GUICtrlSetBkColor($idLblCity, 0x1E1E2E)
	Global $g_idCombo_City = GUICtrlCreateCombo("", 65, 287, 150, 25, 0x0003)
	GUICtrlSetFont($g_idCombo_City, 9, 700)
	GUICtrlSetBkColor($g_idCombo_City, 0x2D2D3F)
	GUICtrlSetColor($g_idCombo_City, 0xE0E0FF)

	; Загружаем города из конфига
	If IsArray($g_aCities) And UBound($g_aCities) > 0 Then
		Local $sCitiesList = ""
		Local $sLastCity = _Config_LoadLastCity()
		Local $sDefaultCity = ""

		For $i = 0 To UBound($g_aCities) - 1
			Local $oCity = $g_aCities[$i]
			Local $sCityName = $oCity["name"]
			Local $iCityY = $oCity["y"]

			If $i > 0 Then $sCitiesList &= "|"
			$sCitiesList &= $sCityName & " (" & $iCityY & ")"

			; Устанавливаем город по умолчанию
			If $sCityName = $sLastCity Then
				$sDefaultCity = $sCityName & " (" & $iCityY & ")"
			EndIf
		Next

		; Если не нашли последний город, берём первый
		If $sDefaultCity = "" Then
			$sDefaultCity = $g_aCities[0]["name"] & " (" & $g_aCities[0]["y"] & ")"
		EndIf

		GUICtrlSetData($g_idCombo_City, $sCitiesList, $sDefaultCity)
	Else
		; Fallback на статические значения если конфиг не загрузился
		GUICtrlSetData($g_idCombo_City, "Devias (533)|Lorencia (551)|Noria (569)", "Devias (533)")
	EndIf

	; Имя маршрута
	Local $idLblName = GUICtrlCreateLabel("Имя:", 225, 290, 35, 20)
	GUICtrlSetFont($idLblName, 9, 700)
	GUICtrlSetColor($idLblName, 0x7AA2F7)
	GUICtrlSetBkColor($idLblName, 0x1E1E2E)
	Global $g_idInput_RouteName = GUICtrlCreateInput("", 262, 287, 190, 25)
	GUICtrlSetFont($g_idInput_RouteName, 9, 400)
	GUICtrlSetBkColor($g_idInput_RouteName, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_RouteName, 0xE0E0FF)

	; Счётчик точек (справа от поля Имя)
	Global $g_idLabel_PointsCount = GUICtrlCreateLabel("Точек: 0", 460, 290, 85, 20)
	GUICtrlSetFont($g_idLabel_PointsCount, 9, 700)
	GUICtrlSetColor($g_idLabel_PointsCount, 0xFFD700)
	GUICtrlSetBkColor($g_idLabel_PointsCount, 0x1E1E2E)

	; Кнопки управления записью
	Global $g_idBtn_StartRecord = GUICtrlCreateButton("🔴 Начать запись", 12, 320, 130, 28)
	GUICtrlSetOnEvent($g_idBtn_StartRecord, "_Button_StartRecord")
	GUICtrlSetFont($g_idBtn_StartRecord, 9, 700)
	GUICtrlSetBkColor($g_idBtn_StartRecord, 0xC0392B)
	GUICtrlSetColor($g_idBtn_StartRecord, 0xFFFFFF)

	Global $g_idBtn_AddPoint = GUICtrlCreateButton("➕ Добавить точку", 148, 320, 130, 28)
	GUICtrlSetOnEvent($g_idBtn_AddPoint, "_Button_AddPoint")
	GUICtrlSetFont($g_idBtn_AddPoint, 9, 700)
	GUICtrlSetBkColor($g_idBtn_AddPoint, 0x27AE60)
	GUICtrlSetColor($g_idBtn_AddPoint, 0xFFFFFF)
	GUICtrlSetState($g_idBtn_AddPoint, $GUI_DISABLE)

	Global $g_idBtn_SaveRoute = GUICtrlCreateButton("💾 Сохранить", 284, 320, 130, 28)
	GUICtrlSetOnEvent($g_idBtn_SaveRoute, "_Button_SaveRoute")
	GUICtrlSetFont($g_idBtn_SaveRoute, 9, 700)
	GUICtrlSetBkColor($g_idBtn_SaveRoute, 0x3A7BD5)
	GUICtrlSetColor($g_idBtn_SaveRoute, 0xFFFFFF)
	GUICtrlSetState($g_idBtn_SaveRoute, $GUI_DISABLE)

	Global $g_idBtn_CancelRecord = GUICtrlCreateButton("❌ Отменить", 420, 320, 120, 28)
	GUICtrlSetOnEvent($g_idBtn_CancelRecord, "_Button_CancelRecord")
	GUICtrlSetFont($g_idBtn_CancelRecord, 9, 700)
	GUICtrlSetBkColor($g_idBtn_CancelRecord, 0x555577)
	GUICtrlSetColor($g_idBtn_CancelRecord, 0xFFFFFF)
	GUICtrlSetState($g_idBtn_CancelRecord, $GUI_DISABLE)

	; --- Выполнение маршрута ---
	Local $idLblExec = GUICtrlCreateLabel("🚀 Выполнение маршрута:", 12, 362, 200, 20)
	GUICtrlSetFont($idLblExec, 9, 700)
	GUICtrlSetColor($idLblExec, 0xE0E0FF)
	GUICtrlSetBkColor($idLblExec, 0x1E1E2E)

	; Dropdown выбора маршрута
	Global $g_idCombo_RouteSelect = GUICtrlCreateCombo("", 12, 385, 280, 25, 0x0003)
	GUICtrlSetFont($g_idCombo_RouteSelect, 9, 700)
	GUICtrlSetBkColor($g_idCombo_RouteSelect, 0x2D2D3F)
	GUICtrlSetColor($g_idCombo_RouteSelect, 0xE0E0FF)
	GUICtrlSetOnEvent($g_idCombo_RouteSelect, "_Combo_RouteSelect_Changed")

	; Кнопки управления маршрутом
	Global $g_idBtn_RefreshRoutes = GUICtrlCreateButton("🔄", 300, 385, 30, 25)
	GUICtrlSetOnEvent($g_idBtn_RefreshRoutes, "_Button_RefreshRoutes")
	GUICtrlSetFont($g_idBtn_RefreshRoutes, 9, 700)
	GUICtrlSetBkColor($g_idBtn_RefreshRoutes, 0x2D5A8E)
	GUICtrlSetColor($g_idBtn_RefreshRoutes, 0xFFFFFF)

	Global $g_idBtn_ExecuteRoute = GUICtrlCreateButton("▶️ Перейти", 338, 385, 100, 25)
	GUICtrlSetOnEvent($g_idBtn_ExecuteRoute, "_Button_ExecuteRoute")
	GUICtrlSetFont($g_idBtn_ExecuteRoute, 9, 700)
	GUICtrlSetBkColor($g_idBtn_ExecuteRoute, 0x27AE60)
	GUICtrlSetColor($g_idBtn_ExecuteRoute, 0xFFFFFF)

	Global $g_idBtn_StopRoute = GUICtrlCreateButton("⏹️ Прервать", 446, 385, 94, 25)
	GUICtrlSetOnEvent($g_idBtn_StopRoute, "_Button_StopRoute")
	GUICtrlSetFont($g_idBtn_StopRoute, 9, 700)
	GUICtrlSetBkColor($g_idBtn_StopRoute, 0xC0392B)
	GUICtrlSetColor($g_idBtn_StopRoute, 0xFFFFFF)
	GUICtrlSetState($g_idBtn_StopRoute, $GUI_DISABLE)

	; Чекбокс Helper
	Global $g_idCheck_HelperOnStart = GUICtrlCreateCheckbox("", 12, 422, 20, 20)
	GUICtrlSetState($g_idCheck_HelperOnStart, $GUI_CHECKED)
	GUICtrlSetBkColor($g_idCheck_HelperOnStart, 0x1E1E2E)
	Local $idLblHelper = GUICtrlCreateLabel("⚡ Включить Helper на старте маршрута", 35, 422, 300, 20)
	GUICtrlSetFont($idLblHelper, 9, 700)
	GUICtrlSetColor($idLblHelper, 0xD4AC0D)
	GUICtrlSetBkColor($idLblHelper, 0x1E1E2E)

	; --- Кнопки теста навигации (под чекбоксом, левая половина группы) ---
	Global $g_idBtn_MoveXPlus = GUICtrlCreateButton("➡️ X+", 12, 450, 60, 28)
	GUICtrlSetOnEvent($g_idBtn_MoveXPlus, "_Button_MoveXPlus")
	GUICtrlSetFont($g_idBtn_MoveXPlus, 9, 700)
	GUICtrlSetBkColor($g_idBtn_MoveXPlus, 0x2D5A8E)
	GUICtrlSetColor($g_idBtn_MoveXPlus, 0xFFFFFF)

	Global $g_idBtn_MoveXMinus = GUICtrlCreateButton("⬅️ X-", 77, 450, 60, 28)
	GUICtrlSetOnEvent($g_idBtn_MoveXMinus, "_Button_MoveXMinus")
	GUICtrlSetFont($g_idBtn_MoveXMinus, 9, 700)
	GUICtrlSetBkColor($g_idBtn_MoveXMinus, 0x2D5A8E)
	GUICtrlSetColor($g_idBtn_MoveXMinus, 0xFFFFFF)

	Global $g_idBtn_MoveYPlus = GUICtrlCreateButton("⬆️ Y+", 142, 450, 60, 28)
	GUICtrlSetOnEvent($g_idBtn_MoveYPlus, "_Button_MoveYPlus")
	GUICtrlSetFont($g_idBtn_MoveYPlus, 9, 700)
	GUICtrlSetBkColor($g_idBtn_MoveYPlus, 0x2D5A8E)
	GUICtrlSetColor($g_idBtn_MoveYPlus, 0xFFFFFF)

	Global $g_idBtn_MoveYMinus = GUICtrlCreateButton("⬇️ Y-", 207, 450, 60, 28)
	GUICtrlSetOnEvent($g_idBtn_MoveYMinus, "_Button_MoveYMinus")
	GUICtrlSetFont($g_idBtn_MoveYMinus, 9, 700)
	GUICtrlSetBkColor($g_idBtn_MoveYMinus, 0x2D5A8E)
	GUICtrlSetColor($g_idBtn_MoveYMinus, 0xFFFFFF)

	; --- Навигация по углу 360° ---
	Local $idLblAngle = GUICtrlCreateLabel("Угол°:", 12, 488, 42, 18)
	GUICtrlSetFont($idLblAngle, 8, 700)
	GUICtrlSetColor($idLblAngle, 0x7AA2F7)
	GUICtrlSetBkColor($idLblAngle, 0x1E1E2E)
	Global $g_idInput_MoveAngle = GUICtrlCreateInput("0", 57, 485, 55, 22)
	GUICtrlSetFont($g_idInput_MoveAngle, 9, 400)
	GUICtrlSetBkColor($g_idInput_MoveAngle, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_MoveAngle, 0xFFD700)

	Local $idLblMult = GUICtrlCreateLabel("×Dist:", 118, 488, 40, 18)
	GUICtrlSetFont($idLblMult, 8, 700)
	GUICtrlSetColor($idLblMult, 0x7AA2F7)
	GUICtrlSetBkColor($idLblMult, 0x1E1E2E)
	Global $g_idInput_DistMult = GUICtrlCreateInput("1.0", 161, 485, 50, 22)
	GUICtrlSetFont($g_idInput_DistMult, 9, 400)
	GUICtrlSetBkColor($g_idInput_DistMult, 0x2D2D3F)
	GUICtrlSetColor($g_idInput_DistMult, 0xFFD700)

	Global $g_idBtn_MoveByAngle = GUICtrlCreateButton("🧭 По углу", 217, 484, 90, 28)
	GUICtrlSetOnEvent($g_idBtn_MoveByAngle, "_Button_MoveByAngle")
	GUICtrlSetFont($g_idBtn_MoveByAngle, 9, 700)
	GUICtrlSetBkColor($g_idBtn_MoveByAngle, 0x8E44AD)
	GUICtrlSetColor($g_idBtn_MoveByAngle, 0xFFFFFF)

	GUICtrlCreateGroup("", -99, -99, 1, 1) ; закрываем группу маршрутов

	; === ГРУППА СТАТИСТИКИ ===
	Local $idLblStatGroup = GUICtrlCreateLabel("📊 Статистика", 560, 475, 200, 20)
	GUICtrlSetFont($idLblStatGroup, 10, 700)
	GUICtrlSetColor($idLblStatGroup, 0x7AA2F7)
	GUICtrlSetBkColor($idLblStatGroup, 0x1E1E2E)
	Local $idGroup_Stat = GUICtrlCreateGroup("", 555, 492, 535, 150)
	GUICtrlSetBkColor($idGroup_Stat, 0x1E1E2E)
	GUICtrlSetColor($idGroup_Stat, 0x3A3A5C)

	Global $g_idLabel_CurrentLevel = GUICtrlCreateLabel("Текущий уровень: 0", 562, 505, 250, 20)
	GUICtrlSetFont($g_idLabel_CurrentLevel, 9, 700)
	GUICtrlSetColor($g_idLabel_CurrentLevel, 0xFFD700)
	GUICtrlSetBkColor($g_idLabel_CurrentLevel, 0x1E1E2E)

	Global $g_idLabel_ResetCount = GUICtrlCreateLabel("Ресетов: 0", 562, 530, 250, 20)
	GUICtrlSetFont($g_idLabel_ResetCount, 9, 700)
	GUICtrlSetColor($g_idLabel_ResetCount, 0xFFD700)
	GUICtrlSetBkColor($g_idLabel_ResetCount, 0x1E1E2E)

	Global $g_idLabel_LevelPerMin = GUICtrlCreateLabel("Уровней/мин: 0.0", 562, 555, 250, 20)
	GUICtrlSetFont($g_idLabel_LevelPerMin, 9, 700)
	GUICtrlSetColor($g_idLabel_LevelPerMin, 0xFFD700)
	GUICtrlSetBkColor($g_idLabel_LevelPerMin, 0x1E1E2E)

	GUICtrlCreateGroup("", -99, -99, 1, 1) ; закрываем группу статистики

	; === ЛОГ ===
	Local $idLblLog = GUICtrlCreateLabel("📋 Лог работы:", 10, 575, 150, 20)
	GUICtrlSetFont($idLblLog, 10, 700)
	GUICtrlSetColor($idLblLog, 0x7AA2F7)
	GUICtrlSetBkColor($idLblLog, 0x1E1E2E)
	$g_idEdit_Log = GUICtrlCreateEdit("", 10, 595, 1080, 245, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL))
	GUICtrlSetFont($g_idEdit_Log, 10, 400, 0, "Consolas")
	GUICtrlSetBkColor($g_idEdit_Log, 0x0D0D1A)
	GUICtrlSetColor($g_idEdit_Log, 0x00E5FF)

	GUISetState(@SW_SHOW, $g_hGUI)
	_Logger_Write("GUI создан успешно", 3)
	_GUI_AddLog("Приложение запущено. Нажмите 'Прочитать окна' для поиска MU Online.")

	; Загружаем список маршрутов
	_Button_RefreshRoutes()
EndFunc

; ===============================================================================
; Функция: _GUI_OnExit
; Описание: Обработчик закрытия приложения
; ===============================================================================
Func _GUI_OnExit()
	_Logger_Write("Закрытие приложения...", 1)
	Exit
EndFunc

; ===============================================================================
; Функция: _Button_ReadWindows
; Описание: Поиск всех окон main.exe и парсинг уровня из title
; ===============================================================================
Func _Button_ReadWindows()
	_Logger_Write("Поиск окон main.exe...", 1)
	_GUI_AddLog("Начинаю поиск окон MU Online...")

	; Сброс
	GUICtrlSetData($g_idCombo_Windows, "")
	$g_iFoundWindowsCount = 0
	ReDim $g_aFoundWindows[1][3]

	; Получение списка всех окон и процессов
	Local $aWinList   = WinList()
	Local $aProcesses = ProcessList()
	Local $iFound     = 0
	Local $sComboList = ""
	Local $iAutoIndex = -1   ; индекс окна с нужным ником

	For $i = 1 To $aWinList[0][0]
		Local $hWnd   = $aWinList[$i][1]
		Local $sTitle = $aWinList[$i][0]

		; Только видимые окна
		If Not BitAND(WinGetState($hWnd), 2) Then ContinueLoop

		; Имя процесса
		Local $iPID  = WinGetProcess($hWnd)
		Local $sProc = ""
		For $j = 1 To $aProcesses[0][0]
			If $aProcesses[$j][1] = $iPID Then
				$sProc = $aProcesses[$j][0]
				ExitLoop
			EndIf
		Next

		If StringLower($sProc) <> "main.exe" Then ContinueLoop

		; Парсим display-строку из title
		Local $aName = StringRegExp($sTitle, "(?i)Name\s*:\s*\[([^\]]+)\]", 3)
		Local $sDisplay = ""
		If Not @error And UBound($aName) > 0 Then
			Local $aLv = StringRegExp($sTitle, "(?i)(?<![Mm]aster\s)Level\s*:\s*\[(\d+)\]", 3)
			Local $aMR = StringRegExp($sTitle, "(?i)Master\s+Level\s*:\s*\[(\d+)\]", 3)
			Local $aR  = StringRegExp($sTitle, "(?i)Resets\s*:\s*\[(\d+)\]", 3)
			$sDisplay = "[" & $aName[0] & "] Lv" & (UBound($aLv) > 0 ? $aLv[0] : "?") & _
			            " MR" & (UBound($aMR) > 0 ? $aMR[0] : "?") & _
			            " R"  & (UBound($aR)  > 0 ? $aR[0]  : "?")

			; Проверяем совпадение с целевым ником
			If $iAutoIndex = -1 And StringInStr($sTitle, $g_sTargetCharacterName) > 0 Then
				$iAutoIndex = $iFound
			EndIf
		Else
			$sDisplay = StringFormat("HWND:0x%08X PID:%d", $hWnd, $iPID)
		EndIf

		; Сохраняем в массив
		$iFound += 1
		ReDim $g_aFoundWindows[$iFound + 1][3]
		$g_aFoundWindows[$iFound][0] = $hWnd
		$g_aFoundWindows[$iFound][1] = $iPID
		$g_aFoundWindows[$iFound][2] = $sDisplay

		If $iFound > 1 Then $sComboList &= "|"
		$sComboList &= $sDisplay

		_Logger_Write("Найдено окно: " & $sDisplay, 1)
	Next

	$g_aFoundWindows[0][0] = $iFound
	$g_iFoundWindowsCount  = $iFound

	If $iFound = 0 Then
		_Logger_Write("Окна main.exe не найдены", 2)
		_GUI_AddLog("⚠️ Окна MU Online не найдены! Запустите игру.")
		GUICtrlSetData($g_idCombo_Windows, "— нет окон —", "— нет окон —")
		Return
	EndIf

	; Заполняем dropdown
	Local $sDefault = $g_aFoundWindows[1][2]
	If $iAutoIndex >= 0 Then
		$sDefault = $g_aFoundWindows[$iAutoIndex + 1][2]
	EndIf
	GUICtrlSetData($g_idCombo_Windows, $sComboList, $sDefault)

	_Logger_Write("Найдено окон: " & $iFound & ", выбрано: " & $sDefault, 3)
	_GUI_AddLog("✅ Найдено окон MU Online: " & $iFound)
	_GUI_AddLog("   Выбрано: " & $sDefault)

	; Устанавливаем $g_hTargetWindow и запускаем парсинг
	Local $iSelIdx = ($iAutoIndex >= 0) ? ($iAutoIndex + 1) : 1
	$g_hTargetWindow = $g_aFoundWindows[$iSelIdx][0]
	_Button_ParseData()
EndFunc

; ===============================================================================
; Функция: _Button_ParseData
; Описание: Парсинг данных из выбранного окна (координаты, карта)
; ===============================================================================
Func _Button_ParseData()
	_Logger_Write("Парсинг данных из окна...", 1)

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Нет выбранного окна для парсинга", 2)
		_GUI_AddLog("⚠️ Сначала нажмите 'Прочитать окна'")
		Return
	EndIf

	; Читаем свежие данные через _ParseWindowData
	Local $oData = _ParseWindowData()

	If $oData["has_char"] Then
		; Обновляем labels персонажа
		GUICtrlSetData($g_idLabel_WinNick,        "👤 Ник: "     & $oData["nick"])
		GUICtrlSetData($g_idLabel_WinLevel,       "📊 Уровень: " & $oData["level"])
		GUICtrlSetData($g_idLabel_WinMasterLevel, "🏆 Мастер: "  & $oData["master_level"])
		GUICtrlSetData($g_idLabel_WinResets,      "🔄 Ресеты: "  & $oData["resets"])

		_Logger_Write("Парсинг: " & $oData["display"], 3)
		_GUI_AddLog("✅ " & $oData["display"])
	Else
		; Нет персонажа — показываем HWND/PID
		GUICtrlSetData($g_idLabel_WinNick,        "👤 Ник: —")
		GUICtrlSetData($g_idLabel_WinLevel,       "📊 Уровень: —")
		GUICtrlSetData($g_idLabel_WinMasterLevel, "🏆 Мастер: —")
		GUICtrlSetData($g_idLabel_WinResets,      "🔄 Ресеты: —")

		_Logger_Write("Парсинг: персонаж не найден, " & $oData["display"], 2)
		_GUI_AddLog("⚠️ Персонаж не найден: " & $oData["display"])
	EndIf
EndFunc

; ===============================================================================
; Функция: _Combo_WindowSelect_Changed
; ===============================================================================
; ===============================================================================
; Функция: _Combo_WindowSelect_Changed
; Описание: Обработчик смены выбора в dropdown окон MU Online
;           Обновляет $g_hTargetWindow и запускает парсинг данных
; ===============================================================================
Func _Combo_WindowSelect_Changed()
	Local $sSelected = GUICtrlRead($g_idCombo_Windows)
	If $sSelected = "" Or $sSelected = "— нет окон —" Then Return

	; Ищем HWND по display-строке в массиве
	For $i = 1 To $g_iFoundWindowsCount
		If $g_aFoundWindows[$i][2] = $sSelected Then
			$g_hTargetWindow = $g_aFoundWindows[$i][0]
			_Logger_Write("Выбрано окно: " & $sSelected & " HWND=" & $g_hTargetWindow, 3)
			_GUI_AddLog("🎮 Выбрано окно: " & $sSelected)
			_Button_ParseData()
			Return
		EndIf
	Next

	_Logger_Write("Окно не найдено в массиве: " & $sSelected, 2)
EndFunc


; ===============================================================================
; Функция: _Button_Screenshot
; Описание: Фоновый скриншот окна через PrintWindow + OCR
; ===============================================================================
Func _Button_Screenshot()
	_Logger_Write("Создание фонового скриншота...", 1)
	_GUI_AddLog("Начинаю создание скриншота...")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	Local $hWnd = $g_hTargetWindow
	Local $sTitle = WinGetTitle($g_hTargetWindow)

	_Logger_Write("Скриншот окна: " & $sTitle, 1)
	_GUI_AddLog("Создаю скриншот окна: " & $sTitle)

	; Получение размеров окна
	Local $aPos = WinGetPos($hWnd)
	If @error Then
		_Logger_Write("Ошибка получения размеров окна", 2)
		_GUI_AddLog("Ошибка: Не удалось получить размеры окна")
		Return
	EndIf

	; Инициализация GDI+ ПЕРЕД созданием bitmap
	_GDIPlus_Startup()

	; Создание фонового скриншота полного окна
	Local $hBitmapFull = _CaptureWindowBackground($hWnd, 0, 0, $aPos[2], $aPos[3])

	If Not $hBitmapFull Then
		_Logger_Write("Ошибка создания скриншота", 2)
		_GUI_AddLog("Ошибка: Не удалось создать скриншот")
		_GDIPlus_Shutdown()
		Return
	EndIf

	; Конвертируем в GDI+ bitmap
	Local $hGDIBitmapFull = _GDIPlus_BitmapCreateFromHBITMAP($hBitmapFull)
	_Logger_Write("GDI+ bitmap создан: " & ($hGDIBitmapFull ? "OK" : "FAIL"), 1)

	If Not $hGDIBitmapFull Then
		_Logger_Write("Ошибка конвертации в GDI+ bitmap", 2)
		_GUI_AddLog("Ошибка: Не удалось конвертировать в GDI+")
		_WinAPI_DeleteObject($hBitmapFull)
		_GDIPlus_Shutdown()
		Return
	EndIf

	; Сохранение полного скриншота через GDI+
	Local $sScreenshotPath = @ScriptDir & "\screenshot_full.bmp"
	_GDIPlus_ImageSaveToFile($hGDIBitmapFull, $sScreenshotPath)
	_Logger_Write("Полный скриншот сохранён: " & $sScreenshotPath, 3)
	_GUI_AddLog("Полный скриншот сохранён")

		; Вырезаем верхний левый угол для OCR через GDI+
		_Logger_Write("Попытка обрезки области " & $g_iCrop_X & "," & $g_iCrop_Y & "," & $g_iCrop_Width & "," & $g_iCrop_Height & "...", 1)
		Local $hGDIBitmapCrop = _GDIPlus_BitmapCloneArea($hGDIBitmapFull, $g_iCrop_X, $g_iCrop_Y, $g_iCrop_Width, $g_iCrop_Height)
		_Logger_Write("Результат обрезки: " & ($hGDIBitmapCrop ? "OK" : "FAIL") & " (@error=" & @error & ")", 1)

		If $hGDIBitmapCrop Then
			; Создаём папку img если её нет
			Local $sImgFolder = @ScriptDir & "\img"
			If Not FileExists($sImgFolder) Then DirCreate($sImgFolder)

			; Сохранение обрезанного скриншота
			Local $sCropPath = $sImgFolder & "\screenshot_crop.bmp"
			_GDIPlus_ImageSaveToFile($hGDIBitmapCrop, $sCropPath)
			_Logger_Write("Обрезанный скриншот сохранён: " & $sCropPath, 3)
			_GUI_AddLog("Обрезанный скриншот (" & $g_iCrop_Width & "x" & $g_iCrop_Height & ") сохранён")

			; === ПЕРЕМЕННЫЕ ДЛЯ РЕЗУЛЬТАТОВ ===
			Local $sCity = ""
			Local $sCoords = ""
			Local $iHelper = 0
			Local $iScaleFactor = 4

			; === ВЫБОР РЕЖИМА OCR ===
			If $g_bUseFullOCR Then
				_Logger_Write("========================================", 1)
				_Logger_Write("РЕЖИМ: ПОЛНЫЙ OCR (Город + Координаты вместе)", 1)
				_Logger_Write("========================================", 1)
				_GUI_AddLog("Режим: Полный OCR (город+координаты вместе)")

				; Вырезаем область с городом И координатами
				_Logger_Write("Область: X=" & $g_iCityFull_X & " Y=" & $g_iCityFull_Y & " W=" & $g_iCityFull_Width & " H=" & $g_iCityFull_Height, 1)
				Local $hGDIBitmap_Full = _GDIPlus_BitmapCloneArea($hGDIBitmapCrop, $g_iCityFull_X, $g_iCityFull_Y, $g_iCityFull_Width, $g_iCityFull_Height)

				If $hGDIBitmap_Full Then
					_GDIPlus_ImageSaveToFile($hGDIBitmap_Full, $sImgFolder & "\full_ocr.bmp")
					_Logger_Write("Изображение сохранено: full_ocr.bmp", 3)

					; Увеличение в 4 раза для OCR
					Local $hGDIBitmap_Full_Scaled = _GDIPlus_ImageResize($hGDIBitmap_Full, $g_iCityFull_Width * $iScaleFactor, $g_iCityFull_Height * $iScaleFactor)
					_GDIPlus_ImageSaveToFile($hGDIBitmap_Full_Scaled, $sImgFolder & "\full_ocr_scaled.bmp")
					_Logger_Write("Увеличенное изображение (x" & $iScaleFactor & "): full_ocr_scaled.bmp", 3)

					; OCR с английским языком
					Local $sOCR_Full = _UWPOCR_GetText($hGDIBitmap_Full_Scaled, "en-US", True)
					_Logger_Write("OCR результат: [" & $sOCR_Full & "]", 1)

					; Парсинг результата
					Local $aParsed = _ParseCityAndCoords($sOCR_Full)
					$sCity = $aParsed[0]
					$sCoords = $aParsed[1]

					_Logger_Write("Распознано - Город: [" & $sCity & "], Координаты: [" & $sCoords & "]", 3)
					_GUI_AddLog("Город: [" & $sCity & "], Координаты: [" & $sCoords & "]")

					_GDIPlus_BitmapDispose($hGDIBitmap_Full_Scaled)
					_GDIPlus_BitmapDispose($hGDIBitmap_Full)
				Else
					_Logger_Write("Ошибка вырезки области для полного OCR", 2)
				EndIf

			Else
				_Logger_Write("========================================", 1)
				_Logger_Write("РЕЖИМ: РАЗДЕЛЬНЫЙ OCR (Город и Координаты отдельно)", 1)
				_Logger_Write("========================================", 1)
				_GUI_AddLog("Режим: Раздельный OCR (город и координаты отдельно)")

				; === ЧАСТЬ 1: ТОЛЬКО ГОРОД ===
				_Logger_Write("Часть 1 (Город): X=" & $g_iCityOnly_X & " Y=" & $g_iCityOnly_Y & " W=" & $g_iCityOnly_Width & " H=" & $g_iCityOnly_Height, 1)
				Local $hGDIBitmap_City = _GDIPlus_BitmapCloneArea($hGDIBitmapCrop, $g_iCityOnly_X, $g_iCityOnly_Y, $g_iCityOnly_Width, $g_iCityOnly_Height)

				If $hGDIBitmap_City Then
					_GDIPlus_ImageSaveToFile($hGDIBitmap_City, $sImgFolder & "\1_city.bmp")
					_Logger_Write("Часть 1 (Город) сохранена: 1_city.bmp", 3)

					; Увеличение в 4 раза для OCR
					Local $hGDIBitmap_City_Scaled = _GDIPlus_ImageResize($hGDIBitmap_City, $g_iCityOnly_Width * $iScaleFactor, $g_iCityOnly_Height * $iScaleFactor)
					_GDIPlus_ImageSaveToFile($hGDIBitmap_City_Scaled, $sImgFolder & "\1_city_scaled.bmp")
					_Logger_Write("Увеличенное изображение города (x" & $iScaleFactor & "): 1_city_scaled.bmp", 3)

					; OCR с английским языком
					$sCity = _UWPOCR_GetText($hGDIBitmap_City_Scaled, "en-US", True)
					$sCity = StringStripWS($sCity, 3)
					_Logger_Write("OCR Город: [" & $sCity & "]", 1)
					_GUI_AddLog("Город: [" & $sCity & "]")

					_GDIPlus_BitmapDispose($hGDIBitmap_City_Scaled)
					_GDIPlus_BitmapDispose($hGDIBitmap_City)
				Else
					_Logger_Write("Ошибка вырезки части 1 (Город)", 2)
				EndIf

				; === ЧАСТЬ 2: ТОЛЬКО КООРДИНАТЫ ===
				_Logger_Write("Часть 2 (Координаты): X=" & $g_iCoordsOnly_X & " Y=" & $g_iCoordsOnly_Y & " W=" & $g_iCoordsOnly_Width & " H=" & $g_iCoordsOnly_Height, 1)
				Local $hGDIBitmap_Coords = _GDIPlus_BitmapCloneArea($hGDIBitmapCrop, $g_iCoordsOnly_X, $g_iCoordsOnly_Y, $g_iCoordsOnly_Width, $g_iCoordsOnly_Height)

				If $hGDIBitmap_Coords Then
					_GDIPlus_ImageSaveToFile($hGDIBitmap_Coords, $sImgFolder & "\2_coords.bmp")
					_Logger_Write("Часть 2 (Координаты) сохранена: 2_coords.bmp", 3)

					; Увеличение в 4 раза для OCR
					Local $hGDIBitmap_Coords_Scaled = _GDIPlus_ImageResize($hGDIBitmap_Coords, $g_iCoordsOnly_Width * $iScaleFactor, $g_iCoordsOnly_Height * $iScaleFactor)
					_GDIPlus_ImageSaveToFile($hGDIBitmap_Coords_Scaled, $sImgFolder & "\2_coords_scaled.bmp")
					_Logger_Write("Увеличенное изображение координат (x" & $iScaleFactor & "): 2_coords_scaled.bmp", 3)

					; OCR для координат (язык не важен, это цифры)
					$sCoords = _UWPOCR_GetText($hGDIBitmap_Coords_Scaled, Default, True)
					$sCoords = StringStripWS($sCoords, 3)
					_Logger_Write("OCR Координаты: [" & $sCoords & "]", 1)
					_GUI_AddLog("Координаты: [" & $sCoords & "]")

					_GDIPlus_BitmapDispose($hGDIBitmap_Coords_Scaled)
					_GDIPlus_BitmapDispose($hGDIBitmap_Coords)
				Else
					_Logger_Write("Ошибка вырезки части 2 (Координаты)", 2)
				EndIf
			EndIf

			; === ЧАСТЬ 3: HELPER BOT (одинаково для обоих режимов) ===
			_Logger_Write("Часть 3 (Helper): X=" & $g_iHelper_X & " Y=" & $g_iHelper_Y & " W=" & $g_iHelper_Width & " H=" & $g_iHelper_Height, 1)
			Local $hGDIBitmap_Helper = _GDIPlus_BitmapCloneArea($hGDIBitmapCrop, $g_iHelper_X, $g_iHelper_Y, $g_iHelper_Width, $g_iHelper_Height)

			If $hGDIBitmap_Helper Then
				_GDIPlus_ImageSaveToFile($hGDIBitmap_Helper, $sImgFolder & "\3_helper.bmp")
				_Logger_Write("Часть 3 (Helper) сохранена: 3_helper.bmp", 3)

				; Проверка цвета пикселя в центре изображения
				Local $iCenterX = Int($g_iHelper_Width / 2)
				Local $iCenterY = Int($g_iHelper_Height / 2)
				Local $iPixelColor = _GDIPlus_BitmapGetPixel($hGDIBitmap_Helper, $iCenterX, $iCenterY)

				; Разложение цвета на RGB
				Local $iRed = BitAND(BitShift($iPixelColor, 16), 0xFF)
				Local $iGreen = BitAND(BitShift($iPixelColor, 8), 0xFF)
				Local $iBlue = BitAND($iPixelColor, 0xFF)

				_Logger_Write("Цвет пикселя [" & $iCenterX & "," & $iCenterY & "]: RGB(" & $iRed & "," & $iGreen & "," & $iBlue & ")", 1)

				; Проверка на жёлтый цвет (цифра "1")
				If $iRed > 150 And $iGreen > 150 And $iBlue < 100 Then
					$iHelper = 1
					_Logger_Write("Helper Bot: АКТИВЕН (1) - обнаружен жёлтый цвет", 3)
					_GUI_AddLog("Helper Bot: [1] АКТИВЕН")
				Else
					$iHelper = 0
					_Logger_Write("Helper Bot: НЕАКТИВЕН (0) - жёлтый цвет не обнаружен", 1)
					_GUI_AddLog("Helper Bot: [0] НЕАКТИВЕН")
				EndIf

				_GDIPlus_BitmapDispose($hGDIBitmap_Helper)
			Else
				_Logger_Write("Ошибка вырезки части 3 (Helper)", 2)
			EndIf

			; === ИТОГОВЫЙ РЕЗУЛЬТАТ ===
			_Logger_Write("========================================", 1)
			_Logger_Write("ИТОГОВЫЙ РЕЗУЛЬТАТ:", 1)
			_Logger_Write("Город: [" & $sCity & "]", 1)
			_Logger_Write("Координаты: [" & $sCoords & "]", 1)
			_Logger_Write("Helper Bot: [" & $iHelper & "]", 1)
			_Logger_Write("========================================", 1)
			_GUI_AddLog("--- ИТОГ: Город=[" & $sCity & "], Координаты=[" & $sCoords & "], Helper=[" & $iHelper & "] ---")

			_GDIPlus_BitmapDispose($hGDIBitmapCrop)
		Else
			_Logger_Write("Ошибка обрезки изображения", 2)
			_GUI_AddLog("Ошибка: Не удалось обрезать изображение")
		EndIf

		_GDIPlus_BitmapDispose($hGDIBitmapFull)
		_WinAPI_DeleteObject($hBitmapFull)

	_GDIPlus_Shutdown()
EndFunc

; ===============================================================================
; Функция: _CaptureWindowBackground
; Описание: Фоновый захват окна через PrintWindow API
; Параметры:
;   $hWnd - Handle окна
;   $iX, $iY - Координаты начала области
;   $iWidth, $iHeight - Размеры области
; Возврат: Handle bitmap или 0 при ошибке
; ===============================================================================
Func _CaptureWindowBackground($hWnd, $iX, $iY, $iWidth, $iHeight)
	_Logger_Write("Фоновый захват окна...", 1)

	; Получение DC окна
	Local $hDC = _WinAPI_GetDC($hWnd)
	If Not $hDC Then
		_Logger_Write("Ошибка получения DC окна", 2)
		Return 0
	EndIf

	; Создание совместимого DC
	Local $hMemDC = _WinAPI_CreateCompatibleDC($hDC)
	If Not $hMemDC Then
		_Logger_Write("Ошибка создания совместимого DC", 2)
		_WinAPI_ReleaseDC($hWnd, $hDC)
		Return 0
	EndIf

	; Создание bitmap
	Local $hBitmap = _WinAPI_CreateCompatibleBitmap($hDC, $iWidth, $iHeight)
	If Not $hBitmap Then
		_Logger_Write("Ошибка создания bitmap", 2)
		_WinAPI_DeleteDC($hMemDC)
		_WinAPI_ReleaseDC($hWnd, $hDC)
		Return 0
	EndIf

	; Выбор bitmap в DC
	Local $hOldBitmap = _WinAPI_SelectObject($hMemDC, $hBitmap)

	; Фоновый захват через PrintWindow
	Local $aResult = DllCall("user32.dll", "bool", "PrintWindow", "hwnd", $hWnd, "handle", $hMemDC, "uint", 0)

	If @error Or Not $aResult[0] Then
		_Logger_Write("Ошибка PrintWindow, используем BitBlt", 2)
		; Fallback на BitBlt
		_WinAPI_BitBlt($hMemDC, 0, 0, $iWidth, $iHeight, $hDC, $iX, $iY, 0x00CC0020) ; SRCCOPY
	EndIf

	; Восстановление и очистка
	_WinAPI_SelectObject($hMemDC, $hOldBitmap)
	_WinAPI_DeleteDC($hMemDC)
	_WinAPI_ReleaseDC($hWnd, $hDC)

	_Logger_Write("Фоновый захват выполнен успешно", 3)
	Return $hBitmap
EndFunc

; ===============================================================================
; Функция: _ParseLevelFromTitle
; Описание: Парсинг уровня персонажа из заголовка окна
; Параметры: $sTitle - заголовок окна
; Возврат: Уровень (число) или 0 если не найден
; Пример: "Level: [367]" -> 367
; ===============================================================================
; ===============================================================================
; Функция: _ParseLevelFromTitle
; Описание: Парсинг уровня персонажа из заголовка окна (обёртка над _ParseWindowData)
; Параметры: $sTitle - заголовок окна (не используется, читается из $g_hTargetWindow)
; Возврат: Уровень (число) или 0 если не найден
; ===============================================================================
Func _ParseLevelFromTitle($sTitle)
	Local $oData = _ParseWindowData()
	Return $oData["level"]
EndFunc

; ===============================================================================
; Функция: _ParseWindowData
; Описание: Полный парсинг данных персонажа из заголовка $g_hTargetWindow
;           Читает свежий title каждый раз при вызове
; Возврат: Map с ключами:
;   has_char   - True если найден персонаж
;   nick       - ник персонажа или ""
;   level      - уровень (число) или 0
;   master_level - мастер уровень (число) или 0
;   resets     - количество ресетов (число) или 0
;   hwnd       - HWND окна
;   pid        - PID процесса
;   display    - строка для отображения в dropdown
; ===============================================================================
Func _ParseWindowData()
	Local $oData[]
	$oData["has_char"]     = False
	$oData["nick"]         = ""
	$oData["level"]        = 0
	$oData["master_level"] = 0
	$oData["resets"]       = 0
	$oData["hwnd"]         = $g_hTargetWindow
	$oData["pid"]          = 0
	$oData["display"]      = ""

	If $g_hTargetWindow = 0 Then
		$oData["display"] = "— окно не выбрано —"
		Return $oData
	EndIf

	; Свежий title каждый раз
	Local $sTitle = WinGetTitle($g_hTargetWindow)
	Local $iPID   = WinGetProcess($g_hTargetWindow)
	$oData["pid"] = $iPID

	; Паттерн: Name: [NanoElf] Level: [325] Master Level: [436] Resets: [85]
	Local $aName   = StringRegExp($sTitle, "(?i)Name\s*:\s*\[([^\]]+)\]", 3)
	Local $aLevel  = StringRegExp($sTitle, "(?i)(?<![Mm]aster\s)Level\s*:\s*\[(\d+)\]", 3)
	Local $aMaster = StringRegExp($sTitle, "(?i)Master\s+Level\s*:\s*\[(\d+)\]", 3)
	Local $aResets = StringRegExp($sTitle, "(?i)Resets\s*:\s*\[(\d+)\]", 3)

	If Not @error And UBound($aName) > 0 Then
		; Персонаж найден
		$oData["has_char"]     = True
		$oData["nick"]         = $aName[0]
		$oData["level"]        = (UBound($aLevel) > 0)  ? Int($aLevel[0])  : 0
		$oData["master_level"] = (UBound($aMaster) > 0) ? Int($aMaster[0]) : 0
		$oData["resets"]       = (UBound($aResets) > 0) ? Int($aResets[0]) : 0
		$oData["display"]      = "[" & $oData["nick"] & "] Lv" & $oData["level"] & _
		                         " MR" & $oData["master_level"] & " R" & $oData["resets"]
	Else
		; Персонаж не найден — показываем HWND + PID
		$oData["display"] = StringFormat("HWND:0x%08X PID:%d", $g_hTargetWindow, $iPID)
	EndIf

	Return $oData
EndFunc

; ===============================================================================
; Функция: _ParseCityAndCoords
; Описание: Парсинг города и координат из результата OCR
; Параметры: $sOCR_Text - текст от OCR (может содержать переносы строк)
; Возврат: Массив [город, координаты] или ["", ""] при ошибке
; Примеры входных данных:
;   "Tarkan\n198,66" -> ["Tarkan", "198,66"]
;   "Lost Tower 7\n123,456" -> ["Lost Tower 7", "123,456"]
;   "Atlans" -> ["Atlans", ""] (только город)
; ===============================================================================
Func _ParseCityAndCoords($sOCR_Text)
	Local $aResult[2] = ["", ""]

	; Убираем лишние пробелы по краям
	$sOCR_Text = StringStripWS($sOCR_Text, 3)

	If $sOCR_Text = "" Then
		_Logger_Write("_ParseCityAndCoords: Пустой текст OCR", 2)
		Return $aResult
	EndIf

	; Разделяем по переносу строки
	Local $aLines = StringSplit($sOCR_Text, @CRLF, 1)

	If $aLines[0] >= 1 Then
		; Первая строка - город
		$aResult[0] = StringStripWS($aLines[1], 3)
		_Logger_Write("_ParseCityAndCoords: Город = [" & $aResult[0] & "]", 1)
	EndIf

	If $aLines[0] >= 2 Then
		; Вторая строка - координаты
		$aResult[1] = StringStripWS($aLines[2], 3)
		_Logger_Write("_ParseCityAndCoords: Координаты = [" & $aResult[1] & "]", 1)
	Else
		; Если нет второй строки, пробуем найти координаты в первой строке
		; Паттерн: цифры,цифры в конце строки или после пробела
		Local $aMatch = StringRegExp($aResult[0], "(\d+,\d+)$", 3)
		If Not @error And UBound($aMatch) >= 1 Then
			$aResult[1] = $aMatch[0]
			; Убираем координаты из города
			$aResult[0] = StringStripWS(StringRegExpReplace($aResult[0], "\s*\d+,\d+$", ""), 3)
			_Logger_Write("_ParseCityAndCoords: Найдены координаты в одной строке", 1)
			_Logger_Write("_ParseCityAndCoords: Город (очищен) = [" & $aResult[0] & "]", 1)
			_Logger_Write("_ParseCityAndCoords: Координаты = [" & $aResult[1] & "]", 1)
		Else
			_Logger_Write("_ParseCityAndCoords: Координаты не найдены", 2)
		EndIf
	EndIf

	Return $aResult
EndFunc

; ===============================================================================
; Функция: _GUI_AddLog
; Описание: Добавление строки в лог GUI
; Параметры: $sText - текст для добавления
; ===============================================================================
Func _GUI_AddLog($sText)
	Local $sCurrentLog = GUICtrlRead($g_idEdit_Log)
	Local $sTimestamp = @HOUR & ":" & @MIN & ":" & @SEC
	Local $sNewLog = "[" & $sTimestamp & "] " & $sText & @CRLF & $sCurrentLog

	; Ограничение размера лога (последние 100 строк)
	Local $aLines = StringSplit($sNewLog, @CRLF, 1)
	If $aLines[0] > 100 Then
		$sNewLog = ""
		For $i = 1 To 100
			$sNewLog &= $aLines[$i] & @CRLF
		Next
	EndIf

	GUICtrlSetData($g_idEdit_Log, $sNewLog)
EndFunc

; ===============================================================================
; Функция: _Button_Reset
; Описание: Отправка команды /reset в выбранное окно
; ===============================================================================
Func _Button_Reset()
	_Logger_Write("Отправка команды /reset...", 1)
	_GUI_AddLog("=== КОМАНДА /RESET ===")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	Local $sTitle = WinGetTitle($g_hTargetWindow)
	_GUI_AddLog("Отправка /reset в окно: " & $sTitle)
	_Logger_Write("Отправка /reset в окно: " & $sTitle, 1)

	Local $bResult = _Send_Reset($g_hTargetWindow)

	If $bResult Then
		_GUI_AddLog("✓ Команда /reset отправлена успешно!")
		_Logger_Write("Команда /reset отправлена успешно", 3)
	Else
		_GUI_AddLog("✗ Ошибка отправки команды /reset")
		_Logger_Write("Ошибка отправки команды /reset", 2)
	EndIf
EndFunc


; ===============================================================================
; Функция: _Button_MoveWindow
; ===============================================================================
; ===============================================================================
; Функция: _Button_MoveWindow
; Описание: Перемещение окна игры в координаты 0,0 для определения точек клика
; ===============================================================================
Func _Button_MoveWindow()
	_Logger_Write("Перемещение окна в 0,0...", 1)
	_GUI_AddLog("=== ПЕРЕМЕЩЕНИЕ ОКНА В 0,0 ===")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	Local $sTitle = WinGetTitle($g_hTargetWindow)
	_GUI_AddLog("Перемещение окна: " & $sTitle)
	_Logger_Write("Перемещение окна: " & $sTitle, 1)

	WinMove($g_hTargetWindow, "", 0, 0)
	Sleep(500)

	Local $aPos = WinGetPos($g_hTargetWindow)
	If IsArray($aPos) Then
		_GUI_AddLog("✓ Окно перемещено в: X=" & $aPos[0] & " Y=" & $aPos[1])
		_Logger_Write("Окно перемещено в: X=" & $aPos[0] & " Y=" & $aPos[1], 3)
	Else
		_GUI_AddLog("✗ Ошибка перемещения окна")
		_Logger_Write("Ошибка перемещения окна", 2)
	EndIf
EndFunc


; ===============================================================================
; Функция: _Button_Teleport
; Описание: Телепорт в первый город (Y=533)
; ===============================================================================
Func _Button_Teleport()
	_Logger_Write("Телепорт в город...", 1)
	_GUI_AddLog("=== ТЕЛЕПОРТ ===")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	Local $sTitle = WinGetTitle($g_hTargetWindow)
	_GUI_AddLog("Телепорт в первый город (Y=" & $g_iTeleport_Y1 & ")")
	_Logger_Write("Телепорт в окне: " & $sTitle, 1)

	Local $bResult = _Send_TeleportToCity($g_hTargetWindow, $g_iTeleport_Y1)

	If $bResult Then
		_GUI_AddLog("✓ Телепорт выполнен успешно!")
		_Logger_Write("Телепорт выполнен успешно", 3)
	Else
		_GUI_AddLog("✗ Ошибка телепорта")
		_Logger_Write("Ошибка телепорта", 2)
	EndIf
EndFunc


; ===============================================================================
; Функция: _Button_MoveWindowProd
; ===============================================================================
; ===============================================================================
; Функция: _Button_MoveWindowProd
; Описание: Перемещение окна в продакшен позицию (1980, 0) - невидимый режим
; ===============================================================================
Func _Button_MoveWindowProd()
	_Logger_Write("Перемещение окна в продакшен позицию...", 1)
	_GUI_AddLog("=== ПЕРЕМЕЩЕНИЕ ОКНА В PROD (" & $g_iWindow_Prod_X & "," & $g_iWindow_Prod_Y & ") ===")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	Local $sTitle = WinGetTitle($g_hTargetWindow)
	_GUI_AddLog("Перемещение окна: " & $sTitle)
	_Logger_Write("Перемещение окна в продакшен: " & $sTitle, 1)

	WinMove($g_hTargetWindow, "", $g_iWindow_Prod_X, $g_iWindow_Prod_Y)
	Sleep(500)

	Local $aPos = WinGetPos($g_hTargetWindow)
	If IsArray($aPos) Then
		_GUI_AddLog("✓ Окно перемещено в: X=" & $aPos[0] & " Y=" & $aPos[1])
		_Logger_Write("Окно перемещено в продакшен: X=" & $aPos[0] & " Y=" & $aPos[1], 3)
		_GUI_AddLog("Окно в невидимом режиме (за пределами экрана)")
	Else
		_GUI_AddLog("✗ Ошибка перемещения окна")
		_Logger_Write("Ошибка перемещения окна", 2)
	EndIf
EndFunc


; ===============================================================================
; Функция: _Button_ScanMarkers
; ===============================================================================
; ===============================================================================
; Функция: _Button_ScanMarkers
; Описание: Сканирование всех маяков из JSON
; ===============================================================================
Func _Button_ScanMarkers()
	_Logger_Write("Сканирование маяков...", 1)
	_GUI_AddLog("=== СКАНИРОВАНИЕ МАЯКОВ ===")

	If $g_hTargetWindow = 0 Then
		_Logger_Write("Окно не выбрано. Нажмите 'Прочитать окна'", 2)
		_GUI_AddLog("⚠️ Окно не выбрано!")
		Return
	EndIf

	; Перезагружаем JSON перед сканированием
	_GUI_AddLog("Перезагрузка маяков из JSON...")
	If Not _Markers_Load() Then
		_GUI_AddLog("ОШИБКА: Не удалось загрузить маяки из JSON")
		_Logger_Write("Ошибка загрузки маяков", 2)
		Return
	EndIf

	; Сканируем все маяки
	Local $aResults = _Markers_ScanAll($g_hTargetWindow)

	If @error Then
		_GUI_AddLog("ОШИБКА: Не удалось отсканировать маяки")
		_Logger_Write("Ошибка сканирования маяков", 2)
		Return
	EndIf

	_GUI_AddLog("Найдено маяков: " & UBound($aResults))
	_GUI_AddLog("----------------------------------------")

	For $i = 0 To UBound($aResults) - 1
		Local $sName     = $aResults[$i][0]
		Local $iX        = $aResults[$i][1]
		Local $iY        = $aResults[$i][2]
		Local $sExpected = $aResults[$i][3]
		Local $sCurrent  = $aResults[$i][4]
		Local $bMatch    = $aResults[$i][5]
		Local $sStatus   = ($bMatch ? "✓ OK" : "✗ НЕ СОВПАДАЕТ")

		_GUI_AddLog($sName & " [" & $iX & "," & $iY & "]")
		_GUI_AddLog("  Ожидается: " & $sExpected)
		_GUI_AddLog("  Текущий:   " & $sCurrent & " " & $sStatus)
	Next

	_GUI_AddLog("========================================")
	_Logger_Write("Сканирование завершено", 3)
EndFunc



; ===============================================================================
; Функция: _AutoSelectWindow
; Описание: Автоматический поиск и выбор окна по нику персонажа
; ===============================================================================
Func _AutoSelectWindow()
	_Logger_Write("_AutoSelectWindow: Поиск окна для персонажа [" & $g_sTargetCharacterName & "]", 1)
	_GUI_AddLog("Автопоиск окна для персонажа: " & $g_sTargetCharacterName)

	; Получение списка всех окон
	Local $aWinList = WinList()
	Local $iFoundCount = 0

	For $i = 1 To $aWinList[0][0]
		Local $hWnd = $aWinList[$i][1]
		Local $sTitle = $aWinList[$i][0]

		; Проверка на видимость окна
		If Not BitAND(WinGetState($hWnd), 2) Then ContinueLoop

		; Получение имени процесса
		Local $iPID = WinGetProcess($hWnd)
		Local $sProcessName = ""
		Local $aProcess = ProcessList()
		For $j = 1 To $aProcess[0][0]
			If $aProcess[$j][1] = $iPID Then
				$sProcessName = $aProcess[$j][0]
				ExitLoop
			EndIf
		Next

		; Проверка на main.exe
		If StringLower($sProcessName) = "main.exe" Then
			$iFoundCount += 1
			_Logger_Write("_AutoSelectWindow: Найдено окно main.exe: " & $sTitle, 1)

			; Проверяем содержит ли заголовок ник персонажа
			If StringInStr($sTitle, $g_sTargetCharacterName) > 0 Then
				$g_hTargetWindow = $hWnd
				_Logger_Write("_AutoSelectWindow: Окно найдено! HWND=" & $hWnd & ", Title=[" & $sTitle & "]", 3)
				_GUI_AddLog("✅ Окно найдено: " & $sTitle)
				_GUI_AddLog("   HWND: " & $hWnd)
				Return True
			EndIf
		EndIf
	Next

	; Окно не найдено
	If $iFoundCount = 0 Then
		_Logger_Write("_AutoSelectWindow: Окна main.exe не найдены", 2)
		_GUI_AddLog("⚠️ Окна MU Online не найдены! Запустите игру.")
	Else
		_Logger_Write("_AutoSelectWindow: Окно с ником [" & $g_sTargetCharacterName & "] не найдено (всего окон: " & $iFoundCount & ")", 2)
		_GUI_AddLog("⚠️ Окно с ником [" & $g_sTargetCharacterName & "] не найдено!")
		_GUI_AddLog("   Найдено окон MU Online: " & $iFoundCount)
		_GUI_AddLog("   Проверьте что персонаж залогинен и ник указан правильно.")
	EndIf

	Return False
EndFunc

; #FUNCTION# ====================================================================
; Name ..........: _Core_FullOCR
; Description ...: Полное сканирование окна: ник, уровень, город, координаты, маркеры
; Syntax ........: _Core_FullOCR($hWnd)
; Parameters ....: $hWnd - handle окна игры
; Return values .: Массив [CharName, Level, City, Coords, MarkersArray, Success]
; ===============================================================================
Func _Core_FullOCR($hWnd)
	_Logger_Write("_Core_FullOCR: Начало полного сканирования", 1)

	Local $aResult[6]
	$aResult[0] = ""        ; CharName
	$aResult[1] = 0         ; Level
	$aResult[2] = ""        ; City
	$aResult[3] = ""        ; Coords
	$aResult[4] = ""        ; MarkersArray
	$aResult[5] = False     ; Success

	; === 1. ПАРСИНГ TITLE (НИК И УРОВЕНЬ) ===
	Local $sTitle = WinGetTitle($hWnd)
	If @error Or $sTitle = "" Then
		_Logger_Write("_Core_FullOCR: Ошибка получения заголовка окна", 2)
		Return $aResult
	EndIf

	_Logger_Write("_Core_FullOCR: Title = [" & $sTitle & "]", 1)

	; Парсинг ника: Name: [NanoElf]
	Local $aMatchName = StringRegExp($sTitle, "Name:\s*\[([^\]]+)\]", 3)
	If Not @error And UBound($aMatchName) >= 1 Then
		$aResult[0] = $aMatchName[0]
		_Logger_Write("_Core_FullOCR: Ник = [" & $aResult[0] & "]", 1)
	EndIf

	; Парсинг уровня: Level: [129]
	Local $aMatchLevel = StringRegExp($sTitle, "Level:\s*\[(\d+)\]", 3)
	If Not @error And UBound($aMatchLevel) >= 1 Then
		$aResult[1] = Number($aMatchLevel[0])
		_Logger_Write("_Core_FullOCR: Уровень = [" & $aResult[1] & "]", 1)
	EndIf

	; === 2. СКРИНШОТ И OCR (ГОРОД + КООРДИНАТЫ) ===
	_Logger_Write("_Core_FullOCR: Создание фонового скриншота...", 1)

	; Получение размеров окна
	Local $aPos = WinGetPos($hWnd)
	If @error Then
		_Logger_Write("_Core_FullOCR: Ошибка получения размеров окна", 2)
		Return $aResult
	EndIf

	; Инициализация GDI+
	_GDIPlus_Startup()

	; Создание фонового скриншота
	Local $hBitmapFull = _CaptureWindowBackground($hWnd, 0, 0, $aPos[2], $aPos[3])
	If Not $hBitmapFull Then
		_Logger_Write("_Core_FullOCR: Ошибка создания скриншота", 2)
		_GDIPlus_Shutdown()
		Return $aResult
	EndIf

	; Конвертируем в GDI+ bitmap
	Local $hGDIBitmapFull = _GDIPlus_BitmapCreateFromHBITMAP($hBitmapFull)
	If Not $hGDIBitmapFull Then
		_Logger_Write("_Core_FullOCR: Ошибка конвертации в GDI+", 2)
		_WinAPI_DeleteObject($hBitmapFull)
		_GDIPlus_Shutdown()
		Return $aResult
	EndIf

	; Вырезаем область для OCR (используем глобальные координаты из Main)
	Local $hGDIBitmapCrop = _GDIPlus_BitmapCloneArea($hGDIBitmapFull, $g_iCrop_X, $g_iCrop_Y, $g_iCrop_Width, $g_iCrop_Height)
	If Not $hGDIBitmapCrop Then
		_Logger_Write("_Core_FullOCR: Ошибка обрезки изображения", 2)
		_GDIPlus_BitmapDispose($hGDIBitmapFull)
		_WinAPI_DeleteObject($hBitmapFull)
		_GDIPlus_Shutdown()
		Return $aResult
	EndIf

	; === OCR ГОРОДА И КООРДИНАТ ===
	; Вырезаем область с городом И координатами
	Local $hGDIBitmap_Full = _GDIPlus_BitmapCloneArea($hGDIBitmapCrop, $g_iCityFull_X, $g_iCityFull_Y, $g_iCityFull_Width, $g_iCityFull_Height)

	If $hGDIBitmap_Full Then
		; Увеличение в 4 раза для OCR
		Local $iScaleFactor = 4
		Local $hGDIBitmap_Full_Scaled = _GDIPlus_ImageResize($hGDIBitmap_Full, $g_iCityFull_Width * $iScaleFactor, $g_iCityFull_Height * $iScaleFactor)

		; OCR с английским языком
		Local $sOCR_Full = _UWPOCR_GetText($hGDIBitmap_Full_Scaled, "en-US", True)
		_Logger_Write("_Core_FullOCR: OCR результат = [" & $sOCR_Full & "]", 1)

		; Парсинг результата
		Local $aParsed = _ParseCityAndCoords($sOCR_Full)
		$aResult[2] = $aParsed[0]  ; City
		$aResult[3] = $aParsed[1]  ; Coords

		_Logger_Write("_Core_FullOCR: Город = [" & $aResult[2] & "], Координаты = [" & $aResult[3] & "]", 1)

		_GDIPlus_BitmapDispose($hGDIBitmap_Full_Scaled)
		_GDIPlus_BitmapDispose($hGDIBitmap_Full)
	Else
		_Logger_Write("_Core_FullOCR: Ошибка вырезки области для OCR", 2)
	EndIf

	; === 3. ПРОВЕРКА МАРКЕРОВ ===
	_Logger_Write("_Core_FullOCR: Проверка маркеров...", 1)

	; Проверяем все маркеры через новую функцию
	Local $sMarkersJSON = _Markers_CheckAll($hGDIBitmapFull)
	If $sMarkersJSON Then
		$aResult[4] = $sMarkersJSON
		_Logger_Write("_Core_FullOCR: Маркеры проверены успешно", 3)
	Else
		_Logger_Write("_Core_FullOCR: Ошибка проверки маркеров", 2)
		$aResult[4] = ""
	EndIf

	; Очистка ресурсов
	_GDIPlus_BitmapDispose($hGDIBitmapCrop)
	_GDIPlus_BitmapDispose($hGDIBitmapFull)
	_WinAPI_DeleteObject($hBitmapFull)
	_GDIPlus_Shutdown()

	$aResult[5] = True
	_Logger_Write("_Core_FullOCR: Сканирование завершено успешно", 3)

	Return $aResult
EndFunc

; ===============================================================================
; Функция: _Button_StartRecord
; ===============================================================================
; ===============================================================================
; Обработчики кнопок записи маршрута
; ===============================================================================
; #FUNCTION# ====================================================================
; Name ..........: _Button_StartRecord
; Description ...: Обработчик кнопки "Начать запись"
; ===============================================================================
Func _Button_StartRecord()
	_GUI_AddLog("=== НАЧАЛО ЗАПИСИ МАРШРУТА ===")

	; Проверяем что окно выбрано
	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано! Нажмите 'Прочитать окна'")
		Return
	EndIf

	; Получаем данные из GUI
	Local $sCityData = GUICtrlRead($g_idCombo_City)
	Local $sRouteName = GUICtrlRead($g_idInput_RouteName)

	; Проверяем имя маршрута
	If StringStripWS($sRouteName, 3) = "" Then
		_GUI_AddLog("❌ Ошибка: Введите имя маршрута!")
		Return
	EndIf

	; Парсим город и Y координату из конфига
	Local $sCityName = ""
	Local $iCityY = 0
	Local $bCityFound = False

	; Извлекаем название города из строки "Название (Y)"
	Local $aMatches = StringRegExp($sCityData, "^(.+?)\s*\((\d+)\)$", 1)
	If Not @error And IsArray($aMatches) And UBound($aMatches) >= 2 Then
		$sCityName = StringStripWS($aMatches[0], 3)
		$iCityY = Number($aMatches[1])
		$bCityFound = True
	EndIf

	If Not $bCityFound Then
		_GUI_AddLog("❌ Ошибка: Неверный формат города!")
		Return
	EndIf

	_GUI_AddLog("📍 Город: " & $sCityName & " (Y=" & $iCityY & ")")
	_GUI_AddLog("📝 Имя маршрута: " & $sRouteName)

	; Сохраняем выбранный город в конфиг
	_Config_SaveLastCity($sCityName)

	; Создаём новый маршрут
	Local $bResult = _Routes_CreateNew($sRouteName, $sCityName, $iCityY, $g_hTargetWindow)

	If $bResult Then
		_GUI_AddLog("✅ Маршрут создан! Стартовая точка записана.")
		_GUI_AddLog("➡️ Управляйте персонажем и нажимайте 'Добавить точку'")

		; Обновляем счётчик
		GUICtrlSetData($g_idLabel_PointsCount, "Точек: " & _Routes_GetWaypointsCount())

		; Меняем состояние кнопок
		GUICtrlSetState($g_idBtn_StartRecord, $GUI_DISABLE)
		GUICtrlSetState($g_idBtn_AddPoint, $GUI_ENABLE)
		GUICtrlSetState($g_idBtn_SaveRoute, $GUI_ENABLE)
		GUICtrlSetState($g_idBtn_CancelRecord, $GUI_ENABLE)
		GUICtrlSetState($g_idCombo_City, $GUI_DISABLE)
		GUICtrlSetState($g_idInput_RouteName, $GUI_DISABLE)
	Else
		_GUI_AddLog("❌ Ошибка создания маршрута!")
	EndIf
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Button_AddPoint
; Description ...: Обработчик кнопки "Добавить точку"
; ===============================================================================
Func _Button_AddPoint()
	_GUI_AddLog("➕ Добавление контрольной точки...")

	; Добавляем точку
	Local $bResult = _Routes_AddPoint($g_hTargetWindow, "Точка #" & _Routes_GetWaypointsCount())

	If $bResult Then
		Local $iCount = _Routes_GetWaypointsCount()
		_GUI_AddLog("✅ Точка #" & ($iCount - 1) & " добавлена!")
		GUICtrlSetData($g_idLabel_PointsCount, "Точек: " & $iCount)
	Else
		_GUI_AddLog("❌ Ошибка добавления точки!")
	EndIf
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Button_SaveRoute
; Description ...: Обработчик кнопки "Сохранить маршрут"
; ===============================================================================
Func _Button_SaveRoute()
	_GUI_AddLog("💾 Сохранение маршрута...")

	; Получаем имя файла
	Local $sFileName = GUICtrlRead($g_idInput_RouteName)
	$sFileName = StringRegExpReplace($sFileName, '[\\/:*?"<>|]', "_")  ; Убираем недопустимые символы

	; Сохраняем
	Local $bResult = _Routes_SaveToFile($sFileName)

	If $bResult Then
		_GUI_AddLog("✅ Маршрут сохранён: " & $sFileName & ".json")
		_GUI_AddLog("=== ЗАПИСЬ ЗАВЕРШЕНА ===")

		; Сбрасываем GUI
		GUICtrlSetData($g_idLabel_PointsCount, "Точек: 0")
		GUICtrlSetData($g_idInput_RouteName, "")

		; Возвращаем состояние кнопок
		GUICtrlSetState($g_idBtn_StartRecord, $GUI_ENABLE)
		GUICtrlSetState($g_idBtn_AddPoint, $GUI_DISABLE)
		GUICtrlSetState($g_idBtn_SaveRoute, $GUI_DISABLE)
		GUICtrlSetState($g_idBtn_CancelRecord, $GUI_DISABLE)
		GUICtrlSetState($g_idCombo_City, $GUI_ENABLE)
		GUICtrlSetState($g_idInput_RouteName, $GUI_ENABLE)
	Else
		_GUI_AddLog("❌ Ошибка сохранения маршрута!")
	EndIf
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Button_CancelRecord
; Description ...: Обработчик кнопки "Отменить запись"
; ===============================================================================
Func _Button_CancelRecord()
	_GUI_AddLog("❌ Запись маршрута отменена")

	; Очищаем глобальные переменные
	$g_oCurrentRoute = ""
	$g_aWaypoints = ""

	; Сбрасываем GUI
	GUICtrlSetData($g_idLabel_PointsCount, "Точек: 0")

	; Возвращаем состояние кнопок
	GUICtrlSetState($g_idBtn_StartRecord, $GUI_ENABLE)
	GUICtrlSetState($g_idBtn_AddPoint, $GUI_DISABLE)
	GUICtrlSetState($g_idBtn_SaveRoute, $GUI_DISABLE)
	GUICtrlSetState($g_idBtn_CancelRecord, $GUI_DISABLE)
	GUICtrlSetState($g_idCombo_City, $GUI_ENABLE)
	GUICtrlSetState($g_idInput_RouteName, $GUI_ENABLE)
EndFunc


; ===============================================================================
; Функции инициализации
; ===============================================================================

; #FUNCTION# ====================================================================
; Name ..........: _Routes_Init
; Description ...: Инициализация системы маршрутов
; Syntax ........: _Routes_Init()
; Return values .: True - успешно, False - ошибка
; ===============================================================================
Func _Routes_Init()
	_Logger_Write("_Routes_Init: Инициализация системы маршрутов", 1)

	; Проверяем существование папки data
	Local $sDataFolder = @ScriptDir & "\data"
	If Not FileExists($sDataFolder) Then
		DirCreate($sDataFolder)
		_Logger_Write("_Routes_Init: Создана папка data", 1)
	EndIf

	; Проверяем существование папки routes
	If Not FileExists($g_sRoutesFolder) Then
		DirCreate($g_sRoutesFolder)
		_Logger_Write("_Routes_Init: Создана папка routes", 1)
	EndIf

	; Инициализация переменных
	$g_bRecording = False
	$g_aCurrentRoute = ""
	$g_iWaypointsCount = 0
	$g_bAutopilotRunning = False
	$g_sCurrentRouteFile = ""
	$g_iCurrentWaypoint = 0

	_Logger_Write("_Routes_Init: Инициализация завершена", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Cities_Load
; ===============================================================================
; ===============================================================================
; Функция: _Cities_Load
; Описание: Загрузка списка городов из JSON конфига
; Возвращает: True при успехе, False при ошибке
; ===============================================================================
Func _Cities_Load()
	_Logger_Write("_Cities_Load: Загрузка городов из JSON", 1)

	If Not FileExists($g_sCitiesFile) Then
		_Logger_Write("_Cities_Load: Файл не найден: " & $g_sCitiesFile, 2)
		Return False
	EndIf

	Local $sJSON = FileRead($g_sCitiesFile)
	If @error Then
		_Logger_Write("_Cities_Load: Ошибка чтения файла", 2)
		Return False
	EndIf

	Local $oData = _JSON_Parse($sJSON)
	If @error Or $oData = "" Then
		_Logger_Write("_Cities_Load: Ошибка парсинга JSON", 2)
		Return False
	EndIf

	$g_aCities = _JSON_Get($oData, "[cities]")
	If @error Or Not IsArray($g_aCities) Then
		_Logger_Write("_Cities_Load: Ошибка получения массива городов", 2)
		Return False
	EndIf

	_Logger_Write("_Cities_Load: Загружено городов: " & UBound($g_aCities), 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _Config_SaveLastRoute
; ===============================================================================
; ===============================================================================
; Функция: _Config_SaveLastRoute
; Описание: Сохранение последнего выбранного маршрута в конфиг
; Параметры: $sRouteName - имя файла маршрута
; ===============================================================================
Func _Config_SaveLastRoute($sRouteName)
	_Logger_Write("_Config_SaveLastRoute: Сохранение маршрута: " & $sRouteName, 1)

	_Utils_Config_Set("[autopilot][last_selected_route]", $sRouteName)
	If @error Then
		_Logger_Write("_Config_SaveLastRoute: Ошибка установки значения", 2)
		Return False
	EndIf

	Local $bResult = _Utils_Config_Save()
	If $bResult Then
		_Logger_Write("_Config_SaveLastRoute: Маршрут сохранён в конфиг", 3)
	Else
		_Logger_Write("_Config_SaveLastRoute: Ошибка сохранения конфига", 2)
	EndIf

	Return $bResult
EndFunc
; ===============================================================================
; Функция: _Config_LoadLastRoute
; Описание: Загрузка последнего выбранного маршрута из конфига
; Возвращает: Имя файла маршрута или пустую строку
; ===============================================================================
Func _Config_LoadLastRoute()
	_Logger_Write("_Config_LoadLastRoute: Загрузка последнего маршрута", 1)

	Local $sLastRoute = _Utils_Config_Get("[autopilot][last_selected_route]", "")
	If @error Then
		_Logger_Write("_Config_LoadLastRoute: Ошибка чтения last_selected_route", 2)
		Return ""
	EndIf

	_Logger_Write("_Config_LoadLastRoute: Последний маршрут: " & $sLastRoute, 1)
	Return $sLastRoute
EndFunc
; ===============================================================================
; Функция: _Config_SaveLastCity
; Описание: Сохранение последнего выбранного города в конфиг
; Параметры: $sCityName - название города
; ===============================================================================
Func _Config_SaveLastCity($sCityName)
	_Logger_Write("_Config_SaveLastCity: Сохранение города: " & $sCityName, 1)

	_Utils_Config_Set("[autopilot][last_selected_city]", $sCityName)
	If @error Then
		_Logger_Write("_Config_SaveLastCity: Ошибка установки значения", 2)
		Return False
	EndIf

	Local $bResult = _Utils_Config_Save()
	If $bResult Then
		_Logger_Write("_Config_SaveLastCity: Город сохранён в конфиг", 3)
	Else
		_Logger_Write("_Config_SaveLastCity: Ошибка сохранения конфига", 2)
	EndIf

	Return $bResult
EndFunc
; ===============================================================================
; Функция: _Config_LoadLastCity
; Описание: Загрузка последнего выбранного города из конфига
; Возвращает: Название города или "Devias" по умолчанию
; ===============================================================================
Func _Config_LoadLastCity()
	_Logger_Write("_Config_LoadLastCity: Загрузка последнего города", 1)

	Local $sLastCity = _Utils_Config_Get("[autopilot][last_selected_city]", "Devias")
	If @error Then
		_Logger_Write("_Config_LoadLastCity: Ошибка чтения last_selected_city", 2)
		Return "Devias"
	EndIf

	_Logger_Write("_Config_LoadLastCity: Последний город: " & $sLastCity, 1)
	Return $sLastCity
EndFunc



; ===============================================================================
; Функции управления файлами
; ===============================================================================

; #FUNCTION# ====================================================================
; Name ..........: _Routes_GetList
; Description ...: Получает список всех файлов маршрутов
; Syntax ........: _Routes_GetList()
; Return values .: Массив имён файлов или пустой массив
; ===============================================================================
Func _Routes_GetList()
	_Logger_Write("_Routes_GetList: Получение списка маршрутов", 1)

	Local $aFiles[0]

	; Проверяем существование папки
	If Not FileExists($g_sRoutesFolder) Then
		_Logger_Write("_Routes_GetList: Папка routes не существует", 2)
		Return $aFiles
	EndIf

	; Ищем все JSON файлы
	Local $hSearch = FileFindFirstFile($g_sRoutesFolder & "\*.json")
	If $hSearch = -1 Then
		_Logger_Write("_Routes_GetList: Маршруты не найдены", 1)
		Return $aFiles
	EndIf

	; Собираем список файлов
	Local $iCount = 0
	While True
		Local $sFileName = FileFindNextFile($hSearch)
		If @error Then ExitLoop

		ReDim $aFiles[$iCount + 1]
		$aFiles[$iCount] = $sFileName
		$iCount += 1
	WEnd

	FileClose($hSearch)

	_Logger_Write("_Routes_GetList: Найдено маршрутов: " & $iCount, 1)
	Return $aFiles
EndFunc

; #FUNCTION# ====================================================================
; Name ..........: _Routes_Load
; Description ...: Загружает маршрут из JSON файла
; Syntax ........: _Routes_Load($sFileName)
; Parameters ....: $sFileName - имя файла (например "Devias_Dungeon.json")
; Return values .: Структура маршрута или False при ошибке
; ===============================================================================
Func _Routes_Load($sFileName)
	_Logger_Write("_Routes_Load: Загрузка маршрута [" & $sFileName & "]", 1)

	Local $sFilePath = $g_sRoutesFolder & "\" & $sFileName

	; Проверяем существование файла
	If Not FileExists($sFilePath) Then
		_Logger_Write("_Routes_Load: Файл не найден: " & $sFilePath, 2)
		Return False
	EndIf

	; Читаем файл
	Local $sJSON = FileRead($sFilePath)
	If @error Or $sJSON = "" Then
		_Logger_Write("_Routes_Load: Ошибка чтения файла", 2)
		Return False
	EndIf

	; Парсим JSON
	Local $aRoute = _JSON_Parse($sJSON)
	If @error Then
		_Logger_Write("_Routes_Load: Ошибка парсинга JSON", 2)
		Return False
	EndIf

	_Logger_Write("_Routes_Load: Маршрут загружен успешно", 3)
	Return $aRoute
EndFunc

; #FUNCTION# ====================================================================
; Name ..........: _Routes_Save
; Description ...: Сохраняет маршрут в JSON файл
; Syntax ........: _Routes_Save($sFileName, $aRoute)
; Parameters ....: $sFileName - имя файла
;                  $aRoute - структура маршрута
; Return values .: True - успешно, False - ошибка
; ===============================================================================
Func _Routes_Save($sFileName, $aRoute)
	_Logger_Write("_Routes_Save: Сохранение маршрута [" & $sFileName & "]", 1)

	Local $sFilePath = $g_sRoutesFolder & "\" & $sFileName

	; Генерируем JSON
	Local $sJSON = _JSON_Generate($aRoute, True)
	If @error Then
		_Logger_Write("_Routes_Save: Ошибка генерации JSON", 2)
		Return False
	EndIf

	; Сохраняем в файл
	Local $hFile = FileOpen($sFilePath, 2) ; 2 = перезапись
	If $hFile = -1 Then
		_Logger_Write("_Routes_Save: Ошибка открытия файла для записи", 2)
		Return False
	EndIf

	FileWrite($hFile, $sJSON)
	FileClose($hFile)

	_Logger_Write("_Routes_Save: Маршрут сохранён: " & $sFilePath, 3)
	Return True
EndFunc

; #FUNCTION# ====================================================================
; Name ..........: _Routes_Delete
; Description ...: Удаляет файл маршрута
; Syntax ........: _Routes_Delete($sFileName)
; Parameters ....: $sFileName - имя файла
; Return values .: True - успешно, False - ошибка
; ===============================================================================
Func _Routes_Delete($sFileName)
	_Logger_Write("_Routes_Delete: Удаление маршрута [" & $sFileName & "]", 1)

	Local $sFilePath = $g_sRoutesFolder & "\" & $sFileName

	; Проверяем существование файла
	If Not FileExists($sFilePath) Then
		_Logger_Write("_Routes_Delete: Файл не найден", 2)
		Return False
	EndIf

	; Удаляем файл
	FileDelete($sFilePath)
	If @error Then
		_Logger_Write("_Routes_Delete: Ошибка удаления файла", 2)
		Return False
	EndIf

	_Logger_Write("_Routes_Delete: Маршрут удалён", 3)
	Return True
EndFunc


; ===============================================================================
; Глобальные переменные для записи маршрута
; ===============================================================================
Global $g_oCurrentRoute = ""           ; Текущий записываемый маршрут (JSON структура)
Global $g_aWaypoints = ""              ; Массив waypoints (JSON структура)
; ===============================================================================
; Функции записи маршрута
; ===============================================================================
; #FUNCTION# ====================================================================
; Name ..........: _Routes_GetCurrentCoords
; Description ...: Получает текущие координаты персонажа через OCR
; Syntax ........: _Routes_GetCurrentCoords($hWnd)
; Parameters ....: $hWnd - Handle окна игры
; Return values .: Строка "X,Y" или "" при ошибке
; ===============================================================================
Func _Routes_GetCurrentCoords($hWnd)
	_Logger_Write("_Routes_GetCurrentCoords: Получение координат...", 1)

	; Используем Full OCR для получения координат
	Local $aOCR = _Core_FullOCR($hWnd)

	If Not $aOCR[5] Then
		_Logger_Write("_Routes_GetCurrentCoords: Ошибка Full OCR", 2)
		Return ""
	EndIf

	Local $sCoords = $aOCR[3]  ; Координаты из Full OCR

	If $sCoords = "" Then
		_Logger_Write("_Routes_GetCurrentCoords: Координаты не получены", 2)
		Return ""
	EndIf

	_Logger_Write("_Routes_GetCurrentCoords: Координаты = [" & $sCoords & "]", 3)
	Return $sCoords
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_CreateNew
; Description ...: Создаёт новый маршрут и записывает первую точку
; Syntax ........: _Routes_CreateNew($sRouteName, $sCityName, $iCityY, $hWnd)
; Parameters ....: $sRouteName - Имя маршрута
;                  $sCityName - Название города
;                  $iCityY - Y координата города для телепорта (533/551/569)
;                  $hWnd - Handle окна игры
; Return values .: True/False
; ===============================================================================
Func _Routes_CreateNew($sRouteName, $sCityName, $iCityY, $hWnd)
	_Logger_Write("_Routes_CreateNew: Создание маршрута [" & $sRouteName & "]", 1)

	; Очищаем текущий маршрут
	$g_oCurrentRoute = ""
	$g_aWaypoints = ""

	; Телепортируемся в город
	_Logger_Write("_Routes_CreateNew: Телепорт в город [" & $sCityName & "] Y=" & $iCityY, 1)
	_Send_TeleportToCity($hWnd, $iCityY)

	; Ждём 3 секунды
	Sleep(3000)

	; Получаем стартовые координаты
	Local $sStartCoords = _Routes_GetCurrentCoords($hWnd)
	If $sStartCoords = "" Then
		_Logger_Write("_Routes_CreateNew: Не удалось получить стартовые координаты", 2)
		Return False
	EndIf

	; Создаём структуру маршрута (Map)
	Local $oRoute[]
	$oRoute["name"] = $sRouteName
	$oRoute["city_name"] = $sCityName
	$oRoute["city_y"] = $iCityY
	$oRoute["created"] = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC

	$g_oCurrentRoute = $oRoute

	; Добавляем первую точку (стартовая позиция)
	Local $oFirstPoint[]
	$oFirstPoint["index"] = 0
	$oFirstPoint["coords"] = $sStartCoords
	$oFirstPoint["description"] = "Стартовая позиция"

	; Создаём массив для waypoints с первой точкой
	Local $aWaypoints[1]
	$aWaypoints[0] = $oFirstPoint
	$g_aWaypoints = $aWaypoints

	_Logger_Write("_Routes_CreateNew: Маршрут создан, стартовая точка: " & $sStartCoords, 3)
	Return True
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_AddPoint
; Description ...: Добавляет новую контрольную точку в текущий маршрут
; Syntax ........: _Routes_AddPoint($hWnd, $sDescription = "")
; Parameters ....: $hWnd - Handle окна игры
;                  $sDescription - Описание точки (опционально)
; Return values .: True/False
; ===============================================================================
Func _Routes_AddPoint($hWnd, $sDescription = "")
	_Logger_Write("_Routes_AddPoint: Добавление точки...", 1)

	If $g_oCurrentRoute = "" Then
		_Logger_Write("_Routes_AddPoint: Маршрут не создан", 2)
		Return False
	EndIf

	; Получаем текущие координаты
	Local $sCoords = _Routes_GetCurrentCoords($hWnd)
	If $sCoords = "" Then
		_Logger_Write("_Routes_AddPoint: Не удалось получить координаты", 2)
		Return False
	EndIf

	; Получаем количество точек
	Local $iCount = _Routes_GetWaypointsCount()

	; Создаём новую точку (Map)
	Local $oPoint[]
	$oPoint["index"] = $iCount
	$oPoint["coords"] = $sCoords
	$oPoint["description"] = $sDescription

	; Добавляем в массив
	ReDim $g_aWaypoints[$iCount + 1]
	$g_aWaypoints[$iCount] = $oPoint

	_Logger_Write("_Routes_AddPoint: Точка #" & $iCount & " добавлена: " & $sCoords, 3)
	Return True
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_SaveToFile
; Description ...: Сохраняет текущий маршрут в JSON файл
; Syntax ........: _Routes_SaveToFile($sFileName)
; Parameters ....: $sFileName - Имя файла (без расширения)
; Return values .: True/False
; ===============================================================================
Func _Routes_SaveToFile($sFileName)
	_Logger_Write("_Routes_SaveToFile: Сохранение маршрута [" & $sFileName & "]", 1)

	If $g_oCurrentRoute = "" Then
		_Logger_Write("_Routes_SaveToFile: Маршрут не создан", 2)
		Return False
	EndIf

	; Добавляем waypoints в маршрут
	$g_oCurrentRoute["waypoints"] = $g_aWaypoints

	; Конвертируем в JSON строку с правильным форматированием
	Local $sJSON = _JSON_Generate($g_oCurrentRoute, "  ", @CRLF, "", " ", "  ", @CRLF)
	If @error Then
		_Logger_Write("_Routes_SaveToFile: Ошибка кодирования JSON", 2)
		Return False
	EndIf

	; Формируем путь к файлу
	Local $sFilePath = $g_sRoutesFolder & "\" & $sFileName & ".json"

	; Сохраняем файл
	Local $hFile = FileOpen($sFilePath, 2)
	If $hFile = -1 Then
		_Logger_Write("_Routes_SaveToFile: Ошибка создания файла", 2)
		Return False
	EndIf

	FileWrite($hFile, $sJSON)
	FileClose($hFile)

	_Logger_Write("_Routes_SaveToFile: Маршрут сохранён в [" & $sFilePath & "]", 3)

	; Очищаем текущий маршрут
	$g_oCurrentRoute = ""
	$g_aWaypoints = ""

	Return True
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_GetWaypointsCount
; Description ...: Возвращает количество точек в текущем маршруте
; Syntax ........: _Routes_GetWaypointsCount()
; Return values .: Количество точек
; ===============================================================================
Func _Routes_GetWaypointsCount()
	If Not IsArray($g_aWaypoints) Then Return 0
	Return UBound($g_aWaypoints)
EndFunc


; ===============================================================================
; Функция: _Button_MoveXPlus
; ===============================================================================
; ===============================================================================
; Обработчики кнопок навигации (тест движения)
; ===============================================================================
Func _Button_MoveXPlus()
	_GUI_AddLog("➡️ Движение X+ (вправо-вниз)")

	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	_Logger_Write("_Button_MoveXPlus: Клик на X=" & $g_iMove_XPlus_X & " Y=" & $g_iMove_XPlus_Y, 1)
	_Send_Click($g_hTargetWindow, $g_iMove_XPlus_X, $g_iMove_XPlus_Y)
	_GUI_AddLog("✅ Клик выполнен: X=" & $g_iMove_XPlus_X & " Y=" & $g_iMove_XPlus_Y)
EndFunc
Func _Button_MoveXMinus()
	_GUI_AddLog("⬅️ Движение X- (влево-вверх)")

	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	_Logger_Write("_Button_MoveXMinus: Клик на X=" & $g_iMove_XMinus_X & " Y=" & $g_iMove_XMinus_Y, 1)
	_Send_Click($g_hTargetWindow, $g_iMove_XMinus_X, $g_iMove_XMinus_Y)
	_GUI_AddLog("✅ Клик выполнен: X=" & $g_iMove_XMinus_X & " Y=" & $g_iMove_XMinus_Y)
EndFunc
Func _Button_MoveYPlus()
	_GUI_AddLog("⬆️ Движение Y+ (вправо-вверх)")

	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	_Logger_Write("_Button_MoveYPlus: Клик на X=" & $g_iMove_YPlus_X & " Y=" & $g_iMove_YPlus_Y, 1)
	_Send_Click($g_hTargetWindow, $g_iMove_YPlus_X, $g_iMove_YPlus_Y)
	_GUI_AddLog("✅ Клик выполнен: X=" & $g_iMove_YPlus_X & " Y=" & $g_iMove_YPlus_Y)
EndFunc
Func _Button_MoveYMinus()
	_GUI_AddLog("⬇️ Движение Y- (влево-вниз)")

	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	_Logger_Write("_Button_MoveYMinus: Клик на X=" & $g_iMove_YMinus_X & " Y=" & $g_iMove_YMinus_Y, 1)
	_Send_Click($g_hTargetWindow, $g_iMove_YMinus_X, $g_iMove_YMinus_Y)
	_GUI_AddLog("✅ Клик выполнен: X=" & $g_iMove_YMinus_X & " Y=" & $g_iMove_YMinus_Y)
EndFunc

; ===============================================================================
; Функция: _Move_ByAngle
; ===============================================================================
; ===============================================================================
; Функция: _Move_ByAngle
; Описание: Клик в направлении угла 0-360° с учётом изометрии MU Online
; Система координат: 0° = X+ (вправо-вниз), 90° = Y+ (вправо-вверх),
;                    180° = X- (влево-вверх), 270° = Y- (влево-вниз)
; Параметры:
;   $hWnd     - Handle окна MU Online
;   $iAngle   - Угол в градусах (0-360)
;   $fDistMult - Множитель дистанции (1.0 = стандарт)
; ===============================================================================
Func _Move_ByAngle($hWnd, $iAngle, $fDistMult = 1.0)
	; Базовые векторы из конфига (offset от центра персонажа)
	; X+ = (150, 140)  — 0°
	; Y+ = (190, -120) — 90°
	; X- = (-150, -140) — 180°
	; Y- = (-190, 120) — 270°
	Local $fVec_XP_X = 150, $fVec_XP_Y = 140   ; вектор X+
	Local $fVec_YP_X = 190, $fVec_YP_Y = -120  ; вектор Y+

	; Переводим угол в радианы
	Local $fRad = $iAngle * 3.14159265358979 / 180.0

	; Разложение угла на компоненты игровых осей:
	; gameX = cos(angle) — вклад оси X (0°=X+, 180°=X-)
	; gameY = sin(angle) — вклад оси Y (90°=Y+, 270°=Y-)
	Local $fGameX = Cos($fRad)
	Local $fGameY = Sin($fRad)

	; Экранный offset = gameX * vec_XP + gameY * vec_YP
	Local $fOffsetX = $fGameX * $fVec_XP_X + $fGameY * $fVec_YP_X
	Local $fOffsetY = $fGameX * $fVec_XP_Y + $fGameY * $fVec_YP_Y

	; Применяем множитель дистанции
	$fOffsetX = $fOffsetX * $fDistMult
	$fOffsetY = $fOffsetY * $fDistMult

	; Итоговые координаты клика
	Local $iClickX = $g_iCenter_X + Round($fOffsetX)
	Local $iClickY = $g_iCenter_Y + Round($fOffsetY)

	_Logger_Write("_Move_ByAngle: Угол=" & $iAngle & "° Mult=" & $fDistMult & " Клик X=" & $iClickX & " Y=" & $iClickY & " (offset " & Round($fOffsetX) & "," & Round($fOffsetY) & ")", 1)
	_Send_Click($hWnd, $iClickX, $iClickY)

	Return True
EndFunc

; ===============================================================================
; Функция: _Button_MoveByAngle
; Описание: Обработчик кнопки "По углу" — тест навигации 360°
; ===============================================================================
Func _Button_MoveByAngle()
	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	Local $iAngle = Int(GUICtrlRead($g_idInput_MoveAngle))
	Local $fMult = Number(GUICtrlRead($g_idInput_DistMult))

	; Валидация угла
	If $iAngle < 0 Or $iAngle > 360 Then
		_GUI_AddLog("❌ Угол должен быть от 0 до 360")
		Return
	EndIf

	; Валидация множителя
	If $fMult <= 0 Or $fMult > 10 Then
		_GUI_AddLog("❌ Множитель должен быть от 0.1 до 10")
		Return
	EndIf

	_GUI_AddLog("🧭 Движение по углу " & $iAngle & "° × " & $fMult)
	_Move_ByAngle($g_hTargetWindow, $iAngle, $fMult)
	_GUI_AddLog("✅ Клик выполнен (угол=" & $iAngle & "° mult=" & $fMult & ")")
EndFunc

; ===============================================================================
; Обработчики автопилота
; ===============================================================================
Func _Button_AutopilotStart()
	_Logger_Write("_Button_AutopilotStart: Запуск автопилота", 1)

	; Считываем настройки из input полей (если валидное число)
	Local $sMinLevel = GUICtrlRead($g_idInput_MinLevel)
	If StringIsInt($sMinLevel) And Number($sMinLevel) > 0 Then
		$g_iAutopilot_MinLevel = Number($sMinLevel)
	EndIf

	Local $sCorrInterval = GUICtrlRead($g_idInput_CorrInterval)
	If StringIsInt($sCorrInterval) And Number($sCorrInterval) > 0 Then
		$g_iAutopilot_CorrectionInterval = Number($sCorrInterval)
	EndIf

	Local $sResetWait = GUICtrlRead($g_idInput_ResetWait)
	If StringIsInt($sResetWait) And Number($sResetWait) >= 0 Then
		$g_iAutopilot_ResetWaitTime = Number($sResetWait)
	EndIf

	Local $sReturnTolerance = GUICtrlRead($g_idInput_ReturnTolerance)
	If StringIsInt($sReturnTolerance) And Number($sReturnTolerance) > 0 Then
		$g_iAutopilot_ReturnTolerance = Number($sReturnTolerance)
	EndIf

	Local $sCorrTolerance = GUICtrlRead($g_idInput_CorrTolerance)
	If StringIsInt($sCorrTolerance) And Number($sCorrTolerance) > 0 Then
		$g_iAutopilot_CorrectionTolerance = Number($sCorrTolerance)
	EndIf

	Local $sMaxFails = GUICtrlRead($g_idInput_MaxRouteFails)
	If StringIsInt($sMaxFails) And Number($sMaxFails) > 0 Then
		$g_iAutopilot_MaxRouteFails = Number($sMaxFails)
	EndIf

	Local $sClicksPerCycle = GUICtrlRead($g_idInput_ClicksPerCycle)
	If StringIsInt($sClicksPerCycle) And Number($sClicksPerCycle) > 0 Then
		$g_iMove_ClicksPerCycle = Number($sClicksPerCycle)
	EndIf

	Local $sMoveTimeout = GUICtrlRead($g_idInput_MoveTimeout)
	If StringIsInt($sMoveTimeout) And Number($sMoveTimeout) > 0 Then
		$g_iMove_Timeout = Number($sMoveTimeout)
	EndIf

	; Ник персонажа
	Local $sCharName = GUICtrlRead($g_idInput_CharName)
	If StringLen($sCharName) > 0 Then
		$g_sTargetCharacterName = $sCharName
	EndIf

	; Авто-статы
	$g_bAutoAddStats = (GUICtrlRead($g_idCheck_AutoStats) = $GUI_CHECKED)
	If $g_bAutoAddStats Then
		Local $sSTR = GUICtrlRead($g_idInput_STR)
		If StringIsInt($sSTR) Then $g_iAutoAddStats_STR = Number($sSTR)
		Local $sAGI = GUICtrlRead($g_idInput_AGI)
		If StringIsInt($sAGI) Then $g_iAutoAddStats_AGI = Number($sAGI)
		Local $sVIT = GUICtrlRead($g_idInput_VIT)
		If StringIsInt($sVIT) Then $g_iAutoAddStats_VIT = Number($sVIT)
		Local $sENE = GUICtrlRead($g_idInput_ENE)
		If StringIsInt($sENE) Then $g_iAutoAddStats_ENE = Number($sENE)
		Local $sCMD = GUICtrlRead($g_idInput_CMD)
		If StringIsInt($sCMD) Then $g_iAutoAddStats_CMD = Number($sCMD)
	EndIf

	; Множитель дистанции клика
	Local $sDistMult = GUICtrlRead($g_idInput_DistMult_AP)
	If Number($sDistMult) > 0 And Number($sDistMult) <= 10 Then
		$g_fMove_DistMult = Number($sDistMult)
	EndIf

	_GUI_AddLog("🤖 Автопилот запущен | Уровень: " & $g_iAutopilot_MinLevel & " | Корр: " & $g_iAutopilot_CorrectionInterval & "с | Возврат: " & $g_iAutopilot_ReturnTolerance & " | Попыток: " & $g_iAutopilot_MaxRouteFails)

	$g_bAutopilotEnabled = True
	$g_iAutopilot_State = 0
	$g_iAutopilot_RouteFailCount = 0
	$g_iAutopilot_LastCheckTime = TimerInit()
	$g_iAutopilot_LastLevelTime = TimerInit()

	; Управление кнопками
	GUICtrlSetState($g_idBtn_AutopilotStart, $GUI_DISABLE)
	GUICtrlSetState($g_idBtn_AutopilotStop, $GUI_ENABLE)
EndFunc

Func _Button_AutopilotStop()
	_Logger_Write("_Button_AutopilotStop: Остановка автопилота", 1)
	_GUI_AddLog("🤖 Автопилот остановлен")

	$g_bAutopilotEnabled = False
	$g_iAutopilot_State = 0

	; Управление кнопками
	GUICtrlSetState($g_idBtn_AutopilotStart, $GUI_ENABLE)
	GUICtrlSetState($g_idBtn_AutopilotStop, $GUI_DISABLE)
EndFunc

; ===============================================================================
; Обработчики для выполнения маршрутов
; ===============================================================================
Func _Button_StopRoute()
	_Logger_Write("_Button_StopRoute: Запрос остановки маршрута", 1)
	_GUI_AddLog("⏹️ Запрос остановки маршрута...")

	$g_bRouteStopRequested = True
EndFunc

Func _Button_RefreshRoutes()
	_Logger_Write("_Button_RefreshRoutes: Обновление списка маршрутов", 1)

	; Получаем список маршрутов
	Local $aRoutes = _Routes_GetList()

	If @error Or UBound($aRoutes) = 0 Then
		_Logger_Write("_Button_RefreshRoutes: Маршруты не найдены", 2)
		GUICtrlSetData($g_idCombo_RouteSelect, "")
		Return
	EndIf

	; Формируем строку для Combo
	Local $sRoutesList = ""
	For $i = 0 To UBound($aRoutes) - 1
		If $i > 0 Then $sRoutesList &= "|"
		$sRoutesList &= $aRoutes[$i]
	Next

	; Загружаем последний выбранный маршрут
	Local $sLastRoute = _Config_LoadLastRoute()
	Local $sDefaultRoute = ""

	; Проверяем существует ли последний маршрут в списке
	If $sLastRoute <> "" Then
		For $i = 0 To UBound($aRoutes) - 1
			If $aRoutes[$i] = $sLastRoute Then
				$sDefaultRoute = $sLastRoute
				ExitLoop
			EndIf
		Next
	EndIf

	; Если не нашли последний маршрут, берём первый
	If $sDefaultRoute = "" And UBound($aRoutes) > 0 Then
		$sDefaultRoute = $aRoutes[0]
	EndIf

	; Очищаем и обновляем Combo
	GUICtrlSetData($g_idCombo_RouteSelect, "", "")
	GUICtrlSetData($g_idCombo_RouteSelect, $sRoutesList, $sDefaultRoute)

	_Logger_Write("_Button_RefreshRoutes: Загружено маршрутов: " & UBound($aRoutes), 3)
	If $sDefaultRoute <> "" Then
		_Logger_Write("_Button_RefreshRoutes: Выбран маршрут: " & $sDefaultRoute, 1)
	EndIf
EndFunc

; ===============================================================================
; Функция: _Combo_RouteSelect_Changed
; ===============================================================================
; ===============================================================================
; Функция: _Combo_RouteSelect_Changed
; Описание: Обработчик изменения выбора маршрута
; ===============================================================================
Func _Combo_RouteSelect_Changed()
	Local $sSelectedRoute = GUICtrlRead($g_idCombo_RouteSelect)
	If $sSelectedRoute <> "" Then
		_Config_SaveLastRoute($sSelectedRoute)
		_Logger_Write("_Combo_RouteSelect_Changed: Выбран маршрут: " & $sSelectedRoute, 1)
	EndIf
EndFunc

Func _Button_ExecuteRoute()
	; Мини обёртка - только устанавливаем флаг для запуска в основном цикле
	If $g_bRouteExecuting Then
		_GUI_AddLog("⚠️ Маршрут уже выполняется!")
		Return
	EndIf

	$g_bRouteExecuting = True
	$g_bRouteStopRequested = False

	; Управление кнопками
	GUICtrlSetState($g_idBtn_ExecuteRoute, $GUI_DISABLE)
	GUICtrlSetState($g_idBtn_StopRoute, $GUI_ENABLE)

	_Logger_Write("_Button_ExecuteRoute: Запуск маршрута в основном цикле", 1)
EndFunc

; ===============================================================================
; Функция выполнения маршрута (вызывается из основного цикла)
; ===============================================================================
Func _Routes_ExecuteRoute()
	_GUI_AddLog("=== ВЫПОЛНЕНИЕ МАРШРУТА ===")

	If $g_hTargetWindow = 0 Then
		_GUI_AddLog("❌ Ошибка: Окно не выбрано!")
		Return
	EndIf

	; Устанавливаем флаги выполнения
	$g_bRouteExecuting = True
	$g_bRouteStopRequested = False

	; Управление кнопками
	GUICtrlSetState($g_idBtn_ExecuteRoute, $GUI_DISABLE)
	GUICtrlSetState($g_idBtn_StopRoute, $GUI_ENABLE)

	; Получаем выбранный маршрут
	Local $sSelectedRoute = GUICtrlRead($g_idCombo_RouteSelect)

	If $sSelectedRoute = "" Then
		_GUI_AddLog("❌ Ошибка: Выберите маршрут из списка!")
		_Route_Cleanup()
		Return
	EndIf

	_GUI_AddLog("📍 Выбран маршрут: " & $sSelectedRoute)

	; Загружаем маршрут
	Local $oRoute = _Routes_Load($sSelectedRoute)

	If @error Or $oRoute = "" Then
		_GUI_AddLog("❌ Ошибка загрузки маршрута!")
		Return
	EndIf

	; Выводим информацию о маршруте
	_GUI_AddLog("🏙️ Город: " & $oRoute["city_name"] & " (Y=" & $oRoute["city_y"] & ")")
	_GUI_AddLog("📊 Точек в маршруте: " & UBound($oRoute["waypoints"]))

	; Телепортируемся в город
	_GUI_AddLog("🚀 Телепорт в " & $oRoute["city_name"] & "...")
	_Send_Click($g_hTargetWindow, 812, 540, True)
	Sleep(200)
	_Send_TeleportToCity($g_hTargetWindow, $oRoute["city_y"])
	Sleep(1000)  ; Ждём завершения телепорта

	; Проверяем чекбокс "Включить Helper на старте"
	If BitAND(GUICtrlRead($g_idCheck_HelperOnStart), $GUI_CHECKED) = $GUI_CHECKED Then
		_GUI_AddLog("🤖 Активация Helper Bot на старте...")

		; Получаем Full OCR для проверки маркера
		Local $aOCR_Start = _Core_FullOCR($g_hTargetWindow)

		If $aOCR_Start[5] = True Then
			Local $oMarkers_Start = _JSON_Parse($aOCR_Start[4])

			If Not @error Then
				Local $iCount_Start = _JSON_Get($oMarkers_Start, "[count]")

				For $m = 0 To $iCount_Start - 1
					Local $sMarkerName_Start = _JSON_Get($oMarkers_Start, "[markers][" & $m & "][name]")

					If $sMarkerName_Start = "helper_active" Then
						Local $iHelperActive_Start = _JSON_Get($oMarkers_Start, "[markers][" & $m & "][value]")

						If $iHelperActive_Start = 0 Then
							_GUI_AddLog("⚠️ Helper Bot выключен, активирую.....")
							_Send_Click($g_hTargetWindow, 812, 540, True)
							Sleep(200)
							_Send_Click($g_hTargetWindow, 565, 870, False)
							Sleep(500)
							_Send_Click($g_hTargetWindow, 812, 540, True)
							Sleep(200)
							; Проверка активации
							Local $aOCR_StartCheck = _Core_FullOCR($g_hTargetWindow)

							If $aOCR_StartCheck[5] = True Then
								Local $oMarkers_StartCheck = _JSON_Parse($aOCR_StartCheck[4])

								If Not @error Then
									Local $iCount_StartCheck = _JSON_Get($oMarkers_StartCheck, "[count]")

									For $n = 0 To $iCount_StartCheck - 1
										Local $sMarkerName_StartCheck = _JSON_Get($oMarkers_StartCheck, "[markers][" & $n & "][name]")

										If $sMarkerName_StartCheck = "helper_active" Then
											Local $iHelperActive_StartCheck = _JSON_Get($oMarkers_StartCheck, "[markers][" & $n & "][value]")

											If $iHelperActive_StartCheck = 1 Then
												_GUI_AddLog("✅ Helper Bot активирован на старте!")
											Else
												_GUI_AddLog("❌ Не удалось активировать Helper Bot на старте")
											EndIf
											ExitLoop
										EndIf
									Next
								EndIf
							EndIf
						Else
							_GUI_AddLog("✅ Helper Bot уже активен")
						EndIf
						ExitLoop
					EndIf
				Next
			EndIf
		EndIf
	EndIf

	; Проходим по всем точкам маршрута
	Local $aWaypoints = $oRoute["waypoints"]

	For $i = 0 To UBound($aWaypoints) - 1
		; Проверка флага остановки
		If $g_bRouteStopRequested Then
			_GUI_AddLog("⏹️ Маршрут прерван пользователем")
			_Route_Cleanup()
			Return
		EndIf

		; Обработка событий GUI для реакции на кнопку "Прервать"
		Sleep(10)

		Local $oPoint = $aWaypoints[$i]
		Local $sTargetCoords = $oPoint["coords"]
		Local $sDescription = $oPoint["description"]

		_GUI_AddLog("📍 Точка #" & $i & ": " & $sDescription & " (" & $sTargetCoords & ")")

		; Пропускаем первую точку (стартовая позиция)
		If $i = 0 Then
			_GUI_AddLog("⏭️ Пропуск стартовой точки")
			ContinueLoop
		EndIf

		; Движемся к точке
		Local $bResult = _Routes_MoveToCoords($g_hTargetWindow, $sTargetCoords)

		If $bResult Then
			_GUI_AddLog("✅ Точка #" & $i & " достигнута!")
		Else
			_GUI_AddLog("❌ Не удалось достичь точки #" & $i & " (таймаут)")
			_GUI_AddLog("⚠️ Выполнение маршрута прервано")
			_Route_Cleanup()
			Return
		EndIf
	Next

	_GUI_AddLog("🎉 Маршрут выполнен полностью!")

	; Активация Helper Bot после завершения маршрута
	_GUI_AddLog("🤖 Проверка Helper Bot...")

	; Получаем Full OCR для проверки маркера
	Local $aOCR = _Core_FullOCR($g_hTargetWindow)

	_GUI_AddLog("🔍 DEBUG: aOCR[5] = " & $aOCR[5])

	If $aOCR[5] = True Then
		_GUI_AddLog("🔍 DEBUG: Full OCR успешен")
		_GUI_AddLog("🔍 DEBUG: JSON строка = " & $aOCR[4])
		_GUI_AddLog("🔍 DEBUG: Тип aOCR[4] = " & VarGetType($aOCR[4]))

		; Парсим JSON маркеров
		Local $oMarkers = _JSON_Parse($aOCR[4])

		_GUI_AddLog("🔍 DEBUG: @error = " & @error)

		If Not @error Then
			_GUI_AddLog("🔍 DEBUG: JSON распарсен успешно")

			; Получаем количество маркеров
			Local $iCount = _JSON_Get($oMarkers, "[count]")

			_GUI_AddLog("🔍 DEBUG: Найдено маркеров: " & $iCount)

			; Ищем helper_active в массиве
			Local $iHelperActive = -1

			For $j = 0 To $iCount - 1
				Local $sMarkerName = _JSON_Get($oMarkers, "[markers][" & $j & "][name]")

				If $sMarkerName = "helper_active" Then
					$iHelperActive = _JSON_Get($oMarkers, "[markers][" & $j & "][value]")
					_GUI_AddLog("🔍 DEBUG: helper_active = " & $iHelperActive)
					ExitLoop
				EndIf
			Next

			If $iHelperActive = 0 Then
				_GUI_AddLog("⚠️ Helper Bot выключен, активирую...")

				; Клик по кнопке Helper Bot (565, 870)
				_Send_Click($g_hTargetWindow, 812, 540, False)
				Sleep(200)
				_Send_Click($g_hTargetWindow, 565, 870, False)
				Sleep(1000)
				_Send_Click($g_hTargetWindow, 812, 540, False)
				Sleep(100)
				; Повторная проверка
				Local $aOCR_Check = _Core_FullOCR($g_hTargetWindow)

				If $aOCR_Check[5] = True Then
					Local $oMarkers_Check = _JSON_Parse($aOCR_Check[4])

					If Not @error Then
						Local $iCount_Check = _JSON_Get($oMarkers_Check, "[count]")

						For $k = 0 To $iCount_Check - 1
							Local $sMarkerName_Check = _JSON_Get($oMarkers_Check, "[markers][" & $k & "][name]")

							If $sMarkerName_Check = "helper_active" Then
								Local $iHelperActive_Check = _JSON_Get($oMarkers_Check, "[markers][" & $k & "][value]")

								If $iHelperActive_Check = 1 Then
									_GUI_AddLog("✅ Helper Bot активирован успешно!")
								Else
									_GUI_AddLog("❌ Не удалось активировать Helper Bot (статус: " & $iHelperActive_Check & ")")
								EndIf
								ExitLoop
							EndIf
						Next
					Else
						_GUI_AddLog("❌ Ошибка парсинга JSON при повторной проверке")
					EndIf
				Else
					_GUI_AddLog("❌ Ошибка Full OCR при повторной проверке")
				EndIf
			ElseIf $iHelperActive = 1 Then
				_GUI_AddLog("✅ Helper Bot уже активен")
			Else
				_GUI_AddLog("❌ Маркер helper_active не найден")
			EndIf
		Else
			_GUI_AddLog("❌ Ошибка парсинга JSON маркеров")
		EndIf
	Else
		_GUI_AddLog("❌ Ошибка проверки маркеров (Full OCR failed)")
	EndIf

	_GUI_AddLog("=== ЗАВЕРШЕНО ===")

	; Очистка флагов и восстановление кнопок
	_Route_Cleanup()
EndFunc

; ===============================================================================
; Функция очистки после выполнения маршрута
; ===============================================================================
Func _Route_Cleanup()
	$g_bRouteExecuting = False
	$g_bRouteStopRequested = False

	GUICtrlSetState($g_idBtn_ExecuteRoute, $GUI_ENABLE)
	GUICtrlSetState($g_idBtn_StopRoute, $GUI_DISABLE)

	_Logger_Write("_Route_Cleanup: Флаги сброшены, кнопки восстановлены", 3)
EndFunc

; ===============================================================================
; Основная функция автопилота (вызывается каждую секунду)
; ===============================================================================
Func _Autopilot_Process()
	; Проверка что маршрут не выполняется (кроме состояния 1)
	If $g_bRouteExecuting And $g_iAutopilot_State <> 1 Then
		Return
	EndIf

	; Получаем Full OCR
	Local $aOCR = _Core_FullOCR($g_hTargetWindow)

	If Not $aOCR[5] Then
		_Logger_Write("_Autopilot_Process: Ошибка Full OCR", 2)
		Return
	EndIf

	; Парсим данные
	Local $sCurrentCoords = $aOCR[3]  ; Координаты "X,Y"
	Local $iCurrentLevel = Number($aOCR[1])  ; Уровень
	Local $sMarkersJSON = $aOCR[4]  ; JSON маркеров

	; Обновляем GUI с текущим уровнем
	GUICtrlSetData($g_idLabel_CurrentLevel, "Текущий уровень: " & $iCurrentLevel)

	; Обновляем статистику DPS
	_Autopilot_UpdateDPS($iCurrentLevel)

	; Получаем конечную точку маршрута
	Local $sSelectedRoute = GUICtrlRead($g_idCombo_RouteSelect)
	If $sSelectedRoute = "" Then
		_Logger_Write("_Autopilot_Process: Маршрут не выбран", 2)
		Return
	EndIf

	Local $oRoute = _Routes_Load($sSelectedRoute)
	If @error Or $oRoute = "" Then
		_Logger_Write("_Autopilot_Process: Ошибка загрузки маршрута", 2)
		Return
	EndIf

	Local $aWaypoints = $oRoute["waypoints"]
	Local $oLastPoint = $aWaypoints[UBound($aWaypoints) - 1]
	Local $sTargetCoords = $oLastPoint["coords"]

	; Вычисляем расстояние до конечной точки
	Local $iDistance = _Autopilot_GetDistance($sCurrentCoords, $sTargetCoords)

	; Обработка состояний
	Switch $g_iAutopilot_State
		Case 0  ; Ожидание (на споте)
			_Autopilot_State_Waiting($iCurrentLevel, $sCurrentCoords, $sTargetCoords, $iDistance, $sMarkersJSON)

		Case 1  ; Ожидание выполнения маршрута
			_Autopilot_State_WaitingRoute($iDistance)

		Case 2  ; Корректировка позиции
			_Autopilot_State_Correction($sCurrentCoords, $sTargetCoords)

		Case 3  ; Выполнение авторесета
			_Autopilot_State_Reset()
	EndSwitch
EndFunc


; ===============================================================================
; Функция: _Routes_CalculateDirection
; ===============================================================================
; ===============================================================================
; Функции навигации
; ===============================================================================
; #FUNCTION# ====================================================================
; Name ..........: _Routes_CalculateDirection
; Description ...: Вычисляет направление движения по разнице координат
; Syntax ........: _Routes_CalculateDirection($sCurrentCoords, $sTargetCoords)
; Parameters ....: $sCurrentCoords - текущие координаты "X,Y"
;                  $sTargetCoords - целевые координаты "X,Y"
; Return values .: Массив [X_клика, Y_клика, "направление"] или False при ошибке
; ===============================================================================
Func _Routes_CalculateDirection($sCurrentCoords, $sTargetCoords)
	_Logger_Write("_Routes_CalculateDirection: Текущие=" & $sCurrentCoords & " Целевые=" & $sTargetCoords, 1)

	; Парсим координаты
	Local $aCurrent = StringSplit($sCurrentCoords, ",", 2)
	Local $aTarget = StringSplit($sTargetCoords, ",", 2)

	If UBound($aCurrent) < 2 Or UBound($aTarget) < 2 Then
		_Logger_Write("_Routes_CalculateDirection: Ошибка парсинга координат", 2)
		Return False
	EndIf

	; Вычисляем дельту
	Local $iDeltaX = Number($aTarget[0]) - Number($aCurrent[0])
	Local $iDeltaY = Number($aTarget[1]) - Number($aCurrent[1])

	_Logger_Write("_Routes_CalculateDirection: ΔX=" & $iDeltaX & " ΔY=" & $iDeltaY, 1)

	; Вычисляем угол через ATan2 (0°=X+, 90°=Y+, 180°=X-, 270°=Y-)
	Local $fAngleRad = ATan($iDeltaY / ($iDeltaX = 0 ? 0.0001 : $iDeltaX))
	; Корректируем квадрант вручную (ATan2 через ATan)
	Local $fAngleDeg
	If $iDeltaX >= 0 Then
		$fAngleDeg = $fAngleRad * 180.0 / 3.14159265358979
	Else
		$fAngleDeg = $fAngleRad * 180.0 / 3.14159265358979 + 180.0
	EndIf
	If $fAngleDeg < 0 Then $fAngleDeg += 360.0
	Local $iAngle = Round($fAngleDeg)

	; Определяем направление по большей разнице (для совместимости)
	Local $aResult[4]

	If Abs($iDeltaX) > Abs($iDeltaY) Then
		If $iDeltaX > 0 Then
			$aResult[0] = $g_iMove_XPlus_X
			$aResult[1] = $g_iMove_XPlus_Y
			$aResult[2] = "X+"
		Else
			$aResult[0] = $g_iMove_XMinus_X
			$aResult[1] = $g_iMove_XMinus_Y
			$aResult[2] = "X-"
		EndIf
	Else
		If $iDeltaY > 0 Then
			$aResult[0] = $g_iMove_YPlus_X
			$aResult[1] = $g_iMove_YPlus_Y
			$aResult[2] = "Y+"
		Else
			$aResult[0] = $g_iMove_YMinus_X
			$aResult[1] = $g_iMove_YMinus_Y
			$aResult[2] = "Y-"
		EndIf
	EndIf

	$aResult[3] = $iAngle  ; 🧭 Точный угол для _Move_ByAngle

	_Logger_Write("_Routes_CalculateDirection: Направление=" & $aResult[2] & " Угол=" & $iAngle & "° Клик X=" & $aResult[0] & " Y=" & $aResult[1], 3)
	Return $aResult
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_IsNearCoords
; Description ...: Проверяет достигли ли целевых координат
; Syntax ........: _Routes_IsNearCoords($sCoords1, $sCoords2, $iTolerance = 5)
; Parameters ....: $sCoords1 - координаты 1 "X,Y"
;                  $sCoords2 - координаты 2 "X,Y"
;                  $iTolerance - допуск в пикселях (по умолчанию 5)
; Return values .: True если близко, False если далеко
; ===============================================================================
Func _Routes_IsNearCoords($sCoords1, $sCoords2, $iTolerance = 5)
	Local $aCoords1 = StringSplit($sCoords1, ",", 2)
	Local $aCoords2 = StringSplit($sCoords2, ",", 2)

	If UBound($aCoords1) < 2 Or UBound($aCoords2) < 2 Then Return False

	Local $iDeltaX = Abs(Number($aCoords1[0]) - Number($aCoords2[0]))
	Local $iDeltaY = Abs(Number($aCoords1[1]) - Number($aCoords2[1]))

	Return ($iDeltaX <= $iTolerance And $iDeltaY <= $iTolerance)
EndFunc
; #FUNCTION# ====================================================================
; Name ..........: _Routes_MoveToCoords
; Description ...: Движение к целевым координатам с проверкой достижения
; Syntax ........: _Routes_MoveToCoords($hWnd, $sTargetCoords)
; Parameters ....: $hWnd - Handle окна игры
;                  $sTargetCoords - целевые координаты "X,Y"
; Return values .: True если достигли, False если таймаут
; ===============================================================================
Func _Routes_MoveToCoords($hWnd, $sTargetCoords)
	_Logger_Write("_Routes_MoveToCoords: Движение к координатам [" & $sTargetCoords & "]", 1)

	Local $iStartTime = TimerInit()
	Local $iMaxTime = $g_iMove_Timeout * 1000  ; Конвертируем в миллисекунды

	While TimerDiff($iStartTime) < $iMaxTime
		; Проверка флага остановки
		If $g_bRouteStopRequested Then
			_Logger_Write("_Routes_MoveToCoords: Остановка по запросу пользователя", 1)
			Return False
		EndIf

		; 1. Получаем текущие координаты через Full OCR
		Local $sCurrentCoords = _Routes_GetCurrentCoords($hWnd)

		If $sCurrentCoords = "" Then
			_Logger_Write("_Routes_MoveToCoords: Ошибка получения координат", 2)
			Sleep($g_iMove_CheckDelay)
			ContinueLoop
		EndIf

		_Logger_Write("_Routes_MoveToCoords: Текущие=" & $sCurrentCoords & " Целевые=" & $sTargetCoords, 1)

		; 2. Проверяем достигли ли цели
		If _Routes_IsNearCoords($sCurrentCoords, $sTargetCoords, $g_iMove_CoordsTolerance) Then
			_Logger_Write("_Routes_MoveToCoords: Цель достигнута!", 3)
			Return True
		EndIf

		; 3. Вычисляем направление
		Local $aDirection = _Routes_CalculateDirection($sCurrentCoords, $sTargetCoords)

		If Not IsArray($aDirection) Then
			_Logger_Write("_Routes_MoveToCoords: Ошибка вычисления направления", 2)
			Sleep($g_iMove_CheckDelay)
			ContinueLoop
		EndIf

		; 4. Делаем N кликов через _Move_ByAngle с множителем дистанции
		_Logger_Write("_Routes_MoveToCoords: Делаю " & $g_iMove_ClicksPerCycle & " кликов в направлении " & $aDirection[2] & " угол=" & $aDirection[3] & "° mult=" & $g_fMove_DistMult, 1)

		For $i = 1 To $g_iMove_ClicksPerCycle
			_Move_ByAngle($hWnd, $aDirection[3], $g_fMove_DistMult)
			Sleep(100)  ; Небольшая задержка между кликами
		Next

		; 5. Ждём перед следующей проверкой
		Sleep($g_iMove_CheckDelay)
	WEnd

	; Таймаут - не достигли цели
	_Logger_Write("_Routes_MoveToCoords: Таймаут! Не удалось достичь координат за " & $g_iMove_Timeout & " сек", 2)
	Return False
EndFunc

; ===============================================================================
; Вспомогательные функции автопилота
; ===============================================================================

; Обновление статистики DPS
Func _Autopilot_UpdateDPS($iCurrentLevel)
	If $iCurrentLevel <> $g_iAutopilot_LastLevel And $g_iAutopilot_LastLevel > 0 Then
		Local $fTimeDiff = TimerDiff($g_iAutopilot_LastLevelTime) / 1000 / 60  ; В минутах
		If $fTimeDiff > 0 Then
			Local $iLevelDiff = $iCurrentLevel - $g_iAutopilot_LastLevel
			Local $fCurrentDPS = $iLevelDiff / $fTimeDiff

			; Добавляем текущее измерение в массив истории
			$g_aAutopilot_DPS_History[$g_iAutopilot_DPS_HistoryIndex] = $fCurrentDPS
			$g_iAutopilot_DPS_HistoryIndex = Mod($g_iAutopilot_DPS_HistoryIndex + 1, 10)

			; Увеличиваем счётчик записей (максимум 10)
			If $g_iAutopilot_DPS_HistoryCount < 10 Then
				$g_iAutopilot_DPS_HistoryCount += 1
			EndIf

			; Вычисляем среднее значение по всем записям
			Local $fSum = 0
			For $i = 0 To $g_iAutopilot_DPS_HistoryCount - 1
				$fSum += $g_aAutopilot_DPS_History[$i]
			Next
			$g_fAutopilot_LevelPerMinute = $fSum / $g_iAutopilot_DPS_HistoryCount

			; Обновляем GUI
			GUICtrlSetData($g_idLabel_LevelPerMin, "Уровней/мин: " & StringFormat("%.1f", $g_fAutopilot_LevelPerMinute))
		EndIf

		$g_iAutopilot_LastLevel = $iCurrentLevel
		$g_iAutopilot_LastLevelTime = TimerInit()
	ElseIf $g_iAutopilot_LastLevel = 0 Then
		$g_iAutopilot_LastLevel = $iCurrentLevel
		$g_iAutopilot_LastLevelTime = TimerInit()
	EndIf
EndFunc

; Вычисление расстояния между координатами
Func _Autopilot_GetDistance($sCoords1, $sCoords2)
	Local $aCoords1 = StringSplit($sCoords1, ",", 2)
	Local $aCoords2 = StringSplit($sCoords2, ",", 2)

	If UBound($aCoords1) <> 2 Or UBound($aCoords2) <> 2 Then Return 9999

	Local $iDeltaX = Abs(Number($aCoords1[0]) - Number($aCoords2[0]))
	Local $iDeltaY = Abs(Number($aCoords1[1]) - Number($aCoords2[1]))

	Return ($iDeltaX > $iDeltaY) ? $iDeltaX : $iDeltaY
EndFunc

; Состояние 0: Ожидание (на споте)
Func _Autopilot_State_Waiting($iCurrentLevel, $sCurrentCoords, $sTargetCoords, $iDistance, $sMarkersJSON)
		; 0. Проверка условий авторесета
	If BitAND(GUICtrlRead($g_idCheck_AutoReset), $GUI_CHECKED) = $GUI_CHECKED Then
		If $iCurrentLevel >= $g_iAutopilot_MinLevel Then
			_GUI_AddLog("🤖 Авторесет: уровень " & $iCurrentLevel & " >= " & $g_iAutopilot_MinLevel)
			$g_iAutopilot_State = 3
			Return
		EndIf
	EndIf

	; 1. Проверка позиции
	If $iDistance > $g_iAutopilot_ReturnTolerance Then
		; Автовозврат
		If BitAND(GUICtrlRead($g_idCheck_AutoReturn), $GUI_CHECKED) = $GUI_CHECKED Then
			_GUI_AddLog("🤖 Автовозврат: расстояние " & $iDistance & " > " & $g_iAutopilot_ReturnTolerance)
			$g_bRouteExecuting = True
			$g_iAutopilot_State = 1
			Return
		EndIf
	ElseIf $iDistance > $g_iAutopilot_CorrectionTolerance Then
		; Корректировка позиции
		If BitAND(GUICtrlRead($g_idCheck_PositionCorrection), $GUI_CHECKED) = $GUI_CHECKED Then
			If TimerDiff($g_iAutopilot_LastCheckTime) >= ($g_iAutopilot_CorrectionInterval * 1000) Then
				_GUI_AddLog("🤖 Корректировка: расстояние " & $iDistance)
				$g_iAutopilot_State = 2
				Return
			EndIf
		EndIf
	EndIf

	; 2. Проверка Helper Bot (только если на конечной точке)
	If $iDistance <= $g_iAutopilot_CorrectionTolerance Then
		_Autopilot_CheckHelper($sMarkersJSON)
	EndIf


EndFunc

; Состояние 1: Ожидание выполнения маршрута
Func _Autopilot_State_WaitingRoute($iDistance)
	If Not $g_bRouteExecuting Then
		; Маршрут завершён, проверяем позицию
		If $iDistance <= 10 Then
			_GUI_AddLog("🤖 Маршрут выполнен, возврат к ожиданию")
			$g_iAutopilot_State = 0
			$g_iAutopilot_RouteFailCount = 0
		Else
			; Маршрут не выполнен
			$g_iAutopilot_RouteFailCount += 1
			_GUI_AddLog("🤖 Маршрут не выполнен (попытка " & $g_iAutopilot_RouteFailCount & "/" & $g_iAutopilot_MaxRouteFails & ")")

			If $g_iAutopilot_RouteFailCount >= $g_iAutopilot_MaxRouteFails Then
				_GUI_AddLog("❌ Автопилот остановлен: превышено количество неудачных попыток")
				_Button_AutopilotStop()
			Else
				; Повторная попытка через 2 сек
				Sleep(2000)
				$g_bRouteExecuting = True
			EndIf
		EndIf
	EndIf
EndFunc

; Состояние 2: Корректировка позиции
Func _Autopilot_State_Correction($sCurrentCoords, $sTargetCoords)
	_Logger_Write("_Autopilot_State_Correction: Корректировка позиции", 1)

	; Вычисляем направление
	Local $aDirection = _Routes_CalculateDirection($sCurrentCoords, $sTargetCoords)

	If IsArray($aDirection) Then
		; Делаем 3 клика через _Move_ByAngle с множителем дистанции 🧭
		For $i = 1 To 3
			_Move_ByAngle($g_hTargetWindow, $aDirection[3], $g_fMove_DistMult)
			Sleep(100)
		Next

		_GUI_AddLog("🤖 Корректировка выполнена (3 клика, угол=" & $aDirection[3] & "° mult=" & $g_fMove_DistMult & ")")
	EndIf

	$g_iAutopilot_LastCheckTime = TimerInit()
	$g_iAutopilot_State = 0
EndFunc

; Состояние 3: Выполнение авторесета
Func _Autopilot_State_Reset()
	_Logger_Write("_Autopilot_State_Reset: Выполнение авторесета", 1)
	_GUI_AddLog("🤖 Выполнение авторесета...")

	; Вызываем функцию ресета
	_Button_Reset()

	; Обновляем счётчик
	$g_iAutopilot_ResetCount += 1
	GUICtrlSetData($g_idLabel_ResetCount, "Ресетов: " & $g_iAutopilot_ResetCount)

	; Ждём 2 секунды после ресета
	Sleep($g_iAutopilot_ResetWaitTime * 1000)

	; Авто-распределение статов если включено
	If $g_bAutoAddStats Then
		_GUI_AddLog("📊 Распределение статов...")
		_Logger_Write("_Autopilot_State_Reset: Распределение статов", 1)
		_Send_Add_Stats($g_hTargetWindow, $g_iAutoAddStats_STR, $g_iAutoAddStats_AGI, $g_iAutoAddStats_VIT, $g_iAutoAddStats_ENE, $g_iAutoAddStats_CMD)
		_GUI_AddLog("📊 Статы распределены")
	EndIf

	; Проверяем чекбокс перезапуска
	If BitAND(GUICtrlRead($g_idCheck_RestartAfterReset), $GUI_CHECKED) = $GUI_CHECKED Then
		_GUI_AddLog("🤖 Перезапуск маршрута после ресета")
		$g_bRouteExecuting = True
		$g_iAutopilot_State = 1
	Else
		$g_iAutopilot_State = 0
	EndIf

	; Сбрасываем уровень для пересчёта DPS
	$g_iAutopilot_LastLevel = 0
EndFunc

; Проверка и активация Helper Bot
Func _Autopilot_CheckHelper($sMarkersJSON)
	Local $oMarkers = _JSON_Parse($sMarkersJSON)

	If @error Then Return

	Local $iCount = _JSON_Get($oMarkers, "[count]")

	For $i = 0 To $iCount - 1
		Local $sMarkerName = _JSON_Get($oMarkers, "[markers][" & $i & "][name]")

		If $sMarkerName = "helper_active" Then
			Local $iHelperActive = _JSON_Get($oMarkers, "[markers][" & $i & "][value]")

			If $iHelperActive = 0 Then
				_Send_Click($g_hTargetWindow, 812,540, False)
				Sleep(200)
				_GUI_AddLog("🤖 Helper Bot выключен, активирую...")
				_Send_Click($g_hTargetWindow, 565, 870, False)
				Sleep(500)
				_Send_Click($g_hTargetWindow, 812, 540, False)
				Sleep(100)
			EndIf

			ExitLoop
		EndIf
	Next
EndFunc

