#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$cpu_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	--default-library=static \
	--libdir=lib \
	--prefix=/usr/local \
	--buildtype=release \


"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install
