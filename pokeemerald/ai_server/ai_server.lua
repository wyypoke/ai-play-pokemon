package.preload['config'] = (function (...)
-- AI Server Configuration
-- 从 pokeemerald.map 提取的符号地址

local Config = {}

-- GBA 内存布局
Config.MEMORY = {
    EWRAM_BASE = 0x02000000,  -- EWRAM 起始地址
    IWRAM_BASE = 0x03000000,  -- IWRAM 起始地址
    ROM_BASE   = 0x08000000,  -- ROM 起始地址
}

-- 全局变量地址 (EWRAM)
Config.ADDRESS = {
    -- 战斗状态
    gBattleMons        = 0x02024084,  -- struct BattlePokemon[4]
    gBattleTypeFlags   = 0x02022fec,  -- u32
    gBattleWeather     = 0x020243cc,  -- u16
    gActiveBattler     = 0x02024064,  -- u8
    gBattlerTarget     = 0x0202420c,  -- u8
    gCurrentMove       = 0x020241ea,  -- u16

    -- 资源指针
    gBattleResources   = 0x020244a8,  -- struct BattleResources*

    -- 其他战斗相关
    gAbsentBattlerFlags = 0x02024062, -- u8
    gBattlerPartyIndexes = 0x02024064, -- u16[4]
}

-- AI 函数地址 (ROM)
Config.AI_FUNC = {
    BattleAI_SetupAIData          = 0x08130950,
    BattleAI_ChooseMoveOrAction   = 0x08130ba4,
    BattleAI_HandleItemUseBeforeAISetup = 0x081308c8,
    gBattleAI_ScriptsTable        = 0x082dbef8,
}

-- 结构体大小和偏移
Config.STRUCT = {
    -- BattlePokemon 结构 (gBattleMons[i])
    BattlePokemon = {
        size = 0x58,  -- 约 88 字节
        offset = {
            species    = 0x00,  -- u16
            attack     = 0x02,  -- u16
            defense    = 0x04,  -- u16
            speed      = 0x06,  -- u16
            spAttack   = 0x08,  -- u16
            spDefense  = 0x0A,  -- u16
            moves      = 0x0C,  -- u16[4]
            pp         = 0x14,  -- u8[4]
            hp         = 0x1C,  -- u16 (实际偏移需确认)
            maxHp      = 0x1E,  -- u16
            level      = 0x20,  -- u8
            ability    = 0x22,  -- u8
            types      = 0x24,  -- u8[2]
            -- ... 更多字段需要从 battle.h 确认
        }
    },

    -- AI_ThinkingStruct (通过 gBattleResources->ai 访问)
    AI_Thinking = {
        size = 0x20,
        offset = {
            aiState       = 0x00,  -- u8
            movesetIndex  = 0x01,  -- u8
            moveConsidered = 0x02, -- u16
            score         = 0x04,  -- s8[4] ← AI评分！
            funcResult    = 0x08,  -- u32
            aiFlags       = 0x0C,  -- u32
            aiAction      = 0x10,  -- u8
            aiLogicId     = 0x11,  -- u8
            simulatedRNG  = 0x18,  -- u8[4]
        }
    },

    -- BattleResources 结构
    BattleResources = {
        offset = {
            secretBase          = 0x00,
            flags               = 0x04,
            battleScriptsStack  = 0x08,
            battleCallbackStack = 0x0C,
            beforeLvlUp         = 0x10,
            ai                  = 0x14,  -- AI_ThinkingStruct*
            battleHistory       = 0x18,
            AI_ScriptsStack     = 0x1C,
        }
    }
}

-- 对战类型标志
Config.BATTLE_TYPE = {
    DOUBLE       = 0x80,
    TRAINER      = 0x01,
    WILD         = 0x00,
    LINK         = 0x02,
}

-- 服务器配置
Config.SERVER = {
    host = "127.0.0.1",
    port = 9999,
}

return Config
 end)
package.preload['memory_utils'] = (function (...)
-- Memory Utilities - 内存读写工具封装
-- 提供统一的内存访问接口

local MemoryUtils = {}

-- 内存域
local DOMAIN = "System Bus"

-- ============================================================================
--                              读取函数
-- ============================================================================

function MemoryUtils.readU8(addr)
    return memory.read_u8(addr, DOMAIN)
end

function MemoryUtils.readU16(addr)
    return memory.read_u16_le(addr, DOMAIN)
end

function MemoryUtils.readU32(addr)
    return memory.read_u32_le(addr, DOMAIN)
end

function MemoryUtils.readS8(addr)
    return memory.read_s8(addr, DOMAIN)
end

function MemoryUtils.readS16(addr)
    return memory.read_s16_le(addr, DOMAIN)
end

function MemoryUtils.readS32(addr)
    return memory.read_s32_le(addr, DOMAIN)
end

-- 读取字节数组
function MemoryUtils.readBytes(addr, length)
    local bytes = {}
    for i = 0, length - 1 do
        bytes[i + 1] = memory.read_u8(addr + i, DOMAIN)
    end
    return bytes
end

-- 读取字符串（以 0xFF 或 0x00 结尾）
function MemoryUtils.readString(addr, maxLength, terminator)
    maxLength = maxLength or 32
    terminator = terminator or 0xFF

    local str = ""
    for i = 0, maxLength - 1 do
        local byte = memory.read_u8(addr + i, DOMAIN)
        if byte == terminator or byte == 0 then
            break
        end
        str = str .. string.char(byte)
    end
    return str
end

-- ============================================================================
--                              写入函数
-- ============================================================================

function MemoryUtils.writeU8(addr, value)
    memory.write_u8(addr, value, DOMAIN)
end

function MemoryUtils.writeU16(addr, value)
    memory.write_u16_le(addr, value, DOMAIN)
end

function MemoryUtils.writeU32(addr, value)
    memory.write_u32_le(addr, value, DOMAIN)
end

-- 写入字节数组
function MemoryUtils.writeBytes(addr, bytes)
    for i, byte in ipairs(bytes) do
        memory.write_u8(addr + i - 1, byte, DOMAIN)
    end
end

-- ============================================================================
--                              CPU 寄存器
-- ============================================================================

-- 注意：emu.getregister/setregister 在 BizHawk 中的可用性需要验证

function MemoryUtils.getRegister(name)
    if emu.getregister then
        return emu.getregister(name)
    else
        console.log("Warning: emu.getregister not available")
        return nil
    end
end

function MemoryUtils.setRegister(name, value)
    if emu.setregister then
        emu.setregister(name, value)
    else
        console.log("Warning: emu.setregister not available")
    end
end

-- 获取 PC
function MemoryUtils.getPC()
    return MemoryUtils.getRegister("PC")
end

-- 设置 PC
function MemoryUtils.setPC(value)
    MemoryUtils.setRegister("PC", value)
end

-- 获取 LR
function MemoryUtils.getLR()
    return MemoryUtils.getRegister("LR")
end

-- 设置 LR
function MemoryUtils.setLR(value)
    MemoryUtils.setRegister("LR", value)
end

-- ============================================================================
--                              调试工具
-- ============================================================================

-- 打印内存区域（十六进制转储）
function MemoryUtils.hexDump(addr, length)
    local line = ""
    local ascii = ""
    for i = 0, length - 1 do
        local byte = memory.read_u8(addr + i, DOMAIN)
        line = line .. string.format("%02X ", byte)
        if byte >= 32 and byte < 127 then
            ascii = ascii .. string.char(byte)
        else
            ascii = ascii .. "."
        end
        if (i + 1) % 16 == 0 then
            console.log(string.format("%08X: %-48s %s", addr + i - 15, line, ascii))
            line = ""
            ascii = ""
        end
    end
    if #line > 0 then
        console.log(string.format("%08X: %-48s %s", addr, line, ascii))
    end
end

return MemoryUtils
 end)
package.preload['battle_state'] = (function (...)
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
        return 0
    end

    -- 2. 读取 gBattleResources->ai 指针 (offset 0x14)
    return Mem.readU32(resourcesPtr + 0x14)
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
 end)
package.preload['ai_caller'] = (function (...)
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

-- 同步等待版本（使用 frameadvance 循环检查）
function AICaller:stepUntil(targetPC, maxFrames)
    maxFrames = maxFrames or 1000
    local reached = false

    -- 注册执行断点
    local eventId = event.on_bus_exec(function()
        reached = true
        event.unregisterbyid(eventId)
    end, targetPC)

    -- 等待到达或超时
    for i = 1, maxFrames do
        if reached then
            console.log(string.format("Reached target PC after %d frames", i))
            return true, i
        end
        emu.frameadvance()
    end

    -- 超时，清理
    if not reached then
        event.unregisterbyid(eventId)
        console.log("Warning: Max frames reached without reaching target PC")
    end

    return reached, maxFrames
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

    -- 保存当前 LR
    local savedLR = Mem.getLR()

    -- 设置返回地址
    Mem.setLR(TRAP_ADDR)

    -- 设置参数 R0 = defaultScoreMoves
    Mem.setRegister("R0", defaultScoreMoves)

    -- 设置 PC 到函数入口
    Mem.setPC(AI_FUNC.SetupAIData)

    -- 执行直到返回
    local success, steps = self:stepUntil(TRAP_ADDR)

    -- 恢复 LR
    if savedLR then
        Mem.setLR(savedLR)
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

    -- 保存当前 LR
    local savedLR = Mem.getLR()

    -- 设置返回地址
    Mem.setLR(TRAP_ADDR)

    -- 设置 PC 到函数入口（无参数）
    Mem.setPC(AI_FUNC.ChooseMoveOrAction)

    -- 执行直到返回
    local success, steps = self:stepUntil(TRAP_ADDR)

    -- 读取返回值（R0）
    local result = Mem.getRegister("R0")

    -- 恢复 LR
    if savedLR then
        Mem.setLR(savedLR)
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
 end)
