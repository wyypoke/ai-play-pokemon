-- AI Caller - AI 调用核心模块
-- 通过 CPU 寄存器操作调用 ROM 内的 AI 函数

local Config = require("config")
local Mem = require("memory_utils")
local BattleState = require("battle_state")

local AICaller = {}
AICaller.__index = AICaller

-- ============================================================================
--                           常量定义
-- ============================================================================

-- 陷阱地址（IWRAM 末尾，通常不会执行到这里）
local TRAP_ADDR = 0x03007FFC

-- 最大执行步数（防止死循环）
local MAX_STEPS = 100000

-- AI 函数地址
local AI_FUNC = {
    SetupAIData = Config.AI_FUNC.BattleAI_SetupAIData,
    ChooseMoveOrAction = Config.AI_FUNC.BattleAI_ChooseMoveOrAction,
}

-- ============================================================================
--                           初始化
-- ============================================================================

function AICaller:new()
    local obj = setmetatable({}, AICaller)
    obj.initialized = false
    obj.debug = false
    return obj
end

function AICaller:init()
    -- 验证 ROM 是否是绿宝石
    local romTitle = ""
    for i = 0, 11 do
        local byte = Mem.readU8(0x080000A0 + i)
        if byte > 0 then
            romTitle = romTitle .. string.char(byte)
        end
    end

    console.log("ROM Title: " .. romTitle)

    if romTitle:find("POKEMON EMER") then
        console.log("Pokemon Emerald detected!")
        self.initialized = true
        return true
    else
        console.log("Warning: Not Pokemon Emerald")
        self.initialized = true  -- 继续但警告
        return true
    end
end

-- ============================================================================
--                           CPU 执行控制
-- ============================================================================

-- 检查 CPU 寄存器 API 是否可用
function AICaller:checkCPUAPI()
    if not emu.getregister or not emu.setregister then
        console.log("Error: CPU register API not available")
        console.log("emu.getregister: " .. tostring(emu.getregister))
        console.log("emu.setregister: " .. tostring(emu.setregister))
        return false
    end
    return true
end

-- 使用 event.on_bus_exec 在目标地址触发回调
-- 异步执行，当 PC 到达目标地址时调用回调函数
function AICaller:executeUntil(targetPC, callback)
    -- 注册执行断点
    local eventId = event.on_bus_exec(function(addr, val, flags)
        -- 到达目标地址，取消注册
        event.unregisterbyid(eventId)
        -- 调用回调
        if callback then callback() end
    end, targetPC)

    return eventId
end

-- 使用 hook 方式等待 AI 函数执行
-- 当游戏自然调用 AI 函数时，读取结果
function AICaller:waitForAIResult(maxFrames)
    maxFrames = maxFrames or 300  -- 约 5 秒

    local result = nil
    local gotResult = false

    -- 在 BattleAI_ChooseMoveOrAction 返回时读取结果
    local eventId = event.on_bus_exec(function()
        -- 读取 AI 决策
        result = BattleState.readAIDecision()
        gotResult = true
        event.unregisterbyid(eventId)
        console.log("AI function executed, got result!")
    end, AI_FUNC.ChooseMoveOrAction + 4, "ai_hook")  -- +4 是函数入口后

    -- 等待结果
    for i = 1, maxFrames do
        if gotResult then
            return result
        end
        emu.frameadvance()
    end

    -- 超时
    event.unregisterbyid(eventId)
    console.log("Warning: Timeout waiting for AI")
    return nil
end

-- 同步等待版本：暂停 -> 设置寄存器 -> 单步执行 -> 等待
function AICaller:stepUntil(targetPC, maxSteps)
    maxSteps = maxSteps or 100000

    -- 1. 暂停模拟器
    client.pause()

    -- 2. 检查当前 PC
    local pc = emu.getregister("PC")
    console.log(string.format("Paused, PC = 0x%08X", pc or 0))

    -- 3. 解除暂停并单步执行
    client.unpause()

    for i = 1, maxSteps do
        -- 单步执行（如果可用）
        if emu.step then
            emu.step()
        else
            -- 没有 step，用 frameadvance 替代
            emu.frameadvance()
        end

        pc = emu.getregister("PC")
        if pc == targetPC then
            console.log(string.format("Reached target PC after %d steps", i))
            return true, i
        end
    end

    console.log("Warning: Max steps reached without reaching target PC")
    return false, maxSteps
end

-- ============================================================================
--                           AI 函数调用
-- ============================================================================

-- 调用 BattleAI_SetupAIData(defaultScoreMoves)
-- defaultScoreMoves: 位掩码，每位对应一个招式是否设置初始分数为 100
function AICaller:callSetupAIData(defaultScoreMoves)
    if not self:checkCPUAPI() then
        return false
    end

    defaultScoreMoves = defaultScoreMoves or 0xFF  -- 默认所有招式

    console.log("Calling BattleAI_SetupAIData...")

    -- 1. 暂停模拟器
    client.pause()
    console.log("Emulator paused")

    -- 2. 保存当前 LR
    local savedLR = emu.getregister("LR")
    console.log("Saved LR: " .. string.format("0x%08X", savedLR or 0))

    -- 3. 设置寄存器
    emu.setregister("LR", TRAP_ADDR)
    emu.setregister("R0", defaultScoreMoves)
    emu.setregister("PC", AI_FUNC.SetupAIData)

    console.log("Set LR: " .. string.format("0x%08X", emu.getregister("LR") or 0))
    console.log("Set R0: " .. tostring(emu.getregister("R0")))
    console.log("Set PC: " .. string.format("0x%08X", emu.getregister("PC") or 0))

    -- 4. 解除暂停
    client.unpause()

    -- 5. 执行直到返回
    local success, steps = self:stepUntil(TRAP_ADDR)

    -- 6. 恢复 LR
    if savedLR then
        emu.setregister("LR", savedLR)
    end

    return success
