package com.xiaobaozi.ai_play_pokemon.emulator;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.*;
import com.xiaobaozi.ai_play_pokemon.emulator.exception.EmulatorException;
import com.xiaobaozi.ai_play_pokemon.service.GameDataLookupService;
import com.xiaobaozi.ai_play_pokemon.utils.HttpClientUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

    // 游戏数据查询服务（可选）
    private GameDataLookupService lookupService;

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

    /**
     * 设置游戏数据查询服务
     */
    public void setLookupService(GameDataLookupService lookupService) {
        this.lookupService = lookupService;
    }

    /**
     * 获取 species 名称
     */
    private String getSpeciesName(int speciesId) {
        if (lookupService != null) {
            return lookupService.getSpeciesName(speciesId);
        }
        return String.valueOf(speciesId);
    }

    /**
     * 获取 move 名称
     */
    private String getMoveName(int moveId) {
        if (lookupService != null) {
            return lookupService.getMoveName(moveId);
        }
        return String.valueOf(moveId);
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
     * Lua API: GET /loadstate?name=xxx
     *
     * @param filename 存档文件名（如 "battle_sav"，不带 .State 扩展名）
     * @return 模拟器状态
     */
    public EmulatorState loadState(String filename) {
        log.info("[BattleEmulator] 加载存档: {}", filename);
        clearBattleFormat(); // 清除缓存的战斗模式

        try {
            // Lua API 使用 GET 请求 + query 参数
            String url = config.getServerUrl() + "/loadstate?name=" + filename;
            String response = HttpClientUtil.sendGetRequest(url);

            JSONObject json = JSON.parseObject(response);
            if (json.getBooleanValue("success")) {
                log.info("[BattleEmulator] 存档加载成功: {}", filename);

                // 等待游戏初始化（存档加载后需要几帧才能读取正确的战斗状态）
                try {
                    Thread.sleep(500); // 等待 500ms
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }

                return new EmulatorState(); // 简化返回
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
     * 获取当前战斗阶段
     * Lua API: GET /phase
     */
    public BattlePhase getBattlePhase() {
        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/phase"
            );
            JSONObject json = JSON.parseObject(response);
            int phaseValue = json.getIntValue("phase");
            return BattlePhase.fromValue(phaseValue);
        } catch (Exception e) {
            log.error("[BattleEmulator] 获取战斗阶段失败: {}", e.getMessage());
            return BattlePhase.NONE;
        }
    }

    /**
     * 运行游戏直到下一个决策点或战斗结束
     * 通过轮询 /phase 端点实现
     *
     * @return 操作结果，包含到达的决策点信息
     */
    public ActionResult runUntilNextDecision() {
        log.info("[BattleEmulator] 等待下一个决策点...");

        try {
            // 轮询等待 phase 变为需要决策的状态
            BattlePhase phase;
            int maxWaitCount = 100; // 最多等待 100 次 × 50ms = 5 秒
            int waitCount = 0;

            while (waitCount < maxWaitCount) {
                phase = getBattlePhase();

                // 需要决策
                if (phase.needsDecision()) {
                    log.info("[BattleEmulator] 到达决策点: {}", phase);
                    return buildActionResultFromPhase(phase);
                }

                // 战斗结束
                if (phase.isBattleEnded()) {
                    log.info("[BattleEmulator] 战斗结束");
                    ActionResult result = ActionResult.battleEnded("unknown");
                    result.setBattleEnded(true);
                    return result;
                }

                // 等待后继续轮询
                Thread.sleep(50); // 50ms
                waitCount++;
            }

            // 超时
            log.warn("[BattleEmulator] 等待决策点超时");
            ActionResult result = new ActionResult();
            result.setSuccess(false);
            result.setDecisionPoint(DecisionPoint.BATTLE_ENDED);
            return result;

        } catch (Exception e) {
            throw EmulatorException.actionFailed("等待决策点失败: " + e.getMessage());
        }
    }

    /**
     * 根据战斗阶段构建 ActionResult
     */
    private ActionResult buildActionResultFromPhase(BattlePhase phase) {
        ActionResult result = new ActionResult();
        result.setSuccess(true);
        result.setDecisionPoint(phase.toDecisionPoint());

        // 获取战斗上下文
        BattleContext context = getBattleContext();
        result.setContext(context);

        // 获取清洗后的战报
        String log = getCleanedBattleLog();
        result.setBattleLog(log);

        return result;
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
     * 启用行动劫持模式
     * Lua API: POST /action/enable
     * 必须在调用 /action/move 或 /action/switch 之前调用
     */
    public boolean enableActionHijack() {
        log.debug("[BattleEmulator] 启用行动劫持模式...");

        try {
            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/action/enable",
                    "{}"
            );
            JSONObject json = JSON.parseObject(response);
            boolean success = json.getBooleanValue("success");
            if (success) {
                log.debug("[BattleEmulator] 行动劫持模式已启用");
            }
            return success;
        } catch (Exception e) {
            log.error("[BattleEmulator] 启用行动劫持失败: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 执行单个游戏操作
     * Lua API: POST /action/move 或 /action/switch
     */
    public ActionResult executeAction(GameAction action) {
        log.info("[BattleEmulator] 执行操作: {}", action);

        try {
            // 1. 先启用行动劫持模式
            enableActionHijack();

            // 2. 根据操作类型调用不同的端点
            boolean success = false;
            if (action.getType() == ActionType.MOVE) {
                // 注意：Lua API 使用 0-based 索引，Java 使用 1-based
                success = injectMove(action.getSlot() - 1, action.getTarget());
            } else if (action.getType() == ActionType.SWITCH || action.getType() == ActionType.FORCE_SWITCH) {
                // 注意：Lua API 使用 0-based 索引，Java 使用 1-based
                success = injectSwitch(action.getSlot() - 1);
            }

            // 3. 等待招式执行完成
            if (success) {
                waitForExecution();
            }

            // 4. 构建结果
            ActionResult result = new ActionResult();
            result.setSuccess(success);

            // 检查战斗是否结束
            BattlePhase phase = getBattlePhase();
            if (phase.isBattleEnded()) {
                result.setBattleEnded(true);
                result.setDecisionPoint(DecisionPoint.BATTLE_ENDED);
            } else {
                result.setDecisionPoint(phase.toDecisionPoint());
                result.setContext(getBattleContext());
            }

            return result;

        } catch (Exception e) {
            throw EmulatorException.actionFailed("执行操作失败: " + e.getMessage());
        }
    }

    /**
     * 注入招式行动
     * Lua API: POST /action/move (JSON: {move, target})
     */
    private boolean injectMove(int moveIndex, Integer target) {
        try {
            JSONObject request = new JSONObject();
            request.put("move", moveIndex);
            if (target != null) {
                request.put("target", target);
            } else {
                request.put("target", 1); // 默认目标敌方
            }

            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/action/move",
                    request.toJSONString()
            );

            JSONObject json = JSON.parseObject(response);
            return json.getBooleanValue("success");

        } catch (Exception e) {
            log.error("[BattleEmulator] 注入招式失败: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 注入切换行动
     * Lua API: POST /action/switch (JSON: {slot})
     */
    private boolean injectSwitch(int slot) {
        try {
            JSONObject request = new JSONObject();
            request.put("slot", slot);

            String response = HttpClientUtil.postJson(
                    config.getServerUrl() + "/action/switch",
                    request.toJSONString()
            );

            JSONObject json = JSON.parseObject(response);
            return json.getBooleanValue("success");

        } catch (Exception e) {
            log.error("[BattleEmulator] 注入切换失败: {}", e.getMessage());
            return false;
        }
    }

    /**
     * 等待招式执行完成
     */
    private void waitForExecution() {
        try {
            // 等待 phase 从 ACTION_SELECT 变为 MOVE_EXECUTION
            int maxWaitCount = 100; // 5 秒
            int waitCount = 0;
            while (waitCount < maxWaitCount) {
                BattlePhase phase = getBattlePhase();
                if (phase == BattlePhase.MOVE_EXECUTION ||
                    phase == BattlePhase.ACTION_SELECT ||
                    phase == BattlePhase.FAINT_SWITCH ||
                    phase.isBattleEnded()) {
                    break;
                }
                Thread.sleep(50);
                waitCount++;
            }

            // 等待 phase 回到 ACTION_SELECT 或其他决策点
            waitCount = 0;
            while (waitCount < maxWaitCount) {
                BattlePhase phase = getBattlePhase();
                if (phase.needsDecision() || phase.isBattleEnded()) {
                    break;
                }
                Thread.sleep(50);
                waitCount++;
            }

        } catch (Exception e) {
            log.warn("[BattleEmulator] 等待执行完成时出错: {}", e.getMessage());
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
     * 聚合 /phase、/battle、/party、/enemy 四个端点的数据
     */
    public BattleContext getBattleContext() {
        log.debug("[BattleEmulator] 获取战斗上下文...");

        try {
            BattleContext context = new BattleContext();

            // 1. 获取战斗阶段和基本信息
            String phaseResponse = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/phase"
            );
            JSONObject phaseJson = JSON.parseObject(phaseResponse);
            boolean isDouble = phaseJson.getBooleanValue("isDouble");
            boolean inBattle = phaseJson.getBooleanValue("inBattle");

            if (!inBattle) {
                return context;
            }

            context.setBattleFormat(isDouble ? BattleFormat.DOUBLES : BattleFormat.SINGLES);

            // 2. 获取场上宝可梦信息
            String battleResponse = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/battle"
            );
            JSONObject battleJson = JSON.parseObject(battleResponse);
            parseBattleInfo(context, battleJson);

            // 3. 获取玩家队伍
            String partyResponse = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/party"
            );
            JSONObject partyJson = JSON.parseObject(partyResponse);
            parsePartyInfo(context, partyJson, true);

            // 4. 获取敌方队伍
            String enemyResponse = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/enemy"
            );
            JSONObject enemyJson = JSON.parseObject(enemyResponse);
            parsePartyInfo(context, enemyJson, false);

            // 设置可用招式（从场上第一只宝可梦获取）
            if (!context.getMyActive().isEmpty()) {
                PokemonState active = context.getMyActive().get(0);
                context.setAvailableMoves(active.getMoves());
            }

            // 设置可用替换位置
            for (int i = 0; i < context.getMyParty().size(); i++) {
                PokemonState p = context.getMyParty().get(i);
                if (p != null && p.isAlive() && !isActive(context, i)) {
                    context.getAvailableSwitches().add(i + 1);
                }
            }

            // 更新缓存的战斗模式
            currentFormat = context.getBattleFormat();

            return context;

        } catch (Exception e) {
            throw EmulatorException.parseError("获取战斗上下文失败: " + e.getMessage());
        }
    }

    /**
     * 检查宝可梦是否在场
     */
    private boolean isActive(BattleContext context, int partyIndex) {
        for (PokemonState active : context.getMyActive()) {
            if (active != null && active.getSlot() == partyIndex + 1) {
                return true;
            }
        }
        return false;
    }

    /**
     * 解析 /battle 端点返回的数据
     */
    private void parseBattleInfo(BattleContext context, JSONObject battleJson) {
        JSONArray pokemonArray = battleJson.getJSONArray("pokemon");
        if (pokemonArray == null) return;

        for (int i = 0; i < pokemonArray.size(); i++) {
            JSONObject mon = pokemonArray.getJSONObject(i);
            int battlerIndex = mon.getIntValue("battlerIndex");
            int speciesId = mon.getIntValue("species");

            PokemonState pokemon = new PokemonState();
            pokemon.setSlot(battlerIndex + 1);
            pokemon.setSpecies(getSpeciesName(speciesId));
            pokemon.setLevel(mon.getIntValue("level"));
            pokemon.setCurrentHp(mon.getIntValue("hp"));
            pokemon.setMaxHp(mon.getIntValue("maxHp"));
            pokemon.setActive(true);
            pokemon.setFainted(mon.getIntValue("hp") == 0);

            // 解析招式
            JSONArray movesArray = mon.getJSONArray("moves");
            JSONArray ppArray = mon.getJSONArray("pp");
            if (movesArray != null) {
                for (int j = 0; j < movesArray.size() && j < 4; j++) {
                    int moveId = movesArray.getIntValue(j);
                    MoveInfo move = new MoveInfo();
                    move.setSlot(j + 1);
                    move.setName(getMoveName(moveId));
                    if (ppArray != null && j < ppArray.size()) {
                        move.setCurrentPp(ppArray.getIntValue(j));
                        move.setMaxPp(ppArray.getIntValue(j));
                    }
                    pokemon.getMoves().add(move);
                }
            }

            // 解析能力变化
            JSONObject boostsJson = mon.getJSONObject("boosts");
            if (boostsJson != null) {
                Map<String, Integer> boosts = new HashMap<>();
                for (String key : boostsJson.keySet()) {
                    boosts.put(key, boostsJson.getIntValue(key));
                }
                pokemon.setBoosts(boosts);
            }

            // battlerIndex: 0=玩家左, 1=敌方左, 2=玩家右, 3=敌方右
            if (battlerIndex == 0 || battlerIndex == 2) {
                context.getMyActive().add(pokemon);
            } else {
                context.getEnemyActive().add(pokemon);
            }
        }
    }

    /**
     * 解析 /party 或 /enemy 端点返回的数据
     */
    private void parsePartyInfo(BattleContext context, JSONObject partyJson, boolean isPlayer) {
        JSONArray partyArray = partyJson.getJSONArray("party");
        if (partyArray == null) return;

        List<PokemonState> party = isPlayer ? context.getMyParty() : context.getEnemyParty();

        for (int i = 0; i < partyArray.size(); i++) {
            JSONObject mon = partyArray.getJSONObject(i);
            int speciesId = mon.getIntValue("species");

            PokemonState pokemon = new PokemonState();
            pokemon.setSlot(i + 1);
            pokemon.setSpecies(getSpeciesName(speciesId));
            pokemon.setLevel(mon.getIntValue("level"));
            pokemon.setCurrentHp(mon.getIntValue("hp"));
            pokemon.setMaxHp(mon.getIntValue("maxHp"));
            pokemon.setFainted(mon.getIntValue("hp") == 0);
            pokemon.setEgg(mon.getIntValue("isEgg") == 1);

            // 解析招式
            JSONArray movesArray = mon.getJSONArray("moves");
            JSONArray ppArray = mon.getJSONArray("pp");
            if (movesArray != null) {
                for (int j = 0; j < movesArray.size() && j < 4; j++) {
                    int moveId = movesArray.getIntValue(j);
                    MoveInfo move = new MoveInfo();
                    move.setSlot(j + 1);
                    move.setName(getMoveName(moveId));
                    if (ppArray != null && j < ppArray.size()) {
                        move.setCurrentPp(ppArray.getIntValue(j));
                        move.setMaxPp(ppArray.getIntValue(j));
                    }
                    pokemon.getMoves().add(move);
                }
            }

            party.add(pokemon);
        }
    }

    /**
     * 获取战报信息
     * Lua API: GET /log
     */
    public String getBattleLog() {
        log.debug("[BattleEmulator] 获取战报...");

        try {
            String response = HttpClientUtil.sendGetRequest(
                    config.getServerUrl() + "/log"
            );

            // Lua 返回的是数组格式
            JSONArray logArray = JSON.parseArray(response);
            if (logArray != null && !logArray.isEmpty()) {
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < logArray.size(); i++) {
                    sb.append(logArray.getString(i)).append("\n");
                }
                return sb.toString();
            }
            return "";

        } catch (Exception e) {
            log.error("[BattleEmulator] 获取战报失败: {}", e.getMessage());
            return "";
        }
    }

    /**
     * 清空战报日志
     * Lua API: POST /log/clear
     */
    public void clearLog() {
        log.info("[BattleEmulator] 清空战报日志...");

        try {
            HttpClientUtil.postJson(config.getServerUrl() + "/log/clear", "{}");
            log.info("[BattleEmulator] 战报日志已清空");
        } catch (Exception e) {
            log.warn("[BattleEmulator] 清空战报日志失败: {}", e.getMessage());
        }
    }

    /**
     * 获取清洗后的战报
     * 1. 删除乱码字符串（含 Á, À, Î, ♂ 等特殊字符）
     * 2. 补全空格（如 "usedSTRENGTH!" -> "used STRENGTH!"）
     * 3. 过滤单行技能名、PP格式、TYPE/属性行
     */
    public String getCleanedBattleLog() {
        String rawLog = getBattleLog();
        if (rawLog == null || rawLog.isEmpty()) {
            return "";
        }
        return cleanBattleLog(rawLog);
    }

    /**
     * 清洗战报文本
     */
    public static String cleanBattleLog(String rawLog) {
        if (rawLog == null || rawLog.isEmpty()) {
            return "";
        }

        String[] lines = rawLog.split("\n");
        StringBuilder cleaned = new StringBuilder();

        for (String line : lines) {
            String trimmed = line.trim();

            // 跳过空行
            if (trimmed.isEmpty()) {
                continue;
            }

            // 1. 删除乱码字符串（含 Á, À, Î, ♂ 等特殊字符的行）
            if (containsGarbage(trimmed)) {
                continue;
            }

            // 3. 过滤单行技能名（纯大写字母和空格组成，且长度合理）
            if (isPureMoveName(trimmed)) {
                continue;
            }

            // 3. 过滤 PP 格式（如 "13/15", "22/25"）
            if (isPPFormat(trimmed)) {
                continue;
            }

            // 3. 过滤 TYPE/ 属性行
            if (isTypeLine(trimmed)) {
                continue;
            }

            // 2. 补全空格
            String fixed = fixMissingSpaces(trimmed);

            cleaned.append(fixed).append("\n");
        }

        return cleaned.toString().trim();
    }

    /**
     * 检查是否包含乱码字符
     */
    private static boolean containsGarbage(String line) {
        // 检测特殊乱码字符
        return line.contains("Á") || line.contains("À") || line.contains("Î") || line.contains("♂");
    }

    /**
     * 检查是否是纯技能名行
     */
    private static boolean isPureMoveName(String line) {
        // 纯大写字母、空格、连字符组成，长度在 3-20 之间
        if (line.matches("^[A-Z][A-Z\\s-]{2,19}$")) {
            // 排除一些可能是正常文本的情况
            // 如 "GO!" 或其他感叹句
            return !line.endsWith("!");
        }
        return false;
    }

    /**
     * 检查是否是 PP 格式
     */
    private static boolean isPPFormat(String line) {
        // 匹配 "数字/数字" 格式
        return line.matches("^\\d+/\\d+$");
    }

    /**
     * 检查是否是 TYPE 属性行
     */
    private static boolean isTypeLine(String line) {
        // 匹配 "TYPE/" 开头的行
        return line.startsWith("TYPE/");
    }

    /**
     * 补全缺失的空格
     */
    private static String fixMissingSpaces(String line) {
        // 在小写字母后跟大写字母之间加空格
        // 如 "usedSTRENGTH" -> "used STRENGTH"
        line = line.replaceAll("([a-z])([A-Z])", "$1 $2");

        // 在单词后跟 "!" 加空格（如 "fainted!" -> "fainted!" 已经正确）
        // 但 "usedSTRENGTH!" 需要处理
        line = line.replaceAll("([a-zA-Z])(!)", "$1$2"); // 保持不变

        // 处理 "willI" -> "will I"
        line = line.replaceAll("willI", "will I");

        // 处理 "sentout" -> "sent out"
        line = line.replaceAll("sentout", "sent out");

        // 处理 "used" + 技能名 的情况
        line = line.replaceAll("used([A-Z])", "used $1");

        // 处理 "fainted!" 之前可能缺少空格
        line = line.replaceAll("([a-zA-Z])(fainted)", "$1 $2");

        return line;
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
