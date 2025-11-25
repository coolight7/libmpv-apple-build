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

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

copyLib() {
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

  strip $build_home_dir/output/$1/*.dylib

  cp $build_home_dir/help/*                    $build_home_dir/output/$1/
	pushd $build_home_dir/output/$1/
  ./create_comm_syms.sh
  popd
}

copyLib iOS/arm64
copyLib Darwin/arm64
copyLib Darwin/x86_64

echo "current dir: vvvvvvvvvvvvvvvvvvvv"
pwd

echo "target dir: vvvvvvvvvvvvvvvvvvvv"
echo $build_home_dir/output/