package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * 操作结果
 */
public class ActionResult {

    /**
     * 是否成功
     */
    private boolean success;

    /**
     * 到达的决策点
     */
    private DecisionPoint decisionPoint;

    /**
     * 战报片段
     */
    private String battleLog;

    /**
     * 战斗上下文
     */
    private BattleContext context;

    /**
     * 战斗是否结束
     */
    private boolean battleEnded;

    /**
     * 胜者（p1/p2）
     */
    private String winner;

    /**
     * 错误信息
     */
    private List<String> errors;

    // ==================== 构造函数 ====================

    public ActionResult() {
        this.errors = new ArrayList<>();
    }

    // ==================== 静态工厂方法 ====================

    /**
     * 创建成功结果
     */
    public static ActionResult success(DecisionPoint decisionPoint, BattleContext context) {
        ActionResult result = new ActionResult();
        result.setSuccess(true);
        result.setDecisionPoint(decisionPoint);
        result.setContext(context);
        return result;
    }

    /**
     * 创建失败结果
     */
    public static ActionResult failure(String error) {
        ActionResult result = new ActionResult();
        result.setSuccess(false);
        result.getErrors().add(error);
        return result;
    }

    /**
     * 创建战斗结束结果
     */
    public static ActionResult battleEnded(String winner) {
        ActionResult result = new ActionResult();
        result.setSuccess(true);
        result.setDecisionPoint(DecisionPoint.BATTLE_ENDED);
        result.setBattleEnded(true);
        result.setWinner(winner);
        return result;
    }

    // ==================== JSON 解析 ====================

    public static ActionResult fromJson(JSONObject json) {
        if (json == null) return null;

        ActionResult result = new ActionResult();
        result.success = json.getBooleanValue("success");
        result.battleEnded = json.getBooleanValue("battleEnded");
        result.winner = json.getString("winner");
        result.battleLog = json.getString("battleLog");

        // 解析决策点
        String dpStr = json.getString("decisionPoint");
        if (dpStr != null) {
            try {
                result.decisionPoint = DecisionPoint.valueOf(dpStr.toUpperCase());
            } catch (IllegalArgumentException e) {
                // 忽略无效的决策点
            }
        }

        // 解析战斗上下文
        if (json.containsKey("context")) {
            result.context = BattleContext.fromJson(json.getJSONObject("context"));
        }

        // 解析错误信息
        if (json.containsKey("errors")) {
            JSONArray errorsArray = json.getJSONArray("errors");
            for (int i = 0; i < errorsArray.size(); i++) {
                result.errors.add(errorsArray.getString(i));
            }
        }

        return result;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("success", success);
        json.put("battleEnded", battleEnded);
        if (winner != null) {
            json.put("winner", winner);
        }
        if (battleLog != null) {
            json.put("battleLog", battleLog);
        }
        if (decisionPoint != null) {
            json.put("decisionPoint", decisionPoint.name());
        }
        if (context != null) {
            json.put("context", context.toJson());
        }
        if (!errors.isEmpty()) {
            json.put("errors", errors);
        }
        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 检查是否需要决策
     */
    public boolean needsDecision() {
        return decisionPoint != null &&
                decisionPoint != DecisionPoint.BATTLE_ENDED;
    }

    /**
     * 检查是否需要濒死替换
     */
    public boolean needsForceSwitch() {
        return decisionPoint == DecisionPoint.FORCE_SWITCH;
    }

    /**
     * 检查是否是 Team Preview
     */
    public boolean isTeamPreview() {
        return decisionPoint == DecisionPoint.TEAM_PREVIEW;
    }

    /**
     * 获取第一个错误信息
     */
    public String getFirstError() {
        return errors.isEmpty() ? null : errors.get(0);
    }

    // ==================== Getter/Setter ====================

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public DecisionPoint getDecisionPoint() {
        return decisionPoint;
    }

    public void setDecisionPoint(DecisionPoint decisionPoint) {
        this.decisionPoint = decisionPoint;
    }

    public String getBattleLog() {
        return battleLog;
    }

    public void setBattleLog(String battleLog) {
        this.battleLog = battleLog;
    }

    public BattleContext getContext() {
        return context;
    }

    public void setContext(BattleContext context) {
        this.context = context;
    }

    public boolean isBattleEnded() {
        return battleEnded;
    }

    public void setBattleEnded(boolean battleEnded) {
        this.battleEnded = battleEnded;
    }

    public String getWinner() {
        return winner;
    }

    public void setWinner(String winner) {
        this.winner = winner;
    }

    public List<String> getErrors() {
        return errors;
    }

    public void setErrors(List<String> errors) {
        this.errors = errors;
    }

    @Override
    public String toString() {
        return String.format("ActionResult{success=%s, decisionPoint=%s, battleEnded=%s, winner='%s'}",
                success, decisionPoint, battleEnded, winner);
    }
}
