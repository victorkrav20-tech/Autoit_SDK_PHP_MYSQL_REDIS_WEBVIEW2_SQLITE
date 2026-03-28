#AutoIt3Wrapper_UseX64=y
#include-once
#include <Array.au3>

; --- Подключаем CommMG x64 (работает и в x64 режиме SciTE) ---
#include "Includes\CommMG64.au3"

; --- Подключаем SDK Utils и ядро библиотеки ---
#include "..\..\libs\Utils\Utils.au3"
#include "Rs485.au3"

; ===============================================================================
; Rs485_AutoTest.au3 — Последовательный автотест всех функций библиотеки Rs485
; Без GUI, без Redis. Запускается через MCP run_script, результат в логах через _Logger_Write.
; Arduino Mega 2560, COM7, 19200, Slave ID=1, SDK_Device.ino
; ===============================================================================

; --- Настройки теста ---
Global Const $TEST_COM_PORT  = 7
Global Const $TEST_BAUD      = 19200
Global Const $TEST_SLAVE     = 1
Global Const $TEST_TIMEOUT   = 300   ; мс
; Автоопределение режима: x64 при запуске через SciTE, x32 через MCP
Global Const $TEST_COMM_MODE = (@AutoItX64 = 1) ? 64 : 32

; --- Счётчики ---
Global $g_iTestPass = 0
Global $g_iTestFail = 0
Global $g_iTestNum  = 0

; --- Запускаем ---
_SDK_Utils_Init("Rs485_AutoTest", "AutoTest", True, 1, 1, True)
_Logger_Write("[AutoTest] @ScriptDir = " & @ScriptDir, 1)
_Logger_Write("[AutoTest] @WorkingDir = " & @WorkingDir, 1)
_RunAllTests()

; ===============================================================================
; Вспомогательные функции тестирования
; ===============================================================================

Func _TestOK($sName, $sInfo = "")
    $g_iTestNum  += 1
    $g_iTestPass += 1
    _Logger_Write("[TEST " & StringFormat("%02d", $g_iTestNum) & "] PASS | " & $sName & ($sInfo <> "" ? " | " & $sInfo : ""), 3)
EndFunc

Func _TestFail($sName, $sExpected, $sGot)
    $g_iTestNum  += 1
    $g_iTestFail += 1
    _Logger_Write("[TEST " & StringFormat("%02d", $g_iTestNum) & "] FAIL | " & $sName & " | ожидалось: " & $sExpected & " | получено: " & $sGot, 2)
EndFunc

Func _TestSection($sTitle)
    _Logger_Write("", 1)
    _Logger_Write("══ " & $sTitle & " ══", 1)
EndFunc

; Сравнение float с допуском
Func _FloatEq($fA, $fB, $fTol = 0.001)
    Return Abs($fA - $fB) <= $fTol
EndFunc

