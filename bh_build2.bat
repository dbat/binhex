@echo OFF
if "%OS%"=="Windows_NT" setLocal
goto START

:getbasename
set "basename="
if not "%~1"=="" set "basename=%~n1"
exit /b


:START
rem set your PATH here to tasm and bcc55
rem set PATH=

rem example:
rem set "BCCINC=-Ie:\c\bcc55\include"
rem set "BCCLIB=-Le:\c\cc55\lib;e:\c\bcc55\projects\libs"
rem set "LNKLIB=-Le:\c\bcc55\lib;e:\c\bcc55\lib\PSDK"

rem I used to make symlink .bin and/or bin to whatever directory need in path
rem That way we can insert a permanent entries to PATH such as: ".bin;%PATH%;bin"

rem //assemble: tasm32 /q /la /ml /zn bin2hex.asm
rem //compile:  bcc32 /c binhex.c
rem //link:     ilink32  c0x32  binhex bbq,binhex,,import32  cw32

set "ASRC=bbq"
set "CSRC=binhex"
set "ASM=tasm32 /q /la /ml /zn"
set "ASM=tasm32"
set "ASMOPT=/lq /la /ml /zn"
rem on uasm, name decoration must be off (-zt0)
rem set "ASM=uasm -zt0 -Fl"
rem set "ASM=uasm -Zg -Zcw -zt0 -Fl"
rem set "ASM=uasm -zlc -zld -zt0 -Fl"
rem set "ASM=uasm -zze -zlc -zld -zt0 -Fl"
rem set "ASM=uasm -zt0 -Fl"
rem set "ASM=uasm -Zd -Zf -zt0 -Fl"
rem set "ASRC=bbqq"
rem set "ASM=nasm -t -fobj -l %asrc%.lst -o %asrc%.obj"

if "%~1"=="2" set "ASM=uasm"
if "%~1"=="3" set "ASM=nasm"
if "%~1"=="4" set "ASM=jwasm"
if "%~1"=="5" set "ASM=lzasm"

if "%~1"=="2" set "ASRC=bbqu"
if "%~1"=="3" set "ASRC=bbqq"
if "%~1"=="4" set "ASRC=bbqa"
if "%~1"=="5" set "ASRC=bbqz"

if "%~1"=="2" set "ASMOPT=-Zv8 -Zd -Zf -zt0 -Fl"
if "%~1"=="2" set "ASMOPT=-Zd -Zf -zt0 -Fl"
if "%~1"=="2" set "ASMOPT=-Zv8 -Gz -Zf -zt0 -Fl"

if "%~1"=="3" set "ASMOPT=-t -fobj -l %asrc%.lst -o %asrc%.obj"
if "%~1"=="3" set "ASMOPT=-t -fobj -l %asrc%.lst -Ox"

if "%~1"=="4" set "ASMOPT=-Zv8 -Zd -Zf -zt0 -Fl"
if "%~1"=="4" set "ASMOPT=-Zd -Zf -zt0 -Fl"
if "%~1"=="4" set "ASMOPT=-Zf -zt0 -Fl"

if "%~1"=="5" set "ASMOPT=/q /la /ml /zn"


if "%OS%"=="Windows_NT" pushd "%~dp0"
echo.
echo.- assembling %asrc%.asm: %ASM% %asrc%

rem if /i "%asrc%"=="bbqq" %ASM% %asrc%.nasm
rem if /i not "%asrc%"=="bbqq" %ASM% %asrc%.asm
rem call :getbasename %ASM%
set "ext="

rem if defined basename set "ext=.%basename%"
rem if not defined basename set "ext="
rem if /i "%basename%"=="tasm32" set "ext=.asm"
set "ext=.%ASM%"
if /i "%ASM%"=="tasm32" set "ext=.asm"

%ASM% %ASMOPT% %ASRC%%ext% 

::echo. 
echo.- compiling %csrc%.c: bcc32 %BCCINC%%BCCLIB% /c %csrc%.c
bcc32 %BCCINC% %BCCLIB% /c %csrc%.c >nul

::echo.
echo.- linking %csrc% %asrc                %: ilink32 %LNKLIB% c0x32 %csrc% %asrc%,%csrc%,,import32 cw32
ilink32 %LNKLIB%  c0x32  %csrc%  %asrc%, %csrc%,, import32  cw32

::echo.
echo.Done


if "%OS%"=="Windows_NT" popd
::pause