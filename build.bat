@echo off
for %%d in ("%cd%") do set src=%%~nxd
set ext=c
set COMPILER=cl /nologo

if exist "%src%.%ext%" goto goon1

for %%f in (*.%ext%) do src=%%f
if not exist "%src%.%ext%" goto eof

:goon1
del /q %src%.obj %src%.exe >nul 2>&1

%COMPILER% "%src%.%ext%"
echo build error: %errorlevel%
if not errorlevel 0 goto skip1

set build=build

if not exist %build% echo.0>%build%
for /f "eol=; tokens=1" %%i in (%build%) do set n=%%i
set /a n=%n%+1
echo.%n%>%build%

:skip1
if not exist %src%.exe goto eof


%src%.exe %*
echo errorlevel is %errorlevel%

:eof
