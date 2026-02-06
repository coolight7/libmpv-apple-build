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
# ./build.sh --prebuild-rm-mediaxx
./build.sh --prebuild-rm-ff-mpv

if [ $? -ne 0 ]; then
  exit -1
fi

# --------------------------------------------------

rm -rf $build_home_dir/output/
mkdir -p $build_home_dir/output/

resetLibDeps() {
  install_name_tool -change /usr/local/lib/libmpv.2.dylib @loader_path/libmpv.2.dylib       $1
  install_name_tool -change /usr/local/lib/libavcodec.dylib @loader_path/libavcodec.dylib   $1
  install_name_tool -change /usr/local/lib/libavfilter.dylib @loader_path/libavfilter.dylib $1
  install_name_tool -change /usr/local/lib/libavformat.dylib @loader_path/libavformat.dylib $1
  install_name_tool -change /usr/local/lib/libavutil.dylib @loader_path/libavutil.dylib     $1
  install_name_tool -change /usr/local/lib/libswresample.dylib @loader_path/libswresample.dylib $1
  install_name_tool -change /usr/local/lib/libswscale.dylib @loader_path/libswscale.dylib   $1
  install_name_tool -change /usr/local/lib/libavdevice.dylib @loader_path/libavdevice.dylib $1
}

copyLib() {
  mkdir -p $build_home_dir/output/$1/
  cp prefix/$1/lib/libmediaxx.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libmpv.2.dylib                 $build_home_dir/output/$1/
  cp prefix/$1/lib/libswresample.dylib            $build_home_dir/output/$1/
  cp prefix/$1/lib/libswscale.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavutil.dylib                $build_home_dir/output/$1/
  cp prefix/$1/lib/libavcodec.dylib               $build_home_dir/output/$1/
  cp prefix/$1/lib/libavformat.dylib              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavfilter.dylib              $build_home_dir/output/$1/
  cp prefix/$1/lib/libavdevice.dylib              $build_home_dir/output/$1/

  install_name_tool -id "@rpath/libmediaxx.dylib"     $build_home_dir/output/$1/libmediaxx.dylib    
  install_name_tool -id "@rpath/libmpv.2.dylib"       $build_home_dir/output/$1/libmpv.2.dylib      
  install_name_tool -id "@rpath/libswresample.dylib"  $build_home_dir/output/$1/libswresample.dylib 
  install_name_tool -id "@rpath/libswscale.dylib"     $build_home_dir/output/$1/libswscale.dylib    
  install_name_tool -id "@rpath/libavutil.dylib"      $build_home_dir/output/$1/libavutil.dylib     
  install_name_tool -id "@rpath/libavcodec.dylib"     $build_home_dir/output/$1/libavcodec.dylib    
  install_name_tool -id "@rpath/libavformat.dylib"    $build_home_dir/output/$1/libavformat.dylib   
  install_name_tool -id "@rpath/libavfilter.dylib"    $build_home_dir/output/$1/libavfilter.dylib   
  install_name_tool -id "@rpath/libavdevice.dylib"    $build_home_dir/output/$1/libavdevice.dylib   

  resetLibDeps $build_home_dir/output/$1/libmediaxx.dylib    
  resetLibDeps $build_home_dir/output/$1/libmpv.2.dylib      
  resetLibDeps $build_home_dir/output/$1/libswresample.dylib 
  resetLibDeps $build_home_dir/output/$1/libswscale.dylib    
  resetLibDeps $build_home_dir/output/$1/libavutil.dylib     
  resetLibDeps $build_home_dir/output/$1/libavcodec.dylib    
  resetLibDeps $build_home_dir/output/$1/libavformat.dylib   
  resetLibDeps $build_home_dir/output/$1/libavfilter.dylib   
  resetLibDeps $build_home_dir/output/$1/libavdevice.dylib   

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