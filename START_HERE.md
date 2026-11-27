# arc-check: start here

The Checkerboard Challenge for the Acorn Archimedes: a small demo (`!Chequered`) in ARM assembler (vasm + vlink), with screens in tokenised BBC BASIC and a Lua script (`checks.lua`) for generating checks.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/arc-check (public; transferred from kieranhj/arc-check on 2026-11-27, old URL redirects) |
| Local path | D:\bitshifters\arc-check (moved from D:\archie\mine on 2026-11-27; before that OneDrive\Archie\Repos) |
| Branch | main; other branches: wip/2026-11-tidy, wip/dual-playfield, wip/lua-scripting, wip/self-mod-loop, wip/six-layers-only |
| Last commit | 2023-06-24: Remove earlier MODs. |

## What's in here

- `arc-check.asm` entry, `src/`, `lib/`; `checks.lua`.
- `data/gfx` (1-bit screens, icon), MOD music; `folder/` (files copied into the app folder).
- `bin/`: vasm, vlink, beebasm (replaced 2026-11-22 with the current 64-bit build; the old one needed the VC++ 2010 runtime), bbcim, Shrinkler, LZ4, Python converters.
- `make.bat` (dev build), `make_compress.bat` (release with Shrinkler + loader), `link_script.txt`.

## Build and run

- The `bin\*.py` converters were ported to Python 3 on 2026-11-22 (byte-identical output) and `make_compress.bat` now calls `py -3`.
- `make`: runs `make.bat` (`py -3` for the assets since 2026-11-22). Tested 2026-11-22, builds. It empties `build\` first.
- `make compress` runs `make_compress.bat`; `make help` lists targets.
- On success both scripts build `!Chequered` in the repo and copy it plus `Screens,ffb` into `..\arculator\hostfs\Builds` (`D:\archie\mine\arculator\hostfs\Builds`). Run `!Chequered` in Arculator.

## Local changes

- 2026-11-22: the old uncommitted edits to `checks.lua`, `make.bat` (`-vicelabels build\vice.txt`) and `ref/blueberry checkerboard.txt` were committed to main.
- Still uncommitted: `arc-check.asm` with `_DEBUG` and `_SYNC_EDITOR` set to 1 (debug/Rocket build). Revert with `git restore arc-check.asm` for a release build.
- `wip/2026-11-tidy` (pushed): a snapshot of all of those edits.
- wip/dual-playfield, wip/lua-scripting, wip/self-mod-loop, wip/six-layers-only are all fully merged into main (0 commits ahead); safe to delete if wanted.

## Status and next steps

- Final/RC builds were made 2023-06-23; the uncommitted edits (Lua checks, Blueberry checkerboard notes) look like later experiments. No TODO/plan notes found.

## See also

- `README.md`, `ref/`; `D:\archie\mine\arculator` (emulator + hostfs).
