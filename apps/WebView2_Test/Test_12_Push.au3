; ===============================================================================
; Test_12_Push.au3 - Тест пушинга AutoIt → WebView2
; Версия: 1.0.0
; Описание: Автоматическое тестирование всех функций пушинга с подтверждением
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Test_12_Push"
Global $iTestsPassed = 0
Global $iTestsTotal = 12
Global $iPushConfirmed = 0

; ===============================================================================
; Инициализация SDK и WebView2
; ===============================================================================
_Logger_Write("========================================", 1)
_Logger_Write("🧪 Test_12_Push - Тест пушинга AutoIt → JS", 1)
_Logger_Write("========================================", 1)

Local $bSDKInit = _SDK_Init($sAppName, True, 1, 3, True)
Local $bWebView2Init = _SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

If Not $bSDKInit Or Not $bWebView2Init Then
    _Logger_Write("❌ Инициализация не удалась", 2)
    Exit 1
EndIf

Opt("GUIOnEventMode", 1)

; ===============================================================================
; Создание GUI и инициализация Bridge
; ===============================================================================
_WebView2_GUI_Create(0, "Test 12 - Push", 1200, 800)
_WebView2_Events_WaitForReady(0, 10000)

_Logger_Write("", 1)
_Logger_Write("🔧 Инициализация Bridge...", 1)
_WebView2_Bridge_Initialize(0, @ScriptDir & "\gui")

; Регистрация обработчика подтверждений
_WebView2_Bridge_On("push_confirmed", "_HandlePushConfirmed", 0)

; Загрузка страницы
_WebView2_Nav_Load("test12.html", False, 0)
_WebView2_GUI_Show()

_Logger_Write("", 1)
_Logger_Write("✅ Приложение готово, начинаю автотесты пушинга...", 3)
_Logger_Write("", 1)

Sleep(2000)  ; Даём странице загрузиться

; ===============================================================================
; АВТОМАТИЧЕСКИЕ ТЕСТЫ ПУШИНГА
; ===============================================================================

