package com.xiaobaozi.ai_play_pokemon.quickstart;

import com.xiaobaozi.ai_play_pokemon.utils.HttpClientUtil;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.util.StringUtils;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 保存存档功能单元测试
 * 测试BizHawk模拟器的/savestate接口功能
 */
public class SaveStateTest {

    private final String sandboxUrl = "http://localhost:8080";

    // 测试用的存档名称
    private static final String TEST_SAVE_NAME = "test_save_state";

    @BeforeEach
    public void setUp() {
        // 确保测试环境可用
        try {
            HttpClientUtil.sendGetRequest(sandboxUrl + "/status");
        } catch (Exception e) {
            System.out.println("警告: 无法连接到沙盒环境");
        }
    }

    @AfterEach
    public void tearDown() {
        // 清理测试存档（可选）
    }

    /**
     * 测试保存存档
     */
    @Test
    public void testSaveState() {
        String saveUrl = sandboxUrl + "/savestate?name=" + TEST_SAVE_NAME;
        String response = HttpClientUtil.sendGetRequest(saveUrl);

        assertNotNull(response);
        assertTrue(StringUtils.hasText(response));

        System.out.println("保存存档响应: " + response);

        // 验证响应包含成功信息
        assertTrue(response.contains("success"));
        assertTrue(response.contains("State saved"));
    }

    /**
     * 测试缺少name参数的情况
     */
    @Test
    public void testSaveStateWithoutNameParameter() {
        String saveUrl = sandboxUrl + "/savestate";
        String response = HttpClientUtil.sendGetRequest(saveUrl);

        assertNotNull(response);
        assertTrue(StringUtils.hasText(response));

        // 验证错误响应
        assertTrue(response.contains("error"));
        assertTrue(response.contains("Missing parameter"));

        System.out.println("缺少name参数响应: " + response);
    }

    /**
     * 测试保存后加载存档
     */
    @Test
    public void testSaveAndLoadState() {
        // 先保存当前状态
        String saveUrl = sandboxUrl + "/savestate?name=" + TEST_SAVE_NAME;
        String saveResponse = HttpClientUtil.sendGetRequest(saveUrl);

        assertNotNull(saveResponse);
        assertTrue(saveResponse.contains("success"));

        // 然后加载保存的状态
        String loadUrl = sandboxUrl + "/loadstate?name=" + TEST_SAVE_NAME;
        String loadResponse = HttpClientUtil.sendGetRequest(loadUrl);

        assertNotNull(loadResponse);
        assertTrue(loadResponse.contains("success"));

        System.out.println("保存并加载存档测试成功");
    }

    /**
     * 测试覆盖保存存档
     */
    @Test
    public void testOverwriteSaveState() {
        String saveUrl = sandboxUrl + "/savestate?name=" + TEST_SAVE_NAME;

        // 第一次保存
        String response1 = HttpClientUtil.sendGetRequest(saveUrl);
        assertNotNull(response1);
        assertTrue(response1.contains("success"));

        // 第二次保存（覆盖）
        String response2 = HttpClientUtil.sendGetRequest(saveUrl);
        assertNotNull(response2);
        assertTrue(response2.contains("success"));

        System.out.println("覆盖保存存档测试成功");
    }
}
