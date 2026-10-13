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

## 编译产物（单个 libmediaxx.dylib）
- 编译方式固定：ffmpeg 编成静态库（`libav*.a`）、libmpv 编成静态库（`libmpv.a`），
  再由 mediaxx 合并成一个动态库，不再有「多库 / 单库」的开关
- 产物：`output/iOS/arm64/libmediaxx.dylib`、`output/Darwin/arm64/libmediaxx.dylib`
    - 依赖只剩系统框架与 `/usr/lib/libiconv.2.dylib`
    - 导出的符号是 `mediaxx_*` 与 `mpv_*`（当前 66 个，同时输出 `libmediaxx_def_syms.txt` 清单）
- 手动编译：
```sh
cd ${项目根目录}/buildscripts/
./build.sh --prebuild-rm-ffm-mpv-mediaxx   # 全量重编 ffmpeg + libmpv + mediaxx
./build.sh --prebuild-rm-mediaxx           # 只重编 mediaxx
./build.sh                                 # 按现有产物增量编译
```
- 编译完可以这样检查（`bundle_default.sh` 打包时会自动跑第一项）：
```sh
cd ${项目根目录}/buildscripts/
./check-single-lib-symbols.sh      # 静态检查：合并后有没有会被错误解析的同名符号
cd test/runtime-check && ./run.sh  # 运行时检查：读媒体信息 x40 + 播放并关闭 x20（只适用于 macOS 产物）
```
- 应用侧注意：`mpv_*` 在这个库里是导出符号，原来用 `DynamicLibrary.open('libmpv.2.dylib')`
  加载 mpv 的地方要改成打开 `libmediaxx.dylib`，否则会找不到 mpv 接口

## 更新记录：ffmpeg 9.0.1 / mpv 分支 / 依赖库 / mediaxx
- ffmpeg 由 `8.0.2` 更新到 `9.0.1`
    - 删除 `--disable-libshaderc`：ffmpeg 9 已移除该选项，留在 configure 里会直接以 "Unknown option" 退出
    - 新增动态 WebP（`--enable-decoder=webp_anim`、`--enable-demuxer=webp_anim`）、Dolby Vision 双层拆分（`--enable-bsf=dovi_split`），音频滤镜补上 `afade`
    - 清理失效条目：`--enable-decoder=sonic`（9.0.1 已移除该解码器）、`--enable-demuxer=afx`（上游从未提供）、`--enable-protocol=hls`（hls 是解复用器，不是协议）；同时删除整段早已失效的 `--disable-decoder=` 列表
    - 删除已被 ffmpeg 上游修复的补丁：`dash_base_url_escape.patch`、`flac-id3-extmeta.patch`
    - `remove-dll-version.patch`、`id3v2-picture.patch`、`disable-install-ln.patch` 已按 9.0.1 源码重新生成
- mpv 改用我们自己的分支 `https://github.com/coolight7/mpv`（master 分支），并按新版 mpv 的 meson 选项补充 `tests`、`dvbin`、`cdda`、`jpeg`、`subrandr` 的关闭项
- 依赖库版本更新：libass 0.17.5、libunibreak 7.0、harfbuzz 14.4.0、freetype 2-14-3、mbedtls 3.6.7、dav1d 1.5.4、libxml2 2.15.4、libplacebo 7.360.1（新版 mpv 要求 libplacebo 不低于 7.360.1）
- mediaxx 依旧在编译时 `git pull` 跟随上游 main
- 修正 `build.sh` 的 C 编译参数：`-include cstddef` 是 C++ 头文件，放进 CFLAGS 会让 ffmpeg 的 C 编译器测试直接失败，现在只保留在 CXXFLAGS 中
- 实编过程中一并修掉的问题：
    - `include/path.sh`：把 venv 的 ninja 目录加进 PATH，这样不先 `source venv/bin/activate` 直接跑 `./build.sh` 也不会报 “CMake was unable to find a build program corresponding to Ninja”
    - `crossfiles/*.ini`：`cpp_args`/`objcpp_args` 增加 `-include cstddef`。meson 交叉编译只读 crossfile，不读环境变量 CXXFLAGS，所以 rubberband 这类没有 `#include <cstddef>` 的 C++ 依赖会报 `unknown type name 'size_t'`，必须写进 crossfile 才生效
    - `bundle_default.sh`：`strip` 改成 `strip -x`，新版 Xcode 下不再报 “symbols referenced by indirect symbol table entries that can't be stripped”，并且 libmpv/libmediaxx 能真正瘦身
    - `bundle_default.sh`：不再打包 macOS x86_64（Intel）目标，`copyLib` 对未编译的目标自动跳过

