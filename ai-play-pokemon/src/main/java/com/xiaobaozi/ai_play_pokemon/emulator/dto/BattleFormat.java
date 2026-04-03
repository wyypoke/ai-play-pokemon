package com.xiaobaozi.ai_play_pokemon.emulator.dto;

/**
 * 战斗模式枚举
 */
public enum BattleFormat {
    /**
     * 单打
     * 场上各1只宝可梦，每次1个决策
     */
    SINGLES(1, "singles"),

    /**
     * 双打
     * 场上各2只宝可梦，每次2个决策
     */
    DOUBLES(2, "doubles");

    private final int activeCount;
    private final String code;

    BattleFormat(int activeCount, String code) {
        this.activeCount = activeCount;
        this.code = code;
    }

    /**
     * 获取场上宝可梦数量
     */
    public int getActiveCount() {
        return activeCount;
    }

    /**
     * 获取代码标识
     */
    public String getCode() {
        return code;
    }

    /**
     * 从代码解析
     */
    public static BattleFormat fromCode(String code) {
        if (code == null) return SINGLES;
        switch (code.toLowerCase()) {
            case "doubles":
            case "double":
                return DOUBLES;
            default:
                return SINGLES;
        }
    }

    /**
     * 从场上宝可梦数量判断
     */
    public static BattleFormat fromActiveCount(int count) {
        return count >= 2 ? DOUBLES : SINGLES;
    }
}
