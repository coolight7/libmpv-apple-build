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
    -DCMAKE_C_FLAGS=-fPIC \
	-DCMAKE_CXX_FLAGS="-fPIC -std=c++23" \
    -DCMAKE_FIND_ROOT_PATH=${prefix_dir} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DJPEGXL_STATIC=ON \
    -DBUILD_TESTING=OFF \
    -DJPEGXL_EMSCRIPTEN=OFF \
    -DJPEGXL_BUNDLE_LIBPNG=OFF \
    -DJPEGXL_ENABLE_TOOLS=OFF \
    -DJPEGXL_ENABLE_VIEWERS=OFF \
    -DJPEGXL_ENABLE_DOXYGEN=OFF \
    -DJPEGXL_ENABLE_EXAMPLES=OFF \
    -DJPEGXL_ENABLE_MANPAGES=OFF \
    -DJPEGXL_ENABLE_JNI=OFF \
    -DJPEGXL_ENABLE_SKCMS=OFF \
    -DJPEGXL_ENABLE_PLUGINS=OFF \
    -DJPEGXL_ENABLE_DEVTOOLS=OFF \
    -DJPEGXL_ENABLE_BENCHMARK=OFF \
    -DJPEGXL_ENABLE_SJPEG=OFF \
    -DJPEGXL_ENABLE_HWY_AVX3=OFF \
    -DJPEGXL_ENABLE_HWY_AVX3_ZEN4=OFF \
    -DJPEGXL_ENABLE_HWY_AVX3_SPR=OFF \


"${MY_NINJA_EXE_DIR}/ninja" -C .
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C . install

# gsed -i '/^Libs: -L${libdir} -ljxl / s|-lc++ |-lc++_static -lc++abi|' "$prefix_dir/lib/pkgconfig/libjxl.pc"
# gsed -i '/^Libs.private:/ s|-lc++ |-lc++_static -lc++abi|' "$prefix_dir/lib/pkgconfig/libjxl_cms.pc"
# gsed '/^Libs.private:/ s|$| -lc++_static -lc++abi|' "$prefix_dir/lib/pkgconfig/libjxl_threads.pc" -i ''