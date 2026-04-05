package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.BattleContext;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.BattlePhase;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.TodoItem;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import com.xiaobaozi.ai_play_pokemon.graph.service.EmulatorLLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: 任务检查
 *
 * 拉取战报 + LLM 检查任务完成情况
 */
public class TaskCheckNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(TaskCheckNode.class);

    private final BattleEmulator emulator;
    private final EmulatorLLMService llmService;

    public TaskCheckNode(BattleEmulator emulator, EmulatorLLMService llmService) {
        this.emulator = emulator;
        this.llmService = llmService;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        log.info("[TaskCheckNode] 检查任务完成情况...");

        Map<String, Object> result = new HashMap<>();

        // 获取当前状态
        BattleContext context = (BattleContext) state.value(EmulatorStateKeys.BATTLE_CONTEXT).orElse(null);
        List<TodoItem> todoList = (List<TodoItem>) state.value(EmulatorStateKeys.TODO_LIST).orElse(new ArrayList<>());
        List<String> forbiddenActions = (List<String>) state.value(EmulatorStateKeys.FORBIDDEN_ACTIONS).orElse(new ArrayList<>());
        boolean battleEnded = (boolean) state.value(EmulatorStateKeys.BATTLE_ENDED).orElse(false);

        // 等待战斗状态更新（像决策节点一样轮询 phase）
        log.info("[TaskCheckNode] 等待战斗状态更新...");
        waitForBattleStateUpdate();

        // 重新获取最新的战斗上下文（包含最新的能力变化等）
        BattleContext latestContext = emulator.getBattleContext();
        if (latestContext != null) {
            context = latestContext;
            result.put(EmulatorStateKeys.BATTLE_CONTEXT, context);
        }

        // 拉取最新战报
        String battleLog = emulator.getCleanedBattleLog();

        // 保存当前战报
        result.put(EmulatorStateKeys.CURRENT_BATTLE_LOG, battleLog);

        // 检查 LLM 服务
        if (llmService == null || !llmService.isAvailable()) {
            log.warn("[TaskCheckNode] LLM 服务不可用，跳过检查");
            result.put(EmulatorStateKeys.NEXT_NODE, "check_result");
            return result;
        }

        // 调用 LLM 检查
        EmulatorLLMService.TaskCheckResult checkResult = llmService.checkTaskCompletion(
                context, battleLog, todoList, forbiddenActions);

        if (checkResult == null) {
            log.warn("[TaskCheckNode] LLM 检查失败，跳过检查");
            result.put(EmulatorStateKeys.NEXT_NODE, "check_result");
            return result;
        }

        // 更新 todo list
        if (checkResult.updatedTodos != null) {
            result.put(EmulatorStateKeys.TODO_LIST, checkResult.updatedTodos);
            log.info("[TaskCheckNode] 更新后的任务列表:");
            for (TodoItem item : checkResult.updatedTodos) {
                log.info("  {}", item);
            }
        }

        // 检查禁止行为
        if (checkResult.forbidden) {
            log.error("[TaskCheckNode] 检测到禁止行为! 原因: {}", checkResult.forbiddenReason);
            result.put(EmulatorStateKeys.FORBIDDEN_DETECTED, true);
            result.put(EmulatorStateKeys.BATTLE_RESULT, "forbidden_action");
            result.put(EmulatorStateKeys.IS_VICTORY, false);
            result.put(EmulatorStateKeys.BATTLE_ENDED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "summary");
            return result;
        }

        // 打印分析
        if (checkResult.analysis != null) {
            log.info("[TaskCheckNode] 分析: {}", checkResult.analysis);
        }

        // 继续战斗循环
        result.put(EmulatorStateKeys.FORBIDDEN_DETECTED, false);
        result.put(EmulatorStateKeys.NEXT_NODE, "check_result");

        return result;
    }

    /**
     * 等待战斗状态更新
     * 通过轮询 phase 端点，等待到达决策点或战斗结束
     */
    private void waitForBattleStateUpdate() {
        try {
            int maxWaitCount = 100; // 最多等待 100 次 × 50ms = 5 秒
            int waitCount = 0;

            while (waitCount < maxWaitCount) {
                BattlePhase phase = emulator.getBattlePhase();

                // 到达决策点或战斗结束，说明状态已稳定
                if (phase.needsDecision() || phase.isBattleEnded()) {
                    log.info("[TaskCheckNode] 战斗状态已稳定: {}", phase);
                    return;
                }

                Thread.sleep(50); // 50ms
                waitCount++;
            }

            log.warn("[TaskCheckNode] 等待战斗状态超时");

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("[TaskCheckNode] 等待被中断");
        } catch (Exception e) {
            log.warn("[TaskCheckNode] 等待战斗状态时出错: {}", e.getMessage());
        }
    }
}
