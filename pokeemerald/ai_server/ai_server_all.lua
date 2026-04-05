-- Pokemon Emerald AI Server - Single File Version
-- 合并所有模块，用于 BizHawk 环境
--
-- 使用方法：
-- 1. 在 BizHawk 中加载 pokeemerald.gba
-- 2. 进入游戏，开始一场战斗
-- 3. 运行此脚本

-- ============================================================================
--                           配置
-- ============================================================================

local Config = {}

Config.ADDRESS = {
    gBattleMons        = 0x02024084,
    gBattleTypeFlags   = 0x02022fec,
    gBattleWeather     = 0x020243cc,
    gActiveBattler     = 0x02024064,
    gBattlerTarget     = 0x0202420c,
    gCurrentMove       = 0x020241ea,
    gBattleResources   = 0x020244a8,
}

Config.AI_FUNC = {
    BattleAI_SetupAIData          = 0x08130950,
    BattleAI_ChooseMoveOrAction   = 0x08130ba4,
}

Config.SERVER = {
    host = "127.0.0.1",
    port = 9999,
}

-- ============================================================================
--                           内存工具
-- ============================================================================

local Mem = {}
local DOMAIN = "System Bus"

function Mem.readU8(addr)
    return memory.read_u8(addr, DOMAIN)
end

function Mem.readU16(addr)
    return memory.read_u16_le(addr, DOMAIN)
end

function Mem.readU32(addr)
    return memory.read_u32_le(addr, DOMAIN)
end

function Mem.readS8(addr)
    return memory.read_s8(addr, DOMAIN)
end

function Mem.writeU8(addr, value)
    memory.write_u8(addr, value, DOMAIN)
end

function Mem.writeU16(addr, value)
    memory.write_u16_le(addr, value, DOMAIN)
end

function Mem.writeU32(addr, value)
    memory.write_u32_le(addr, value, DOMAIN)
end

function Mem.getRegister(name)
    if emu and emu.getregister then
        return emu.getregister(name)
    end
    return nil
end

function Mem.setRegister(name, value)
    if emu and emu.setregister then
        emu.setregister(name, value)
    end
end

function Mem.getPC()
    return Mem.getRegister("PC")
end

function Mem.setPC(value)
    Mem.setRegister("PC", value)
end

function Mem.getLR()
    return Mem.getRegister("LR")
end

function Mem.setLR(value)
    Mem.setRegister("LR", value)
end

-- ============================================================================
--                           战斗状态
-- ============================================================================

local BP_OFFSET = {
    species    = 0x00, attack = 0x02, defense = 0x04, speed = 0x06,
    spAttack   = 0x08, spDefense = 0x0A, moves = 0x0C, pp = 0x24,
    ability    = 0x20, types = 0x21, hp = 0x28, level = 0x2A,
    maxHP      = 0x2C, item = 0x2E, status1 = 0x4C, status2 = 0x50,
}
local BP_SIZE = 0x58

local AI_OFFSET = {
    aiState = 0x00, movesetIndex = 0x01, moveConsidered = 0x02,
    score = 0x04, aiFlags = 0x0C, aiAction = 0x10,
}

local BattleState = {}

function BattleState.readBattlePokemon(battlerIndex)
    local base = Config.ADDRESS.gBattleMons + battlerIndex * BP_SIZE
    return {
        species = Mem.readU16(base + BP_OFFSET.species),
        attack = Mem.readU16(base + BP_OFFSET.attack),
        defense = Mem.readU16(base + BP_OFFSET.defense),
        speed = Mem.readU16(base + BP_OFFSET.speed),
        spAttack = Mem.readU16(base + BP_OFFSET.spAttack),
        spDefense = Mem.readU16(base + BP_OFFSET.spDefense),
        moves = {
            Mem.readU16(base + BP_OFFSET.moves),
            Mem.readU16(base + BP_OFFSET.moves + 2),
            Mem.readU16(base + BP_OFFSET.moves + 4),
            Mem.readU16(base + BP_OFFSET.moves + 6),
        },
        pp = {
            Mem.readU8(base + BP_OFFSET.pp),
            Mem.readU8(base + BP_OFFSET.pp + 1),
            Mem.readU8(base + BP_OFFSET.pp + 2),
            Mem.readU8(base + BP_OFFSET.pp + 3),
        },
        ability = Mem.readU8(base + BP_OFFSET.ability),
        hp = Mem.readU16(base + BP_OFFSET.hp),
        maxHP = Mem.readU16(base + BP_OFFSET.maxHP),
        level = Mem.readU8(base + BP_OFFSET.level),
    }
