-- Battle State - 战斗状态读写模块
-- 基于 pokeemerald 源码的内存结构

local Config = require("config")
local Mem = require("memory_utils")

local BattleState = {}

-- ============================================================================
--                           BattlePokemon 结构偏移
-- ============================================================================

-- 从 include/pokemon.h:260-295 提取
local BP_OFFSET = {
    species    = 0x00,  -- u16
    attack     = 0x02,  -- u16
    defense    = 0x04,  -- u16
    speed      = 0x06,  -- u16
    spAttack   = 0x08,  -- u16
    spDefense  = 0x0A,  -- u16
    moves      = 0x0C,  -- u16[4]
    ivs        = 0x14,  -- u32 (位域)
    statStages = 0x18,  -- s8[8]
    ability    = 0x20,  -- u8
    types      = 0x21,  -- u8[2]
    unknown    = 0x23,  -- u8
    pp         = 0x24,  -- u8[4]
    hp         = 0x28,  -- u16
    level      = 0x2A,  -- u8
    friendship = 0x2B,  -- u8
    maxHP      = 0x2C,  -- u16
    item       = 0x2E,  -- u16
    nickname   = 0x30,  -- u8[11]
    ppBonuses  = 0x3B,  -- u8
    otName     = 0x3C,  -- u8[8]
    experience = 0x44,  -- u32
    personality = 0x48, -- u32
    status1    = 0x4C,  -- u32
    status2    = 0x50,  -- u32
    otId       = 0x54,  -- u32
}

-- 结构体大小
local BP_SIZE = 0x58  -- 88 字节

-- ============================================================================
--                           AI_ThinkingStruct 偏移
-- ============================================================================

local AI_OFFSET = {
    aiState       = 0x00,  -- u8
    movesetIndex  = 0x01,  -- u8
    moveConsidered = 0x02, -- u16
    score         = 0x04,  -- s8[4]
    funcResult    = 0x08,  -- u32
    aiFlags       = 0x0C,  -- u32
    aiAction      = 0x10,  -- u8
    aiLogicId     = 0x11,  -- u8
    filler        = 0x12,  -- u8[6]
    simulatedRNG  = 0x18,  -- u8[4]
}

-- ============================================================================
--                           读取战斗状态
-- ============================================================================

-- 读取单个 BattlePokemon
function BattleState.readBattlePokemon(battlerIndex)
    local baseAddr = Config.ADDRESS.gBattleMons + battlerIndex * BP_SIZE

    local mon = {
        species = Mem.readU16(baseAddr + BP_OFFSET.species),
        attack = Mem.readU16(baseAddr + BP_OFFSET.attack),
        defense = Mem.readU16(baseAddr + BP_OFFSET.defense),
        speed = Mem.readU16(baseAddr + BP_OFFSET.speed),
        spAttack = Mem.readU16(baseAddr + BP_OFFSET.spAttack),
        spDefense = Mem.readU16(baseAddr + BP_OFFSET.spDefense),
        moves = {
            Mem.readU16(baseAddr + BP_OFFSET.moves),
            Mem.readU16(baseAddr + BP_OFFSET.moves + 2),
            Mem.readU16(baseAddr + BP_OFFSET.moves + 4),
            Mem.readU16(baseAddr + BP_OFFSET.moves + 6),
        },
        pp = {
            Mem.readU8(baseAddr + BP_OFFSET.pp),
            Mem.readU8(baseAddr + BP_OFFSET.pp + 1),
            Mem.readU8(baseAddr + BP_OFFSET.pp + 2),
            Mem.readU8(baseAddr + BP_OFFSET.pp + 3),
        },
        ability = Mem.readU8(baseAddr + BP_OFFSET.ability),
        types = {
            Mem.readU8(baseAddr + BP_OFFSET.types),
            Mem.readU8(baseAddr + BP_OFFSET.types + 1),
        },
        hp = Mem.readU16(baseAddr + BP_OFFSET.hp),
        maxHP = Mem.readU16(baseAddr + BP_OFFSET.maxHP),
        level = Mem.readU8(baseAddr + BP_OFFSET.level),
        item = Mem.readU16(baseAddr + BP_OFFSET.item),
        status1 = Mem.readU32(baseAddr + BP_OFFSET.status1),
        status2 = Mem.readU32(baseAddr + BP_OFFSET.status2),
    }

    -- 读取能力等级
    mon.statStages = {}
    for i = 0, 7 do
        mon.statStages[i + 1] = Mem.readS8(baseAddr + BP_OFFSET.statStages + i)
    end

    return mon
end

-- 读取完整战斗状态
function BattleState.readState()
    local state = {
        weather = Mem.readU16(Config.ADDRESS.gBattleWeather),
        battleType = Mem.readU32(Config.ADDRESS.gBattleTypeFlags),
        activeBattler = Mem.readU8(Config.ADDRESS.gActiveBattler),
        battlerTarget = Mem.readU8(Config.ADDRESS.gBattlerTarget),
        currentMove = Mem.readU16(Config.ADDRESS.gCurrentMove),
        battlers = {},
    }

    -- 读取所有场上宝可梦
    for i = 0, 3 do
        state.battlers[i + 1] = BattleState.readBattlePokemon(i)
    end

    return state
end

-- ============================================================================
--                           写入战斗状态
-- ============================================================================

