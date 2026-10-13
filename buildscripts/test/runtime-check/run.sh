#!/bin/bash -e
# libmediaxx.dylib 的运行时检查
#
# 用法: ./run.sh [输出目录, 默认 ../../../output/Darwin/arm64] [读信息次数] [播放次数]
# 例:   ./run.sh
#       ./run.sh ../../../output/Darwin/arm64 60 30
#
# 只能跑 macOS（Darwin/arm64）的产物；iOS 的 dylib 编译出来只能做静态检查
# （buildscripts/check-single-lib-symbols.sh）。

cd "$( dirname "${BASH_SOURCE[0]}" )"

OUT_DIR="${1:-../../../output/Darwin/arm64}"
INFO_ROUNDS="${2:-40}"
PLAY_ROUNDS="${3:-20}"

PREFIX_DIR="../../prefix/Darwin/arm64"
MEDIA_FILE="${TMPDIR:-/tmp}/libmediaxx_runtime_check.wav"

if [ ! -f "$OUT_DIR/libmediaxx.dylib" ]; then
    echo "找不到 $OUT_DIR/libmediaxx.dylib，请先执行 buildscripts/bundle_default.sh" >&2
    exit 1
fi

# 生成一段 3 秒 44100Hz 立体声的测试音频（不依赖外部素材）
if [ ! -f "$MEDIA_FILE" ]; then
    echo "生成测试音频: $MEDIA_FILE"
    python3 - "$MEDIA_FILE" <<'PY'
import math, struct, sys, wave

path = sys.argv[1]
rate = 44100
seconds = 3
with wave.open(path, "w") as f:
    f.setnchannels(2)
    f.setsampwidth(2)
    f.setframerate(rate)
    frames = bytearray()
    for i in range(rate * seconds):
        v = int(12000 * math.sin(2 * math.pi * 440 * i / rate))
        frames += struct.pack("<hh", v, v)
    f.writeframes(bytes(frames))
PY
fi

# 在临时目录里编译运行，输出目录只放编译产物，不掺测试文件
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/single-lib-check.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT
cp "$OUT_DIR/libmediaxx.dylib" "$work_dir/"

# 链接只需要 libmediaxx.dylib 与头文件；rpath 用 @loader_path 指到同一个目录
clang++ -std=c++17 -O1 -g \
    -I"$PREFIX_DIR/include" \
    -L"$work_dir" \
    -Wl,-rpath,@loader_path \
    -o "$work_dir/check_single_lib" \
    check_single_lib.cpp \
    -lmediaxx

echo "运行: 读媒体信息 x$INFO_ROUNDS，播放并关闭 x$PLAY_ROUNDS"
echo "--------------------------------------------------------------"
"$work_dir/check_single_lib" "$MEDIA_FILE" "$INFO_ROUNDS" "$PLAY_ROUNDS"
