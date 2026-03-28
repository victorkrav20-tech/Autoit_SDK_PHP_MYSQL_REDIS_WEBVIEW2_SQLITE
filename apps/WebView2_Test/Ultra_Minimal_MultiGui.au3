; Ultra Minimal WebView2 Test - 5 окон
;########## Инициализация SDK и WebView2
#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Ultra_WebView2_Test_Multi"

Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

;########## Инициализация SDK и WebView2
Opt("GUIOnEventMode", 1)

; Создаём 5 окон
For $i = 1 To 5
    _Logger_Write("Создание окна ID=" & $i, 1)
    
    _WebView2_Engine_Initialize($i, "local", @ScriptDir & "\profile")
    _WebView2_GUI_Create($i, "Ultra Minimal #" & $i, 800, 600, 100 + ($i * 50), 100 + ($i * 50))
    
    ; Устанавливаем обработчик закрытия окна
    GUISetOnEvent($GUI_EVENT_CLOSE, "_WebView2_GUI_OnClose_Auto")
    
    _WebView2_Events_WaitForReady($i, 10000)
    _WebView2_Nav_Load("index.html", 0, $i)
    _WebView2_GUI_Show($i)
    
    _Logger_Write("Окно ID=" & $i & " создано и показано", 3)
Next

_Logger_Write("Все 5 окон созданы. Закрой все окна для выхода.", 3)

; Основной цикл
While 1
    Sleep(10)
WEnd

