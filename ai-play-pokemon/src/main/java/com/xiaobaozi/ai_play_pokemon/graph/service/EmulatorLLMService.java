package com.xiaobaozi.ai_play_pokemon.graph.service;

import com.alibaba.cloud.ai.dashscope.api.DashScopeApi;
import com.alibaba.cloud.ai.dashscope.chat.DashScopeChatModel;
import com.alibaba.cloud.ai.dashscope.chat.DashScopeChatOptions;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.BattleContext;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.DecisionPoint;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.GameAction;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.MoveInfo;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.PokemonState;
import com.xiaobaozi.ai_play_pokemon.emulator.dto.TodoItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 模拟器战斗 LLM 服务
 *
 * 为模拟器战斗图节点提供 LLM 调用能力
 */
@Service
public class EmulatorLLMService {

    private static final Logger log = LoggerFactory.getLogger(EmulatorLLMService.class);

    private final ChatModel chatModel;

    // ==================== System Prompts ====================

    private static final String AI_DECISION_SYSTEM_PROMPT = """
            # 宝可梦对战 AI 决策助手

            你是一个专业的宝可梦对战 AI 决策助手。根据当前战斗局面，生成最优决策。

            ## 分析要点
            1. **局面评估**：分析双方宝可梦的 HP、状态、能力变化
            2. **招式选择**：评估每个招式的效果和克制关系
            3. **替换策略**：判断是否需要替换宝可梦
            4. **历史教训**：参考之前失败的经验，避免重复错误

            ## 输出格式（必须严格遵循 JSON 格式）
            ```json
            {
              "type": "move",
              "slot": 1,
              "target": 1,
              "moveName": "Thunderbolt",
              "reasoning": "电击对水系宝可梦效果拔群"
            }
            ```

            ## 决策类型
            - `move`: 使用招式，需要 slot（招式槽位1-4）、target（目标位置，双打用，1=敌方左，2=敌方右）
            - `switch`: 替换宝可梦，需要 slot（后备位置1-6）

            ## 特殊情况
            - 濒死替换时，只能选择 `switch` 类型
            - Team Preview 时，选择首发阵容

            请针对对方队伍最有威胁的宝可梦们做出长线最优决策。
            """;

    private static final String FAILURE_ANALYSIS_SYSTEM_PROMPT = """
            # 失败分析

            对失败战斗的战报进行简要概况，先返回固定内容。
            
            

            ## 输出格式（JSON）
            ```json
            {
              "lessons": [看到残血精灵就想击杀，错过强化窗口期]
            }
            ```
            """;

    private static final String VICTORY_SUMMARY_SYSTEM_PROMPT = """
            # 胜利总结

            简洁总结胜利原因。

            输出格式（不超过100字）：
            - 关键决策：xxx
            - 有效策略：xxx
            """;

    private static final String DEFEAT_SUMMARY_SYSTEM_PROMPT = """
            # 失败总结

            简洁总结失败原因。

            输出格式（不超过100字）：
            - 敌方威胁：xxx
            - 失败原因：xxx
            - 下次注意：xxx
            """;

    // ==================== 构造函数 ====================

    public EmulatorLLMService() {
        String apiKey = System.getenv("AI_DASHSCOPE_API_KEY");
        if (apiKey == null || apiKey.isEmpty()) {
            log.warn("AI_DASHSCOPE_API_KEY 环境变量未设置，LLM 服务将不可用");
            this.chatModel = null;
        } else {
            DashScopeApi dashScopeApi = DashScopeApi.builder()
                    .apiKey(apiKey)
                    .build();

            DashScopeChatOptions chatOptions = DashScopeChatOptions.builder()
                    .model("deepseek-v3")
                    .temperature(0.1)
                    .build();

            this.chatModel = DashScopeChatModel.builder()
                    .dashScopeApi(dashScopeApi)
                    .defaultOptions(chatOptions)
                    .build();
        }
    }

