package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONObject;

/**
 * 游戏操作
 */
public class GameAction {

    /**
     * 操作类型
     */
    private ActionType type;

    /**
     * 招式槽位 (1-4) 或 替换位置 (1-6)
     */
    private int slot;

    /**
     * 目标位置（双打用）
     * 1 = 敌方左, 2 = 敌方右
     * -1 = 己方位置1, -2 = 己方位置2
     */
    private Integer target;

    /**
     * 招式名称（可选，用于日志）
     */
    private String moveName;

    /**
     * 决策理由（可选，AI 决策时使用）
     */
    private String reason;

    // ==================== 静态工厂方法 ====================

    /**
     * 创建招式操作
     */
    public static GameAction move(int slot, Integer target) {
        GameAction action = new GameAction();
        action.setType(ActionType.MOVE);
        action.setSlot(slot);
        action.setTarget(target);
        return action;
    }

    /**
     * 创建招式操作（无目标）
     */
    public static GameAction move(int slot) {
        return move(slot, null);
    }

    /**
     * 创建招式操作（带名称）
     */
    public static GameAction move(int slot, Integer target, String moveName) {
        GameAction action = move(slot, target);
        action.setMoveName(moveName);
        return action;
    }

    /**
     * 创建替换操作
     */
    public static GameAction switchAction(int position) {
        GameAction action = new GameAction();
        action.setType(ActionType.SWITCH);
        action.setSlot(position);
        return action;
    }

    /**
     * 创建濒死替换操作
     */
    public static GameAction forceSwitch(int position) {
        GameAction action = new GameAction();
        action.setType(ActionType.FORCE_SWITCH);
        action.setSlot(position);
        return action;
    }

    /**
     * 创建 Team Preview 操作
     */
    public static GameAction teamPreview(String slots) {
        GameAction action = new GameAction();
        action.setType(ActionType.TEAM_PREVIEW);
        // slots 如 "12" 表示首发位置 1 和 2
        return action;
    }

    // ==================== JSON 解析 ====================

    public static GameAction fromJson(JSONObject json) {
        if (json == null) return null;

        GameAction action = new GameAction();
        String typeStr = json.getString("type");
        if (typeStr != null) {
            action.type = ActionType.valueOf(typeStr.toUpperCase());
        }
        action.slot = json.getIntValue("slot");
        action.target = json.getInteger("target");
        action.moveName = json.getString("moveName");
        action.reason = json.getString("reason");

        return action;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        if (type != null) {
            json.put("type", type.name().toLowerCase());
        }
        json.put("slot", slot);
        if (target != null) {
            json.put("target", target);
        }
        if (moveName != null) {
            json.put("moveName", moveName);
        }
        if (reason != null) {
            json.put("reason", reason);
        }
        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 转换为模拟器决策字符串
     */
    public String toDecisionString() {
        if (type == null) return "";

        switch (type) {
            case MOVE:
                StringBuilder sb = new StringBuilder("move ").append(slot);
                if (target != null) {
                    sb.append(" ").append(target);
                }
                return sb.toString();

            case SWITCH:
            case FORCE_SWITCH:
                return "switch " + slot;

            case TEAM_PREVIEW:
                return "team " + slot;

            default:
                return "";
        }
    }

    // ==================== Getter/Setter ====================

    public ActionType getType() {
        return type;
    }

    public void setType(ActionType type) {
        this.type = type;
    }

    public int getSlot() {
        return slot;
    }

    public void setSlot(int slot) {
        this.slot = slot;
    }

    public Integer getTarget() {
        return target;
    }

    public void setTarget(Integer target) {
        this.target = target;
    }

    public String getMoveName() {
        return moveName;
    }

    public void setMoveName(String moveName) {
        this.moveName = moveName;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    @Override
    public String toString() {
        return String.format("GameAction{type=%s, slot=%d, target=%s, moveName='%s'}",
                type, slot, target, moveName);
    }
}
