@echo off

:: choose name for the program
set exe_name=mplayer
set code=%cd%

set common_build_opts=-show-timings -collection:src=%code%\code -microarch:native -debug -warnings-as-errors
set build_plat_opts=%common_build_opts% -build-mode:exe
set build_app_opts=%common_build_opts% -build-mode:dll

if not exist bld mkdir bld
pushd bld
del *.pdb > NUL 2> NUL
del *.rdi > NUL 2> NUL

set time_stamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

echo building platform layer
call odin build %code%\code -out:%exe_name%.exe %build_plat_opts%

popd