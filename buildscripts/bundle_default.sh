# --------------------------------------------------

# 编译产物固定为单个 libmediaxx.dylib：
# ffmpeg（libav*.a）与 libmpv（libmpv.a）都编成静态库，由 mediaxx 合并成一个动态库

export build_home_dir="$PWD/../"

# TODO: coolight --- temp
# if [ ! -f "deps" ]; then
#   rm -rf deps
# fi
# if [ ! -f "prefix" ]; then
#   rm -rf prefix
# fi

# ./download.sh
# ./patch.sh

# --------------------------------------------------

if [ ! -f "scripts/ffmpeg" ]; then
  rm scripts/ffmpeg.sh
fi
cp flavors/default.sh scripts/ffmpeg.sh

# --------------------------------------------------
source venv/bin/activate

cd deps/mediaxx && git pull && git submodule update --init && cd -

# coolight --- temp
# 本次更新（ffmpeg 9.0.1 / 依赖库 / mpv 分支 / mediaxx）需要重新编译 ffmpeg、libmpv、mediaxx
./build.sh --prebuild-rm-ffm-mpv-mediaxx
# ./build.sh --prebuild-rm-mediaxx # 只清理 mediaxx 重新编译
# ./build.sh

if [ $? -ne 0 ]; then
  exit -1
fi

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

# 打包：ffmpeg + libmpv + 其他依赖都已经合并进 libmediaxx.dylib，输出目录里只有这一个库
copyLib() {
  if [ ! -f "prefix/$1/lib/libmediaxx.dylib" ]; then
    echo "skip $1: prefix/$1/lib/libmediaxx.dylib 不存在"
    return 0
  fi

  # 打包之前先检查有没有会被错误解析的同名符号：
  # 这类问题编译能过，但运行时一走到那条路径就崩，必须提前拦住
  # 用 bash 调用，避免脚本没有可执行位时直接报 Permission denied
  if ! bash ./check-single-lib-symbols.sh "prefix/$1"; then
    echo "错误: $1 的符号检查未通过，不打包。修掉上面列出的同名符号后重新编译。" >&2
    exit 1
  fi

  mkdir -p $build_home_dir/output/$1/
  cp prefix/$1/lib/libmediaxx.dylib $build_home_dir/output/$1/
  install_name_tool -id "@rpath/libmediaxx.dylib" $build_home_dir/output/$1/libmediaxx.dylib
  # 直接 strip 在新版 Xcode 上会因间接符号表报错且不去符号，-x 只去掉局部符号
  strip -x $build_home_dir/output/$1/libmediaxx.dylib

  # 导出符号就是 libmediaxx.dylib 自己导出的（mediaxx_* 与 mpv_*），用 macOS 自带 nm 导出清单
  pushd $build_home_dir/output/$1/
  nm -gU libmediaxx.dylib | awk '{print $NF}' | sort -u > libmediaxx_def_syms.txt
  echo "导出符号数量: $(wc -l < libmediaxx_def_syms.txt)"
  popd
}

# macOS x86_64（Intel）已不再支持，只打包 arm64 的 iOS / Darwin
copyLib iOS/arm64
copyLib Darwin/arm64

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/