-- Memory Readers
-- Read game data from memory

local Config = require("config")

local Readers = {}

-- Log history storage
local logState = {
    history = {},
    lastText = ""
}

-- GBA character mapping (Gen3)
local GBACharmap = {
    [0] = " ", "À", "Á", "Â", "Ç", "È", "É", "Ê", "Ë", "Ì", "こ", "Î", "Ï", "Ò", "Ó", "Ô",
    "Œ", "Ù", "Ú", "Û", "Ñ", "ß", "à", "á", "ね", "ç", "è", "é", "ê", "ë", "ì", "ま",
    "î", "ï", "ò", "ó", "ô", "œ", "ù", "ú", "û", "ñ", "º", "ª", "", "&", "+", "あ",
    "ぃ", "ぅ", "ぇ", "ぉ", "v", "=", "ょ", "が", "ぎ", "ぐ", "げ", "ご", "ざ", "じ", "ず", "ぜ",
    "ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",
    "っ", "¿", "¡", "Pk", "Mn", "Po", "Ké", "", "", "", "Í", "%", "(", ")", "セ", "ソ",
    "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "â", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "í",
    "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "↑", "↓", "←", "→", "ヲ", "ン", "ァ",
    "ィ", "ゥ", "ェ", "ォ", "ャ", "ュ", "ョ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ",
    "ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ",
    "ッ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?", ".", "-", "・",
    "…", "\"", "\"", "'", "'", "♂", "♀", "$", ",", "×", "/", "A", "B", "C", "D", "E",
    "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
    "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
    "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "▶",
    ":", "Ä", "Ö", "Ü", "ä", "ö", "ü", "↑", "↓", "←", "", "", "", "", "", ""
}

-- Helper functions
local function read_u8(addr)
    return memory.read_u8(addr)
end

local function read_u16(addr)
    return memory.read_u16_le(addr)
end

local function read_u32(addr)
    return memory.read_u32_le(addr)
end

local function get_bits(value, start, length)
    local mask = (1 << length) - 1
    return (value >> start) & mask
end

-- Get battle log
function Readers.getLog()
    local result = {}
    for _, line in ipairs(logState.history) do
        table.insert(result, line)
    end
    if logState.lastText ~= "" then
        table.insert(result, logState.lastText)
    end
    return result
end

-- Update log (call every frame)
function Readers.updateLog()
    local currentText = Readers.getBattleText()
    local inBattle = Readers.isInBattle()

    -- Not in battle, clear history
    if not inBattle then
        logState.history = {}
        logState.lastText = ""
        return
    end

    -- Text changed
    if currentText ~= logState.lastText and currentText ~= "" then
        -- Append old text to history if non-empty
        if logState.lastText ~= "" then
            table.insert(logState.history, logState.lastText)
        end
        logState.lastText = currentText
    end
end

-- Clear log history
function Readers.clearLog()
    logState.history = {}
    logState.lastText = ""
end

-- Get battle text (raw, no history)
function Readers.getBattleText()
    local addr = Config.ADDRESS.gDisplayedStringBattle
    local text = {}

    for i = 0, 299 do
        local b = read_u8(addr + i)
        if b == 0xFF then break end  -- GBA string terminator
        table.insert(text, GBACharmap[b] or "?")
    end

    return table.concat(text)
end

-- Data order table for Gen3 Pokemon decryption
local dataOrderTable = {
    growth = {1,1,1,1,1,1, 2,2,3,4,3,4, 2,2,3,4,3,4, 2,2,3,4,3,4},
    attack = {2,2,3,4,3,4, 1,1,1,1,1,1, 3,4,2,2,4,3, 3,4,2,2,4,3},
    effort = {3,4,2,2,4,3, 3,4,2,2,4,3, 1,1,1,1,1,1, 4,3,4,3,2,2},
    misc   = {4,3,4,3,2,2, 4,3,4,3,2,2, 4,3,4,3,2,2, 1,1,1,1,1,1}
}

-- Read a single BattlePokemon (gBattleMons - unencrypted)
local function readBattlePokemon(baseAddr)
    local mon = {}

    mon.species = read_u16(baseAddr + 0x00)
    if mon.species == 0 then return nil end

    mon.attack = read_u16(baseAddr + 0x02)
    mon.defense = read_u16(baseAddr + 0x04)
    mon.speed = read_u16(baseAddr + 0x06)
    mon.spAttack = read_u16(baseAddr + 0x08)
    mon.spDefense = read_u16(baseAddr + 0x0A)

    mon.moves = {
        read_u16(baseAddr + 0x0C),
        read_u16(baseAddr + 0x0E),
        read_u16(baseAddr + 0x10),
        read_u16(baseAddr + 0x12)
    }

    mon.pp = {
        read_u8(baseAddr + 0x14),
        read_u8(baseAddr + 0x15),
        read_u8(baseAddr + 0x16),
        read_u8(baseAddr + 0x17)
    }

    mon.hp = read_u16(baseAddr + 0x28)
    mon.maxHp = read_u16(baseAddr + 0x2C)
    mon.level = read_u8(baseAddr + 0x2A)

    return mon
end

