package com.xiaobaozi.ai_play_pokemon.graph.config;

import com.alibaba.cloud.ai.graph.CompiledGraph;
import com.alibaba.cloud.ai.graph.KeyStrategy;
import com.alibaba.cloud.ai.graph.KeyStrategyFactory;
import com.alibaba.cloud.ai.graph.StateGraph;
import com.alibaba.cloud.ai.graph.exception.GraphStateException;
import com.alibaba.cloud.ai.graph.state.strategy.AppendStrategy;
import com.alibaba.cloud.ai.graph.state.strategy.ReplaceStrategy;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import com.xiaobaozi.ai_play_pokemon.graph.node.emulator.*;
import com.xiaobaozi.ai_play_pokemon.graph.service.EmulatorLLMService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

import static com.alibaba.cloud.ai.graph.StateGraph.END;
import static com.alibaba.cloud.ai.graph.StateGraph.START;
import static com.alibaba.cloud.ai.graph.action.AsyncEdgeAction.edge_async;
import static com.alibaba.cloud.ai.graph.action.AsyncNodeAction.node_async;

/**
 * 模拟器战斗图配置
 *
 * 流程:
 * START -> load_save -> task_generation -> get_decision_point -> ai_decision -> execute -> task_check -> 循环
 * task_check: 禁止行为 -> summary -> END
 * check_result: 战斗结束 -> summary -> END
 *            : 继续战斗 -> get_decision_point
 */
@Configuration
public class EmulatorBattleGraphConfig {

    private static final Logger log = LoggerFactory.getLogger(EmulatorBattleGraphConfig.class);

    @Value("${emulator.lua-server.url:http://localhost:8080}")
    private String emulatorUrl;

    /**
     * 创建状态键策略工厂
     */
    public KeyStrategyFactory createKeyStrategyFactory() {
        return () -> {
            Map<String, KeyStrategy> strategies = new HashMap<>();

            // 存档
            strategies.put(EmulatorStateKeys.INITIAL_SAVE_FILE, new ReplaceStrategy());

            // 战斗状态
            strategies.put(EmulatorStateKeys.TURN, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.DECISION_COUNT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_CONTEXT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_CONTEXT_HISTORY, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.DECISION_POINT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_ENDED, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.WINNER, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_RESULT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.IS_VICTORY, new ReplaceStrategy());

            // 决策相关
            strategies.put(EmulatorStateKeys.AI_DECISION, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.DECISION_HISTORY, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_LOG_HISTORY, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.CURRENT_BATTLE_LOG, new ReplaceStrategy());

            // 学习循环
            strategies.put(EmulatorStateKeys.ATTEMPT_COUNT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.MAX_ATTEMPTS, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.LESSONS_LEARNED, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.CURRENT_LESSONS, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.NEED_RETRY, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.BATTLE_RESULT_HISTORY, new ReplaceStrategy());

            // 配置
            strategies.put(EmulatorStateKeys.MAX_DECISIONS, new ReplaceStrategy());

            // 控制流
            strategies.put(EmulatorStateKeys.NEXT_NODE, new ReplaceStrategy());

            // LLM 相关
            strategies.put(EmulatorStateKeys.LLM_RETRY_COUNT, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.LLM_FAILED, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.ANALYSIS_SUMMARY, new ReplaceStrategy());

            // 任务系统
            strategies.put(EmulatorStateKeys.TODO_LIST, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.TIPS, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.FORBIDDEN_ACTIONS, new ReplaceStrategy());
            strategies.put(EmulatorStateKeys.FORBIDDEN_DETECTED, new ReplaceStrategy());

            return strategies;
        };
    }

