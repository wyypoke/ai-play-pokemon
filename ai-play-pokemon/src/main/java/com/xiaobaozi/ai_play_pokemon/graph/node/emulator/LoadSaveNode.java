package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.BattleEmulator;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * 节点: 加载存档
 *
 * 读取初始存档文件，重置战斗状态
 */
public class LoadSaveNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(LoadSaveNode.class);

    private final BattleEmulator emulator;

    public LoadSaveNode(BattleEmulator emulator) {
        this.emulator = emulator;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        String saveFile = (String) state.value(EmulatorStateKeys.INITIAL_SAVE_FILE).orElse(null);
        int attemptCount = (int) state.value(EmulatorStateKeys.ATTEMPT_COUNT).orElse(0);

        log.info("[LoadSaveNode] 加载存档: {} (尝试 #{})", saveFile, attemptCount + 1);

        Map<String, Object> result = new HashMap<>();

        // 加载存档
        emulator.loadState(saveFile);

        // 增加尝试次数
        result.put(EmulatorStateKeys.ATTEMPT_COUNT, attemptCount + 1);

        // 重置战斗状态
        result.put(EmulatorStateKeys.TURN, 0);
        result.put(EmulatorStateKeys.DECISION_COUNT, 0);
        result.put(EmulatorStateKeys.BATTLE_ENDED, false);
        result.put(EmulatorStateKeys.DECISION_HISTORY, new ArrayList<>());

        // 清除模拟器缓存的战斗模式
        emulator.clearBattleFormat();

        // 清空战报日志
        emulator.clearLog();

        log.info("[LoadSaveNode] 存档加载完成");

        return result;
    }
}
