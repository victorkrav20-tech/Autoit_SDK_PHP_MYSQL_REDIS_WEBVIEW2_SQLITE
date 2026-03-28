#pragma compile(AutoItExecuteAllowed, True)
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=img\note.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=n
; --- Настройки Au3Stripper для точного определения строк ошибок ---
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo /rsln
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; --- Подключение библиотек AutoIt ---
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <Date.au3>
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>



#NoTrayIcon

; --- Глобальные переменные ---
Global $sTestMessage = "Тестовая программа для проверки парсера ошибок"

; --- ЗАПУСК ---
ConsoleWrite("Запуск тестовой программы..." & @CRLF)
ConsoleWrite("Через 3 секунды произойдет ошибка..." & @CRLF)
sleep(10000)
; Вызываем функцию с ошибкой
ControlsssssS()

ConsoleWrite("Эта строка никогда не выполнится" & @CRLF)
















; --- ФУНКЦИЯ С ОШИБКОЙ ---
Func ControlsssssS()
    ConsoleWrite("Вошли в функцию TestErrorFunction" & @CRLF)

    ; Создаем массив с 5 элементами (индексы 0-4)
    Local $aTestArray[5]

    ; Заполняем массив
    For $i = 0 To 4
        $aTestArray[$i] = "Тестовый элемент " & $i
        ConsoleWrite("Заполнен элемент " & $i & ": " & $aTestArray[$i] & @CRLF)
    Next

    ConsoleWrite("Массив заполнен, начинаем ошибочный цикл..." & @CRLF)

    ; ОШИБОЧНЫЙ цикл - пытаемся обратиться к индексу 5, которого нет
    For $i = 0 To 5 ; ОШИБКА: должно быть 0 To 4
        ConsoleWrite("Попытка доступа к элементу " & $i & ": " & $aTestArray[$i] & @CRLF)
        Sleep(500) ; Небольшая задержка для наглядности
    Next

    ConsoleWrite("Функция завершена (этого сообщения не должно быть)" & @CRLF)
EndFunc

; --- ДОПОЛНИТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ТЕСТИРОВАНИЯ ---
Func AnotherTestFunction()
    ConsoleWrite("Эта функция не вызывается, но нужна для тестирования поиска функций" & @CRLF)
    Local $sTest = "Тестовая строка"
    Return $sTest
EndFunc