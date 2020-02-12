:::: Multicall sh runner
::
:: A multicall Windows batch file (the _runner_) to provide a transparent 
:: method to run a sh-script with [busybox-w32](http://frippery.org/busybox/).
::
:: Usage: 
::   Suppose the sh-script is "DIR_NAME/SCRIPT_NAME.sh"
::   - Copy this script to "DIR_NAME/".
::   - Rename this script to SCRIPT_NAME.cmd, to run as current user.
::   - Or, rename this script to SCRIPT_NAME.admin.cmd, to run as admin.
::   - All arguments are passed through directly to the sh-script, so be 
::     careful with quoting and slashing!
::
:: Prerequisites:
::   + `sh.exe` must be among PATH or this script's dir.
::     - `sh.exe` is just a renamed `busybox.exe` or `busybox64.exe`. 
::     - App's website: http://frippery.org/busybox/
::   + `elevate.exe` should be among PATH or this script's dir.
::     - Not required if not to run as admin.
::     - App's website: http://code.kliu.org/misc/elevate/
::
:: Author: south.guo@gmail.com
:: Timestamp: 20200212.1444

@echo off

setlocal
set "_SH_NAME=sh.exe"
set "_ADMIN_BIN=elevate.exe"

set "_SCRIPT_NAME=%~n0"
set "_SCRIPT_DIR=%~dp0"
set "PATH=%_SCRIPT_DIR%;%PATH%"

:: Find `sh.exe` and `elevate.exe`
for %%I in (%_SH_NAME%) do set "_RUN_CMD=%%~$PATH:I"
for %%I in (%_ADMIN_BIN%) do set "_ADMIN_FULL=%%~$PATH:I"

if "%_RUN_CMD%"=="" (
	echo Cannot find '%_SH_NAME%'. It should be among PATH or this script's dir.
	exit /b
)

:: Run as admin?
for %%I in (%_SCRIPT_NAME%) do set "_AS_ADMIN=%%~xI"
if "%_AS_ADMIN%"==".admin" (
	if "%_ADMIN_FULL%"=="" (
		echo Cannot find "%_ADMIN_BIN%". It should be among PATH or this script's dir.
		exit /b
	)
	set "_RUN_CMD=^"%_ADMIN_FULL%^" ^"%_RUN_CMD%^""

	for %%I in (%_SCRIPT_NAME%) do set "_SCRIPT_NAME=%%~nI"
)

:: Build the sh-script's full path
for %%I in (%_SCRIPT_DIR%%_SCRIPT_NAME%.sh) do set "_SCRIPT_FULL=%%~fI"

:: Run it.
endlocal & %_RUN_CMD% "%_SCRIPT_FULL%" %*
