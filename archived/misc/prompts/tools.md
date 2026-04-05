# 工具调用方法


## 速度线工具

**工具名称**：`compareSpeeds`

**功能**：计算场上宝可梦的速度并返回出手顺序

**参数格式**（JSON数组字符串）：
```json
[
  {"species": "Swampert", "level": 42, "iv": 29, "ev": 47, "nature": "Naughty", "position": "我方左"},
  {"species": "Castform", "level": 28, "iv": 0, "ev": 8, "nature": "Brave", "position": "我方右"},
  {"species": "Claydol", "level": 41, "iv": 30, "ev": 0, "nature": "Lax", "position": "敌方左"},
  {"species": "Xatu", "level": 41, "iv": 30, "ev": 0, "nature": "Docile", "position": "敌方右"}
]
```

**参数说明**：
- `species`: 宝可梦英文名（如 Swampert, Claydol, Xatu, Castform）
- `level`: 等级 (1-100)
- `iv`: 速度个体值 (0-31)
- `ev`: 速度努力值 (0-252)
- `nature`: 性格英文名（如 Jolly, Timid, Brave, Naughty）
- `position`: 场上位置标识（如 "我方左"、"我方右"、"敌方左"、"敌方右"）

**输出**：当前回合的行动顺序（从快到慢）

---

## 伤害计算工具

**工具名称**：`calculateDamage`

**功能**：计算招式伤害范围和击杀概率

**必填参数**：
- `attackingPokemon`: 攻击方宝可梦英文名（如 "Swampert"）
- `defendingPokemon`: 防守方宝可梦英文名（如 "Claydol"）
- `moveName`: 招式英文名（如 "Surf", "Earthquake"）

**可选参数**：
- `attackerLevel`: 攻击方等级
- `attackerAbility`: 攻击方特性（如 "Torrent"）
- `attackerItem`: 攻击方道具（如 "Mystic Water"）
- `attackerNature`: 攻击方性格
- `attackerIvs`: 个体值JSON，如 `{"spa":30}`
- `attackerEvs`: 努力值JSON，如 `{"spa":32}`
- `attackerBoosts`: 能力阶级JSON，如 `{"spa":1}` 表示+1特攻
- `defenderLevel`: 防守方等级
- `defenderAbility`: 防守方特性（如 "Levitate"）
- `defenderItem`: 防守方道具
- `defenderNature`: 防守方性格
- `defenderIvs`: 防守方个体值JSON
- `defenderEvs`: 防守方努力值JSON
- `defenderCurHP`: 防守方当前HP（用于计算击杀概率）
- `gameType`: 对战模式，双打填 `"Doubles"`
- `weather`: 天气，如 `"Sun"`(大晴天)、`"Rain"`(雨天)、`"Hail"`(冰雹)
- `isHelpingHand`: 是否有帮手加成（双打）
- `isFriendGuard`: 是否有友情防守（双打）

