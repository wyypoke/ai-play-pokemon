-- 完整训练师队伍注入脚本
local ADDR = 0x0203D000
local MAGIC = 0xDEADBEEF

-- 偏移量常量
local HEADER_SIZE = 8
local MON_SIZE = 64

-- 每只宝可梦字段偏移
local OFF_SPECIES      = 0x00
local OFF_ITEM         = 0x02
local OFF_MOVES        = 0x04
local OFF_PP           = 0x0C
local OFF_PP_BONUSES   = 0x10
local OFF_LEVEL        = 0x11
local OFF_FRIENDSHIP   = 0x12
local OFF_ABILITY_NUM  = 0x13
local OFF_PERSONALITY  = 0x14
local OFF_HP_IV        = 0x18
local OFF_ATK_IV       = 0x19
local OFF_DEF_IV       = 0x1A
local OFF_SPEED_IV     = 0x1B
local OFF_SPATK_IV     = 0x1C
local OFF_SPDEF_IV     = 0x1D
local OFF_HP_EV        = 0x1E
local OFF_ATK_EV       = 0x1F
local OFF_DEF_EV       = 0x20
local OFF_SPEED_EV     = 0x21
local OFF_SPATK_EV     = 0x22
local OFF_SPDEF_EV     = 0x23
local OFF_STATUS1      = 0x24
local OFF_OT_ID        = 0x28
local OFF_CURRENT_HP   = 0x2C
local OFF_STAT_STAGES  = 0x30
local OFF_STATUS2      = 0x38
local OFF_ABILITY      = 0x3C
local OFF_TYPES        = 0x3D

-- BizHawk API
local function write_u32(addr, val) memory.write_u32_le(addr, val) end
local function write_u16(addr, val) memory.write_u16_le(addr, val) end
local function write_u8(addr, val) memory.write_u8(addr, val) end
local function read_u32(addr) return memory.read_u32_le(addr) end
local function read_u8(addr) return memory.read_u8(addr) end

-- 获取第 i 只宝可梦的基地址
local function getMonAddr(i)
    return ADDR + HEADER_SIZE + i * MON_SIZE
end

-- 写入单只宝可梦数据
local function writeMon(i, data)
    local base = getMonAddr(i)

    -- Pokemon 基础属性
    write_u16(base + OFF_SPECIES, data.species or 0)
    write_u16(base + OFF_ITEM, data.item or 0)

    -- 技能
    for j = 1, 4 do
        write_u16(base + OFF_MOVES + (j-1)*2, data.moves and data.moves[j] or 0)
        write_u8(base + OFF_PP + (j-1), data.pp and data.pp[j] or 0)
    end

    write_u8(base + OFF_PP_BONUSES, data.ppBonuses or 0)
    write_u8(base + OFF_LEVEL, data.level or 50)
    write_u8(base + OFF_FRIENDSHIP, data.friendship or 255)
    write_u8(base + OFF_ABILITY_NUM, data.abilityNum or 0)
    write_u32(base + OFF_PERSONALITY, data.personality or 0)

    -- IVs
    write_u8(base + OFF_HP_IV, data.hpIV or 31)
    write_u8(base + OFF_ATK_IV, data.atkIV or 31)
    write_u8(base + OFF_DEF_IV, data.defIV or 31)
    write_u8(base + OFF_SPEED_IV, data.speedIV or 31)
    write_u8(base + OFF_SPATK_IV, data.spAtkIV or 31)
    write_u8(base + OFF_SPDEF_IV, data.spDefIV or 31)

    -- EVs
    write_u8(base + OFF_HP_EV, data.hpEV or 0)
    write_u8(base + OFF_ATK_EV, data.atkEV or 0)
    write_u8(base + OFF_DEF_EV, data.defEV or 0)
    write_u8(base + OFF_SPEED_EV, data.speedEV or 0)
    write_u8(base + OFF_SPATK_EV, data.spAtkEV or 0)
    write_u8(base + OFF_SPDEF_EV, data.spDefEV or 0)

    -- 状态
    write_u32(base + OFF_STATUS1, data.status1 or 0)
    write_u32(base + OFF_OT_ID, data.otId or 0)
    write_u16(base + OFF_CURRENT_HP, data.currentHP or 0)

    -- BattlePokemon 专属属性
    for j = 0, 7 do
        write_u8(base + OFF_STAT_STAGES + j, data.statStages and data.statStages[j+1] or 6)
    end
    write_u32(base + OFF_STATUS2, data.status2 or 0)
    write_u8(base + OFF_ABILITY, data.abilityOverride or 0)
    write_u8(base + OFF_TYPES, data.type1 or 0)
    write_u8(base + OFF_TYPES + 1, data.type2 or 0)
end

-- 写入头部
local function writeHeader(partySize, enabled)
    write_u32(ADDR, MAGIC)
    write_u8(ADDR + 4, partySize)
    write_u8(ADDR + 5, enabled and 1 or 0)
end

-- ========================================
-- 示例：注入一只 Lv50 火焰鸡
-- ========================================

local party = {
    {
        species = 282,  -- Blaziken (火焰鸡)
        item = 205,    -- Leftovers (吃剩的东西)
        moves = {299, 327, 231, 53},  -- Blaze Kick, Sky Uppercut, Iron Tail, Flamethrower
        pp = {15, 15, 25, 15},
        ppBonuses = 0,
        level = 50,
        friendship = 255,
        abilityNum = 0,  -- Blaze (猛火)
        personality = 0x12345678,
        hpIV = 31, atkIV = 31, defIV = 31, speedIV = 31, spAtkIV = 31, spDefIV = 31,
        hpEV = 0, atkEV = 252, defEV = 4, speedEV = 252, spAtkEV = 0, spDefEV = 0,
        status1 = 0,
        otId = 54321,
        currentHP = 0,  -- 0 = 满HP
        statStages = {6, 6, 6, 6, 6, 6, 6, 6},  -- 默认
        status2 = 0,
        abilityOverride = 0,  -- 0 = 使用自动计算
        type1 = 0,  -- 0 = 使用自动计算
        type2 = 0,
    },
}

-- 执行注入
writeHeader(#party, true)
for i, mon in ipairs(party) do
    writeMon(i - 1, mon)
end

print("=== 注入完成 ===")
print(string.format("Magic: 0x%08X", read_u32(ADDR)))
print(string.format("Party Size: %d", read_u8(ADDR + 4)))
print(string.format("Enabled: %d", read_u8(ADDR + 5)))
print(string.format("Mon 0 Species: %d", memory.read_u16_le(getMonAddr(0) + OFF_SPECIES)))
print(string.format("Mon 0 Level: %d", read_u8(getMonAddr(0) + OFF_LEVEL)))