; ===============================================================================
; ГЛАВНАЯ ФУНКЦИЯ — запускает все тесты по порядку
; ===============================================================================
Func _RunAllTests()
    _Logger_Write("╔══════════════════════════════════════════╗", 1)
    _Logger_Write("║   Rs485 AutoTest — SDK_Device COM7       ║", 1)
    _Logger_Write("╚══════════════════════════════════════════╝", 1)

    ; --- Блок 1: Оффлайн тесты (без порта) ---
    _TestSection("БЛОК 1: CRC16")
    _Test_CRC16()

    _TestSection("БЛОК 2: BuildRequest / Pack")
    _Test_BuildRequests()
    _Test_Pack()

    _TestSection("БЛОК 3: Парсинг из известных байт (без порта)")
    _Test_ParseOffline()

    ; --- Блок 2: Онлайн тесты (нужен COM7 + Arduino) ---
    _TestSection("БЛОК 4: Инициализация порта COM7")
    Local $bOpen = _Test_Init()

    If $bOpen Then
        _TestSection("БЛОК 5: Сброс регистров записи (11-19 → 0)")
        _Test_ResetWriteRegs()

        _TestSection("БЛОК 6: Чтение регистров 0–9 (все типы)")
        Local $aResp = _Test_ReadAll()

        If $aResp <> "" Then
            _TestSection("БЛОК 7: Парсинг всех типов из ответа Arduino")
            _Test_ParseFromDevice($aResp)

            _TestSection("БЛОК 8: ParseResponse → JSON")
            _Test_ParseResponse($aResp)

            _TestSection("БЛОК 9: Запись FC06 — UINT16")
            _Test_WriteUINT16()

            _TestSection("БЛОК 10: Запись FC16 — FLOAT32 ABCD")
            _Test_WriteFloat32ABCD()

            _TestSection("БЛОК 11: Запись FC16 — FLOAT32 CDAB")
            _Test_WriteFloat32CDAB()

            _TestSection("БЛОК 12: Запись FC16 — INT32")
            _Test_WriteINT32()

            _TestSection("БЛОК 13: Запись FC16 — UINT32")
            _Test_WriteUINT32()
        Else
            _Logger_Write("  Пропускаем тесты парсинга и записи — нет ответа от устройства", 2)
        EndIf

        _Rs485_Close()
    Else
        _Logger_Write("  Пропускаем онлайн тесты — порт не открыт", 2)
    EndIf

    ; --- Итог ---
    _Logger_Write("", 1)
    _Logger_Write("╔══════════════════════════════════════════╗", 1)
    _Logger_Write("║  ИТОГ: PASS=" & $g_iTestPass & "  FAIL=" & $g_iTestFail & "  ВСЕГО=" & $g_iTestNum, 1)
    _Logger_Write("╚══════════════════════════════════════════╝", 1)
EndFunc

; ===============================================================================
; БЛОК 1: Тест CRC16
; ===============================================================================
Func _Test_CRC16()
    ; Известный запрос: 01 03 00 00 00 14 → CRC = 45 C5
    Local $sCRC = _Rs485_CRC16("010300000014")
    If StringUpper($sCRC) = "45C5" Then
        _TestOK("CRC16 FC03 read 20 regs", "010300000014 → " & $sCRC)
    Else
        _TestFail("CRC16 FC03 read 20 regs", "45C5", $sCRC)
    EndIf

    ; FC06 write reg 11 = 0x1234: 01 06 00 0B 12 34 → CRC = ?
    ; Вычислим вручную для проверки симметрии
    Local $sReq = _Rs485_BuildWriteSingle(1, 11, 0x1234)
    ; Проверяем что строка начинается с 0x01060 0B1234
    If StringLeft($sReq, 14) = "0x0106000B1234" Then
        _TestOK("CRC16 FC06 BuildWriteSingle структура", $sReq)
    Else
        _TestFail("CRC16 FC06 BuildWriteSingle структура", "0x0106000B1234...", $sReq)
    EndIf

    ; Проверка что CRC в BuildRequest совпадает с QModMaster
    ; 01 03 00 00 00 14 45 C5 — это наш запрос чтения 20 регистров
    Local $sBuilt = _Rs485_BuildRequest(1, 3, 0, 20)
    If StringUpper($sBuilt) = "0X010300000014" & "45C5" Then
        _TestOK("BuildRequest CRC совпадает с QModMaster", $sBuilt)
    Else
        _TestFail("BuildRequest CRC совпадает с QModMaster", "0x010300000014" & "45C5", $sBuilt)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 2: Тест BuildRequest и Pack функций (без порта)
; ===============================================================================
Func _Test_BuildRequests()
    ; FC03 read 20 regs от 0
    Local $s = _Rs485_BuildRequest(1, 3, 0, 20)
    If StringLeft($s, 2) = "0x" And StringLen($s) = 18 Then
        _TestOK("BuildRequest FC03 длина строки", $s)
    Else
        _TestFail("BuildRequest FC03 длина строки", "18 символов с 0x", StringLen($s))
    EndIf

    ; FC06 write single
    Local $s6 = _Rs485_BuildWriteSingle(1, 11, 500)
    If StringLeft($s6, 2) = "0x" And StringLen($s6) = 18 Then
        _TestOK("BuildWriteSingle FC06 длина строки", $s6)
    Else
        _TestFail("BuildWriteSingle FC06 длина строки", "18 символов", StringLen($s6))
    EndIf

    ; FC16 write multiple 2 регистра
    Local $aV[2] = [0x4048, 0xF5C3]
    Local $s16 = _Rs485_BuildWriteMultiple(1, 13, $aV)
    If StringLeft($s16, 2) = "0x" Then
        _TestOK("BuildWriteMultiple FC16 структура", $s16)
    Else
        _TestFail("BuildWriteMultiple FC16 структура", "0x...", $s16)
    EndIf
