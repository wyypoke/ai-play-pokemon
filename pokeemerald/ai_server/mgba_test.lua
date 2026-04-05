-- mGBA AI 测试脚本
-- 在 mGBA 中运行，测试 CPU 寄存器操作

-- 配置
local ADDR = {
    gBattleMons = 0x02024084,
    gBattleResources = 0x020244a8,
    gActiveBattler = 0x02024064,
    BattleAI_SetupAIData = 0x08130950,
    BattleAI_ChooseMoveOrAction = 0x08130ba4,
}

local TRAP_ADDR = 0x03007FFC

-- 主函数
function test_registers()
    console:log("=== Testing mGBA Registers ===")

    -- 读取当前 PC
    local pc = emu:readRegister("PC")
    console:log(string.format("Current PC: 0x%08X", pc or 0))

    -- 设置 R0
    emu:writeRegister("R0", 12345)
    local r0 = emu:readRegister("R0")
    console:log(string.format("R0: %d", r0 or 0))

    -- 设置 LR
    emu:writeRegister("LR", TRAP_ADDR)
    local lr = emu:readRegister("LR")
    console:log(string.format("LR: 0x%08X", lr or 0))

    -- 设置 PC
    emu:writeRegister("PC", ADDR.BattleAI_SetupAIData)
    pc = emu:readRegister("PC")
    console:log(string.format("New PC: 0x%08X", pc or 0))

    console:log("=== Test Complete ===")
end

-- 检查战斗状态
function check_battle()
    console:log("=== Checking Battle State ===")

    -- 读取 gBattleResources 指针
    local resources = emu:read32(ADDR.gBattleResources)
    console:log(string.format("gBattleResources: 0x%08X", resources or 0))

    if resources and resources ~= 0 then
        -- 读取 gBattleResources->ai
        local ai = emu:read32(resources + 0x14)
        console:log(string.format("AI struct: 0x%08X", ai or 0))

        if ai and ai ~= 0 then
            -- 读取 AI 分数
            console:log("AI scores:")
            for i = 0, 3 do
                local score = emu:read8(ai + 0x04 + i)
                console:log(string.format("  Move %d: %d", i, score or 0))
            end
        end
    end
end

-- 执行 AI 函数
function call_ai()
    console:log("=== Calling AI Function ===")

    -- 设置 gActiveBattler
    emu:write8(ADDR.gActiveBattler, 2)

    -- 设置返回地址
    emu:writeRegister("LR", TRAP_ADDR)
    emu:writeRegister("R0", 0xFF)

    -- 跳转到 AI 函数
    emu:writeRegister("PC", ADDR.BattleAI_SetupAIData)

    console:log("Jumped to BattleAI_SetupAIData")

    -- 单步执行几步
    for i = 1, 10 do
        emu:step()
        local pc = emu:readRegister("PC")
        console:log(string.format("Step %d: PC = 0x%08X", i, pc or 0))
    end
end

-- 注册命令
console:log("mGBA AI Test Script Loaded")
console:log("Commands: test_registers(), check_battle(), call_ai()")
