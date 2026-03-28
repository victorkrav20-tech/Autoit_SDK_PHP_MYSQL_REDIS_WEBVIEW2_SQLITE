#include-once
; ===============================================================================
; Rs485.au3 — Ядро библиотеки RS-485 / Modbus RTU для AutoIt SDK
; Версия: v1.0
; Зависимости: libs/Utils/Utils.au3, Includes/CommMG.au3 или CommMG64.au3
; ===============================================================================
; СПИСОК ФУНКЦИЙ:
;   _Rs485_Init($iPort, $iSpeed, $iMode)       — открытие порта (mode: 32 или 64)
;   _Rs485_Close()                              — закрытие порта и таймера
;   _Rs485_IsOpen()                             — проверка открытости порта
;   _Rs485_CRC16($sHex)                         — CRC16 Modbus RTU
;   _Rs485_BuildRequest($iSlave,$iFC,$iReg,$iCnt) — построить FC03 запрос
;   _Rs485_BuildWriteSingle($iSlave,$iReg,$iVal)  — FC06 запись одного регистра
;   _Rs485_BuildWriteMultiple($iSlave,$iReg,$aVals) — FC16 запись нескольких
;   _Rs485_Send($sHexLine)                      — отправка hex-строки в порт
;   _Rs485_Read($iBytes, $iTimeout)             — чтение байт с таймаутом
;   _Rs485_SendAndRead($sHex,$iBytes,$iTimeout) — отправка + чтение + CRC проверка
;   _Rs485_Parse_INT16($aBytes,$iOff,$sOrder)   — парсинг INT16
;   _Rs485_Parse_UINT16($aBytes,$iOff,$sOrder)  — парсинг UINT16
;   _Rs485_Parse_INT32($aBytes,$iOff,$sOrder)   — парсинг INT32
;   _Rs485_Parse_UINT32($aBytes,$iOff,$sOrder)  — парсинг UINT32
;   _Rs485_Parse_FLOAT32($aBytes,$iOff,$sOrder) — парсинг FLOAT32 IEEE754
;   _Rs485_Parse_BOOL($aBytes,$iOff,$iBit)      — парсинг бита из регистра
;   _Rs485_Pack_INT16($iVal,$sOrder)            — упаковка INT16 → hex
;   _Rs485_Pack_UINT16($iVal,$sOrder)           — упаковка UINT16 → hex
;   _Rs485_Pack_INT32($iVal,$sOrder)            — упаковка INT32 → hex
;   _Rs485_Pack_UINT32($iVal,$sOrder)           — упаковка UINT32 → hex
;   _Rs485_Pack_FLOAT32($fVal,$sOrder)          — упаковка FLOAT32 → hex
;   _Rs485_ParseResponse($aBytes,$aVarMap)      — парсинг ответа по карте → JSON
; ===============================================================================

#include "..\..\libs\Utils\Utils.au3"

; --- Константы раскладок байт ---
Global Const $RS485_ORDER_ABCD = "ABCD"  ; Big Endian (стандарт Modbus)
Global Const $RS485_ORDER_DCBA = "DCBA"  ; Little Endian
Global Const $RS485_ORDER_CDAB = "CDAB"  ; Mid-Big (часто у ПЛК)
Global Const $RS485_ORDER_BADC = "BADC"  ; Mid-Little

; --- Глобальные переменные модуля ---
Global $g_bRs485_Open       = False   ; порт открыт
Global $g_iRs485_Port       = 0       ; номер COM порта
Global $g_iRs485_Mode       = 64      ; 32 или 64 бит CommMG
Global $g_hRs485_WinMM      = 0       ; handle winmm.dll для таймера

