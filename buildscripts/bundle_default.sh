# --------------------------------------------------

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

# coolight --- temp
# ./build.sh 
./build.sh --prebuild-rm-mediaxx
# ./build.sh --prebuild-rm-ff-mpv

if [ $? -ne 0 ]; then
  exit -1
fi

stripLib() {
  strip --strip-all prefix/arm64/lib/$1
  strip --strip-all prefix/armeabi/lib/$1
  strip --strip-all prefix/x86/lib/$1
  strip --strip-all prefix/x86_64/lib/$1
}

stripLib libmediaxx.dylib
stripLib libmpv.dylib
stripLib libavcodec.dylib
stripLib libavutil.dylib
stripLib libavfilter.dylib
stripLib libavformat.dylib
stripLib libavdevice.dylib
stripLib libswresample.dylib
stripLib libswscale.dylib

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

copyLib() {
  if [[ $1 != "arm64" && $1 != "armeabi" && $1 != "x86" && $1 != "x86_64" ]]; then
    echo "call copyLib 参数 {cpu} 不正确: $1"
    exit -1
  fi

  mkdir -p $build_home_dir/output/$1/
  cp prefix/$1/lib/libmediaxx.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libmpv.dylib                   $build_home_dir/output/$1/
  cp prefix/$1/lib/libswresample.dylib            $build_home_dir/output/$1/
  cp prefix/$1/lib/libswscale.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavutil.dylib                $build_home_dir/output/$1/
  cp prefix/$1/lib/libavcodec.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavformat.dylib              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavfilter.dylib              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavdevice.dylib              $build_home_dir/output/$1/

  cp $build_home_dir/help/*                    $build_home_dir/output/$1/
	pushd $build_home_dir/output/$1/
  ./create_comm_syms.sh
  popd
}

copyLib arm64
copyLib armeabi
copyLib x86
copyLib x86_64

cat $build_home_dir/output/arm64/comm_cxx_syms.txt \
    $build_home_dir/output/armeabi/comm_cxx_syms.txt \
    $build_home_dir/output/x86/comm_cxx_syms.txt \
    $build_home_dir/output/x86_64/comm_cxx_syms.txt \
    | sort | uniq > $build_home_dir/output/comm_cxx_syms.txt
cat $build_home_dir/output/arm64/comm_syms.txt \
    $build_home_dir/output/armeabi/comm_syms.txt \
    $build_home_dir/output/x86/comm_syms.txt \
    $build_home_dir/output/x86_64/comm_syms.txt \
    | sort | uniq > $build_home_dir/output/comm_syms.txt
cat $build_home_dir/output/arm64/libmpv_undef_syms.txt \
    $build_home_dir/output/armeabi/libmpv_undef_syms.txt \
    $build_home_dir/output/x86/libmpv_undef_syms.txt \
    $build_home_dir/output/x86_64/libmpv_undef_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_undef_syms.txt
cat $build_home_dir/output/arm64/libmpv_def_syms.txt \
    $build_home_dir/output/armeabi/libmpv_def_syms.txt \
    $build_home_dir/output/x86/libmpv_def_syms.txt \
    $build_home_dir/output/x86_64/libmpv_def_syms.txt \
    | sort | uniq > $build_home_dir/output/libmpv_def_syms.txt

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/