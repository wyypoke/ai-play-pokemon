#include "global.h"
#include "battle.h"
#include "battle_anim.h"
#include "battle_util.h"
#include "pokemon.h"
#include "util.h"
#include "constants/battle.h"

#define ACTION_INJECT_MAGIC 0xDEADBEEF

// 获取注入数据指针
static struct ActionInjectData *GetActionInjectData(void)
{
    return (struct ActionInjectData *)0x0203D200;
}

// 获取玩家位置索引 (0=左侧, 1=右侧)
static u8 GetPlayerSlotIndex(u8 battler)
{
    u8 position = GetBattlerPosition(battler);
    return (position == B_POSITION_PLAYER_LEFT) ? 0 : 1;
}

// 检查招式是否可用
static bool8 IsMoveUsable(u8 battler, u8 moveIndex)
{
    u8 unusableMask = CheckMoveLimitations(battler, 0,
        MOVE_LIMITATION_PP | MOVE_LIMITATION_DISABLED |
        MOVE_LIMITATION_TAUNT | MOVE_LIMITATION_IMPRISON);

    return !(unusableMask & gBitTable[moveIndex]);
}

// 检查目标是否有效
static bool8 IsTargetValid(u8 battler, u8 target)
{
    if (target >= gBattlersCount)
        return FALSE;
    if (gAbsentBattlerFlags & gBitTable[target])
        return FALSE;
    return TRUE;
}

// 检查切换目标是否有效
static bool8 IsSwitchValid(u8 battler, u8 partyId)
{
    u8 currentPartyId = gBattlerPartyIndexes[battler];

    if (partyId == currentPartyId)
        return FALSE;

    if (GetMonData(&gPlayerParty[partyId], MON_DATA_HP) == 0)
        return FALSE;

    return TRUE;
}

// 阶段1：检查是否需要注入行动类型（用于 HandleInputChooseAction）
// 只返回行动类型，不清除 enabled 标志
bool8 TryGetInjectedActionType(u8 battler, u8 *action)
{
    struct ActionInjectData *data;
    u8 slotIndex;

    data = GetActionInjectData();

    if (data->magic != ACTION_INJECT_MAGIC)
        return FALSE;

    if (!data->enabled || data->waiting)
        return FALSE;

    if (GetBattlerSide(battler) != B_SIDE_PLAYER)
        return FALSE;

    slotIndex = GetPlayerSlotIndex(battler);

    // 只返回行动类型
    *action = data->actions[slotIndex].action;
    return TRUE;
}

// 阶段2：获取注入的招式（用于 HandleInputChooseMove）
// 返回具体招式参数，清除 enabled 标志
bool8 TryGetInjectedMove(u8 battler, u8 *action, u16 *param)
{
    struct ActionInjectData *data;
    struct SingleActionData *slotData;
    u8 slotIndex;

    data = GetActionInjectData();

    if (data->magic != ACTION_INJECT_MAGIC)
        return FALSE;

    if (!data->enabled || data->waiting)
        return FALSE;

    if (GetBattlerSide(battler) != B_SIDE_PLAYER)
        return FALSE;

    slotIndex = GetPlayerSlotIndex(battler);
    slotData = &data->actions[slotIndex];

    // 只处理招式类型
    if (slotData->action != B_ACTION_USE_MOVE)
        return FALSE;

    // 验证招式可用
    if (!IsMoveUsable(battler, slotData->moveIndex))
        return FALSE;

    if (!IsTargetValid(battler, slotData->target))
        return FALSE;

    *action = B_ACTION_EXEC_SCRIPT;  // 10
    *param = slotData->moveIndex | (slotData->target << 8);

    // 清除标志
    data->enabled = FALSE;

    return TRUE;
}

// 尝试获取注入的切换选择
bool8 TryGetInjectedSwitch(u8 battler, u8 *partyId)
{
    struct ActionInjectData *data;
    struct SingleActionData *slotData;
    u8 slotIndex;

    data = GetActionInjectData();

    if (data->magic != ACTION_INJECT_MAGIC)
        return FALSE;

    if (!data->enabled || data->waiting)
        return FALSE;

    if (GetBattlerSide(battler) != B_SIDE_PLAYER)
        return FALSE;

    slotIndex = GetPlayerSlotIndex(battler);
    slotData = &data->actions[slotIndex];

    if (slotData->action != B_ACTION_SWITCH)
        return FALSE;

    if (!IsSwitchValid(battler, slotData->switchMonId))
        return FALSE;

    *partyId = slotData->switchMonId;

    // 清除标志
    data->enabled = FALSE;

    return TRUE;
}
