// 单库 libmediaxx.dylib 的运行时检查程序
//
// 用途：编译时把 ffmpeg / libmpv / mediaxx 合并进一个 dylib，链接期的符号问题
// （见 patches/ffmpeg/rename-apv-parser-static-close.patch）要到运行时才会暴露，
// 所以编译完之后用它跑一遍：反复读媒体信息、反复播放并关闭，检查有没有崩溃。
//
// 编译与运行见同目录的 run.sh

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "mediaxx.h"
#include "mpv/client.h"

static int g_fail = 0;

static void check(int ok, const char *what) {
    if (!ok) {
        printf("  [FAIL] %s\n", what);
        g_fail++;
    }
}

// 1. mediaxx 接口：读媒体信息（内部会打开并关闭文件）
static void test_mediaxx_info(const char *file, int rounds) {
    printf("== mediaxx 读媒体信息 x%d ==\n", rounds);
    for (int i = 0; i < rounds; i++) {
        const char *out_result = nullptr;
        const char *out_log    = nullptr;
        // mediaxx 的接口要求参数非空，不需要的传空字符串
        int ret = mediaxx_get_media_info_malloc(file, "", "", "", &out_result, &out_log);
        if (ret != 0 || out_result == nullptr) {
            printf("  [FAIL] 第 %d 次: ret=%d log=%s\n", i, ret, out_log ? out_log : "(null)");
            g_fail++;
        } else if (i == 0) {
            printf("  第 1 次结果前 120 字符: %.120s\n", out_result);
        }
        if (out_result) mediaxx_free(out_result);
        if (out_log) mediaxx_free(out_log);
    }
    printf("  完成 %d 次\n", rounds);
}

// 2. libmpv 接口：创建 -> 播放到结束 -> 销毁（销毁走关文件的路径）
static void test_mpv_play(const char *file, int rounds) {
    printf("== libmpv 播放并关闭 x%d ==\n", rounds);
    for (int i = 0; i < rounds; i++) {
        mpv_handle *mpv = mpv_create();
        if (!mpv) {
            printf("  [FAIL] 第 %d 次: mpv_create 失败\n", i);
            g_fail++;
            return;
        }
        // 播放结束后自动退出，不需要显示设备
        mpv_set_option_string(mpv, "vo", "null");
        mpv_set_option_string(mpv, "ao", "null");
        mpv_set_option_string(mpv, "terminal", "no");
        mpv_set_option_string(mpv, "msg-level", "all=error");

        if (mpv_initialize(mpv) < 0) {
            printf("  [FAIL] 第 %d 次: mpv_initialize 失败\n", i);
            g_fail++;
            mpv_terminate_destroy(mpv);
            return;
        }

        const char *cmd[] = {"loadfile", file, nullptr};
        if (mpv_command(mpv, cmd) < 0) {
            printf("  [FAIL] 第 %d 次: loadfile 失败\n", i);
            g_fail++;
            mpv_terminate_destroy(mpv);
            return;
        }

        // 等播放结束；结束事件是正常退出，其它结束原因记下来
        while (1) {
            mpv_event *ev = mpv_wait_event(mpv, 5.0);
            if (ev->event_id == MPV_EVENT_NONE) {
                printf("  [FAIL] 第 %d 次: 等播放结束超时\n", i);
                g_fail++;
                break;
            }
            if (ev->event_id == MPV_EVENT_END_FILE) {
                mpv_event_end_file *e = (mpv_event_end_file *)ev->data;
                if (e && e->reason != MPV_END_FILE_REASON_EOF) {
                    printf("  [FAIL] 第 %d 次: 结束原因=%d\n", i, e->reason);
                    g_fail++;
                }
                break;
            }
            if (ev->event_id == MPV_EVENT_SHUTDOWN) break;
        }

        // 关闭路径就在 mpv_terminate_destroy 里面
        mpv_terminate_destroy(mpv);
        if ((i + 1) % 10 == 0) printf("  已完成 %d 次播放+关闭\n", i + 1);
    }
    printf("  完成 %d 次\n", rounds);
}

int main(int argc, char *argv[]) {
    // 不缓冲，崩溃时也能看到已经跑到哪一步
    setvbuf(stdout, nullptr, _IONBF, 0);

    if (argc < 2) {
        printf("用法: %s <媒体文件> [读信息次数=40] [播放次数=20]\n", argv[0]);
        return 2;
    }
    const char *file = argv[1];
    int info_rounds  = (argc > 2) ? atoi(argv[2]) : 40;
    int play_rounds  = (argc > 3) ? atoi(argv[3]) : 20;

    printf("媒体文件: %s\n", file);
    printf("libmediaxx 版本: %s\n", mediaxx_get_label_malloc());
    printf("libmpv 客户端 API 版本: %lu\n", mpv_client_api_version());

    test_mediaxx_info(file, info_rounds);
    test_mpv_play(file, play_rounds);

    printf("\n=== %s (失败 %d 项) ===\n", g_fail == 0 ? "全部通过，没有崩溃" : "有失败项", g_fail);
    return g_fail == 0 ? 0 : 1;
}
