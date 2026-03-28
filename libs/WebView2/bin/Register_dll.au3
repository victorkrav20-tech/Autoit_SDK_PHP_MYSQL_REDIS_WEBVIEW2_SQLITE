#RequireAdmin
#include <MsgBoxConstants.au3>
#include <File.au3>

; === Configuration ===
Local $sDllName = "NetWebView2Lib.dll"
Local $sNet4_x86 = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe"
Local $sNet4_x64 = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe"

Local $bSuccess = False

ConsoleWrite("=== COM Registration Report ===" & @CRLF)
ConsoleWrite("-------------------------------" & @CRLF)

; === Check WebView2 Runtime ===
Local $sWV2Version = WebView2Exist()

If $sWV2Version <> "" Then
    ConsoleWrite("[+] WebView2 Runtime: Found (" & $sWV2Version & ")" & @CRLF)
Else
    ConsoleWrite("[-] WebView2 Runtime: NOT FOUND" & @CRLF)
    ConsoleWrite("[!] Download from: https://go.microsoft.com/fwlink/p/?LinkId=2124703" & @CRLF)
    Exit 1
EndIf

; === Register COM 'ScadaWebView2.dll' ===
Local $iExitCode

; Register for x86 (32-bit)
If FileExists($sNet4_x86) Then
    ConsoleWrite("[*] Running RegAsm x86..." & @CRLF)
    $iExitCode = RunWait('"' & $sNet4_x86 & '" "' & @ScriptDir & '\' & $sDllName & '" /codebase /tlb', @ScriptDir, @SW_HIDE)
    If $iExitCode = 0 Then
        ConsoleWrite("[+] x86 Registration: SUCCESS" & @CRLF)
        $bSuccess = True
    Else
        ConsoleWrite("[-] x86 Registration: FAILED (Code: " & $iExitCode & ")" & @CRLF)
    EndIf
Else
    ConsoleWrite("[!] x86 RegAsm not found" & @CRLF)
EndIf

; Register for x64 (64-bit)
If FileExists($sNet4_x64) Then
    ConsoleWrite("[*] Running RegAsm x64..." & @CRLF)
    $iExitCode = RunWait('"' & $sNet4_x64 & '" "' & @ScriptDir & '\' & $sDllName & '" /codebase /tlb', @ScriptDir, @SW_HIDE)
    If $iExitCode = 0 Then
        ConsoleWrite("[+] x64 Registration: SUCCESS" & @CRLF)
        $bSuccess = True
    Else
        ConsoleWrite("[-] x64 Registration: FAILED (Code: " & $iExitCode & ")" & @CRLF)
    EndIf
Else
    ConsoleWrite("[!] x64 RegAsm not found" & @CRLF)
EndIf

; === Final message ===
ConsoleWrite(@CRLF)
If $bSuccess Then
    ConsoleWrite("[✓] Registration completed!" & @CRLF)
    Exit 0
Else
    ConsoleWrite("[✗] Registration failed!" & @CRLF)
    Exit 1
EndIf

;---------------------------------------------------------------------------------------
Func WebView2Exist()
    ; === Method 1: Check via EdgeUpdate registry ===
    Local $aKeys[3] = [ _
        "HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients", _
        "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients", _
        "HKEY_CURRENT_USER\Software\Microsoft\EdgeUpdate\Clients" _
    ]
    Local $sSubKey, $sName, $sPv, $iIndex

    For $sRootKey In $aKeys
        For $iIndex = 1 To 500
            $sSubKey = RegEnumKey($sRootKey, $iIndex)
            If @error Then ExitLoop
            $sName = RegRead($sRootKey & "\" & $sSubKey, "name")
            If $sName = "Microsoft Edge WebView2 Runtime" Then
                $sPv = RegRead($sRootKey & "\" & $sSubKey, "pv")
                If $sPv <> "" Then Return $sPv
            EndIf
        Next
    Next

    ; === Method 2: Check files in System32 and SysWOW64 ===
    Local $aPaths[4] = [ _
        @WindowsDir & "\System32\Microsoft-Edge-WebView\EBWebView\x86\EmbeddedBrowserWebView.dll", _
        @WindowsDir & "\System32\Microsoft-Edge-WebView\EBWebView\x64\EmbeddedBrowserWebView.dll", _
        @WindowsDir & "\SysWOW64\Microsoft-Edge-WebView\EBWebView\x86\EmbeddedBrowserWebView.dll", _
        @WindowsDir & "\SysWOW64\Microsoft-Edge-WebView\EBWebView\x64\EmbeddedBrowserWebView.dll" _
    ]

    For $sPath In $aPaths
        If FileExists($sPath) Then
            Local $sVersion = FileGetVersion($sPath)
            If $sVersion <> "" Then Return $sVersion
            Return "Detected via System Files"
        EndIf
    Next

    ; === Method 3: Check via Program Files ===
    Local $aProgramPaths[4] = [ _
        @ProgramFilesDir & "\Microsoft\EdgeWebView\Application", _
        @ProgramFilesDir & " (x86)\Microsoft\EdgeWebView\Application", _
        EnvGet("ProgramFiles(x86)") & "\Microsoft\EdgeWebView\Application", _
        EnvGet("ProgramW6432") & "\Microsoft\EdgeWebView\Application" _
    ]

    For $sPath In $aProgramPaths
        If FileExists($sPath) Then
            Local $aVersions = _FileListToArray($sPath, "*.*.*.*", $FLTA_FOLDERS)
            If Not @error And IsArray($aVersions) And $aVersions[0] > 0 Then
                Return $aVersions[1]
            EndIf
            Return "Detected in Program Files"
        EndIf
    Next

    Return ""
EndFunc
