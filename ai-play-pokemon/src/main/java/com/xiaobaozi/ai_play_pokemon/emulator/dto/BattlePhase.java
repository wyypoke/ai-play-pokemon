package com.xiaobaozi.ai_play_pokemon.emulator.dto;

/**
 * Lua 战斗阶段枚举
 * 对应 BATTLE_API.md 中定义的 phase 值
 */
public enum BattlePhase {
    /**
     * 不在战斗中
     */
    NONE(0),

    /**
     * 战斗开场动画
     */
    INTRO(1),

    /**
     * 行动选择（等待输入）
     */
    ACTION_SELECT(2),

    /**
     * 招式执行中
     */
    MOVE_EXECUTION(3),

    /**
     * 濒死替换选择
     */
    FAINT_SWITCH(4),

    /**
     * 战斗结束
     */
    END(5);

    private final int value;

    BattlePhase(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    /**
     * 从 Lua 返回的 phase 值转换
     */
    public static BattlePhase fromValue(int value) {
        for (BattlePhase phase : values()) {
            if (phase.value == value) {
                return phase;
            }
        }
        return NONE;
    }

    /**
     * 转换为 DecisionPoint
     */
    public DecisionPoint toDecisionPoint() {
        switch (this) {
            case ACTION_SELECT:
                return DecisionPoint.TURN_START;
            case FAINT_SWITCH:
                return DecisionPoint.FORCE_SWITCH;
            case END:
            case NONE:
                return DecisionPoint.BATTLE_ENDED;
            default:
                return null;
        }
    }

    /**
     * 是否需要决策
     */
    public boolean needsDecision() {
        return this == ACTION_SELECT || this == FAINT_SWITCH;
    }

    /**
     * 战斗是否结束
     */
    public boolean isBattleEnded() {
        return this == END || this == NONE;
    }
}
