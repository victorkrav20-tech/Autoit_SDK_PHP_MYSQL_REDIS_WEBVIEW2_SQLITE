#include <ScreenCapture.au3>
#include <GDIPlus.au3>
#include "..\UWPOCR.au3"


_Example()

Func _Example()

	#Region - create example bitmap	- take a screenshot
	_GDIPlus_Startup()
	;hImage/hBitmap GDI

	While 1
	Local $hTimer = TimerInit()
	;Local $hHBitmap = _ScreenCapture_Capture("", 320, 95, 456, 145, False)
	Local $hHBitmap = _ScreenCapture_Capture("", 239, 72, 585, 130, False)
	;_ScreenCapture_SaveImage (@ScriptDir & "\GDIPlus_Image.bmp", $hHBitmap)
	Local $hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hHBitmap)
	#EndRegion - create example bitmap	- take a screenshot

	#Region - do the OCR Stuff
	;Get OCR Text From hImage/hBitmap
;~ 	_UWPOCR_Log(__UWPOCR_Log) ;Enable Log
	Local $sOCRTextResult = _UWPOCR_GetText($hBitmap, Default, True)
	;MsgBox(0, "Time Elapsed: " & TimerDiff($hTimer), $sOCRTextResult)
	ToolTip('')
	ToolTip($sOCRTextResult)
	#EndRegion - do the OCR Stuff

	#Region - bitmap clean up
	_WinAPI_DeleteObject($hHBitmap)
	_GDIPlus_BitmapDispose($hBitmap)

	Wend



	_GDIPlus_Shutdown()
	#EndRegion - bitmap clean up

EndFunc   ;==>_Example
