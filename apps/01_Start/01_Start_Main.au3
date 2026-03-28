#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; ===============================================================================
; Файл: 01_Start_Main.au3
; Описание: Главный файл приложения 01_Start
; Версия: 1.0.0
; ===============================================================================

#include-once
#include "01_Start_Init.au3"
#include "01_Start_Core.au3"
#include "01_Start_Init_Events.au3"
#include "01_Start_Init_Response.au3"
#include "01_Start_Init_Utils.au3"
#include <TrayConstants.au3>

; ===============================================================================
; ГЛОБАЛЬНЫЕ НАСТРОЙКИ
; ===============================================================================
; Режим логирования Response:
; 1 = каждый запрос, 2 = раз в 10, 3 = раз в 100, 4 = никогда
Global $g_i01_Start_Response_LogMode = 3
Global $g_i01_Start_StartUp = 1
Global $g_sTray_Mode = "hide"        ; Режим трея: "destroy" или "hide"
Global $g_b01_Start_ExitOnNoWindows = False ; True = завершать при 0 окнах, False = фоновый процесс с треем

; ===============================================================================
; Включение событийной модели
; ===============================================================================
Opt("GUIOnEventMode", 1)
Opt("TrayOnEventMode", 1)
Opt("TrayMenuMode", 1)

; ===============================================================================
; Асинхронная регистрация горячих клавиш
; ===============================================================================
AdlibRegister("_01_Start_RegisterHotKeys_Async", 1000)

; ===============================================================================
; Настройка режима отладки (вызывается ДО инициализации SDK)
; ===============================================================================
_01_Start_Main_Debug()

; ===============================================================================
; Инициализация приложения
; ===============================================================================
Local $bInit = _01_Start_Init(True, True, "127.0.0.1", 6379)
If Not $bInit Then
	If $g_bDebug_01_Start Then _Logger_Write("❌ Критическая ошибка инициализации", 2)
	Exit
EndIf

; ===============================================================================
; Инициализация трэя
; ===============================================================================
_01_Start_Tray_Init()

; ===============================================================================
; Создание главного окна
; ===============================================================================
If $g_bDebug_01_Start Then _Logger_Write("🚀 Создание главного окна", 3)
_01_Start_Window_Create()

$g_i01_Start_StartUp = 0
If $g_bDebug_01_Start Then _Logger_Write("✅ Приложение готово к работе", 3)

; ===============================================================================
; Инициализация таймера отложенного логирования запуска
; ===============================================================================
$g_h01_Start_StartupLog_Timer = TimerInit()

; ===============================================================================
; Инициализация Core таймера
; ===============================================================================
_Core_Timer_Init(1000, True)

; ===============================================================================
; Основной цикл
; ===============================================================================
While True
	; Точный такт (раз в $g_iCore_Interval мс, синхронизирован с .100)
	If _Core_Timer_Check() Then
		;_Logger_Write("🔄 Такт", 1)
		_01_Start_ProcessStartupLogging()
		_01_Start_CheckRedisConnection()
		_01_Start_Monitor_Memory()
		_Core_Timer_End()
	EndIf

	; Автокликер — вне такта, нужна высокая частота
	_01_Start_AutoClicker_Process()
	Sleep(1)
	;_HighPrecisionSleep(2000, $g_hCore_DLL) ; 2мс микрозадержка
WEnd

; ===============================================================================
; Функция: _01_Start_Main_Debug
; Описание: Настройка режимов отладки всех библиотек SDK
; Вызывается ДО инициализации SDK
; ===============================================================================
Func _01_Start_Main_Debug()
	Global $g_bDebug_01_Start = True

	; SDK Init
	Global $g_bDebug_SDK_Init = False

	; WebView2
	Global $g_bDebug_WebView2_Core = False
	Global $g_bDebug_WebView2_Events = False
	Global $g_bDebug_WebView2_GUI = False
	Global $g_bDebug_WebView2_Injection = False
	Global $g_bDebug_WebView2_Navigation = False
	Global $g_bDebug_WebView2_Engine = False
	Global $g_bDebug_WebView2_Bridge = False
	Global $g_bDebug_WebView2_WebView2_DLL = False
	Global $g_bDebug_WebView2_DevTools = False

	; Utils
	Global $g_bUtils_DebugMode = False
	Global $g_bUtils_SQLite_DebugMode = False

	; Redis
	Global $g_bDebug_Redis_Core = False
	Global $g_bDebug_Redis_PubSub = False

	; MySQL
	Global $g_bMySQL_DebugMode = False
EndFunc