; ===============================================================================
; Функция: _Rs485_Init
; Описание: Открывает COM порт, загружает CommMG x32 или x64, включает таймер 1мс
; Параметры:
;   $iPort  — номер COM порта (например 7)
;   $iSpeed — скорость (например 19200)
;   $iMode  — 32 или 64 (выбор CommMG библиотеки)
; Возврат: True = успех, False = ошибка
; Пример: _Rs485_Init(7, 19200, 64)
; ===============================================================================
Func _Rs485_Init($iPort, $iSpeed, $iMode = 64)
    $g_iRs485_Mode = $iMode
    $g_iRs485_Port = $iPort

    ; Подключаем нужную версию CommMG
    Local $sLibPath = @ScriptDir & "\Includes\"
    If $iMode = 64 Then
        If Not FileExists($sLibPath & "CommMG64.au3") Then
            _Logger_Write("[Rs485] ОШИБКА: CommMG64.au3 не найден в " & $sLibPath, 2)
            Return False
        EndIf
        ; CommMG64 уже подключён через #include в AutoTest/Example
    Else
        If Not FileExists($sLibPath & "CommMG.au3") Then
            _Logger_Write("[Rs485] ОШИБКА: CommMG.au3 не найден в " & $sLibPath, 2)
            Return False
        EndIf
    EndIf

    ; Устанавливаем путь к DLL явно (CommMG ищет по имени иначе)
    ; commg.dll = x32, COMMG64.dll = x64 — имя должно совпадать с тем что в CommMG*.au3
    Local $sDllName = ($iMode = 64) ? "COMMG64.dll" : "commg.dll"
    Local $sDllPath = @ScriptDir & "\Includes\" & $sDllName
    If Not FileExists($sDllPath) Then $sDllPath = @ScriptDir & "\" & $sDllName
    _Logger_Write("[Rs485] DLL: " & $sDllPath & " | exists=" & FileExists($sDllPath), 1)
    If FileExists($sDllPath) Then
        _CommSetDllPath($sDllPath)
    Else
        _Logger_Write("[Rs485] ОШИБКА: DLL не найдена: " & $sDllPath, 2)
        Return False
    EndIf

    ; Открываем порт — CommMG использует DLL из @ScriptDir, копируем путь
    Local $iErr = 0
    Local $hPort = _CommSetPort($iPort, $iErr, $iSpeed, 8, "None", 1, 0)
    If $iErr <> 0 Or $hPort = 0 Then
        _Logger_Write("[Rs485] ОШИБКА открытия COM" & $iPort & " err=" & $iErr, 2)
        Return False
    EndIf

    ; Включаем высокое разрешение таймера (1мс)
    $g_hRs485_WinMM = DllOpen("winmm.dll")
    DllCall("winmm.dll", "uint", "timeBeginPeriod", "uint", 1)
    _Logger_Write("[Rs485] Установлено разрешение таймера 1мс (timeBeginPeriod)", 1)

    $g_bRs485_Open = True
    _Logger_Write("[Rs485] Порт COM" & $iPort & " открыт, " & $iSpeed & " бод, CommMG x" & $iMode, 3)
    Return True
EndFunc

; ===============================================================================
; Функция: _Rs485_Close
; Описание: Закрывает порт, восстанавливает таймер, освобождает DLL
; ===============================================================================
Func _Rs485_Close()
    If $g_bRs485_Open Then
        _CommClosePort()
        $g_bRs485_Open = False
        _Logger_Write("[Rs485] Порт COM" & $g_iRs485_Port & " закрыт", 1)
    EndIf
    ; Восстанавливаем стандартное разрешение таймера
    DllCall("winmm.dll", "uint", "timeEndPeriod", "uint", 1)
    If $g_hRs485_WinMM <> 0 Then
        DllClose($g_hRs485_WinMM)
        $g_hRs485_WinMM = 0
    EndIf
    _Logger_Write("[Rs485] Восстановлено стандартное разрешение таймера", 1)
EndFunc

; ===============================================================================
; Функция: _Rs485_IsOpen
; Возврат: True если порт открыт
; ===============================================================================
Func _Rs485_IsOpen()
    Return $g_bRs485_Open
EndFunc

