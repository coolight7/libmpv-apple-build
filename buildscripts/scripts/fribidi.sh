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

# - FIX build ios: ld kill 9: ./libavcodec/sinewin_fixed_tablegen > libavcodec/sinewin_fixed_tables.h
# 需要 host-cc 编译一个程序，然后运行生成代码 gen，上述错误即编译有问题，运行时崩溃导致无法生成代码
unset IPHONEOS_DEPLOYMENT_TARGET
export MACOSX_DEPLOYMENT_TARGET=11.0
export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

meson setup $build --cross-file "$prefix_dir/crossfile.txt" \
	--default-library=static \
	--libdir=lib \
	--prefix=/usr/local \
	--buildtype=release \
	-Dtests=false \
	-Ddocs=false

"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install