package.preload['server'] = (function (...)
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
 end)
package.preload['http_utils'] = (function (...)
-- HTTP Utilities - HTTP 响应构建工具

local HttpUtils = {}

-- 发送 HTTP 响应
function HttpUtils.sendResponse(client, code, status, contentType, body)
    local response = "HTTP/1.1 " .. code .. " " .. status .. "\r\n" ..
                     "Content-Type: " .. contentType .. "\r\n" ..
                     "Content-Length: " .. #body .. "\r\n" ..
                     "Connection: close\r\n" ..
                     "Access-Control-Allow-Origin: *\r\n" ..
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" ..
                     "Access-Control-Allow-Headers: Content-Type\r\n" ..
                     "\r\n" ..
                     body
    client:send(response)
end

-- 发送 JSON 响应
function HttpUtils.sendJson(client, code, status, data)
    local json = require("json")
    local body = json.encode(data, {indent = true})
    HttpUtils.sendResponse(client, code, status, "application/json", body)
end

-- 发送错误响应
function HttpUtils.sendError(client, code, status, message)
    HttpUtils.sendJson(client, code, status, {
        error = true,
        message = message
    })
end

-- 解析查询参数
function HttpUtils.parseQuery(path)
    local query = {}
    local queryStart = path:find("?")
    if queryStart then
        local queryString = path:sub(queryStart + 1)
        for key, value in queryString:gmatch("([^&=]+)=([^&=]+)") do
            query[key] = value
        end
        path = path:sub(1, queryStart - 1)
    end
    return path, query
end

return HttpUtils
 end)
package.preload['json'] = (function (...)
-- Module options:
local always_try_using_lpeg = true
local register_global_module_table = false
local global_module_name = 'json'

--[==[

David Kolf's JSON module for Lua 5.1/5.2

Version 2.5


For the documentation see the corresponding readme.txt or visit
<http://dkolf.de/src/dkjson-lua.fsl/>.

You can contact the author by sending an e-mail to 'david' at the
domain 'dkolf.de'.


Copyright (C) 2010-2014 David Heiko Kolf

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]==]

-- global dependencies:
local pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset =
      pairs, type, tostring, tonumber, getmetatable, setmetatable, rawset
local error, require, pcall, select = error, require, pcall, select
local floor, huge = math.floor, math.huge
local strrep, gsub, strsub, strbyte, strchar, strfind, strlen, strformat =
      string.rep, string.gsub, string.sub, string.byte, string.char,
      string.find, string.len, string.format
local strmatch = string.match
local concat = table.concat

local json = { version = "dkjson 2.5" }

if register_global_module_table then
  _G[global_module_name] = json
end

local _ENV = nil -- blocking globals in Lua 5.2

pcall (function()
  -- Enable access to blocked metatables.
  -- Don't worry, this module doesn't change anything in them.
  local debmeta = require "debug".getmetatable
  if debmeta then getmetatable = debmeta end
end)

json.null = setmetatable ({}, {
  __tojson = function () return "null" end
})

local function isarray (tbl)
  local max, n, arraylen = 0, 0, 0
  for k,v in pairs (tbl) do
    if k == 'n' and type(v) == 'number' then
      arraylen = v
      if v > max then
        max = v
      end
    else
      if type(k) ~= 'number' or k < 1 or floor(k) ~= k then
        return false
      end
      if k > max then
        max = k
      end
      n = n + 1
    end
  end
  if max > 10 and max > arraylen and max > n * 2 then
    return false -- don't create an array with too many holes
  end
  return true, max
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t"
}

local function escapeutf8 (uchar)
  local value = escapecodes[uchar]
  if value then
    return value
  end
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

local function fsub (str, pattern, repl)
  -- gsub always builds a new string in a buffer, even when no match
  -- exists. First using find should be more efficient when most strings
  -- don't contain the pattern.
  if strfind (str, pattern) then
    return gsub (str, pattern, repl)
  else
    return str
  end
end

local function quotestring (value)
  -- based on the regexp "escapable" in https://github.com/douglascrockford/JSON-js
  value = fsub (value, "[%z\1-\31\"\\\127]", escapeutf8)
  if strfind (value, "[\194\216\220\225\226\239]") then
    value = fsub (value, "\194[\128-\159\173]", escapeutf8)
    value = fsub (value, "\216[\128-\132]", escapeutf8)
    value = fsub (value, "\220\143", escapeutf8)
    value = fsub (value, "\225\158[\180\181]", escapeutf8)
    value = fsub (value, "\226\128[\140-\143\168-\175]", escapeutf8)
    value = fsub (value, "\226\129[\160-\175]", escapeutf8)
    value = fsub (value, "\239\187\191", escapeutf8)
    value = fsub (value, "\239\191[\176-\191]", escapeutf8)
  end
  return "\"" .. value .. "\""
end
json.quotestring = quotestring

local function replace(str, o, n)
  local i, j = strfind (str, o, 1, true)
  if i then
    return strsub(str, 1, i-1) .. n .. strsub(str, j+1, -1)
  else
    return str
  end
end

-- locale independent num2str and str2num functions
local decpoint, numfilter