; ===============================================================================
; Функция: _Rs485_CRC16
; Описание: Вычисляет CRC16 Modbus RTU для hex-строки
; Параметры:
;   $sHex — строка байт без "0x" и пробелов, например "010300000014"
; Возврат: строка 4 символа, младший байт первый (Modbus порядок), например "C545"
; Пример: _Rs485_CRC16("010300000014") → "45C5"
; ===============================================================================
Func _Rs485_CRC16($sHex)
    Local $iCRC = 0xFFFF
    Local $iLen = StringLen($sHex) / 2
    For $i = 0 To $iLen - 1
        Local $iByte = Dec(StringMid($sHex, $i * 2 + 1, 2))
        $iCRC = BitXOR($iCRC, $iByte)
        For $j = 0 To 7
            If BitAND($iCRC, 0x0001) Then
                $iCRC = BitShift($iCRC, 1)           ; сдвиг вправо на 1
                $iCRC = BitAND($iCRC, 0x7FFF)        ; убираем знаковый бит AutoIt
                $iCRC = BitXOR($iCRC, 0xA001)
            Else
                $iCRC = BitShift($iCRC, 1)
                $iCRC = BitAND($iCRC, 0x7FFF)
            EndIf
        Next
    Next
    ; Возвращаем: младший байт первый (little-endian для Modbus)
    Local $sLo = Hex(BitAND($iCRC, 0xFF), 2)
    Local $sHi = Hex(BitAND(BitShift($iCRC, 8), 0xFF), 2)
    Return $sLo & $sHi
EndFunc

; ===============================================================================
; Функция: _Rs485_BuildRequest
; Описание: Строит Modbus FC03 (Read Holding Registers) запрос с CRC
; Параметры:
;   $iSlave — Slave ID (1–247)
;   $iFC    — Function Code (3=read holding, 4=read input)
;   $iReg   — начальный регистр (0-based)
;   $iCnt   — количество регистров
; Возврат: hex-строка с "0x" префиксом, готовая к отправке
; Пример: _Rs485_BuildRequest(1, 3, 0, 20) → "0x010300000014" + CRC
; ===============================================================================
Func _Rs485_BuildRequest($iSlave, $iFC, $iReg, $iCnt)
    Local $sBody = Hex($iSlave, 2) & Hex($iFC, 2) & Hex($iReg, 4) & Hex($iCnt, 4)
    Local $sCRC  = _Rs485_CRC16($sBody)
    Return "0x" & $sBody & $sCRC
EndFunc

; ===============================================================================
; Функция: _Rs485_BuildWriteSingle
; Описание: Строит Modbus FC06 (Write Single Register) запрос с CRC
; Параметры:
;   $iSlave — Slave ID
;   $iReg   — номер регистра (0-based)
;   $iValue — значение UINT16
; Возврат: hex-строка с "0x" префиксом
; Пример: _Rs485_BuildWriteSingle(1, 11, 0xFF6A)
; ===============================================================================
Func _Rs485_BuildWriteSingle($iSlave, $iReg, $iValue)
    Local $sBody = Hex($iSlave, 2) & "06" & Hex($iReg, 4) & Hex(BitAND($iValue, 0xFFFF), 4)
    Local $sCRC  = _Rs485_CRC16($sBody)
    Return "0x" & $sBody & $sCRC
EndFunc

; ===============================================================================
; Функция: _Rs485_BuildWriteMultiple
; Описание: Строит Modbus FC16 (Write Multiple Registers) запрос с CRC
; Параметры:
;   $iSlave  — Slave ID
;   $iReg    — начальный регистр (0-based)
;   $aValues — одномерный массив UINT16 значений
; Возврат: hex-строка с "0x" префиксом
; Пример: _Rs485_BuildWriteMultiple(1, 13, $aFloatWords)
; ===============================================================================
Func _Rs485_BuildWriteMultiple($iSlave, $iReg, $aValues)
    Local $iCnt      = UBound($aValues)
    Local $iBytesCnt = $iCnt * 2
    Local $sBody = Hex($iSlave, 2) & "10" & Hex($iReg, 4) & Hex($iCnt, 4) & Hex($iBytesCnt, 2)
    For $i = 0 To $iCnt - 1
        $sBody &= Hex(BitAND($aValues[$i], 0xFFFF), 4)
    Next
    Local $sCRC = _Rs485_CRC16($sBody)
    Return "0x" & $sBody & $sCRC
EndFunc

; ===============================================================================
; Функция: _Rs485_Send
; Описание: Отправляет hex-строку в COM порт
; Параметры:
;   $sHexLine — строка вида "0x010300000014C5C0"
; Возврат: True = успех
; ===============================================================================
Func _Rs485_Send($sHexLine)
    If Not $g_bRs485_Open Then
        _Logger_Write("[Rs485] Send: порт не открыт", 2)
        Return False
    EndIf
    Local $bBin     = Binary($sHexLine)
    Local $iNumBytes = BinaryLen($bBin)
    Local $tData    = DllStructCreate("byte[" & $iNumBytes & "]")
    DllStructSetData($tData, 1, $bBin)
    Local $iRet = _CommSendByteArray(DllStructGetPtr($tData), $iNumBytes, 1)
    If @error Or $iRet = -1 Then
        _Logger_Write("[Rs485] Send ОШИБКА: " & @error, 2)
        Return False
    EndIf
    Return True
