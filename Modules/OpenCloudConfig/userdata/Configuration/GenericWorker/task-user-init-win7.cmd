:: Task User initialisation script - this script runs as task user, not as administrator.
:: It runs after task user has logged in, but before worker claims a task.

:WaitForExplorerKey
echo Wait for Explorer registry key to exist before adding sub key...
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer /ve
if %ERRORLEVEL% EQU 0 goto HideTaskBar
echo HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer does not yet exist
:: Cannot use timeout command from non-interactive process
:: (try it yourself with e.g. `echo hello | timeout /t 1`)
ping -n 2 127.0.0.1 1>/nul
goto WaitForExplorerKey

:HideTaskBar
echo Hiding taskbar...
:: The value below was obtained simply by manually hiding taskbar, and then
:: seeing what the setting was. Prior to hiding the task bar, the StuckRects2
:: key did not exist, so we can't use the same trick we use on Windows 10.
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects2 /v Settings /t REG_BINARY /d 28000000ffffffff03000000030000003e0000002800000000000000d80300000005000000040000 /f
:: Need to stop and start explorer for change to take effect
taskkill /im explorer.exe /f
:: Wait 3 seconds before starting
ping -n 4 127.0.0.1 1> nul
start explorer.exe

:: Holding off including this here for now, as we will likely be doing this in preflight
:: scripts in future. See: https://bugzilla.mozilla.org/show_bug.cgi?id=1396168#c13
:: 
:: :: Task user firewall exceptions
:: netsh advfirewall firewall add rule name="ssltunnel-%USERNAME%" dir=in action=allow program="%USERPROFILE%\build\tests\bin\ssltunnel.exe" enable=yes
:: netsh advfirewall firewall add rule name="ssltunnel-%USERNAME%" dir=out action=allow program="%USERPROFILE%\build\tests\bin\ssltunnel.exe" enable=yes
:: netsh advfirewall firewall add rule name="python-%USERNAME%" dir=in action=allow program="%USERPROFILE%\build\venv\scripts\python.exe" enable=yes
:: netsh advfirewall firewall add rule name="python-%USERNAME%" dir=out action=allow program="%USERPROFILE%\build\venv\scripts\python.exe" enable=yes

echo Completed task user initialisation.
