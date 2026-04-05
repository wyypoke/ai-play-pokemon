-- AI Server Configuration
-- 从 pokeemerald.map 提取的符号地址

local Config = {}

-- GBA 内存布局
Config.MEMORY = {
    EWRAM_BASE = 0x02000000,  -- EWRAM 起始地址
    IWRAM_BASE = 0x03000000,  -- IWRAM 起始地址
    ROM_BASE   = 0x08000000,  -- ROM 起始地址
}

-- 全局变量地址 (EWRAM)
Config.ADDRESS = {
    -- 战斗状态
    gBattleMons        = 0x02024084,  -- struct BattlePokemon[4]
    gBattleTypeFlags   = 0x02022fec,  -- u32
    gBattleWeather     = 0x020243cc,  -- u16
    gActiveBattler     = 0x02024064,  -- u8
    gBattlerTarget     = 0x0202420c,  -- u8
    gCurrentMove       = 0x020241ea,  -- u16

    -- 资源指针
    gBattleResources   = 0x020244a8,  -- struct BattleResources*

    -- 其他战斗相关
    gAbsentBattlerFlags = 0x02024062, -- u8
    gBattlerPartyIndexes = 0x02024064, -- u16[4]
}

-- AI 函数地址 (ROM)
Config.AI_FUNC = {
    BattleAI_SetupAIData          = 0x08130950,
    BattleAI_ChooseMoveOrAction   = 0x08130ba4,
    BattleAI_HandleItemUseBeforeAISetup = 0x081308c8,
    gBattleAI_ScriptsTable        = 0x082dbef8,
}

-- 结构体大小和偏移
Config.STRUCT = {
    -- BattlePokemon 结构 (gBattleMons[i])
    BattlePokemon = {
        size = 0x58,  -- 约 88 字节
        offset = {
            species    = 0x00,  -- u16
            attack     = 0x02,  -- u16
            defense    = 0x04,  -- u16
            speed      = 0x06,  -- u16
            spAttack   = 0x08,  -- u16
            spDefense  = 0x0A,  -- u16
            moves      = 0x0C,  -- u16[4]
            pp         = 0x14,  -- u8[4]
            hp         = 0x1C,  -- u16 (实际偏移需确认)
            maxHp      = 0x1E,  -- u16
            level      = 0x20,  -- u8
            ability    = 0x22,  -- u8
            types      = 0x24,  -- u8[2]
            -- ... 更多字段需要从 battle.h 确认
        }
    },

    -- AI_ThinkingStruct (通过 gBattleResources->ai 访问)
    AI_Thinking = {
        size = 0x20,
        offset = {
            aiState       = 0x00,  -- u8
            movesetIndex  = 0x01,  -- u8
            moveConsidered = 0x02, -- u16
            score         = 0x04,  -- s8[4] ← AI评分！
            funcResult    = 0x08,  -- u32
            aiFlags       = 0x0C,  -- u32
            aiAction      = 0x10,  -- u8
            aiLogicId     = 0x11,  -- u8
            simulatedRNG  = 0x18,  -- u8[4]
        }
    },

    -- BattleResources 结构
    BattleResources = {
        offset = {
            secretBase          = 0x00,
            flags               = 0x04,
            battleScriptsStack  = 0x08,
            battleCallbackStack = 0x0C,
            beforeLvlUp         = 0x10,
            ai                  = 0x14,  -- AI_ThinkingStruct*
            battleHistory       = 0x18,
            AI_ScriptsStack     = 0x1C,
        }
    }
}

-- 对战类型标志
Config.BATTLE_TYPE = {
    DOUBLE       = 0x80,
    TRAINER      = 0x01,
    WILD         = 0x00,
    LINK         = 0x02,
}

-- 服务器配置
Config.SERVER = {
    host = "127.0.0.1",
    port = 9999,
}

return Config