EndFunc

; ===============================================================================
; Функция: _Rs485_Read
; Описание: Ждёт нужное количество байт с таймаутом, возвращает массив hex-строк
; Параметры:
;   $iExpectedBytes — сколько байт ожидаем
;   $iTimeoutMs     — таймаут в миллисекундах
; Возврат: массив строк ["01","03","28",...] или "" при ошибке/таймауте
; ===============================================================================
Func _Rs485_Read($iExpectedBytes, $iTimeoutMs = 200)
    If Not $g_bRs485_Open Then Return ""
    Local $tStart = TimerInit()
    While 1
        Local $iCount = _CommGetInputCount()
        If $iCount >= $iExpectedBytes Then
            Local $tData = DllStructCreate("byte[" & $iExpectedBytes & "]")
            _CommReadByteArray(DllStructGetPtr($tData), $iExpectedBytes, 1)
            Local $sRaw = DllStructGetData($tData, 1)
            ; CommMG возвращает строку вида "0x010328FF6A..." — убираем префикс 0x
            If StringLeft($sRaw, 2) = "0x" Or StringLeft($sRaw, 2) = "0X" Then
                $sRaw = StringMid($sRaw, 3)
            EndIf
            ; Разбиваем на массив hex-байт по 2 символа
            Local $iTotal = StringLen($sRaw) / 2
            Local $aBytes[$iTotal]
            For $i = 0 To $iTotal - 1
                $aBytes[$i] = StringMid($sRaw, $i * 2 + 1, 2)
            Next
            _CommClearInputBuffer()
            Return $aBytes
        EndIf
        If TimerDiff($tStart) >= $iTimeoutMs Then
            _CommClearInputBuffer()
            _Logger_Write("[Rs485] Read таймаут: ждали " & $iExpectedBytes & " байт, получили " & $iCount, 2)
            Return ""
        EndIf
        Sleep(1)
    WEnd
EndFunc

; ===============================================================================
; Функция: _Rs485_SendAndRead
; Описание: Отправляет запрос, читает ответ, проверяет CRC
; Параметры:
;   $sHexLine       — запрос (с "0x")
;   $iExpectedBytes — ожидаемое количество байт ответа
;   $iTimeoutMs     — таймаут мс
; Возврат: массив байт или "" при ошибке CRC/таймауте
; ===============================================================================
Func _Rs485_SendAndRead($sHexLine, $iExpectedBytes, $iTimeoutMs = 200)
    _Rs485_Send($sHexLine)
    Local $aBytes = _Rs485_Read($iExpectedBytes, $iTimeoutMs)
    If $aBytes = "" Then Return ""

    ; Проверяем CRC: собираем hex без последних 2 байт
    Local $sBody = ""
    For $i = 0 To UBound($aBytes) - 3
        $sBody &= $aBytes[$i]
    Next
    Local $sCalcCRC = _Rs485_CRC16($sBody)
    Local $sRecvCRC = $aBytes[UBound($aBytes) - 2] & $aBytes[UBound($aBytes) - 1]

    If StringUpper($sCalcCRC) <> StringUpper($sRecvCRC) Then
        _Logger_Write("[Rs485] CRC ОШИБКА: вычислено=" & $sCalcCRC & " получено=" & $sRecvCRC, 2)
        Return ""
    EndIf
    Return $aBytes
EndFunc

; ===============================================================================
; ВНУТРЕННЯЯ: применить раскладку байт к 2 байтам → UINT16
; $sOrder: "ABCD","DCBA","CDAB","BADC" — берём только первые 2 символа (AB или BA)
; ===============================================================================
Func __Rs485_ApplyOrder2($sB0, $sB1, $sOrder)
    ; B0 = первый байт в потоке (старший в ABCD), B1 = второй
    Switch StringUpper($sOrder)
        Case "ABCD", "CDAB"  ; старший первый
            Return Dec($sB0 & $sB1)
        Case "DCBA", "BADC"  ; младший первый
            Return Dec($sB1 & $sB0)
    EndSwitch
    Return Dec($sB0 & $sB1)
