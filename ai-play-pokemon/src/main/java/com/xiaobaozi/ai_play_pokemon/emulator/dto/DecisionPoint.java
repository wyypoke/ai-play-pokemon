package com.xiaobaozi.ai_play_pokemon.emulator.dto;

/**
 * 决策点枚举
 *
 * 表示游戏运行到需要玩家决策的时刻
 */
public enum DecisionPoint {
    /**
     * 回合开始
     * 需要选择招式或替换宝可梦
     */
    TURN_START,

    /**
     * 濒死替换
     * 当前宝可梦濒死，需要选择替换的宝可梦
     */
    FORCE_SWITCH,

    /**
     * Team Preview
     * 战斗开始，选择首发阵容
     */
    TEAM_PREVIEW,

    /**
     * 战斗结束
     */
    BATTLE_ENDED
}
