; ===============================================================================
; SDK Initialization Library v1.0
; Единая точка инициализации всех модулей SDK
; ===============================================================================

; СПИСОК ФУНКЦИЙ:
; ===============================================================================
; ОСНОВНАЯ ФУНКЦИЯ:
; _SDK_Init($sAppName, $bDebugMode, $iLogFilter, $iLogTarget, $bClearLog)
;   Инициализация базового SDK (Utils + логирование)
;   $sAppName - имя приложения (обязательный)
;   $bDebugMode - режим отладки: True/False (по умолчанию True)
;   $iLogFilter - фильтр: 1=все, 2=только ошибки, 3=только успех (по умолчанию 1)
;   $iLogTarget - куда: 1=консоль, 2=файл, 3=оба (по умолчанию 3)
;   $bClearLog - очищать лог при запуске: True/False (по умолчанию True)
;   Возврат: True при успехе, False при ошибке
;
; МОДУЛЬНЫЕ ИНИЦИАЛИЗАЦИИ (опциональные):
; _SDK_Utils_Window_Init() - Инициализация системы управления окнами Utils_Window (НЕ для WebView2)
; _SDK_MySQL_Init() - Инициализация MySQL (очереди)
; _SDK_Redis_Init($sHost, $iPort) - Инициализация Redis подключения
; _SDK_WebView2_Init($sMode, $sProfilePath, $sInjectPath, $sGuiPath, $sDataPath) - Инициализация WebView2 движка
;
; ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ:
; _SDK_IsInitialized() - Проверка инициализации SDK
; _SDK_GetAppName() - Получение имени текущего приложения
; ===============================================================================

#include-once

; Подключение библиотек в правильном порядке
#include "json/JSON.au3"
#include "WinHttp/WinHttp.au3"
#include "Utils/Utils.au3"
#include "MySQL_PHP/MySQL_Core_API.au3"
#include "Redis_TCP/Redis_Core_TCP.au3"
#include "Redis_TCP/Redis_PubSub.au3"
#include "WebView2/WebView2_Engine.au3"

; ===============================================================================
; ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ SDK
; ===============================================================================

Global $g_sSDK_AppName = "DefaultApp"
Global $g_bSDK_Initialized = False

; Дебаг переменная для управления логами SDK_Init
Global $g_bDebug_SDK_Init = False

; ===============================================================================
; Функция: _SDK_Init
; Описание: Инициализация базового SDK (Utils + логирование)
; Параметры:
;   $sAppName - имя приложения (обязательный)
;   $bDebugMode - режим отладки: True/False (по умолчанию True)
;   $iLogFilter - фильтр: 1=все, 2=только ошибки, 3=только успех (по умолчанию 1)
;   $iLogTarget - куда: 1=консоль, 2=файл, 3=оба (по умолчанию 3)
;   $bClearLog - очищать лог при запуске: True/False (по умолчанию True)
; Возврат: True при успехе, False при ошибке
; Пример: _SDK_Init("MyApp", True, 1, 3, True)
; ===============================================================================
Func _SDK_Init($sAppName = "DefaultApp", $bDebugMode = True, $iLogFilter = 1, $iLogTarget = 3, $bClearLog = True)
    $g_sSDK_AppName = $sAppName

    Local $bUtilsInit = _SDK_Utils_Init($sAppName, "Main", $bDebugMode, $iLogFilter, $iLogTarget, $bClearLog)
    If Not $bUtilsInit Then
        _Logger_ConsoleWriteUTF("❌ Ошибка инициализации Utils")
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("🚀 [SDK] Инициализация SDK для приложения: " & $sAppName, 1)
    If $g_bDebug_SDK_Init Then _Logger_Write("🔧 [SDK] Режим отладки: " & ($bDebugMode ? "Включен" : "Выключен"), 1)
    If $g_bDebug_SDK_Init Then _Logger_Write("📊 [SDK] Фильтр логов: " & ($iLogFilter = 1 ? "Все" : ($iLogFilter = 2 ? "Только ошибки" : "Только успех")), 1)
    If $g_bDebug_SDK_Init Then _Logger_Write("📁 [SDK] Цель логов: " & ($iLogTarget = 1 ? "Консоль" : ($iLogTarget = 2 ? "Файл" : "Консоль+Файл")), 1)

    ; Инициализация системы конфигурации
    If $g_bDebug_SDK_Init Then _Logger_Write("⚙️ [SDK] Инициализация системы конфигурации...", 1)
    Local $bConfigInit = _Utils_Config_Init($sAppName)
    If Not $bConfigInit Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] Ошибка инициализации конфигурации", 2)
        Return False
    EndIf
    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] Конфигурация успешно инициализирована", 3)

    $g_bSDK_Initialized = True

    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] Базовый SDK успешно инициализирован (Utils + Logger + Config)", 3)

    Return True
EndFunc

; ===============================================================================
; Функция: _SDK_IsInitialized
; Описание: Проверка инициализации SDK
; Возврат: True если инициализирован, False если нет
; ===============================================================================
Func _SDK_IsInitialized()
    Return $g_bSDK_Initialized