-- Read encrypted party Pokemon (gPlayerParty/gEnemyParty)
local function readPartyPokemon(baseAddr, slot)
    local pokemonStart = baseAddr + 100 * slot

    -- Debug: log first read
    if slot == 0 then
        console.log(string.format("readPartyPokemon: baseAddr=0x%08X, pokemonStart=0x%08X", baseAddr, pokemonStart))
    end

    -- Personality Value (4 bytes)
    local personality = read_u32(pokemonStart)
    if slot == 0 then
        console.log(string.format("personality=0x%08X", personality))
    end
    if personality == 0 then return nil end

    -- Original Trainer ID (4 bytes)
    local otid = read_u32(pokemonStart + 4)

    -- Magic word for decryption
    local magicword = personality ~ otid

    -- Determine data order based on personality
    local dataOrder = personality % 24
    local growthOffset = (dataOrderTable.growth[dataOrder + 1] - 1) * 12
    local attackOffset = (dataOrderTable.attack[dataOrder + 1] - 1) * 12
    local effortOffset = (dataOrderTable.effort[dataOrder + 1] - 1) * 12
    local miscOffset = (dataOrderTable.misc[dataOrder + 1] - 1) * 12

    -- Decrypt data substructures (48 bytes at offset 0x20)
    local growth1 = read_u32(pokemonStart + 32 + growthOffset) ~ magicword
    local growth2 = read_u32(pokemonStart + 32 + growthOffset + 4) ~ magicword
    local growth3 = read_u32(pokemonStart + 32 + growthOffset + 8) ~ magicword
    local attack1 = read_u32(pokemonStart + 32 + attackOffset) ~ magicword
    local attack2 = read_u32(pokemonStart + 32 + attackOffset + 4) ~ magicword
    local attack3 = read_u32(pokemonStart + 32 + attackOffset + 8) ~ magicword
    local effort1 = read_u32(pokemonStart + 32 + effortOffset) ~ magicword
    local effort2 = read_u32(pokemonStart + 32 + effortOffset + 4) ~ magicword
    local misc1 = read_u32(pokemonStart + 32 + miscOffset) ~ magicword
    local misc2 = read_u32(pokemonStart + 32 + miscOffset + 4) ~ magicword

    -- Extract data from decrypted substructures
    local speciesID = get_bits(growth1, 0, 16)
    local heldItemID = get_bits(growth1, 16, 16)

    local mon = {
        personality = personality,
        otid = otid,
        species = speciesID,
        heldItem = heldItemID,
        experience = growth2,
        friendship = get_bits(growth3, 8, 8),

        moves = {
            get_bits(attack1, 0, 16),
            get_bits(attack1, 16, 16),
            get_bits(attack2, 0, 16),
            get_bits(attack2, 16, 16)
        },

        pp = {
            get_bits(attack3, 0, 8),
            get_bits(attack3, 8, 8),
            get_bits(attack3, 16, 8),
            get_bits(attack3, 24, 8)
        },

        evs = {
            hp = get_bits(effort1, 0, 8),
            attack = get_bits(effort1, 8, 8),
            defense = get_bits(effort1, 16, 8),
            speed = get_bits(effort1, 24, 8),
            spAttack = get_bits(effort2, 0, 8),
            spDefense = get_bits(effort2, 8, 8)
        },

        ivs = {
            hp = get_bits(misc2, 0, 5),
            attack = get_bits(misc2, 5, 5),
            defense = get_bits(misc2, 10, 5),
            speed = get_bits(misc2, 15, 5),
            spAttack = get_bits(misc2, 20, 5),
            spDefense = get_bits(misc2, 25, 5)
        },

        -- Current stats (not encrypted, at end of structure)
        level = read_u8(pokemonStart + 84),
        hp = read_u16(pokemonStart + 86),
        maxHp = read_u16(pokemonStart + 88),
        attack = read_u16(pokemonStart + 90),
        defense = read_u16(pokemonStart + 92),
        speed = read_u16(pokemonStart + 94),
        spAttack = read_u16(pokemonStart + 96),
        spDefense = read_u16(pokemonStart + 98),

        nature = personality % 25,
        partyIndex = slot
    }

    return mon
end

-- Read all battle pokemon (4 max, unencrypted)
function Readers.getBattleMons()
    local mons = {}
    local baseAddr = Config.ADDRESS.gBattleMons

    for i = 0, 3 do
        local mon = readBattlePokemon(baseAddr + i * 0x58)
        if mon then
            mon.battlerIndex = i
            table.insert(mons, mon)
        end
    end

    return mons
end

-- Read player party (6, encrypted)
function Readers.getPlayerParty()
    local party = {}
    local baseAddr = Config.ADDRESS.gPlayerParty

    for i = 0, 5 do
        local mon = readPartyPokemon(baseAddr, i)
        if mon then
            table.insert(party, mon)
        end
    end

    return party
end

-- Read enemy party (6, encrypted)
function Readers.getEnemyParty()
    local party = {}
    local baseAddr = Config.ADDRESS.gEnemyParty

    for i = 0, 5 do
        local mon = readPartyPokemon(baseAddr, i)
        if mon then
            table.insert(party, mon)
        end
    end

    return party
end

-- Check if in battle
function Readers.isInBattle()
    local flags = read_u32(Config.ADDRESS.gBattleTypeFlags)
    return flags ~= 0
end

-- Check if double battle
function Readers.isDoubleBattle()
    local flags = read_u32(Config.ADDRESS.gBattleTypeFlags)
    return (flags & 0x01) ~= 0
end

-- Get battle phase (requires game mod)
function Readers.getBattlePhase()
    if not Readers.isInBattle() then
        return Config.BATTLE_PHASE.NONE
    end
    return Config.BATTLE_PHASE.ACTION_SELECT
end


return Readers