EndFunc

; ===============================================================================
; ВНУТРЕННЯЯ: применить раскладку к 4 байтам → UINT32
; Байты в потоке: b0 b1 b2 b3
; ABCD: b0=A b1=B b2=C b3=D → результат ABCD (big endian)
; DCBA: b0=D b1=C b2=B b3=A → реверс
; CDAB: b0=C b1=D b2=A b3=B → swap words
; BADC: b0=B b1=A b2=D b3=C → swap bytes в каждом слове
; ===============================================================================
Func __Rs485_ApplyOrder4($sB0, $sB1, $sB2, $sB3, $sOrder)
    Local $iVal
    Switch StringUpper($sOrder)
        Case "ABCD"
            $iVal = Dec($sB0 & $sB1 & $sB2 & $sB3)
        Case "DCBA"
            $iVal = Dec($sB3 & $sB2 & $sB1 & $sB0)
        Case "CDAB"
            $iVal = Dec($sB2 & $sB3 & $sB0 & $sB1)
        Case "BADC"
            $iVal = Dec($sB1 & $sB0 & $sB3 & $sB2)
        Case Else
            $iVal = Dec($sB0 & $sB1 & $sB2 & $sB3)
    EndSwitch
    Return $iVal
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_INT16
; Параметры:
;   $aBytes  — массив hex-строк байт (весь ответ)
;   $iOffset — смещение в байтах от начала массива данных (после заголовка FC03: байт 3+)
;   $sOrder  — раскладка байт
; Возврат: число INT16 со знаком
; ===============================================================================
Func _Rs485_Parse_INT16($aBytes, $iOffset, $sOrder = "ABCD")
    Local $iDataStart = 3  ; FC03 ответ: [0]=slave [1]=FC [2]=byteCount, данные с [3]
    Local $iU = __Rs485_ApplyOrder2($aBytes[$iDataStart + $iOffset], $aBytes[$iDataStart + $iOffset + 1], $sOrder)
    ; Конвертируем в знаковое
    If $iU > 32767 Then $iU -= 65536
    Return $iU
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_UINT16
; ===============================================================================
Func _Rs485_Parse_UINT16($aBytes, $iOffset, $sOrder = "ABCD")
    Local $iDataStart = 3
    Return __Rs485_ApplyOrder2($aBytes[$iDataStart + $iOffset], $aBytes[$iDataStart + $iOffset + 1], $sOrder)
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_INT32
; ===============================================================================
Func _Rs485_Parse_INT32($aBytes, $iOffset, $sOrder = "ABCD")
    Local $iDataStart = 3
    Local $iU = __Rs485_ApplyOrder4($aBytes[$iDataStart+$iOffset], $aBytes[$iDataStart+$iOffset+1], _
                                     $aBytes[$iDataStart+$iOffset+2], $aBytes[$iDataStart+$iOffset+3], $sOrder)
    ; Конвертируем в знаковое 32-бит
    If $iU > 2147483647 Then $iU -= 4294967296
    Return $iU
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_UINT32
; ===============================================================================
Func _Rs485_Parse_UINT32($aBytes, $iOffset, $sOrder = "ABCD")
    Local $iDataStart = 3
    Return __Rs485_ApplyOrder4($aBytes[$iDataStart+$iOffset], $aBytes[$iDataStart+$iOffset+1], _
                                $aBytes[$iDataStart+$iOffset+2], $aBytes[$iDataStart+$iOffset+3], $sOrder)
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_FLOAT32
; Описание: Парсит 4 байта как IEEE 754 float
; ===============================================================================
Func _Rs485_Parse_FLOAT32($aBytes, $iOffset, $sOrder = "ABCD")
    Local $iDataStart = 3
    Local $iU = __Rs485_ApplyOrder4($aBytes[$iDataStart+$iOffset], $aBytes[$iDataStart+$iOffset+1], _
                                     $aBytes[$iDataStart+$iOffset+2], $aBytes[$iDataStart+$iOffset+3], $sOrder)
    ; IEEE 754: через DllStruct
    Local $tU = DllStructCreate("uint")
    Local $tF = DllStructCreate("float", DllStructGetPtr($tU))
    DllStructSetData($tU, 1, $iU)
    Return DllStructGetData($tF, 1)
