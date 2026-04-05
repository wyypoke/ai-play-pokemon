# 宝可梦绿宝石 AI 决策接口暴露 - 项目进度

## 目标

将 ROM 内的原始 AI 决策逻辑暴露给外部程序调用。

```
外部程序发送 JSON（对战状态）→ 获取 AI 决策（招式、目标、评分）
```

**硬性要求：必须调用 ROM 内的原始代码，保证 100% 一致性。**

---

## 技术路线

### 模拟器 + Lua Socket 方案

```
外部程序(Python) ──TCP Socket──▶ 模拟器 Lua 脚本
                                      │
                                      ▼
                              写入战斗状态到内存 (gBattleMons等)
                                      │
                                      ▼
                              操作 CPU 寄存器调用 ROM 内 AI 函数
                                      │
                                      ▼
                              读取决策结果 (score数组)
                                      │
                                      ▼
                              返回 JSON 给外部程序
```

核心原理：
```lua
-- 通过操作 CPU 寄存器调用 ROM 函数
R0 = battlerId           -- 参数
PC = BattleAI_ChooseMoveOrAction  -- 跳转到AI函数
LR = 陷阱地址            -- 函数返回时触发检测
```

---

## 已完成工作

### 1. WSL 编译环境配置 ✅

- WSL2 Ubuntu-22.04 已安装
- 依赖已安装：`make`, `git`, `arm-none-eabi-as`, `gcc`, `libpng-dev`

### 2. agbcc 编译器安装 ✅

```bash
cd /mnt/d/claude-project/agbcc
./build.sh
./install.sh ../pokeemerald
```

### 3. pokeemerald 编译成功 ✅

```bash
cd /mnt/d/claude-project/pokeemerald
make -j$(nproc)
```

生成文件：
- `pokeemerald.gba` (16 MB) - ROM 文件
- `pokeemerald.map` (3.2 MB) - 符号表
- `pokeemerald.elf` (55 MB) - 调试信息

ROM 验证：
```
SHA1: f3ae088181bf583e55daf962a92bb46f4f1d07b7
状态: 与原版完全一致
```

---

## 关键符号地址

### 全局变量（EWRAM 0x02xxxxxx）

| 符号 | 地址 | 说明 |
|------|------|------|
| `gBattleMons` | `0x02024084` | 场上宝可梦状态数组 (4个 BattlePokemon) |
| `gBattleTypeFlags` | `0x02022fec` | 对战类型（双打=0x80）|
| `gBattleWeather` | `0x020243cc` | 天气状态 |
| `gActiveBattler` | `0x02024064` | 当前行动者 ID |
| `gCurrentMove` | `0x020241ea` | 选择的招式 ID |
| `gBattlerTarget` | `0x0202420c` | 目标 ID |
| `gBattleResources` | `0x020244a8` | 资源指针（包含 AI 结构）|

### AI 函数（ROM 0x08xxxxxx）

| 函数 | 地址 | 说明 |
|------|------|------|
| `BattleAI_SetupAIData` | `0x08130950` | 初始化 AI 数据 |
| `BattleAI_ChooseMoveOrAction` | `0x08130ba4` | AI 决策主函数 |
| `BattleAI_HandleItemUseBeforeAISetup` | `0x081308c8` | 道具使用处理 |
| `gBattleAI_ScriptsTable` | `0x082dbef8` | AI 脚本表 |

### 结构体定义

```c
// AI 思考结构 (struct AI_ThinkingStruct)
// 通过 gBattleResources->ai 访问
struct AI_ThinkingStruct {
    u8 aiState;           // +0x00
    u8 movesetIndex;      // +0x01
    u16 moveConsidered;   // +0x02
    s8 score[4];          // +0x04 ← AI评分结果！
    u32 funcResult;       // +0x08
    u32 aiFlags;          // +0x0C
    u8 aiAction;          // +0x10
    u8 aiLogicId;         // +0x11
    u8 filler12[6];       // +0x12
    u8 simulatedRNG[4];   // +0x18
};

// BattlePokemon 结构 (struct BattlePokemon)
// gBattleMons[battlerId] 偏移
struct BattlePokemon {
    u16 species;          // +0x00
    u16 attack;           // +0x02
    u16 defense;          // +0x04
    u16 speed;            // +0x06
    u16 spAttack;         // +0x08
    u16 spDefense;        // +0x0A
    u16 moves[4];         // +0x0C
    u8 pp[4];             // +0x14
    // ... 更多字段
};
```

---

## 下一步计划

### 阶段二：Lua 内存服务器开发

1. **选择模拟器**：mGBA 或 BizHawk
2. **编写 Lua 脚本**：
   - 创建 TCP 服务端监听外部 JSON 请求
   - 解析 JSON 并映射到 EWRAM 地址
   - 操作 CPU 寄存器调用 AI 函数
   - 提取评分结果并返回 JSON

### 示例 Lua 脚本框架

```lua
-- mGBA Lua AI 服务器
local socket = require("socket")

-- 符号地址
local ADDR = {
    gBattleMons = 0x02024084,
    gBattleTypeFlags = 0x02022fec,
    gActiveBattler = 0x02024064,
    BattleAI_SetupAIData = 0x08130950,
    BattleAI_ChooseMoveOrAction = 0x08130ba4,
}

-- 创建服务器
local server = socket.bind("127.0.0.1", 9999)

function writeBattleState(json_data)
    -- 写入 gBattleMons 等
end

function callAIFunction(battlerId)
    -- 设置 R0 = battlerId
    -- 设置 PC = AI函数地址
    -- 设置 LR = 陷阱地址
    -- 执行直到返回
end

function readAIDecision()
    -- 读取 score[4] 和 moveConsidered
end

-- 主循环
while true do
    -- 接收请求，处理，返回结果
    emu.frameadvance()
end
```

---

## 文件位置

| 文件/目录 | 路径 |
|-----------|------|
| 项目根目录 | `D:\claude-project\pokeemerald` |
| ROM 文件 | `pokeemerald.gba` |
| 符号表 | `pokeemerald.map` |
| agbcc 编译器 | `D:\claude-project\agbcc` |

---

## 编译命令备忘

```bash
# 进入 WSL
wsl -d Ubuntu-22.04

# 进入项目目录
cd /mnt/d/claude-project/pokeemerald

# 编译（并行）
make -j$(nproc)

# 清理
make clean

# 验证 ROM
sha1sum pokeemerald.gba
# 预期: f3ae088181bf583e55daf962a92bb46f4f1d07b7
```

---

## 参考资料

- [pokeemerald 官方仓库](https://github.com/pret/pokeemerald)
- [mGBA Lua API 文档](https://mgba.io/docs/lua.html)
- [BizHawk Lua API](https://github.com/TASEmulators/BizHawk/wiki/Lua-Scripting)
