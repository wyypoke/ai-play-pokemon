package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.*;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: 执行操作
 *
 * 执行 AI 决策，将操作发送到模拟器
 */
public class ExecuteActionNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(ExecuteActionNode.class);

    private final BattleEmulator emulator;

    public ExecuteActionNode(BattleEmulator emulator) {
        this.emulator = emulator;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        GameAction decision = (GameAction) state.value(EmulatorStateKeys.AI_DECISION).orElse(null);
        DecisionPoint decisionPoint = (DecisionPoint) state.value(EmulatorStateKeys.DECISION_POINT).orElse(null);
        BattleContext context = (BattleContext) state.value(EmulatorStateKeys.BATTLE_CONTEXT).orElse(null);
        int turn = (int) state.value(EmulatorStateKeys.TURN).orElse(0);

        log.info("[ExecuteActionNode] 执行操作: {} (回合: {})", decision, turn);

        Map<String, Object> result = new HashMap<>();

        if (decision == null) {
            log.error("[ExecuteActionNode] 没有决策可执行");
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        ActionResult actionResult = null;

        // 根据决策点类型执行操作
        switch (decisionPoint) {
            case FORCE_SWITCH:
                actionResult = emulator.forceSwitch(decision.getSlot());
                break;

            case TEAM_PREVIEW:
                // Team Preview 特殊处理
                actionResult = handleTeamPreview(decision, context);
                break;

            case TURN_START:
            default:
                actionResult = executeTurnAction(decision, context);
                break;
        }

        if (actionResult == null) {
            log.error("[ExecuteActionNode] 执行操作失败");
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        // 记录决策历史（限制最多50条）
        List<GameAction> decisionHistory = (List<GameAction>) state.value(EmulatorStateKeys.DECISION_HISTORY)
                .orElse(new ArrayList<>());
        List<GameAction> newHistory = new ArrayList<>(decisionHistory);
        newHistory.add(decision);
        if (newHistory.size() > 50) {
            newHistory = new ArrayList<>(newHistory.subList(newHistory.size() - 50, newHistory.size()));
        }
        result.put(EmulatorStateKeys.DECISION_HISTORY, newHistory);

        // 注意：战报历史由 GetDecisionPointNode 在战斗结束时统一处理
        // 这里不再重复添加，避免日志重复

        // 更新状态
        result.put(EmulatorStateKeys.BATTLE_ENDED, actionResult.isBattleEnded());
        result.put(EmulatorStateKeys.WINNER, actionResult.getWinner());

        if (actionResult.getContext() != null) {
            result.put(EmulatorStateKeys.BATTLE_CONTEXT, actionResult.getContext());
            result.put(EmulatorStateKeys.TURN, actionResult.getContext().getTurn());
        }

        if (actionResult.isBattleEnded()) {
            log.info("[ExecuteActionNode] 战斗结束!");
        }

        return result;
    }

    /**
     * 执行回合操作
     */
    private ActionResult executeTurnAction(GameAction decision, BattleContext context) {
        if (context != null && context.isDoubles()) {
            // 双打需要两个决策，这里简化处理
            // 实际应用中可能需要更复杂的逻辑
            return emulator.executeAction(decision);
        } else {
            // 单打
            return emulator.executeAction(decision);
        }
    }

    /**
     * 处理 Team Preview
     */
    private ActionResult handleTeamPreview(GameAction decision, BattleContext context) {
        // Team Preview 需要特殊处理
        // 这里简化为执行决策
        return emulator.executeAction(decision);
    }
}
