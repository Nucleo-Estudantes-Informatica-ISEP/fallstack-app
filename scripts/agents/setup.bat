@echo off
rem Windows entry point for setup.sh: finds Git Bash and runs the shell script.
rem Usage: scripts\agents\setup.bat [--no-guide] <agent>...
setlocal

set "BASH="
for /f "delims=" %%G in ('where git 2^>nul') do (
  if not defined BASH if exist "%%~dpG..\bin\bash.exe" set "BASH=%%~dpG..\bin\bash.exe"
)
if not defined BASH if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH=%ProgramFiles%\Git\bin\bash.exe"

if not defined BASH (
  echo error: Git Bash not found. Install Git for Windows, or run scripts/agents/setup.sh from WSL. 1>&2
  exit /b 1
)

set "SCRIPT=%~dp0setup.sh"
"%BASH%" "%SCRIPT:\=/%" %*
exit /b %ERRORLEVEL%
