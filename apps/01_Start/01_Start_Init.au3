; ===============================================================================
; Файл: 01_Start_Init.au3
; Описание: Инициализация приложения 01_Start
; Функции:
;   _01_Start_Init() - Главная инициализация приложения
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"
#include "01_Start_Main.au3"

; ===============================================================================
; Глобальные переменные приложения
; ===============================================================================
Global $g_bDebug_01_Start = True ; Флаг отладки (устанавливается в Main через _01_Start_Main_Debug)

Global $g_s01_Start_AppName    = "01_Start"
Global $g_i01_Start_WindowID   = 1
Global $g_i01_Start_WindowWidth  = 1200
Global $g_i01_Start_WindowHeight = 700
Global $g_s01_Start_WindowTitle  = "01 Start"

Global $g_b01_Start_Initialized    = False
Global $g_b01_Start_MySQL_Enabled  = False
Global $g_b01_Start_Redis_Enabled  = False

; Переменные для мониторинга Redis подключения
Global $g_s01_Start_Redis_Host             = "127.0.0.1"
Global $g_i01_Start_Redis_Port             = 6379
Global $g_h01_Start_Redis_LastCheck        = 0
Global $g_i01_Start_Redis_ReconnectAttempts = 0
Global $g_i01_Start_Redis_CheckInterval    = 1000
Global $g_i01_Start_Redis_FastCheckInterval = 1000
Global $g_i01_Start_Redis_SlowCheckInterval = 3000
Global $g_i01_Start_Redis_MaxFastAttempts  = 10
Global $g_b01_Start_Redis_WasConnected     = False

; Переменные для отложенного логирования запуска
Global $g_h01_Start_StartupLog_Timer  = 0
Global $g_b01_Start_StartupLog_Sent   = False
Global $g_i01_Start_StartupLog_Delay  = 5000

; ===============================================================================
; Управление главным окном
; ===============================================================================
Global $g_b01_Start_WindowExists    = False  ; Существует ли главное окно
Global $g_i01_Start_InstanceID      = 1      ; InstanceID главного окна (всегда 1)
Global $g_h01_Start_Memory_LastCheck     = 0
Global $g_i01_Start_Memory_CheckInterval = 10000 ; 10 секунд
Global $g_i01_Start_Memory_Limit         = 1024  ; МБ (1GB)
Global $g_i01_Start_StartUp = 1


