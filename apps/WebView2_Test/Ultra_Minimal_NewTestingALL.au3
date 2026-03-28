; Ultra Minimal WebView2 Test
;########## Инициализация SDK и WebView2
#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Ultra_WebView2_Test"

Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("external", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")
;########## Инициализация SDK и WebView2
Opt("GUIOnEventMode", 1)

_WebView2_Engine_Initialize(0, "external", @ScriptDir & "\profile")
_WebView2_GUI_Create(0, "Ultra Minimal", 1200, 600) ; Создание окна


_WebView2_Events_WaitForReady(0, 10000); Ожидание готовности WebView2
_WebView2_Nav_Load("http://127.0.0.1/apps/new_app1/gui/index.html") ; Загрузка страницы
_WebView2_GUI_Show()

sleep(50000); Так и оставляем для полной прогрузки.
Exit 0
