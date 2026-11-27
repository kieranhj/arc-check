# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# make.bat empties build\, converts the PNGs with Python 3 (py -3),
# assembles and links, builds !Chequered and copies it to ..\arculator\hostfs\Builds.
.PHONY: all build compress help
all: build

build:
	cmd /c .\make.bat

compress:
	cmd /c .\make_compress.bat

help:
	@echo make           - full build of !Chequered, deployed to ..\arculator\hostfs\Builds (make.bat)
	@echo make compress  - same with a Shrinkler-packed demo and loader (make_compress.bat)
	@echo make help      - this list
