ls -lh ./output/iOS/arm64/*.dylib
cp ./output/iOS/arm64/*.dylib  /Users/coolight/0Acoolight/program/flutter/mymusic/plugins/media-kit/libs/ios/media_kit_libs_ios_video/outlibs/
cp ./output/iOS/arm64/*.dylib /Users/coolight/0Acoolight/program/flutter/mymusic/resource/ffmpeg/ios/

ls -lh ./output/Darwin/arm64/*.dylib
cp  ./output/Darwin/arm64/*.dylib  /Users/coolight/0Acoolight/program/flutter/mymusic/plugins/media-kit/libs/macos/media_kit_libs_macos_video/outlibs
cp -r ./output/Darwin/arm64/*.dylib  /Users/coolight/0Acoolight/program/flutter/mymusic/resource/ffmpeg/macos/
