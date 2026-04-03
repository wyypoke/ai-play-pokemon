package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * 战斗上下文
 *
 * 包含当前战斗的完整状态信息
 */
public class BattleContext {

    /**
     * 战斗模式（单打/双打）
     */
    private BattleFormat battleFormat;

    /**
     * 回合数
     */
    private int turn;

    /**
     * 我方队伍（6只）
     */
    private List<PokemonState> myParty;

    /**
     * 敌方队伍（可见的）
     */
    private List<PokemonState> enemyParty;

    /**
     * 我方场上宝可梦
     */
    private List<PokemonState> myActive;

    /**
     * 敌方场上宝可梦
     */
    private List<PokemonState> enemyActive;

    /**
     * 场地状态
     */
    private FieldState field;

    /**
     * 可用招式列表（单打时使用）
     */
    private List<MoveInfo> availableMoves;

    /**
     * 位置1可用招式列表（双打时使用）
     */
    private List<MoveInfo> slot1Moves;

    /**
     * 位置2可用招式列表（双打时使用）
     */
    private List<MoveInfo> slot2Moves;

    /**
     * 可用替换位置
     */
    private List<Integer> availableSwitches;

    /**
     * 是否需要濒死替换
     */
    private boolean forceSwitch;

    /**
     * 是否 Team Preview 阶段
     */
    private boolean teamPreview;

    // ==================== 构造函数 ====================

    public BattleContext() {
        this.battleFormat = BattleFormat.SINGLES;
        this.myParty = new ArrayList<>();
        this.enemyParty = new ArrayList<>();
        this.myActive = new ArrayList<>();
        this.enemyActive = new ArrayList<>();
        this.availableMoves = new ArrayList<>();
        this.slot1Moves = new ArrayList<>();
        this.slot2Moves = new ArrayList<>();
        this.availableSwitches = new ArrayList<>();
        this.field = new FieldState();
    }

    // ==================== JSON 解析 ====================

