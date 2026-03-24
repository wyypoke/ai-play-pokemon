package com.xiaobaozi.ai_play_pokemon.utils;

import com.alibaba.cloud.ai.dashscope.api.DashScopeApi;
import com.alibaba.cloud.ai.dashscope.chat.DashScopeChatModel;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.ToolResponseMessage;
import org.springframework.ai.chat.metadata.ChatResponseMetadata;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.content.Media;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.util.MimeTypeUtils;

import java.io.File;
import java.net.URL;
import java.util.List;

/**
 * DashScope API客户端封装
 * 支持文本+图像消息
 *
 * Lua服务器额外接口：
 * - GET /screenshot: 获取游戏截屏
 * - GET /savestate?: 保存游戏状态
 * - GET /loadstate?: 加载游戏状态
 */
public class DashScopeApiClient {

    private final ChatModel chatModel;

    public DashScopeApiClient(String apiKey) {
        DashScopeApi dashScopeApi = DashScopeApi.builder()
                .apiKey(apiKey)
                .build();

        this.chatModel = DashScopeChatModel.builder()
                .dashScopeApi(dashScopeApi)
                .build();
    }

    /**
     * 发送文本消息
     */
    public String sendTextMessage(String systemPrompt, String userMessage) {
        SystemMessage systemMsg = new SystemMessage(systemPrompt);
        UserMessage userMsg = new UserMessage(userMessage);

        List<Message> messages = List.of(systemMsg, userMsg);
        Prompt prompt = new Prompt(messages);
        ChatResponse response = chatModel.call(prompt);

        return response.getResult().getOutput().getText();
    }

    /**
     * 发送文本+图像消息
     */
    public String sendTextAndImageMessage(String systemPrompt, String text, URL imageUrl) {
        SystemMessage systemMsg = new SystemMessage(systemPrompt);

        UserMessage userMsg = UserMessage.builder()
                .text(text)
                .media(Media.builder()
                        .mimeType(MimeTypeUtils.IMAGE_JPEG)
                        .data(imageUrl)
                        .build())
                .build();

        List<Message> messages = List.of(systemMsg, userMsg);
        Prompt prompt = new Prompt(messages);
        ChatResponse response = chatModel.call(prompt);

        return response.getResult().getOutput().getText();
    }

    /**
     * 发送文本+图像消息（本地文件）
     */
    public String sendTextAndLocalImageMessage(String systemPrompt, String text, String imagePath) {
        SystemMessage systemMsg = new SystemMessage(systemPrompt);

        UserMessage userMsg = UserMessage.builder()
                .text(text)
                .media(new Media(
                        MimeTypeUtils.IMAGE_JPEG,
                        new ClassPathResource(imagePath)
                ))
                .build();

        List<Message> messages = List.of(systemMsg, userMsg);
        Prompt prompt = new Prompt(messages);
        ChatResponse response = chatModel.call(prompt);

        return response.getResult().getOutput().getText();
    }

    /**
     * 获取token使用信息
     */
    public ChatResponseMetadata getUsageInfo(ChatResponse response) {
        return response.getMetadata();
    }
}