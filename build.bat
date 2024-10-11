@echo off

:: choose name for the program
set exe_name=flac_odin
set code=%cd%

:: On=1, Off=0
set generate_debug_info=1

:: Debug=0, Release=1
set release_mode=0

set common_build_opts=-show-timings -collection:src=%code%\code -microarch:native -warnings-as-errors -vet


if %release_mode% EQU 0 ( rem Debug
	set common_build_opts=%common_build_opts% -o:none
) else ( rem Release
	set common_build_opts=%common_build_opts% -o:speed
)

if %generate_debug_info% EQU 1 ( rem Debug Info On
	set common_build_opts=%common_build_opts% -debug
)

set build_plat_opts=%common_build_opts% -build-mode:exe


if not exist bld mkdir bld
pushd bld
del *.pdb > NUL 2> NUL
del *.rdi > NUL 2> NUL

set time_stamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

echo building platform layer
call odin build %code%\code -out:%exe_name%.exe %build_plat_opts%

popd