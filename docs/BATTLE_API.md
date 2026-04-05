# HTTP Battle API 文档

## 概述

本 API 提供对 Pokemon Emerald 模拟器的 HTTP 控制接口，用于 AI 自动对战。

- **服务器地址**: `http://127.0.0.1:8080`
- **协议**: HTTP/1.1
- **数据格式**: JSON
- **字符编码**: UTF-8

---

## 快速开始

```bash
# 1. 启动 BizHawk 并加载 ROM 和 Lua 脚本
# 2. 检查战斗状态
curl http://localhost:8080/battle

# 3. 启用行动劫持模式
curl -X POST http://localhost:8080/action/enable

# 4. 注入招式
curl -X POST http://localhost:8080/action/move -H "Content-Type: application/json" -d "{\"move\":0,\"target\":1}"

# 5. 注入切换
curl -X POST http://localhost:8080/action/switch -H "Content-Type: application/json" -d "{\"slot\":2}"
```

---

## API 端点总览

| 端点 | 方法 | 描述 |
|------|------|------|
| `/battle` | GET | 获取战斗中的宝可梦信息 |
| `/party` | GET | 获取玩家队伍 |
| `/enemy` | GET | 获取敌方队伍 |
| `/log` | GET | 获取战斗日志 |
| `/log/clear` | POST | 清空战斗日志 |
| `/phase` | GET | 获取战斗阶段 |
| `/action/enable` | POST | 启用行动劫持模式 |
| `/action/disable` | POST | 禁用行动劫持模式 |
| `/action/move` | POST | 注入招式行动 |
| `/action/switch` | POST | 注入切换行动 |
| `/loadstate` | GET | 加载存档 |

---

## 详细端点说明

### 1. GET /battle

获取当前战斗中的宝可梦信息。

**请求**:
```
GET /battle
```

**响应**:
```json
{
    "inBattle": true,
    "isDouble": false,
    "pokemon": [
        {
            "battlerIndex": 0,
            "species": 25,
            "level": 50,
            "hp": 120,
            "maxHp": 120,
            "attack": 80,
            "defense": 60,
            "speed": 90,
            "spAttack": 70,
            "spDefense": 65,
            "moves": [85, 86, 87, 88],
            "pp": [15, 20, 10, 5]
        }
    ]
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `inBattle` | boolean | 是否在战斗中 |
| `isDouble` | boolean | 是否为双打 |
| `pokemon` | array | 场上宝可梦列表（最多4只） |
| `battlerIndex` | number | 战斗位置索引 (0-3) |
| `species` | number | 种族ID |
| `level` | number | 等级 |
| `hp` | number | 当前HP |
| `maxHp` | number | 最大HP |
| `attack` | number | 攻击力 |
| `defense` | number | 防御力 |
| `speed` | number | 速度 |
| `spAttack` | number | 特攻 |
| `spDefense` | number | 特防 |
| `moves` | array[4] | 招式ID列表 |
| `pp` | array[4] | PP值列表 |

---

### 2. GET /party

获取玩家队伍信息。

**请求**:
```
GET /party
```

**响应**:
```json
{
    "party": [
        {
            "partyIndex": 0,
            "species": 25,
            "level": 50,
            "hp": 120,
            "maxHp": 120,
            "nature": 10,
            "friendship": 255,
            "moves": [85, 86, 87, 88],
            "pp": [15, 20, 10, 5],
            "evs": {...},
            "ivs": {...}
        }
    ]
}
```

**注意**: 队伍数据是加密存储的，API 会自动解密。

---

### 3. GET /enemy

获取敌方队伍信息。格式与 `/party` 相同。

---

### 4. GET /log

获取战斗日志历史。

**请求**:
```
GET /log
```

**响应**:
```json
[
    "Wild PIKACHU appeared!",
    "Go! CHARMANDER!",
    "What will CHARMANDER do?"
]
```

**说明**:
- 日志每帧自动累积
- 文本变化时自动追加到历史
- 不在战斗中时自动清空

---

### 5. POST /log/clear

手动清空战斗日志。

**请求**:
```
POST /log/clear
```

**响应**:
```json
{
    "success": true,
    "message": "Log history cleared"
}
```

---

### 6. GET /phase

获取当前战斗阶段。

**请求**:
```
GET /phase
```

**响应**:
```json
{
    "phase": 2,
    "isDouble": false,
    "inBattle": true
}
```

**阶段枚举**:

| 值 | 常量名 | 说明 |
|----|--------|------|
| 0 | `NONE` | 不在战斗中 |
| 1 | `INTRO` | 战斗开场动画 |
| 2 | `ACTION_SELECT` | 行动选择（等待输入） |
| 3 | `MOVE_EXECUTION` | 招式执行中 |
| 4 | `FAINT_SWITCH` | 濒死替换选择 |
| 5 | `END` | 战斗结束 |

**用途**: AI 可以根据阶段判断当前需要执行什么操作。

---

### 7. POST /action/enable

启用行动劫持模式。

**请求**:
```
POST /action/enable
```

**响应**:
```json
{
    "success": true,
    "message": "Hijack mode enabled"
}
```

**说明**:
- 必须在使用 `/action/move` 或 `/action/switch` 前调用
- 会清除之前的行动数据
- 设置魔术数字 `0xDEADBEEF` 到内存

---

### 8. POST /action/disable

禁用行动劫持模式。

**请求**:
```
POST /action/disable
```

**响应**:
```json
{
    "success": true,
    "message": "Hijack mode disabled"
}
```

---

### 9. POST /action/move

注入招式行动。

**请求**:
```
POST /action/move
Content-Type: application/json