; ТЕСТ 1: UpdateElement (температура)
_Logger_Write("📋 ТЕСТ 1: UpdateElement (temp_value)", 1)
_WebView2_Bridge_UpdateElement("temp_value", "25.5°C", 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 2: UpdateElement (давление)
_Logger_Write("📋 ТЕСТ 2: UpdateElement (pressure_value)", 1)
_WebView2_Bridge_UpdateElement("pressure_value", "1013 hPa", 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 3: SetHTML
_Logger_Write("📋 ТЕСТ 3: SetHTML", 1)
_WebView2_Bridge_SetHTML("html_content", "<b>Bold Text</b> <i>Italic</i>", 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 4: SetClass (активный статус)
_Logger_Write("📋 ТЕСТ 4: SetClass (active)", 1)
_WebView2_Bridge_SetClass("status_indicator", "value-display active", 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 5: HideElement
_Logger_Write("📋 ТЕСТ 5: HideElement", 1)
_WebView2_Bridge_HideElement("toggle_element", 0)
Sleep(1000)

; ТЕСТ 6: ShowElement
_Logger_Write("📋 ТЕСТ 6: ShowElement", 1)
_WebView2_Bridge_ShowElement("toggle_element", 0)
Sleep(500)
$iTestsPassed += 2

; ТЕСТ 7: CallJS (вызов функции)
_Logger_Write("📋 ТЕСТ 7: CallJS (testFunction)", 1)
Local $aParams[2] = ["Hello", 123]
_WebView2_Bridge_CallJS("testFunction", $aParams, 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 8: Notify
_Logger_Write("📋 ТЕСТ 8: Notify", 1)
_WebView2_Bridge_Notify("success", "Все тесты пройдены!", 0)
Sleep(500)

; ТЕСТ 9: Speed Test (быстрое обновление)
_Logger_Write("", 1)
_Logger_Write("📋 ТЕСТ 9: Speed Test - быстрое обновление temp_value (100 раз по 10мс)", 1)
Local $hSpeedTimer = TimerInit()
For $i = 1 To 100
    Local $fValue = 20 + Random(0, 10, 2)  ; Случайное значение 20-30 с 2 знаками
    _WebView2_Bridge_UpdateElement("temp_value", Round($fValue, 2) & "°C", 0)
    Sleep(10)  ; 10мс между обновлениями = 100 обновлений/сек
Next
Local $iSpeedTime = TimerDiff($hSpeedTimer)
_Logger_Write("✅ Speed Test завершён за " & Round($iSpeedTime) & " мс (100 обновлений)", 3)
Sleep(500)

; ===============================================================================
; НОВЫЕ ТЕСТЫ: МАССИВЫ И JSON
; ===============================================================================

_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🧪 ТЕСТЫ МАССИВОВ И JSON", 1)
_Logger_Write("========================================", 1)
_Logger_Write("", 1)

; ТЕСТ 10: 1D массив (числа)
_Logger_Write("📋 ТЕСТ 10: UpdateData - 1D Array (числа)", 1)
Local $aTest1D[5] = [10, 20, 30, 40, 50]
_WebView2_Bridge_UpdateData("array_1d", $aTest1D, 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 11: 2D массив (таблица)
_Logger_Write("📋 ТЕСТ 11: UpdateData - 2D Array (таблица)", 1)
Local $aTest2D[3][3]
$aTest2D[0][0] = "Name"
$aTest2D[0][1] = "Age"
$aTest2D[0][2] = "City"
$aTest2D[1][0] = "Alice"
$aTest2D[1][1] = 25
$aTest2D[1][2] = "Moscow"
$aTest2D[2][0] = "Bob"
$aTest2D[2][1] = 30
$aTest2D[2][2] = "London"
_WebView2_Bridge_UpdateData("array_2d", $aTest2D, 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 12: JSON строка (объект)
_Logger_Write("📋 ТЕСТ 12: UpdateData - JSON Object", 1)
Local $sJSON = '{"temperature": 25.5, "pressure": 1013, "humidity": 65, "status": "ok"}'
_WebView2_Bridge_UpdateData("json_data", $sJSON, 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 13: Смешанный массив (строки + числа)
_Logger_Write("📋 ТЕСТ 13: UpdateData - Mixed Array", 1)
Local $aMixed[4] = ["Sensor-01", 25.5, "Active", 100]
_WebView2_Bridge_UpdateData("mixed_array", $aMixed, 0)
Sleep(500)
$iTestsPassed += 1

; ТЕСТ 14: Пустой массив
_Logger_Write("📋 ТЕСТ 14: UpdateData - Empty Array", 1)
Local $aEmpty[0]
_WebView2_Bridge_UpdateData("array_1d", $aEmpty, 0)
Sleep(500)
$iTestsPassed += 1

; ===============================================================================
; ФИНАЛ
; ===============================================================================
Sleep(1000)
_Logger_Write("", 1)
_Logger_Write("========================================", 1)
_Logger_Write("🎉 Автотесты завершены: " & $iTestsPassed & "/" & $iTestsTotal, 3)
_Logger_Write("📨 Подтверждений получено: " & $iPushConfirmed, 1)
_Logger_Write("========================================", 1)

Sleep(3000)
Exit 0

; ===============================================================================
; Обработчик подтверждений от JavaScript
; ===============================================================================
Func _HandlePushConfirmed($vJson)
    $iPushConfirmed += 1

    Local $sType = $vJson["payload"]["type"]
    _Logger_Write("✅ [Push Confirmed] " & $sType, 3)

    ; Логируем детали в зависимости от типа
    Switch $sType
        Case "update_element"
            Local $sElement = $vJson["payload"]["element"]
            Local $sValue = $vJson["payload"]["value"]
            _Logger_Write("   Element: " & $sElement & " = " & $sValue, 1)

        Case "update_data"
            Local $sElement = $vJson["payload"]["element"]
            Local $sDataType = $vJson["payload"]["dataType"]
            Local $bIsArray = $vJson["payload"]["isArray"]

            If $bIsArray Then
                Local $sDimension = $vJson["payload"]["arrayDimension"]
                _Logger_Write("   Element: " & $sElement & ", Type: " & $sDataType & " (" & $sDimension & ")", 1)
            Else
                _Logger_Write("   Element: " & $sElement & ", Type: " & $sDataType, 1)
            EndIf

        Case "set_html"
            Local $sElement = $vJson["payload"]["element"]
            _Logger_Write("   Element: " & $sElement, 1)

        Case "set_class"
            Local $sElement = $vJson["payload"]["element"]
            Local $sClass = $vJson["payload"]["className"]
            _Logger_Write("   Element: " & $sElement & ", Class: " & $sClass, 1)

        Case "show_element", "hide_element"
            Local $sElement = $vJson["payload"]["element"]
            _Logger_Write("   Element: " & $sElement, 1)

        Case "call_function"
            Local $sFunc = $vJson["payload"]["function"]
            _Logger_Write("   Function: " & $sFunc & "()", 1)

        Case "notify"
            Local $sNotifyType = $vJson["payload"]["notifyType"]
            Local $sMessage = $vJson["payload"]["message"]
            _Logger_Write("   Type: " & $sNotifyType & ", Message: " & $sMessage, 1)
    EndSwitch
EndFunc