local function updatedecpoint ()
  decpoint = strmatch(tostring(0.5), "([^05+])")
  -- build a filter that can be used to remove group separators
  numfilter = "[^0-9%-%+eE" .. gsub(decpoint, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "]+"
end

updatedecpoint()

local function num2str (num)
  return replace(fsub(tostring(num), numfilter, ""), decpoint, ".")
end

local function str2num (str)
  local num = tonumber(replace(str, ".", decpoint))
  if not num then
    updatedecpoint()
    num = tonumber(replace(str, ".", decpoint))
  end
  return num
end

local function addnewline2 (level, buffer, buflen)
  buffer[buflen+1] = "\n"
  buffer[buflen+2] = strrep ("  ", level)
  buflen = buflen + 2
  return buflen
end

function json.addnewline (state)
  if state.indent then
    state.bufferlen = addnewline2 (state.level or 0,
                           state.buffer, state.bufferlen or #(state.buffer))
  end
end

local encode2 -- forward declaration

local function addpair (key, value, prev, indent, level, buffer, buflen, tables, globalorder, state)
  local kt = type (key)
  if kt ~= 'string' and kt ~= 'number' then
    return nil, "type '" .. kt .. "' is not supported as a key by JSON."
  end
  if prev then
    buflen = buflen + 1
    buffer[buflen] = ","
  end
  if indent then
    buflen = addnewline2 (level, buffer, buflen)
  end
  buffer[buflen+1] = quotestring (key)
  buffer[buflen+2] = ":"
  return encode2 (value, indent, level, buffer, buflen + 2, tables, globalorder, state)
end

local function appendcustom(res, buffer, state)
  local buflen = state.bufferlen
  if type (res) == 'string' then
    buflen = buflen + 1
    buffer[buflen] = res
  end
  return buflen
end

local function exception(reason, value, state, buffer, buflen, defaultmessage)
  defaultmessage = defaultmessage or reason
  local handler = state.exception
  if not handler then
    return nil, defaultmessage
  else
    state.bufferlen = buflen
    local ret, msg = handler (reason, value, state, defaultmessage)
    if not ret then return nil, msg or defaultmessage end
    return appendcustom(ret, buffer, state)
  end
end

function json.encodeexception(reason, value, state, defaultmessage)
  return quotestring("<" .. defaultmessage .. ">")
end

encode2 = function (value, indent, level, buffer, buflen, tables, globalorder, state)
  local valtype = type (value)
  local valmeta = getmetatable (value)
  valmeta = type (valmeta) == 'table' and valmeta -- only tables
  local valtojson = valmeta and valmeta.__tojson
  if valtojson then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    state.bufferlen = buflen
    local ret, msg = valtojson (value, state)
    if not ret then return exception('custom encoder failed', value, state, buffer, buflen, msg) end
    tables[value] = nil
    buflen = appendcustom(ret, buffer, state)
  elseif value == nil then
    buflen = buflen + 1
    buffer[buflen] = "null"
  elseif valtype == 'number' then
    local s
    if value ~= value or value >= huge or -value >= huge then
      -- This is the behaviour of the original JSON implementation.
      s = "null"
    else
      s = num2str (value)
    end
    buflen = buflen + 1
    buffer[buflen] = s
  elseif valtype == 'boolean' then
    buflen = buflen + 1
    buffer[buflen] = value and "true" or "false"
  elseif valtype == 'string' then
    buflen = buflen + 1
    buffer[buflen] = quotestring (value)
  elseif valtype == 'table' then
    if tables[value] then
      return exception('reference cycle', value, state, buffer, buflen)
    end
    tables[value] = true
    level = level + 1
    local isa, n = isarray (value)
    if n == 0 and valmeta and valmeta.__jsontype == 'object' then
      isa = false
    end
    local msg
    if isa then -- JSON array
      buflen = buflen + 1
      buffer[buflen] = "["
      for i = 1, n do
        buflen, msg = encode2 (value[i], indent, level, buffer, buflen, tables, globalorder, state)
        if not buflen then return nil, msg end
        if i < n then
          buflen = buflen + 1
          buffer[buflen] = ","
        end
      end
      buflen = buflen + 1
      buffer[buflen] = "]"
    else -- JSON object
      local prev = false
      buflen = buflen + 1
      buffer[buflen] = "{"
      local order = valmeta and valmeta.__jsonorder or globalorder
      if order then
        local used = {}
        n = #order
        for i = 1, n do
          local k = order[i]
          local v = value[k]
          if v then
            used[k] = true
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            prev = true -- add a seperator before the next element
          end
        end
        for k,v in pairs (value) do
          if not used[k] then
            buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
            if not buflen then return nil, msg end
            prev = true -- add a seperator before the next element
          end
        end
      else -- unordered
        for k,v in pairs (value) do
          buflen, msg = addpair (k, v, prev, indent, level, buffer, buflen, tables, globalorder, state)
          if not buflen then return nil, msg end
          prev = true -- add a seperator before the next element
        end
      end
      if indent then
        buflen = addnewline2 (level - 1, buffer, buflen)
      end
      buflen = buflen + 1
      buffer[buflen] = "}"
    end
    tables[value] = nil
  else
    return exception ('unsupported type', value, state, buffer, buflen,
      "type '" .. valtype .. "' is not supported by JSON.")
  end
  return buflen
end

function json.encode (value, state)
  state = state or {}
  local oldbuffer = state.buffer
  local buffer = oldbuffer or {}
  state.buffer = buffer
  updatedecpoint()
  local ret, msg = encode2 (value, state.indent, state.level or 0,
                   buffer, state.bufferlen or 0, state.tables or {}, state.keyorder, state)
  if not ret then
    error (msg, 2)
  elseif oldbuffer == buffer then
    state.bufferlen = ret
    return true
  else
    state.bufferlen = nil
    state.buffer = nil
    return concat (buffer)
  end
end

local function loc (str, where)
  local line, pos, linepos = 1, 1, 0
  while true do
    pos = strfind (str, "\n", pos, true)
    if pos and pos < where then
      line = line + 1
      linepos = pos
      pos = pos + 1
    else
      break
    end
  end
  return "line " .. line .. ", column " .. (where - linepos)
end

local function unterminated (str, what, where)
  return nil, strlen (str) + 1, "unterminated " .. what .. " at " .. loc (str, where)
end

local function scanwhite (str, pos)
  while true do
    pos = strfind (str, "%S", pos)
    if not pos then return nil end
    local sub2 = strsub (str, pos, pos + 1)
    if sub2 == "\239\187" and strsub (str, pos + 2, pos + 2) == "\191" then
      -- UTF-8 Byte Order Mark
      pos = pos + 3
    elseif sub2 == "//" then
      pos = strfind (str, "[\n\r]", pos + 2)
      if not pos then return nil end
    elseif sub2 == "/*" then
      pos = strfind (str, "*/", pos + 2)
      if not pos then return nil end
      pos = pos + 2
    else
      return pos
    end
  end
end

local escapechars = {
  ["\""] = "\"", ["\\"] = "\\", ["/"] = "/", ["b"] = "\b", ["f"] = "\f",
  ["n"] = "\n", ["r"] = "\r", ["t"] = "\t"
}

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local function scanstring (str, pos)
  local lastpos = pos + 1
  local buffer, n = {}, 0
  while true do
    local nextpos = strfind (str, "[\"\\]", lastpos)
    if not nextpos then
      return unterminated (str, "string", pos)
    end
    if nextpos > lastpos then
      n = n + 1
      buffer[n] = strsub (str, lastpos, nextpos - 1)
    end
    if strsub (str, nextpos, nextpos) == "\"" then
      lastpos = nextpos + 1
      break
    else
      local escchar = strsub (str, nextpos + 1, nextpos + 1)
      local value
      if escchar == "u" then
        value = tonumber (strsub (str, nextpos + 2, nextpos + 5), 16)
        if value then
          local value2
          if 0xD800 <= value and value <= 0xDBff then
            -- we have the high surrogate of UTF-16. Check if there is a
            -- low surrogate escaped nearby to combine them.
            if strsub (str, nextpos + 6, nextpos + 7) == "\\u" then
              value2 = tonumber (strsub (str, nextpos + 8, nextpos + 11), 16)
              if value2 and 0xDC00 <= value2 and value2 <= 0xDFFF then
                value = (value - 0xD800)  * 0x400 + (value2 - 0xDC00) + 0x10000
              else
                value2 = nil -- in case it was out of range for a low surrogate
              end
            end
          end
          value = value and unichar (value)
          if value then
            if value2 then
              lastpos = nextpos + 12
            else
              lastpos = nextpos + 6
            end
          end
        end
      end
      if not value then
        value = escapechars[escchar] or escchar
        lastpos = nextpos + 2
      end
      n = n + 1
      buffer[n] = value
    end
  end
  if n == 1 then
    return buffer[1], lastpos
  elseif n > 1 then
    return concat (buffer), lastpos
  else
    return "", lastpos
  end
end

local scanvalue -- forward declaration

local function scantable (what, closechar, str, startpos, nullval, objectmeta, arraymeta)
  local len = strlen (str)
  local tbl, n = {}, 0
  local pos = startpos + 1
  if what == 'object' then
    setmetatable (tbl, objectmeta)
  else
    setmetatable (tbl, arraymeta)
  end
  while true do
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    local char = strsub (str, pos, pos)
    if char == closechar then
      return tbl, pos + 1
    end
    local val1, err
    val1, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
    if err then return nil, pos, err end
    pos = scanwhite (str, pos)
    if not pos then return unterminated (str, what, startpos) end
    char = strsub (str, pos, pos)
    if char == ":" then
      if val1 == nil then
        return nil, pos, "cannot use nil as table index (at " .. loc (str, pos) .. ")"
      end
      pos = scanwhite (str, pos + 1)
      if not pos then return unterminated (str, what, startpos) end
      local val2
      val2, pos, err = scanvalue (str, pos, nullval, objectmeta, arraymeta)
      if err then return nil, pos, err end
      tbl[val1] = val2
      pos = scanwhite (str, pos)
      if not pos then return unterminated (str, what, startpos) end
      char = strsub (str, pos, pos)
    else
      n = n + 1
      tbl[n] = val1
    end
    if char == "," then
      pos = pos + 1
    end
  end
end

scanvalue = function (str, pos, nullval, objectmeta, arraymeta)
  pos = pos or 1
  pos = scanwhite (str, pos)
  if not pos then
    return nil, strlen (str) + 1, "no valid JSON value (reached the end)"
  end
  local char = strsub (str, pos, pos)
  if char == "{" then
    return scantable ('object', "}", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "[" then
    return scantable ('array', "]", str, pos, nullval, objectmeta, arraymeta)
  elseif char == "\"" then
    return scanstring (str, pos)
  else
    local pstart, pend = strfind (str, "^%-?[%d%.]+[eE]?[%+%-]?%d*", pos)
    if pstart then
      local number = str2num (strsub (str, pstart, pend))
      if number then
        return number, pend + 1
      end
    end
    pstart, pend = strfind (str, "^%a%w*", pos)
    if pstart then
      local name = strsub (str, pstart, pend)
      if name == "true" then
        return true, pend + 1
      elseif name == "false" then
        return false, pend + 1
      elseif name == "null" then
        return nullval, pend + 1
      end
    end
    return nil, pos, "no valid JSON value at " .. loc (str, pos)
  end
end

local function optionalmetatables(...)
  if select("#", ...) > 0 then
    return ...
  else
    return {__jsontype = 'object'}, {__jsontype = 'array'}
  end
end

function json.decode (str, pos, nullval, ...)
  local objectmeta, arraymeta = optionalmetatables(...)
  return scanvalue (str, pos, nullval, objectmeta, arraymeta)
end

function json.use_lpeg ()
  local g = require ("lpeg")

  if g.version() == "0.11" then
    error "due to a bug in LPeg 0.11, it cannot be used for JSON matching"
  end

  local pegmatch = g.match
  local P, S, R = g.P, g.S, g.R

  local function ErrorCall (str, pos, msg, state)
    if not state.msg then
      state.msg = msg .. " at " .. loc (str, pos)
      state.pos = pos
    end
    return false
  end

  local function Err (msg)
    return g.Cmt (g.Cc (msg) * g.Carg (2), ErrorCall)
  end

  local SingleLineComment = P"//" * (1 - S"\n\r")^0
  local MultiLineComment = P"/*" * (1 - P"*/")^0 * P"*/"
  local Space = (S" \n\r\t" + P"\239\187\191" + SingleLineComment + MultiLineComment)^0

  local PlainChar = 1 - S"\"\\\n\r"
  local EscapeSequence = (P"\\" * g.C (S"\"\\/bfnrt" + Err "unsupported escape sequence")) / escapechars
  local HexDigit = R("09", "af", "AF")
  local function UTF16Surrogate (match, pos, high, low)
    high, low = tonumber (high, 16), tonumber (low, 16)
    if 0xD800 <= high and high <= 0xDBff and 0xDC00 <= low and low <= 0xDFFF then
      return true, unichar ((high - 0xD800)  * 0x400 + (low - 0xDC00) + 0x10000)
    else
      return false
    end
  end
  local function UTF16BMP (hex)
    return unichar (tonumber (hex, 16))
  end
  local U16Sequence = (P"\\u" * g.C (HexDigit * HexDigit * HexDigit * HexDigit))
  local UnicodeEscape = g.Cmt (U16Sequence * U16Sequence, UTF16Surrogate) + U16Sequence/UTF16BMP
  local Char = UnicodeEscape + EscapeSequence + PlainChar
  local String = P"\"" * g.Cs (Char ^ 0) * (P"\"" + Err "unterminated string")
  local Integer = P"-"^(-1) * (P"0" + (R"19" * R"09"^0))
  local Fractal = P"." * R"09"^0
  local Exponent = (S"eE") * (S"+-")^(-1) * R"09"^1
  local Number = (Integer * Fractal^(-1) * Exponent^(-1))/str2num
  local Constant = P"true" * g.Cc (true) + P"false" * g.Cc (false) + P"null" * g.Carg (1)
  local SimpleValue = Number + String + Constant
  local ArrayContent, ObjectContent

  -- The functions parsearray and parseobject parse only a single value/pair
  -- at a time and store them directly to avoid hitting the LPeg limits.
  local function parsearray (str, pos, nullval, state)
    local obj, cont
    local npos
    local t, nt = {}, 0
    repeat
      obj, cont, npos = pegmatch (ArrayContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      nt = nt + 1
      t[nt] = obj
    until cont == 'last'
    return pos, setmetatable (t, state.arraymeta)
  end

  local function parseobject (str, pos, nullval, state)
    local obj, key, cont
    local npos
    local t = {}
    repeat
      key, obj, cont, npos = pegmatch (ObjectContent, str, pos, nullval, state)
      if not npos then break end
      pos = npos
      t[key] = obj
    until cont == 'last'
    return pos, setmetatable (t, state.objectmeta)
  end

  local Array = P"[" * g.Cmt (g.Carg(1) * g.Carg(2), parsearray) * Space * (P"]" + Err "']' expected")
  local Object = P"{" * g.Cmt (g.Carg(1) * g.Carg(2), parseobject) * Space * (P"}" + Err "'}' expected")
  local Value = Space * (Array + Object + SimpleValue)
  local ExpectedValue = Value + Space * Err "value expected"
  ArrayContent = Value * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
  local Pair = g.Cg (Space * String * Space * (P":" + Err "colon expected") * ExpectedValue)
  ObjectContent = Pair * Space * (P"," * g.Cc'cont' + g.Cc'last') * g.Cp()
  local DecodeValue = ExpectedValue * g.Cp ()

  function json.decode (str, pos, nullval, ...)
    local state = {}
    state.objectmeta, state.arraymeta = optionalmetatables(...)
    local obj, retpos = pegmatch (DecodeValue, str, pos, nullval, state)
    if state.msg then
      return nil, state.pos, state.msg
    else
      return obj, retpos
    end
  end

  -- use this function only once:
  json.use_lpeg = function () return json end

  json.using_lpeg = true

  return json -- so you can get the module using json = require "dkjson".use_lpeg()
end

if always_try_using_lpeg then
  pcall (json.use_lpeg)
end

return json
 end)
package.preload['socket'] = (function (...)
-----------------------------------------------------------------------------
-- LuaSocket helper module
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G
local string = require("string")
local math = require("math")
local socket = require("socket.core")

local _M = socket

-----------------------------------------------------------------------------
-- Exported auxiliar functions
-----------------------------------------------------------------------------
function _M.connect4(address, port, laddress, lport)
    return socket.connect(address, port, laddress, lport, "inet")
end

function _M.connect6(address, port, laddress, lport)
    return socket.connect(address, port, laddress, lport, "inet6")
end

function _M.bind(host, port, backlog)
    if host == "*" then host = "0.0.0.0" end
    local addrinfo, err = socket.dns.getaddrinfo(host);
    if not addrinfo then return nil, err end
    local sock, res
    err = "no info on address"
    for i, alt in base.ipairs(addrinfo) do
        if alt.family == "inet" then
            sock, err = socket.tcp4()
        else
            sock, err = socket.tcp6()
        end
        if not sock then return nil, err end
        sock:setoption("reuseaddr", true)
        res, err = sock:bind(alt.addr, port)
        if not res then
            sock:close()
        else
            res, err = sock:listen(backlog)
            if not res then
                sock:close()
            else
                return sock
            end
        end
    end
    return nil, err
end

_M.try = _M.newtry()

function _M.choose(table)
    return function(name, opt1, opt2)
        if base.type(name) ~= "string" then
            name, opt1, opt2 = "default", name, opt1
        end
        local f = table[name or "nil"]
        if not f then base.error("unknown key (".. base.tostring(name) ..")", 3)
        else return f(opt1, opt2) end
    end
end

-----------------------------------------------------------------------------
-- Socket sources and sinks, conforming to LTN12
-----------------------------------------------------------------------------
-- create namespaces inside LuaSocket namespace
local sourcet, sinkt = {}, {}
_M.sourcet = sourcet
_M.sinkt = sinkt

_M.BLOCKSIZE = 2048

sinkt["close-when-done"] = function(sock)
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function(self, chunk, err)
            if not chunk then
                sock:close()
                return 1
            else return sock:send(chunk) end
        end
    })
end

sinkt["keep-open"] = function(sock)
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function(self, chunk, err)
            if chunk then return sock:send(chunk)
            else return 1 end
        end
    })
