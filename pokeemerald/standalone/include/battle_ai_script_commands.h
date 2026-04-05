/**
 * AI Standalone - battle_ai_script_commands.h 模拟
 */

#ifndef GUARD_BATTLE_AI_SCRIPT_COMMANDS_H
#define GUARD_BATTLE_AI_SCRIPT_COMMANDS_H

#include "global.h"

// 函数声明
void BattleAI_HandleItemUseBeforeAISetup(u8 defaultScoreMoves);
void BattleAI_SetupAIData(u8 defaultScoreMoves);
u8 BattleAI_ChooseMoveOrAction(void);
void AI_CalcDmg(u8 attacker, u8 defender);
u8 TypeCalc(u16 move, u8 attacker, u8 defender);
u8 AI_TypeCalc(u16 move, u16 targetSpecies, u8 targetAbility);
void ClearBattlerMoveHistory(u8 battler);
void RecordAbilityBattle(u8 battler, u8 abilityId);
void ClearBattlerAbilityHistory(u8 battler);
void RecordItemEffectBattle(u8 battler, u8 itemEffect);
void ClearBattlerItemEffectHistory(u8 battler);

#endif // GUARD_BATTLE_AI_SCRIPT_COMMANDS_H