{
    "move": 0,
    "target": 1
}
```

**参数**:

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `move` | number | 是 | 招式位置 (0-3) |
| `target` | number | 否 | 目标位置 (默认1) |
| `move2` | number | 否 | 双打时第二只宝可梦的招式 |
| `target2` | number | 否 | 双打时第二只宝可梦的目标 |

**响应**:
```json
{
    "success": true,
    "message": "Move injected"
}
```

**目标位置说明**:

| 值 | 单打 | 双打 |
|----|------|------|
| 0 | 玩家 | 玩家左 |
| 1 | 对手 | 对手左 |
| 2 | - | 玩家右 |
| 3 | - | 对手右 |

**示例 - 双打**:
```json
{
    "move": 0,
    "target": 1,
    "move2": 2,
    "target2": 3
}
```

---

### 10. POST /action/switch

注入切换行动。

**请求**:
```
POST /action/switch
Content-Type: application/json

{
    "slot": 2
}
```

**参数**:

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `slot` | number | 是 | 切换到的队伍位置 (0-5) |
| `slot2` | number | 否 | 双打时第二只宝可梦切换位置 |

**响应**:
```json
{
    "success": true,
    "message": "Switch injected"
}
```

**注意**:
- `slot` 是队伍中的位置 (0-5)，不是战斗位置
- 不能切换到当前场上的宝可梦
- 不能切换到濒死的宝可梦

---

### 11. GET /loadstate

加载存档状态。

**请求**:
```
GET /loadstate?name=before_battle
```

**参数**:

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 存档名称（不含扩展名） |

**响应**:
```json
{
    "success": true,
    "message": "State loaded: before_battle"
}
```

**存档路径**: `BizHawk/GBA/State/{name}.State`

---

## 使用流程

### 标准战斗流程

```
1. 轮询 GET /phase 等待 phase == 2 (ACTION_SELECT)
2. 调用 GET /battle 获取场上信息
3. 调用 GET /party 获取队伍信息（如需）
4. 调用 POST /action/enable 启用劫持
5. 调用 POST /action/move 或 /action/switch 注入行动
6. 重复步骤1-5直到战斗结束
```

### 伪代码示例

```java
// 1. 等待行动选择阶段
while (getPhase() != 2) {
    Thread.sleep(100);
}

// 2. 获取战斗信息
BattleInfo battle = getBattle();
PartyInfo party = getParty();

// 3. 启用劫持
postActionEnable();

// 4. 选择招式
int moveIndex = selectBestMove(battle, party);
postActionMove(moveIndex, 1);  // target=1 对手

// 5. 等待下一回合
while (getPhase() == 3) {  // MOVE_EXECUTION
    Thread.sleep(100);
}
```

---

## 常量定义

### B_ACTION - 行动类型

```java
public static final int B_ACTION_USE_MOVE = 0;
public static final int B_ACTION_USE_ITEM = 1;
public static final int B_ACTION_SWITCH   = 2;
public static final int B_ACTION_RUN      = 3;
```

### BATTLE_PHASE - 战斗阶段

```java
public static final int BATTLE_PHASE_NONE           = 0;
public static final int BATTLE_PHASE_INTRO          = 1;
public static final int BATTLE_PHASE_ACTION_SELECT  = 2;
public static final int BATTLE_PHASE_MOVE_EXECUTION = 3;
public static final int BATTLE_PHASE_FAINT_SWITCH   = 4;
public static final int BATTLE_PHASE_END            = 5;
```

---

## 内存地址参考

| 变量 | 地址 |
|------|------|
| gBattleTypeFlags | 0x02022FEC |
| gBattleMons | 0x02024084 |
| gPlayerParty | 0x020244EC |
| gEnemyParty | 0x02024744 |
| gDisplayedStringBattle | 0x02022E2C |
| ActionInjectData | 0x0203D200 |

---

## 错误处理

所有错误返回格式：

```json
{
    "error": "错误描述"
}
```

常见错误：

| HTTP状态码 | 说明 |
|-----------|------|
| 400 | 请求参数错误 |
| 404 | 端点不存在 |
| 405 | HTTP方法不允许 |
| 500 | 服务器内部错误 |

---

## 注意事项

1. **Windows curl JSON 格式**: 使用双引号和转义
   ```bash
   # 错误
   curl -d '{move:0}'

   # 正确
   curl -d "{\"move\":0}"
   ```

2. **行动注入时序**: 必须在 `phase == 2` (ACTION_SELECT) 时注入，否则可能无效

3. **双打支持**: 当前双打切换仍有问题，只有一只宝可梦生效

4. **经验值跳过**: 当前版本完全跳过经验值分配

5. **文本自动滚动**: 文本会自动推进，无需按A键

---

## 项目结构

```
tools/battle_api/
├── main.lua        # 入口文件
├── server.lua      # HTTP服务器
├── api.lua         # API处理器
├── readers.lua     # 内存读取
├── config.lua      # 配置
├── dkjson.lua      # JSON库
└── squishy         # 打包配置
```

构建命令：
```bash
cd tools/battle_api
lua ../../../ai-play-pokemon/archived/tools/squish/squish.lua --no-minify --output=battle_api.lua
cp battle_api.lua ../../../ai-play-pokemon/archived/emulators/BizHawk-2.11-win-x64/Lua/GBA/battle_api.lua
```

---

## 版本历史

- **v1.3** - 添加战斗阶段标志、跳过经验值、自动文本滚动
- **v1.2** - 添加日志历史累积
- **v1.1** - 添加 HTTP Battle API
- **v1.0** - 初始版本，行动劫持系统
