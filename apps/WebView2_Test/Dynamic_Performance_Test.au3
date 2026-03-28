; ===============================================================================
; Dynamic_Performance_Test.au3 - Тест производительности с динамическим контентом
; Версия: 1.0.0
; Описание: Проверка влияния флагов оптимизации на динамический контент
; ===============================================================================

#include-once
#include "..\..\libs\SDK_Init.au3"

Global $sAppName = "Dynamic_Perf_Test"

_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("🔥 ТЕСТ ДИНАМИЧЕСКОЙ ПРОИЗВОДИТЕЛЬНОСТИ")
_Logger_ConsoleWriteUTF("========================================")

; Инициализация
_SDK_Init($sAppName, True, 3, 3, True)
_SDK_WebView2_Init("local", @ScriptDir & "\profile", "", @ScriptDir & "\gui", "")

Opt("GUIOnEventMode", 1)

_WebView2_GUI_Create(0, "Dynamic Performance Test", 1200, 600)
_WebView2_GUI_Show()

_WebView2_Events_WaitForReady(0, 10000)

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("📊 ТЕСТ 1: Статичная страница (test.html)")
_Logger_ConsoleWriteUTF("========================================")

Local $hTimer1 = TimerInit()
_WebView2_Nav_Load("test.html")
Sleep(1000)  ; Даём время на загрузку
Local $fTime1 = TimerDiff($hTimer1)
_Logger_ConsoleWriteUTF("✅ Время загрузки: " & Round($fTime1, 2) & " мс")

Sleep(2000)

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("📊 ТЕСТ 2: Динамическая страница (dynamic_test.html)")
_Logger_ConsoleWriteUTF("========================================")

Local $hTimer2 = TimerInit()
_WebView2_Nav_Load("dynamic_test.html")
Sleep(1000)  ; Даём время на загрузку
Local $fTime2 = TimerDiff($hTimer2)
_Logger_ConsoleWriteUTF("✅ Время загрузки: " & Round($fTime2, 2) & " мс")

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("⏱️ Страница с таймерами работает...")
_Logger_ConsoleWriteUTF("💡 Проверь загрузку CPU в диспетчере задач!")
_Logger_ConsoleWriteUTF("💡 Счётчики должны обновляться плавно")

Sleep(5000)

_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("📊 СВОДКА")
_Logger_ConsoleWriteUTF("========================================")
_Logger_ConsoleWriteUTF("Статичная страница: " & Round($fTime1, 2) & " мс")
_Logger_ConsoleWriteUTF("Динамическая страница: " & Round($fTime2, 2) & " мс")
_Logger_ConsoleWriteUTF("")
_Logger_ConsoleWriteUTF("🎉 Тест завершён!")
_Logger_ConsoleWriteUTF("========================================")

Exit 0
