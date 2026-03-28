@echo off
chcp 65001 >nul
title Настройка и проверка NTP-сервера

echo ============================================
echo  Настройка Windows как NTP/SNTP сервера
echo ============================================

:: Настроить синхронизацию с внешним NTP-сервером
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:MANUAL /reliable:YES /update

:: Включить NTP-сервер через реестр
reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer" /v Enabled /t REG_DWORD /d 1 /f >nul

:: Перезапуск службы времени
net stop w32time >nul
net start w32time >nul

:: Открыть порт в брандмауэре
netsh advfirewall firewall add rule name="NTP Server" dir=in action=allow protocol=UDP localport=123 >nul

echo.
echo [OK] Служба Windows Time запущена и работает как NTP сервер.
echo.

:: Показать локальные IP компьютера
echo --------------------------------------------
echo  Локальный IP-адрес компьютера:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do echo   %%a
echo --------------------------------------------
echo Укажи этот IP в настройках Memograph для SNTP.
echo.

:: Проверка состояния службы
echo Проверка состояния службы времени...
w32tm /query /status
echo.

:: Проверка порта 123
echo Проверка порта 123/UDP...
netstat -an | findstr :123
echo.

:: Проверка ответа от NTP сервера (самотест)
echo Проверка ответа от NTP сервера (5 запросов)...
w32tm /stripchart /computer:localhost /samples:5 /dataonly

echo.
echo ============================================
echo  Настройка и проверка завершена.
echo  Окно закроется через 5 секунд...
timeout /t 5 /nobreak >nul