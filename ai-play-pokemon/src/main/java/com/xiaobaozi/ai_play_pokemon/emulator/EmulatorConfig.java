package com.xiaobaozi.ai_play_pokemon.emulator;

/**
 * 模拟器配置类
 */
public class EmulatorConfig {

    /**
     * Lua 服务器 URL
     */
    private String serverUrl = "http://localhost:8080";

    /**
     * 请求超时（毫秒）
     */
    private int timeout = 30000;

    /**
     * 存档路径
     */
    private String savePath = "./saves/";

    /**
     * 连接重试次数
     */
    private int retryCount = 3;

    /**
     * 重试间隔（毫秒）
     */
    private int retryInterval = 1000;

    // ==================== 构造函数 ====================

    public EmulatorConfig() {
    }

    public EmulatorConfig(String serverUrl) {
        this.serverUrl = serverUrl;
    }

    // ==================== Builder 模式 ====================

    public static EmulatorConfigBuilder builder() {
        return new EmulatorConfigBuilder();
    }

    public static class EmulatorConfigBuilder {
        private String serverUrl = "http://localhost:8080";
        private int timeout = 30000;
        private String savePath = "./saves/";
        private int retryCount = 3;
        private int retryInterval = 1000;

        public EmulatorConfigBuilder serverUrl(String serverUrl) {
            this.serverUrl = serverUrl;
            return this;
        }

        public EmulatorConfigBuilder timeout(int timeout) {
            this.timeout = timeout;
            return this;
        }

        public EmulatorConfigBuilder savePath(String savePath) {
            this.savePath = savePath;
            return this;
        }

        public EmulatorConfigBuilder retryCount(int retryCount) {
            this.retryCount = retryCount;
            return this;
        }

        public EmulatorConfigBuilder retryInterval(int retryInterval) {
            this.retryInterval = retryInterval;
            return this;
        }

        public EmulatorConfig build() {
            EmulatorConfig config = new EmulatorConfig();
            config.serverUrl = this.serverUrl;
            config.timeout = this.timeout;
            config.savePath = this.savePath;
            config.retryCount = this.retryCount;
            config.retryInterval = this.retryInterval;
            return config;
        }
    }

    // ==================== Getter/Setter ====================

    public String getServerUrl() {
        return serverUrl;
    }

    public void setServerUrl(String serverUrl) {
        this.serverUrl = serverUrl;
    }

    public int getTimeout() {
        return timeout;
    }

    public void setTimeout(int timeout) {
        this.timeout = timeout;
    }

    public String getSavePath() {
        return savePath;
    }

    public void setSavePath(String savePath) {
        this.savePath = savePath;
    }

    public int getRetryCount() {
        return retryCount;
    }

    public void setRetryCount(int retryCount) {
        this.retryCount = retryCount;
    }

    public int getRetryInterval() {
        return retryInterval;
    }

    public void setRetryInterval(int retryInterval) {
        this.retryInterval = retryInterval;
    }

    @Override
    public String toString() {
        return String.format("EmulatorConfig{serverUrl='%s', timeout=%d, savePath='%s', retryCount=%d}",
                serverUrl, timeout, savePath, retryCount);
    }
}