end

-- 调用 BattleAI_ChooseMoveOrAction()
-- 返回：选择的招式索引
function AICaller:callChooseMoveOrAction()
    if not self:checkCPUAPI() then
        return nil
    end

    console.log("Calling BattleAI_ChooseMoveOrAction...")

    -- 1. 暂停模拟器
    client.pause()

    -- 2. 保存当前 LR
    local savedLR = emu.getregister("LR")

    -- 3. 设置寄存器
    emu.setregister("LR", TRAP_ADDR)
    emu.setregister("PC", AI_FUNC.ChooseMoveOrAction)

    console.log("Set PC: " .. string.format("0x%08X", emu.getregister("PC") or 0))

    -- 4. 解除暂停
    client.unpause()

    -- 5. 执行直到返回
    local success, steps = self:stepUntil(TRAP_ADDR)

    -- 6. 读取返回值（R0）
    local result = emu.getregister("R0")

    -- 7. 恢复 LR
    if savedLR then
        emu.setregister("LR", savedLR)
    end

    return result
end

    return result
end

-- ============================================================================
--                           高级 API
-- ============================================================================

-- 完整的 AI 决策流程
-- 1. 写入战斗状态
-- 2. 设置 AI 标志
-- 3. 调用 AI 函数
-- 4. 读取结果
function AICaller:computeDecision(state, battlerId)
    if not self.initialized then
        console.log("Error: AICaller not initialized")
        return nil
    end

    battlerId = battlerId or 2  -- 默认 AI 是 battler 2

    console.log(string.format("Computing AI decision for battler %d...", battlerId))

    -- 1. 写入战斗状态
    if state then
        BattleState.writeState(state)
    end

    -- 2. 设置 gActiveBattler
    Mem.writeU8(Config.ADDRESS.gActiveBattler, battlerId)

    -- 3. 检查 gBattleResources 是否有效
    local aiAddr = BattleState.getAIThinkingAddr()
    if aiAddr == 0 then
        console.log("Error: gBattleResources->ai is null")
        console.log("Game may not be in battle state")
        return nil
    end

    -- 4. 调用 AI 函数
    -- 先调用 SetupAIData
    local success = self:callSetupAIData(0xFF)  -- 所有招式初始分数为 100
    if not success then
        console.log("Error: BattleAI_SetupAIData failed")
        return nil
    end

    -- 然后调用 ChooseMoveOrAction
    local chosenMove = self:callChooseMoveOrAction()
    if chosenMove == nil then
        console.log("Error: BattleAI_ChooseMoveOrAction failed")
        return nil
    end

    -- 5. 读取 AI 决策结果
    local decision = BattleState.readAIDecision()

    if decision then
        decision.chosenMoveIndex = chosenMove
        console.log(string.format("AI chose move %d (score: %d)",
            chosenMove, decision.bestScore))
    end

    return decision
end

-- 从 JSON 字符串计算 AI 决策
function AICaller:computeFromJSON(jsonStr)
    local json = require("json")
    local state, err = json.decode(jsonStr)

    if not state then
        console.log("Error: Failed to parse JSON: " .. (err or "unknown"))
        return nil
    end

    local battlerId = state.ai_battler or 2
    return self:computeDecision(state, battlerId)
end

-- ============================================================================
--                           调试工具
-- ============================================================================

-- 设置调试模式
function AICaller:setDebug(enabled)
    self.debug = enabled
    console.log("Debug mode: " .. tostring(enabled))
end

-- 测试 CPU 寄存器 API
function AICaller:testCPUAPI()
    console.log("=== Testing CPU Register API ===")

    -- 测试 getregister
    local pc = Mem.getPC()
    console.log("Current PC: " .. string.format("0x%08X", pc or 0))

    -- 测试 setregister
    Mem.setRegister("R0", 12345)
    local r0 = Mem.getRegister("R0")
    console.log("R0 after set: " .. tostring(r0))

    if r0 == 12345 then
        console.log("CPU Register API: OK")
        return true
    else
        console.log("CPU Register API: FAILED")
        return false
    end
end

-- 测试 AI 函数调用（需要在战斗中）
function AICaller:testAICall()
    console.log("=== Testing AI Function Call ===")

    -- 检查 gBattleResources
    local aiAddr = BattleState.getAIThinkingAddr()
    console.log("AI_ThinkingStruct address: " .. string.format("0x%08X", aiAddr or 0))

    if aiAddr == 0 then
        console.log("Not in battle state. Please start a battle first.")
        return false
    end

    -- 读取当前 AI 决策
    local decision = BattleState.readAIDecision()
    if decision then
        console.log(string.format("Scores: %d, %d, %d, %d",
            decision.scores[1], decision.scores[2],
            decision.scores[3], decision.scores[4]))
    end

    return true
end

return AICaller
