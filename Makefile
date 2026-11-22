# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# make.bat empties build\, converts the PNGs with Python 2.7 (c:\dev\Python27\python.exe),
# assembles and links, builds !Chequered and copies it to ..\arculator\hostfs.
.PHONY: all build compress help
all: build

build:
	cmd /c .\make.bat

compress:
	cmd /c .\make_compress.bat

help:
	@echo make           - full build of !Chequered, deployed to ..\arculator\hostfs (make.bat)
	@echo make compress  - same with a Shrinkler-packed demo and loader (make_compress.bat)
	@echo make help      - this list
	@echo Needs Python 2.7 at c:\dev\Python27\python.exe for the asset conversion.
