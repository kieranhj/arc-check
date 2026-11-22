# arc-check: start here

The Checkerboard Challenge for the Acorn Archimedes: a small demo (`!Chequered`) in ARM assembler (vasm + vlink), with screens in tokenised BBC BASIC and a Lua script (`checks.lua`) for generating checks.

| | |
|---|---|
| GitHub | https://github.com/kieranhj/arc-check (public) |
| Local path | D:\archie\mine\arc-check (moved from OneDrive\Archie\Repos\arc-check on 2026-11-22) |
| Branch | main; other branches: wip/2026-11-tidy, wip/dual-playfield, wip/lua-scripting, wip/self-mod-loop, wip/six-layers-only |
| Last commit | 2023-06-24: Remove earlier MODs. |

## What's in here

- `arc-check.asm` entry, `src/`, `lib/`; `checks.lua`.
- `data/gfx` (1-bit screens, icon), MOD music; `folder/` (files copied into the app folder).
- `bin/`: vasm, vlink, beebasm, bbcim, Shrinkler, LZ4, Python converters.
- `make.bat` (dev build), `make_compress.bat` (release with Shrinkler + loader), `link_script.txt`.

## Build and run

- The `bin\*.py` converters were ported to Python 3 on 2026-11-22 (byte-identical output) and `make_compress.bat` now calls `py -3`.
- `make`: runs `make.bat`. **Still blocked**: `make.bat` has an uncommitted local edit, so it was not changed and still calls `c:\dev\Python27\python.exe` (not on this machine). It empties `build\` first, so a failed run leaves `build\` empty. Fix: replace the 5 `c:\dev\Python27\python.exe` calls in `make.bat` with `py -3`.
- `make compress` runs `make_compress.bat`; `make help` lists targets.
- On success both scripts build `!Chequered` in the repo and copy it plus `Screens,ffb` into `..\arculator\hostfs` (`D:\archie\mine\arculator\hostfs`). Run `!Chequered` in Arculator.

## Local changes

- Uncommitted (4 files): `arc-check.asm`, `checks.lua`, `make.bat` (adds `-vicelabels build\vice.txt` to the link), `ref/blueberry checkerboard.txt`.
- `wip/2026-11-tidy` (pushed): a snapshot of exactly those edits.
- wip/dual-playfield, wip/lua-scripting, wip/self-mod-loop, wip/six-layers-only are all fully merged into main (0 commits ahead); safe to delete if wanted.

## Status and next steps

- Final/RC builds were made 2023-06-23; the uncommitted edits (Lua checks, Blueberry checkerboard notes) look like later experiments. No TODO/plan notes found.

## See also

- `README.md`, `ref/`; `D:\archie\mine\arculator` (emulator + hostfs).
