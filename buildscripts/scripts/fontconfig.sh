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

gsed -i "s/both_libraries/library/g" ./src/meson.build

# 阻止 ./autogen.sh 内直接运行 configure
export NOCONFIGURE=no-config
# -mno-ieee-fp is not supported by clang
gsed s/\-mno\-ieee\-fp// -i configure.ac

unset CC CXX # meson wants these unset

# 需要安装 apt install -y autopoint gperf gettext
CFLAGS="-fPIC -D_GNU_SOURCE" CXXFLAGS="-fPIC -D_GNU_SOURCE" meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
        --libdir=lib \
        --prefix=/usr/local \
        --buildtype=release \
        -Ddefault_library=static \
        -Ddoc=disabled \
        -Dtests=disabled \
        -Dtools=disabled 


"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install
