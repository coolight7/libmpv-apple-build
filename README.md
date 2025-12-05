# libmpv-apple-build
- 由 libmpv-linux-build 复制修改而来

## 编译
- 在 macos 系统上，安装好 xcode
- cd ${项目根目录}/buildscripts/
- 首次编译需要创建 python 环境：
```sh
cd ${项目根目录}/buildscripts/
python3 create venv
source venv/bin/activate
pip3 install meson

# 如果后续缺少什么python库或需要安装程序，可以在命令行：
source venv/bin/activate
pip3 install {需要的库}
```
- 执行编译 ./bundle_default.sh
- 编译结果在 ${项目根目录}/output/

## 可能遇到的问题
- patch 应用失败
    - 手动更改之后，git diff 修改patch
    - 还是不行就照着 patch 内容手动修改
- 编译报错：
    - 更新 meson 1.8.4 或更高，可以用 pip3 install meson 安装
```sh
Compiling HB for LibreOffice on macOS results in the error "_LIBCPP_ENABLE_ASSERTIONS has been removed, please use _LIBCPP_HARDENING_MODE instead".
```
- macos/ios libmpv 播放就崩溃
    - 崩溃点在文件关闭 close, 一般时调用 avformat_input_close 时，段错误，Sig 11
    - 考虑动态链接 ffmpeg ，一开始我们把所有库都静态链接进 libmpv，整合得到 libmpv.2.dylib，但运行时出现上述错误，稳定崩溃。
    - 改为编译 ffmpeg 为动态库，libmpv也动态链接 libav*.dylib/libsw*.dylib 其他依赖库保持静态链接，这样就没问题了。
    - 另外 mediaxx 也是链接了 ffmpeg，没有调用 libmpv 的函数，也是只要跟 ffmpeg 静态链接整合到一起就崩溃，同样崩溃在close时，因此问题应该时在 ffmpeg 上
- ios/libmpv 播放时崩溃
    - 崩溃点在 libmpv.2.dylib: AVAudioSession:
```sh
Runner[14462:371841] -[AVAudioSession setCategory:withOptions:withOptions:error:]: unrecognized selector sent to instance 0x280c488c0
2025-11-27 12:47:15.470127+0800 Runner[14462:371841] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[AVAudioSession setCategory:withOptions:withOptions:error:]: unrecognized selector sent to instance 0x280c488c0'
*** First throw call stack:
(0x180d83c60 0x1985afee4 0x180e546e8 0x180d1d54c 0x180d1c75c 0x1035fb2e4 0x103501af8 0x10359789c 0x10358eb64 0x10356615c 0x1dc0fa338 0x1dc0f8938)
libc++abi: terminating with uncaught exception of type NSException
dyld4 config: DYLD_LIBRARY_PATH=/usr/lib/system/introspection DYLD_INSERT_LIBRARIES=/Developer/usr/lib/libBacktraceRecording.dylib:/Developer/usr/lib/libMainThreadChecker.dylib:/Developer/Library/PrivateFrameworks/DTDDISupport.framework/libViewDebuggerSupport.dylib
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[AVAudioSession setCategory:withOptions:withOptions:error:]: unrecognized selector sent to instance 0x280c488c0'
terminating with uncaught exception of type NSException
```
    - 检查 patch，media-kit 项目中包含一个 mpv 的 patch，中 0.40.0 编译应该去掉：mpv-mix-with-others.patch:
```patch
diff --git a/audio/out/ao_audiounit.m b/audio/out/ao_audiounit.m
index 8d4eb4d..c138550 100644
--- a/audio/out/ao_audiounit.m
+++ b/audio/out/ao_audiounit.m
@@ -120,7 +120,7 @@ static bool init_audiounit(struct ao *ao)
         options |= AVAudioSessionCategoryOptionMixWithOthers;
     }
 
-    [instance setCategory:AVAudioSessionCategoryPlayback withOptions:options error:nil];
+    [instance setCategory:AVAudioSessionCategoryPlayback withOptions:options withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
     [instance setMode:AVAudioSessionModeMoviePlayback error:nil];
     [instance setActive:YES error:nil];
     [instance setPreferredOutputNumberOfChannels:prefChannels error:nil];

```