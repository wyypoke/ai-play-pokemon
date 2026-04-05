package com.xiaobaozi.ai_play_pokemon.graph.node.emulator;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.TodoItem;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 节点: 任务生成
 *
 * 生成战斗任务列表（硬编码实现）
 */
public class TaskGenerationNode implements NodeAction {

    private static final Logger log = LoggerFactory.getLogger(TaskGenerationNode.class);

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        log.info("[TaskGenerationNode] 生成战斗任务...");

        Map<String, Object> result = new HashMap<>();

        // 硬编码任务列表
        List<TodoItem> todoList = new ArrayList<>();
        todoList.add(TodoItem.of("1", "持续性任务：面对Luvdisc时，保证我方场上有Safeguard状态，如果Luvdisc濒死，任务完成", 1));
        todoList.add(TodoItem.of("2", "持续性任务：面对Luvdisc时，保证我方场上有HP>50%，如果Luvdisc濒死，任务完成", 2));
        todoList.add(TodoItem.of("3", "面对Luvdisc，使用至少6次Dragon Dance，检查方式攻击力至少+6，如果Luvdisc濒死，任务完成", 3));
        todoList.add(TodoItem.of("4", "满足攻击力至少+6时，使用Aerial Ace击杀对方5只精灵", 4));
        // 战斗提示
        String tips = "开局使用Safeguard。面对Luvdisc时，Safeguard效果消失及时补充";

        // 禁止行为
        List<String> forbiddenActions = new ArrayList<>();
        forbiddenActions.add("击倒Luvdisc时 Altaria的攻击没有达到至少+5");

        result.put(EmulatorStateKeys.TODO_LIST, todoList);
        result.put(EmulatorStateKeys.TIPS, tips);
        result.put(EmulatorStateKeys.FORBIDDEN_ACTIONS, forbiddenActions);
        result.put(EmulatorStateKeys.FORBIDDEN_DETECTED, false);
        result.put(EmulatorStateKeys.NEXT_NODE, "get_decision_point");

        log.info("[TaskGenerationNode] 任务列表:");
        for (TodoItem item : todoList) {
            log.info("  {}", item);
        }
        log.info("[TaskGenerationNode] 提示: {}", tips);
        log.info("[TaskGenerationNode] 禁止行为: {}", forbiddenActions);

        return result;
    }
}
