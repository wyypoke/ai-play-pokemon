-- 行动劫持脚本（支持双打）
local ADDR = {
    PARTY  = 0x0203D000,
    ACTION = 0x0203D200,
}
local MAGIC = 0xDEADBEEF

-- 数据结构偏移量
local OFF_MAGIC       = 0
local OFF_ENABLED     = 4
local OFF_WAITING     = 5
local OFF_ACTIONS     = 8        -- actions 数组起始

-- 单个 action 的偏移 (每个 4 字节)
local ACTION_SIZE     = 4
local ACT_OFF_ACTION  = 0
local ACT_OFF_MOVE    = 1
local ACT_OFF_TARGET  = 2
local ACT_OFF_SWITCH  = 3

-- B_ACTION 常量
local B_ACTION_USE_MOVE = 0
local B_ACTION_SWITCH   = 2

-- 状态
local hijackEnabled = false

-- 内存操作
local function write_u32(addr, val) memory.write_u32_le(addr, val) end
local function write_u8(addr, val) memory.write_u8(addr, val) end
local function read_u8(addr) return memory.read_u8(addr) end

-- 获取 action 槽地址
local function getActionAddr(slot)
    return ADDR.ACTION + OFF_ACTIONS + slot * ACTION_SIZE
end

-- 初始化注入结构
local function initInject()
    write_u32(ADDR.ACTION + OFF_MAGIC, MAGIC)
    write_u8(ADDR.ACTION + OFF_ENABLED, 0)
    write_u8(ADDR.ACTION + OFF_WAITING, 0)
end

-- 启用/禁用劫持模式
function on()
    hijackEnabled = true
    write_u8(ADDR.ACTION + OFF_WAITING, 0)
    print("劫持模式已启用")
end

function off()
    hijackEnabled = false
    write_u8(ADDR.ACTION + OFF_WAITING, 0)
    print("劫持模式已禁用")
end

-- 注入单个行动
local function injectAction(slot, actionType, moveIndex, target, switchId)
    local base = getActionAddr(slot)
    write_u8(base + ACT_OFF_ACTION, actionType)
    write_u8(base + ACT_OFF_MOVE, moveIndex or 0)
    write_u8(base + ACT_OFF_TARGET, target or 1)
    write_u8(base + ACT_OFF_SWITCH, switchId or 0)
end

-- 注入招式
-- 单打: move(0, 1)         - 招式0攻击目标1
-- 双打: move(0, 1, 1, 3)   - 左宝可梦招式0打目标1，右宝可梦招式1打目标3
function move(m1, t1, m2, t2)
    if not hijackEnabled then
        print("错误：请先启用劫持模式 (输入 on())")
        return
    end

    injectAction(0, B_ACTION_USE_MOVE, m1, t1 or 1, 0)

    if m2 then
        injectAction(1, B_ACTION_USE_MOVE, m2, t2 or 3, 0)
    end

    write_u8(ADDR.ACTION + OFF_ENABLED, 1)

    if m2 then
        print(string.format("注入招式: 左[%d->%d] 右[%d->%d]", m1, t1 or 1, m2, t2 or 3))
    else
        print(string.format("注入招式: [%d->%d]", m1, t1 or 1))
    end
end

-- 注入切换
function switch(s1, s2)
    if not hijackEnabled then
        print("错误：请先启用劫持模式")
        return
    end

    injectAction(0, B_ACTION_SWITCH, 0, 0, s1)

    if s2 then
        injectAction(1, B_ACTION_SWITCH, 0, 0, s2)
    end

    write_u8(ADDR.ACTION + OFF_ENABLED, 1)

    if s2 then
        print(string.format("注入切换: 左->%d 右->%d", s1, s2))
    else
        print(string.format("注入切换: ->%d", s1))
    end
end

-- 帮助
function help()
    print("========== 行动劫持命令 ==========")
    print("on()              - 启用劫持模式")
    print("off()             - 禁用劫持模式")
    print("move(i, t)        - 单打：招式i攻击目标t")
    print("move(i1,t1, i2,t2)- 双打：两个宝可梦同时行动")
    print("switch(n)         - 切换到队伍位置n")
    print("switch(n1, n2)    - 双打：同时切换两个")
    print("")
    print("示例:")
    print("  on()            - 启用")
    print("  move(0, 1)      - 用招式0打目标1")
    print("  move(0,1, 2,3)  - 双打：左用招式0打目标1，右用招式2打目标3")
    print("  switch(3, 4)    - 双打：左切换到位置3，右切换到位置4")
    print("==================================")
end

-- 初始化
initInject()
print("=== 行动劫持脚本已加载 ===")
print("输入 help() 查看命令列表")
