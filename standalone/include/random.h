/**
 * Standalone 模拟头文件 - random
 */

#ifndef GUARD_RANDOM_H
#define GUARD_RANDOM_H

#include "gba/types.h"

u16 Random(void);
void AI_SetRngSeed(u32 seed);

#endif // GUARD_RANDOM_H
