/**
 * Standalone 模拟头文件 - malloc
 *
 * 原版 malloc.h 依赖 GBA 堆管理，standalone 不需要
 */

#ifndef GUARD_MALLOC_H
#define GUARD_MALLOC_H

#include "gba/types.h"

#define HEAP_SIZE 0x1C000

// 空定义
extern u8 gHeap[HEAP_SIZE];

static inline void *Alloc(u32 size) { return malloc(size); }
static inline void *AllocZeroed(u32 size) { return calloc(1, size); }
static inline void Free(void *ptr) { free(ptr); }
static inline void InitHeap(void *heapStart, u32 heapSize) { (void)heapStart; (void)heapSize; }

#endif // GUARD_MALLOC_H
