#RequireAdmin
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <MsgBoxConstants.au3>

; === Конфигурация ===
Local $sSearchTerm = "ScadaWebView2"
Local $aTargets[2] = ["HKEY_LOCAL_MACHINE64\SOFTWARE\Classes", "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Classes"]

; Создание GUI
Local $iWidth = @DesktopWidth * 0.7 , $iHeight = @DesktopHeight * 0.9
Local $hGUI = GUICreate("ScadaWebView2 - Глубокая очистка реестра", $iWidth, $iHeight)
GUISetFont(9, 400, 0, "Segoe UI")
$iWidth -= 20
$iHeight -= 90
Local $idListView = GUICtrlCreateListView("Путь к ключу реестра|Детали", 10, 10, $iWidth, $iHeight, $LVS_REPORT + $LVS_SHOWSELALWAYS)
_GUICtrlListView_SetExtendedListViewStyle($idListView, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
_GUICtrlListView_SetColumnWidth($idListView, 0, $iWidth * 0.6)
_GUICtrlListView_SetColumnWidth($idListView, 1, $iWidth * 0.4)
$iHeight += 20
Local $idStatus = GUICtrlCreateLabel("Сканирование реестра... пожалуйста, подождите...", 10, $iHeight, $iWidth - 210 - 10, 20)
$iHeight += 20
Local $idBtnCancel = GUICtrlCreateButton("Отмена", $iWidth - 100, $iHeight, 100, 40)
Local $idBtnDelete = GUICtrlCreateButton("Удалить выбранное", $iWidth - 210, $iHeight, 100, 40)
GUISetState(@SW_SHOW)

; Сканирование
Local $iTotalFound = 0
For $sRoot In $aTargets
    _Registry_Scan_Recursive($sRoot, $sSearchTerm, $idListView, $iTotalFound)
Next
GUICtrlSetData($idStatus, "Сканирование завершено. Найдено " & $iTotalFound & " ключей.")

While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE, $idBtnCancel
            Exit

        Case $idBtnDelete
            Local $iCheckedCount = 0
            ; Сначала подсчитываем отмеченные элементы
            For $i = 0 To _GUICtrlListView_GetItemCount($idListView) - 1
                If _GUICtrlListView_GetItemChecked($idListView, $i) Then $iCheckedCount += 1
            Next

            If $iCheckedCount = 0 Then
                MsgBox($MB_ICONEXCLAMATION, "Ничего не выбрано", "Пожалуйста, отметьте ключи, которые хотите удалить.")
                ContinueLoop
            EndIf

            If MsgBox($MB_YESNO + $MB_ICONWARNING, "Подтверждение удаления", "Вы уверены, что хотите удалить " & $iCheckedCount & " выбранных ключей?") = $IDYES Then
                _Delete_Checked_Items($idListView)
                MsgBox($MB_ICONINFORMATION, "Готово", "Очистка успешно завершена.")
                Exit
            EndIf
    EndSwitch
WEnd

;---------------------------------------------------------------------------------------
Func _Registry_Scan_Recursive($sKey, $sSearch, $hLV, ByRef $iCount)
    Local $iIndex = 1
    While 1
        Local $sSubKey = RegEnumKey($sKey, $iIndex)
        If @error Then ExitLoop

		If Mod($iIndex, 100) = 0 Then
			GUICtrlSetData($idStatus, "Сканирование: " & $iIndex & " ключей в " & StringLeft($sKey, 40) & "...")
		EndIf

        Local $sFull = $sKey & "\" & $sSubKey
        Local $sData = RegRead($sFull, "")

        If StringInStr($sSubKey, $sSearch) Or StringInStr($sData, $sSearch) Then
            $iCount += 1
            Local $sDisplayData = ($sData <> "" ? $sData : "Папка/Контейнер")
            GUICtrlCreateListViewItem($sFull & "|" & $sDisplayData, $hLV)
            _GUICtrlListView_SetItemChecked($hLV, _GUICtrlListView_GetItemCount($hLV) - 1)
        EndIf

        _Registry_Scan_Recursive($sFull, $sSearch, $hLV, $iCount)
        $iIndex += 1
    WEnd
EndFunc
;---------------------------------------------------------------------------------------
Func _Delete_Checked_Items($hLV)
    ; Удаление в обратном порядке для избежания смещения индексов
    For $i = _GUICtrlListView_GetItemCount($hLV) - 1 To 0 Step -1
        If _GUICtrlListView_GetItemChecked($hLV, $i) Then
            Local $sKeyPath = _GUICtrlListView_GetItemText($hLV, $i)
            If RegDelete($sKeyPath) Then
                ConsoleWrite("[-] Удалено: " & $sKeyPath & @CRLF)
            EndIf
        EndIf
    Next
EndFunc
;---------------------------------------------------------------------------------------
