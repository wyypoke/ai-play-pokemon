# AI Play Pokemon

基于强化学习范式的仿真 Agent 决策框架，通过 HTTP REST 接口与 BizHawk 模拟器通信。

## 项目结构

```
ai-play-pokemon/
├── ai-play-pokemon/              # Java 后端项目
│   └── src/
│       ├── main/java/            # 主要代码
│       └── test/java/            # 单元测试
├── pokeemerald/                  # Pokemon Emerald 源码（修改版）
│   └── ai_server/                # Lua HTTP 服务
├── archived/                     # 归档文件
└── README.md
```

## 环境要求

- Java 17+
- BizHawk 2.11 (GBA 模拟器) 或 mGBA
- Pokemon Emerald ROM

## 快速开始

### 1. 编译 pokeemerald (可选)

```bash
cd pokeemerald
make
```

### 2. 启动 Lua 服务器

在 mGBA 中加载 ROM 和 `pokeemerald/ai_server/main.lua`

### 3. 启动 Java 后端

```bash
cd ai-play-pokemon
mvn spring-boot:run
```

### 4. 运行测试

```bash
mvn test -Dtest=EmulatorBattleGraphTest
```

## API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/party` | GET | 获取队伍信息 |
| `/battle` | GET | 获取战斗状态 |
| `/phase` | GET | 获取战斗阶段 |
| `/action/move` | POST | 注入招式行动 |
| `/action/switch` | POST | 注入替换行动 |
| `/loadstate` | GET | 加载存档 |
| `/screenshot` | GET | 获取截图 |

## 技术栈

- Java 17 + Spring Boot
- Spring AI Alibaba (LLM Agent)
- Lua (mGBA/BizHawk 脚本)
- pokeemerald (Pokemon Emerald 反编译)

## pokeemerald

基于 Pokémon Emerald 反编译项目，添加了 AI 对战接口。

原始项目: [pret/pokeemerald](https://github.com/pret/pokeemerald)

## License

MIT
