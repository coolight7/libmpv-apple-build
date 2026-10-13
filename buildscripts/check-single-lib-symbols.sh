#!/bin/bash
# 静态库合并成 libmediaxx.dylib 时的符号检查
#
# 编译时会把 ffmpeg / libmpv / 各依赖的静态库合并成一个 libmediaxx.dylib。
# 如果某个 LTO bitcode 目标里有一个 static 函数，名字和系统库函数相同，
# 而另一个目标又把这个名字当外部函数引用，链接器会把那个外部调用错误地绑到这个
# static 函数上：编译能通过，运行时会崩。
# 例：libavcodec/apv_parser.c 里的 static close() 吞掉了 libavformat/file.c 对系统
# close() 的调用，关闭文件时把文件描述符当指针解引用，出现 EXC_BAD_ACCESS at 0x3。
#
# 这里找出「LTO 目标里有本地定义 + 有未定义引用 + 静态输入里没有任何外部定义」的名字，
# 也就是会被错误解析、只能来自系统库的名字。
# 修补方式参考 patches/ffmpeg/rename-apv-parser-static-close.patch（把那个 static 函数改名）。
#
# 用法: ./check-single-lib-symbols.sh [prefix/Darwin/arm64 ...]
#       不带参数时检查所有已编译的 prefix/*/* 目录

set -o pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"

NM="${NM:-$(xcrun -f llvm-nm 2>/dev/null || echo nm)}"

if [ $# -gt 0 ]; then
    targets=("$@")
else
    targets=(prefix/*/*)
fi

tmp=$(mktemp -d 2>/dev/null || mktemp -d -t singlelib)
trap 'rm -rf "$tmp"' EXIT

failed=0

for target in "${targets[@]}"; do
    [ -d "$target/lib" ] || continue

    # 把静态库和 mediaxx 自己的目标文件一起扫一遍
    : > "$tmp/nm.txt"
    for lib in "$target"/lib/*.a; do
        [ -f "$lib" ] || continue
        "$NM" -A -m "$lib" >> "$tmp/nm.txt" 2>/dev/null
    done
    # mediaxx 的构建目录名是 _build-Darwin-arm64 这种形式（斜杠换成横线）
    objdir="deps/mediaxx/src/_build-$(echo "${target#prefix/}" | tr '/' '-')/CMakeFiles/mediaxx.dir"
    if [ -d "$objdir" ]; then
        find "$objdir" -name '*.o' -print0 | xargs -0 "$NM" -A -m >> "$tmp/nm.txt" 2>/dev/null
    fi

    # local: LTO bitcode 里的非外部定义（static 函数或变量）
    # undef: 未定义引用（需要外部提供，通常来自系统库）
    # ext:   静态输入里的外部定义（可以正常满足未定义引用）
    awk '
        / \(LTO/ && /non-external/     { print $NF }
    ' "$tmp/nm.txt" | sort -u > "$tmp/local"
    awk '
        /\(undefined\)/                { print $NF }
    ' "$tmp/nm.txt" | sort -u > "$tmp/undef"
    awk '
        /external/ && !/non-external/ && !/\(undefined\)/  { print $NF }
    ' "$tmp/nm.txt" | sort -u > "$tmp/ext"

    hazards=$(comm -12 "$tmp/local" "$tmp/undef" | comm -23 - "$tmp/ext")

    echo "== 检查 $target =="
    echo "   LTO 本地定义 $(wc -l < "$tmp/local" | tr -d ' ') 个，未定义引用 $(wc -l < "$tmp/undef" | tr -d ' ') 个"
    if [ -n "$hazards" ]; then
        echo "   发现会被错误解析的名字（运行时可能崩溃）:"
        echo "$hazards" | sed 's/^/     /'
        echo "   查来源: $NM -A -m $target/lib/*.a | grep '<名字>$'"
        failed=1
    else
        echo "   没有同名冲突"
    fi
done

if [ "$failed" != "0" ]; then
    echo ""
    echo "符号检查未通过：上面列出的名字在合并后的 dylib 里会绑到静态库内部的同名函数，"
    echo "而不是系统库。请打补丁改掉对应的 static 函数名后重新编译。"
    exit 1
fi

echo "符号检查通过"
exit 0
