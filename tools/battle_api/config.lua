-- Battle API Configuration
-- Addresses from pokeemerald.map

local Config = {}

-- Memory addresses (Emerald BPEE)
Config.ADDRESS = {
    gBattleTypeFlags   = 0x02022FEC,
    gBattleMons        = 0x02024084,
    gPlayerParty       = 0x020244EC,
    gEnemyParty        = 0x02024744,
    ActionInjectData   = 0x0203D200,
    gDisplayedStringBattle = 0x02022E2C,
}

-- BattlePokemon structure size and offsets
Config.BATTLE_MON = {
    size = 0x58,
    offset = {
        species    = 0x00,  -- u16
        attack     = 0x02,  -- u16
        defense    = 0x04,  -- u16
        speed      = 0x06,  -- u16
        spAttack   = 0x08,  -- u16
        spDefense  = 0x0A,  -- u16
        moves      = 0x0C,  -- u16[4]
        pp         = 0x14,  -- u8[4]
        hp         = 0x1C,  -- u16 (offset may need verification)
        maxHp      = 0x1E,  -- u16
        level      = 0x20,  -- u8
        ability    = 0x22,  -- u8
        types      = 0x24,  -- u8[2]
    }
}

-- Action inject structure
Config.ACTION_INJECT = {
    magic   = 0xDEADBEEF,
    offset = {
        magic    = 0x00,  -- u32
        enabled  = 0x04,  -- u8
        waiting  = 0x05,  -- u8
        reserved = 0x06,  -- u8[2]
        actions  = 0x08,  -- SingleActionData[2]
    },
    actionSize = 4,
    actionOffset = {
        action     = 0x00,  -- u8
        moveIndex  = 0x01,  -- u8
        target     = 0x02,  -- u8
        switchMon  = 0x03,  -- u8
    }
}

-- B_ACTION constants
Config.B_ACTION = {
    USE_MOVE = 0,
    USE_ITEM = 1,
    SWITCH   = 2,
    RUN      = 3,
}

-- Battle phase constants
Config.BATTLE_PHASE = {
    NONE          = 0,
    ACTION_SELECT = 1,
    TEXT_WAIT     = 2,
    FORCED_SWITCH = 3,
    BATTLE_END    = 4,
}

-- Server configuration
Config.SERVER = {
    host = "127.0.0.1",
    port = 8080,
}

-- State save path (relative to BizHawk)
Config.STATE_PATH = "../../GBA/State/"

return Config
