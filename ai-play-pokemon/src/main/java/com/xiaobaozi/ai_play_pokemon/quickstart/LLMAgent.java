package com.xiaobaozi.ai_play_pokemon.quickstart;

import com.xiaobaozi.ai_play_pokemon.utils.DashScopeApiClient;
import org.springframework.util.StringUtils;

import java.net.MalformedURLException;
import java.net.URL;

/**
 * 智能决策中心
 * 根据战斗状态和游戏截图做出决策
 */
public class LLMAgent {

    private final DashScopeApiClient dashScopeApiClient;

    public LLMAgent() {
        // 使用阿里百炼API密钥（实际使用时请替换为真实密钥）
        String apiKey = System.getenv("AI_DASHSCOPE_API_KEY");
        if (apiKey == null || apiKey.isEmpty()) {
            throw new IllegalStateException("请设置AI_DASHSCOPE_API_KEY环境变量");
        }
        this.dashScopeApiClient = new DashScopeApiClient(apiKey);
    }

    /**
     * 根据战斗状态和截图做出决策
     * @param battleStatus 战斗状态信息
     * @param screenshot 游戏截图
     * @return 动作序列（如 "A,LEFT,UP"），返回空字符串表示退出
     */
    public String makeDecision(String battleStatus, byte[] screenshot) {
        try {
            // 将截图转换为URL（实际使用时需要正确的图片URL）
            URL imageUrl = convertBytesToUrl(screenshot);

            // 构建系统提示，设定agent角色
            String systemPrompt = """
                你是一个专业的宝可梦对战AI助手。
                你的任务是分析当前战斗状态和游戏画面，做出最佳决策。
                支持的动作原子：A, B, L, R, START, SELECT, UP, DOWN, LEFT, RIGHT
                如果决定退出战斗，请返回空字符串。
                """;

            // 构建用户消息，包含战斗状态和截图
            String userMessage = """
                当前战斗状态：
                %s

                请分析当前战斗情况，选择最佳动作序列。
                如果战斗已经结束或需要退出，请返回空字符串。
                """.formatted(battleStatus);

            // 发送文本+图像消息给AI
            String response = dashScopeApiClient.sendTextAndImageMessage(
                systemPrompt,
                userMessage,
                imageUrl
            );

            // 处理AI响应，提取动作序列
            return parseActionSequence(response);

        } catch (Exception e) {
            System.err.println("Agent决策失败: " + e.getMessage());
            return ""; // 决策失败时返回空字符串表示退出
        }
    }

    /**
     * 将字节数组转换为URL（模拟实现）
     */
    private URL convertBytesToUrl(byte[] screenshot) throws MalformedURLException {
        // 实际实现中需要将字节数组保存为临时文件或上传到服务器
        // 这里简化处理，返回一个示例URL
        return new URL("https://example.com/temp-screenshot.jpg");
    }

    /**
     * 解析AI响应，提取动作序列
     */
    private String parseActionSequence(String response) {
        if (!StringUtils.hasText(response)) {
            return ""; // 空响应表示退出
        }

        // 简单解析：查找包含动作序列的部分
        String[] lines = response.split("\n");
        for (String line : lines) {
            if (line.contains("动作序列") || line.contains("Action")) {
                // 提取动作序列（简化处理）
                String[] parts = line.split(":");
                if (parts.length > 1) {
                    String sequence = parts[1].trim();
                    // 清理动作序列，只保留支持的原子动作
                    return cleanActionSequence(sequence);
                }
            }
        }

        // 默认返回空字符串表示退出
        return "";
    }

    /**
     * 清理动作序列，只保留支持的原子动作
     */
    private String cleanActionSequence(String sequence) {
        // 支持的动作原子
        String validActions = "A,B,L,R,START,SELECT,UP,DOWN,LEFT,RIGHT";
        String[] actions = validActions.split(",");

        // 分割输入序列
        String[] inputActions = sequence.split("[,\\s]+");

        // 过滤有效动作
        StringBuilder cleanedSequence = new StringBuilder();
        for (String action : inputActions) {
            if (isValidAction(action.trim(), actions)) {
                if (cleanedSequence.length() > 0) {
                    cleanedSequence.append(",");
                }
                cleanedSequence.append(action.trim());
            }
        }

        return cleanedSequence.toString();
    }

    /**
     * 检查动作是否有效
     */
    private boolean isValidAction(String action, String[] validActions) {
        for (String validAction : validActions) {
            if (validAction.equalsIgnoreCase(action)) {
                return true;
            }
        }
        return false;
    }
}