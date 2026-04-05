package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 宝可梦状态
 */
public class PokemonState {

    /**
     * 位置 (1-6)
     */
    private int slot;

    /**
     * 种类
     */
    private String species;

    /**
     * 昵称
     */
    private String nickname;

    /**
     * 等级
     */
    private int level;

    /**
     * 当前 HP
     */
    private int currentHp;

    /**
     * 最大 HP
     */
    private int maxHp;

    /**
     * 招式列表
     */
    private List<MoveInfo> moves;

    /**
     * 状态异常
     * none/par/psn/brn/frz/slp/tox
     */
    private String status;

    /**
     * 能力变化
     * atk/def/spa/spd/spe/acc/eva (-6 ~ +6)
     */
    private Map<String, Integer> boosts;

    /**
     * 是否在场
     */
    private boolean active;

    /**
     * 是否濒死
     */
    private boolean fainted;

    /**
     * 是否是蛋
     */
    private boolean egg;

    /**
     * 携带道具（如果可见）
     */
    private String item;

    /**
     * 特性（如果可见）
     */
    private String ability;

    // ==================== 构造函数 ====================

    public PokemonState() {
        this.moves = new ArrayList<>();
        this.boosts = new HashMap<>();
        this.status = "none";
    }

    // ==================== JSON 解析 ====================

    public static PokemonState fromJson(JSONObject json) {
        if (json == null) return null;

        PokemonState pokemon = new PokemonState();
        pokemon.slot = json.getIntValue("slot");
        pokemon.species = json.getString("species");
        pokemon.nickname = json.getString("nickname");
        pokemon.level = json.getIntValue("level");
        pokemon.currentHp = json.getIntValue("currentHp");
        pokemon.maxHp = json.getIntValue("maxHp");
        pokemon.status = json.getString("status");
        pokemon.active = json.getBooleanValue("active");
        pokemon.fainted = json.getBooleanValue("fainted");
        pokemon.item = json.getString("item");
        pokemon.ability = json.getString("ability");

        // 解析招式列表
        if (json.containsKey("moves")) {
            List<JSONObject> movesJson = json.getJSONArray("moves").toJavaList(JSONObject.class);
            for (JSONObject moveJson : movesJson) {
                pokemon.moves.add(MoveInfo.fromJson(moveJson));
            }
        }

        // 解析能力变化
        if (json.containsKey("boosts")) {
            JSONObject boostsJson = json.getJSONObject("boosts");
            for (String key : boostsJson.keySet()) {
                pokemon.boosts.put(key, boostsJson.getIntValue(key));
            }
        }

        return pokemon;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("slot", slot);
        json.put("species", species);
        json.put("nickname", nickname);
        json.put("level", level);
        json.put("currentHp", currentHp);
        json.put("maxHp", maxHp);
        json.put("status", status);
        json.put("active", active);
        json.put("fainted", fainted);
        json.put("item", item);
        json.put("ability", ability);

        // 招式列表
        List<JSONObject> movesJson = new ArrayList<>();
        for (MoveInfo move : moves) {
            movesJson.add(move.toJson());
        }
        json.put("moves", movesJson);

        // 能力变化
        json.put("boosts", boosts);

        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 检查是否存活
     */
    public boolean isAlive() {
        return !fainted && currentHp > 0;
    }

    /**
     * 获取 HP 百分比
     */
    public double getHpPercent() {
        if (maxHp <= 0) return 0;
        return (double) currentHp / maxHp * 100;
    }

    /**
     * 获取指定能力的等级变化
     */
    public int getBoost(String stat) {
        return boosts.getOrDefault(stat, 0);
    }

    /**
     * 获取可用招式列表
     */
    public List<MoveInfo> getUsableMoves() {
        List<MoveInfo> usable = new ArrayList<>();
        for (MoveInfo move : moves) {
            if (move.isUsable()) {
                usable.add(move);
            }
        }
        return usable;
    }

    // ==================== Getter/Setter ====================

    public int getSlot() {
        return slot;
    }

    public void setSlot(int slot) {
        this.slot = slot;
    }

    public String getSpecies() {
        return species;
    }

    public void setSpecies(String species) {
        this.species = species;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public int getLevel() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public int getCurrentHp() {
        return currentHp;
    }

    public void setCurrentHp(int currentHp) {
        this.currentHp = currentHp;
    }

    public int getMaxHp() {
        return maxHp;
    }

    public void setMaxHp(int maxHp) {
        this.maxHp = maxHp;
    }

    public List<MoveInfo> getMoves() {
        return moves;
    }

    public void setMoves(List<MoveInfo> moves) {
        this.moves = moves;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Map<String, Integer> getBoosts() {
        return boosts;
    }

    public void setBoosts(Map<String, Integer> boosts) {
        this.boosts = boosts;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public boolean isFainted() {
        return fainted;
    }

    public void setFainted(boolean fainted) {
        this.fainted = fainted;
    }

    public boolean isEgg() {
        return egg;
    }

    public void setEgg(boolean egg) {
        this.egg = egg;
    }

    public String getItem() {
        return item;
    }

    public void setItem(String item) {
        this.item = item;
    }

    public String getAbility() {
        return ability;
    }

    public void setAbility(String ability) {
        this.ability = ability;
    }

    @Override
    public String toString() {
        return String.format("PokemonState{slot=%d, species='%s', Lv.%d, HP=%d/%d, status='%s', active=%s, fainted=%s}",
                slot, species, level, currentHp, maxHp, status, active, fainted);
    }
}
