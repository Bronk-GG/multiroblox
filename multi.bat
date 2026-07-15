@echo off
:: Überprüfen, ob die Batch-Datei bereits als Administrator läuft
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :runScript
) else (
    goto :elevate
)

:elevate
:: Wenn nicht, fordert die Batch-Datei jetzt Admin-Rechte an
echo need admin rights..
powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
exit /b

:runScript
:: In den Ordner der Batch-Datei wechseln
cd /d "%~dp0"

:: Das PowerShell-Skript starten (Name eventuell anpassen!)
echo waiting 5 sec for Roblox to start...
timeout /t 5
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "multiroblox.ps1"

echo.
echo Fertig!
pause