    public EmulatorLLMService(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // ==================== AI 决策 ====================

    /**
     * 生成战斗决策
     *
     * @param context 战斗上下文
     * @param decisionPoint 决策点类型
     * @param lessonsLearned 历史经验教训
     * @param currentBattleLog 当前战报日志
     * @param attemptCount 当前尝试次数
     * @param todoList 任务列表
     * @param tips 战斗提示
     * @param forbiddenActions 禁止行为
     * @return AI 决策结果
     */
    public AIDecisionResult generateDecision(
            BattleContext context,
            DecisionPoint decisionPoint,
            List<String> lessonsLearned,
            String currentBattleLog,
            int attemptCount,
            List<TodoItem> todoList,
            String tips,
            List<String> forbiddenActions) {

        if (chatModel == null) {
            log.warn("ChatModel 未初始化，返回空决策");
            return null;
        }

        // 构建用户消息
        String userMessage = buildDecisionMessage(context, decisionPoint, lessonsLearned, currentBattleLog, attemptCount, todoList, tips, forbiddenActions);

        System.out.println("\n========== AI Decision User Prompt ==========");
        System.out.println(userMessage);
        System.out.println("==============================================");

        try {
            // 调用 LLM
            List<Message> messages = new ArrayList<>();
            messages.add(new SystemMessage(AI_DECISION_SYSTEM_PROMPT));
            messages.add(new UserMessage(userMessage));

            Prompt prompt = new Prompt(messages);
            ChatResponse response = chatModel.call(prompt);

            String content = response.getResult().getOutput().getText();

            // 解析响应
            return parseDecisionResponse(content);

        } catch (Exception e) {
            log.error("LLM 调用失败", e);
            return null;
        }
    }

    /**
     * 构建决策消息
     */
    private String buildDecisionMessage(
            BattleContext context,
            DecisionPoint decisionPoint,
            List<String> lessonsLearned,
            String currentBattleLog,
            int attemptCount,
            List<TodoItem> todoList,
            String tips,
            List<String> forbiddenActions) {

        StringBuilder sb = new StringBuilder();

        // 战斗模式
        sb.append("## 战斗模式\n");
        sb.append(context.isDoubles() ? "双打" : "单打").append("\n\n");

        // 当前回合和尝试次数
        sb.append("## 当前回合: ").append(context.getTurn()).append("\n");
        sb.append("## 尝试次数: ").append(attemptCount + 1).append("\n\n");

        // ==================== 任务系统 ====================
        if (todoList != null && !todoList.isEmpty()) {
            // 过滤掉已完成的任务
            List<TodoItem> pendingTasks = todoList.stream()
                    .filter(item -> !item.isCompleted())
                    .toList();
            if (!pendingTasks.isEmpty()) {
                sb.append("## 当前任务（按优先级执行）\n");
                for (TodoItem item : pendingTasks) {
                    sb.append("- ").append(item.getDescription()).append(" (优先级:").append(item.getPriority()).append(")\n");
                }
                sb.append("\n");
            }
        }

        if (tips != null && !tips.isEmpty()) {
            sb.append("## 战斗提示\n").append(tips).append("\n\n");
        }

        if (forbiddenActions != null && !forbiddenActions.isEmpty()) {
            sb.append("## 禁止行为（触犯将直接判负）\n");
            for (String action : forbiddenActions) {
                sb.append("- ").append(action).append("\n");
            }
            sb.append("\n");
        }

        // 注入战报日志
        if (currentBattleLog != null && !currentBattleLog.isEmpty()) {
            sb.append("## 最近战报\n");
            sb.append("（注：战报中的 'I' 是宝可梦昵称，不是代词'我'）\n");
            sb.append("```\n");
            sb.append(currentBattleLog);
            sb.append("\n```\n\n");
        }

        // ==================== 场上宝可梦 ====================
        sb.append("## 我方场上宝可梦\n");
        for (PokemonState p : context.getMyActive()) {
            if (p != null && p.isAlive()) {
                sb.append(formatPokemonFull(p, true));
            }
        }
        sb.append("\n");

        sb.append("## 敌方场上宝可梦\n");
        for (PokemonState p : context.getEnemyActive()) {
            if (p != null && p.isAlive()) {
                sb.append(formatPokemonFull(p, false));
            }
        }
        sb.append("\n");

        // ==================== 我方完整队伍 ====================
        sb.append("## 我方完整队伍\n");
        for (PokemonState p : context.getMyParty()) {
            if (p != null && !p.isEgg()) {
                sb.append(formatPokemonFull(p, true));
            }
        }
        sb.append("\n");

        // ==================== 敌方已知队伍 ====================
        if (context.getEnemyParty() != null && !context.getEnemyParty().isEmpty()) {
            sb.append("## 敌方已知队伍\n");
            for (PokemonState p : context.getEnemyParty()) {
                if (p != null) {
                    sb.append(formatPokemonFull(p, false));
                }
            }
            sb.append("\n");
        }

        // 经验教训
        if (lessonsLearned != null && !lessonsLearned.isEmpty()) {
            sb.append("## 历史经验教训（请避免重复错误）\n");
            for (String lesson : lessonsLearned) {
                sb.append("- ").append(lesson).append("\n");
            }
            sb.append("\n");
        }

        // 决策点类型
        sb.append("## 当前决策点\n");
        sb.append(decisionPoint != null ? decisionPoint.name() : "TURN_START").append("\n");

        if (decisionPoint == DecisionPoint.FORCE_SWITCH) {
            sb.append("\n**注意：当前需要濒死替换，只能选择替换操作**\n");
        }

        return sb.toString();
    }

    /**
     * 格式化宝可梦完整信息
     * @param p 宝可梦状态
     * @param isMyPokemon 是否是我方宝可梦（我方显示更多信息）
     */
    private String formatPokemonFull(PokemonState p, boolean isMyPokemon) {
        StringBuilder sb = new StringBuilder();

        // 基本信息：位置、种类、等级
        sb.append("**").append(p.getSlot()).append(". ").append(p.getSpecies());
        if (p.getLevel() > 0) {
            sb.append(" Lv.").append(p.getLevel());
        }
        sb.append("**");

        // 状态标记
        if (p.isActive()) {
            sb.append(" [场上]");
        }
        if (p.isFainted()) {
            sb.append(" [濒死]");
        } else if (!p.isAlive()) {
            sb.append(" [HP耗尽]");
        }

        sb.append("\n");

        // HP 信息
        sb.append("   HP: ").append(p.getCurrentHp()).append("/").append(p.getMaxHp());
        if (p.getMaxHp() > 0) {
            sb.append(" (").append(String.format("%.1f", p.getHpPercent())).append("%)");
        }

        // 状态异常
        if (p.getStatus() != null && !"none".equals(p.getStatus()) && !"null".equals(p.getStatus())) {
            sb.append(" | 状态: ").append(formatStatus(p.getStatus()));
        }
        sb.append("\n");

        // 能力变化（只显示非零的）
        if (p.getBoosts() != null && !p.getBoosts().isEmpty()) {
            List<String> boostStrs = new ArrayList<>();
            for (Map.Entry<String, Integer> entry : p.getBoosts().entrySet()) {
                if (entry.getValue() != 0) {
                    boostStrs.add(formatBoost(entry.getKey(), entry.getValue()));
                }
            }
            if (!boostStrs.isEmpty()) {
                sb.append("   能力: ").append(String.join(", ", boostStrs)).append("\n");
            }
        }

        // 招式列表（我方显示完整，敌方显示已知）
        if (isMyPokemon && p.getMoves() != null && !p.getMoves().isEmpty()) {
            sb.append("   招式: ");
            List<String> moveStrs = new ArrayList<>();
            for (MoveInfo m : p.getMoves()) {
                String moveStr = m.getName();
                if (m.getCurrentPp() >= 0) {
                    moveStr += " (PP:" + m.getCurrentPp() + "/" + m.getMaxPp() + ")";
                }
                if (!m.isUsable()) {
                    moveStr += "[不可用]";
                }
                moveStrs.add(moveStr);
            }
            sb.append(String.join(", ", moveStrs)).append("\n");
        } else if (!isMyPokemon && p.getMoves() != null && !p.getMoves().isEmpty()) {
            // 敌方只显示已知招式
            sb.append("   已知招式: ");
            List<String> moveStrs = new ArrayList<>();
            for (MoveInfo m : p.getMoves()) {
                moveStrs.add(m.getName());
            }
            sb.append(String.join(", ", moveStrs)).append("\n");
        }

        // 道具和特性
        if (p.getItem() != null && !p.getItem().isEmpty()) {
            sb.append("   道具: ").append(p.getItem()).append("\n");
        }
        if (p.getAbility() != null && !p.getAbility().isEmpty()) {
            sb.append("   特性: ").append(p.getAbility()).append("\n");
        }

        return sb.toString();
    }

    /**
     * 格式化状态异常
     */
    private String formatStatus(String status) {
        return switch (status.toLowerCase()) {
            case "par" -> "麻痹";
            case "psn" -> "中毒";
            case "tox" -> "剧毒";
            case "brn" -> "灼伤";
            case "frz" -> "冰冻";
            case "slp" -> "睡眠";
            default -> status;
        };
    }

    /**
     * 格式化能力变化
     */
    private String formatBoost(String stat, int value) {
        String statName = switch (stat.toLowerCase()) {
            case "atk" -> "攻击";
            case "def" -> "防御";
            case "spa" -> "特攻";
            case "spd" -> "特防";
            case "spe" -> "速度";
            case "acc" -> "命中";
            case "eva" -> "闪避";
            default -> stat;
        };
        String sign = value > 0 ? "+" : "";
        return statName + sign + value;
    }

    /**
     * 解析决策响应
     */
    private AIDecisionResult parseDecisionResponse(String content) {
        String jsonStr = extractJsonFromResponse(content);
        if (jsonStr == null) {
            return null;
        }

        try {
            JSONObject json = JSON.parseObject(jsonStr);

            AIDecisionResult result = new AIDecisionResult();
            result.reasoning = json.getString("reasoning");

            String type = json.getString("type");
            int slot = json.getIntValue("slot");
            Integer target = json.getInteger("target");
            String moveName = json.getString("moveName");

            GameAction action = null;
            if ("move".equalsIgnoreCase(type)) {
                action = GameAction.move(slot, target, moveName);
            } else if ("switch".equalsIgnoreCase(type)) {
                action = GameAction.switchAction(slot);
            }

            if (action != null) {
                action.setReason(result.reasoning);
                result.action = action;
            }

            return result;

        } catch (Exception e) {
            log.warn("决策响应解析失败: {}", e.getMessage());
            return null;
        }
    }

    // ==================== 失败分析 ====================

    /**
     * 分析失败原因，生成经验教训
     *
     * @param contextHistory 战斗上下文历史
     * @param logHistory 战报历史
     * @param previousLessons 之前的教训
     * @param attemptCount 尝试次数
     * @return 失败分析结果（包含经验教训）
     */
    public FailureAnalysisResult analyzeFailure(
            List<BattleContext> contextHistory,
            List<String> logHistory,
            List<String> previousLessons,
            int attemptCount) {

        if (chatModel == null) {
            log.warn("ChatModel 未初始化，返回空分析");
            return null;
        }

        // 构建用户消息
        String userMessage = buildFailureAnalysisMessage(contextHistory, logHistory, previousLessons, attemptCount);

        log.info("\n========== Failure Analysis User Prompt ==========\n{}\n==================================================",
                userMessage.length() > 500 ? userMessage.substring(0, 500) + "..." : userMessage);

        try {
            // 调用 LLM
            List<Message> messages = new ArrayList<>();
            messages.add(new SystemMessage(FAILURE_ANALYSIS_SYSTEM_PROMPT));
            messages.add(new UserMessage(userMessage));

            Prompt prompt = new Prompt(messages);
            ChatResponse response = chatModel.call(prompt);

            String content = response.getResult().getOutput().getText();
            log.info("[EmulatorLLMService] 失败分析响应:\n{}", content);

            // 解析响应
            return parseFailureAnalysisResponse(content);

        } catch (Exception e) {
            log.error("失败分析 LLM 调用失败", e);
            return null;
        }
    }

    /**
     * 构建失败分析消息
     */
    private String buildFailureAnalysisMessage(
            List<BattleContext> contextHistory,
            List<String> logHistory,
            List<String> previousLessons,
            int attemptCount) {

        StringBuilder sb = new StringBuilder();

        sb.append("## 尝试次数: ").append(attemptCount).append("\n\n");

        // 我方完整队伍（从第一个上下文获取）
        if (contextHistory != null && !contextHistory.isEmpty()) {
            BattleContext firstCtx = contextHistory.get(0);
            sb.append("## 我方完整后备\n");
            for (PokemonState p : firstCtx.getMyParty()) {
                if (p != null && !p.isEgg()) {
                    sb.append("- ").append(p.getSpecies())
                      .append(" HP:").append(p.getCurrentHp()).append("/").append(p.getMaxHp());
                    if (p.getMoves() != null && !p.getMoves().isEmpty()) {
                        sb.append(" 招式:");
                        for (MoveInfo m : p.getMoves()) {
                            sb.append(m.getName()).append(" ");
                        }
                    }
                    sb.append("\n");
                }
            }
            sb.append("\n");
        }

        // 每回合战斗状态
        if (contextHistory != null && !contextHistory.isEmpty()) {
            sb.append("## 每回合战斗状态\n");
            for (int i = 0; i < contextHistory.size(); i++) {
                BattleContext ctx = contextHistory.get(i);
                sb.append("### 回合 ").append(i+1).append("\n");
                sb.append("我方场上:\n");
                for (PokemonState p : ctx.getMyActive()) {
                    if (p != null && p.isAlive()) {
                        sb.append("- ").append(p.getSpecies())
                          .append(" HP:").append(p.getCurrentHp()).append("/").append(p.getMaxHp());
                        if (p.getStatus() != null && !"none".equals(p.getStatus())) {
                            sb.append(" 状态:").append(p.getStatus());
                        }
                        sb.append("\n");
                    }
                }
                sb.append("敌方场上:\n");
                for (PokemonState p : ctx.getEnemyActive()) {
                    if (p != null && p.isAlive()) {
                        sb.append("- ").append(p.getSpecies())
                          .append(" HP:").append(p.getCurrentHp()).append("/").append(p.getMaxHp());
                        if (p.getStatus() != null && !"none".equals(p.getStatus())) {
                            sb.append(" 状态:").append(p.getStatus());
                        }
                        sb.append("\n");
                    }
                }
                sb.append("\n");
            }
        }

        // 战报
        if (logHistory != null && !logHistory.isEmpty()) {
            sb.append("## 战报\n");
            for (String log : logHistory) {
                if (log != null && !log.isEmpty()) {
                    sb.append(log).append("\n");
                }
            }
            sb.append("\n");
        }

        // 之前的教训
        if (previousLessons != null && !previousLessons.isEmpty()) {
            sb.append("## 已知教训（避免重复）\n");
            for (String lesson : previousLessons) {
                sb.append("- ").append(lesson).append("\n");
            }
            sb.append("\n");
        }

        sb.append("请分析失败原因。");

        return sb.toString();
    }

    /**
     * 解析失败分析响应
     */
    private FailureAnalysisResult parseFailureAnalysisResponse(String content) {
        String jsonStr = extractJsonFromResponse(content);
        if (jsonStr == null) {
            return null;
        }

        try {
            JSONObject json = JSON.parseObject(jsonStr);

            FailureAnalysisResult result = new FailureAnalysisResult();
            result.analysis = json.getString("analysis");

            JSONArray lessonsArray = json.getJSONArray("lessons");
            if (lessonsArray != null) {
                result.lessons = new ArrayList<>();
                for (int i = 0; i < lessonsArray.size(); i++) {
                    result.lessons.add(lessonsArray.getString(i));
                }
            }

            return result;

        } catch (Exception e) {
            log.warn("失败分析响应解析失败: {}", e.getMessage());
            return null;
        }
    }

    // ==================== 战斗总结 ====================

    /**
     * 生成战斗总结报告
     *
     * @param isVictory 是否胜利
     * @param attemptCount 尝试次数
     * @param resultHistory 结果历史
     * @param lessonsLearned 经验教训
     * @param decisionHistory 决策历史
     * @return 总结报告
     */
    public String generateSummary(
            boolean isVictory,
            int attemptCount,
            List<String> resultHistory,
            List<String> lessonsLearned,
            List<GameAction> decisionHistory) {

        if (chatModel == null) {
            log.warn("ChatModel 未初始化，返回默认总结");
            return buildDefaultSummary(isVictory, attemptCount, resultHistory, lessonsLearned);
        }

        // 根据胜负选择提示词
        String systemPrompt = isVictory ? VICTORY_SUMMARY_SYSTEM_PROMPT : DEFEAT_SUMMARY_SYSTEM_PROMPT;

        // 构建用户消息
        String userMessage = buildSummaryMessage(isVictory, attemptCount, resultHistory, lessonsLearned, decisionHistory);

        log.info("\n========== Summary User Prompt ==========\n{}\n==========================================",
                userMessage.length() > 300 ? userMessage.substring(0, 300) + "..." : userMessage);

        try {
            List<Message> messages = new ArrayList<>();
            messages.add(new SystemMessage(systemPrompt));
            messages.add(new UserMessage(userMessage));

            Prompt prompt = new Prompt(messages);
            ChatResponse response = chatModel.call(prompt);

            return response.getResult().getOutput().getText();

        } catch (Exception e) {
            log.error("总结 LLM 调用失败", e);
            return buildDefaultSummary(isVictory, attemptCount, resultHistory, lessonsLearned);
        }
    }

    /**
     * 构建总结消息
     */
    private String buildSummaryMessage(
            boolean isVictory,
            int attemptCount,
            List<String> resultHistory,
            List<String> lessonsLearned,
            List<GameAction> decisionHistory) {

        StringBuilder sb = new StringBuilder();

        sb.append("## 战斗数据\n");
        sb.append("- 最终结果: ").append(isVictory ? "胜利" : "失败").append("\n");
        sb.append("- 尝试次数: ").append(attemptCount).append("\n");
        sb.append("- 决策总数: ").append(decisionHistory != null ? decisionHistory.size() : 0).append("\n\n");

        // 尝试历史
        if (resultHistory != null && !resultHistory.isEmpty()) {
            sb.append("## 尝试历程\n");
            for (String history : resultHistory) {
                sb.append("- ").append(history).append("\n");
            }
            sb.append("\n");
        }

        // 经验教训
        if (lessonsLearned != null && !lessonsLearned.isEmpty()) {
            sb.append("## 经验教训汇总\n");
            for (int i = 0; i < lessonsLearned.size(); i++) {
                sb.append(i + 1).append(". ").append(lessonsLearned.get(i)).append("\n");
            }
            sb.append("\n");
        }

        sb.append("请根据以上数据生成战斗总结报告。");

        return sb.toString();
    }

    /**
     * 构建默认总结
     */
    private String buildDefaultSummary(
            boolean isVictory,
            int attemptCount,
            List<String> resultHistory,
            List<String> lessonsLearned) {

        StringBuilder sb = new StringBuilder();
        sb.append("# 战斗总结\n\n");

        sb.append("## 最终结果\n");
        sb.append(isVictory ? "胜利" : "失败").append("\n\n");

        sb.append("## 统计数据\n");
        sb.append("- 尝试次数: ").append(attemptCount).append("\n");

        if (lessonsLearned != null && !lessonsLearned.isEmpty()) {
            sb.append("- 经验教训数: ").append(lessonsLearned.size()).append("\n");
        }

        return sb.toString();
    }

    // ==================== 任务检查 ====================

    private static final String TASK_CHECK_SYSTEM_PROMPT = """
            你是战斗分析师，请分析当前局势并更新任务列表。

            ## 任务类型说明
            - **一次性任务**：如"击杀敌方XX"，完成后保持完成状态
            - **持续性任务**：如"保持HP在50%以上"，需要持续满足条件，不满足时标记为未完成

            ## 状态更新规则
            - 已完成的持续性任务，如果条件不再满足，必须变更为未完成
            - 已完成的任务，如果后续战报显示条件被破坏（如HP跌破阈值），标记为未完成

            ## 输出格式（JSON）
            ```json
            {
              "updatedTodos": [
                {"id": "1", "completed": true, "reason": "敌方Tropius已被击败"},
                {"id": "2", "completed": false, "reason": "Swampert HP已降至40%"}
              ],
              "forbidden": false,
              "forbiddenReason": null,
              "analysis": "简要分析当前局势"
            }
            ```
            """;

    /**
     * 检查任务完成情况
     *
     * @param context 战斗上下文
     * @param battleLog 战报
     * @param todoList 任务列表
     * @param forbiddenActions 禁止行为
     * @return 任务检查结果
     */
    public TaskCheckResult checkTaskCompletion(
            BattleContext context,
            String battleLog,
            List<TodoItem> todoList,
            List<String> forbiddenActions) {

        if (chatModel == null) {
            log.warn("ChatModel 未初始化，返回空结果");
            return null;
        }

        String userMessage = buildTaskCheckMessage(context, battleLog, todoList, forbiddenActions);

        //System.out.println("\n========== Task Check User Prompt ==========");
        //System.out.println(userMessage);
        //System.out.println("=============================================");

        try {
            List<Message> messages = new ArrayList<>();
            messages.add(new SystemMessage(TASK_CHECK_SYSTEM_PROMPT));
            messages.add(new UserMessage(userMessage));

            Prompt prompt = new Prompt(messages);
            ChatResponse response = chatModel.call(prompt);

            String content = response.getResult().getOutput().getText();

            return parseTaskCheckResponse(content, todoList);

        } catch (Exception e) {
            log.error("任务检查 LLM 调用失败", e);
            return null;
        }
    }

    /**
     * 构建任务检查消息
     */
    private String buildTaskCheckMessage(
            BattleContext context,
            String battleLog,
            List<TodoItem> todoList,
            List<String> forbiddenActions) {

        StringBuilder sb = new StringBuilder();

        // ==================== 场上宝可梦（完整信息）====================
        sb.append("## 我方场上宝可梦\n");
        for (PokemonState p : context.getMyActive()) {
            if (p != null && p.isAlive()) {
                sb.append(formatPokemonFull(p, true));
            }
        }
        sb.append("\n");

        sb.append("## 敌方场上宝可梦\n");
        for (PokemonState p : context.getEnemyActive()) {
            if (p != null && p.isAlive()) {
                sb.append(formatPokemonFull(p, false));
            }
        }
        sb.append("\n");

        // ==================== 我方完整队伍 ====================
        sb.append("## 我方完整队伍\n");
        for (PokemonState p : context.getMyParty()) {
            if (p != null && !p.isEgg()) {
                sb.append(formatPokemonFull(p, true));
            }
        }
        sb.append("\n");

        // ==================== 敌方已知队伍 ====================
        if (context.getEnemyParty() != null && !context.getEnemyParty().isEmpty()) {
            sb.append("## 敌方已知队伍\n");
            for (PokemonState p : context.getEnemyParty()) {
                if (p != null) {
                    sb.append(formatPokemonFull(p, false));
                }
            }
            sb.append("\n");
        }

        // 战报
        if (battleLog != null && !battleLog.isEmpty()) {
            sb.append("## 最近战报\n```\n").append(battleLog).append("\n```\n\n");
        }

        // 任务列表
        sb.append("## 当前任务列表\n");
        for (TodoItem item : todoList) {
            sb.append("- ").append(item.getId()).append(". ")
              .append(item.getDescription())
              .append(" [").append(item.isCompleted() ? "已完成" : "进行中").append("]\n");
        }
        sb.append("\n");

        // 禁止行为
        sb.append("## 禁止行为\n");
        for (String action : forbiddenActions) {
            sb.append("- ").append(action).append("\n");
        }
        sb.append("\n");

        sb.append("请根据当前战报和场上状态，更新每个任务的完成状态。\n");
        sb.append("注意：持续性任务（如保持HP）如果不满足条件，需要标记为未完成。");

        return sb.toString();
    }

    /**
     * 解析任务检查响应
     */
    private TaskCheckResult parseTaskCheckResponse(String content, List<TodoItem> originalList) {
        String jsonStr = extractJsonFromResponse(content);
        if (jsonStr == null) {
            return null;
        }

        try {
            JSONObject json = JSON.parseObject(jsonStr);

            TaskCheckResult result = new TaskCheckResult();
            result.forbidden = json.getBooleanValue("forbidden");
            result.forbiddenReason = json.getString("forbiddenReason");
            result.analysis = json.getString("analysis");

            // 更新 todo list
            JSONArray updatedTodos = json.getJSONArray("updatedTodos");
            if (updatedTodos != null) {
                Map<String, Boolean> completedMap = new HashMap<>();
                Map<String, String> reasonMap = new HashMap<>();
                for (int i = 0; i < updatedTodos.size(); i++) {
                    JSONObject todoJson = updatedTodos.getJSONObject(i);
                    String id = todoJson.getString("id");
                    completedMap.put(id, todoJson.getBooleanValue("completed"));
                    if (todoJson.containsKey("reason")) {
                        reasonMap.put(id, todoJson.getString("reason"));
                    }
                }

                List<TodoItem> newTodoList = new ArrayList<>();
                for (TodoItem item : originalList) {
                    boolean newCompleted = completedMap.getOrDefault(item.getId(), item.isCompleted());

                    // 记录状态变化
                    if (item.isCompleted() && !newCompleted) {
                        log.info("[TaskCheck] 任务 '{}' 从已完成变为未完成: {}",
                                item.getId(), reasonMap.getOrDefault(item.getId(), "条件不再满足"));
                    } else if (!item.isCompleted() && newCompleted) {
                        log.info("[TaskCheck] 任务 '{}' 已完成: {}",
                                item.getId(), reasonMap.getOrDefault(item.getId(), "条件已满足"));
                    }

                    TodoItem newItem = new TodoItem(item.getId(), item.getDescription(), item.getPriority(), newCompleted);
                    newTodoList.add(newItem);
                }
                result.updatedTodos = newTodoList;
            }

            return result;

        } catch (Exception e) {
            log.warn("任务检查响应解析失败: {}", e.getMessage());
            return null;
        }
    }

    // ==================== 工具方法 ====================

    /**
     * 从响应中提取 JSON
     */
    private String extractJsonFromResponse(String response) {
        if (response == null) return null;

        // 尝试提取 ```json ``` 代码块
        Pattern jsonBlockPattern = Pattern.compile(
                "```json\\s*\\n?([\\s\\S]*?)\\n?```",
                Pattern.CASE_INSENSITIVE
        );
        Matcher matcher = jsonBlockPattern.matcher(response);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }

        // 尝试提取 { }
        int start = response.indexOf('{');
        int end = response.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return response.substring(start, end + 1);
        }

        return null;
    }

    /**
     * 检查服务是否可用
     */
    public boolean isAvailable() {
        return chatModel != null;
    }

    // ==================== 结果类 ====================

    /**
     * AI 决策结果
     */
    public static class AIDecisionResult {
        public GameAction action;
        public String reasoning;

        public static AIDecisionResult of(GameAction action, String reasoning) {
            AIDecisionResult result = new AIDecisionResult();
            result.action = action;
            result.reasoning = reasoning;
            return result;
        }
    }

    /**
     * 失败分析结果
     */
    public static class FailureAnalysisResult {
        public List<String> lessons;
        public String analysis;
        public String priority;

        public static FailureAnalysisResult of(List<String> lessons, String analysis) {
            FailureAnalysisResult result = new FailureAnalysisResult();
            result.lessons = lessons;
            result.analysis = analysis;
            return result;
        }
    }

    /**
     * 任务检查结果
     */
    public static class TaskCheckResult {
        public List<TodoItem> updatedTodos;
        public boolean forbidden;
        public String forbiddenReason;
        public String analysis;
    }
}