EndFunc

; ===============================================================================
; Функция: _Rs485_Parse_BOOL
; Описание: Читает бит из регистра UINT16
; Параметры:
;   $aBytes  — массив байт
;   $iOffset — смещение в байтах (0-based от начала данных)
;   $iBit    — номер бита (0–15)
; ===============================================================================
Func _Rs485_Parse_BOOL($aBytes, $iOffset, $iBit = 0)
    Local $iVal = _Rs485_Parse_UINT16($aBytes, $iOffset)
    Return BitAND(BitShift($iVal, $iBit), 1) = 1
EndFunc

; ===============================================================================
; УПАКОВКА — конвертация значений в hex-строки для записи
; ===============================================================================

; ===============================================================================
; Функция: _Rs485_Pack_UINT16
; Возврат: строка 4 символа hex, например "FF6A"
; ===============================================================================
Func _Rs485_Pack_UINT16($iVal, $sOrder = "ABCD")
    Local $iV = BitAND($iVal, 0xFFFF)
    Local $sHi = Hex(BitAND(BitShift($iV, 8), 0xFF), 2)
    Local $sLo = Hex(BitAND($iV, 0xFF), 2)
    Switch StringUpper($sOrder)
        Case "ABCD", "CDAB"
            Return $sHi & $sLo
        Case "DCBA", "BADC"
            Return $sLo & $sHi
    EndSwitch
    Return $sHi & $sLo
EndFunc

; ===============================================================================
; Функция: _Rs485_Pack_INT16
; ===============================================================================
Func _Rs485_Pack_INT16($iVal, $sOrder = "ABCD")
    If $iVal < 0 Then $iVal += 65536
    Return _Rs485_Pack_UINT16($iVal, $sOrder)
EndFunc

; ===============================================================================
; Функция: _Rs485_Pack_UINT32
; Возврат: массив [hi_word, lo_word] как UINT16 значения
; ===============================================================================
Func _Rs485_Pack_UINT32($iVal, $sOrder = "ABCD")
    Local $aWords[2]
    Local $iHi = BitAND(BitShift($iVal, 16), 0xFFFF)  ; нет, BitShift(x,16) = x>>16
    ; В AutoIt BitShift(x, n) = x >> n для положительных n
    $iHi = Int($iVal / 65536)
    Local $iLo = BitAND($iVal, 0xFFFF)
    Switch StringUpper($sOrder)
        Case "ABCD"
            $aWords[0] = $iHi
            $aWords[1] = $iLo
        Case "DCBA"
            $aWords[0] = $iLo
            $aWords[1] = $iHi
        Case "CDAB"
            ; CDAB: word0=lo, word1=hi (swap words)
            $aWords[0] = $iLo
            $aWords[1] = $iHi
        Case "BADC"
            $aWords[0] = $iHi
            $aWords[1] = $iLo
        Case Else
            $aWords[0] = $iHi
            $aWords[1] = $iLo
    EndSwitch
    Return $aWords
EndFunc

; ===============================================================================
; Функция: _Rs485_Pack_INT32
; ===============================================================================
Func _Rs485_Pack_INT32($iVal, $sOrder = "ABCD")
    If $iVal < 0 Then $iVal += 4294967296
    Return _Rs485_Pack_UINT32($iVal, $sOrder)
EndFunc