end

sinkt["default"] = sinkt["keep-open"]

_M.sink = _M.choose(sinkt)

sourcet["by-length"] = function(sock, length)
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function()
            if length <= 0 then return nil end
            local size = math.min(socket.BLOCKSIZE, length)
            local chunk, err = sock:receive(size)
            if err then return nil, err end
            length = length - string.len(chunk)
            return chunk
        end
    })
end

sourcet["until-closed"] = function(sock)
    local done
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function()
            if done then return nil end
            local chunk, err, partial = sock:receive(socket.BLOCKSIZE)
            if not err then return chunk
            elseif err == "closed" then
                sock:close()
                done = 1
                return partial
            else return nil, err end
        end
    })
end


sourcet["default"] = sourcet["until-closed"]

_M.source = _M.choose(sourcet)

return _M
 end)
package.preload['socket.url'] = (function (...)
-----------------------------------------------------------------------------
-- URI parsing, composition and relative URL resolution
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module
-----------------------------------------------------------------------------
local string = require("string")
local base = _G
local table = require("table")
local socket = require("socket")

socket.url = {}
local _M = socket.url

-----------------------------------------------------------------------------
-- Module version
-----------------------------------------------------------------------------
_M._VERSION = "URL 1.0.3"

-----------------------------------------------------------------------------
-- Encodes a string into its escaped hexadecimal representation
-- Input
--   s: binary string to be encoded
-- Returns
--   escaped representation of string binary
-----------------------------------------------------------------------------
function _M.escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02x", string.byte(c))
    end))
end

-----------------------------------------------------------------------------
-- Protects a path segment, to prevent it from interfering with the
-- url parsing.
-- Input
--   s: binary string to be encoded
-- Returns
--   escaped representation of string binary
-----------------------------------------------------------------------------
local function make_set(t)
    local s = {}
    for i,v in base.ipairs(t) do
        s[t[i]] = 1
    end
    return s
end

-- these are allowed within a path segment, along with alphanum
-- other characters must be escaped
local segment_set = make_set {
    "-", "_", ".", "!", "~", "*", "'", "(",
    ")", ":", "@", "&", "=", "+", "$", ",",
}

local function protect_segment(s)
    return string.gsub(s, "([^A-Za-z0-9_])", function (c)
        if segment_set[c] then return c
        else return string.format("%%%02X", string.byte(c)) end
    end)
end

-----------------------------------------------------------------------------
-- Unencodes a escaped hexadecimal string into its binary representation
-- Input
--   s: escaped hexadecimal string to be unencoded
-- Returns
--   unescaped binary representation of escaped hexadecimal  binary
-----------------------------------------------------------------------------
function _M.unescape(s)
    return (string.gsub(s, "%%(%x%x)", function(hex)
        return string.char(base.tonumber(hex, 16))
    end))
end

