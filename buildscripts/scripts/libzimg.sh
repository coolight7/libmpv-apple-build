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

# 阻止 ./autogen.sh 内直接运行 configure
export NOCONFIGURE=no-config
# -mno-ieee-fp is not supported by clang
gsed s/\-mno\-ieee\-fp// -i configure.ac
[ -f configure ] || ./autogen.sh

mkdir -p _build$cpu_suffix
cd _build$cpu_suffix

STL_LIBS="$default_cxx_stl" CXXFLAGS="$CXXFLAGS -include cstdint" ../configure \
	--host=$cpu_triple \
    --disable-shared \
    --enable-static \
	--with-pic 

# opus 有asm，需要特定指定特定编译平台的汇编器
make -j$cores
make DESTDIR="$prefix_dir" install

# gsed -i '/^Libs.private:/ s|-lstdc++|-lc++_static -lc++abi|' "$prefix_dir/lib/pkgconfig/zimg.pc"