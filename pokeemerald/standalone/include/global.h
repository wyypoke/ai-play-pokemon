/**
 * AI Standalone - 最小化 global.h
 *
 * 只定义 AI 决策需要的类型和结构体
 * 注意：原版 battle_ai_script_commands.c 包含 "battle.h"，需要创建模拟版本
 */

#ifndef GUARD_GLOBAL_H
#define GUARD_GLOBAL_H

// 标准库
#include <string.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>

// GBA 类型定义
#include "config.h"
#include "gba/gba.h"

// ============================================================================
//                           常量定义（与原版一致）
// ============================================================================

#define PARTY_SIZE 6
#define MAX_MON_MOVES 4
#define MAX_TRAINER_ITEMS 4

// Battler 数量（原版在 constants/battle.h 中定义为枚举值 4）
#define MAX_BATTLERS_COUNT_VAL 4
#define NUM_BATTLE_SIDES 2

#define TRUE  1
#define FALSE 0

// Battler 宏（与原版 constants/battle.h 一致）
#define BIT_SIDE 1
#define BIT_FLANK 2
#define BATTLE_OPPOSITE(id) ((id) ^ BIT_SIDE)
#define BATTLE_PARTNER(id) ((id) ^ BIT_FLANK)
#define GET_BATTLER_SIDE(battler) ((battler) & BIT_SIDE)

#define B_SIDE_PLAYER 0
#define B_SIDE_OPPONENT 1

// 战斗类型标志（与原版 constants/battle.h 一致）
#define BATTLE_TYPE_DOUBLE             (1 << 0)
#define BATTLE_TYPE_LINK               (1 << 1)
#define BATTLE_TYPE_IS_MASTER          (1 << 2)
#define BATTLE_TYPE_TRAINER            (1 << 3)
#define BATTLE_TYPE_FIRST_BATTLE       (1 << 4)
#define BATTLE_TYPE_20                 (1 << 5)
#define BATTLE_TYPE_21                 (1 << 6)
#define BATTLE_TYPE_SAFARI             (1 << 7)
#define BATTLE_TYPE_BATTLE_TOWER       (1 << 8)
#define BATTLE_TYPE_WILD_SCRIPTED      (1 << 9)
#define BATTLE_TYPE_EREADER_TRAINER    (1 << 10)
#define BATTLE_TYPE_ROAMER             (1 << 11)
#define BATTLE_TYPE_SECRET_BASE        (1 << 12)
#define BATTLE_TYPE_GROUDON            (1 << 13)
#define BATTLE_TYPE_RECORDED           (1 << 14)
#define BATTLE_TYPE_RECORDED_LINK      (1 << 15)
#define BATTLE_TYPE_TRAINER_HILL       (1 << 16)
#define BATTLE_TYPE_BATTLE_PALACE      (1 << 17)
#define BATTLE_TYPE_FRONTIER           (1 << 18)
#define BATTLE_TYPE_FACTORY            (1 << 19)
#define BATTLE_TYPE_DOUBLE_INGAME_PARTNER (1 << 20)
#define BATTLE_TYPE_TWO_OPPONENTS      (1 << 21)
#define BATTLE_TYPE_DOME               (1 << 22)
#define BATTLE_TYPE_PALACE             BATTLE_TYPE_BATTLE_PALACE
#define BATTLE_TYPE_INGAME_PARTNER     BATTLE_TYPE_DOUBLE_INGAME_PARTNER