EndFunc

; ===============================================================================
; Функция: _SDK_GetAppName
; Описание: Получение имени текущего приложения
; Возврат: Строка с именем приложения
; ===============================================================================
Func _SDK_GetAppName()
    Return $g_sSDK_AppName
EndFunc

; ===============================================================================
; Функция: _SDK_MySQL_Init
; Описание: Инициализация MySQL (очереди) - опциональная
; Возврат: True при успехе, False при ошибке
; Пример: _SDK_MySQL_Init()
; ===============================================================================
Func _SDK_MySQL_Init()
    If Not $g_bSDK_Initialized Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] SDK не инициализирован. Вызовите _SDK_Init() сначала", 2)
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("🗄️ [SDK] Инициализация MySQL (очереди)...", 1)

    ; Инициализируем MySQL очереди
    Local $bMySQLInit = _MySQL_InitQueue()
    If Not $bMySQLInit Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] Ошибка инициализации MySQL очередей", 2)
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] MySQL успешно инициализирован", 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _SDK_Redis_Init
; Описание: Инициализация Redis подключения - опциональная
; Параметры:
;   $sHost - адрес Redis сервера (по умолчанию "127.0.0.1")
;   $iPort - порт Redis сервера (по умолчанию 6379)
; Возврат: True при успехе, False при ошибке
; Пример: _SDK_Redis_Init("127.0.0.1", 6379)
; ===============================================================================
Func _SDK_Redis_Init($sHost = "127.0.0.1", $iPort = 6379)
    If Not $g_bSDK_Initialized Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] SDK не инициализирован. Вызовите _SDK_Init() сначала", 2)
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("🔌 [SDK] Инициализация Redis: " & $sHost & ":" & $iPort, 1)

    ; Подключаемся к Redis
    Local $bRedisConnect = _Redis_Connect($sHost, $iPort)
    If Not $bRedisConnect Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] Ошибка подключения к Redis", 2)
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] Redis успешно инициализирован", 3)
    Return True
EndFunc
; ===============================================================================
; Функция: _SDK_WebView2_Init
; Описание: Инициализация WebView2 движка - опциональная
; Параметры:
;   $sMode - режим работы: "local" или "external" (по умолчанию "local")
;   $sProfilePath - путь к профилю WebView2 (обязательный)
;   $sInjectPath - путь к папке inject (опционально)
;   $sGuiPath - путь к папке gui (опционально, для local режима)
;   $sDataPath - путь к папке data (опционально)
; Возврат: True при успехе, False при ошибке
; Пример: _SDK_WebView2_Init("local", @ScriptDir & "\profile", @ScriptDir & "\inject", @ScriptDir & "\gui")
; ===============================================================================
Func _SDK_WebView2_Init($sMode = "local", $sProfilePath = "", $sInjectPath = "", $sGuiPath = "", $sDataPath = "")
    If Not $g_bSDK_Initialized Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] SDK не инициализирован. Вызовите _SDK_Init() сначала", 2)
        Return False
    EndIf
#cs
    If $g_bDebug_SDK_Init Then _Logger_Write("🌐 [SDK] Инициализация WebView2 движка (режим: " & $sMode & ")", 1)

    ; Проверяем обязательный параметр
    If $sProfilePath = "" Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] Путь к профилю WebView2 обязателен", 2)
        Return False
    EndIf

    ; Инициализируем WebView2 движок (default экземпляр ID=0)
    Local $bWebView2Init = _WebView2_Engine_Initialize(0, $sMode, $sProfilePath)
    If Not $bWebView2Init Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] Ошибка инициализации WebView2 движка", 2)
        Return False
    EndIf

    ; Устанавливаем пути если указаны
    If $sInjectPath <> "" Or $sGuiPath <> "" Or $sDataPath <> "" Then
        _WebView2_Engine_SetPaths($sInjectPath, $sGuiPath, $sDataPath)
        If $g_bDebug_SDK_Init Then _Logger_Write("📁 [SDK] Пути WebView2 установлены", 1)
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] WebView2 успешно инициализирован", 3)
#ce
    Return True
EndFunc


; ===============================================================================
; Функция: _SDK_Utils_Window_Init
; Описание: Инициализация системы управления окнами Utils_Window
; Параметры: нет
; Возврат: True при успехе
; Пример: _SDK_Utils_Window_Init()
; Примечание: Вызывать ТОЛЬКО если используются окна Utils_Window (НЕ WebView2)
; ===============================================================================
Func _SDK_Utils_Window_Init()
    If Not $g_bSDK_Initialized Then
        If $g_bDebug_SDK_Init Then _Logger_Write("❌ [SDK] SDK не инициализирован. Вызовите _SDK_Init() сначала", 2)
        Return False
    EndIf

    If $g_bDebug_SDK_Init Then _Logger_Write("🪟 [SDK] Инициализация системы управления окнами Utils_Window...", 1)
    Opt("GUIOnEventMode", 1)
    If $g_bDebug_SDK_Init Then _Logger_Write("✅ [SDK] Utils_Window OnEventMode включен", 3)

    Return True
EndFunc
