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
    -DCMAKE_FIND_ROOT_PATH=${prefix_dir} \
    -DCMAKE_BUILD_TYPE=Release \
    -DVULKAN_HEADERS_INSTALL_DIR=${prefix_dir} \
    -DBUILD_TESTS=OFF \
    -DENABLE_WERROR=OFF \
    -DUSE_GAS=ON \
    -DBUILD_STATIC_LOADER=ON \
    -DCMAKE_C_FLAGS='${CMAKE_C_FLAGS} -D__STDC_FORMAT_MACROS -DSTRSAFE_NO_DEPRECATE -Dparse_number=cjson_parse_number' \
    -DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS} -D__STDC_FORMAT_MACROS -fpermissive' \

DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C 

cp $build/loader/libvulkan.a $prefix_dir/lib/libvulkan.a
cp $build/loader/vulkan_own.pc $prefix_dir/lib/pkgconfig/vulkan.pc

