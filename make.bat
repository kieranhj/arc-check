@echo off

echo Start build...
if EXIST build del /Q build\*.*
if NOT EXIST build mkdir build

if %ERRORLEVEL% neq 0 (
	echo Failed to make  code.
	exit /b 1
)

echo Assembling code...
bin\vasmarm_std_win32.exe -L build\compile.txt -m250 -Fvobj -opt-adr -o build\arc-check.o arc-check.asm

if %ERRORLEVEL% neq 0 (
	echo Failed to assemble code.
	exit /b 1
)

echo Linking code...
bin\vlink.exe -T link_script.txt -b rawbin1 -o build\arc-check.bin build\arc-check.o -Mbuild\linker.txt

if %ERRORLEVEL% neq 0 (
	echo Failed to link code.
	exit /b 1
)

echo Making !folder...
set FOLDER="!Check"
if EXIST %FOLDER% del /Q "%FOLDER%"
if NOT EXIST %FOLDER% mkdir %FOLDER%

echo Adding files...
copy folder\*.* "%FOLDER%\*.*"
copy build\arc-check.bin "%FOLDER%\!RunImage,ff8"

echo Copying !folder...
set HOSTFS=..\arculator\hostfs
if EXIST "%HOSTFS%\%FOLDER%" del /Q "%HOSTFS%\%FOLDER%"
if NOT EXIST "%HOSTFS%\%FOLDER%" mkdir "%HOSTFS%\%FOLDER%"
copy "%FOLDER%\*.*" "%HOSTFS%\%FOLDER%"