依赖库版本变化后，旧的 deps 目录与 prefix 目录不能继续使用，需要重新下载并全量重编译：
```sh
cd ${项目根目录}/buildscripts/
# download.sh 只在目录不存在时才 clone，所以旧的 deps 必须先删除
# （上一次编译留下的 deps/prefix 是 root 权限，需要 sudo 删除）
sudo rm -rf deps prefix
./download.sh
./patch.sh
# 全量重新编译 ffmpeg、libmpv、mediaxx
./build.sh --prebuild-rm-ffm-mpv-mediaxx
```

## 可能遇到的问题
- patch 应用失败
    - 手动更改之后，git diff 修改patch, 更推荐 git diff {file} > diff.txt, 复制 diff.txt
    - 还是不行就照着 patch 内容手动修改
- 编译报错：
    - 更新 meson 1.8.4 或更高，可以用 pip3 install meson 安装
```sh
Compiling HB for LibreOffice on macOS results in the error "_LIBCPP_ENABLE_ASSERTIONS has been removed, please use _LIBCPP_HARDENING_MODE instead".
```
-   - 编译 mpv 报错，提示 ld 链接时找不到 ffmpeg 动态库 avcodec、avutil 等，但 查看对应目录发现 libavcodec.dylib 存在？
        - ls -lh libavcodec.dylib 查看是否软链接到它本身了，所以文件实际上时不存在的，则检查 ffmpeg 是否执行 patch 禁用 ln 软链接（buildscripts/patches/ffmpeg/disable-install-ln.patch）
- macos/ios libmpv 播放就崩溃
    - 崩溃点在文件关闭 close, 一般时调用 avformat_input_close 时，段错误，Sig 11
    - 考虑动态链接 ffmpeg ，一开始我们把所有库都静态链接进 libmpv，整合得到 libmpv.2.dylib，但运行时出现上述错误，稳定崩溃。
    - 改为编译 ffmpeg 为动态库，libmpv也动态链接 libav*.dylib/libsw*.dylib 其他依赖库保持静态链接，这样就没问题了。
    - 另外 mediaxx 也是链接了 ffmpeg，没有调用 libmpv 的函数，也是只要跟 ffmpeg 静态链接整合到一起就崩溃，同样崩溃在close时，因此问题应该时在 ffmpeg 上
    - 2026-10-13 补：改成固定单库编译之后，这个问题已经定位到具体原因并修掉
        - ffmpeg 用 `--enable-lto=full` 编译成 LLVM bitcode，`libavcodec/apv_parser.c` 里有一个
          `static av_cold void close(AVCodecParserContext *s)`，名字和系统 `close()` 相同
        - 把所有静态库合并进一个 dylib 时，链接器解析 LTO 符号会把 `libavformat/file.c` 里
          `close(fd)` 的调用错误地绑到这个 static 函数上，于是关闭文件时把文件描述符（3）
          当结构体指针解引用，报 `EXC_BAD_ACCESS at 0x3`（崩溃点在 ffmpeg 的关闭流程，与上面记录一致）
        - 之前把 ffmpeg 的 file.c 和 apv_parser.c 分到 libavformat.dylib / libavcodec.dylib 里，
          不在同一个镜像，所以一直没暴露这个问题；当初改成动态链接 ffmpeg 正好绕过了它
          （现在只有单库这一种编译方式，动态 ffmpeg 的做法不再使用）
        - 处理办法：`patches/ffmpeg/rename-apv-parser-static-close.patch` 把这个 static 函数
          改名成 `apv_parser_close`。合并时用 `buildscripts/check-single-lib-symbols.sh` 检查
          「LTO 本地定义 + 未定义引用 + 没有外部定义」的名字，可以提前发现这类同名冲突
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