EndFunc

Func _Test_Pack()
    ; Pack UINT16 ABCD: 0x00A5 → "00A5"
    Local $s = _Rs485_Pack_UINT16(0x00A5, "ABCD")
    If StringUpper($s) = "00A5" Then
        _TestOK("Pack_UINT16 ABCD 0x00A5", $s)
    Else
        _TestFail("Pack_UINT16 ABCD 0x00A5", "00A5", $s)
    EndIf

    ; Pack INT16 ABCD: -150 → 0xFF6A → "FF6A"
    Local $sI = _Rs485_Pack_INT16(-150, "ABCD")
    If StringUpper($sI) = "FF6A" Then
        _TestOK("Pack_INT16 ABCD -150", $sI)
    Else
        _TestFail("Pack_INT16 ABCD -150", "FF6A", $sI)
    EndIf

    ; Pack FLOAT32 ABCD: 3.14159 → [0x4049, 0x0FD0] (приближённо)
    Local $aF = _Rs485_Pack_FLOAT32(3.14159, "ABCD")
    If $aF[0] = 0x4049 Or $aF[0] = 0x4048 Then
        _TestOK("Pack_FLOAT32 ABCD 3.14159 hi word", Hex($aF[0],4) & " " & Hex($aF[1],4))
    Else
        _TestFail("Pack_FLOAT32 ABCD 3.14159 hi word", "4048 или 4049", Hex($aF[0],4))
    EndIf

    ; Pack FLOAT32 CDAB: 897.5
    ; Arduino floatToRegsCDAB: word0=CD, word1=AB
    ; 897.5=0x4461C000: A=44,B=61,C=C0,D=00 → word0=C0*256+00=0xC000, word1=44*256+61=0x4461
    ; НО наша Pack даёт 6000 4460 — это значит байты в памяти читаются иначе
    ; Проверяем ABCD сначала чтобы понять реальный порядок
    Local $aABCD = _Rs485_Pack_FLOAT32(897.5, "ABCD")
    Local $aC    = _Rs485_Pack_FLOAT32(897.5, "CDAB")
    _Logger_Write("[CDAB диагностика] ABCD=" & Hex($aABCD[0],4) & " " & Hex($aABCD[1],4) & " | CDAB=" & Hex($aC[0],4) & " " & Hex($aC[1],4), 1)
    ; CDAB: word0 должен быть lo(ABCD), word1 — hi(ABCD)
    If $aC[0] = $aABCD[1] And $aC[1] = $aABCD[0] Then
        _TestOK("Pack_FLOAT32 CDAB 897.5 — word swap корректен", "ABCD[1]=" & Hex($aABCD[1],4) & " ABCD[0]=" & Hex($aABCD[0],4))
    Else
        _TestFail("Pack_FLOAT32 CDAB 897.5 — word swap", "lo=" & Hex($aABCD[1],4) & " hi=" & Hex($aABCD[0],4), Hex($aC[0],4) & " " & Hex($aC[1],4))
    EndIf

    ; Pack INT32 ABCD: 100000 = 0x000186A0 → [0x0001, 0x86A0]
    Local $aI32 = _Rs485_Pack_INT32(100000, "ABCD")
    If $aI32[0] = 0x0001 And $aI32[1] = 0x86A0 Then
        _TestOK("Pack_INT32 ABCD 100000", Hex($aI32[0],4) & " " & Hex($aI32[1],4))
    Else
        _TestFail("Pack_INT32 ABCD 100000", "0001 86A0", Hex($aI32[0],4) & " " & Hex($aI32[1],4))
    EndIf
EndFunc

