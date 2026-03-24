package com.xiaobaozi.ai_play_pokemon.quickstart;

import com.xiaobaozi.ai_play_pokemon.utils.HttpClientUtil;
import org.junit.jupiter.api.Test;
import org.springframework.util.StringUtils;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 双打对战存档加载测试
 * 测试加载 states/Double-Battle-Test.State 存档文件
 */
public class DoubleBattleLoadStateTest {

    private final String sandboxUrl = "http://localhost:8080";

    
    // API调用时使用去掉 .State 后缀的名称
    private static final String STATE_NAME = "Double-Battle-Test";

    /**
     * 测试加载 Double-Battle-Test 存档
     */
    @Test
    public void testLoadState() {
        String loadStateUrl = sandboxUrl + "/loadstate?name=" + STATE_NAME;
        String response = HttpClientUtil.sendGetRequest(loadStateUrl);

        assertNotNull(response, "响应不应为空");
        assertTrue(StringUtils.hasText(response), "响应应包含内容");

        System.out.println("加载存档 [" + STATE_NAME + "] 响应: " + response);
    }
}