end

function BattleState.writeBattlePokemon(battlerIndex, mon)
    local base = Config.ADDRESS.gBattleMons + battlerIndex * BP_SIZE
    if mon.species then Mem.writeU16(base + BP_OFFSET.species, mon.species) end
    if mon.attack then Mem.writeU16(base + BP_OFFSET.attack, mon.attack) end
    if mon.defense then Mem.writeU16(base + BP_OFFSET.defense, mon.defense) end
    if mon.speed then Mem.writeU16(base + BP_OFFSET.speed, mon.speed) end
    if mon.sp_attack then Mem.writeU16(base + BP_OFFSET.spAttack, mon.sp_attack) end
    if mon.sp_defense then Mem.writeU16(base + BP_OFFSET.spDefense, mon.sp_defense) end
    if mon.hp then Mem.writeU16(base + BP_OFFSET.hp, mon.hp) end
    if mon.max_hp then Mem.writeU16(base + BP_OFFSET.maxHP, mon.max_hp) end
    if mon.level then Mem.writeU8(base + BP_OFFSET.level, mon.level) end
    if mon.ability then Mem.writeU8(base + BP_OFFSET.ability, mon.ability) end
    if mon.moves then
        for i, m in ipairs(mon.moves) do
            if i <= 4 then Mem.writeU16(base + BP_OFFSET.moves + (i-1)*2, m) end
        end
    end
    if mon.pp then
        for i, p in ipairs(mon.pp) do
            if i <= 4 then Mem.writeU8(base + BP_OFFSET.pp + (i-1), p) end
        end
    end
end

function BattleState.readState()
    local state = {
        weather = Mem.readU16(Config.ADDRESS.gBattleWeather),
        battleType = Mem.readU32(Config.ADDRESS.gBattleTypeFlags),
        activeBattler = Mem.readU8(Config.ADDRESS.gActiveBattler),
        battlers = {},
    }
    for i = 0, 3 do
        state.battlers[i + 1] = BattleState.readBattlePokemon(i)
    end
    return state
end

function BattleState.writeState(state)
    if state.weather then Mem.writeU16(Config.ADDRESS.gBattleWeather, state.weather) end
    if state.battle_type then Mem.writeU32(Config.ADDRESS.gBattleTypeFlags, state.battle_type) end
    if state.active_battler then Mem.writeU8(Config.ADDRESS.gActiveBattler, state.active_battler) end
    if state.battlers then
        for i, mon in ipairs(state.battlers) do
            if i <= 4 then BattleState.writeBattlePokemon(i - 1, mon) end
        end
    end
end

function BattleState.getAIThinkingAddr()
    -- 先读取 gBattleResources 指针
    local resourcesPtr = Mem.readU32(Config.ADDRESS.gBattleResources)
    if resourcesPtr == 0 then
        return 0
    end
    -- 再读取 gBattleResources->ai 指针
    return Mem.readU32(resourcesPtr + 0x14)
end

function BattleState.readAIDecision()
    local aiAddr = BattleState.getAIThinkingAddr()
    if aiAddr == 0 then return nil end
    local scores = {}
    for i = 0, 3 do
        scores[i + 1] = Mem.readS8(aiAddr + AI_OFFSET.score + i)
    end
    return {
        aiState = Mem.readU8(aiAddr + AI_OFFSET.aiState),
        movesetIndex = Mem.readU8(aiAddr + AI_OFFSET.movesetIndex),
        moveConsidered = Mem.readU16(aiAddr + AI_OFFSET.moveConsidered),
        scores = scores,
        bestScore = math.max(table.unpack(scores)),
    }
end

-- ============================================================================
--                           AI 调用
-- ============================================================================

local TRAP_ADDR = 0x03007FFC
local MAX_FRAMES = 1000

local AICaller = {}

