# AI Play Pokemon

基于强化学习范式的仿真 Agent 决策框架，通过 HTTP REST 接口与 BizHawk 模拟器通信。

## 项目结构

```
ai-play-pokemon/
├── ai-play-pokemon/              # Java 后端项目
│   └── src/
│       ├── main/java/            # 主要代码
│       └── test/java/            # 单元测试
├── pokemon-memory-reader/        # Lua 脚本源码
│   ├── main.lua                  # 入口脚本
│   ├── network/                  # HTTP 服务模块
│   ├── readers/                  # 内存读取模块
│   └── ...
├── build-lua.bat                 # Lua 构建脚本
└── README.md
```

## 环境要求

- Java 17+
- BizHawk 2.11 (GBA 模拟器)
- Pokemon Emerald ROM

## 快速开始

### 1. 构建 Lua 脚本

```bash
build-lua.bat
```

生成的脚本位于 `BizHawk-2.11-win-x64/Lua/GBA/pokemon-memory-reader.lua`

### 2. 启动 BizHawk

1. 打开 BizHawk，加载 Pokemon Emerald ROM
2. 打开 Lua 控制台 (Tools -> Lua Console)
3. 加载脚本 `Lua/GBA/pokemon-memory-reader.lua`

### 3. 启动 Java 后端

```bash
cd ai-play-pokemon
mvn spring-boot:run
```

### 4. 测试 API

```bash
# 加载存档
curl "http://localhost:8080/loadstate?name=Double-Battle-Test"

# 获取队伍信息
curl "http://localhost:8080/party"

# 获取玩家信息
curl "http://localhost:8080/player"

# 发送按键
curl "http://localhost:8080/input?buttons=A,B,UP"
```

## API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/party` | GET | 获取队伍信息 |
| `/player` | GET | 获取玩家信息 |
| `/bag` | GET | 获取背包信息 |
| `/enemy` | GET | 获取敌方信息 |
| `/battle` | GET | 获取战斗状态 |
| `/map` | GET | 获取地图信息 |
| `/input` | GET | 发送按键序列 |
| `/loadstate` | GET | 加载存档 |
| `/status` | GET | 获取服务状态 |

## 支持的按键

`A`, `B`, `L`, `R`, `START`, `SELECT`, `UP`, `DOWN`, `LEFT`, `RIGHT`

## 技术栈

- Java 17 + Spring Boot
- Spring AI Alibaba (LLM Agent)
- Lua (BizHawk 脚本)
- Apache HttpClient

## License

MIT
