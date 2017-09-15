@echo off
setLocal enableExtensions enableDelayedExpansion

set "dir=test-%random%"
echo creating dir: %dir%
md "%dir%"

pushd %dir%

if exist ..\binhex.exe mklink binhex.exe ..\binhex.exe
if exist ..\ASCII mklink ASCII ..\ASCII

rem reference executable
set "BASE64_ENC=base64 /e"
set "BASE64_DEC=base64 /d"
set "COMPARE=fc /b"

set "TEST=tes"
set "RESULT=RESULT"

goto mktest255X
goto mktest2X
goto mktest1X


:b64enc
    if "%~1"=="" exit /b
    echo.encoding/decoding "%1"
    %BASE64_ENC% "%1" "%1.e64"	>nul
    binhex /e "%1"		>nul
    binhex /d "%1.enc"		>nul
exit /b

:b64cmp
    if "%~1"=="" exit /b
    echo.comparing "%1"
    %COMPARE% "%1".e64 "%1.enc" >> %RESULT%
    %COMPARE% "%1" "%1.enc.dec" >> %RESULT%
exit /b


:mktest1X
echo.
echo creating test00 to- test19
for /l %%i in (0,1,19) do (
    set "target=%TEST%%%i"
    if %%i lss 10 set "target=%TEST%0%%i"
    echo.creating !target!
    echo | set /p "dummy=" > "!target!"
    for /l %%j in (1,1,%%i) do (
        set /a "k=%%j%%10"
        echo | set /p "dummy=!k!" >> "!target!"
    )
)

echo.
echo encode/decode test00 to- test19
for /l %%i in (0,1,19) do (
    set "target=%TEST%%%i"
    if %%i lss 10 set "target=%TEST%0%%i"
    call :b64enc !target!
)

echo.
echo comparing result test00 to- test19
for /l %%i in (0,1,19) do (
    set "target=%TEST%%%i"
    if %%i lss 10 set "target=%TEST%0%%i"
    call :b64cmp !target!
)

goto Done

:mktest2x
echo.
echo creating RANDOM test20 to- test29
for /l %%i in (20,1,29) do (
    set "target=%TEST%%%i"
    echo.creating !target!
    set /a "raa=!random!/!random!"
    echo | set /p "dummy=!raa!" > "!target!"
    for /l %%j in (21,1,%%i) do (
        set /a "k=!random!*%%j"
        echo | set /p "dummy=!k!" >> "!target!"
    )
)

echo.
echo encode/decode test20 to- test29
for /l %%i in (20,1,29) do call :b64enc %TEST%%%i

echo.
echo comparing result test20 to- test29
for /l %%i in (20,1,29) do call :b64cmp %TEST%%%i

goto done

:mktest255x
if not exist ASCII goto done

set MIN=0
set MAX=19
if not "%~1"=="" set /a "MAX=0 + %~1"

echo.
echo creating test000 to- test%MAX%
for /l %%i in (%MIN%,1,%MAX%) do (
    set "target=%TEST%%%i"
    if %%i lss 100 set "target=%TEST%0%%i"
    if %%i lss 10 set "target=%TEST%00%%i"
    echo.creating !target!
    copy /y ascii "!target!"	>nul
    truncate "!target!" %%i	>nul
)

echo.
echo encode/decode test000 to- test%MAX%
for /l %%i in (%MIN%,1,%MAX%) do (
    set "target=%TEST%%%i"
    if %%i lss 100 set "target=%TEST%0%%i"
    if %%i lss 10 set "target=%TEST%00%%i"
    call :b64enc !target!
)

echo.
echo comparing result test000 to- test%MAX%
for /l %%i in (%MIN%,1,%MAX%) do (
    set "target=%TEST%%%i"
    if %%i lss 100 set "target=%TEST%0%%i"
    if %%i lss 10 set "target=%TEST%00%%i"
    call :b64cmp !target!
)

goto done


:done
popd
echo.
echo Done.
echo.Result in dir: %dir%\%RESULT%

::pause