// AI 脚本标志（与原版 constants/battle_ai.h 一致）
#define AI_SCRIPT_CHECK_BAD_MOVE       (1 << 0)
#define AI_SCRIPT_TRY_TO_FAINT         (1 << 1)
#define AI_SCRIPT_CHECK_VIABILITY      (1 << 2)
#define AI_SCRIPT_SETUP_FIRST_TURN     (1 << 3)
#define AI_SCRIPT_RISKY                (1 << 4)
#define AI_SCRIPT_PREFER_POWER         (1 << 5)
#define AI_SCRIPT_PREFER_BATON_PASS    (1 << 6)
#define AI_SCRIPT_DOUBLE_BATTLE        (1 << 7)
#define AI_SCRIPT_HP_AWARE             (1 << 8)
#define AI_SCRIPT_IGNORE_BIDE          (1 << 9)
#define AI_SCRIPT_METRONOME            (1 << 10)
#define AI_SCRIPT_PLEASE_HELP          (1 << 11)
#define AI_SCRIPT_SAFARI               (1 << 30)
#define AI_SCRIPT_ROAMING              (1 << 29)
#define AI_SCRIPT_FIRST_BATTLE         (1 << 31)

// 行动类型
#define B_ACTION_USE_MOVE 0

// AI 选择结果
#define AI_CHOICE_FLEE 0xFE
#define AI_CHOICE_WATCH 0xFF

// 能力等级
#define NUM_BATTLE_STATS 8
#define DEFAULT_STAT_STAGE 6

// 招式限制
#define MOVE_LIMITATIONS_ALL 0xFF
#define ALL_MOVES_MASK 0xF

// 招式结果标志
#define MOVE_RESULT_MISSED                (1 << 0)
#define MOVE_RESULT_SUPER_EFFECTIVE       (1 << 1)
#define MOVE_RESULT_NOT_VERY_EFFECTIVE    (1 << 2)
#define MOVE_RESULT_DOESNT_AFFECT_FOE     (1 << 3)
#define MOVE_RESULT_ONE_HIT_KO            (1 << 4)
#define MOVE_RESULT_NO_EFFECT             (MOVE_RESULT_MISSED | MOVE_RESULT_DOESNT_AFFECT_FOE)

// 属性相克
#define TYPE_MUL_NO_EFFECT       0
#define TYPE_MUL_NOT_EFFECTIVE   5
#define TYPE_MUL_NORMAL          10
#define TYPE_MUL_SUPER_EFFECTIVE 20
#define TYPE_ENDTABLE 0xFF

// 类型检查宏
#define IS_BATTLER_OF_TYPE(battler, type) \
    (gBattleMons[battler].types[0] == (type) || gBattleMons[battler].types[1] == (type))

// 宏
#define ARRAY_COUNT(array) (size_t)(sizeof(array) / sizeof((array)[0]))
#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) >= (b) ? (a) : (b))

// 读取宏
#define T1_READ_8(ptr)  ((ptr)[0])
#define T1_READ_16(ptr) ((ptr)[0] | ((ptr)[1] << 8))
#define T1_READ_32(ptr) ((ptr)[0] | ((ptr)[1] << 8) | ((ptr)[2] << 16) | ((ptr)[3] << 24))
#define T1_READ_PTR(ptr) (const u8 *) T1_READ_32(ptr)

// 类型效果宏
#define TYPE_EFFECT_ATK_TYPE(ptr)   (ptr)[0]
#define TYPE_EFFECT_DEF_TYPE(ptr)   (ptr)[1]
#define TYPE_EFFECT_MULTIPLIER(ptr) (ptr)[2]

// ============================================================================
//                           常量枚举（从原版提取）
// ============================================================================

// 属性 ID
enum {
    TYPE_NORMAL = 0,
    TYPE_FIGHTING,
    TYPE_FLYING,
    TYPE_POISON,
    TYPE_GROUND,
    TYPE_ROCK,
    TYPE_BUG,
    TYPE_GHOST,
    TYPE_STEEL,
    TYPE_MYSTERY,
    TYPE_FIRE,
    TYPE_WATER,
    TYPE_GRASS,
    TYPE_ELECTRIC,
    TYPE_PSYCHIC,
    TYPE_ICE,
    TYPE_DRAGON,
    TYPE_DARK,
};