-----------------------------------------------------------------------------
-- Removes '..' and '.' components appropriately from a path.
-- Input
--   path
-- Returns
--   dot-normalized path
local function remove_dot_components(path)
    local marker = string.char(1)
    repeat
        local was = path
        path = path:gsub('//', '/'..marker..'/', 1)
    until path == was
    repeat
        local was = path
        path = path:gsub('/%./', '/', 1)
    until path == was
    repeat
        local was = path
        path = path:gsub('[^/]+/%.%./([^/]+)', '%1', 1)
    until path == was
    path = path:gsub('[^/]+/%.%./*$', '')
    path = path:gsub('/%.%.$', '/')
    path = path:gsub('/%.$', '/')
    path = path:gsub('^/%.%./', '/')
    path = path:gsub(marker, '')
    return path
end

-----------------------------------------------------------------------------
-- Builds a path from a base path and a relative path
-- Input
--   base_path
--   relative_path
-- Returns
--   corresponding absolute path
-----------------------------------------------------------------------------
local function absolute_path(base_path, relative_path)
    if string.sub(relative_path, 1, 1) == "/" then
      return remove_dot_components(relative_path) end
    base_path = base_path:gsub("[^/]*$", "")
    if not base_path:find'/$' then base_path = base_path .. '/' end
    local path = base_path .. relative_path
    path = remove_dot_components(path)
    return path
end

-----------------------------------------------------------------------------
-- Parses a url and returns a table with all its parts according to RFC 2396
-- The following grammar describes the names given to the URL parts
-- <url> ::= <scheme>://<authority>/<path>;<params>?<query>#<fragment>
-- <authority> ::= <userinfo>@<host>:<port>
-- <userinfo> ::= <user>[:<password>]
-- <path> :: = {<segment>/}<segment>
-- Input
--   url: uniform resource locator of request
--   default: table with default values for each field
-- Returns
--   table with the following fields, where RFC naming conventions have
--   been preserved:
--     scheme, authority, userinfo, user, password, host, port,
--     path, params, query, fragment
-- Obs:
--   the leading '/' in {/<path>} is considered part of <path>
-----------------------------------------------------------------------------
function _M.parse(url, default)
    -- initialize default parameters
    local parsed = {}
    for i,v in base.pairs(default or parsed) do parsed[i] = v end
    -- empty url is parsed to nil
    if not url or url == "" then return nil, "invalid url" end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get scheme
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
        function(s) parsed.scheme = s; return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get query string
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = q
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    if url ~= "" then parsed.path = url end
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
        function(u) parsed.userinfo = u; return "" end)
    authority = string.gsub(authority, ":([^:%]]*)$",
        function(p) parsed.port = p; return "" end)
    if authority ~= "" then
        -- IPv6?
        parsed.host = string.match(authority, "^%[(.+)%]$") or authority
    end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
        function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end

-----------------------------------------------------------------------------
-- Rebuilds a parsed URL from its components.
-- Components are protected if any reserved or unallowed characters are found
-- Input
--   parsed: parsed URL, as returned by parse
-- Returns
--   a stringing with the corresponding URL
-----------------------------------------------------------------------------
function _M.build(parsed)
    --local ppath = _M.parse_path(parsed.path or "")
    --local url = _M.build_path(ppath)
    local url = parsed.path or ""
    if parsed.params then url = url .. ";" .. parsed.params end
    if parsed.query then url = url .. "?" .. parsed.query end
    local authority = parsed.authority
    if parsed.host then
        authority = parsed.host
        if string.find(authority, ":") then -- IPv6?
            authority = "[" .. authority .. "]"
        end
        if parsed.port then authority = authority .. ":" .. base.tostring(parsed.port) end
        local userinfo = parsed.userinfo
        if parsed.user then
            userinfo = parsed.user
            if parsed.password then
                userinfo = userinfo .. ":" .. parsed.password
            end
        end
        if userinfo then authority = userinfo .. "@" .. authority end
    end
    if authority then url = "//" .. authority .. url end
    if parsed.scheme then url = parsed.scheme .. ":" .. url end
    if parsed.fragment then url = url .. "#" .. parsed.fragment end
    -- url = string.gsub(url, "%s", "")
    return url
end

-----------------------------------------------------------------------------
-- Builds a absolute URL from a base and a relative URL according to RFC 2396
-- Input
--   base_url
--   relative_url
-- Returns
--   corresponding absolute url
-----------------------------------------------------------------------------
function _M.absolute(base_url, relative_url)
    local base_parsed
    if base.type(base_url) == "table" then
        base_parsed = base_url
        base_url = _M.build(base_parsed)
    else
        base_parsed = _M.parse(base_url)
    end
    local result
    local relative_parsed = _M.parse(relative_url)
    if not base_parsed then
        result = relative_url
    elseif not relative_parsed then
        result = base_url
    elseif relative_parsed.scheme then
        result = relative_url
    else
        relative_parsed.scheme = base_parsed.scheme
        if not relative_parsed.authority then
            relative_parsed.authority = base_parsed.authority
            if not relative_parsed.path then
                relative_parsed.path = base_parsed.path
                if not relative_parsed.params then
                    relative_parsed.params = base_parsed.params
                    if not relative_parsed.query then
                        relative_parsed.query = base_parsed.query
                    end
                end
            else
                relative_parsed.path = absolute_path(base_parsed.path or "",
                    relative_parsed.path)
            end
        end
        result = _M.build(relative_parsed)
    end
    return remove_dot_components(result)
end

-----------------------------------------------------------------------------
-- Breaks a path into its segments, unescaping the segments
-- Input
--   path
-- Returns
--   segment: a table with one entry per segment
-----------------------------------------------------------------------------
function _M.parse_path(path)
    local parsed = {}
    path = path or ""
    --path = string.gsub(path, "%s", "")
    string.gsub(path, "([^/]+)", function (s) table.insert(parsed, s) end)
    for i = 1, #parsed do
        parsed[i] = _M.unescape(parsed[i])
    end
    if string.sub(path, 1, 1) == "/" then parsed.is_absolute = 1 end
    if string.sub(path, -1, -1) == "/" then parsed.is_directory = 1 end
    return parsed
end

-----------------------------------------------------------------------------
-- Builds a path component from its segments, escaping protected characters.
-- Input
--   parsed: path segments
--   unsafe: if true, segments are not protected before path is built
-- Returns
--   path: corresponding path stringing
-----------------------------------------------------------------------------
function _M.build_path(parsed, unsafe)
    local path = ""
    local n = #parsed
    if unsafe then
        for i = 1, n-1 do
            path = path .. parsed[i]
            path = path .. "/"
        end
        if n > 0 then
            path = path .. parsed[n]
            if parsed.is_directory then path = path .. "/" end
        end
    else
        for i = 1, n-1 do
            path = path .. protect_segment(parsed[i])
            path = path .. "/"
        end
        if n > 0 then
            path = path .. protect_segment(parsed[n])
            if parsed.is_directory then path = path .. "/" end
        end
    end
    if parsed.is_absolute then path = "/" .. path end
    return path
end

return _M
 end)
package.preload['socket.http'] = (function (...)
-----------------------------------------------------------------------------
-- HTTP/1.1 client support for the Lua language.
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-------------------------------------------------------------------------------
local socket = require("socket")
local url = require("socket.url")
local ltn12 = require("ltn12")
local mime = require("mime")
local string = require("string")
local headers = require("socket.headers")
local base = _G
local table = require("table")
socket.http = {}
local _M = socket.http

-----------------------------------------------------------------------------
-- Program constants
-----------------------------------------------------------------------------
-- connection timeout in seconds
_M.TIMEOUT = 60
-- user agent field sent in request
_M.USERAGENT = socket._VERSION

-- supported schemes and their particulars
local SCHEMES = {
    http = {
        port = 80
        , create = function(t)
            return socket.tcp end }
    , https = {
        port = 443
        , create = function(t)
          local https = assert(
            require("ssl.https"), 'LuaSocket: LuaSec not found')
          local tcp = assert(
            https.tcp, 'LuaSocket: Function tcp() not available from LuaSec')
          return tcp(t) end }}

-----------------------------------------------------------------------------
-- Reads MIME headers from a connection, unfolding where needed
-----------------------------------------------------------------------------
local function receiveheaders(sock, headers)
    local line, name, value, err
    headers = headers or {}
    -- get first line
    line, err = sock:receive()
    if err then return nil, err end
    -- headers go until a blank line is found
    while line ~= "" do
        -- get field-name and value
        name, value = socket.skip(2, string.find(line, "^(.-):%s*(.*)"))
        if not (name and value) then return nil, "malformed reponse headers" end
        name = string.lower(name)
        -- get next line (value might be folded)
        line, err  = sock:receive()
        if err then return nil, err end
        -- unfold any folded values
        while string.find(line, "^%s") do
            value = value .. line
            line = sock:receive()
            if err then return nil, err end
        end
        -- save pair in table
        if headers[name] then headers[name] = headers[name] .. ", " .. value
        else headers[name] = value end
    end
    return headers
end

-----------------------------------------------------------------------------
-- Extra sources and sinks
-----------------------------------------------------------------------------
socket.sourcet["http-chunked"] = function(sock, headers)
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function()
            -- get chunk size, skip extention
            local line, err = sock:receive()
            if err then return nil, err end
            local size = base.tonumber(string.gsub(line, ";.*", ""), 16)
            if not size then return nil, "invalid chunk size" end
            -- was it the last chunk?
            if size > 0 then
                -- if not, get chunk and skip terminating CRLF
                local chunk, err, _ = sock:receive(size)
                if chunk then sock:receive() end
                return chunk, err
            else
                -- if it was, read trailers into headers table
                headers, err = receiveheaders(sock, headers)
                if not headers then return nil, err end
            end
        end
    })
