package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.ActionResult;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.BattleContext;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.DecisionPoint;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * 节点: 获取决策点
 *
 * 运行模拟器到下一个决策点，获取战斗上下文
 */
public class GetDecisionPointNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(GetDecisionPointNode.class);

    private final BattleEmulator emulator;

    public GetDecisionPointNode(BattleEmulator emulator) {
        this.emulator = emulator;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        int turn = (int) state.value(EmulatorStateKeys.TURN).orElse(0);

        log.info("[GetDecisionPointNode] 等待下一个决策点... (当前回合: {})", turn);

        Map<String, Object> result = new HashMap<>();

        // 运行到下一个决策点
        ActionResult actionResult = emulator.runUntilNextDecision();

        if (actionResult == null) {
            log.error("[GetDecisionPointNode] 获取决策点失败");
            result.put(EmulatorStateKeys.NEXT_NODE, "end");
            return result;
        }

        // 更新状态
        result.put(EmulatorStateKeys.DECISION_POINT, actionResult.getDecisionPoint());
        result.put(EmulatorStateKeys.BATTLE_ENDED, actionResult.isBattleEnded());
        result.put(EmulatorStateKeys.WINNER, actionResult.getWinner());
        result.put(EmulatorStateKeys.CURRENT_BATTLE_LOG, actionResult.getBattleLog());

        // 更新战斗上下文
        BattleContext context = actionResult.getContext();
        if (context != null) {
            result.put(EmulatorStateKeys.BATTLE_CONTEXT, context);
            result.put(EmulatorStateKeys.TURN, context.getTurn());
            log.info("[GetDecisionPointNode] 战斗模式: {}, 回合: {}, 决策点: {}",
                    context.getBattleFormat(), context.getTurn(), actionResult.getDecisionPoint());
        }

        // 判断是否需要决策
        if (actionResult.isBattleEnded()) {
            // 判断胜负（带重试）
            String battleLog = actionResult.getBattleLog();
            boolean playerWon = checkBattleResultWithRetry(battleLog);
            String winner = playerWon ? "p1" : "p2";
            String battleResult = playerWon ? "victory" : "defeat";

            log.info("[GetDecisionPointNode] 战斗结束! 胜者: {}, 结果: {}", winner, battleResult);

            result.put(EmulatorStateKeys.WINNER, winner);
            result.put(EmulatorStateKeys.BATTLE_RESULT, battleResult);
            result.put(EmulatorStateKeys.NEXT_NODE, "check_result");
        } else if (actionResult.getDecisionPoint() == DecisionPoint.FORCE_SWITCH) {
            log.info("[GetDecisionPointNode] 需要濒死替换");
            result.put(EmulatorStateKeys.NEXT_NODE, "ai_decision");
        } else if (actionResult.getDecisionPoint() == DecisionPoint.TEAM_PREVIEW) {
            log.info("[GetDecisionPointNode] Team Preview 阶段");
            result.put(EmulatorStateKeys.NEXT_NODE, "ai_decision");
        } else {
            result.put(EmulatorStateKeys.NEXT_NODE, "ai_decision");
        }

        return result;
    }

    /**
     * 根据战报判断胜负（带重试机制）
     * 包含 "whited out" -> 玩家输了
     * 包含 "Player defeated" 或 "for winning" -> 玩家赢了
     */
    private boolean checkBattleResultWithRetry(String initialBattleLog) {
        final int maxRetries = 3;
        final long retryDelayMs = 500;

        String battleLog = initialBattleLog;
        Boolean result = null;

        for (int retry = 0; retry <= maxRetries; retry++) {
            result = checkBattleResult(battleLog);

            if (result != null) {
                // 成功判断
                return result;
            }

            // 无法判断，需要重试
            if (retry < maxRetries) {
                log.warn("[GetDecisionPointNode] 战报无法判断胜负，{}ms 后重试 ({}/{})",
                        retryDelayMs, retry + 1, maxRetries);

                try {
                    Thread.sleep(retryDelayMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }

                // 重新获取战报
                battleLog = emulator.getCleanedBattleLog();
            }
        }

        // 重试失败，默认失败
        log.warn("[GetDecisionPointNode] 重试 {} 次后仍无法判断，默认失败", maxRetries);
        return false;
    }

    /**
     * 根据战报判断胜负
     * @return true=胜利, false=失败, null=无法判断
     */
    private Boolean checkBattleResult(String battleLog) {
        if (battleLog == null || battleLog.isEmpty()) {
            log.warn("[GetDecisionPointNode] 战报为空，无法判断");
            return null;
        }

        String lowerLog = battleLog.toLowerCase();

        if (lowerLog.contains("whited out")) {
            log.info("[GetDecisionPointNode] 检测到 'whited out' -> 玩家失败");
            return false;
        } else if (lowerLog.contains("player defeated") || lowerLog.contains("for winning")) {
            log.info("[GetDecisionPointNode] 检测到胜利关键词 -> 玩家胜利");
            return true;
        }

        // 无法判断
        log.warn("[GetDecisionPointNode] 未检测到胜负关键词");
        return null;
    }
}
