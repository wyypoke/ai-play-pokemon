/**
 * AI Standalone - 全局变量定义
 *
 * 定义 AI 决策所需的全局变量和辅助函数
 */

#include "global.h"
#include <stdlib.h>
#include <string.h>

// ============================================================================
//                           战斗状态全局变量
// ============================================================================

struct BattlePokemon gBattleMons[MAX_BATTLERS_COUNT];
u32 gBattleTypeFlags = 0;
u8 gActiveBattler = 0;
u8 gBattlerTarget = 0;
u16 gCurrentMove = 0;
u16 gBattleWeather = 0;
u8 gAbsentBattlerFlags = 0;
u16 gBattlerPartyIndexes[MAX_BATTLERS_COUNT];
u16 gTrainerBattleOpponent_A = 0;
u16 gTrainerBattleOpponent_B = 0;

// ============================================================================
//                           AI 思考结构
// ============================================================================

struct AI_ThinkingStruct gAI_ThinkingData;
struct BattleHistory gBattleHistoryData;
struct BattleScriptsStack gAI_ScriptsStackData;
struct ResourceFlags gResourceFlagsData;

struct BattleResources gBattleResourcesData = {
    .secretBase = NULL,
    .flags = &gResourceFlagsData,
    .battleScriptsStack = NULL,
    .battleCallbackStack = NULL,
    .beforeLvlUp = NULL,
    .ai = &gAI_ThinkingData,
    .battleHistory = &gBattleHistoryData,
    .AI_ScriptsStack = &gAI_ScriptsStackData,
};

struct BattleResources *gBattleResources = &gBattleResourcesData;

// ============================================================================
//                           伤害计算变量
// ============================================================================

s32 gBattleMoveDamage = 0;
u16 gDynamicBasePower = 0;
u8 gCritMultiplier = 1;
u8 gMoveResultFlags = 0;

u32 gStatuses3[MAX_BATTLERS_COUNT] = {0};
u16 gSideStatuses[NUM_BATTLE_SIDES] = {0};
struct DisableStruct gDisableStructs[MAX_BATTLERS_COUNT];
struct ProtectStruct gProtectStructs[MAX_BATTLERS_COUNT];

struct BattleStruct gBattleStructData;
struct BattleStruct *gBattleStruct = &gBattleStructData;

struct BattleScripting gBattleScripting;
const u8 *gBattlescriptCurrInstr = NULL;

// ============================================================================
//                           历史记录
// ============================================================================

u16 gLastMoves[MAX_BATTLERS_COUNT] = {0};
u16 gLastLandedMoves[MAX_BATTLERS_COUNT] = {0};
u16 gLastHitByType[MAX_BATTLERS_COUNT] = {0};
u8 gLastUsedAbility = 0;

struct BattleResults gBattleResults;

// 队伍
struct Pokemon gPlayerParty[PARTY_SIZE];
struct Pokemon gEnemyParty[PARTY_SIZE];

// 数据表（存根）
static const struct BattleMove sDummyBattleMoves[1] = {0};
const struct BattleMove *gBattleMoves = sDummyBattleMoves;

static const struct SpeciesInfo sDummySpeciesInfo[1] = {0};
const struct SpeciesInfo *gSpeciesInfo = sDummySpeciesInfo;

static const u8 sDummyAIScripts[1] = {0};
const u8 *const gBattleAI_ScriptsTable[8] = {
    sDummyAIScripts, sDummyAIScripts, sDummyAIScripts, sDummyAIScripts,
    sDummyAIScripts, sDummyAIScripts, sDummyAIScripts, sDummyAIScripts
};

const u32 gBitTable[16] = {
    0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80,
    0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000
};

// ============================================================================
//                           AI 脚本指针（原版定义）
// ============================================================================

// gAIScriptPtr 在原版 battle_ai_script_commands.c 中定义，这里只声明
extern const u8 *gAIScriptPtr;

// ============================================================================
//                           训练家数据
// ============================================================================

static const struct Trainer sDummyTrainer = {0};
const struct Trainer *gTrainers = &sDummyTrainer;

// ============================================================================
//                           随机数
// ============================================================================