end

socket.sinkt["http-chunked"] = function(sock)
    return base.setmetatable({
        getfd = function() return sock:getfd() end,
        dirty = function() return sock:dirty() end
    }, {
        __call = function(self, chunk, err)
            if not chunk then return sock:send("0\r\n\r\n") end
            local size = string.format("%X\r\n", string.len(chunk))
            return sock:send(size ..  chunk .. "\r\n")
        end
    })
end

-----------------------------------------------------------------------------
-- Low level HTTP API
-----------------------------------------------------------------------------
local metat = { __index = {} }

function _M.open(host, port, create)
    -- create socket with user connect function, or with default
    local c = socket.try(create())
    local h = base.setmetatable({ c = c }, metat)
    -- create finalized try
    h.try = socket.newtry(function() h:close() end)
    -- set timeout before connecting
    h.try(c:settimeout(_M.TIMEOUT))
    h.try(c:connect(host, port))
    -- here everything worked
    return h
end

function metat.__index:sendrequestline(method, uri)
    local reqline = string.format("%s %s HTTP/1.1\r\n", method or "GET", uri)
    return self.try(self.c:send(reqline))
end

function metat.__index:sendheaders(tosend)
    local canonic = headers.canonic
    local h = "\r\n"
    for f, v in base.pairs(tosend) do
        h = (canonic[f] or f) .. ": " .. v .. "\r\n" .. h
    end
    self.try(self.c:send(h))
    return 1
end

function metat.__index:sendbody(headers, source, step)
    source = source or ltn12.source.empty()
    step = step or ltn12.pump.step
    -- if we don't know the size in advance, send chunked and hope for the best
    local mode = "http-chunked"
    if headers["content-length"] then mode = "keep-open" end
    return self.try(ltn12.pump.all(source, socket.sink(mode, self.c), step))
end

function metat.__index:receivestatusline()
    local status,ec = self.try(self.c:receive(5))
    -- identify HTTP/0.9 responses, which do not contain a status line
    -- this is just a heuristic, but is what the RFC recommends
    if status ~= "HTTP/" then
        if ec == "timeout" then
            return 408
        end
        return nil, status
    end
    -- otherwise proceed reading a status line
    status = self.try(self.c:receive("*l", status))
    local code = socket.skip(2, string.find(status, "HTTP/%d*%.%d* (%d%d%d)"))
    return self.try(base.tonumber(code), status)
end

function metat.__index:receiveheaders()
    return self.try(receiveheaders(self.c))
end

function metat.__index:receivebody(headers, sink, step)
    sink = sink or ltn12.sink.null()
    step = step or ltn12.pump.step
    local length = base.tonumber(headers["content-length"])
    local t = headers["transfer-encoding"] -- shortcut
    local mode = "default" -- connection close
    if t and t ~= "identity" then mode = "http-chunked"
    elseif base.tonumber(headers["content-length"]) then mode = "by-length" end
    return self.try(ltn12.pump.all(socket.source(mode, self.c, length),
        sink, step))
end

function metat.__index:receive09body(status, sink, step)
    local source = ltn12.source.rewind(socket.source("until-closed", self.c))
    source(status)
    return self.try(ltn12.pump.all(source, sink, step))
end

function metat.__index:close()
    return self.c:close()
end

-----------------------------------------------------------------------------
-- High level HTTP API
-----------------------------------------------------------------------------
local function adjusturi(reqt)
    local u = reqt
    -- if there is a proxy, we need the full url. otherwise, just a part.
    if not reqt.proxy and not _M.PROXY then
        u = {
           path = socket.try(reqt.path, "invalid path 'nil'"),
           params = reqt.params,
           query = reqt.query,
           fragment = reqt.fragment
        }
    end
    return url.build(u)
end

local function adjustproxy(reqt)
    local proxy = reqt.proxy or _M.PROXY
    if proxy then
        proxy = url.parse(proxy)
        return proxy.host, proxy.port or 3128
    else
        return reqt.host, reqt.port
    end
end

local function adjustheaders(reqt)
    -- default headers
    local host = reqt.host
    local port = tostring(reqt.port)
    if port ~= tostring(SCHEMES[reqt.scheme].port) then
        host = host .. ':' .. port end
    local lower = {
        ["user-agent"] = _M.USERAGENT,
        ["host"] = host,
        ["connection"] = "close, TE",
        ["te"] = "trailers"
    }
    -- if we have authentication information, pass it along
    if reqt.user and reqt.password then
        lower["authorization"] =
            "Basic " ..  (mime.b64(reqt.user .. ":" ..
		url.unescape(reqt.password)))
    end
    -- if we have proxy authentication information, pass it along
    local proxy = reqt.proxy or _M.PROXY
    if proxy then
        proxy = url.parse(proxy)
        if proxy.user and proxy.password then
            lower["proxy-authorization"] =
                "Basic " ..  (mime.b64(proxy.user .. ":" .. proxy.password))
        end
    end
    -- override with user headers
    for i,v in base.pairs(reqt.headers or lower) do
        lower[string.lower(i)] = v
    end
    return lower
end

-- default url parts
local default = {
    path ="/"
    , scheme = "http"
}

local function adjustrequest(reqt)
    -- parse url if provided
    local nreqt = reqt.url and url.parse(reqt.url, default) or {}
    -- explicit components override url
    for i,v in base.pairs(reqt) do nreqt[i] = v end
    -- default to scheme particulars
    local schemedefs, host, port, method
        = SCHEMES[nreqt.scheme], nreqt.host, nreqt.port, nreqt.method
    if not nreqt.create then nreqt.create = schemedefs.create(nreqt) end
    if not (port and port ~= '') then nreqt.port = schemedefs.port end
    if not (method and method ~= '') then nreqt.method = 'GET' end
    if not (host and host ~= "") then
        socket.try(nil, "invalid host '" .. base.tostring(nreqt.host) .. "'")
    end
    -- compute uri if user hasn't overriden
    nreqt.uri = reqt.uri or adjusturi(nreqt)
    -- adjust headers in request
    nreqt.headers = adjustheaders(nreqt)
    if nreqt.source
        and not nreqt.headers["content-length"]
        and not nreqt.headers["transfer-encoding"]
    then
        nreqt.headers["transfer-encoding"] = "chunked"
    end

    -- ajust host and port if there is a proxy
    nreqt.host, nreqt.port = adjustproxy(nreqt)
    return nreqt
end

local function shouldredirect(reqt, code, headers)
    local location = headers.location
    if not location then return false end
    location = string.gsub(location, "%s", "")
    if location == "" then return false end
    local scheme = url.parse(location).scheme
    if scheme and (not SCHEMES[scheme]) then return false end
    -- avoid https downgrades
    if ('https' == reqt.scheme) and ('https' ~= scheme) then return false end
    return (reqt.redirect ~= false) and
           (code == 301 or code == 302 or code == 303 or code == 307) and
           (not reqt.method or reqt.method == "GET" or reqt.method == "HEAD")
        and ((false == reqt.maxredirects)
                or ((reqt.nredirects or 0)
                        < (reqt.maxredirects or 5)))
end

local function shouldreceivebody(reqt, code)
    if reqt.method == "HEAD" then return nil end
    if code == 204 or code == 304 then return nil end
    if code >= 100 and code < 200 then return nil end
    return 1
end

-- forward declarations
local trequest, tredirect

--[[local]] function tredirect(reqt, location)
    -- the RFC says the redirect URL has to be absolute, but some
    -- servers do not respect that
    local newurl = url.absolute(reqt.url, location)
    -- if switching schemes, reset port and create function
    if url.parse(newurl).scheme ~= reqt.scheme then
        reqt.port = nil
        reqt.create = nil end
    -- make new request
    local result, code, headers, status = trequest {
        url = newurl,
        source = reqt.source,
        sink = reqt.sink,
        headers = reqt.headers,
        proxy = reqt.proxy,
        maxredirects = reqt.maxredirects,
        nredirects = (reqt.nredirects or 0) + 1,
        create = reqt.create
    }
    -- pass location header back as a hint we redirected
    headers = headers or {}
    headers.location = headers.location or location
    return result, code, headers, status
end