; ===============================================================================
; Функция: _01_Start_Init
; Описание: Главная инициализация приложения
; ===============================================================================
Func _01_Start_Init($bEnableMySQL = True, $bEnableRedis = True, $sRedisHost = "127.0.0.1", $iRedisPort = 6379)
	; Инициализация базового SDK (Utils + Logger + Config)
	Local $bSDKInit = _SDK_Init($g_s01_Start_AppName, True, 1, 3, True)
	_01_Start_Main_Debug()
	If Not $bSDKInit Then
		If $g_bDebug_01_Start Then _Logger_Write("❌ Ошибка инициализации SDK", 2)
		Return SetError(1, 0, False)
	EndIf
	If $g_bDebug_01_Start Then _Logger_Write("✅ SDK инициализирован: " & $g_s01_Start_AppName, 3)

	; Инициализация MySQL (если включено)
	If $bEnableMySQL Then
		Local $bMySQLInit = _SDK_MySQL_Init()
		If Not $bMySQLInit Then
			If $g_bDebug_01_Start Then _Logger_Write("❌ Ошибка инициализации MySQL", 2)
			Return SetError(2, 0, False)
		EndIf
		$g_b01_Start_MySQL_Enabled = True
		If $g_bDebug_01_Start Then _Logger_Write("✅ MySQL инициализирован", 3)
	Else
		If $g_bDebug_01_Start Then _Logger_Write("ℹ️ MySQL отключен", 1)
	EndIf

	; Инициализация Redis (если включено)
	If $bEnableRedis Then
		$g_s01_Start_Redis_Host    = $sRedisHost
		$g_i01_Start_Redis_Port    = $iRedisPort
		$g_b01_Start_Redis_Enabled = True

		Local $bRedisInit = _SDK_Redis_Init($sRedisHost, $iRedisPort)
		If Not $bRedisInit Then
			If $g_bDebug_01_Start Then _Logger_Write("⚠️ Redis недоступен при старте (будет автоматическое переподключение)", 2)
			$g_b01_Start_Redis_WasConnected = False
			$g_h01_Start_Redis_LastCheck    = TimerInit()
		Else
			If $g_bDebug_01_Start Then _Logger_Write("✅ Redis инициализирован: " & $sRedisHost & ":" & $iRedisPort, 3)
			Local $bRedisConnected = _Redis_Connect($sRedisHost, $iRedisPort)
			If $bRedisConnected Then
				_Logger_Write("✅ Redis TCP подключен", 3)
				$g_b01_Start_Redis_WasConnected = True
			Else
				_Logger_Write("⚠️ Redis TCP не подключен (будет автоматическое переподключение)", 2)
				$g_b01_Start_Redis_WasConnected = False
			EndIf
			$g_h01_Start_Redis_LastCheck = TimerInit()
		EndIf
	Else
		If $g_bDebug_01_Start Then _Logger_Write("ℹ️ Redis отключен", 1)
	EndIf

	; Инициализация WebView2
	Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")
	If Not $bWebView2Init Then
		If $g_bDebug_01_Start Then _Logger_Write("❌ Ошибка инициализации WebView2", 2)
		Return SetError(3, 0, False)
	EndIf
	If $g_bDebug_01_Start Then _Logger_Write("✅ WebView2 инициализирован", 3)

	$g_b01_Start_Initialized    = True
	$g_h01_Start_Memory_LastCheck = TimerInit()
	If $g_bDebug_01_Start Then _Logger_Write("🚀 Приложение 01_Start полностью инициализировано", 3)

	Return True
EndFunc

; ===============================================================================
Func _01_Start_IsInitialized()
	Return $g_b01_Start_Initialized
EndFunc

Func _01_Start_IsMySQLEnabled()
	Return $g_b01_Start_MySQL_Enabled
EndFunc

Func _01_Start_IsRedisEnabled()
	Return $g_b01_Start_Redis_Enabled
EndFunc


; ===============================================================================
; Функция: _01_Start_CheckRedisConnection
; Описание: Неблокирующая проверка и восстановление подключения к Redis
; ===============================================================================
Func _01_Start_CheckRedisConnection()
	If Not $g_b01_Start_Redis_Enabled Then Return False

	Local $iCurrentInterval = $g_i01_Start_Redis_CheckInterval
	If $g_i01_Start_Redis_ReconnectAttempts > 0 Then
		If $g_i01_Start_Redis_ReconnectAttempts <= $g_i01_Start_Redis_MaxFastAttempts Then
			$iCurrentInterval = $g_i01_Start_Redis_FastCheckInterval
		Else
			$iCurrentInterval = $g_i01_Start_Redis_SlowCheckInterval
		EndIf
	EndIf

	If TimerDiff($g_h01_Start_Redis_LastCheck) < $iCurrentInterval Then Return $g_b01_Start_Redis_WasConnected
	$g_h01_Start_Redis_LastCheck = TimerInit()

	Local $bConnectionOK = _Redis_PingNonBlocking(5)

	If $bConnectionOK Then
		If Not $g_b01_Start_Redis_WasConnected Then
			If $g_bDebug_01_Start Then _Logger_Write("✅ Redis подключение восстановлено после " & $g_i01_Start_Redis_ReconnectAttempts & " попыток", 3)
			$g_i01_Start_Redis_ReconnectAttempts = 0
		EndIf
		$g_b01_Start_Redis_WasConnected = True
		Return True
	Else
		Local $bReconnected = _Redis_ConnectNonBlocking($g_s01_Start_Redis_Host, $g_i01_Start_Redis_Port, 10)
		If $bReconnected Then
			If $g_bDebug_01_Start Then _Logger_Write("✅ Redis переподключен успешно", 3)
			$g_b01_Start_Redis_WasConnected = True
			$g_i01_Start_Redis_ReconnectAttempts = 0
			Return True
		Else
			$g_i01_Start_Redis_ReconnectAttempts += 1
			If $g_b01_Start_Redis_WasConnected Or (Mod($g_i01_Start_Redis_ReconnectAttempts, 10) = 0) Then
				Local $sMode = ($g_i01_Start_Redis_ReconnectAttempts <= $g_i01_Start_Redis_MaxFastAttempts) ? "быстрый режим" : "медленный режим"
				If $g_bDebug_01_Start Then _Logger_Write("⚠️ Redis недоступен (попытка " & $g_i01_Start_Redis_ReconnectAttempts & ", " & $sMode & ")", 2)
			EndIf
			$g_b01_Start_Redis_WasConnected = False
			Return False
		EndIf
	EndIf