; ===============================================================================
; БЛОК 3: Парсинг из известных байт (без порта, симулируем ответ Arduino)
; Ответ QModMaster: 01 03 28 FF6A 00A5 03E8 4049 0FD0 6000 4460 0001 86A0 000F 4240 ...
; ===============================================================================
Func _Test_ParseOffline()
    ; Симулируем полный ответ Arduino (первые 10 регистров = 20 байт данных + заголовок 3 + CRC 2 = 25 байт)
    ; Из QModMaster: 01 03 28 FF6A 00A5 03E8 4049 0FD0 6000 4460 0001 86A0 000F 4240 + нули + CRC
    Local $aBytes[25]
    $aBytes[0]  = "01"  ; slave
    $aBytes[1]  = "03"  ; FC
    $aBytes[2]  = "28"  ; byte count = 40 (20 регистров × 2)
    ; reg[0] INT16 = -150 = 0xFF6A
    $aBytes[3]  = "FF" ; reg0 hi
    $aBytes[4]  = "6A" ; reg0 lo
    ; reg[1] UINT16 = 0x00A5 = 165
    $aBytes[5]  = "00"
    $aBytes[6]  = "A5"
    ; reg[2] UINT16 = 1000 = 0x03E8
    $aBytes[7]  = "03"
    $aBytes[8]  = "E8"
    ; reg[3][4] FLOAT32 ABCD = 3.14159 ≈ 0x40490FD0
    $aBytes[9]  = "40"
    $aBytes[10] = "49"
    $aBytes[11] = "0F"
    $aBytes[12] = "D0"
    ; reg[5][6] FLOAT32 CDAB = 897.5: CDAB word0=C000 word1=4461
    ; В потоке байты: C0 00 44 61
    $aBytes[13] = "60"  ; из QModMaster: 6000 4460 — это CDAB раскладка
    $aBytes[14] = "00"
    $aBytes[15] = "44"
    $aBytes[16] = "60"
    ; reg[7][8] INT32 ABCD = 100000 = 0x000186A0
    $aBytes[17] = "00"
    $aBytes[18] = "01"
    $aBytes[19] = "86"
    $aBytes[20] = "A0"
    ; reg[9][10] UINT32 = 1000000 = 0x000F4240
    $aBytes[21] = "00"
    $aBytes[22] = "0F"
    $aBytes[23] = "42"
    $aBytes[24] = "40"

    ; Тест INT16
    Local $iT = _Rs485_Parse_INT16($aBytes, 0, "ABCD")
    If $iT = -150 Then
        _TestOK("Parse_INT16 ABCD offset=0 → -150", $iT)
    Else
        _TestFail("Parse_INT16 ABCD offset=0", "-150", $iT)
    EndIf

    ; Тест UINT16
    Local $iU = _Rs485_Parse_UINT16($aBytes, 2, "ABCD")
    If $iU = 165 Then
        _TestOK("Parse_UINT16 ABCD offset=2 → 165", $iU)
    Else
        _TestFail("Parse_UINT16 ABCD offset=2", "165", $iU)
    EndIf

    ; Тест UINT16 счётчик
    Local $iC = _Rs485_Parse_UINT16($aBytes, 4, "ABCD")
    If $iC = 1000 Then
        _TestOK("Parse_UINT16 ABCD offset=4 → 1000", $iC)
    Else
        _TestFail("Parse_UINT16 ABCD offset=4", "1000", $iC)
    EndIf

    ; Тест FLOAT32 ABCD
    Local $fP = _Rs485_Parse_FLOAT32($aBytes, 6, "ABCD")
    If _FloatEq($fP, 3.14159, 0.001) Then
        _TestOK("Parse_FLOAT32 ABCD offset=6 → 3.14159", StringFormat("%.5f", $fP))
    Else
        _TestFail("Parse_FLOAT32 ABCD offset=6", "3.14159", StringFormat("%.5f", $fP))
    EndIf

    ; Тест INT32
    Local $iL = _Rs485_Parse_INT32($aBytes, 14, "ABCD")
    If $iL = 100000 Then
        _TestOK("Parse_INT32 ABCD offset=14 → 100000", $iL)
    Else
        _TestFail("Parse_INT32 ABCD offset=14", "100000", $iL)
    EndIf

    ; Тест UINT32
    Local $iU32 = _Rs485_Parse_UINT32($aBytes, 18, "ABCD")
    If $iU32 = 1000000 Then
        _TestOK("Parse_UINT32 ABCD offset=18 → 1000000", $iU32)
    Else
        _TestFail("Parse_UINT32 ABCD offset=18", "1000000", $iU32)
    EndIf

    ; Тест BOOL — бит 0 из reg[1]=0xA5=10100101b → бит0=1
    Local $bB = _Rs485_Parse_BOOL($aBytes, 2, 0)
    If $bB = True Then
        _TestOK("Parse_BOOL offset=2 bit=0 → True (0xA5 bit0=1)", $bB)
    Else
        _TestFail("Parse_BOOL offset=2 bit=0", "True", $bB)
    EndIf

    ; Тест BOOL — бит 1 из 0xA5=10100101b → бит1=0
    Local $bB2 = _Rs485_Parse_BOOL($aBytes, 2, 1)
    If $bB2 = False Then
        _TestOK("Parse_BOOL offset=2 bit=1 → False (0xA5 bit1=0)", $bB2)
    Else
        _TestFail("Parse_BOOL offset=2 bit=1", "False", $bB2)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 4: Инициализация порта
