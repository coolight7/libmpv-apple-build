#!/bin/bash -e

cd "$( dirname "${BASH_SOURCE[0]}" )"
. ./include/depinfo.sh

cleanbuild=0
clean_lib_ff_mpv=0
clean_mediaxx=0
target=mediaxx
systems=(iOS Darwin)
# archs=(armv7l arm64 x86 x86_64)
archs=(arm64)

getdeps () {
	varname="dep_${1//-/_}[*]"
	echo ${!varname}
}

loadarch () {
	unset CC CXX CPATH LIBRARY_PATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
    unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

	# cpu_triple: what the toolchain actually is
	# cc_triple: what Google pretends the toolchain is
	local _sys=$1
	local _arch=$2
	if [ "$_arch" == "armv7l" ]; then
		export cpu_suffix=-$_sys
		export cpu_triple=armeabi-apple-darwin
		cc_triple=armeabi-apple-darwin
		prefix_name=armeabi
	elif [ "$_arch" == "arm64" ]; then
		export cpu_suffix=-$_sys-arm64
		export cpu_triple=aarch64-apple-darwin
		cc_triple=$cpu_triple
		prefix_name=arm64
	elif [ "$_arch" == "x86" ]; then
		export cpu_suffix=-$_sys-x86
		export cpu_triple=i686-apple-darwin
		cc_triple=$cpu_triple
		prefix_name=x86
	elif [ "$_arch" == "x86_64" ]; then
		export cpu_suffix=-$_sys-x64
		export cpu_triple=x86_64-apple-darwin
		cc_triple=$cpu_triple
		prefix_name=x86_64
	else
		echo "Invalid architecture"
		exit 1
	fi
	export current_target_os=$_sys
	export current_abi_name=$prefix_name

	export default_cxx_stl=" "
	export default_ld_cxx_stdlib_unset=" "
	export default_ld_cxx_stdlib="  "
	export default_ld_cxx_stdlib_mediaxx=""
	export build_home_dir="$PWD/../"
	export prefix_dir="$PWD/prefix/$_sys/$prefix_name"
	export source_dir="$PWD/deps/"

	if [ ! -d "$prefix_dir" ]; then
		mkdir -p "$prefix_dir"
		mkdir -p "$prefix_dir/lib"
    	mkdir -p "$prefix_dir/lib/pkgconfig"
    	mkdir -p "$prefix_dir/include"
		# enforce flat structure (/usr/local -> /)
		ln -s . "$prefix_dir/usr"
		ln -s . "$prefix_dir/local"
	fi

	toolchain_dir=
	sysroot_dir=
	min_version=
	unset SDKROOT IPHONEOS_DEPLOYMENT_TARGET MACOSX_DEPLOYMENT_TARGET
	if [[ "$current_target_os" == "iOS" && "$current_abi_name" == "arm64" ]]; then
		cp "./crossfiles/ios-arm64.ini" "$prefix_dir/crossfile.txt"
		min_version="--target=arm64-apple-ios13.0 -miphoneos-version-min=13.0 -mios-version-min=13.0"
		toolchain_dir=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
		sysroot_dir=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
		export IPHONEOS_DEPLOYMENT_TARGET=13.0
		export CMAKE_DEPLOYMENT_TARGET=13.0
		export SDKROOT=$sysroot_dir
	elif [[ "$current_target_os" == "Darwin" && "$current_abi_name" == "arm64" ]]; then
		cp "./crossfiles/macos-arm64.ini" "$prefix_dir/crossfile.txt"
		min_version="--target=arm64-apple-macos11.0 -mmacosx-version-min=11.0 -mmacos-version-min=11.0"
		toolchain_dir=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
		sysroot_dir=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
    	export MACOSX_DEPLOYMENT_TARGET=11.0
		export CMAKE_DEPLOYMENT_TARGET=11.0
		export SDKROOT=$sysroot_dir
	elif [[ "$current_target_os" == "Darwin" && "$current_abi_name" == "x86_64" ]]; then
		cp "./crossfiles/macos-amd64.ini" "$prefix_dir/crossfile.txt"
		min_version="--target=arm64-apple-macos11.0 -mmacosx-version-min=11.0 -mmacos-version-min=11.0"
		toolchain_dir=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
		sysroot_dir=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
    	export MACOSX_DEPLOYMENT_TARGET=11.0
		export CMAKE_DEPLOYMENT_TARGET=11.0
		export SDKROOT=$sysroot_dir
	else
		echo "unsupport targetos / abi: $current_target_os, $current_abi_name"
		exit -77
	fi

	export toolchain_dir=$toolchain_dir
	export sysroot_dir=$sysroot_dir

	export CFLAGS="-I$prefix_dir/include -arch $_arch $min_version -isysroot $sysroot_dir -I$sysroot_dir/usr/include -F$sysroot_dir/System/Library/Frameworks/ -fPIC -O3"
	export CXXFLAGS="-I$prefix_dir/include -arch $_arch $min_version -isysroot $sysroot_dir -I$sysroot_dir/usr/include -I$sysroot_dir/usr/include/c++/v1 -F$sysroot_dir/System/Library/Frameworks/ -fPIC -O3 -stdlib=libc++"
	export LDFLAGS="-L$prefix_dir/lib/ -arch $_arch $min_version -isysroot $sysroot_dir -F$sysroot_dir/System/Library/Frameworks/ -Wl,-O3"
	export CC="$toolchain_dir/clang"
	export CXX="$toolchain_dir/clang++"
	if [[ "$1" == arm* ]]; then
		export AS="$CC"
	else
		export AS="$toolchain_dir/nasm"
	fi
	export AR="$toolchain_dir/ar"
	export NM="$toolchain_dir/nm"
	export RANLIB="$toolchain_dir/ranlib"
}