--[[local]] function trequest(reqt)
    -- we loop until we get what we want, or
    -- until we are sure there is no way to get it
    local nreqt = adjustrequest(reqt)
    local h = _M.open(nreqt.host, nreqt.port, nreqt.create)
    -- send request line and headers
    h:sendrequestline(nreqt.method, nreqt.uri)
    h:sendheaders(nreqt.headers)
    -- if there is a body, send it
    if nreqt.source then
        h:sendbody(nreqt.headers, nreqt.source, nreqt.step)
    end
    local code, status = h:receivestatusline()
    -- if it is an HTTP/0.9 server, simply get the body and we are done
    if not code then
        h:receive09body(status, nreqt.sink, nreqt.step)
        return 1, 200
    elseif code == 408 then
        return 1, code
    end
    local headers
    -- ignore any 100-continue messages
    while code == 100 do
        h:receiveheaders()
        code, status = h:receivestatusline()
    end
    headers = h:receiveheaders()
    -- at this point we should have a honest reply from the server
    -- we can't redirect if we already used the source, so we report the error
    if shouldredirect(nreqt, code, headers) and not nreqt.source then
        h:close()
        return tredirect(reqt, headers.location)
    end
    -- here we are finally done
    if shouldreceivebody(nreqt, code) then
        h:receivebody(headers, nreqt.sink, nreqt.step)
    end
    h:close()
    return 1, code, headers, status
end

-- turns an url and a body into a generic request
local function genericform(u, b)
    local t = {}
    local reqt = {
        url = u,
        sink = ltn12.sink.table(t),
        target = t
    }
    if b then
        reqt.source = ltn12.source.string(b)
        reqt.headers = {
            ["content-length"] = string.len(b),
            ["content-type"] = "application/x-www-form-urlencoded"
        }
        reqt.method = "POST"
    end
    return reqt
end

_M.genericform = genericform

local function srequest(u, b)
    local reqt = genericform(u, b)
    local _, code, headers, status = trequest(reqt)
    return table.concat(reqt.target), code, headers, status
end

_M.request = socket.protect(function(reqt, body)
    if base.type(reqt) == "string" then return srequest(reqt, body)
    else return trequest(reqt) end
end)

_M.schemes = SCHEMES
return _M
 end)
package.preload['socket.tp'] = (function (...)
-----------------------------------------------------------------------------
-- Unified SMTP/FTP subsystem
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G
local string = require("string")
local socket = require("socket")
local ltn12 = require("ltn12")

socket.tp = {}
local _M = socket.tp

-----------------------------------------------------------------------------
-- Program constants
-----------------------------------------------------------------------------
_M.TIMEOUT = 60

-----------------------------------------------------------------------------
-- Implementation
-----------------------------------------------------------------------------
-- gets server reply (works for SMTP and FTP)
local function get_reply(c)
    local code, current, sep
    local line, err = c:receive()
    local reply = line
    if err then return nil, err end
    code, sep = socket.skip(2, string.find(line, "^(%d%d%d)(.?)"))
    if not code then return nil, "invalid server reply" end
    if sep == "-" then -- reply is multiline
        repeat
            line, err = c:receive()
            if err then return nil, err end
            current, sep = socket.skip(2, string.find(line, "^(%d%d%d)(.?)"))
            reply = reply .. "\n" .. line
        -- reply ends with same code
        until code == current and sep == " "
    end
    return code, reply
end

-- metatable for sock object
local metat = { __index = {} }

function metat.__index:getpeername()
    return self.c:getpeername()
end

function metat.__index:getsockname()
    return self.c:getpeername()
end

function metat.__index:check(ok)
    local code, reply = get_reply(self.c)
    if not code then return nil, reply end
    if base.type(ok) ~= "function" then
        if base.type(ok) == "table" then
            for i, v in base.ipairs(ok) do
                if string.find(code, v) then
                    return base.tonumber(code), reply
                end
            end
            return nil, reply
        else
            if string.find(code, ok) then return base.tonumber(code), reply
            else return nil, reply end
        end
    else return ok(base.tonumber(code), reply) end
end

function metat.__index:command(cmd, arg)
    cmd = string.upper(cmd)
    if arg then
        return self.c:send(cmd .. " " .. arg.. "\r\n")
    else
        return self.c:send(cmd .. "\r\n")
    end
end

function metat.__index:sink(snk, pat)
    local chunk, err = self.c:receive(pat)
    return snk(chunk, err)
end

function metat.__index:send(data)
    return self.c:send(data)
end

function metat.__index:receive(pat)
    return self.c:receive(pat)
end

function metat.__index:getfd()
    return self.c:getfd()
end

function metat.__index:dirty()
    return self.c:dirty()
end

function metat.__index:getcontrol()
    return self.c
end

function metat.__index:source(source, step)
    local sink = socket.sink("keep-open", self.c)
    local ret, err = ltn12.pump.all(source, sink, step or ltn12.pump.step)
    return ret, err
end

-- closes the underlying c
function metat.__index:close()
    self.c:close()
    return 1
end

-- connect with server and return c object
function _M.connect(host, port, timeout, create)
    local c, e = (create or socket.tcp)()
    if not c then return nil, e end
    c:settimeout(timeout or _M.TIMEOUT)
    local r, e = c:connect(host, port)
    if not r then
        c:close()
        return nil, e
    end
    return base.setmetatable({c = c}, metat)
end

return _M
 end)