; ===============================================================================
Func _Test_Init()
    Local $bOk = _Rs485_Init($TEST_COM_PORT, $TEST_BAUD, $TEST_COMM_MODE)
    If $bOk Then
        _TestOK("Init COM" & $TEST_COM_PORT & " " & $TEST_BAUD & " x" & $TEST_COMM_MODE, "порт открыт")
        Return True
    Else
        _TestFail("Init COM" & $TEST_COM_PORT, "True", "False — порт не открылся")
        Return False
    EndIf
EndFunc

; ===============================================================================
; БЛОК 5: Чтение всех 20 регистров
; ===============================================================================
Func _Test_ReadAll()
    ; FC03 читаем 20 регистров от 0: ожидаем 3+40+2 = 45 байт
    Local $sReq  = _Rs485_BuildRequest($TEST_SLAVE, 3, 0, 20)
    Local $iExpected = 3 + 20 * 2 + 2  ; header + data + CRC = 45
    _Logger_Write("  Запрос: " & $sReq, 1)
    Local $aResp = _Rs485_SendAndRead($sReq, $iExpected, $TEST_TIMEOUT)
    If $aResp = "" Then
        _TestFail("ReadAll 20 регистров", "45 байт", "нет ответа / CRC ошибка")
        Return ""
    EndIf
    Local $sRaw = ""
    For $i = 0 To UBound($aResp) - 1
        $sRaw &= $aResp[$i] & " "
    Next
    _TestOK("ReadAll 20 регистров FC03", "45 байт | " & StringTrimRight($sRaw, 1))
    Return $aResp
EndFunc

