@echo off

set code=%cd%

set common_build_opts=-collection:src=%code%\code -microarch:native -debug -warnings-as-errors -vet-shadowing

if not exist bld mkdir bld

pushd bld
call odin test %code%\tests %common_build_opts% -out:flac_test.exe
popd
