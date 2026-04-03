package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONObject;

/**
 * 招式信息
 */
public class MoveInfo {

    /**
     * 招式槽位 (1-4)
     */
    private int slot;

    /**
     * 招式名称
     */
    private String name;

    /**
     * 当前 PP
     */
    private int currentPp;

    /**
     * 最大 PP
     */
    private int maxPp;

    /**
     * 目标类型
     * normal/any/adjacentAlly/adjacentAllyOrSelf/adjacentFoe/self/allAdjacent/allAdjacentFoes/all/allySide/foeSide
     */
    private String target;

    /**
     * 是否被禁用
     */
    private boolean disabled;

    // ==================== 构造函数 ====================

    public MoveInfo() {
    }

    public MoveInfo(int slot, String name, int currentPp, int maxPp, String target, boolean disabled) {
        this.slot = slot;
        this.name = name;
        this.currentPp = currentPp;
        this.maxPp = maxPp;
        this.target = target;
        this.disabled = disabled;
    }

    // ==================== JSON 解析 ====================

    public static MoveInfo fromJson(JSONObject json) {
        if (json == null) return null;

        MoveInfo move = new MoveInfo();
        move.slot = json.getIntValue("slot");
        move.name = json.getString("name");
        move.currentPp = json.getIntValue("currentPp");
        move.maxPp = json.getIntValue("maxPp");
        move.target = json.getString("target");
        move.disabled = json.getBooleanValue("disabled");

        return move;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("slot", slot);
        json.put("name", name);
        json.put("currentPp", currentPp);
        json.put("maxPp", maxPp);
        json.put("target", target);
        json.put("disabled", disabled);
        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 检查招式是否可用
     */
    public boolean isUsable() {
        return !disabled && currentPp > 0;
    }

    /**
     * 检查是否需要选择目标
     */
    public boolean needsTarget() {
        if (target == null) return true;
        switch (target) {
            case "self":
            case "allAdjacent":
            case "allAdjacentFoes":
            case "all":
            case "allySide":
            case "foeSide":
            case "allies":
            case "allyTeam":
            case "randomNormal":
            case "scripted":
                return false;
            default:
                return true;
        }
    }

    // ==================== Getter/Setter ====================

    public int getSlot() {
        return slot;
    }

    public void setSlot(int slot) {
        this.slot = slot;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getCurrentPp() {
        return currentPp;
    }

    public void setCurrentPp(int currentPp) {
        this.currentPp = currentPp;
    }

    public int getMaxPp() {
        return maxPp;
    }

    public void setMaxPp(int maxPp) {
        this.maxPp = maxPp;
    }

    public String getTarget() {
        return target;
    }

    public void setTarget(String target) {
        this.target = target;
    }

    public boolean isDisabled() {
        return disabled;
    }

    public void setDisabled(boolean disabled) {
        this.disabled = disabled;
    }

    @Override
    public String toString() {
        return String.format("MoveInfo{slot=%d, name='%s', pp=%d/%d, target='%s', disabled=%s}",
                slot, name, currentPp, maxPp, target, disabled);
    }
}
