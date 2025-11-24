#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$cpu_suffix
	exit 0
else
	exit 255
fi

build=_build$cpu_suffix

mkdir -p $build
cd $build


cpu=
[[ "$cpu_triple" == "aarch64"* ]] && cpu=aarch64
[[ "$cpu_triple" == "x86_64"* ]] && cpu=x86_64
[[ "$cpu_triple" == "i686"* ]] && cpu=x86

CONF=1 "${MY_CMAKE_EXE_DIR}/cmake" -S.. -B. \
    -G Ninja \
    -DCMAKE_SYSTEM_NAME=${current_target_os} \
    -DCMAKE_SYSTEM_PROCESSOR=${cpu} \
    -DCMAKE_OSX_SYSROOT=${sysroot_dir} \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_DEPLOYMENT_TARGET} \
    -DCMAKE_AR="$AR" \
    -DCMAKE_RANLIB="$RANLIB" \
    -DCMAKE_FIND_ROOT_PATH=${prefix_dir} \
    -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_FIND_ROOT_PATH="/" \
    -DBUILD_SHARED_LIBS=OFF \
    -DSKIP_INSTALL_LIBRARIES=OFF \
    -DZLIB_COMPAT=ON \
    -DBUILD_TESTING=OFF \
    -DZLIBNG_ENABLE_TESTS=OFF \
    -DFNO_LTO_AVAILABLE=OFF \


"${MY_NINJA_EXE_DIR}/ninja" -C .
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C . install
