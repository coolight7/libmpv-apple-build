#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$cpu_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$cpu_suffix
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# 清理标准库依赖
gsed -i '/^Libs/ s|-lstdc++| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++_static| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++abi| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++_shared| |' $prefix_dir/lib/pkgconfig/*.pc
gsed -i '/^Libs/ s|-lc++| |' $prefix_dir/lib/pkgconfig/*.pc

# 可用于限制导出的符号
# CFLAGS、CXXFLAGS 中添加  -fvisibility=hidden
# -Wl,--undefined-version,--version-script=$mpv_EXPORT_IDS
mpv_EXPORT_IDS=$build_home_dir/buildscripts/mpv-export.lds

export C_INCLUDE_PATH=$prefix_dir/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$sysroot_dir/usr/include/c++/v1:$prefix_dir/include:$CPLUS_INCLUDE_PATH

target_os=
target_options=
if [[ "$current_target_os" == "iOS" ]]; then
	unset SDKROOT MACOSX_DEPLOYMENT_TARGET
	export IPHONEOS_DEPLOYMENT_TARGET=12.1
	target_os=arm64-apple-ios12.1
	target_options="-Daudiounit=enabled -Davfoundation=disabled -Dios-gl=enabled -Dcocoa=disabled -Dgl-cocoa=disabled -Dcoreaudio=disabled -Dvideotoolbox-gl=disabled -Dvideotoolbox-pl=disabled -Dswift-build=disabled"
else 
	unset IPHONEOS_DEPLOYMENT_TARGET
	target_os=arm64-apple-macos11.0
	target_options="-Dcoreaudio=enabled -Davfoundation=enabled -Dcocoa=disabled -Dgl-cocoa=disabled -Dvideotoolbox-gl=disabled -Dvideotoolbox-pl=disabled -Dmacos-cocoa-cb=disabled -Dswift-build=disabled"
fi

# c++std: libjxl、shaderc
# 由 mediaxx 静态链接标准库并导出符号，libmpv 动态链接使用
LDFLAGS="$LDFLAGS -L$prefix_dir/lib/ $default_ld_cxx_stdlib -lm" CFLAGS="$CFLAGS -F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include" CXXFLAGS="$CXXFLAGS -F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include" meson setup $build \
	--cross-file "$prefix_dir/crossfile.txt" \
	--default-library static \
	--libdir=lib \
	--prefix=/usr/local \
    -Dbuildtype=release \
    -Db_lto=true \
	-Db_lto_mode=default \
	-Db_ndebug=true \
	-Dc_args="$CFLAGS -F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include " \
	-Dcpp_args="$CXXFLAGS -F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include " \
	-Dobjc_args="-F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include" \
	-Dobjcpp_args="-F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include" \
	-Dswift-flags="-target $target_os -sdk $sysroot_dir -sysroot $sysroot_dir -F$sysroot_dir/System/Library/Frameworks/ -I$sysroot_dir/usr/include -I$prefix_dir/include" \
	-Ddebug=false \
	-Doptimization=3 \
	-Dlibmpv=true \
 	-Dcplayer=false \
	-Dgpl=true \
    -Dbuild-date=false \
	\
	-Dhtml-build=disabled \
	-Dmanpage-build=disabled \
	-Dpdf-build=disabled \
	\
	-Dcplugins=disabled \
	-Dlua=disabled \
	-Djavascript=disabled \
	\
	-Dlibbluray=disabled \
	-Ddvdnav=disabled \
	-Dvapoursynth=disabled \
	-Duchardet=disabled \
	\
	-Diconv=disabled \
	-Dlibarchive=enabled \
	-Drubberband=enabled \
	-Dlcms2=enabled \
	\
	-Dalsa=disabled \
	-Dpipewire=disabled \
	-Dpulse=disabled \
	-Dsdl2-audio=disabled \
    -Dopensles=disabled \
	\
	-Dplain-gl=enabled \
	-Dgl=enabled \
	${target_options} \
	-Dx11=disabled \
	-Dwayland=disabled \
	-Degl=disabled \
	-Dvaapi-drm=disabled \
	-Dvulkan=disabled \
	-Dsdl2-video=disabled \
	-Dcaca=disabled \
	-Dsixel=disabled \
	\
	-Dcuda-hwaccel=disabled \
	-Dcuda-interop=disabled \


"${MY_NINJA_EXE_DIR}/ninja" -C $build -j$cores
DESTDIR="$prefix_dir" "${MY_NINJA_EXE_DIR}/ninja" -C $build install