// 特性 ID（部分）
enum {
    ABILITY_NONE = 0,
    ABILITY_LEVITATE = 26,
    ABILITY_WONDER_GUARD = 25,
    ABILITY_SHADOW_TAG = 23,
    ABILITY_MAGNET_PULL = 42,
    ABILITY_ARENA_TRAP = 71,
    ABILITY_PRESSURE = 46,
    ABILITY_SYNCHRONIZE = 28,
    ABILITY_KEEN_EYE = 51,
    ABILITY_FLASH_FIRE = 18,
};

// 招式效果（部分）
enum {
    EFFECT_EXPLOSION = 153,
    EFFECT_DREAM_EATER = 140,
    EFFECT_RAZOR_WIND = 139,
    EFFECT_SKY_ATTACK = 141,
    EFFECT_RECHARGE = 111,
    EFFECT_SKULL_BASH = 110,
    EFFECT_SOLAR_BEAM = 116,
    EFFECT_SPIT_UP = 82,
    EFFECT_FOCUS_PUNCH = 122,
    EFFECT_SUPERPOWER = 154,
    EFFECT_ERUPTION = 225,
    EFFECT_OVERHEAT = 218,
};

// AI 目标类型
#define AI_USER           0
#define AI_TARGET         1
#define AI_USER_PARTNER   2
#define AI_TARGET_PARTNER 3
#define AI_TYPE1_USER     0
#define AI_TYPE1_TARGET   1
#define AI_TYPE2_USER     2
#define AI_TYPE2_TARGET   3
#define AI_TYPE_MOVE      4

// AI 属性相克评分
#define AI_EFFECTIVENESS_x1      10
#define AI_EFFECTIVENESS_x2      20
#define AI_EFFECTIVENESS_x4      40
#define AI_EFFECTIVENESS_x0_5    5
#define AI_EFFECTIVENESS_x0_25   2
#define AI_EFFECTIVENESS_x0      0

// 招式威力分类
#define MOVE_MOST_POWERFUL     2
#define MOVE_NOT_MOST_POWERFUL 1
#define MOVE_POWER_OTHER       0

// AI 天气
#define AI_WEATHER_NONE  0
#define AI_WEATHER_RAIN  1
#define AI_WEATHER_SANDSTORM 2
#define AI_WEATHER_SUN  3
#define AI_WEATHER_HAIL 4

// 天气标志
#define B_WEATHER_RAIN      (1 << 0)
#define B_WEATHER_SANDSTORM (1 << 1)
#define B_WEATHER_SUN       (1 << 2)
#define B_WEATHER_HAIL      (1 << 3)

// 资源标志
#define RESOURCE_FLAG_FLASH_FIRE (1 << 0)

// 最大 Battler 数量
enum {
    BATTLER_0,
    BATTLER_1,
    BATTLER_2,
    BATTLER_3,
    MAX_BATTLERS_COUNT,
};

// ============================================================================
//                           结构体定义
// ============================================================================

// 战斗宝可梦数据
struct BattlePokemon {
    u16 species;
    u16 attack;
    u16 defense;
    u16 speed;
    u16 spAttack;
    u16 spDefense;
    u16 moves[MAX_MON_MOVES];
    u32 hpIV:5;
    u32 attackIV:5;
    u32 defenseIV:5;
    u32 speedIV:5;
    u32 spAttackIV:5;
    u32 spDefenseIV:5;
    u32 isEgg:1;
    u32 abilityNum:1;
    s8 statStages[NUM_BATTLE_STATS];
    u8 ability;
    u8 types[2];
    u8 unknown;
    u8 pp[MAX_MON_MOVES];
    u16 hp;
    u8 level;
    u8 friendship;
    u16 maxHP;
    u16 item;
    u8 nickname[11];
    u8 ppBonuses;
    u8 otName[8];
    u32 experience;
    u32 personality;
    u32 status1;
    u32 status2;
    u32 otId;
};

// 招式数据
struct BattleMove {
    u8 effect;
    u8 power;
    u8 type;
    u8 accuracy;
    u8 pp;
    u8 secondaryEffectChance;
    u8 target;
    s8 priority;
    u32 flags;
};

