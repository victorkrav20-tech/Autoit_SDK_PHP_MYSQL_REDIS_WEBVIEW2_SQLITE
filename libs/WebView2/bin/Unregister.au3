#RequireAdmin
#include <MsgBoxConstants.au3>

; === Конфигурация ===
Local $sDllName = "NetWebView2Lib.dll"
Local $sTlbName = "NetWebView2Lib.tlb"
Local $sNet4_x86 = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe"
Local $sNet4_x64 = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe"

Local $sLog = "Отчёт об отмене регистрации:" & @CRLF & "----------------------" & @CRLF

; Получаем полный путь к DLL
Local $sDllFullPath = @ScriptDir & '\' & $sDllName

; Конвертируем сетевой диск в локальный если нужно
If StringLeft($sDllFullPath, 2) = "Z:" Then
    Local $sDllAltPath = StringReplace(@ScriptDir, "Z:", "D:\OSPanel", 1) & '\' & $sDllName
    If FileExists($sDllAltPath) Then
        $sDllFullPath = $sDllAltPath
        $sLog &= "[*] Используется локальный путь: " & $sDllFullPath & @CRLF
    EndIf
EndIf

$sLog &= "[*] Путь к DLL: " & $sDllFullPath & @CRLF & @CRLF

; === Отмена регистрации x86 ===
If FileExists($sNet4_x86) Then
    $sLog &= "[*] Запуск RegAsm /u x86..." & @CRLF
    Local $iExitCode = RunWait('"' & $sNet4_x86 & '" /u "' & $sDllFullPath & '"', @ScriptDir, @SW_SHOW)
    $sLog &= ($iExitCode = 0 ? "[+] Отмена регистрации x86: УСПЕШНО" : "[-] Отмена регистрации x86: ОШИБКА (Код: " & $iExitCode & ")") & @CRLF
EndIf

; === Отмена регистрации x64 ===
If FileExists($sNet4_x64) Then
    $sLog &= "[*] Запуск RegAsm /u x64..." & @CRLF
    Local $iExitCode = RunWait('"' & $sNet4_x64 & '" /u "' & $sDllFullPath & '"', @ScriptDir, @SW_SHOW)
    $sLog &= ($iExitCode = 0 ? "[+] Отмена регистрации x64: УСПЕШНО" : "[-] Отмена регистрации x64: ОШИБКА (Код: " & $iExitCode & ")") & @CRLF
EndIf

; === Ручное удаление ключей реестра ===
$sLog &= @CRLF & "[*] Ручная очистка реестра..." & @CRLF

; Удаляем основной ключ класса
Local $sRegKey = "HKEY_CLASSES_ROOT\ScadaWebView2.Manager"
RegDelete($sRegKey)
If @error = 0 Then
    $sLog &= "[+] Удалён ключ: " & $sRegKey & @CRLF
Else
    $sLog &= "[-] Ключ не найден или ошибка: " & $sRegKey & @CRLF
EndIf

; Получаем CLSID и удаляем его ключи
Local $sCLSID = RegRead("HKEY_CLASSES_ROOT\ScadaWebView2.Manager\CLSID", "")
If $sCLSID <> "" Then
    $sLog &= "[*] Найден CLSID: " & $sCLSID & @CRLF

    ; Удаляем CLSID из HKCR
    RegDelete("HKEY_CLASSES_ROOT\CLSID\" & $sCLSID)
    If @error = 0 Then
        $sLog &= "[+] Удалён CLSID из HKCR" & @CRLF
    EndIf

    ; Удаляем CLSID из Wow6432Node (для x64 систем)
    RegDelete("HKEY_CLASSES_ROOT\Wow6432Node\CLSID\" & $sCLSID)
    If @error = 0 Then
        $sLog &= "[+] Удалён CLSID из Wow6432Node" & @CRLF
    EndIf
EndIf

; Удаляем TypeLib
RegDelete("HKEY_CLASSES_ROOT\TypeLib\{A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D}")
If @error = 0 Then
    $sLog &= "[+] Удалён TypeLib" & @CRLF
EndIf

$sLog &= @CRLF & "[✓] Очистка завершена!" & @CRLF

MsgBox($MB_ICONINFORMATION, "Очистка завершена", $sLog)