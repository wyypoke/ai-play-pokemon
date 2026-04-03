package com.xiaobaozi.ai_play_pokemon.emulator.exception;

/**
 * 模拟器异常类
 */
public class EmulatorException extends RuntimeException {

    /**
     * 错误码
     */
    private final ErrorCode errorCode;

    /**
     * 详细信息
     */
    private final String details;

    // ==================== 错误码枚举 ====================

    public enum ErrorCode {
        /**
         * 连接失败
         */
        CONNECTION_FAILED("E001", "无法连接到模拟器服务器"),

        /**
         * 超时
         */
        TIMEOUT("E002", "操作超时"),

        /**
         * 操作失败
         */
        ACTION_FAILED("E003", "操作执行失败"),

        /**
         * 状态错误
         */
        INVALID_STATE("E004", "无效的游戏状态"),

        /**
         * 存档错误
         */
        SAVE_ERROR("E005", "存档操作失败"),

        /**
         * 响应解析错误
         */
        PARSE_ERROR("E006", "响应解析失败"),

        /**
         * 未知错误
         */
        UNKNOWN("E999", "未知错误");

        private final String code;
        private final String message;

        ErrorCode(String code, String message) {
            this.code = code;
            this.message = message;
        }

        public String getCode() {
            return code;
        }

        public String getMessage() {
            return message;
        }
    }

    // ==================== 构造函数 ====================

    public EmulatorException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
        this.details = null;
    }

    public EmulatorException(ErrorCode errorCode, String details) {
        super(errorCode.getMessage() + ": " + details);
        this.errorCode = errorCode;
        this.details = details;
    }

    public EmulatorException(ErrorCode errorCode, String details, Throwable cause) {
        super(errorCode.getMessage() + ": " + details, cause);
        this.errorCode = errorCode;
        this.details = details;
    }

    public EmulatorException(ErrorCode errorCode, Throwable cause) {
        super(errorCode.getMessage(), cause);
        this.errorCode = errorCode;
        this.details = cause.getMessage();
    }

    // ==================== 静态工厂方法 ====================

    public static EmulatorException connectionFailed(String details) {
        return new EmulatorException(ErrorCode.CONNECTION_FAILED, details);
    }

    public static EmulatorException timeout(String details) {
        return new EmulatorException(ErrorCode.TIMEOUT, details);
    }

    public static EmulatorException actionFailed(String details) {
        return new EmulatorException(ErrorCode.ACTION_FAILED, details);
    }

    public static EmulatorException invalidState(String details) {
        return new EmulatorException(ErrorCode.INVALID_STATE, details);
    }

    public static EmulatorException saveError(String details) {
        return new EmulatorException(ErrorCode.SAVE_ERROR, details);
    }

    public static EmulatorException parseError(String details) {
        return new EmulatorException(ErrorCode.PARSE_ERROR, details);
    }

    public static EmulatorException unknown(String details) {
        return new EmulatorException(ErrorCode.UNKNOWN, details);
    }

    // ==================== Getter ====================

    public ErrorCode getErrorCode() {
        return errorCode;
    }

    public String getDetails() {
        return details;
    }

    public String getFullMessage() {
        if (details != null) {
            return String.format("[%s] %s: %s", errorCode.getCode(), errorCode.getMessage(), details);
        }
        return String.format("[%s] %s", errorCode.getCode(), errorCode.getMessage());
    }
}
