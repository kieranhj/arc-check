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

bin\vasmarm_std_win32.exe -L build\loader.txt -m250 -Fbin -opt-adr -o build\loader.bin lib\loader.asm

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

echo Shrinkling exe...
rem bin\lz4.exe build\arc-check.bin
bin\shrinkler.exe -d -b -p -z build\arc-check.bin build\arc-check.shri

if %ERRORLEVEL% neq 0 (
	echo Failed to compress exe.
	exit /b 1
)

echo Tokenising BASIC...
bin\beebasm.exe -i src\basic_files.asm -do build\basic_files.ssd

if %ERRORLEVEL% neq 0 (
	echo Failed to tokenise BASIC.
	exit /b 1
)

echo Extracting BASIC files...
bin\bbcim -e build\basic_files.ssd screens

echo Making !folder...
set FOLDER="!Check"
if EXIST %FOLDER% del /Q "%FOLDER%"
if NOT EXIST %FOLDER% mkdir %FOLDER%

set HOSTFS=..\arculator\hostfs

echo Adding files...
copy folder\*.* "%FOLDER%\*.*"
copy build\loader.bin "%FOLDER%\!RunImage,ff8"
copy build\arc-check.shri "%FOLDER%\Demo,ffd"
copy build\basic_files.ssd.$.screens "%HOSTFS%\Screens,ffb"

echo Copying !folder...
if EXIST "%HOSTFS%\%FOLDER%" del /Q "%HOSTFS%\%FOLDER%"
if NOT EXIST "%HOSTFS%\%FOLDER%" mkdir "%HOSTFS%\%FOLDER%"
copy "%FOLDER%\*.*" "%HOSTFS%\%FOLDER%"