-- 使用 event.on_bus_exec 和 frameadvance 实现同步等待
function AICaller.stepUntil(targetPC)
    local reached = false

    -- 注册执行断点
    local eventId = event.on_bus_exec(function()
        reached = true
        event.unregisterbyid(eventId)
    end, targetPC)

    -- 等待到达或超时
    for i = 1, MAX_FRAMES do
        if reached then
            console.log(string.format("Reached target after %d frames", i))
            return true
        end
        emu.frameadvance()
    end

    -- 超时，清理
    if not reached then
        event.unregisterbyid(eventId)
        console.log("Warning: Max frames reached")
    end

    return reached
end

function AICaller.callSetupAIData(defaultScoreMoves)
    local savedLR = Mem.getLR()
    Mem.setLR(TRAP_ADDR)
    Mem.setRegister("R0", defaultScoreMoves or 0xFF)
    Mem.setPC(Config.AI_FUNC.BattleAI_SetupAIData)
    local success = AICaller.stepUntil(TRAP_ADDR)
    if savedLR then Mem.setLR(savedLR) end
    return success
end

function AICaller.callChooseMoveOrAction()
    local savedLR = Mem.getLR()
    Mem.setLR(TRAP_ADDR)
    Mem.setPC(Config.AI_FUNC.BattleAI_ChooseMoveOrAction)
    local success = AICaller.stepUntil(TRAP_ADDR)
    local result = Mem.getRegister("R0")
    if savedLR then Mem.setLR(savedLR) end
    return result
end

function AICaller.computeDecision(state, battlerId)
    battlerId = battlerId or 2

    if state then BattleState.writeState(state) end
    Mem.writeU8(Config.ADDRESS.gActiveBattler, battlerId)

    local aiAddr = BattleState.getAIThinkingAddr()
    if aiAddr == 0 then
        console.log("Error: Not in battle state")
        return nil
    end

    AICaller.callSetupAIData(0xFF)
    local chosenMove = AICaller.callChooseMoveOrAction()
    local decision = BattleState.readAIDecision()

    if decision then
        decision.chosenMoveIndex = chosenMove
    end
    return decision
end

-- ============================================================================
--                           测试函数
-- ============================================================================

function test_cpu()
    console.log("=== Testing CPU Register API ===")
    local pc = Mem.getPC()
    console.log("Current PC: " .. string.format("0x%08X", pc or 0))

    Mem.setRegister("R0", 12345)
    local r0 = Mem.getRegister("R0")
    console.log("R0 after set: " .. tostring(r0))

    if r0 == 12345 then
        console.log("CPU Register API: OK")
        return true
    else
        console.log("CPU Register API: FAILED or not available")
        return false
    end
end

function test_ai()
    console.log("=== Testing AI Function ===")
    local aiAddr = BattleState.getAIThinkingAddr()
    console.log("AI_ThinkingStruct: " .. string.format("0x%08X", aiAddr or 0))

    if aiAddr == 0 then
        console.log("Not in battle. Start a battle first!")
        return false
    end

    local decision = BattleState.readAIDecision()
    if decision then
        console.log(string.format("Scores: %d, %d, %d, %d",
            decision.scores[1], decision.scores[2],
            decision.scores[3], decision.scores[4]))
    end
    return true
end

function battle()
    local state = BattleState.readState()
    console.log("=== Battle State ===")
    console.log(string.format("Weather: %d, Type: 0x%X", state.weather, state.battleType))
    for i, mon in ipairs(state.battlers) do
        console.log(string.format("Battler %d: Species %d Lv%d HP %d/%d",
            i-1, mon.species, mon.level, mon.hp, mon.maxHP))
    end
    return state
end

function help()
    console.log("")
    console.log("=== Commands ===")
    console.log("test_cpu()  - Test CPU register API")
    console.log("test_ai()   - Test AI function call")
    console.log("battle()    - Read current battle state")
    console.log("help()      - Show this help")
    console.log("")
end

-- ============================================================================
--                           主入口
-- ============================================================================

console.log("========================================")
console.log("  Pokemon Emerald AI Server v1.0")
console.log("========================================")
console.log("")

-- 测试 CPU API
console.log("Testing CPU Register API...")
test_cpu()

console.log("")
console.log("=== Ready ===")
console.log("Type help() for commands")
console.log("")
