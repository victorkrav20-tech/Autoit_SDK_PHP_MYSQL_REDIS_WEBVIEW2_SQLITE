; Ultra Minimal WebView2 + Utils_Window Test
;########## Инициализация SDK и WebView2
#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Ultra_WebView2_Utils_Test"

Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")
;########## Инициализация SDK и WebView2

; Тест 1: Создание окна через Utils_Window для WebView2
ConsoleWrite("=== Тест 1: Создание окна через Utils_Window ===" & @CRLF)
Local $hWindow = _Utils_Window_CreateForWebView2("WebView2 Utils Test", 1200, 600, -1, -1, "webview2")
If @error Then
	ConsoleWrite("❌ Ошибка создания окна: " & @error & @CRLF)
	Exit 1
EndIf
ConsoleWrite("✅ Окно создано: " & $hWindow & @CRLF)
Sleep(1000)

; Тест 2: Инициализация WebView2
ConsoleWrite("=== Тест 2: Инициализация WebView2 ===" & @CRLF)
_WebView2_Engine_Initialize(0, "local", @ScriptDir & "\profile")
ConsoleWrite("✅ WebView2 инициализирован" & @CRLF)
Sleep(1000)

; Тест 3: Привязка WebView2 к окну Utils
ConsoleWrite("=== Тест 3: Привязка WebView2 к окну ===" & @CRLF)
; Получаем handle окна из Utils
Local $hUtilsWindow = _Utils_Window_GetHandle($hWindow)
ConsoleWrite("Handle окна Utils: " & $hUtilsWindow & @CRLF)

; Привязываем WebView2 к этому окну (нужно установить handle в массив WebView2)
If IsDeclared("g_aWebView2_Instances") Then
	Global $g_aWebView2_Instances
	$g_aWebView2_Instances[0][0] = $hUtilsWindow ; Устанавливаем handle окна
	ConsoleWrite("✅ WebView2 привязан к окну Utils" & @CRLF)
EndIf
Sleep(1000)

; Тест 4: Ожидание готовности WebView2
ConsoleWrite("=== Тест 4: Ожидание готовности WebView2 ===" & @CRLF)
_WebView2_Events_WaitForReady(0, 10000)
ConsoleWrite("✅ WebView2 готов" & @CRLF)
Sleep(1000)

; Тест 5: Загрузка страницы
ConsoleWrite("=== Тест 5: Загрузка страницы ===" & @CRLF)
_WebView2_Nav_Load("index.html")
ConsoleWrite("✅ Страница загружена" & @CRLF)
Sleep(1000)

; Тест 6: Показ окна
ConsoleWrite("=== Тест 6: Показ окна ===" & @CRLF)
_Utils_Window_Show($hWindow)
ConsoleWrite("✅ Окно показано" & @CRLF)
Sleep(1000)

ConsoleWrite("=== Все тесты завершены ===" & @CRLF)
Exit 0