static u32 sRngSeed = 0;

void AI_SetRngSeed(u32 seed) {
    sRngSeed = seed;
    srand(seed);
}

u16 Random(void) {
    return (u16)(rand() & 0xFFFF);
}

// ============================================================================
//                           辅助函数
// ============================================================================

u8 GetBattlerSide(u8 battler) {
    return GET_BATTLER_SIDE(battler);
}

u8 GetBattlerPosition(u8 battler) {
    return battler;
}

u8 GetBattlerAtPosition(u8 position) {
    return position;
}

// ============================================================================
//                           存根函数（AI 需要但不实现完整逻辑）
// ============================================================================

u8 CheckMoveLimitations(u8 battler, u8 unusableMoves, u8 checkFlag) {
    // 简化实现：检查 PP 和招式是否存在
    (void)battler;
    (void)checkFlag;
    u8 result = unusableMoves;
    for (int i = 0; i < MAX_MON_MOVES; i++) {
        if (gBattleMons[battler].moves[i] == 0 || gBattleMons[battler].pp[i] == 0) {
            result |= (1 << i);
        }
    }
    return result;
}

u8 GetWhoStrikesFirst(u8 battler1, u8 battler2, u8 ignoreSpeed) {
    (void)ignoreSpeed;
    if (gBattleMons[battler1].speed > gBattleMons[battler2].speed)
        return battler1;
    if (gBattleMons[battler2].speed > gBattleMons[battler1].speed)
        return battler2;
    return Random() & 1 ? battler1 : battler2;
}

u8 AttacksThisTurn(u8 battler, u16 move) {
    (void)battler;
    (void)move;
    return 2;  // 正常攻击
}

u16 GetMonData(void *mon, s32 data) {
    (void)mon;
    (void)data;
    return 0;
}

u8 GetItemHoldEffect(u16 item) {
    (void)item;
    return 0;
}

// ============================================================================
//                           初始化函数
// ============================================================================

void AI_InitBattle(void) {
    memset(gBattleMons, 0, sizeof(gBattleMons));
    memset(&gAI_ThinkingData, 0, sizeof(gAI_ThinkingData));
    memset(&gBattleHistoryData, 0, sizeof(gBattleHistoryData));
    memset(gDisableStructs, 0, sizeof(gDisableStructs));
    memset(gProtectStructs, 0, sizeof(gProtectStructs));

    gBattleTypeFlags = 0;
    gActiveBattler = 0;
    gBattlerTarget = 0;
    gBattleMoveDamage = 0;
    gMoveResultFlags = 0;
}

// 存根函数
u8 GetGenderFromSpeciesAndPersonality(u16 species, u32 personality) {
    (void)species;
    (void)personality;
    return 0;  // Male
}

void AI_CalcDmg(u8 attacker, u8 defender) {
    (void)attacker;
    (void)defender;
    gBattleMoveDamage = 40;  // 基础伤害
}

u8 TypeCalc(u16 move, u8 attacker, u8 defender) {
    (void)attacker;
    (void)defender;
    // 简化：假设招式有效
    u8 moveType = gBattleMoves[move].type;
    u8 targetType1 = gBattleMons[defender].types[0];
    u8 targetType2 = gBattleMons[defender].types[1];

    // 检查免疫
    if ((moveType == TYPE_GROUND && gBattleMons[defender].ability == ABILITY_LEVITATE) ||
        (moveType == TYPE_PSYCHIC && targetType1 == TYPE_DARK) ||
        (moveType == TYPE_PSYCHIC && targetType2 == TYPE_DARK)) {
        return MOVE_RESULT_DOESNT_AFFECT_FOE;
    }
    return 0;
}

u32 GetAiScriptsInRecordedBattle(void) {
    return 0;
}

u32 GetAiScriptsInBattleFactory(void) {
    return 0;
}

// RecordAbilityBattle 在原版 battle_ai_script_commands.c 中定义

// 主入口（Windows）
#ifdef _WIN32
int main(void) {
    printf("AI Standalone compiled successfully!\n");
    printf("Original battle_ai_script_commands.c compiled without modification.\n");
    return 0;
}
#endif
