/**
 * AI Standalone - pokemon.h 模拟
 */

#ifndef GUARD_POKEMON_H
#define GUARD_POKEMON_H

#include "global.h"

// Pokemon 数据访问
u16 GetMonData(void *mon, s32 data);

// 数据常量
enum {
    MON_DATA_SPECIES = 0,
    MON_DATA_HP,
    MON_DATA_MAX_HP,
    MON_DATA_STATUS,
    MON_DATA_SPECIES_OR_EGG,
};

#define SPECIES_NONE 0
#define SPECIES_EGG  0xFFFF

#endif // GUARD_POKEMON_H
