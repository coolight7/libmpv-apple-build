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

# 禁用编译 可执行文件 tar/unzip 等 ...
CONF=1 "${MY_CMAKE_EXE_DIR}/cmake" -S.. -B. \
    -G Ninja \
    -DCMAKE_SYSTEM_NAME=${current_target_os} \
    -DCMAKE_SYSTEM_PROCESSOR=${cpu} \
    -DCMAKE_OSX_SYSROOT=${sysroot_dir} \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_DEPLOYMENT_TARGET} \
    -DCMAKE_FIND_ROOT_PATH=${prefix_dir} \
    -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_ZLIB=ON \
    -DENABLE_ZSTD=ON \
    -DENABLE_OPENSSL=ON \
    -DENABLE_BZip2=ON \
    -DENABLE_LZ4=OFF \
    -DENABLE_ICONV=ON \
    -DENABLE_LIBXML2=ON \
    -DENABLE_EXPAT=ON \
    -DENABLE_LZO=ON \
    -DENABLE_LZMA=ON \
    -DENABLE_CPIO=OFF \
    -DENABLE_CAT=OFF \
    -DENABLE_TAR=OFF \
    -DENABLE_UNZIP=OFF \
    -DENABLE_WERROR=OFF \
    -DBUILD_TESTING=OFF \
    -DENABLE_TEST=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \



"${MY_NINJA_EXE_DIR}/ninja" -C .
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C . install
