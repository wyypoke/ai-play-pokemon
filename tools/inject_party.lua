-- 注入训练师队伍等级脚本（单次注入）
local ADDR = 0x0203D000
local targetLevel = 50

local function log(msg)
    print(msg)
end

-- BizHawk API
local function write_u32(addr, val)
    memory.write_u32_le(addr, val)
end

local function write_u16(addr, val)
    memory.write_u16_le(addr, val)
end

local function write_u8(addr, val)
    memory.write_u8(addr, val)
end

local function read_u8(addr)
    return memory.read_u8(addr)
end

-- 单次注入
write_u32(ADDR, 0xDEADBEEF)
write_u16(ADDR + 4, 0xFFFF)
write_u8(ADDR + 6, 1)
write_u8(ADDR + 7, 1)
write_u16(ADDR + 8, 0)
write_u8(ADDR + 10, targetLevel)

log("=== 注入完成 ===")
log(string.format("目标等级: %d", targetLevel))
log(string.format("Magic: 0x%08X", memory.read_u32_le(ADDR)))
log(string.format("Enabled: %d", read_u8(ADDR + 7)))
log(string.format("Level: %d", read_u8(ADDR + 10)))
