package com.xiaobaozi.ai_play_pokemon.quickstart;

import com.xiaobaozi.ai_play_pokemon.utils.HttpClientUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.util.StringUtils;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 截图功能单元测试
 * 测试BizHawk模拟器的/screenshot接口功能
 */
public class ScreenshotTest {

    private final String sandboxUrl = "http://localhost:8080";

    @BeforeEach
    public void setUp() {
        // 确保测试环境可用
        try {
            HttpClientUtil.sendGetRequest(sandboxUrl + "/status");
        } catch (Exception e) {
            System.out.println("警告: 无法连接到沙盒环境");
        }
    }

    /**
     * 测试截图（使用默认文件名）
     */
    @Test
    public void testScreenshotWithDefaultName() {
        String screenshotUrl = sandboxUrl + "/screenshot";
        String response = HttpClientUtil.sendGetRequest(screenshotUrl);

        assertNotNull(response);
        assertTrue(StringUtils.hasText(response));

        System.out.println("截图响应: " + response);

        // 验证响应包含成功信息和文件名
        assertTrue(response.contains("success"));
        assertTrue(response.contains("filename"));
        assertTrue(response.contains(".png"));
    }

    /**
     * 测试截图（使用自定义文件名）
     */
    @Test
    public void testScreenshotWithCustomName() {
        String screenshotName = "test_screenshot_001";
        String screenshotUrl = sandboxUrl + "/screenshot?name=" + screenshotName;
        String response = HttpClientUtil.sendGetRequest(screenshotUrl);

        assertNotNull(response);
        assertTrue(StringUtils.hasText(response));

        System.out.println("自定义名称截图响应: " + response);

        // 验证响应包含指定的文件名
        assertTrue(response.contains("success"));
        assertTrue(response.contains(screenshotName + ".png"));
    }

    /**
     * 测试多次连续截图
     */
    @Test
    public void testMultipleScreenshots() {
        for (int i = 0; i < 3; i++) {
            String screenshotName = "multi_test_" + i;
            String screenshotUrl = sandboxUrl + "/screenshot?name=" + screenshotName;
            String response = HttpClientUtil.sendGetRequest(screenshotUrl);

            assertNotNull(response);
            assertTrue(response.contains("success"));

            System.out.println("第 " + (i + 1) + " 次截图成功: " + response);

            // 短暂等待
            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }

    /**
     * 测试截图后验证路径格式
     */
    @Test
    public void testScreenshotPathFormat() {
        String screenshotName = "path_test";
        String screenshotUrl = sandboxUrl + "/screenshot?name=" + screenshotName;
        String response = HttpClientUtil.sendGetRequest(screenshotUrl);

        assertNotNull(response);

        // 验证路径格式包含 Screenshot 目录
        assertTrue(response.contains("Screenshot"));
        assertTrue(response.contains(screenshotName + ".png"));

        System.out.println("路径格式验证成功: " + response);
    }
}
