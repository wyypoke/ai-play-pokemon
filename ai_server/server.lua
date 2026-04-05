-- HTTP Server - HTTP 服务器模块
-- 提供外部访问 AI 决策的 API

local socket = require("socket")
local json = require("json")
local HttpUtils = require("http_utils")
local Config = require("config")
local BattleState = require("battle_state")
local AICaller = require("ai_caller")

local Server = {}
Server.__index = Server

-- ============================================================================
--                           服务器创建
-- ============================================================================

function Server:new(aiCaller)
    local obj = setmetatable({}, Server)
    obj.aiCaller = aiCaller
    obj.host = Config.SERVER.host
    obj.port = Config.SERVER.port
    obj.server = nil
    obj.isRunning = false
    obj.clients = {}
    return obj
end

-- ============================================================================
--                           服务器控制
-- ============================================================================

function Server:start()
    if self.isRunning then
        console.log("Server already running")
        return true
    end

    self.server = socket.tcp()
    if not self.server then
        console.log("Failed to create server socket")
        return false
    end

    self.server:settimeout(0)
    self.server:setoption("reuseaddr", true)

    local success, err = self.server:bind(self.host, self.port)
    if not success then
        console.log("Failed to bind: " .. (err or "unknown error"))
        return false
    end

    success, err = self.server:listen(5)
    if not success then
        console.log("Failed to listen: " .. (err or "unknown error"))
        return false
    end

    self.isRunning = true
    console.log("AI Server started on http://" .. self.host .. ":" .. self.port)
    self:printEndpoints()

    return true
end

function Server:stop()
    if not self.isRunning then
        return true
    end

    for i = #self.clients, 1, -1 do
        self.clients[i]:close()
        table.remove(self.clients, i)
    end

    if self.server then
        self.server:close()
        self.server = nil
    end

    self.isRunning = false
    console.log("AI Server stopped")
    return true
end

function Server:printEndpoints()
    console.log("Available endpoints:")
    console.log("  GET  /status         - Server status")
    console.log("  GET  /battle/state   - Read current battle state")
    console.log("  POST /battle/state   - Write battle state")
    console.log("  POST /ai/decision    - Get AI decision (single: ai_battler, multi: ai_battlers[])")
    console.log("  POST /ai/test        - Test AI function call")
end

-- ============================================================================
--                           主循环
-- ============================================================================

function Server:update()
    if not self.isRunning or not self.server then
        return
    end

    -- 接受新连接
    local client = self.server:accept()
    if client then
        client:settimeout(0)
        table.insert(self.clients, client)
    end

    -- 处理现有连接
    for i = #self.clients, 1, -1 do
        local client = self.clients[i]
        local request, err = client:receive("*l")

        if request then
            self:handleRequest(client, request)
            client:close()
            table.remove(self.clients, i)
        elseif err == "closed" then
            client:close()
            table.remove(self.clients, i)
        end
    end
end

-- ============================================================================
--                           请求处理
-- ============================================================================

function Server:handleRequest(client, requestLine)
    local method, path, protocol = requestLine:match("^(%S+)%s+(%S+)%s+(%S+)")

    if not method or not path then
        HttpUtils.sendError(client, 400, "Bad Request", "Invalid HTTP request")
        return
    end

    -- 解析查询参数
    local query
    path, query = HttpUtils.parseQuery(path)

    -- 读取 headers
    local headers = {}
    while true do
        local line, err = client:receive("*l")
        if not line or line == "" then break end
        local key, value = line:match("^([^:]+):%s*(.+)")
        if key and value then
            headers[key:lower()] = value
        end
    end

    -- 读取 body（POST 请求）
    local body = ""
    if method == "POST" then
        local contentLength = tonumber(headers["content-length"]) or 0
        if contentLength > 0 then
            body = client:receive(contentLength) or ""
        end
    end

    -- 路由请求
    self:route(client, method, path, query, body, headers)
end

function Server:route(client, method, path, query, body, headers)
    -- GET 请求
    if method == "GET" then
        if path == "/status" then
            self:handleStatus(client)
        elseif path == "/battle/state" then
            self:handleGetBattleState(client)
        else
            HttpUtils.sendError(client, 404, "Not Found", "Endpoint not found")
        end

    -- POST 请求
    elseif method == "POST" then
        if path == "/battle/state" then
            self:handlePostBattleState(client, body)
        elseif path == "/ai/decision" then
            self:handleAIDecision(client, body)
        elseif path == "/ai/test" then
            self:handleAITest(client)
        else
            HttpUtils.sendError(client, 404, "Not Found", "Endpoint not found")
        end

    else
        HttpUtils.sendError(client, 405, "Method Not Allowed", "Method not supported")
    end
end

-- ============================================================================
--                           API 处理器
-- ============================================================================

-- GET /status
function Server:handleStatus(client)
    local status = {
        server = {
            running = self.isRunning,
            host = self.host,
            port = self.port,
        },
        aiCaller = {
            initialized = self.aiCaller.initialized,
        },
    }

    HttpUtils.sendJson(client, 200, "OK", status)
end

-- GET /battle/state
function Server:handleGetBattleState(client)
    local state = BattleState.readState()
    HttpUtils.sendJson(client, 200, "OK", state)
end

-- POST /battle/state
function Server:handlePostBattleState(client, body)
    local state, err = json.decode(body)
    if not state then
        HttpUtils.sendError(client, 400, "Bad Request", "Invalid JSON: " .. (err or "unknown"))
        return
    end

    BattleState.writeState(state)

    HttpUtils.sendJson(client, 200, "OK", {
        success = true,
        message = "Battle state written"
    })
end

-- POST /ai/decision
-- 支持单个或多个 battler
-- 请求格式：
--   { "ai_battler": 2 }  - 单个 battler
--   { "ai_battlers": [2, 3] }  - 多个 battler（双打）
function Server:handleAIDecision(client, body)
    local data, err = json.decode(body)
    if not data then
        HttpUtils.sendError(client, 400, "Bad Request", "Invalid JSON: " .. (err or "unknown"))
        return
    end

    -- 检查是否请求多个 battler
    if data.ai_battlers and type(data.ai_battlers) == "table" then
        -- 多个 battler 模式
        local decisions = {}
        for _, battlerId in ipairs(data.ai_battlers) do
            decisions[battlerId] = self.aiCaller:computeDecision(data, battlerId)
        end
        HttpUtils.sendJson(client, 200, "OK", {
            success = true,
            decisions = decisions
        })
    else
        -- 单个 battler 模式（向后兼容）
        local battlerId = data.ai_battler or 2
        local decision = self.aiCaller:computeDecision(data, battlerId)

        if decision then
            HttpUtils.sendJson(client, 200, "OK", {
                success = true,
                decision = decision
            })
        else
            HttpUtils.sendJson(client, 500, "Internal Server Error", {
                success = false,
                error = "Failed to compute AI decision"
            })
        end
    end
end

-- POST /ai/test
function Server:handleAITest(client)
    local success = self.aiCaller:testAICall()

    HttpUtils.sendJson(client, 200, "OK", {
        success = success,
        message = success and "AI test passed" or "AI test failed"
    })
end

return Server
