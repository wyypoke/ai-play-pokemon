# 输出格式约束（强制 JSON 状态机）

你必须严格按照以下 JSON 格式返回推演结果，不得输出任何 Markdown 说明文字、前言或总结。所有字段均为必填。

```json
{
  "turn": 1,
  "status": "ongoing",
  "reason": "简要说明当前回合核心战略逻辑",
  "action_flow": [
    {
      "order": 1,
      "pokemon": "物种名/昵称",
      "side": "我方/对方",
      "type": "active",
      "action": "具体招式/道具/替换上场宝可梦",
      "target": "目标位置",
      "reason": "基于数值证据的逻辑断言（如：达成 OHKO 判定、属性强化必要性）",
      "evidence": [
        {
          "tool": "compareSpeeds/calculateDamage",
          "result": "数值对比摘要（如：伤害区间与当前 HP 的对比结论）"
        }
      ],
      "hp_snapshot": {
        "我方左边宝可梦": "当前HP/最大HP",
        "我放右边宝可梦": "当前HP/最大HP",
        "对方左边宝可梦": "当前HP/最大HP",
        "对方右边宝可梦": "当前HP/最大HP"
      }
    }
  ]
}
```

## 字段说明

- `status`: 枚举值 `"ongoing"`, `"win"`, `"lose"`
- `type`: 枚举值 `"active"`(正常行动), `"switch"`(主动替换), `"fainted_replacement"`(被动濒死替换)
- `target`: 如 "对方左", "我方右", "全体", "无"

## 逻辑断言与时序准则

### 时序驱动 (Sequence Driven)
- `action_flow` 数组必须严格按速度降序（从快到慢）排列
- 主动替换：占据该宝可梦本回合的出手位阶，后续不得再执行招式
- 被动替换：若某宝可梦 HP 归零，必须立即插入一个 `type: "fainted_replacement"` 的记录。被替换上场的单位在本回合不再执行主动招式

### 目标重定向 (Target Redirection)
在 Gen 3 双打机制下，若原定目标在出手前因濒死被替换，后续宝可梦的单体招式将作用于替换上场的单位。你必须在 `hp_snapshot` 中准确反映这一结算。

### HP 实时快照 (Real-time HP Snapshot)
每个 `action_flow` 元素必须包含 `hp_snapshot` 字段，记录该动作执行完毕后，场上所有活跃单位的最新 HP 数值。

### 终止判定 (Termination)
仅当 PC 获得绝对先手（含对方后备）且具备 1HKO 数值证据时，`status` 标记为 `"win"` 并停止推演。
