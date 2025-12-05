#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

os=linux
export os

cores=6

# configure pkg-config paths if inside buildscripts
# 搜索重定向根目录，因此 库写入 .pc 文件时路径应该保持原本的 /lib 一类的默认目录，不写入实际路径
# 而指定 install 目录安装到正确的路径

# cmake、meson setup、configure 时指定的 INSTALL_PREFIX 会影响最终 install 时 pc 文件内的 prefix 值
# DESTDIR="$prefix_dir" ninja -C . install 时指定的 DESTDIR 只影响 install 的文件位置，但 pc 文件内的 prefix 值不变
if [ -n "$cpu_triple" ]; then
	# 这里提供当前项目编译的库的搜索目录
	# 部分库是由系统安装库提供的,在 /usr/lib、/usr/local/lib、/usr/share 等系统库目录，编译时由 gcc 和 ld 自己查找使用
	export PKG_CONFIG_SYSROOT_DIR="$prefix_dir"
	export PKG_CONFIG_LIBDIR="$prefix_dir/lib/pkgconfig"
	unset PKG_CONFIG_PATH
fi

export MY_CMAKE_EXE_DIR=/opt/homebrew/bin/
export MY_NINJA_EXE_DIR=$build_home_dir/buildscripts/venv/bin/

export PATH="$MY_CMAKE_EXE_DIR:$PATH"