; ===============================================================================
; Функция: _Rs485_Pack_FLOAT32
; Возврат: массив [hi_word, lo_word] как UINT16 значения
; ===============================================================================
Func _Rs485_Pack_FLOAT32($fVal, $sOrder = "ABCD")
    ; Получаем 4 байта IEEE754 через структуру
    Local $tF  = DllStructCreate("float")
    Local $tB  = DllStructCreate("byte[4]", DllStructGetPtr($tF))
    DllStructSetData($tF, 1, $fVal)
    ; Память little-endian: индекс 1=LSB(D), 2=C, 3=B, 4=MSB(A)
    ; Пример 897.5=0x4461C000: A=0x44,B=0x61,C=0xC0,D=0x00
    ; В памяти: [1]=0x00(D), [2]=0xC0(C), [3]=0x61(B), [4]=0x44(A)
    Local $bA = DllStructGetData($tB, 1, 4)  ; MSB
    Local $bB = DllStructGetData($tB, 1, 3)
    Local $bC = DllStructGetData($tB, 1, 2)
    Local $bD = DllStructGetData($tB, 1, 1)  ; LSB
    Local $iWordAB = $bA * 256 + $bB   ; старший word
    Local $iWordCD = $bC * 256 + $bD   ; младший word
    Local $aWords[2]
    Switch StringUpper($sOrder)
        Case "ABCD"
            $aWords[0] = $iWordAB
            $aWords[1] = $iWordCD
        Case "DCBA"
            $aWords[0] = $iWordCD
            $aWords[1] = $iWordAB
        Case "CDAB"
            $aWords[0] = $iWordCD  ; CD первый
            $aWords[1] = $iWordAB  ; AB второй
        Case "BADC"
            $aWords[0] = $bB * 256 + $bA  ; BA
            $aWords[1] = $bD * 256 + $bC  ; DC
        Case Else
            $aWords[0] = $iWordAB
            $aWords[1] = $iWordCD
    EndSwitch
    Return $aWords
EndFunc

; ===============================================================================
; Функция: _Rs485_ParseResponse
; Описание: Парсит массив байт ответа по карте переменных, возвращает JSON строку
; Параметры:
;   $aBytes  — массив байт (полный ответ включая заголовок и CRC)
;   $aVarMap — двумерный массив карты переменных [N][6]:
;              [i][0] sKey        — имя ключа
;              [i][1] iByteOffset — смещение в байтах от начала данных (0-based)
;              [i][2] sType       — "INT16","UINT16","INT32","UINT32","FLOAT32","BOOL"
;              [i][3] sByteOrder  — "ABCD","DCBA","CDAB","BADC"
;              [i][4] fScale      — множитель (1.0 = без изменений)
;              [i][5] sUnit       — единица (только для информации, в JSON не включается)
; Возврат: JSON строка вида {"ts":...,"vars":{...},"raw":"..."}
; ===============================================================================
Func _Rs485_ParseResponse($aBytes, $aVarMap)
    If $aBytes = "" Or UBound($aVarMap, 1) = 0 Then Return "{}"

    ; Формируем raw строку
    Local $sRaw = ""
    For $i = 0 To UBound($aBytes) - 1
        $sRaw &= $aBytes[$i] & " "
    Next
    $sRaw = StringTrimRight($sRaw, 1)

    ; Timestamp
    Local $sTS = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC

    ; Парсим переменные
    Local $sVars = ""
    For $i = 0 To UBound($aVarMap, 1) - 1
        Local $sKey    = $aVarMap[$i][0]
        Local $iOff    = Int($aVarMap[$i][1])
        Local $sType   = StringUpper($aVarMap[$i][2])
        Local $sOrder  = $aVarMap[$i][3]
        Local $fScale  = Number($aVarMap[$i][4])
        If $fScale = 0 Then $fScale = 1.0

        Local $vVal = 0
        Switch $sType
            Case "INT16"
                $vVal = _Rs485_Parse_INT16($aBytes, $iOff, $sOrder) * $fScale
            Case "UINT16"
                $vVal = _Rs485_Parse_UINT16($aBytes, $iOff, $sOrder) * $fScale
            Case "INT32"
                $vVal = _Rs485_Parse_INT32($aBytes, $iOff, $sOrder) * $fScale
            Case "UINT32"
                $vVal = _Rs485_Parse_UINT32($aBytes, $iOff, $sOrder) * $fScale
            Case "FLOAT32"
                $vVal = _Rs485_Parse_FLOAT32($aBytes, $iOff, $sOrder) * $fScale
            Case "BOOL"
                $vVal = _Rs485_Parse_BOOL($aBytes, $iOff) ? "true" : "false"
        EndSwitch
        If $i > 0 Then $sVars &= ","
        ; Для BOOL не добавляем кавычки, для чисел тоже
        If $sType = "BOOL" Then
            $sVars &= '"' & $sKey & '":' & $vVal
        Else
            ; Округляем float до 6 знаков
            $sVars &= '"' & $sKey & '":' & StringFormat("%.6g", $vVal)
        EndIf
    Next

    Return '{"ts":' & $sTS & ',"vars":{' & $sVars & '},"raw":"' & $sRaw & '"}'
EndFunc
