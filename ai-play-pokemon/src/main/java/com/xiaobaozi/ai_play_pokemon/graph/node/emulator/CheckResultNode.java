package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * 节点: 检查结果
 *
 * 检查战斗结果，判断胜负
 */
public class CheckResultNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(CheckResultNode.class);

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        String winner = (String) state.value(EmulatorStateKeys.WINNER).orElse(null);
        String battleResult = (String) state.value(EmulatorStateKeys.BATTLE_RESULT).orElse("defeat");
        String targetWinner = (String) state.value(EmulatorStateKeys.TARGET_WINNER)
                .orElse(EmulatorStateKeys.DEFAULT_TARGET_WINNER);
        int decisionCount = (int) state.value(EmulatorStateKeys.DECISION_COUNT).orElse(0);
        boolean battleEnded = (boolean) state.value(EmulatorStateKeys.BATTLE_ENDED).orElse(false);

        log.info("[CheckResultNode] 检查战斗状态: ended={}, 结果: {}, 胜者: {}, 决策数: {}",
                battleEnded, battleResult, winner, decisionCount);

        Map<String, Object> result = new HashMap<>();

        // 如果战斗还没结束，继续战斗
        if (!battleEnded) {
            log.info("[CheckResultNode] 战斗继续...");
            result.put(EmulatorStateKeys.NEXT_NODE, "get_decision_point");
            return result;
        }

        // 战斗结束，判断是否胜利
        boolean isVictory = "victory".equals(battleResult) || targetWinner.equals(winner);

        // 如果是 limit_reached，也算失败
        if ("limit_reached".equals(battleResult)) {
            isVictory = false;
            log.warn("[CheckResultNode] 达到决策数限制，视为失败");
        }

        // 如果是禁止行为触发的失败
        if ("forbidden_action".equals(battleResult)) {
            isVictory = false;
            log.warn("[CheckResultNode] 触犯禁止行为，判负");
        }

        result.put(EmulatorStateKeys.IS_VICTORY, isVictory);
        if (battleResult != null) {
            result.put(EmulatorStateKeys.BATTLE_RESULT, battleResult);
        } else {
            result.put(EmulatorStateKeys.BATTLE_RESULT, isVictory ? "victory" : "defeat");
        }

        if (isVictory) {
            log.info("[CheckResultNode] 🎉 胜利!");
        } else {
            log.info("[CheckResultNode] ❌ 失败!");
        }

        result.put(EmulatorStateKeys.NEXT_NODE, "summary");

        return result;
    }
}
