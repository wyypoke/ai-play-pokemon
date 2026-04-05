package com.xiaobaozi.ai_play_pokemon.graph.model;

/**
 * 模拟器战斗图状态键常量
 *
 * 用于 OverAllState 中存储和检索数据
 */
public final class EmulatorStateKeys {

    private EmulatorStateKeys() {
        // 工具类，禁止实例化
    }

    // ==================== 模拟器配置 ====================

    /**
     * 初始存档文件名
     */
    public static final String INITIAL_SAVE_FILE = "initial_save_file";

    /**
     * 初始存档状态（用于重置）
     */
    public static final String INITIAL_STATE = "initial_state";

    /**
     * 当前存档状态
     */
    public static final String CURRENT_STATE = "current_state";

    // ==================== 战斗状态 ====================

    /**
     * 当前回合数
     */
    public static final String TURN = "turn";

    /**
     * 决策计数（总共执行的决策数）
     */
    public static final String DECISION_COUNT = "decision_count";

    /**
     * 战斗上下文
     */
    public static final String BATTLE_CONTEXT = "battle_context";

    /**
     * 战斗上下文历史（每回合）
     */
    public static final String BATTLE_CONTEXT_HISTORY = "battle_context_history";

    /**
     * 当前决策点
     */
    public static final String DECISION_POINT = "decision_point";

    /**
     * 战斗是否结束
     */
    public static final String BATTLE_ENDED = "battle_ended";

    /**
     * 战斗结果（victory/defeat/limit_reached）
     */
    public static final String BATTLE_RESULT = "battle_result";

    /**
     * 胜者
     */
    public static final String WINNER = "winner";

    // ==================== 决策相关 ====================

    /**
     * AI 决策
     */
    public static final String AI_DECISION = "ai_decision";

    /**
     * 决策历史记录
     */
    public static final String DECISION_HISTORY = "decision_history";

    /**
     * 战报历史
     */
    public static final String BATTLE_LOG_HISTORY = "battle_log_history";

    /**
     * 当前战报
     */
    public static final String CURRENT_BATTLE_LOG = "current_battle_log";

    // ==================== 学习循环 ====================

    /**
     * 尝试次数（重置读档的次数）
     */
    public static final String ATTEMPT_COUNT = "attempt_count";

    /**
     * 经验教训列表
     */
    public static final String LESSONS_LEARNED = "lessons_learned";

    /**
     * 本次尝试的经验教训
     */
    public static final String CURRENT_LESSONS = "current_lessons";

    /**
     * 是否需要重新尝试
     */
    public static final String NEED_RETRY = "need_retry";

    /**
     * 历史战斗结果
     */
    public static final String BATTLE_RESULT_HISTORY = "battle_result_history";

    // ==================== 配置 ====================

    /**
     * 最大决策数限制
     */
    public static final String MAX_DECISIONS = "max_decisions";

    /**
     * 最大尝试次数
     */
    public static final String MAX_ATTEMPTS = "max_attempts";

    /**
     * 目标胜利方（p1/p2）
     */
    public static final String TARGET_WINNER = "target_winner";

    // ==================== 控制流 ====================

    /**
     * 下一个节点
     */
    public static final String NEXT_NODE = "next_node";

    /**
     * 是否胜利
     */
    public static final String IS_VICTORY = "is_victory";

    /**
     * 分析总结
     */
    public static final String ANALYSIS_SUMMARY = "analysis_summary";

    /**
     * LLM 调用重试次数
     */
    public static final String LLM_RETRY_COUNT = "llm_retry_count";

    /**
     * LLM 调用失败
     */
    public static final String LLM_FAILED = "llm_failed";

    /**
     * LLM 最大重试次数
     */
    public static final int MAX_LLM_RETRIES = 3;

    // ==================== 任务系统 ====================

    /**
     * 任务列表
     */
    public static final String TODO_LIST = "todo_list";

    /**
     * 战斗提示
     */
    public static final String TIPS = "tips";

    /**
     * 禁止行为列表
     */
    public static final String FORBIDDEN_ACTIONS = "forbidden_actions";

    /**
     * 是否检测到禁止行为
     */
    public static final String FORBIDDEN_DETECTED = "forbidden_detected";

    // ==================== 默认值 ====================

    /**
     * 默认最大决策数
     */
    public static final int DEFAULT_MAX_DECISIONS = 500;

    /**
     * 默认最大尝试次数
     */
    public static final int DEFAULT_MAX_ATTEMPTS = 10;

    /**
     * 默认目标胜利方
     */
    public static final String DEFAULT_TARGET_WINNER = "p1";
}
