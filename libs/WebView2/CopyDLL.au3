; ===============================================================================
; CopyDLL.au3
; Automatic copying of all files and folders after compilation
; + Automatic COM DLL registration
; ===============================================================================

#include <File.au3>

; Paths
Local $sSourceDir = @ScriptDir & "\src\bin\Release\"
Local $sDestDir = @ScriptDir & "\bin\"
Local $sDllName = "NetWebView2Lib.dll"

; Check if folders exist
If Not FileExists($sSourceDir) Then
	_Logger_ConsoleWriteUTF("ERROR: Folder not found: " & $sSourceDir & @CRLF)
	Exit 1
EndIf

If Not FileExists($sDestDir) Then
	DirCreate($sDestDir)
	_Logger_ConsoleWriteUTF("Created folder: " & $sDestDir & @CRLF)
EndIf

_Logger_ConsoleWriteUTF("=== COPYING FILES AND FOLDERS ===" & @CRLF)
_Logger_ConsoleWriteUTF("Source: " & $sSourceDir & @CRLF)
_Logger_ConsoleWriteUTF("Destination: " & $sDestDir & @CRLF)
_Logger_ConsoleWriteUTF(@CRLF)

Local $iSuccess = 0
Local $iFailed = 0

; Copy all files
Local $aFiles = _FileListToArray($sSourceDir, "*", $FLTA_FILES)

If Not @error And IsArray($aFiles) Then
	For $i = 1 To $aFiles[0]
		Local $sSource = $sSourceDir & $aFiles[$i]
		Local $sDest = $sDestDir & $aFiles[$i]

		FileCopy($sSource, $sDest, 1) ; 1 = overwrite
		If @error Then
			_Logger_ConsoleWriteUTF("ERROR: " & $aFiles[$i] & @CRLF)
			$iFailed += 1
		Else
			_Logger_ConsoleWriteUTF("✓ " & $aFiles[$i] & @CRLF)
			$iSuccess += 1
		EndIf
	Next
EndIf

; Copy all folders recursively
Local $aFolders = _FileListToArray($sSourceDir, "*", $FLTA_FOLDERS)

If Not @error And IsArray($aFolders) Then
	For $i = 1 To $aFolders[0]
		Local $sSourceFolder = $sSourceDir & $aFolders[$i]
		Local $sDestFolder = $sDestDir & $aFolders[$i]

		; Copy folder recursively
		DirCopy($sSourceFolder, $sDestFolder, 1) ; 1 = overwrite
		If @error Then
			_Logger_ConsoleWriteUTF("ERROR: Folder " & $aFolders[$i] & @CRLF)
			$iFailed += 1
		Else
			_Logger_ConsoleWriteUTF("✓ [FOLDER] " & $aFolders[$i] & @CRLF)
			$iSuccess += 1
		EndIf
	Next
EndIf

; Copy summary
_Logger_ConsoleWriteUTF(@CRLF & "=== COPY SUMMARY ===" & @CRLF)
_Logger_ConsoleWriteUTF("Copied: " & $iSuccess & @CRLF)
_Logger_ConsoleWriteUTF("Errors: " & $iFailed & @CRLF)
_Logger_ConsoleWriteUTF(@CRLF)

; === AUTOMATIC COM DLL REGISTRATION ===
_Logger_ConsoleWriteUTF("=== COM DLL REGISTRATION ===" & @CRLF)

Local $sNet4_x86 = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe"
Local $sNet4_x64 = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe"
Local $sDllPath = $sDestDir & $sDllName

If Not FileExists($sDllPath) Then
	_Logger_ConsoleWriteUTF("ERROR: DLL not found: " & $sDllPath & @CRLF)
	Exit 1
EndIf

Local $bRegSuccess = False

; Register x86
If FileExists($sNet4_x86) Then
	_Logger_ConsoleWriteUTF("Registering x86..." & @CRLF)
	Local $iExitCode = RunWait('"' & $sNet4_x86 & '" "' & $sDllPath & '" /codebase /tlb', $sDestDir, @SW_HIDE)
	If $iExitCode = 0 Then
		_Logger_ConsoleWriteUTF("✓ x86 Registration: SUCCESS" & @CRLF)
		$bRegSuccess = True
	Else
		_Logger_ConsoleWriteUTF("ERROR: x86 Registration FAILED (Code: " & $iExitCode & ")" & @CRLF)
	EndIf
Else
	_Logger_ConsoleWriteUTF("WARNING: x86 RegAsm not found" & @CRLF)
EndIf

; Register x64
If FileExists($sNet4_x64) Then
	_Logger_ConsoleWriteUTF("Registering x64..." & @CRLF)
	Local $iExitCode = RunWait('"' & $sNet4_x64 & '" "' & $sDllPath & '" /codebase /tlb', $sDestDir, @SW_HIDE)
	If $iExitCode = 0 Then
		_Logger_ConsoleWriteUTF("✓ x64 Registration: SUCCESS" & @CRLF)
		$bRegSuccess = True
	Else
		_Logger_ConsoleWriteUTF("ERROR: x64 Registration FAILED (Code: " & $iExitCode & ")" & @CRLF)
	EndIf
Else
	_Logger_ConsoleWriteUTF("WARNING: x64 RegAsm not found" & @CRLF)
EndIf

_Logger_ConsoleWriteUTF(@CRLF & "=== FINAL SUMMARY ===" & @CRLF)
_Logger_ConsoleWriteUTF("Copying: " & ($iFailed = 0 ? "✓ OK" : "ERROR") & @CRLF)
_Logger_ConsoleWriteUTF("Registration: " & ($bRegSuccess ? "✓ OK" : "ERROR") & @CRLF)

If $iFailed > 0 Or Not $bRegSuccess Then
	Exit 1
Else
	Exit 0
EndIf

Func _Logger_ConsoleWriteUTF($sText)
    ConsoleWrite(BinaryToString(StringToBinary($sText, 4)))
EndFunc
