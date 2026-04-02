#ifndef GUARD_INJECTED_PARTY_H
#define GUARD_INJECTED_PARTY_H

// 注入地址定义 (EWRAM 空闲区域)
#define INJECTED_PARTY_ADDR     0x0203D000

// 魔数标识
#define INJECTED_PARTY_MAGIC    0xDEADBEEF

// 简化的注入结构体 (用于最小化测试)
// offset 0-3:   magic (u32) = 0xDEADBEEF
// offset 4-5:   trainerId (u16) - 暂未使用
// offset 6:     partySize (u8) - 暂未使用
// offset 7:     enabled (u8) - 非0启用
// offset 8-9:   species (u16) - 暂未使用
// offset 10:    level (u8) - 第一只精灵的新等级

#endif // GUARD_INJECTED_PARTY_H
