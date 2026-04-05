-- mGBA AI 测试 - LR 陷阱法 v2
-- 修复断点 API

local ADDR = {
    gBattleMons = 0x02024084,
    gBattleResources = 0x020244a8,
    gActiveBattler = 0x02024064,
    BattleAI_SetupAIData = 0x08130951,
    BattleAI_ChooseMoveOrAction = 0x08130ba5,
}

local TRAP_ADDR = 0x0203FFFC

local state = {
    trapHit = false,
    result = nil,
    bpId = nil
}

-- 读取 AI 分数
function read_ai_scores()
    local resources = emu:read32(ADDR.gBattleResources)
    if not resources or resources == 0 then return nil end

    local ai = emu:read32(resources + 0x14)
    if not ai or ai == 0 then return nil end

    local scores = {}
    for i = 0, 3 do
        scores[i + 1] = emu:read8(ai + 0x04 + i)
    end

    return { scores = scores, best = math.max(table.unpack(scores)) }
end

-- 检查 mGBA API
function check_api()
    console:log("=== Checking mGBA API ===")
    console:log("emu:setBreakpoint: " .. tostring(emu.setBreakpoint))
    console:log("emu:clearBreakpoint: " .. tostring(emu.clearBreakpoint))
    console:log("emu:step: " .. tostring(emu.step))
    console:log("emu:readRegister: " .. tostring(emu.readRegister))
    console:log("emu:writeRegister: " .. tostring(emu.writeRegister))
end

-- 测试简单调用（无断点）
function test_simple()
    console:log("=== Simple AI Call Test ===")

    -- 1. 设置陷阱
    emu:write16(TRAP_ADDR, 0xE7FE)
    console:log(string.format("Wrote trap at 0x%08X", TRAP_ADDR))

    -- 2. 设置寄存器
    emu:writeRegister("LR", TRAP_ADDR + 1)
    emu:writeRegister("R0", 0xFF)
    emu:writeRegister("PC", ADDR.BattleAI_SetupAIData)

    console:log(string.format("LR = 0x%08X", emu:readRegister("LR")))
    console:log(string.format("PC = 0x%08X", emu:readRegister("PC")))

    -- 3. 单步执行几步看 PC 变化
    console:log("Stepping...")
    for i = 1, 20 do
        emu:step()
        local pc = emu:readRegister("PC")
        console:log(string.format("Step %d: PC = 0x%08X", i, pc))

        if pc == TRAP_ADDR or pc == TRAP_ADDR + 1 then
            console:log("Trap reached!")
            local scores = read_ai_scores()
            if scores then
                console:log(string.format("Scores: %d, %d, %d, %d",
                    scores.scores[1], scores.scores[2],
                    scores.scores[3], scores.scores[4]))
            end
            break
        end
    end
end

-- 执行更多步
function run_until_trap(maxSteps)
    maxSteps = maxSteps or 5000

    emu:write16(TRAP_ADDR, 0xE7FE)
    emu:writeRegister("LR", TRAP_ADDR + 1)
    emu:writeRegister("R0", 0xFF)
    emu:writeRegister("PC", ADDR.BattleAI_SetupAIData)

    console:log(string.format("Starting from PC = 0x%08X", ADDR.BattleAI_SetupAIData))
    console:log(string.format("LR = 0x%08X", TRAP_ADDR + 1))

    for i = 1, maxSteps do
        emu:step()

        if i % 500 == 0 then
            local pc = emu:readRegister("PC")
            console:log(string.format("Step %d: PC = 0x%08X", i, pc))
        end

        local pc = emu:readRegister("PC")
        if pc == TRAP_ADDR or pc == TRAP_ADDR + 1 then
            console:log(string.format("Trap reached after %d steps!", i))
            local scores = read_ai_scores()
            if scores then
                console:log(string.format("Scores: %d, %d, %d, %d",
                    scores.scores[1], scores.scores[2],
                    scores.scores[3], scores.scores[4]))
            end
            return true, scores
        end
    end

    console:log("Timeout - trap not reached")
    console:log(string.format("Final PC: 0x%08X", emu:readRegister("PC")))
    return false, nil
end

console:log("=== mGBA AI Trap Test v2 ===")
console:log("Commands:")
console:log("  check_api()      - List available APIs")
console:log("  test_simple()    - Simple step test")
console:log("  run_until_trap() - Run until trap or timeout")
console:log("  read_ai_scores() - Read current AI scores")