EndFunc

; ===============================================================================
; Функция: _01_Start_ProcessStartupLogging
; Описание: Отложенное логирование запуска в MySQL
; ===============================================================================
Func _01_Start_ProcessStartupLogging()
	If $g_b01_Start_StartupLog_Sent Then Return
	If TimerDiff($g_h01_Start_StartupLog_Timer) >= $g_i01_Start_StartupLog_Delay Then
		If _01_Start_IsMySQLEnabled() Then
			_MySQL_InsertSCADA("app_logs", "app_id=01_start|app_name=01 Start|event_type=start|message=Приложение запущено успешно|hostname=" & @ComputerName, $MYSQL_SERVER_LOCAL)
			_MySQL_InsertSCADA("app_logs", "app_id=01_start|app_name=01 Start|event_type=start|message=Приложение запущено успешно|hostname=" & @ComputerName, $MYSQL_SERVER_REMOTE)
			If $g_bDebug_01_Start Then _Logger_Write("📝 Логирование запуска отправлено в MySQL", 3)
		EndIf
		$g_b01_Start_StartupLog_Sent = True
	EndIf
EndFunc


; ===============================================================================
; Функция: _01_Start_Window_Create
; Описание: Создание главного окна WebView2
; ===============================================================================
Func _01_Start_Window_Create()
	Local $iInstanceID = $g_i01_Start_InstanceID

	; Проверяем что окно ещё не создано
	If $g_b01_Start_WindowExists Then
		Local $oInstance = _WebView2_Core_GetInstance($iInstanceID)
		If IsObj($oInstance) Then
			If $g_bDebug_01_Start Then _Logger_Write("⚠️ Главное окно уже существует", 2)
			Return False
		Else
			If $g_bDebug_01_Start Then _Logger_Write("🔄 Флаг True, но инстанс не существует — сбрасываю флаг", 2)
			$g_b01_Start_WindowExists = False
		EndIf
	EndIf

	If $g_bDebug_01_Start Then _Logger_Write("📱 Создание главного окна ID=" & $iInstanceID, 1)

	; Инициализация Engine
	_WebView2_Engine_Initialize($iInstanceID, "local", @ScriptDir & "\profile")

	; Создание GUI
	_WebView2_GUI_Create($iInstanceID, $g_s01_Start_WindowTitle, $g_i01_Start_WindowWidth, $g_i01_Start_WindowHeight, 100, 100, $WV2_MODE_FRAMED_RESIZABLE)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_01_Start_OnWindowClose")

	; Ожидание готовности
	If $g_i01_Start_StartUp Then
		_WebView2_Events_WaitForReady($iInstanceID, 15000)
	Else
		_WebView2_Events_WaitForReady($iInstanceID, 1000)
	EndIf

	; Production режим
	_WebView2_GUI_SetProductionMode($iInstanceID, True, True)
	If $g_bDebug_01_Start Then _Logger_Write("🔒 Production режим включен для ID=" & $iInstanceID, 1)

	; Инициализация Bridge
	_WebView2_Bridge_Initialize($iInstanceID, @ScriptDir & "\gui", True)
	_WebView2_Bridge_On("main_window_data", "_01_Start_OnMainWindowData", $iInstanceID)
	_WebView2_Bridge_On("response", "_01_Start_OnResponse", $iInstanceID)
	If $g_bDebug_01_Start Then _Logger_Write("✅ Bridge инициализирован для ID=" & $iInstanceID, 3)

	; Навигация
	_WebView2_Nav_Load("index.html", 0, $iInstanceID)

	; Показываем окно
	_WebView2_GUI_Show($iInstanceID)

	$g_b01_Start_WindowExists = True
	If $g_bDebug_01_Start Then _Logger_Write("✅ Главное окно ID=" & $iInstanceID & " создано", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _01_Start_Window_Destroy
; Описание: Удаление главного окна
; ===============================================================================
Func _01_Start_Window_Destroy()
	Local $iInstanceID = $g_i01_Start_InstanceID

	If Not $g_b01_Start_WindowExists Then
		If $g_bDebug_01_Start Then _Logger_Write("⚠️ Главное окно не существует", 2)
		Return False
	EndIf

	If $g_bDebug_01_Start Then _Logger_Write("🔄 Закрытие главного окна ID=" & $iInstanceID, 1)

	_WebView2_GUI_Hide($iInstanceID)

	Local $hWnd = _WebView2_GUI_GetHandle($iInstanceID)
	_WebView2_Core_DestroyInstance($iInstanceID)

	If $hWnd <> 0 Then
		GUIDelete($hWnd)
		If $g_bDebug_01_Start Then _Logger_Write("✅ GUI окно удалено", 1)
	EndIf

	$g_b01_Start_WindowExists = False
	If $g_bDebug_01_Start Then _Logger_Write("✅ Главное окно ID=" & $iInstanceID & " удалено", 3)
	Return True
EndFunc

; ===============================================================================
; Функция: _01_Start_Window_Recreate
; Описание: Пересоздание главного окна
; ===============================================================================
Func _01_Start_Window_Recreate()
	If $g_bDebug_01_Start Then _Logger_Write("🔄 Пересоздание главного окна...", 1)
	_01_Start_Window_Destroy()
	Sleep(500)
	Return _01_Start_Window_Create()
EndFunc

; ===============================================================================
; Функция: _01_Start_Monitor_Memory
; Описание: Мониторинг использования памяти (раз в 10 секунд)
; ===============================================================================
Func _01_Start_Monitor_Memory()
	If TimerDiff($g_h01_Start_Memory_LastCheck) < $g_i01_Start_Memory_CheckInterval Then Return
	$g_h01_Start_Memory_LastCheck = TimerInit()

	Local $aMemory = ProcessGetStats()
	If Not IsArray($aMemory) Then Return

	Local $iMemoryMB = Round($aMemory[0] / 1024 / 1024, 2)

	If $iMemoryMB > $g_i01_Start_Memory_Limit Then
		If $g_bDebug_01_Start Then _Logger_Write("⚠️ Превышен лимит памяти: " & $iMemoryMB & " МБ (лимит: " & $g_i01_Start_Memory_Limit & " МБ)", 2)
		If $g_b01_Start_WindowExists Then
			If $g_bDebug_01_Start Then _Logger_Write("🔄 Пересоздание главного окна из-за памяти", 1)
			_01_Start_Window_Recreate()
		EndIf
		If $g_bDebug_01_Start Then _Logger_Write("✅ Окно пересоздано, память должна освободиться", 3)
	EndIf
EndFunc
