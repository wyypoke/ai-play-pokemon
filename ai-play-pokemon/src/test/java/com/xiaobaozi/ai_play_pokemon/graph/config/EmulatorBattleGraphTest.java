package com.xiaobaozi.ai_play_pokemon.graph.config;

import com.alibaba.cloud.ai.graph.CompiledGraph;
import com.alibaba.cloud.ai.graph.OverAllState;
import com.xiaobaozi.ai_play_pokemon.graph.model.EmulatorStateKeys;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Map;

/**
 * 模拟器战斗图测试
 */
@SpringBootTest
public class EmulatorBattleGraphTest {

    @Autowired
    private CompiledGraph emulatorBattleGraph;

    @Test
    public void testRunBattle() {
        // 创建初始状态
        Map<String, Object> initialState = EmulatorBattleGraphConfig.createInitialState("battle_sav");

        System.out.println("========== 开始战斗测试 ==========");
        System.out.println("存档文件: battle_sav.State");
        System.out.println("最大决策数: " + EmulatorStateKeys.DEFAULT_MAX_DECISIONS);
        System.out.println();

        try {
            // 运行图
            OverAllState result = emulatorBattleGraph.invoke(initialState).orElse(null);

            if (result == null) {
                System.err.println("战斗执行失败: 图执行返回 null");
                return;
            }

            // 输出结果
            System.out.println("========== 战斗结束 ==========");
            System.out.println("战斗结束: " + result.value(EmulatorStateKeys.BATTLE_ENDED).orElse(false));
            System.out.println("胜者: " + result.value(EmulatorStateKeys.WINNER).orElse("unknown"));
            System.out.println("决策数: " + result.value(EmulatorStateKeys.DECISION_COUNT).orElse(0));
            System.out.println();

        } catch (Exception e) {
            System.err.println("战斗执行失败: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * 手动测试入口
     */
    public static void main(String[] args) {
        System.out.println("请通过 Maven 或 IDE 的 JUnit 运行此测试");
        System.out.println("命令: mvn test -Dtest=EmulatorBattleGraphTest#testRunBattle");
    }
}
