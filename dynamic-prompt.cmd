@echo off

set script=%~dpn0
set template=%~dp0template.txt
set temp_file=%TEMP%\prompt.txt
set debug=0


if "%debug%"=="1" echo [Debug] First param: %1
if "%debug%"=="1" echo [Debug] Template location: %template%

REM Remove first param ("/exec")
if "%debug%"=="1" echo [Debug] All params: "%*"
for /f "tokens=1,* delims= " %%a in ("%*") do set ALL_BUT_FIRST=%%b
if "%debug%"=="1" echo [Debug] ALL_BUT_FIRST=%ALL_BUT_FIRST%

if "%1"=="/help" goto :PrintUsage
if "%1"=="/h" goto :PrintUsage
if "%1"=="/?" goto :PrintUsage

REM /init <command> <command_to_call>
if "%1"=="/init" call :Initialize %2 %3
if "%1"=="/exec" call :ExecuteOrigCommand %ALL_BUT_FIRST%

REM Set prompt and finish execution
goto :SetPrompt

REM Initialize
:Initialize
    if "%1"=="" (
        echo Missing command parameter
        call :PrintUsage
        exit /b 1
    )

    set command=%script% /exec %1 $*
    if not "%2"=="" set command=%script% /exec %2 $*

    if "%debug%"=="1" echo [Debug] Initialize: %1=%command%
    REM overriding original command
    doskey %1=%command%
    echo Dynamic prompt initialized
goto :EOF

REM Execute original command
:ExecuteOrigCommand
    if "%1"=="" (
        echo Missing command parameter: %*
        call :PrintUsage
        exit /b 1
    )

    for /f "tokens=1,* delims= " %%a in ("%*") do set ALL_BUT_FIRST=%%b
    set command=%1 %ALL_BUT_FIRST%
    if "%debug%"=="1" echo [Debug] Executing command: %command%
    REM Call orginal command
    call %command%
goto :EOF

REM SetPrompt
:SetPrompt
    if "%debug%"=="1" echo [Debug] SetPrompt

    if not exist %template% (
        echo Prompt template file does not exist: %template%
        exit /b 1
    )

    REM Evaluate variables
    for /f "delims=" %%i in (%template%) DO cmd /c "echo %%i>%temp_file%"

    REM Set prompt
    for /f "delims=" %%i in (%temp_file%) do prompt %%i
goto :EOF

REM Prints usage
:PrintUsage
    echo.
    echo Sets command prompt based on template file
    echo.
    echo dynamic-prompt [/init ^<command_to_override^> [^<command_to_issue^>]]
    echo                [/help ^| ^/^h ^| /^?]
    echo.
    echo   /init    Initializes given command
    echo   /help    Prints this help
    echo.
    echo   Usage example:
    echo.
    echo     %~n0 /init git git-wrapper.cmd
    echo       Script will run after every "git" command and will call git-wrapper.cmd
    echo       script passing all the arguments
goto :EOF
