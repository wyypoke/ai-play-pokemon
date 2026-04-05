package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.BattleContext;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import com.xiaobaozi.ai_play_pokemon.graph.service.EmulatorLLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: 分析失败
 *
 * 使用 LLM 分析失败原因，生成经验教训
 */
public class AnalyzeFailureNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(AnalyzeFailureNode.class);

    private final EmulatorLLMService llmService;

    public AnalyzeFailureNode(EmulatorLLMService llmService) {
        this.llmService = llmService;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        int attemptCount = (int) state.value(EmulatorStateKeys.ATTEMPT_COUNT).orElse(0);
        String battleResult = (String) state.value(EmulatorStateKeys.BATTLE_RESULT).orElse("defeat");

        // 获取战斗上下文历史
        List<BattleContext> contextHistory = (List<BattleContext>) state.value(EmulatorStateKeys.BATTLE_CONTEXT_HISTORY)
                .orElse(new ArrayList<>());

        // 获取战报历史
        List<String> logHistory = (List<String>) state.value(EmulatorStateKeys.BATTLE_LOG_HISTORY)
                .orElse(new ArrayList<>());

        // 获取之前的教训
        List<String> previousLessons = (List<String>) state.value(EmulatorStateKeys.LESSONS_LEARNED)
                .orElse(new ArrayList<>());

        log.info("========== 分析失败 ==========");
        log.info("尝试次数: {}, 结果: {}, 回合数: {}", attemptCount, battleResult, contextHistory.size());

        Map<String, Object> result = new HashMap<>();

        // 检查 LLM 服务是否可用
        if (llmService == null || !llmService.isAvailable()) {
            log.error("[AnalyzeFailureNode] LLM 服务不可用!");
            result.put(EmulatorStateKeys.LLM_FAILED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "summary");
            return result;
        }

        // LLM 失败分析（带重试）
        List<String> currentLessons = null;
        int maxRetries = EmulatorStateKeys.MAX_LLM_RETRIES;

        for (int retry = 0; retry < maxRetries; retry++) {
            try {
                log.info("[AnalyzeFailureNode] LLM 分析尝试 {}/{}", retry + 1, maxRetries);
                EmulatorLLMService.FailureAnalysisResult llmResult = llmService.analyzeFailure(
                        contextHistory, logHistory, previousLessons, attemptCount);

                if (llmResult != null && llmResult.lessons != null && !llmResult.lessons.isEmpty()) {
                    currentLessons = llmResult.lessons;
                    log.info("[AnalyzeFailureNode] LLM 分析成功: {}", llmResult.analysis);
                    break;
                }
            } catch (Exception e) {
                log.error("[AnalyzeFailureNode] LLM 分析异常 (尝试 {}/{}): {}", retry + 1, maxRetries, e.getMessage());
            }
        }

        // 检查分析结果
        if (currentLessons == null || currentLessons.isEmpty()) {
            log.error("[AnalyzeFailureNode] LLM 分析失败，已重试 {} 次", maxRetries);
            result.put(EmulatorStateKeys.LLM_FAILED, true);
            result.put(EmulatorStateKeys.NEXT_NODE, "summary");
            return result;
        }

        // 将新教训追加到总教训列表
        List<String> allLessons = new ArrayList<>(previousLessons);
        allLessons.addAll(currentLessons);
        result.put(EmulatorStateKeys.LESSONS_LEARNED, allLessons);
        result.put(EmulatorStateKeys.CURRENT_LESSONS, currentLessons);

        // 设置下一个节点为重新加载存档
        result.put(EmulatorStateKeys.NEXT_NODE, "load_save");

        log.info("[AnalyzeFailureNode] 生成的经验教训:");
        for (int i = 0; i < currentLessons.size(); i++) {
            log.info("  {}. {}", i + 1, currentLessons.get(i));
        }
        log.info("累计教训总数: {}", allLessons.size());
        log.info("================================");

        return result;
    }
}
