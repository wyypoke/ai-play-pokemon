-- Pokemon Emerald AI Server - Main Entry
-- BizHawk Lua 脚本，通过 CPU 寄存器操作调用 ROM 内的 AI 函数
--
-- 使用方法：
-- 1. 在 BizHawk 中加载 pokeemerald.gba
-- 2. 进入游戏，开始一场战斗
-- 3. 运行此脚本
-- 4. 通过 HTTP API 访问 AI 决策

-- 全局对象
AIServer = {}

-- 加载模块
local Config = require("config")
local AICaller = require("ai_caller")
local Server = require("server")

-- ============================================================================
--                           初始化
-- ============================================================================

function AIServer.initialize()
    console.log("========================================")
    console.log("  Pokemon Emerald AI Server v1.0")
    console.log("========================================")
    console.log("")

    -- 创建 AI 调用器
    AIServer.aiCaller = AICaller:new()
    if not AIServer.aiCaller:init() then
        console.log("Failed to initialize AI Caller")
        return false
    end

    -- 测试 CPU 寄存器 API
    console.log("")
    console.log("Testing CPU Register API...")
    local cpuOK = AIServer.aiCaller:testCPUAPI()

    if not cpuOK then
        console.log("")
        console.log("WARNING: CPU Register API not available!")
        console.log("AI function calls will not work.")
        console.log("You can still use the server to read battle state.")
    end

    -- 创建服务器
    console.log("")
    console.log("Starting HTTP Server...")
    AIServer.server = Server:new(AIServer.aiCaller)
    if not AIServer.server:start() then
        console.log("Failed to start server")
        return false
    end

    console.log("")
    console.log("=== Server Ready ===")
    console.log("")

    return true
end

-- ============================================================================
--                           主循环
-- ============================================================================

function AIServer.update()
    -- 更新服务器
    if AIServer.server then
        AIServer.server:update()
    end
end

function AIServer.shutdown()
    console.log("Shutting down...")

    if AIServer.server then
        AIServer.server:stop()
    end

    console.log("Goodbye!")
end

-- ============================================================================
--                           用户命令
-- ============================================================================

-- 帮助
function help()
    console.log("")
    console.log("=== Available Commands ===")
    console.log("help()           - Show this help")
    console.log("status()         - Show server status")
    console.log("battle()         - Read current battle state")
    console.log("test_cpu()       - Test CPU register API")
    console.log("test_ai()        - Test AI function call")
    console.log("debug(on)        - Enable/disable debug mode")
    console.log("")
end

-- 状态
function status()
    console.log("")
    console.log("=== Server Status ===")
    console.log("Running: " .. tostring(AIServer.server and AIServer.server.isRunning or false))
    console.log("Port: " .. (AIServer.server and AIServer.server.port or 0))
    console.log("AI Caller: " .. tostring(AIServer.aiCaller and AIServer.aiCaller.initialized or false))
    console.log("")
end

-- 读取战斗状态
function battle()
    local BattleState = require("battle_state")
    local state = BattleState.readState()
    BattleState.printState(state)
    return state
end

-- 测试 CPU API
function test_cpu()
    if AIServer.aiCaller then
        AIServer.aiCaller:testCPUAPI()
    end
end

-- 测试 AI 调用
function test_ai()
    if AIServer.aiCaller then
        AIServer.aiCaller:testAICall()
    end
end

-- 调试模式
function debug(enabled)
    if AIServer.aiCaller then
        AIServer.aiCaller:setDebug(enabled)
    end
end

-- ============================================================================
--                           启动
-- ============================================================================

-- 注册退出回调
event.onexit(AIServer.shutdown)

-- 初始化并运行
if AIServer.initialize() then
    console.log("Type help() for available commands")
    console.log("")

    -- 主循环
    while true do
        AIServer.update()
        emu.frameadvance()
    end
else
    console.log("Initialization failed!")
end
