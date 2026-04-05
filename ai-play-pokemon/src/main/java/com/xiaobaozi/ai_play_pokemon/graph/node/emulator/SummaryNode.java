package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.GameAction;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import com.xiaobaozi.ai_play_pokemon.graph.service.EmulatorLLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: 总结
 *
 * 使用 LLM 生成战斗总结报告
 * 无回退机制，LLM 调用失败重试 3 次后返回简短总结
 */
public class SummaryNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(SummaryNode.class);

    private final EmulatorLLMService llmService;

    public SummaryNode(EmulatorLLMService llmService) {
        this.llmService = llmService;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        boolean isVictory = (boolean) state.value(EmulatorStateKeys.IS_VICTORY).orElse(false);
        boolean llmFailed = (boolean) state.value(EmulatorStateKeys.LLM_FAILED).orElse(false);
        int attemptCount = (int) state.value(EmulatorStateKeys.ATTEMPT_COUNT).orElse(0);
        int finalDecisionCount = (int) state.value(EmulatorStateKeys.DECISION_COUNT).orElse(0);
        String winner = (String) state.value(EmulatorStateKeys.WINNER).orElse(null);
        String targetWinner = (String) state.value(EmulatorStateKeys.TARGET_WINNER)
                .orElse(EmulatorStateKeys.DEFAULT_TARGET_WINNER);
        String battleResult = (String) state.value(EmulatorStateKeys.BATTLE_RESULT).orElse("unknown");

        List<String> resultHistory = (List<String>) state.value(EmulatorStateKeys.BATTLE_RESULT_HISTORY)
                .orElse(new ArrayList<>());
        List<String> lessonsLearned = (List<String>) state.value(EmulatorStateKeys.LESSONS_LEARNED)
                .orElse(new ArrayList<>());
        List<GameAction> decisionHistory = (List<GameAction>) state.value(EmulatorStateKeys.DECISION_HISTORY)
                .orElse(new ArrayList<>());

        log.info("========== 战斗总结 ==========");
        log.info("最终结果: {}", isVictory ? "胜利!" : "失败");
        log.info("尝试次数: {}", attemptCount);
        log.info("最终决策数: {}", finalDecisionCount);
        log.info("最终胜者: {}", winner);

        Map<String, Object> result = new HashMap<>();

        // 如果之前 LLM 已经失败，直接生成简短总结
        if (llmFailed) {
            log.warn("[SummaryNode] 之前 LLM 已失败，生成简短总结");
            String summary = buildMinimalSummary(isVictory, battleResult, attemptCount);
            result.put(EmulatorStateKeys.ANALYSIS_SUMMARY, summary);
            log.info("\n{}", summary);
            return result;
        }

        // 检查 LLM 服务是否可用
        if (llmService == null || !llmService.isAvailable()) {
            log.error("[SummaryNode] LLM 服务不可用!");
            String summary = buildMinimalSummary(isVictory, battleResult, attemptCount);
            result.put(EmulatorStateKeys.ANALYSIS_SUMMARY, summary);
            log.info("\n{}", summary);
            return result;
        }

        // LLM 总结（带重试）
        String summary = null;
        int maxRetries = EmulatorStateKeys.MAX_LLM_RETRIES;

        for (int retry = 0; retry < maxRetries; retry++) {
            try {
                log.info("[SummaryNode] LLM 总结尝试 {}/{}", retry + 1, maxRetries);
                summary = llmService.generateSummary(
                        isVictory, attemptCount, resultHistory, lessonsLearned, decisionHistory);

                if (summary != null && !summary.isEmpty()) {
                    log.info("[SummaryNode] LLM 总结生成成功");
                    break;
                }
            } catch (Exception e) {
                log.error("[SummaryNode] LLM 总结异常 (尝试 {}/{}): {}", retry + 1, maxRetries, e.getMessage());
            }
        }

        // 检查总结结果
        if (summary == null || summary.isEmpty()) {
            log.error("[SummaryNode] LLM 总结失败，已重试 {} 次", maxRetries);
            summary = buildMinimalSummary(isVictory, battleResult, attemptCount);
        }

        result.put(EmulatorStateKeys.ANALYSIS_SUMMARY, summary);
        log.info("\n{}", summary);

        return result;
    }

    /**
     * 生成最小化总结（LLM 失败时使用）
     */
    private String buildMinimalSummary(boolean isVictory, String battleResult, int attemptCount) {
        StringBuilder sb = new StringBuilder();
        sb.append("# 战斗结束\n\n");
        sb.append("## 结果\n");
        sb.append("- 状态: ").append(isVictory ? "胜利" : "失败").append("\n");
        sb.append("- 原因: ").append(battleResult != null ? battleResult : "未知").append("\n");
        sb.append("- 尝试次数: ").append(attemptCount).append("\n\n");
        sb.append("*注: LLM 服务不可用，无法生成详细总结*\n");
        return sb.toString();
    }
}