; ===============================================================================
; БЛОК 6: Парсинг всех типов из реального ответа Arduino
; ===============================================================================
Func _Test_ParseFromDevice($aResp)
    ; reg[0] INT16 = -150
    Local $iT = _Rs485_Parse_INT16($aResp, 0, "ABCD")
    If $iT = -150 Then
        _TestOK("Device Parse_INT16 reg0 → -150", $iT)
    Else
        _TestFail("Device Parse_INT16 reg0", "-150", $iT)
    EndIf

    ; reg[1] UINT16 = 165
    Local $iU = _Rs485_Parse_UINT16($aResp, 2, "ABCD")
    If $iU = 165 Then
        _TestOK("Device Parse_UINT16 reg1 → 165", $iU)
    Else
        _TestFail("Device Parse_UINT16 reg1", "165", $iU)
    EndIf

    ; reg[2] UINT16 = 1000
    Local $iC = _Rs485_Parse_UINT16($aResp, 4, "ABCD")
    If $iC = 1000 Then
        _TestOK("Device Parse_UINT16 reg2 → 1000", $iC)
    Else
        _TestFail("Device Parse_UINT16 reg2", "1000", $iC)
    EndIf

    ; reg[3][4] FLOAT32 ABCD = 3.14159
    Local $fP = _Rs485_Parse_FLOAT32($aResp, 6, "ABCD")
    If _FloatEq($fP, 3.14159, 0.001) Then
        _TestOK("Device Parse_FLOAT32 ABCD reg3-4 → 3.14159", StringFormat("%.5f", $fP))
    Else
        _TestFail("Device Parse_FLOAT32 ABCD reg3-4", "3.14159", StringFormat("%.5f", $fP))
    EndIf

    ; reg[5][6] FLOAT32 CDAB = 897.5
    Local $fW = _Rs485_Parse_FLOAT32($aResp, 10, "CDAB")
    If _FloatEq($fW, 897.5, 0.1) Then
        _TestOK("Device Parse_FLOAT32 CDAB reg5-6 → 897.5", StringFormat("%.2f", $fW))
    Else
        _TestFail("Device Parse_FLOAT32 CDAB reg5-6", "897.5", StringFormat("%.2f", $fW))
    EndIf

    ; reg[7][8] INT32 = 100000
    Local $iL = _Rs485_Parse_INT32($aResp, 14, "ABCD")
    If $iL = 100000 Then
        _TestOK("Device Parse_INT32 reg7-8 → 100000", $iL)
    Else
        _TestFail("Device Parse_INT32 reg7-8", "100000", $iL)
    EndIf

    ; reg[9][10] UINT32 = 1000000
    Local $iU32 = _Rs485_Parse_UINT32($aResp, 18, "ABCD")
    If $iU32 = 1000000 Then
        _TestOK("Device Parse_UINT32 reg9-10 → 1000000", $iU32)
    Else
        _TestFail("Device Parse_UINT32 reg9-10", "1000000", $iU32)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 7: ParseResponse → JSON
; ===============================================================================
Func _Test_ParseResponse($aResp)
    ; Карта переменных для регистров 0–4 (10 байт данных)
    Local $aMap[5][6]
    $aMap[0][0]="temp_int16"
    $aMap[0][1]=0
    $aMap[0][2]="INT16"
    $aMap[0][3]="ABCD"
    $aMap[0][4]=0.1
    $aMap[0][5]="C"
    $aMap[1][0]="status"
    $aMap[1][1]=2
    $aMap[1][2]="UINT16"
    $aMap[1][3]="ABCD"
    $aMap[1][4]=1.0
    $aMap[1][5]=""
    $aMap[2][0]="counter"
    $aMap[2][1]=4
    $aMap[2][2]="UINT16"
    $aMap[2][3]="ABCD"
    $aMap[2][4]=1.0
    $aMap[2][5]=""
    $aMap[3][0]="pressure"
    $aMap[3][1]=6
    $aMap[3][2]="FLOAT32"
    $aMap[3][3]="ABCD"
    $aMap[3][4]=1.0
    $aMap[3][5]="bar"
    $aMap[4][0]="weight"
    $aMap[4][1]=10
    $aMap[4][2]="FLOAT32"
    $aMap[4][3]="CDAB"
    $aMap[4][4]=1.0
    $aMap[4][5]="kg"

    Local $sJSON = _Rs485_ParseResponse($aResp, $aMap)
    If StringInStr($sJSON, '"temp_int16"') And StringInStr($sJSON, '"pressure"') And StringInStr($sJSON, '"ts"') Then
        _TestOK("ParseResponse → JSON содержит ключи", "")
        _Logger_Write("  JSON: " & $sJSON, 3)
    Else
        _TestFail("ParseResponse → JSON", "ключи temp_int16, pressure, ts", $sJSON)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 5: Сброс регистров записи (11–19) в 0 чтобы Arduino вернул начальные значения
; ===============================================================================
Func _Test_ResetWriteRegs()
    ; Флаг сброса: пишем 0xFFFF в reg[11] — Arduino восстановит начальные значения
    Local $sReq  = _Rs485_BuildWriteSingle($TEST_SLAVE, 11, 0xFFFF)
    Local $aResp = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)
    If $aResp <> "" Then
        _TestOK("Сброс reg11=0xFFFF → Arduino восстановил начальные значения", "")
    Else
        _TestFail("Сброс reg11=0xFFFF", "echo", "нет ответа")
    EndIf
    Sleep(150)  ; даём Arduino время применить сброс
