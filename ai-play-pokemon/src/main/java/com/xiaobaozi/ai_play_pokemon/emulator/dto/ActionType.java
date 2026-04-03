package com.xiaobaozi.ai_play_pokemon.emulator.dto;

/**
 * 游戏操作类型枚举
 */
public enum ActionType {
    /**
     * 使用招式
     */
    MOVE,

    /**
     * 替换宝可梦
     */
    SWITCH,

    /**
     * 濒死替换
     */
    FORCE_SWITCH,

    /**
     * Team Preview 首发选择
     */
    TEAM_PREVIEW
}
