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

mkdir -p _build$cpu_suffix
cd _build$cpu_suffix

if [[ "$current_target_os" == "iOS" ]]; then
    cpu=ios64-arm
    [[ "$cpu_triple" == "aarch64"* ]] && cpu=ios64-cross
    [[ "$cpu_triple" == "x86_64"* ]] && cpu=ios64-x86_64
    [[ "$cpu_triple" == "i686"* ]] && cpu=ios64-x86
else
    cpu=darwin64-arm
    [[ "$cpu_triple" == "aarch64"* ]] && cpu=darwin64-arm64
    [[ "$cpu_triple" == "x86_64"* ]] && cpu=darwin64-x86_64
    [[ "$cpu_triple" == "i686"* ]] && cpu=darwin64-x86
fi

CFLAGS="$CFLAGS -fPIC -I$prefix_dir/include -I$prefix_dir/include/brotli" CXXFLAGS="$CXXFLAGS -fPIC -I$prefix_dir/include -I$prefix_dir/include/brotli" LDFLAGS="$LDFLAGS -L$prefix_dir/lib -lz -lzstd -lbrotlicommon -lbrotlidec -lbrotlienc" CONF=1 ../Configure \
    --libdir=lib \
    --release \
    $cpu \
    enable-ec \
    no-ssl3-method \
    enable-brotli \
    no-whirlpool \
    no-filenames \
    no-camellia \
    enable-zstd \
    no-capieng \
    no-shared \
    no-rmd160 \
    no-module \
    no-legacy \
    no-tests \
    threads \
    no-docs \
    no-apps \
    no-ocsp \
    no-ssl3 \
    no-cmac \
    no-mdc2 \
    no-idea \
    no-cast \
    no-seed \
    no-aria \
    no-err \
    no-dso \
    no-dsa \
    no-srp \
    no-rc2 \
    no-rc4 \
    no-sm2 \
    no-sm3 \
    no-sm4 \
    no-md4 \
    no-cms \
    no-cmp \
    no-dh \
    no-bf \
    zlib


make -j$cores build_sw
make DESTDIR="$prefix_dir" install_sw
