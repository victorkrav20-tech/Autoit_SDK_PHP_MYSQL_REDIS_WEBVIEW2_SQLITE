; ===============================================================================
; Test_09_Performance.au3 - Тестирование производительности WebView2
; Версия: 1.0.0
; Описание: Замеры времени всех операций, поиск узких мест
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_09_Perf"

; Инициализация SDK
_SDK_Init($sAppName, True, 1, 3, True)

_Logger_Write("========================================", 1)
_Logger_Write("🚀 Test_09_Performance - Замеры производительности", 1)
_Logger_Write("========================================", 1)

Opt("GUIOnEventMode", 1)

; ===============================================================================
; ТЕСТ 1: Создание экземпляра
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 1: Создание экземпляра WebView2", 1)

Local $hTimer = TimerInit()
Local $hInstance = _WebView2_Engine_CreateInstance(1, "local", @ScriptDir & "\profile")
Local $fTime1 = TimerDiff($hTimer)

_Logger_Write("✅ Экземпляр создан за: " & Round($fTime1, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 2: Создание GUI
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 2: Создание GUI окна", 1)

$hTimer = TimerInit()
Local $hGUI = GUICreate("Test_09_Performance", 1200, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnExit")
GUISetState(@SW_SHOW)
Local $fTime2 = TimerDiff($hTimer)

_Logger_Write("✅ GUI создан за: " & Round($fTime2, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 3: Инициализация WebView
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 3: Инициализация WebView контрола", 1)

$hTimer = TimerInit()
_WebView2_Engine_SetPaths("", @ScriptDir & "\gui", "", $hInstance)
_WebView2_Core_InitializeWebView($hInstance, $hGUI, 0, 0, 1200, 600)
Local $fTime3 = TimerDiff($hTimer)

_Logger_Write("✅ WebView инициализирован за: " & Round($fTime3, 2) & " мс", 3)

; Ожидание готовности
_Logger_Write("⏳ Ожидание INIT_READY события...", 1)
$hTimer = TimerInit()
Sleep(2000)
Local $fTime3_wait = TimerDiff($hTimer)
_Logger_Write("✅ Ожидание заняло: " & Round($fTime3_wait, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 4: Загрузка HTML из строки
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 4: Загрузка HTML из строки", 1)

Local $sHTML = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>'
$sHTML &= '<body style="background:#f5f5f5;padding:20px;font-family:Arial;">'
$sHTML &= '<h1>Performance Test</h1>'
$sHTML &= '<div id="data">Test Data</div>'
$sHTML &= '</body></html>'

$hTimer = TimerInit()
_WebView2_Nav_LoadHTML($sHTML, $hInstance)
Sleep(500)
Local $fTime4 = TimerDiff($hTimer)

_Logger_Write("✅ HTML загружен за: " & Round($fTime4, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 5: Выполнение JavaScript (простой)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 5: Выполнение простого JavaScript", 1)

Local $fTotalJS = 0
For $i = 1 To 10
    $hTimer = TimerInit()
    _WebView2_Core_ExecuteScript($hInstance, "2 + 2")
    $fTotalJS += TimerDiff($hTimer)
    Sleep(50)
Next

Local $fAvgJS = $fTotalJS / 10
_Logger_Write("✅ Среднее время JS (10 вызовов): " & Round($fAvgJS, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 6: Выполнение JavaScript (сложный)
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 6: Выполнение сложного JavaScript", 1)

Local $sComplexJS = "var arr = []; for(var i=0; i<1000; i++) arr.push(i); arr.reduce((a,b) => a+b, 0);"
$fTotalJS = 0
For $i = 1 To 10
    $hTimer = TimerInit()
    _WebView2_Core_ExecuteScript($hInstance, $sComplexJS)
    $fTotalJS += TimerDiff($hTimer)
    Sleep(50)
Next

$fAvgJS = $fTotalJS / 10
_Logger_Write("✅ Среднее время сложного JS (10 вызовов): " & Round($fAvgJS, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 7: Изменение DOM
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 7: Изменение DOM элементов", 1)

Local $fTotalDOM = 0
For $i = 1 To 10
    $hTimer = TimerInit()
    _WebView2_Core_ExecuteScript($hInstance, "document.getElementById('data').innerHTML = 'Update " & $i & "';")
    $fTotalDOM += TimerDiff($hTimer)
    Sleep(50)
Next

Local $fAvgDOM = $fTotalDOM / 10
_Logger_Write("✅ Среднее время изменения DOM (10 вызовов): " & Round($fAvgDOM, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 8: Инъекция CSS
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 8: Инъекция CSS", 1)

Local $sCSS = "body { background: #e3f2fd !important; }"
$hTimer = TimerInit()
_WebView2_Core_InjectCss($hInstance, $sCSS)
Sleep(100)
Local $fTime8 = TimerDiff($hTimer)

_Logger_Write("✅ CSS инъекция за: " & Round($fTime8, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 9: Загрузка локального файла
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Загрузка локального HTML файла", 1)

$hTimer = TimerInit()
_WebView2_Nav_Load("index.html", False, $hInstance)
Sleep(500)
Local $fTime9 = TimerDiff($hTimer)

_Logger_Write("✅ Локальный файл загружен за: " & Round($fTime9, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 10: Загрузка внешнего URL
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 10: Загрузка внешнего URL", 1)

$hTimer = TimerInit()
_WebView2_Nav_LoadExternal("https://www.google.com", False, $hInstance)
Sleep(2000)
Local $fTime10 = TimerDiff($hTimer)

_Logger_Write("✅ Внешний URL загружен за: " & Round($fTime10, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 11: GetSource
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 11: Получение HTML кода (GetSource)", 1)

$fTotalJS = 0
For $i = 1 To 10
    $hTimer = TimerInit()
    Local $sSource = _WebView2_Core_GetSource($hInstance)
    $fTotalJS += TimerDiff($hTimer)
    Sleep(50)
Next

$fAvgJS = $fTotalJS / 10
_Logger_Write("✅ Среднее время GetSource (10 вызовов): " & Round($fAvgJS, 2) & " мс", 3)

; ===============================================================================
; ТЕСТ 12: Множественные операции подряд
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 12: Стресс-тест (100 операций подряд)", 1)

$hTimer = TimerInit()
For $i = 1 To 100
    _WebView2_Core_ExecuteScript($hInstance, "document.title = 'Test " & $i & "';")
Next
Local $fTime12 = TimerDiff($hTimer)

_Logger_Write("✅ 100 операций выполнено за: " & Round($fTime12, 2) & " мс", 3)
_Logger_Write("ℹ️ Среднее время на операцию: " & Round($fTime12 / 100, 2) & " мс", 1)

; ===============================================================================
; СВОДКА РЕЗУЛЬТАТОВ
; ===============================================================================
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("📊 СВОДКА ПРОИЗВОДИТЕЛЬНОСТИ", 1)
_Logger_Write("========================================", 1)

Local $fTotal = $fTime1 + $fTime2 + $fTime3 + $fTime3_wait + $fTime4 + $fTime8 + $fTime9 + $fTime10

_Logger_Write("", 1)
_Logger_Write("⏱️ ВРЕМЯ ОПЕРАЦИЙ:", 1)
_Logger_Write("1. Создание экземпляра: " & Round($fTime1, 2) & " мс", 1)
_Logger_Write("2. Создание GUI: " & Round($fTime2, 2) & " мс", 1)
_Logger_Write("3. Инициализация WebView: " & Round($fTime3, 2) & " мс", 1)
_Logger_Write("   └─ Ожидание INIT_READY: " & Round($fTime3_wait, 2) & " мс", 1)
_Logger_Write("4. Загрузка HTML (строка): " & Round($fTime4, 2) & " мс", 1)
_Logger_Write("5. JavaScript (простой): " & Round($fAvgJS, 2) & " мс (среднее)", 1)
_Logger_Write("6. JavaScript (сложный): " & Round($fAvgJS, 2) & " мс (среднее)", 1)
_Logger_Write("7. Изменение DOM: " & Round($fAvgDOM, 2) & " мс (среднее)", 1)
_Logger_Write("8. Инъекция CSS: " & Round($fTime8, 2) & " мс", 1)
_Logger_Write("9. Загрузка локального файла: " & Round($fTime9, 2) & " мс", 1)
_Logger_Write("10. Загрузка внешнего URL: " & Round($fTime10, 2) & " мс", 1)
_Logger_Write("11. GetSource: " & Round($fAvgJS, 2) & " мс (среднее)", 1)
_Logger_Write("12. Стресс-тест (100 операций): " & Round($fTime12, 2) & " мс", 1)

_Logger_Write("", 1)
_Logger_Write("📈 УЗКИЕ МЕСТА:", 1)

; Определяем самые медленные операции
Local $aSlowOps[0][2]
If $fTime3_wait > 1000 Then
    ReDim $aSlowOps[UBound($aSlowOps) + 1][2]
    $aSlowOps[UBound($aSlowOps) - 1][0] = "Ожидание INIT_READY"
    $aSlowOps[UBound($aSlowOps) - 1][1] = Round($fTime3_wait, 2)
EndIf

If $fTime10 > 1000 Then
    ReDim $aSlowOps[UBound($aSlowOps) + 1][2]
    $aSlowOps[UBound($aSlowOps) - 1][0] = "Загрузка внешнего URL"
    $aSlowOps[UBound($aSlowOps) - 1][1] = Round($fTime10, 2)
EndIf

If $fTime9 > 500 Then
    ReDim $aSlowOps[UBound($aSlowOps) + 1][2]
    $aSlowOps[UBound($aSlowOps) - 1][0] = "Загрузка локального файла"
    $aSlowOps[UBound($aSlowOps) - 1][1] = Round($fTime9, 2)
EndIf

If UBound($aSlowOps) > 0 Then
    For $i = 0 To UBound($aSlowOps) - 1
        _Logger_Write("⚠️ " & $aSlowOps[$i][0] & ": " & $aSlowOps[$i][1] & " мс", 2)
    Next
Else
    _Logger_Write("✅ Узких мест не обнаружено", 3)
EndIf

_Logger_Write("", 1)
_Logger_Write("💡 РЕКОМЕНДАЦИИ:", 1)
If $fTime3_wait > 1500 Then
    _Logger_Write("• Ожидание INIT_READY можно сократить до 1000 мс", 1)
EndIf
If $fTime10 > 2000 Then
    _Logger_Write("• Внешние URL загружаются медленно (зависит от сети)", 1)
EndIf
If $fTime9 > 500 Then
    _Logger_Write("• Локальные файлы можно кешировать", 1)
EndIf
If $fTime12 / 100 > 10 Then
    _Logger_Write("• Множественные операции можно батчить", 1)
EndIf

_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Тест завершён!", 3)
_Logger_Write("========================================", 1)

Exit 0

Func _OnExit()
    Exit
EndFunc
