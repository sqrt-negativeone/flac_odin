#!/bin/bash

app_name="flac_odin"

code="$PWD"
common_opts="-show-timings -collection:src=$code/code -microarch:native -warnings-as-errors -vet"

generate_debug_info="1"
release_mode="0"

if [[ "$release_mode" == "0" ]]; then
  common_opts="$common_opts -o:none"
else
  common_opts="$common_opts -o:speed"
fi

if [[ "$generate_debug_info" == "1" ]]; then
  common_opts="$common_opts -debug"
fi

mkdir -p $code/bld
cd $code/bld > /dev/null

odin build $code/code -out:${app_name}.exe $common_opts

cd $code > /dev/null
