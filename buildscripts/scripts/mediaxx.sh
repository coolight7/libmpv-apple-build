#!/bin/bash -e

cd src

. ../../../include/depinfo.sh
. ../../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$cpu_suffix
	exit 0
else
	exit 255
fi

# 当只需要重新构建 mediaxx ，避免重复构建ffmpeg时启用
# pushd $PWD
# (. ../../../include/backup_restore_dll.sh $prefix_dir/lib/) || true
# popd

build=_build$cpu_suffix

mkdir -p $build
cd $build

# 清理标准库依赖
gsed -i '/^Libs/ s|-lstdc++| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++_static| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++abi| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++_shared| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++| |' $prefix_dir/lib/pkgconfig/*.pc

# 共享符号，编译 mediaxx 时开启导出全部符号，并让 mpv 尽量动态链接
# mediaxx: EXPORT_ALL_SYMBOL=ON
# mpv: --prefer-static

export PKG_CONFIG_SYSROOT_DIR="$prefix_dir"
export PKG_CONFIG_LIBDIR="$prefix_dir/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/share/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"

extend_fw_arg=
if [[ "$current_target_os" == "iOS" ]]; then
	extend_fw_arg="-framework AVFoundation -framework OpenGLES"
else 
	extend_fw_arg="-framework AVFoundation -framework CoreAudio -framework Foundation -framework CoreFoundation "
fi

cpu=
[[ "$cpu_triple" == "aarch64"* ]] && cpu=aarch64
[[ "$cpu_triple" == "x86_64"* ]] && cpu=x86_64
[[ "$cpu_triple" == "i686"* ]] && cpu=x86

LDFLAGS="$LDFLAGS $extend_fw_arg $default_ld_cxx_stdlib_mediaxx -lm" CFLAGS="$CFLAGS " CXXFLAGS="$CXXFLAGS " "${MY_CMAKE_EXE_DIR}/cmake" -S.. -B. \
    -G Ninja \
    -DCMAKE_SYSTEM_NAME=${current_target_os} \
    -DCMAKE_SYSTEM_PROCESSOR=${cpu} \
    -DCMAKE_OSX_SYSROOT=${sysroot_dir} \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_DEPLOYMENT_TARGET} \
    -DCMAKE_FIND_ROOT_PATH=${prefix_dir} \
    -DCMAKE_C_FLAGS="$CFLAGS -Wno-error=int-conversion ${cpuflags}" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS $extend_fw_arg " \
    -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS $extend_fw_arg $default_ld_cxx_stdlib_mediaxx -lm" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DEXPORT_ALL_SYMBOL=OFF \
    -DSTATIC_LINK_FFMPEG=ON \
    -DSTATIC_LINK_LIBMPV=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \


"${MY_NINJA_EXE_DIR}/ninja" -C .
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C . install

# (. ../../../../include/backup_dll.sh $prefix_dir/lib/) || true