EndFunc

; ===============================================================================
; БЛОК 8–12: Тесты записи
; После каждой записи — читаем обратно и проверяем что Arduino отразил значение
; ===============================================================================

; Вспомогательная: читаем один регистр и возвращаем UINT16
Func _ReadReg($iReg)
    Local $sReq  = _Rs485_BuildRequest($TEST_SLAVE, 3, $iReg, 1)
    Local $aResp = _Rs485_SendAndRead($sReq, 7, $TEST_TIMEOUT)  ; 3+2+2=7
    If $aResp = "" Then Return -1
    Return _Rs485_Parse_UINT16($aResp, 0, "ABCD")
EndFunc

; Вспомогательная: читаем 2 регистра (для 32-бит типов)
Func _ReadReg2($iReg)
    Local $sReq  = _Rs485_BuildRequest($TEST_SLAVE, 3, $iReg, 2)
    Local $aResp = _Rs485_SendAndRead($sReq, 9, $TEST_TIMEOUT)  ; 3+4+2=9
    Return $aResp
EndFunc

; ===============================================================================
; БЛОК 8: FC06 запись UINT16
; ===============================================================================
Func _Test_WriteUINT16()
    ; Пишем 777 в reg[12] (rw_uint16), Arduino отразит в reg[1]
    Local $sReq = _Rs485_BuildWriteSingle($TEST_SLAVE, 12, 777)
    Local $aResp = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)  ; FC06 echo = 8 байт
    If $aResp = "" Then
        _TestFail("FC06 Write UINT16=777 reg12", "echo 8 байт", "нет ответа")
        Return
    EndIf
    _TestOK("FC06 Write UINT16=777 reg12 — echo получен", "")
    Sleep(50)
    ; Читаем reg[1] — должно быть 777
    Local $iVal = _ReadReg(1)
    If $iVal = 777 Then
        _TestOK("FC06 Write UINT16 — reg1 отразил 777", $iVal)
    Else
        _TestFail("FC06 Write UINT16 — reg1 отразил", "777", $iVal)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 9: FC16 запись FLOAT32 ABCD
; ===============================================================================
Func _Test_WriteFloat32ABCD()
    ; Пишем 2.71828 (e) в reg[13][14] (rw_f32_abcd), Arduino отразит в reg[3][4]
    Local $aWords = _Rs485_Pack_FLOAT32(2.71828, "ABCD")
    Local $sReq   = _Rs485_BuildWriteMultiple($TEST_SLAVE, 13, $aWords)
    Local $aResp  = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)
    If $aResp = "" Then
        _TestFail("FC16 Write FLOAT32 ABCD=2.71828 reg13-14", "echo", "нет ответа")
        Return
    EndIf
    _TestOK("FC16 Write FLOAT32 ABCD=2.71828 — echo получен", "")
    Sleep(50)
    ; Читаем reg[3][4]
    Local $aR = _ReadReg2(3)
    If $aR = "" Then
        _TestFail("FC16 Write FLOAT32 ABCD — чтение reg3-4", "ответ", "нет")
        Return
    EndIf
    Local $fVal = _Rs485_Parse_FLOAT32($aR, 0, "ABCD")
    If _FloatEq($fVal, 2.71828, 0.001) Then
        _TestOK("FC16 Write FLOAT32 ABCD — reg3-4 отразил 2.71828", StringFormat("%.5f", $fVal))
    Else
        _TestFail("FC16 Write FLOAT32 ABCD — reg3-4", "2.71828", StringFormat("%.5f", $fVal))
    EndIf
EndFunc

