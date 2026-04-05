#ifndef GUARD_INJECTED_PARTY_H
#define GUARD_INJECTED_PARTY_H

// 注入地址定义 (EWRAM 空闲区域)
#define INJECTED_PARTY_ADDR     0x0203D000

// 魔数标识
#define INJECTED_PARTY_MAGIC    0xDEADBEEF

// 最大队伍数量
#define INJECTED_PARTY_SIZE     6

// 单只宝可梦注入数据结构 (64字节)
struct InjectedMon
{
    // --- Pokemon 基础属性 (0x00-0x2F) ---
    /* 0x00 */ u16 species;
    /* 0x02 */ u16 item;
    /* 0x04 */ u16 moves[4];
    /* 0x0C */ u8 pp[4];
    /* 0x10 */ u8 ppBonuses;
    /* 0x11 */ u8 level;
    /* 0x12 */ u8 friendship;
    /* 0x13 */ u8 abilityNum;
    /* 0x14 */ u32 personality;
    /* 0x18 */ u8 hpIV;
    /* 0x19 */ u8 attackIV;
    /* 0x1A */ u8 defenseIV;
    /* 0x1B */ u8 speedIV;
    /* 0x1C */ u8 spAttackIV;
    /* 0x1D */ u8 spDefenseIV;
    /* 0x1E */ u8 hpEV;
    /* 0x1F */ u8 attackEV;
    /* 0x20 */ u8 defenseEV;
    /* 0x21 */ u8 speedEV;
    /* 0x22 */ u8 spAttackEV;
    /* 0x23 */ u8 spDefenseEV;
    /* 0x24 */ u32 status1;
    /* 0x28 */ u32 otId;
    /* 0x2C */ u16 currentHP;   // 0 = 满HP
    /* 0x2E */ u16 reserved1;

    // --- BattlePokemon 专属属性 (0x30-0x3F) ---
    /* 0x30 */ u8 statStages[8];  // 能力阶级，默认全6
    /* 0x38 */ u32 status2;       // 战斗状态
    /* 0x3C */ u8 ability;        // 覆盖特性
    /* 0x3D */ u8 types[2];       // 覆盖属性
    /* 0x3F */ u8 reserved2;
} __attribute__((packed));

// 注入数据头部
struct InjectedPartyHeader
{
    /* 0x00 */ u32 magic;
    /* 0x04 */ u8 partySize;
    /* 0x05 */ u8 enabled;
    /* 0x06 */ u16 reserved;
} __attribute__((packed));

// 完整注入结构
struct InjectedParty
{
    struct InjectedPartyHeader header;
    struct InjectedMon mons[INJECTED_PARTY_SIZE];
} __attribute__((packed));

#endif // GUARD_INJECTED_PARTY_H