package.preload['socket.headers'] = (function (...)
-----------------------------------------------------------------------------
-- Canonic header field capitalization
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------
local socket = require("socket")
socket.headers = {}
local _M = socket.headers

_M.canonic = {
    ["accept"] = "Accept",
    ["accept-charset"] = "Accept-Charset",
    ["accept-encoding"] = "Accept-Encoding",
    ["accept-language"] = "Accept-Language",
    ["accept-ranges"] = "Accept-Ranges",
    ["action"] = "Action",
    ["alternate-recipient"] = "Alternate-Recipient",
    ["age"] = "Age",
    ["allow"] = "Allow",
    ["arrival-date"] = "Arrival-Date",
    ["authorization"] = "Authorization",
    ["bcc"] = "Bcc",
    ["cache-control"] = "Cache-Control",
    ["cc"] = "Cc",
    ["comments"] = "Comments",
    ["connection"] = "Connection",
    ["content-description"] = "Content-Description",
    ["content-disposition"] = "Content-Disposition",
    ["content-encoding"] = "Content-Encoding",
    ["content-id"] = "Content-ID",
    ["content-language"] = "Content-Language",
    ["content-length"] = "Content-Length",
    ["content-location"] = "Content-Location",
    ["content-md5"] = "Content-MD5",
    ["content-range"] = "Content-Range",
    ["content-transfer-encoding"] = "Content-Transfer-Encoding",
    ["content-type"] = "Content-Type",
    ["cookie"] = "Cookie",
    ["date"] = "Date",
    ["diagnostic-code"] = "Diagnostic-Code",
    ["dsn-gateway"] = "DSN-Gateway",
    ["etag"] = "ETag",
    ["expect"] = "Expect",
    ["expires"] = "Expires",
    ["final-log-id"] = "Final-Log-ID",
    ["final-recipient"] = "Final-Recipient",
    ["from"] = "From",
    ["host"] = "Host",
    ["if-match"] = "If-Match",
    ["if-modified-since"] = "If-Modified-Since",
    ["if-none-match"] = "If-None-Match",
    ["if-range"] = "If-Range",
    ["if-unmodified-since"] = "If-Unmodified-Since",
    ["in-reply-to"] = "In-Reply-To",
    ["keywords"] = "Keywords",
    ["last-attempt-date"] = "Last-Attempt-Date",
    ["last-modified"] = "Last-Modified",
    ["location"] = "Location",
    ["max-forwards"] = "Max-Forwards",
    ["message-id"] = "Message-ID",
    ["mime-version"] = "MIME-Version",
    ["original-envelope-id"] = "Original-Envelope-ID",
    ["original-recipient"] = "Original-Recipient",
    ["pragma"] = "Pragma",
    ["proxy-authenticate"] = "Proxy-Authenticate",
    ["proxy-authorization"] = "Proxy-Authorization",
    ["range"] = "Range",
    ["received"] = "Received",
    ["received-from-mta"] = "Received-From-MTA",
    ["references"] = "References",
    ["referer"] = "Referer",
    ["remote-mta"] = "Remote-MTA",
    ["reply-to"] = "Reply-To",
    ["reporting-mta"] = "Reporting-MTA",
    ["resent-bcc"] = "Resent-Bcc",
    ["resent-cc"] = "Resent-Cc",
    ["resent-date"] = "Resent-Date",
    ["resent-from"] = "Resent-From",
    ["resent-message-id"] = "Resent-Message-ID",
    ["resent-reply-to"] = "Resent-Reply-To",
    ["resent-sender"] = "Resent-Sender",
    ["resent-to"] = "Resent-To",
    ["retry-after"] = "Retry-After",
    ["return-path"] = "Return-Path",
    ["sender"] = "Sender",
    ["server"] = "Server",
    ["smtp-remote-recipient"] = "SMTP-Remote-Recipient",
    ["status"] = "Status",
    ["subject"] = "Subject",
    ["te"] = "TE",
    ["to"] = "To",
    ["trailer"] = "Trailer",
    ["transfer-encoding"] = "Transfer-Encoding",
    ["upgrade"] = "Upgrade",
    ["user-agent"] = "User-Agent",
    ["vary"] = "Vary",
    ["via"] = "Via",
    ["warning"] = "Warning",
    ["will-retry-until"] = "Will-Retry-Until",
    ["www-authenticate"] = "WWW-Authenticate",
    ["x-mailer"] = "X-Mailer",
}

return _M end)
package.preload['ltn12'] = (function (...)
-----------------------------------------------------------------------------
-- LTN12 - Filters, sources, sinks and pumps.
-- LuaSocket toolkit.
-- Author: Diego Nehab
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module
-----------------------------------------------------------------------------
local string = require("string")
local table = require("table")
local unpack = unpack or table.unpack
local base = _G
local select = select

local _M = {}
if module then -- heuristic for exporting a global package table
    ltn12 = _M  -- luacheck: ignore
end
local filter,source,sink,pump = {},{},{},{}

_M.filter = filter
_M.source = source
_M.sink = sink
_M.pump = pump

-- 2048 seems to be better in windows...
_M.BLOCKSIZE = 2048
_M._VERSION = "LTN12 1.0.3"

-----------------------------------------------------------------------------
-- Filter stuff
-----------------------------------------------------------------------------
-- returns a high level filter that cycles a low-level filter
function filter.cycle(low, ctx, extra)
    base.assert(low)
    return function(chunk)
        local ret
        ret, ctx = low(ctx, chunk, extra)
        return ret
    end
end

-- chains a bunch of filters together
-- (thanks to Wim Couwenberg)
function filter.chain(...)
    local arg = {...}
    local n = select('#',...)
    local top, index = 1, 1
    local retry = ""
    return function(chunk)
        retry = chunk and retry
        while true do
            if index == top then
                chunk = arg[index](chunk)
                if chunk == "" or top == n then return chunk
                elseif chunk then index = index + 1
                else
                    top = top+1
                    index = top
                end
            else
                chunk = arg[index](chunk or "")
                if chunk == "" then
                    index = index - 1
                    chunk = retry
                elseif chunk then
                    if index == n then return chunk
                    else index = index + 1 end
                else base.error("filter returned inappropriate nil") end
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Source stuff
-----------------------------------------------------------------------------
-- create an empty source
local function empty()
    return nil
end

function source.empty()
    return empty
end

-- returns a source that just outputs an error
function source.error(err)
    return function()
        return nil, err
    end
end

-- creates a file source
function source.file(handle, io_err)
    if handle then
        return function()
            local chunk = handle:read(_M.BLOCKSIZE)
            if not chunk then handle:close() end
            return chunk
        end
    else return source.error(io_err or "unable to open file") end
end

-- turns a fancy source into a simple source
function source.simplify(src)
    base.assert(src)
    return function()
        local chunk, err_or_new = src()
        src = err_or_new or src
        if not chunk then return nil, err_or_new
        else return chunk end
    end
end

-- creates string source
function source.string(s)
    if s then
        local i = 1
        return function()
            local chunk = string.sub(s, i, i+_M.BLOCKSIZE-1)
            i = i + _M.BLOCKSIZE
            if chunk ~= "" then return chunk
            else return nil end
        end
    else return source.empty() end
end

-- creates table source
function source.table(t)
    base.assert('table' == type(t))
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

-- creates rewindable source
function source.rewind(src)
    base.assert(src)
    local t = {}
    return function(chunk)
        if not chunk then
            chunk = table.remove(t)
            if not chunk then return src()
            else return chunk end
        else
            table.insert(t, chunk)
        end
    end
end

-- chains a source with one or several filter(s)
function source.chain(src, f, ...)
    if ... then f=filter.chain(f, ...) end
    base.assert(src and f)
    local last_in, last_out = "", ""
    local state = "feeding"
    local err
    return function()
        if not last_out then
            base.error('source is empty!', 2)
        end
        while true do
            if state == "feeding" then
                last_in, err = src()
                if err then return nil, err end
                last_out = f(last_in)
                if not last_out then
                    if last_in then
                        base.error('filter returned inappropriate nil')
                    else
                        return nil
                    end
                elseif last_out ~= "" then
                    state = "eating"
                    if last_in then last_in = "" end
                    return last_out
                end
            else
                last_out = f(last_in)
                if last_out == "" then
                    if last_in == "" then
                        state = "feeding"
                    else
                        base.error('filter returned ""')
                    end
                elseif not last_out then
                    if last_in then
                        base.error('filter returned inappropriate nil')
                    else
                        return nil
                    end
                else
                    return last_out
                end
            end
        end
    end
end

-- creates a source that produces contents of several sources, one after the
-- other, as if they were concatenated
-- (thanks to Wim Couwenberg)
function source.cat(...)
    local arg = {...}
    local src = table.remove(arg, 1)
    return function()
        while src do
            local chunk, err = src()
            if chunk then return chunk end
            if err then return nil, err end
            src = table.remove(arg, 1)
        end
    end
end

-----------------------------------------------------------------------------
-- Sink stuff
-----------------------------------------------------------------------------
-- creates a sink that stores into a table
function sink.table(t)
    t = t or {}
    local f = function(chunk, err)
        if chunk then table.insert(t, chunk) end
        return 1
    end
    return f, t
end

-- turns a fancy sink into a simple sink
function sink.simplify(snk)
    base.assert(snk)
    return function(chunk, err)
        local ret, err_or_new = snk(chunk, err)
        if not ret then return nil, err_or_new end
        snk = err_or_new or snk
        return 1
    end
end

-- creates a file sink
function sink.file(handle, io_err)
    if handle then
        return function(chunk, err)
            if not chunk then
                handle:close()
                return 1
            else return handle:write(chunk) end
        end
    else return sink.error(io_err or "unable to open file") end
end

-- creates a sink that discards data
local function null()
    return 1
end

function sink.null()
    return null
end

-- creates a sink that just returns an error
function sink.error(err)
    return function()
        return nil, err
    end
end

-- chains a sink with one or several filter(s)
function sink.chain(f, snk, ...)
    if ... then
        local args = { f, snk, ... }
        snk = table.remove(args, #args)
        f = filter.chain(unpack(args))
    end
    base.assert(f and snk)
    return function(chunk, err)
        if chunk ~= "" then
            local filtered = f(chunk)
            local done = chunk and ""
            while true do
                local ret, snkerr = snk(filtered, err)
                if not ret then return nil, snkerr end
                if filtered == done then return 1 end
                filtered = f(done)
            end
        else return 1 end
    end
end

-----------------------------------------------------------------------------
-- Pump stuff
-----------------------------------------------------------------------------
-- pumps one chunk from the source to the sink
function pump.step(src, snk)
    local chunk, src_err = src()
    local ret, snk_err = snk(chunk, src_err)
    if chunk and ret then return 1
    else return nil, src_err or snk_err end
end

-- pumps all data from a source to a sink, using a step function
function pump.all(src, snk, step)
    base.assert(src and snk)
    step = step or pump.step
    while true do
        local ret, err = step(src, snk)
        if not ret then
            if err then return nil, err
            else return 1 end
        end
    end
end

return _M
 end)
package.preload['mime'] = (function (...)
-----------------------------------------------------------------------------
-- MIME support for the Lua language.
-- Author: Diego Nehab
-- Conforming to RFCs 2045-2049
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------
local base = _G
local ltn12 = require("ltn12")
local mime = require("mime.core")
local _M = mime

-- encode, decode and wrap algorithm tables
local encodet, decodet, wrapt = {},{},{}

_M.encodet = encodet
_M.decodet = decodet
_M.wrapt   = wrapt

-- creates a function that chooses a filter by name from a given table
local function choose(table)
    return function(name, opt1, opt2)
        if base.type(name) ~= "string" then
            name, opt1, opt2 = "default", name, opt1
        end
        local f = table[name or "nil"]
        if not f then
            base.error("unknown key (" .. base.tostring(name) .. ")", 3)
        else return f(opt1, opt2) end
    end
end

-- define the encoding filters
encodet['base64'] = function()
    return ltn12.filter.cycle(_M.b64, "")
end

encodet['quoted-printable'] = function(mode)
    return ltn12.filter.cycle(_M.qp, "",
        (mode == "binary") and "=0D=0A" or "\r\n")
end

-- define the decoding filters
decodet['base64'] = function()
    return ltn12.filter.cycle(_M.unb64, "")
end

decodet['quoted-printable'] = function()
    return ltn12.filter.cycle(_M.unqp, "")
end

-- define the line-wrap filters
wrapt['text'] = function(length)
    length = length or 76
    return ltn12.filter.cycle(_M.wrp, length, length)
end
wrapt['base64'] = wrapt['text']
wrapt['default'] = wrapt['text']

wrapt['quoted-printable'] = function()
    return ltn12.filter.cycle(_M.qpwrp, 76, 76)
end

-- function that choose the encoding, decoding or wrap algorithm
_M.encode = choose(encodet)
_M.decode = choose(decodet)
_M.wrap = choose(wrapt)

-- define the end-of-line normalization filter
function _M.normalize(marker)
    return ltn12.filter.cycle(_M.eol, 0, marker)
end

-- high level stuffing filter
function _M.stuff()
    return ltn12.filter.cycle(_M.dot, 2)
end

return _M
 end)
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
