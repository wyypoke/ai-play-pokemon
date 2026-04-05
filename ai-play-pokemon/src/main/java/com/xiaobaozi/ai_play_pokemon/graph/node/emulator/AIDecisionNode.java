package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.*;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import com.xiaobaozi.ai_play_pokemon.graph.service.EmulatorLLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: AI 决策
 *
 * 使用 LLM 进行决策，无回退机制
 * LLM 调用失败重试 3 次后返回失败
 */
public class AIDecisionNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(AIDecisionNode.class);

    private final BattleEmulator emulator;
    private final EmulatorLLMService llmService;

    public AIDecisionNode(BattleEmulator emulator, EmulatorLLMService llmService) {
        this.emulator = emulator;
        this.llmService = llmService;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        BattleContext context = (BattleContext) state.value(EmulatorStateKeys.BATTLE_CONTEXT).orElse(null);
        DecisionPoint decisionPoint = (DecisionPoint) state.value(EmulatorStateKeys.DECISION_POINT).orElse(null);
        int decisionCount = (int) state.value(EmulatorStateKeys.DECISION_COUNT).orElse(0);
        int maxDecisions = (int) state.value(EmulatorStateKeys.MAX_DECISIONS)
                .orElse(EmulatorStateKeys.DEFAULT_MAX_DECISIONS);
        String currentBattleLog = (String) state.value(EmulatorStateKeys.CURRENT_BATTLE_LOG).orElse("");

        log.info("[AIDecisionNode] 决策中... (决策点: {}, 已决策: {}/{})",
                decisionPoint, decisionCount, maxDecisions);

        Map<String, Object> result = new HashMap<>();

        // 检查决策数是否超限
        if (decisionCount >= maxDecisions) {
            log.warn("[AIDecisionNode] 决策数超限! {}/{}", decisionCount, maxDecisions);
            result.put(EmulatorStateKeys.BATTLE_ENDED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        // 检查 LLM 服务是否可用
        if (llmService == null || !llmService.isAvailable()) {
            log.error("[AIDecisionNode] LLM 服务不可用!");
            result.put(EmulatorStateKeys.BATTLE_ENDED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        // 获取经验教训
        List<String> lessonsLearned = (List<String>) state.value(EmulatorStateKeys.LESSONS_LEARNED)
                .orElse(new ArrayList<>());

        // 获取任务系统参数
        List<TodoItem> todoList = (List<TodoItem>) state.value(EmulatorStateKeys.TODO_LIST).orElse(new ArrayList<>());
        String tips = (String) state.value(EmulatorStateKeys.TIPS).orElse("");
        List<String> forbiddenActions = (List<String>) state.value(EmulatorStateKeys.FORBIDDEN_ACTIONS).orElse(new ArrayList<>());

        // 打印当前任务状态
        if (!todoList.isEmpty()) {
            log.info("[AIDecisionNode] 当前任务:");
            for (TodoItem item : todoList) {
                log.info("  {}", item);
            }
        }

        // LLM 决策（带重试）
        GameAction decision = null;
        int maxRetries = EmulatorStateKeys.MAX_LLM_RETRIES;

        for (int retry = 0; retry < maxRetries; retry++) {
            try {
                log.info("[AIDecisionNode] LLM 决策尝试 {}/{}", retry + 1, maxRetries);
                EmulatorLLMService.AIDecisionResult llmResult = llmService.generateDecision(
                        context, decisionPoint, lessonsLearned, currentBattleLog, 0,
                        todoList, tips, forbiddenActions);

                if (llmResult != null && llmResult.action != null) {
                    decision = llmResult.action;
                    decision.setReason(llmResult.reasoning);
                    log.info("[AIDecisionNode] LLM 决策成功: {} (理由: {})",
                            decision.toDecisionString(), llmResult.reasoning);
                    break;
                }
            } catch (Exception e) {
                log.error("[AIDecisionNode] LLM 决策异常 (尝试 {}/{}): {}", retry + 1, maxRetries, e.getMessage());
            }
        }

        // 检查决策结果
        if (decision == null) {
            log.error("[AIDecisionNode] LLM 决策失败，已重试 {} 次", maxRetries);
            result.put(EmulatorStateKeys.BATTLE_ENDED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        // 决策成功
        result.put(EmulatorStateKeys.AI_DECISION, decision);
        result.put(EmulatorStateKeys.DECISION_COUNT, decisionCount + 1);
        result.put(EmulatorStateKeys.NEXT_NODE, "execute");

        // 注意：新流程移除了失败分析，不再需要保存战斗上下文历史
        // 如需恢复，可在此处添加历史保存逻辑

        System.out.println("\n========== Final Decision ==========");
        System.out.println("Action: " + decision.toDecisionString());
        System.out.println("Reason: " + decision.getReason());
        System.out.println("====================================");

        log.info("[AIDecisionNode] 决策完成: {}", decision.toDecisionString());

        return result;
    }
}
