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

unset CC CXX
CFLAGS=-fPIC CXXFLAGS="-fPIC -I$prefix_dir/include " meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	--default-library=static \
	--libdir=lib \
	--prefix=/usr/local \
	--buildtype=release \
        -Dshaderc=disabled \
        -Dopengl=enabled \
        -Dvulkan=disabled \
        -Dvk-proc-addr=disabled \
        -Dlcms=enabled \
        -Ddebug=false \
        -Db_ndebug=true \
        -Doptimization=3 \
        -Ddemos=false \
        -Dtests=false \


"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install


# add missing library for static linking
# this isn't "-lstdc++" due to a meson bug: https://github.com/mesonbuild/meson/issues/11300
# gsed '/^Libs:/ s|$| -lc++_static -lc++abi|' "$prefix_dir/lib/pkgconfig/libplacebo.pc" -i ''