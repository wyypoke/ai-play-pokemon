# 训练师队伍注入 - 工作日志

## 2026-04-02

### 问题背景
用户希望通过外部注入的方式修改训练师队伍数据，包括精灵种类、等级、技能等。

### 遇到的问题

#### 问题1: 即时存档不兼容
- **原因**: 即时存档保存了原版 ROM 的执行状态，无法跨 ROM 版本使用
- **解决**: 使用电池存档（.sav 文件）

#### 问题2: 等级修改无效
- **现象**: 修改代码后，战斗中显示的等级没有变化
- **原因分析过程**:
  1. 最初在 `CreateNPCTrainerParty` 中添加 `SetMonData(&party[i], MON_DATA_LEVEL, &level)` - 无效
  2. 在 `CB2_InitBattle` 中修改 `gEnemyParty` - 无效
  3. 在 `BattleIntroDrawTrainersOrMonsSprites` 中修改 `gBattleMons` - 经验值正确但显示等级错误
  4. 发现 `CalculateMonStats` 会从经验值重新计算等级并覆盖设置的值

#### 问题3: Lua 脚本写入空地址
- **原因**: BizHawk API 检测逻辑有误，使用了错误的 API
- **解决**: 简化为单次注入，直接使用 BizHawk 的 `memory.write_xx` API

### 关键发现

`CalculateMonStats` 函数会从经验值计算等级：
```c
s32 level = GetLevelFromMonExp(mon);  // 从经验值计算等级
SetMonData(mon, MON_DATA_LEVEL, &level);  // 覆盖我们设置的等级！
```

**解决方案**: 设置经验值而不是直接设置等级：
```c
u16 species = GetMonData(&party[i], MON_DATA_SPECIES);
u32 exp = gExperienceTables[gSpeciesInfo[species].growthRate][level];
SetMonData(&party[i], MON_DATA_EXP, &exp);
CalculateMonStats(&party[i]);
```

### 修改的文件

1. **src/battle_main.c**
   - `CreateNPCTrainerParty` 函数末尾添加注入逻辑
   - 当前使用注入地址判断，需要验证

2. **include/injected_party.h**
   - 定义注入地址和魔数

3. **tools/inject_party.lua**
   - 单次注入脚本

### 当前状态

- 已实现设置经验值来控制等级
- Lua 脚本已简化为单次注入
- **待测试**: 确认固定等级是否生效

### 下一步

1. 测试固定等级 50 是否生效
2. 如果生效，恢复注入判断逻辑
3. 测试 Lua 注入是否正常工作
4. 扩展支持更多字段（species、moves 等）

### 数据结构

```
0x0203D000: magic (4B) = 0xDEADBEEF
0x0203D004: trainerId (2B) - 未使用
0x0203D006: partySize (1B) - 未使用
0x0203D007: enabled (1B) - 非0启用
0x0203D008: species (2B) - 未使用
0x0203D00A: level (1B) - 目标等级
```