-- 写入单个 BattlePokemon
function BattleState.writeBattlePokemon(battlerIndex, mon)
    local baseAddr = Config.ADDRESS.gBattleMons + battlerIndex * BP_SIZE

    if mon.species then
        Mem.writeU16(baseAddr + BP_OFFSET.species, mon.species)
    end
    if mon.attack then
        Mem.writeU16(baseAddr + BP_OFFSET.attack, mon.attack)
    end
    if mon.defense then
        Mem.writeU16(baseAddr + BP_OFFSET.defense, mon.defense)
    end
    if mon.speed then
        Mem.writeU16(baseAddr + BP_OFFSET.speed, mon.speed)
    end
    if mon.sp_attack then
        Mem.writeU16(baseAddr + BP_OFFSET.spAttack, mon.sp_attack)
    end
    if mon.sp_defense then
        Mem.writeU16(baseAddr + BP_OFFSET.spDefense, mon.sp_defense)
    end

    -- 写入招式
    if mon.moves then
        for i, moveId in ipairs(mon.moves) do
            if i <= 4 then
                Mem.writeU16(baseAddr + BP_OFFSET.moves + (i - 1) * 2, moveId)
            end
        end
    end

    -- 写入 PP
    if mon.pp then
        for i, pp in ipairs(mon.pp) do
            if i <= 4 then
                Mem.writeU8(baseAddr + BP_OFFSET.pp + (i - 1), pp)
            end
        end
    end

    -- 写入其他字段
    if mon.ability then
        Mem.writeU8(baseAddr + BP_OFFSET.ability, mon.ability)
    end
    if mon.types then
        Mem.writeU8(baseAddr + BP_OFFSET.types, mon.types[1] or 0)
        Mem.writeU8(baseAddr + BP_OFFSET.types + 1, mon.types[2] or mon.types[1] or 0)
    end
    if mon.hp then
        Mem.writeU16(baseAddr + BP_OFFSET.hp, mon.hp)
    end
    if mon.max_hp then
        Mem.writeU16(baseAddr + BP_OFFSET.maxHP, mon.max_hp)
    end
    if mon.level then
        Mem.writeU8(baseAddr + BP_OFFSET.level, mon.level)
    end
    if mon.item then
        Mem.writeU16(baseAddr + BP_OFFSET.item, mon.item)
    end

    console.log(string.format("Wrote BattlePokemon[%d]: species=%d, level=%d",
        battlerIndex, mon.species or 0, mon.level or 0))
end

-- 写入完整战斗状态
function BattleState.writeState(state)
    -- 写入全局状态
    if state.weather then
        Mem.writeU16(Config.ADDRESS.gBattleWeather, state.weather)
    end
    if state.battle_type then
        Mem.writeU32(Config.ADDRESS.gBattleTypeFlags, state.battle_type)
    end
    if state.active_battler then
        Mem.writeU8(Config.ADDRESS.gActiveBattler, state.active_battler)
    end
    if state.battler_target then
        Mem.writeU8(Config.ADDRESS.gBattlerTarget, state.battler_target)
    end

    -- 写入所有宝可梦
    if state.battlers then
        for i, mon in ipairs(state.battlers) do
            if i <= 4 then
                BattleState.writeBattlePokemon(i - 1, mon)
            end
        end
    end

    console.log("Battle state written to memory")
end

-- ============================================================================
--                           AI 思考结果读取
-- ============================================================================

-- 获取 AI 思考结构地址
-- gBattleResources 是一个指针，需要先读取指针值
function BattleState.getAIThinkingAddr()
    -- 1. 先读取 gBattleResources 指针
    local resourcesPtr = Mem.readU32(Config.ADDRESS.gBattleResources)

    if resourcesPtr == 0 then
        console.log("Error: gBattleResources is null (not in battle)")
        return 0
    end

    -- 2. 读取 gBattleResources->ai 指针 (offset 0x14)
    local aiPtrOffset = 0x14  -- BattleResources.ai 偏移
    local aiPtr = Mem.readU32(resourcesPtr + aiPtrOffset)

    return aiPtr
end

-- 读取 AI 决策结果
function BattleState.readAIDecision()
    local aiAddr = BattleState.getAIThinkingAddr()

    if aiAddr == 0 then
        console.log("Error: AI_ThinkingStruct pointer is null")
        return nil
    end

    local result = {
        aiState = Mem.readU8(aiAddr + AI_OFFSET.aiState),
        movesetIndex = Mem.readU8(aiAddr + AI_OFFSET.movesetIndex),
        moveConsidered = Mem.readU16(aiAddr + AI_OFFSET.moveConsidered),
        scores = {
            Mem.readS8(aiAddr + AI_OFFSET.score),
            Mem.readS8(aiAddr + AI_OFFSET.score + 1),
            Mem.readS8(aiAddr + AI_OFFSET.score + 2),
            Mem.readS8(aiAddr + AI_OFFSET.score + 3),
        },
        aiFlags = Mem.readU32(aiAddr + AI_OFFSET.aiFlags),
        aiAction = Mem.readU8(aiAddr + AI_OFFSET.aiAction),
        aiLogicId = Mem.readU8(aiAddr + AI_OFFSET.aiLogicId),
    }

    -- 找到最高分
    result.bestScore = math.max(table.unpack(result.scores))
    result.bestMoveIndex = result.movesetIndex + 1  -- Lua 1-indexed

    return result
end

-- ============================================================================
--                           调试工具
-- ============================================================================

-- 打印战斗状态
function BattleState.printState(state)
    console.log("=== Battle State ===")
    console.log(string.format("Weather: %d, BattleType: 0x%08X", state.weather, state.battleType))
    console.log(string.format("Active: %d, Target: %d", state.activeBattler, state.battlerTarget))

    for i, mon in ipairs(state.battlers) do
        console.log(string.format("Battler %d: %s Lv%d HP %d/%d",
            i - 1, mon.species, mon.level, mon.hp, mon.maxHP))
    end
end

return BattleState