setup_prefix () {

	local cpu_family=${cpu_triple%%-*}
	[ "$cpu_family" == "i686" ] && cpu_family=x86
	
	. ./include/path.sh
}

build () {
	if [ ! -d deps/$1 ]; then
		printf >&2 '\e[1;31m%s\e[m\n' "Target $1 not found"
		return 1
	fi

	printf >&2 '\e[1;34m%s\e[m\n' "Preparing $1..."
	local deps=$(getdeps $1)
	echo >&2 "Dependencies: $deps"
	for dep in $deps; do
		build $dep
	done

	printf >&2 '\e[1;34m%s\e[m\n' "Building $1..."

	if [[ -f "$prefix_dir/lib/$1.a" 
		|| -f "$prefix_dir/lib/lib$1.a" 
		|| ( $1 == "lzo" && -f "$prefix_dir/lib/liblzo2.a" ) 
		|| ( $1 == "zlib" && -f "$prefix_dir/lib/libz.a" ) 
		|| ( $1 == "bzip2" && -f "$prefix_dir/lib/libbz2_static.a" ) 
		|| ( $1 == "brotli" && -f "$prefix_dir/lib/libbrotlicommon.a" ) 
		|| ( $1 == "xz" && -f "$prefix_dir/lib/liblzma.a" ) 
		|| ( $1 == "highway" && -f "$prefix_dir/lib/libhwy.a" ) 
		|| ( $1 == "shaderc" && -f "$prefix_dir/lib/libshaderc_combined.a" ) 
		|| ( $1 == "spirv_cross" && -f "$prefix_dir/lib/libspirv-cross-c.a" ) 
		|| ( $1 == "openssl" && -f "$prefix_dir/lib/libssl.a" ) 
		# || ( $1 == "ffmpeg")
		|| ( $1 == "ffmpeg" && -f "$prefix_dir/lib/libavfilter.a") 
		# || ( $1 == "ffmpeg" && -f "$prefix_dir/lib/libavfilter.a")
		|| ( $1 == "mpv" && -f "$prefix_dir/lib/libmpv.a" ) 
		]]; then
		printf >&2 '\e[1;30m%s\e[m\n' "-  Have $1. a/dylib, skip."
		return
	fi

	pushd deps/$1
	BUILDSCRIPT=../../scripts/$1.sh
 	chmod +x $BUILDSCRIPT
	$BUILDSCRIPT clean
	
    $BUILDSCRIPT build
    popd
}

usage () {
	printf '%s\n' \
		"Usage: build.sh [options] [target]" \
		"Builds the specified target (default: $target)" \
		"-n             Do not build dependencies" \
		"--clean        Clean build dirs before compiling" \
		"--arch <arch>  Build for specified architecture (supported: armv7l, arm64, x86, x86_64)"
	exit 0
}

while [ $# -gt 0 ]; do
	case "$1" in
		--clean)
		cleanbuild=1
		;;
		--arch)
		shift
		arch=$1
		;;
		-h|--help)
		usage
		;;
		--prebuild-rm-ff-mpv)
		clean_lib_ff_mpv=1
		rm -rf $source_dir/ffmpeg/_build*
		rm -rf $source_dir/mpv/_build*
		rm -rf $source_dir/mediaxx/_build*
		;;
		--prebuild-rm-mediaxx)
		clean_mediaxx=1
		rm -rf $source_dir/mediaxx/_build*
		;;
		*)
		target=$1
		;;
	esac
	shift
done

if [ -z $arch ]; then
	for sys in ${systems[@]}; do
		for arch in ${archs[@]}; do
			loadarch $sys $arch
			setup_prefix $sys $arch
			
			if [[ $clean_lib_ff_mpv == 1 ]]; then
				echo "rm libav*/libmpv/mediaxx ----------------------"
				rm -f $prefix_dir/lib/libavcodec.*
				rm -f $prefix_dir/lib/libavdevice.*
				rm -f $prefix_dir/lib/libavfilter.*
				rm -f $prefix_dir/lib/libavformat.*
				rm -f $prefix_dir/lib/libavutil.*
				rm -f $prefix_dir/lib/libswresample.*
				rm -f $prefix_dir/lib/libswscale.*
				rm -rf $prefix_dir/lib/ffmpeg-backup/

				rm -f $prefix_dir/lib/libmpv.*
				rm -f $prefix_dir/lib/libmediaxx.*
			elif [[ $clean_mediaxx == 1 ]]; then
				echo "rm libav*/libmpv/mediaxx ----------------------"
				rm -f $prefix_dir/lib/libmediaxx.*
			fi

			env > "$PWD/env-$arch.sh"
			chmod +x "$PWD/env-$arch.sh"
			build $target
		done
	done
else
  	loadarch iOS $arch
  	setup_prefix iOS $arch

	if [[ $clean_lib_ff_mpv == 1 ]]; then
		echo "rm libav*/libmpv/mediaxx ----------------------"
		rm -f $prefix_dir/lib/libavcodec.*
		rm -f $prefix_dir/lib/libavdevice.*
		rm -f $prefix_dir/lib/libavfilter.*
		rm -f $prefix_dir/lib/libavformat.*
		rm -f $prefix_dir/lib/libavutil.*
		rm -f $prefix_dir/lib/libswresample.*
		rm -f $prefix_dir/lib/libswscale.*
		rm -rf $prefix_dir/lib/ffmpeg-backup/

		rm -f $prefix_dir/lib/libmpv.*
		rm -f $prefix_dir/lib/libmediaxx.*
	elif [[ $clean_mediaxx == 1 ]]; then
		echo "rm libav*/libmpv/mediaxx ----------------------"
		rm -f $prefix_dir/lib/libmediaxx.*
	fi
  	build $target
fi

exit 0
