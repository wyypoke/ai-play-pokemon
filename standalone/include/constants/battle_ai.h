/**
 * AI Standalone - constants/battle_ai.h 模拟
 */

#ifndef GUARD_CONSTANTS_BATTLE_AI_H
#define GUARD_CONSTANTS_BATTLE_AI_H

// AI 脚本标志
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

#endif // GUARD_CONSTANTS_BATTLE_AI_H
