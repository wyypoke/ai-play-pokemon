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

-- 导出为全局变量以便调试
_G.Mem = MemoryUtils

return MemoryUtils