    public static BattleContext fromJson(JSONObject json) {
        if (json == null) return null;

        BattleContext context = new BattleContext();
        context.turn = json.getIntValue("turn");
        context.forceSwitch = json.getBooleanValue("forceSwitch");
        context.teamPreview = json.getBooleanValue("teamPreview");

        // 解析战斗模式
        String formatStr = json.getString("battleFormat");
        if (formatStr != null) {
            context.battleFormat = BattleFormat.fromCode(formatStr);
        } else {
            // 根据场上宝可梦数量自动判断
            context.battleFormat = BattleFormat.SINGLES;
        }

        // 解析我方队伍
        if (json.containsKey("myParty")) {
            JSONArray partyArray = json.getJSONArray("myParty");
            for (int i = 0; i < partyArray.size(); i++) {
                context.myParty.add(PokemonState.fromJson(partyArray.getJSONObject(i)));
            }
        }

        // 解析敌方队伍
        if (json.containsKey("enemyParty")) {
            JSONArray partyArray = json.getJSONArray("enemyParty");
            for (int i = 0; i < partyArray.size(); i++) {
                context.enemyParty.add(PokemonState.fromJson(partyArray.getJSONObject(i)));
            }
        }

        // 解析场上宝可梦
        if (json.containsKey("myActive")) {
            JSONArray activeArray = json.getJSONArray("myActive");
            for (int i = 0; i < activeArray.size(); i++) {
                context.myActive.add(PokemonState.fromJson(activeArray.getJSONObject(i)));
            }
        }

        if (json.containsKey("enemyActive")) {
            JSONArray activeArray = json.getJSONArray("enemyActive");
            for (int i = 0; i < activeArray.size(); i++) {
                context.enemyActive.add(PokemonState.fromJson(activeArray.getJSONObject(i)));
            }
        }

        // 解析场地状态
        if (json.containsKey("field")) {
            context.field = FieldState.fromJson(json.getJSONObject("field"));
        }

        // 解析可用招式
        if (json.containsKey("availableMoves")) {
            JSONArray movesArray = json.getJSONArray("availableMoves");
            for (int i = 0; i < movesArray.size(); i++) {
                context.availableMoves.add(MoveInfo.fromJson(movesArray.getJSONObject(i)));
            }
        }

        // 解析位置1可用招式（双打）
        if (json.containsKey("slot1Moves")) {
            JSONArray movesArray = json.getJSONArray("slot1Moves");
            for (int i = 0; i < movesArray.size(); i++) {
                context.slot1Moves.add(MoveInfo.fromJson(movesArray.getJSONObject(i)));
            }
        }

        // 解析位置2可用招式（双打）
        if (json.containsKey("slot2Moves")) {
            JSONArray movesArray = json.getJSONArray("slot2Moves");
            for (int i = 0; i < movesArray.size(); i++) {
                context.slot2Moves.add(MoveInfo.fromJson(movesArray.getJSONObject(i)));
            }
        }

        // 解析可用替换
        if (json.containsKey("availableSwitches")) {
            JSONArray switchesArray = json.getJSONArray("availableSwitches");
            for (int i = 0; i < switchesArray.size(); i++) {
                context.availableSwitches.add(switchesArray.getInteger(i));
            }
        }

        return context;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("turn", turn);
        json.put("forceSwitch", forceSwitch);
        json.put("teamPreview", teamPreview);
        if (battleFormat != null) {
            json.put("battleFormat", battleFormat.getCode());
        }

        // 队伍
        JSONArray myPartyArray = new JSONArray();
        for (PokemonState p : myParty) {
            myPartyArray.add(p.toJson());
        }
        json.put("myParty", myPartyArray);

        JSONArray enemyPartyArray = new JSONArray();
        for (PokemonState p : enemyParty) {
            enemyPartyArray.add(p.toJson());
        }
        json.put("enemyParty", enemyPartyArray);

        // 场上
        JSONArray myActiveArray = new JSONArray();
        for (PokemonState p : myActive) {
            myActiveArray.add(p.toJson());
        }
        json.put("myActive", myActiveArray);

        JSONArray enemyActiveArray = new JSONArray();
        for (PokemonState p : enemyActive) {
            enemyActiveArray.add(p.toJson());
        }
        json.put("enemyActive", enemyActiveArray);

        // 场地
        if (field != null) {
            json.put("field", field.toJson());
        }

        // 可用招式
        JSONArray movesArray = new JSONArray();
        for (MoveInfo m : availableMoves) {
            movesArray.add(m.toJson());
        }
        json.put("availableMoves", movesArray);

        // 位置1可用招式
        JSONArray slot1MovesArray = new JSONArray();
        for (MoveInfo m : slot1Moves) {
            slot1MovesArray.add(m.toJson());
        }
        json.put("slot1Moves", slot1MovesArray);

        // 位置2可用招式
        JSONArray slot2MovesArray = new JSONArray();
        for (MoveInfo m : slot2Moves) {
            slot2MovesArray.add(m.toJson());
        }
        json.put("slot2Moves", slot2MovesArray);

        // 可用替换
        json.put("availableSwitches", availableSwitches);

        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 获取存活的场上宝可梦数量
     */
    public int getMyActiveCount() {
        int count = 0;
        for (PokemonState p : myActive) {
            if (p.isAlive()) count++;
        }
        return count;
    }

    /**
     * 获取敌方存活的场上宝可梦数量
     */
    public int getEnemyActiveCount() {
        int count = 0;
        for (PokemonState p : enemyActive) {
            if (p.isAlive()) count++;
        }
        return count;
    }

    /**
     * 获取可用的后备宝可梦数量
     */
    public int getAvailableSwitchCount() {
        return availableSwitches.size();
    }

    /**
     * 检查是否有可用的替换选项
     */
    public boolean hasAvailableSwitches() {
        return !availableSwitches.isEmpty();
    }

    /**
     * 获取指定位置的我方宝可梦
     */
    public PokemonState getMyPokemon(int slot) {
        for (PokemonState p : myParty) {
            if (p.getSlot() == slot) return p;
        }
        return null;
    }

    /**
     * 获取指定位置的敌方宝可梦
     */
    public PokemonState getEnemyPokemon(int slot) {
        for (PokemonState p : enemyParty) {
            if (p.getSlot() == slot) return p;
        }
        return null;
    }

    // ==================== 战斗模式相关 ====================

    /**
     * 检查是否是双打
     */
    public boolean isDoubles() {
        return battleFormat == BattleFormat.DOUBLES;
    }

    /**
     * 检查是否是单打
     */
    public boolean isSingles() {
        return battleFormat == BattleFormat.SINGLES;
    }

    /**
     * 获取战斗模式
     */
    public BattleFormat getBattleFormat() {
        return battleFormat;
    }

    /**
     * 设置战斗模式
     */
    public void setBattleFormat(BattleFormat battleFormat) {
        this.battleFormat = battleFormat;
    }

    /**
     * 获取指定位置的可用招式
     * @param slot 位置 (1 或 2)
     * @return 该位置的可用招式列表
     */
    public List<MoveInfo> getAvailableMovesForSlot(int slot) {
        if (isDoubles()) {
            return slot == 1 ? slot1Moves : slot2Moves;
        }
        return availableMoves;
    }

    /**
     * 获取位置1的可用招式（双打）
     */
    public List<MoveInfo> getSlot1Moves() {
        return slot1Moves;
    }

    /**
     * 设置位置1的可用招式（双打）
     */
    public void setSlot1Moves(List<MoveInfo> slot1Moves) {
        this.slot1Moves = slot1Moves;
    }

    /**
     * 获取位置2的可用招式（双打）
     */
    public List<MoveInfo> getSlot2Moves() {
        return slot2Moves;
    }

    /**
     * 设置位置2的可用招式（双打）
     */
    public void setSlot2Moves(List<MoveInfo> slot2Moves) {
        this.slot2Moves = slot2Moves;
    }

    /**
     * 获取需要决策的数量（双打为2，单打为1）
     */
    public int getDecisionCount() {
        // 双打时，需要根据存活宝可梦数量决定
        if (isDoubles()) {
            return getMyActiveCount();
        }
        return 1;
    }

    // ==================== Getter/Setter ====================

    public int getTurn() {
        return turn;
    }

    public void setTurn(int turn) {
        this.turn = turn;
    }

    public List<PokemonState> getMyParty() {
        return myParty;
    }

    public void setMyParty(List<PokemonState> myParty) {
        this.myParty = myParty;
    }

    public List<PokemonState> getEnemyParty() {
        return enemyParty;
    }

    public void setEnemyParty(List<PokemonState> enemyParty) {
        this.enemyParty = enemyParty;
    }

    public List<PokemonState> getMyActive() {
        return myActive;
    }

    public void setMyActive(List<PokemonState> myActive) {
        this.myActive = myActive;
    }

    public List<PokemonState> getEnemyActive() {
        return enemyActive;
    }

    public void setEnemyActive(List<PokemonState> enemyActive) {
        this.enemyActive = enemyActive;
    }

    public FieldState getField() {
        return field;
    }

    public void setField(FieldState field) {
        this.field = field;
    }

    public List<MoveInfo> getAvailableMoves() {
        return availableMoves;
    }

    public void setAvailableMoves(List<MoveInfo> availableMoves) {
        this.availableMoves = availableMoves;
    }

    public List<Integer> getAvailableSwitches() {
        return availableSwitches;
    }

    public void setAvailableSwitches(List<Integer> availableSwitches) {
        this.availableSwitches = availableSwitches;
    }

    public boolean isForceSwitch() {
        return forceSwitch;
    }

    public void setForceSwitch(boolean forceSwitch) {
        this.forceSwitch = forceSwitch;
    }

    public boolean isTeamPreview() {
        return teamPreview;
    }

    public void setTeamPreview(boolean teamPreview) {
        this.teamPreview = teamPreview;
    }

    @Override
    public String toString() {
        return String.format("BattleContext{format=%s, turn=%d, myActive=%d, enemyActive=%d, forceSwitch=%s, teamPreview=%s}",
                battleFormat, turn, getMyActiveCount(), getEnemyActiveCount(), forceSwitch, teamPreview);
    }
}
