package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONObject;

/**
 * 场地状态
 */
public class FieldState {

    /**
     * 天气
     * none/rain/sun/sandstorm/hail
     */
    private String weather;

    /**
     * 地形
     * none/electric/grassy/psychic/misty
     */
    private String terrain;

    /**
     * 天气剩余回合
     */
    private int weatherTurns;

    /**
     * 地形剩余回合
     */
    private int terrainTurns;

    // ==================== 构造函数 ====================

    public FieldState() {
        this.weather = "none";
        this.terrain = "none";
    }

    // ==================== JSON 解析 ====================

    public static FieldState fromJson(JSONObject json) {
        if (json == null) return null;

        FieldState field = new FieldState();
        field.weather = json.getString("weather");
        field.terrain = json.getString("terrain");
        field.weatherTurns = json.getIntValue("weatherTurns");
        field.terrainTurns = json.getIntValue("terrainTurns");

        return field;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("weather", weather);
        json.put("terrain", terrain);
        json.put("weatherTurns", weatherTurns);
        json.put("terrainTurns", terrainTurns);
        return json;
    }

    // ==================== 工具方法 ====================

    /**
     * 检查是否有天气
     */
    public boolean hasWeather() {
        return weather != null && !"none".equals(weather);
    }

    /**
     * 检查是否有地形
     */
    public boolean hasTerrain() {
        return terrain != null && !"none".equals(terrain);
    }

    // ==================== Getter/Setter ====================

    public String getWeather() {
        return weather;
    }

    public void setWeather(String weather) {
        this.weather = weather;
    }

    public String getTerrain() {
        return terrain;
    }

    public void setTerrain(String terrain) {
        this.terrain = terrain;
    }

    public int getWeatherTurns() {
        return weatherTurns;
    }

    public void setWeatherTurns(int weatherTurns) {
        this.weatherTurns = weatherTurns;
    }

    public int getTerrainTurns() {
        return terrainTurns;
    }

    public void setTerrainTurns(int terrainTurns) {
        this.terrainTurns = terrainTurns;
    }

    @Override
    public String toString() {
        return String.format("FieldState{weather='%s'(%d), terrain='%s'(%d)}",
                weather, weatherTurns, terrain, terrainTurns);
    }
}
