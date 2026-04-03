package com.xiaobaozi.ai_play_pokemon.emulator;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.*;
import com.xiaobaozi.ai_play_pokemon.emulator.exception.EmulatorException;
import com.xiaobaozi.ai_play_pokemon.utils.HttpClientUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

/**
 * 战斗模拟器封装类
 *
 * 通过 HTTP 与 Lua 服务器通信，控制 GBA 模拟器进行宝可梦战斗
 * 支持宝可梦绿宝石，支持单打/双打
 */
public class BattleEmulator {

    private static final Logger log = LoggerFactory.getLogger(BattleEmulator.class);

    private final EmulatorConfig config;

    // 当前战斗模式（缓存）
    private BattleFormat currentFormat;

    // ==================== 构造函数 ====================

    public BattleEmulator() {
        this.config = new EmulatorConfig();
    }

    public BattleEmulator(EmulatorConfig config) {
        this.config = config;
    }

    public BattleEmulator(String serverUrl) {
        this.config = EmulatorConfig.builder().serverUrl(serverUrl).build();
    }

    // ==================== 战斗模式检测 ====================

    /**
     * 检查当前战斗是单打还是双打
     *
     * @return 战斗模式
     */
    public BattleFormat getBattleFormat() {
        if (currentFormat != null) {
            return currentFormat;
        }

        try {
            BattleContext context = getBattleContext();
            if (context != null) {
                // 从上下文中获取或根据场上数量判断
                if (context.getBattleFormat() != null) {
                    currentFormat = context.getBattleFormat();
                } else {
                    currentFormat = BattleFormat.fromActiveCount(context.getMyActiveCount());
                }
            }
        } catch (Exception e) {
            log.warn("[BattleEmulator] 获取战斗模式失败: {}", e.getMessage());
        }

        return currentFormat != null ? currentFormat : BattleFormat.SINGLES;
    }

    /**
     * 检查是否是双打
     */
    public boolean isDoubles() {
        return getBattleFormat() == BattleFormat.DOUBLES;
    }

    /**
     * 检查是否是单打
     */
    public boolean isSingles() {
        return getBattleFormat() == BattleFormat.SINGLES;
    }

    /**
     * 清除缓存的战斗模式（战斗结束后调用）
     */
    public void clearBattleFormat() {
        this.currentFormat = null;
    }

    // ==================== 存档管理 ====================