    /**
     * 创建模拟器战斗图
     */
    @Bean
    public CompiledGraph emulatorBattleGraph(EmulatorLLMService llmService,
                                              com.xiaobaozi.ai_play_pokemon.service.GameDataLookupService lookupService) throws GraphStateException {
        log.info("创建模拟器战斗图...");

        // 创建模拟器
        BattleEmulator emulator = new BattleEmulator(emulatorUrl);
        emulator.setLookupService(lookupService);

        // 创建节点
        var loadSave = node_async(new LoadSaveNode(emulator));
        var taskGeneration = node_async(new TaskGenerationNode());
        var getDecisionPoint = node_async(new GetDecisionPointNode(emulator));
        var aiDecision = node_async(new AIDecisionNode(emulator, llmService));
        var executeAction = node_async(new ExecuteActionNode(emulator));
        var taskCheck = node_async(new TaskCheckNode(emulator, llmService));
        var checkResult = node_async(new CheckResultNode());
        var summary = node_async(new SummaryNode(llmService));

        // 构建图
        StateGraph workflow = new StateGraph(createKeyStrategyFactory())
                .addNode("load_save", loadSave)
                .addNode("task_generation", taskGeneration)
                .addNode("get_decision_point", getDecisionPoint)
                .addNode("ai_decision", aiDecision)
                .addNode("execute", executeAction)
                .addNode("task_check", taskCheck)
                .addNode("check_result", checkResult)
                .addNode("summary", summary);

        // 基本边
        workflow.addEdge(START, "load_save");
        workflow.addEdge("load_save", "task_generation");
        workflow.addEdge("task_generation", "get_decision_point");

        // get_decision_point 条件边
        workflow.addConditionalEdges("get_decision_point",
                edge_async(state -> {
                    String nextNode = (String) state.value(EmulatorStateKeys.NEXT_NODE).orElse("ai_decision");
                    return nextNode;
                }),
                Map.of(
                        "ai_decision", "ai_decision",
                        "check_result", "check_result"
                ));

        // ai_decision 条件边
        workflow.addConditionalEdges("ai_decision",
                edge_async(state -> {
                    String nextNode = (String) state.value(EmulatorStateKeys.NEXT_NODE).orElse("execute");
                    return nextNode;
                }),
                Map.of(
                        "execute", "execute",
                        "end", END
                ));

        // execute -> task_check
        workflow.addEdge("execute", "task_check");

        // task_check 条件边: 禁止行为 -> summary, 正常 -> check_result
        workflow.addConditionalEdges("task_check",
                edge_async(state -> {
                    String nextNode = (String) state.value(EmulatorStateKeys.NEXT_NODE).orElse("check_result");
                    return nextNode;
                }),
                Map.of(
                        "check_result", "check_result",
                        "summary", END
                ));

        // check_result 条件边: 战斗结束 -> summary, 继续战斗 -> get_decision_point
        workflow.addConditionalEdges("check_result",
                edge_async(state -> {
                    String nextNode = (String) state.value(EmulatorStateKeys.NEXT_NODE).orElse("summary");
                    return nextNode;
                }),
                Map.of(
                        "summary", END,
                        "get_decision_point", "get_decision_point"
                ));

        // summary -> END
        workflow.addEdge("summary", END);

        log.info("模拟器战斗图创建完成");

        return workflow.compile();
    }

    /**
     * 创建初始状态
     */
    public static Map<String, Object> createInitialState(String saveFile) {
        Map<String, Object> state = new HashMap<>();
        state.put(EmulatorStateKeys.INITIAL_SAVE_FILE, saveFile);
        state.put(EmulatorStateKeys.MAX_DECISIONS, EmulatorStateKeys.DEFAULT_MAX_DECISIONS);
        state.put(EmulatorStateKeys.MAX_ATTEMPTS, 5);
        state.put(EmulatorStateKeys.ATTEMPT_COUNT, 0);
        state.put(EmulatorStateKeys.DECISION_COUNT, 0);
        state.put(EmulatorStateKeys.BATTLE_ENDED, false);
        state.put(EmulatorStateKeys.LLM_RETRY_COUNT, 0);
        state.put(EmulatorStateKeys.LLM_FAILED, false);
        return state;
    }
}
