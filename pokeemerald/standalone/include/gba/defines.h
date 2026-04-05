/**
 * Standalone 模拟头文件 - GBA defines
 *
 * 替代原版 include/gba/defines.h
 * 空定义 GBA 特定宏，让代码在 PC 上编译
 */

#ifndef GUARD_GBA_DEFINES_H
#define GUARD_GBA_DEFINES_H

#include <stddef.h>

// TRUE/FALSE 与原版一致
#define TRUE  1
#define FALSE 0

// GBA 内存段宏 - PC 上空定义
#define IWRAM_DATA
#define EWRAM_DATA
#define COMMON_DATA

// 编译器属性
#define UNUSED    __attribute__((unused))
#define NOINLINE  __attribute__((noinline))
#define ALIGNED(n) __attribute__((aligned(n)))

// GBA 硬件地址 - standalone 不使用，定义为 0 避免错误
#define SOUND_INFO_PTR ((void *)0)
#define INTR_CHECK     0
#define INTR_VECTOR    ((void *)0)

// GBA 内存范围 - standalone 不使用
#define EWRAM_START 0
#define EWRAM_END   0
#define IWRAM_START 0
#define IWRAM_END   0

// 图形相关 - standalone 不使用
#define PLTT          0
#define BG_PLTT       0
#define BG_PLTT_SIZE  0
#define OBJ_PLTT      0
#define OBJ_PLTT_SIZE 0
#define PLTT_SIZE     0

#define VRAM      0
#define VRAM_SIZE 0

#define BG_VRAM           0
#define BG_VRAM_SIZE      0
#define BG_CHAR_SIZE      0
#define BG_SCREEN_SIZE    0
#define BG_CHAR_ADDR(n)   0
#define BG_SCREEN_ADDR(n) 0

#define BG_TILE_H_FLIP(n) (0 + (n))
#define BG_TILE_V_FLIP(n) (0 + (n))

#define NUM_BACKGROUNDS 4

#define OBJ_VRAM0      0
#define OBJ_VRAM0_SIZE 0
#define OBJ_VRAM1      0
#define OBJ_VRAM1_SIZE 0

#define OAM      0
#define OAM_SIZE 0

#define ROM_HEADER_SIZE   0

#define TILE_WIDTH  8
#define TILE_HEIGHT 8

#define DISPLAY_WIDTH  240
#define DISPLAY_HEIGHT 160

#define DISPLAY_TILE_WIDTH  (DISPLAY_WIDTH / TILE_WIDTH)
#define DISPLAY_TILE_HEIGHT (DISPLAY_HEIGHT / TILE_HEIGHT)

#define TILE_SIZE(bpp) ((bpp) * TILE_WIDTH * TILE_HEIGHT / 8)
#define TILE_SIZE_1BPP 8
#define TILE_SIZE_4BPP 32
#define TILE_SIZE_8BPP 64

#define TILE_OFFSET_4BPP(n) ((n) * TILE_SIZE_4BPP)
#define TILE_OFFSET_8BPP(n) ((n) * TILE_SIZE_8BPP)

#define TOTAL_OBJ_TILE_COUNT 1024

#define PLTT_SIZEOF(n) ((n) * sizeof(u16))
#define PLTT_SIZE_4BPP 32
#define PLTT_SIZE_8BPP 512

#define PLTT_OFFSET_4BPP(n) ((n) * PLTT_SIZE_4BPP)

#endif // GUARD_GBA_DEFINES_H