// 种族信息
struct SpeciesInfo {
    u8 baseHP;
    u8 baseAttack;
    u8 baseDefense;
    u8 baseSpeed;
    u8 baseSpAttack;
    u8 baseSpDefense;
    u8 types[2];
    u8 catchRate;
    u8 expYield;
    u16 evYield;
    u16 abilities[2];
};

// AI 思考结构
struct AI_ThinkingStruct {
    u8 aiState;
    u8 movesetIndex;
    u16 moveConsidered;
    s8 score[MAX_MON_MOVES];
    u32 funcResult;
    u32 aiFlags;
    u8 aiAction;
    u8 aiLogicId;
    u8 filler12[6];
    u8 simulatedRNG[MAX_MON_MOVES];
};

// 已用招式记录
struct UsedMoves {
    u16 moves[MAX_MON_MOVES];
    u16 unknown[MAX_MON_MOVES];
};

// 战斗历史
struct BattleHistory {
    struct UsedMoves usedMoves[MAX_BATTLERS_COUNT];
    u8 abilities[MAX_BATTLERS_COUNT];
    u8 itemEffects[MAX_BATTLERS_COUNT];
    u16 trainerItems[MAX_BATTLERS_COUNT];
    u8 itemsNo;
};

// AI 脚本栈
struct BattleScriptsStack {
    const u8 *ptr[8];
    u8 size;
};

// 资源标志
struct ResourceFlags {
    u8 flags[MAX_BATTLERS_COUNT];
};

// 战斗资源
struct BattleResources {
    void *secretBase;
    struct ResourceFlags *flags;
    void *battleScriptsStack;
    void *battleCallbackStack;
    void *beforeLvlUp;
    struct AI_ThinkingStruct *ai;
    struct BattleHistory *battleHistory;
    struct BattleScriptsStack *AI_ScriptsStack;
};

// Disable 结构
struct DisableStruct {
    u8 disabledMove;
    u8 disableTimer:4;
    u8 unused1:4;
    u8 encoredMove;
    u8 encoreTimer:4;
    u8 unused2:4;
    u16 protectUses:4;
    u16 stockpileCounter:4;
    u16 substituteHP:7;
    u16 hasSubstitute:1;
    u16 transformedPersonality;
    u8 disabledMoveSlot:4;
    u8 encoredMoveSlot:4;
    u8 isFirstTurn:1;
    u8 unused3:7;
    u8 tauntTimer;
};

// Protect 结构
struct ProtectStruct {
    u32 protected:1;
    u32 spikyShielded:1;
    u32 kingsShielded:1;
    u32 bananaBunchProtected:1;
    u32 enduring:1;
    u32 noValidMoves:1;
    u32 helpingHand:1;
    u32 bounceMove:1;
    u32 stealMove:1;
    u32 flag0Unknown:1;
    u32 prlzImmununity:1;
    u32 usedImprison:1;
    u32 usedProtect:1;
    u32 usedDetect:1;
    u32 usedQuickGuard:1;
    u32 usedWideGuard:1;
    u32 usedCraftyShield:1;
    u32 usedMatBlock:1;
    u32 flag1Unknown:1;
    u32 physicalDmg;
    u32 specialDmg;
    u32 physicalBattlerId:2;
    u32 specialBattlerId:2;
    u32 targetNotAffected:1;
};

// 战斗脚本状态
struct BattleScripting {
    s32 dmgMultiplier;
};

// 战斗结构
struct BattleStruct {
    u8 dynamicMoveType;
    u8 safariEscapeFactor;
    u8 usedHeldItems[MAX_BATTLERS_COUNT][2];
    u8 palaceFlags;
};

// 战斗结果
struct BattleResults {
    u8 playerFaintCounter;
    u8 opponentFaintCounter;
    u8 playerSwitchesCounter;
    u8 numHealingItemsUsed;
    u8 numRevivesUsed;
    u8 playerMonWasDamaged:1;
    u8 usedMasterBall:1;
    u8 caughtMonBall:4;
    u8 shinyWildMon:1;
    u16 playerMon1Species;
    u8 playerMon1Name[11];
    u8 battleTurnCounter;
};

