@echo OFF

if "%OS%"=="WinNT" setLocal
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


if "%OS%"=="WinNT" pushd "%~dp0"

echo.
echo.- assembling %asrc%.asm
tasm32 /q /la /ml /zn  %asrc%.asm

rem echo.
echo.- compiling %csrc%.c
bcc32 %BCCINC% %BCCLIB% /c %csrc%.c

echo.
echo.- linking %csrc% %asrc%
ilink32 %LNKLIB%  c0x32  %csrc%  %asrc%, %csrc%,, import32  cw32

echo.
echo.Done


if "%OS%"=="WinNT" popd