    /**
     * 读取游戏存档
     *
     * @param filename 存档文件名（如 "battle_save.sav"）
     * @return 模拟器状态
     */
    public EmulatorState loadState(String filename) {
        log.info("[BattleEmulator] 加载存档: {}", filename);
        clearBattleFormat(); // 清除缓存的战斗模式

        try {
            JSONObject request = new JSONObject();
            request.put("filename", filename);

            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/loadstate",
                    request.toJSONString()
            );

            JSONObject json = JSON.parseObject(response);
            if (json.getBooleanValue("success")) {
                return EmulatorState.fromJson(json.getJSONObject("state"));
            } else {
                throw EmulatorException.saveError(json.getString("error"));
            }

        } catch (EmulatorException e) {
            throw e;
        } catch (Exception e) {
            throw EmulatorException.connectionFailed("加载存档失败: " + e.getMessage());
        }
    }

    /**
     * 保存当前游戏状态
     *
     * @param filename 存档文件名（可选）
     * @return 当前状态快照
     */
    public EmulatorState saveState(String filename) {
        log.info("[BattleEmulator] 保存状态: {}", filename);

        try {
            String url = config.getServerUrl() + "/savestate";
            if (filename != null && !filename.isEmpty()) {
                url += "?filename=" + filename;
            }

            String response = HttpClientUtil.sendGetRequest(url);
            JSONObject json = JSON.parseObject(response);

            if (json.getBooleanValue("success")) {
                return EmulatorState.fromJson(json.getJSONObject("state"));
            } else {
                throw EmulatorException.saveError(json.getString("error"));
            }

        } catch (EmulatorException e) {
            throw e;
        } catch (Exception e) {
            throw EmulatorException.connectionFailed("保存状态失败: " + e.getMessage());
        }
    }

    // ==================== 游戏控制 ====================

    /**
     * 运行游戏直到下一个决策点或战斗结束
     *
     * @return 操作结果，包含到达的决策点信息
     */
    public ActionResult runUntilNextDecision() {
        log.info("[BattleEmulator] 运行到下一个决策点...");

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/run"
            );

            JSONObject json = JSON.parseObject(response);
            ActionResult result = ActionResult.fromJson(json);

            // 更新战斗模式
            if (result.getContext() != null && result.getContext().getBattleFormat() != null) {
                currentFormat = result.getContext().getBattleFormat();
            }

            return result;

        } catch (Exception e) {
            throw EmulatorException.actionFailed("运行到下一个决策点失败: " + e.getMessage());
        }
    }

    // ==================== 单打操作 ====================

    /**
     * 执行招式（单打）
     *
     * @param slot   招式槽位 (1-4)
     * @param target 目标位置，可为 null
     */
    public ActionResult useMove(int slot, Integer target) {
        log.info("[BattleEmulator] 执行招式: slot={}, target={}", slot, target);
        GameAction action = GameAction.move(slot, target);
        return executeAction(action);
    }

    /**
     * 执行替换（单打）
     *
     * @param position 后备位置 (1-6)
     */
    public ActionResult switchPokemon(int position) {
        log.info("[BattleEmulator] 执行替换: position={}", position);
        GameAction action = GameAction.switchAction(position);
        return executeAction(action);
    }

    /**
     * 执行濒死替换（单打）
     *
     * @param position 后备位置 (1-6)
     */
    public ActionResult forceSwitch(int position) {
        log.info("[BattleEmulator] 执行濒死替换: position={}", position);
        GameAction action = GameAction.forceSwitch(position);
        return executeAction(action);
    }

    // ==================== 双打操作 ====================

    /**
     * 执行双打招式（两个位置同时决策）
     *
     * @param slot1Move   位置1招式槽位 (1-4)
     * @param slot1Target 位置1目标（可为 null）
     * @param slot2Move   位置2招式槽位 (1-4)
     * @param slot2Target 位置2目标（可为 null）
     * @return 操作结果
     */
    public ActionResult useMoveDouble(int slot1Move, Integer slot1Target,
                                       int slot2Move, Integer slot2Target) {
        log.info("[BattleEmulator] 双打招式: 位置1=move{} target{}, 位置2=move{} target{}",
                slot1Move, slot1Target, slot2Move, slot2Target);

        List<GameAction> actions = new ArrayList<>();
        actions.add(GameAction.move(slot1Move, slot1Target));
        actions.add(GameAction.move(slot2Move, slot2Target));

        return executeActions(actions);
    }

    /**
     * 执行双打替换（两个位置同时决策）
     *
     * @param position1 位置1替换位置 (1-6)，null 表示不替换
     * @param position2 位置2替换位置 (1-6)，null 表示不替换
     * @return 操作结果
     */
    public ActionResult switchDouble(Integer position1, Integer position2) {
        log.info("[BattleEmulator] 双打替换: 位置1={}, 位置2={}", position1, position2);

        List<GameAction> actions = new ArrayList<>();
        if (position1 != null) {
            actions.add(GameAction.switchAction(position1));
        }
        if (position2 != null) {
            actions.add(GameAction.switchAction(position2));
        }

        return executeActions(actions);
    }

    /**
     * 执行双打濒死替换
     *
     * @param position 后备位置 (1-6)
     * @return 操作结果
     */
    public ActionResult forceSwitchDouble(int position) {
        log.info("[BattleEmulator] 双打濒死替换: position={}", position);
        GameAction action = GameAction.forceSwitch(position);
        return executeAction(action);
    }

    /**
     * 双打混合决策（一个招式一个替换）
     *
     * @param moveSlot   招式槽位
     * @param moveTarget 招式目标
     * @param switchPos  替换位置
     * @return 操作结果
     */
    public ActionResult mixedActionDouble(int moveSlot, Integer moveTarget, int switchPos) {
        log.info("[BattleEmulator] 双打混合: move{} target{}, switch{}",
                moveSlot, moveTarget, switchPos);

        List<GameAction> actions = new ArrayList<>();
        actions.add(GameAction.move(moveSlot, moveTarget));
        actions.add(GameAction.switchAction(switchPos));

        return executeActions(actions);
    }

    // ==================== 通用操作方法 ====================

    /**
     * 执行单个游戏操作
     */
    public ActionResult executeAction(GameAction action) {
        log.info("[BattleEmulator] 执行操作: {}", action);

        try {
            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/action",
                    action.toJson().toJSONString()
            );

            JSONObject json = JSON.parseObject(response);
            return ActionResult.fromJson(json);

        } catch (Exception e) {
            throw EmulatorException.actionFailed("执行操作失败: " + e.getMessage());
        }
    }

    /**
     * 执行多个游戏操作（双打时使用）
     */
    public ActionResult executeActions(List<GameAction> actions) {
        log.info("[BattleEmulator] 执行多操作: {} 个", actions.size());

        try {
            JSONArray actionsArray = new JSONArray();
            for (GameAction action : actions) {
                actionsArray.add(action.toJson());
            }

            JSONObject request = new JSONObject();
            request.put("actions", actionsArray);

            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/action",
                    request.toJSONString()
            );

            JSONObject json = JSON.parseObject(response);
            return ActionResult.fromJson(json);

        } catch (Exception e) {
            throw EmulatorException.actionFailed("执行多操作失败: " + e.getMessage());
        }
    }

    // ==================== AI 决策 ====================

    /**
     * 获取 CPU AI 的决策建议
     */
    public GameAction aiThink() {
        log.info("[BattleEmulator] 获取 AI 决策...");

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/ai-think"
            );

            JSONObject json = JSON.parseObject(response);
            if (json.containsKey("action")) {
                return GameAction.fromJson(json.getJSONObject("action"));
            }

            return null;

        } catch (Exception e) {
            log.error("[BattleEmulator] 获取 AI 决策失败: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 获取双打 AI 决策（返回两个操作）
     */
    public List<GameAction> aiThinkDouble() {
        log.info("[BattleEmulator] 获取双打 AI 决策...");

        List<GameAction> actions = new ArrayList<>();

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/ai-think?format=doubles"
            );

            JSONObject json = JSON.parseObject(response);
            if (json.containsKey("actions")) {
                JSONArray actionsArray = json.getJSONArray("actions");
                for (int i = 0; i < actionsArray.size(); i++) {
                    actions.add(GameAction.fromJson(actionsArray.getJSONObject(i)));
                }
            }

        } catch (Exception e) {
            log.error("[BattleEmulator] 获取双打 AI 决策失败: {}", e.getMessage());
        }

        return actions;
    }

    // ==================== 状态获取 ====================

    /**
     * 获取当前战斗上下文
     */
    public BattleContext getBattleContext() {
        log.debug("[BattleEmulator] 获取战斗上下文...");

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/context"
            );

            JSONObject json = JSON.parseObject(response);
            BattleContext context = BattleContext.fromJson(json);

            // 更新缓存的战斗模式
            if (context != null && context.getBattleFormat() != null) {
                currentFormat = context.getBattleFormat();
            }

            return context;

        } catch (Exception e) {
            throw EmulatorException.parseError("获取战斗上下文失败: " + e.getMessage());
        }
    }

    /**
     * 获取战报信息
     */
    public String getBattleLog() {
        log.debug("[BattleEmulator] 获取战报...");

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/battle-log"
            );

            JSONObject json = JSON.parseObject(response);
            return json.getString("log");

        } catch (Exception e) {
            log.error("[BattleEmulator] 获取战报失败: {}", e.getMessage());
            return "";
        }
    }

    // ==================== 状态检查 ====================

    /**
     * 检查是否在战斗中
     */
    public boolean isInBattle() {
        try {
            JSONObject status = getStatus();
            return status.getBooleanValue("inBattle");
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 检查战斗是否结束
     */
    public boolean isBattleEnded() {
        try {
            JSONObject status = getStatus();
            return status.getBooleanValue("battleEnded");
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 检查是否需要濒死替换
     */
    public boolean needsForceSwitch() {
        try {
            BattleContext context = getBattleContext();
            return context != null && context.isForceSwitch();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 获取模拟器状态
     */
    private JSONObject getStatus() {
        String response = HttpClientUtil.sendGetRequest(
                config.getServerUrl() + "/status"
        );
        return JSON.parseObject(response);
    }

    // ==================== 截图 ====================

    /**
     * 获取当前画面截图
     */
    public byte[] screenshot() {
        log.info("[BattleEmulator] 获取截图...");

        try {
            return HttpClientUtil.sendGetRequestBytes(
                    config.getServerUrl() + "/screenshot"
            );
        } catch (Exception e) {
            log.error("[BattleEmulator] 获取截图失败: {}", e.getMessage());
            return new byte[0];
        }
    }

    // ==================== 工具方法 ====================

    /**
     * 获取配置
     */
    public EmulatorConfig getConfig() {
        return config;
    }

    /**
     * 检查服务器连接
     */
    public boolean checkConnection() {
        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/status"
            );
            return response != null && !response.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
}