// 训练家数据
struct Trainer {
    u8 partyFlags;
    u8 trainerClass;
    u8 encounterMusic_gender;
    u8 trainerPic;
    u8 trainerName[12];
    u16 items[MAX_TRAINER_ITEMS];
    u32 aiFlags;
    u8 doubleBattle;
};

// 简化的 Pokemon 结构体（用于 GetMonData）
struct Pokemon {
    u16 species;
    u16 pad1;
    u32 pad2;
    u16 hp;
    // 其他字段...
};

// 队伍
extern struct Pokemon gPlayerParty[PARTY_SIZE];
extern struct Pokemon gEnemyParty[PARTY_SIZE];

// ============================================================================
//                           全局变量声明
// ============================================================================

extern struct BattlePokemon gBattleMons[MAX_BATTLERS_COUNT];
extern struct BattleResources *gBattleResources;
extern u32 gBattleTypeFlags;
extern u8 gActiveBattler;
extern u8 gBattlerTarget;
extern u16 gCurrentMove;
extern u16 gBattleWeather;
extern u8 gAbsentBattlerFlags;
extern u16 gBattlerPartyIndexes[MAX_BATTLERS_COUNT];
extern u16 gTrainerBattleOpponent_A;
extern u16 gTrainerBattleOpponent_B;
extern s32 gBattleMoveDamage;
extern u16 gDynamicBasePower;
extern u8 gCritMultiplier;
extern u8 gMoveResultFlags;
extern u32 gStatuses3[MAX_BATTLERS_COUNT];
extern u16 gSideStatuses[NUM_BATTLE_SIDES];
extern struct DisableStruct gDisableStructs[MAX_BATTLERS_COUNT];
extern struct ProtectStruct gProtectStructs[MAX_BATTLERS_COUNT];
extern struct BattleStruct *gBattleStruct;
extern struct BattleScripting gBattleScripting;
extern const u8 *gBattlescriptCurrInstr;
extern u16 gLastMoves[MAX_BATTLERS_COUNT];
extern u16 gLastLandedMoves[MAX_BATTLERS_COUNT];
extern u16 gLastHitByType[MAX_BATTLERS_COUNT];
extern u8 gLastUsedAbility;
extern struct BattleResults gBattleResults;
extern const u8 *gAIScriptPtr;
extern const struct BattleMove *gBattleMoves;
extern const struct SpeciesInfo *gSpeciesInfo;
extern const u8 *const gBattleAI_ScriptsTable[];
extern const u8 gTypeEffectivenessTable[];
extern const u32 gBitTable[16];
extern const struct Trainer *gTrainers;

// ============================================================================
//                           函数声明
// ============================================================================

u16 Random(void);
void AI_SetRngSeed(u32 seed);
u8 GetBattlerSide(u8 battler);
u8 GetBattlerPosition(u8 battler);
u8 GetBattlerAtPosition(u8 position);
void BattleAI_HandleItemUseBeforeAISetup(u8 defaultScoreMoves);
void BattleAI_SetupAIData(u8 defaultScoreMoves);
u8 BattleAI_ChooseMoveOrAction(void);
void AI_CalcDmg(u8 attacker, u8 defender);
u8 TypeCalc(u16 move, u8 attacker, u8 defender);
u8 CheckMoveLimitations(u8 battler, u8 unusableMoves, u8 checkFlag);
u8 GetWhoStrikesFirst(u8 battler1, u8 battler2, u8 ignoreSpeed);
u8 AttacksThisTurn(u8 battler, u16 move);
u16 GetMonData(void *mon, s32 data);
u8 GetItemHoldEffect(u16 item);
void RecordAbilityBattle(u8 battler, u8 abilityId);

#endif // GUARD_GLOBAL_H
