#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <ScreenCapture.au3>

_Main()

Func _Main()
    Local $hBmp

    ; Захватывает весь экран
    $hBmp = _ScreenCapture_Capture("", 320, 95, 456, 138, False)

    ; Сохраняет растровый рисунок в файл
    _ScreenCapture_SaveImage (@DesktopDir & "\GDIPlus_Image.jpg", $hBmp)

EndFunc   ;==>_Main