; ===============================================================================
; БЛОК 10: FC16 запись FLOAT32 CDAB
; ===============================================================================
Func _Test_WriteFloat32CDAB()
    ; Пишем 123.456 в reg[15][16] (rw_f32_cdab), Arduino отразит в reg[5][6]
    Local $aWords = _Rs485_Pack_FLOAT32(123.456, "CDAB")
    Local $sReq   = _Rs485_BuildWriteMultiple($TEST_SLAVE, 15, $aWords)
    Local $aResp  = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)
    If $aResp = "" Then
        _TestFail("FC16 Write FLOAT32 CDAB=123.456 reg15-16", "echo", "нет ответа")
        Return
    EndIf
    _TestOK("FC16 Write FLOAT32 CDAB=123.456 — echo получен", "")
    Sleep(50)
    Local $aR = _ReadReg2(5)
    If $aR = "" Then
        _TestFail("FC16 Write FLOAT32 CDAB — чтение reg5-6", "ответ", "нет")
        Return
    EndIf
    Local $fVal = _Rs485_Parse_FLOAT32($aR, 0, "CDAB")
    If _FloatEq($fVal, 123.456, 0.01) Then
        _TestOK("FC16 Write FLOAT32 CDAB — reg5-6 отразил 123.456", StringFormat("%.3f", $fVal))
    Else
        _TestFail("FC16 Write FLOAT32 CDAB — reg5-6", "123.456", StringFormat("%.3f", $fVal))
    EndIf
EndFunc

; ===============================================================================
; БЛОК 11: FC16 запись INT32
; ===============================================================================
Func _Test_WriteINT32()
    ; Пишем -55000 в reg[17][18], Arduino отразит в reg[7][8]
    Local $aWords = _Rs485_Pack_INT32(-55000, "ABCD")
    Local $sReq   = _Rs485_BuildWriteMultiple($TEST_SLAVE, 17, $aWords)
    Local $aResp  = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)
    If $aResp = "" Then
        _TestFail("FC16 Write INT32=-55000 reg17-18", "echo", "нет ответа")
        Return
    EndIf
    _TestOK("FC16 Write INT32=-55000 — echo получен", "")
    Sleep(50)
    Local $aR = _ReadReg2(7)
    If $aR = "" Then
        _TestFail("FC16 Write INT32 — чтение reg7-8", "ответ", "нет")
        Return
    EndIf
    Local $iVal = _Rs485_Parse_INT32($aR, 0, "ABCD")
    If $iVal = -55000 Then
        _TestOK("FC16 Write INT32 — reg7-8 отразил -55000", $iVal)
    Else
        _TestFail("FC16 Write INT32 — reg7-8", "-55000", $iVal)
    EndIf
EndFunc

; ===============================================================================
; БЛОК 12: FC16 запись UINT32
; ===============================================================================
Func _Test_WriteUINT32()
    ; Пишем 500000 в reg[19] (hi) + reg[10] уже есть lo, пишем оба через reg[19]
    ; Для простоты пишем только hi word в reg[19], Arduino отразит в reg[9]
    Local $aWords = _Rs485_Pack_UINT32(500000, "ABCD")
    ; Пишем hi в reg[19]
    Local $sReq = _Rs485_BuildWriteSingle($TEST_SLAVE, 19, $aWords[0])
    Local $aResp = _Rs485_SendAndRead($sReq, 8, $TEST_TIMEOUT)
    If $aResp = "" Then
        _TestFail("FC06 Write UINT32 hi reg19", "echo", "нет ответа")
        Return
    EndIf
    ; Пишем lo в reg[10]
    Local $sReq2 = _Rs485_BuildWriteSingle($TEST_SLAVE, 10, $aWords[1])
    _Rs485_SendAndRead($sReq2, 8, $TEST_TIMEOUT)
    _TestOK("FC06 Write UINT32=500000 reg19+10 — echo получен", "hi=" & Hex($aWords[0],4) & " lo=" & Hex($aWords[1],4))
    Sleep(50)
    Local $aR = _ReadReg2(9)
    If $aR = "" Then
        _TestFail("FC06 Write UINT32 — чтение reg9-10", "ответ", "нет")
        Return
    EndIf
    Local $iVal = _Rs485_Parse_UINT32($aR, 0, "ABCD")
    If $iVal = 500000 Then
        _TestOK("FC06 Write UINT32 — reg9-10 отразил 500000", $iVal)
    Else
        _TestFail("FC06 Write UINT32 — reg9-10", "500000", $iVal)
    EndIf
EndFunc
