package com.xiaobaozi.ai_play_pokemon.emulator.dto;

import com.alibaba.fastjson.JSONObject;

/**
 * 模拟器状态（存档快照）
 */
public class EmulatorState {

    /**
     * 存档文件名
     */
    private String filename;

    /**
     * 状态数据（Base64 编码）
     */
    private String stateData;

    /**
     * 帧数
     */
    private int frameCount;

    /**
     * 时间戳
     */
    private long timestamp;

    // ==================== 构造函数 ====================

    public EmulatorState() {
        this.timestamp = System.currentTimeMillis();
    }

    public EmulatorState(String filename, String stateData, int frameCount) {
        this.filename = filename;
        this.stateData = stateData;
        this.frameCount = frameCount;
        this.timestamp = System.currentTimeMillis();
    }

    // ==================== JSON 解析 ====================

    public static EmulatorState fromJson(JSONObject json) {
        if (json == null) return null;

        EmulatorState state = new EmulatorState();
        state.filename = json.getString("filename");
        state.stateData = json.getString("stateData");
        state.frameCount = json.getIntValue("frameCount");
        state.timestamp = json.getLongValue("timestamp");

        return state;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        json.put("filename", filename);
        json.put("stateData", stateData);
        json.put("frameCount", frameCount);
        json.put("timestamp", timestamp);
        return json;
    }

    // ==================== Getter/Setter ====================

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getStateData() {
        return stateData;
    }

    public void setStateData(String stateData) {
        this.stateData = stateData;
    }

    public int getFrameCount() {
        return frameCount;
    }

    public void setFrameCount(int frameCount) {
        this.frameCount = frameCount;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return String.format("EmulatorState{filename='%s', frameCount=%d, timestamp=%d}",
                filename, frameCount, timestamp);
    }
}
