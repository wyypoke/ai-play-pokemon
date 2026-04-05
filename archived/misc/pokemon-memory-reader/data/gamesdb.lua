-- Pokemon Games Database
-- Consolidated database containing all game information and memory addresses
-- Uses game code as primary identifier (supports modified ROMs)

local GamesDB = {}

GamesDB.games = {

    -- ===== GENERATION 1 GAMES =====

    -- MARK: Red (USA)
    ["5245"] = {  -- "RE" from licensee code
        gameInfo = {
            gameCode = "RE",
            gameName = "Pokemon Red (USA)",
            versionName = "Pokemon Red",
            versionColor = "Red",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16B,
            partySlotsCounterAddr = 0xD163,
            partyNicknamesAddr = 0xD2B5,
            wildDVsAddr = 0xCFF1,
            trainerID = 0xD359,
            itemNameTable = 0x472B
        },
        trainerOffsets = {
            name = 0xD158,
            badges = 0xD356,
            money = 0xD347,
            coins = 0xD5A4,
            bagCount = 0xD31D,
            bagItems = 0xD31E,
            pcCount = 0xD53A,
            pcItems = 0xD53B
        },
        romTitle = "POKEMON RED"
    },

    --MARK: Blue (USA)
    ["424C"] = {  -- "BL" from licensee code
        gameInfo = {
            gameCode = "BL",
            gameName = "Pokemon Blue (USA)",
            versionName = "Pokemon Blue",
            versionColor = "Blue",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16B,
            partySlotsCounterAddr = 0xD163,
            partyNicknamesAddr = 0xD2B5,
            wildDVsAddr = 0xCFF1,
            trainerID = 0xD359,
            itemNameTable = 0x472B
        },
        trainerOffsets = {
            name = 0xD158,
            badges = 0xD356,
            money = 0xD347,
            coins = 0xD5A4,
            bagCount = 0xD31D,
            bagItems = 0xD31E,
            pcCount = 0xD53A,
            pcItems = 0xD53B
        },
        romTitle = "POKEMON BLUE"
    },

    -- MARK: Yellow (USA)
    ["5945"] = {  -- "YE" from licensee code
        gameInfo = {
            gameCode = "YE",
            gameName = "Pokemon Yellow (USA)",
            versionName = "Pokemon Yellow",
            versionColor = "Yellow",
            generation = 1,
            platform = "GB",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xD16A,
            partySlotsCounterAddr = 0xD162,
            partyNicknamesAddr = 0xD2B4,
            wildDVsAddr = 0xCFF0,
            trainerID = 0xD358,
            itemNameTable = 0x45B9
        },
        trainerOffsets = {
            name = 0xD157,
            badges = 0xD355,
            money = 0xD346,
            coins = 0xD5A3,
            bagCount = 0xD31C,
            bagItems = 0xD31D,
            pcCount = 0xD539,
            pcItems = 0xD53A
        },
        romTitle = "POKEMON YELLOW"
    },

    -- ===== GENERATION 2 GAMES =====

    -- MARK: Gold (USA)
    ["474C"] = {  -- "GL" from licensee code
        gameInfo = {
            gameCode = "GL",
            gameName = "Pokemon Gold (USA)",
            versionName = "Pokemon Gold",
            versionColor = "Gold",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDA2A,
            partySlotsCounterAddr = 0xDA22,
            partyNicknamesAddr = 0xDB8C,
            partyOTAddr = 0xDB4A,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDA2A,
            tmToMoveTable = 0x11A66,
            moveNamesTable = 0x1B1574,
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD1A1,
            name = 0xD1A3,
            money = 0xD573,
            momMoney = 0xD576,
            coins = 0xD57A,
            johtoBadges = 0xD57C,
            kantoBadges = 0xD57D,
            itemCount = 0xD5B7,
            itemsPocket = 0xD5B8,
            keyItemCount = 0xD5E1,
            keyItemsPocket = 0xD5E2,
            ballCount = 0xD5FC,
            ballsPocket = 0xD5FD,
            tmhmPocket = 0xD57E,
        },
        romTitle = "POKEMON_GOLD"
    },

    -- MARK: Silver (USA)
    ["534C"] = {  -- "SL" from licensee code
        gameInfo = {
            gameCode = "SL",
            gameName = "Pokemon Silver (USA)",
            versionName = "Pokemon Silver",
            versionColor = "Silver",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDA2A,
            partySlotsCounterAddr = 0xDA22,
            partyNicknamesAddr = 0xDB8C,
            partyOTAddr = 0xDB4A,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDA2A,
            tmToMoveTable = 0x11A66,
            moveNamesTable = 0x1B1574,
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD1A1,
            name = 0xD1A3,
            money = 0xD573,
            momMoney = 0xD576,
            coins = 0xD57A,
            johtoBadges = 0xD57C,
            kantoBadges = 0xD57D,
            itemCount = 0xD5B7,
            itemsPocket = 0xD5B8,
            keyItemCount = 0xD5E1,
            keyItemsPocket = 0xD5E2,
            ballCount = 0xD5FC,
            ballsPocket = 0xD5FD,
            tmhmPocket = 0xD57E,
        },
        romTitle = "POKEMON_SILVER"
    },

    -- MARK: Crystal (USA)
    ["414C"] = {  -- "AL" from licensee code
        gameInfo = {
            gameCode = "AL",
            gameName = "Pokemon Crystal (USA)",
            versionName = "Pokemon Crystal",
            versionColor = "Crystal",
            generation = 2,
            platform = "GBC",
            isRomhack = false
        },
        addresses = {
            partyAddr = 0xDCDF,
            partySlotsCounterAddr = 0xDCD7,
            partyNicknamesAddr = 0xDE41,
            partyOTAddr = 0xDDFF,
            wildDVsAddr = 0xC6F0,
            trainerID = 0xDCDF,
            speciesNameTable = 0x53384,
            itemNameTable = 0x1C8000,
            moveNamesTable = 0x1C9F29,
            tmToMoveTable = 0x1167A,
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 25,
            ballsPocket = 12,
            tmhmPocket = 57,
        },
        trainerOffsets = {
            trainerID = 0xD47B,
            name = 0xD47D,
            money = 0xD84F,
            momMoney = 0xD852,
            coins = 0xD855,
            johtoBadges = 0xD857,
            kantoBadges = 0xD858,
            itemCount = 0xD893,
            keyItemCount = 0xD8BC,
            ballCount = 0xD8D7,
            pcCount = 0xD8F1,
            itemsPocket = 0xD893,
            keyItemsPocket = 0xD8BD,
            ballsPocket = 0xD8D8,
            tmhmPocket = 0xD859,
            pcItems = 0xD8F2,
        },
        romTitle = "POKEMON CRYSTAL"
    },

    -- ===== GENERATION 3 GAMES =====

    -- MARK: Ruby (USA)
    ["AXVE"] = {
        gameInfo = {
            gameCode = "AXVE",
            gameName = "Pokemon Ruby (USA)",
            versionName = "Pokemon Ruby",
            versionColor = "Ruby",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            partyAddr = "02004360",
            enemyPartyAddr = "02024744",
            gBattleMons = "02024084",
            speciesDataTable = "081FEC34",
            speciesNameTable = "081F716C",
            itemNameTable = "083C5564",
            naturePointersAddr = "083C1004",
            mapBank = "020322E4",
            mapNumber = "020322E5"
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "02025734",
            saveBlock2 = "02024EA4",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 20,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            trainerID = 0x0A,
            name = 0x00,
            gender = 0x08,
            money = 0x490,
            coins = 0x494,
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5B0,
            ballsPocket = 0x600,
            tmhmPocket = 0x640,
            berriesPocket = 0x740,
            flags = 0x1220,
            badgeFlags = 0x100
        },
        romTitle = "POKEMON RUBY"
    },

    -- MARK: Sapphire (USA)
    ["AXPE"] = {
        gameInfo = {
            gameCode = "AXPE",
            gameName = "Pokemon Sapphire (USA)",
            versionName = "Pokemon Sapphire",
            versionColor = "Sapphire",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            partyAddr = "02004360",
            enemyPartyAddr = "02024744",
            gBattleMons = "02024084",
            speciesDataTable = "081FEC34",
            speciesNameTable = "081F716C",
            itemNameTable = "083C5564",
            naturePointersAddr = "083C1004",
            mapBank = "020322E4",
            mapNumber = "020322E5"
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "02025734",
            saveBlock2 = "02024EA4",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 20,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            trainerID = 0x0A,
            name = 0x00,
            gender = 0x08,
            money = 0x490,
            coins = 0x494,
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5B0,
            ballsPocket = 0x600,
            tmhmPocket = 0x640,
            berriesPocket = 0x740,
            flags = 0x1220,
            badgeFlags = 0x100
        },
        romTitle = "POKEMON SAPPHIRE"
    },

    -- MARK: Emerald (USA)
    ["BPEE"] = {
        gameInfo = {
            gameCode = "BPEE",
            gameName = "Pokemon Emerald (USA)",
            versionName = "Pokemon Emerald",
            versionColor = "Emerald",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            partyAddr = "020244EC",
            enemyPartyAddr = "02024744",
            gBattleMons = "02024084",
            speciesDataTable = "083203CC",
            speciesNameTable = "083185C8",
            itemTable = "0858399E",
            naturePointersAddr = "0861CB50",
            abilityNameTable = "0831B6DB",
            moveNamesTable = "0831977C",
            tmToMoveTable = "08616040",
            mapBank = "020322E4",
            mapNumber = "020322E5"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005D8C",
            saveBlock2 = "03005D90",
        },
        pocketSize = {
            pcCount = 50,
            itemsPocket = 20,
            keyItemsPocket = 30,
            ballsPocket = 16,
            tmhmPocket = 64,
            berriesPocket = 46
        },
        trainerOffsets = {
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xAC,
            money = 0x490,
            coins = 0x494,
            pcItems = 0x498,
            itemsPocket = 0x560,
            keyItemsPocket = 0x5D8,
            ballsPocket = 0x650,
            tmhmPocket = 0x690,
            berriesPocket = 0x790,
            flags = 0x1270,
            badgeFlags = 0x10C
        },
        romTitle = "POKEMON EMER"
    },

    -- MARK: FireRed (USA)
    ["BPRE"] = {
        gameInfo = {
            gameCode = "BPRE",
            gameName = "Pokemon FireRed (USA)",
            versionName = "Pokemon FireRed",
            versionColor = "FireRed",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C",
            gBattleMons = "02023BE4",
            speciesDataTable = "082547A0",
            speciesNameTable = "08245EE0",
            itemNameTable = "083DB028",
            naturePointersAddr = "08463E60",
            abilityNameTable = "0824FC40",
            moveNameTable = "08247094",
            mapBank = "020322E4",
            mapNumber = "020322E5"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005008",
            saveBlock2 = "0300500C",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            money = 0x290,
            coins = 0x294,
            pcItems = 0x298,
            itemsPocket = 0x310,
            keyItemsPocket = 0x3B8,
            ballsPocket = 0x430,
            tmhmPocket = 0x464,
            berriesPocket = 0x54C,
            flags = 0x0EE0,
            badgeFlags = 0x104
        },
        romTitle = "POKEMON FIRE"
    },

    -- MARK: LeafGreen (USA)
    ["BPGE"] = {
        gameInfo = {
            gameCode = "BPGE",
            gameName = "Pokemon LeafGreen (USA)",
            versionName = "Pokemon LeafGreen",
            versionColor = "LeafGreen",
            generation = 3,
            platform = "GBA",
            isRomhack = false
        },
        addresses = {
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C",
            gBattleMons = "02023BE4",
            speciesDataTable = "0825477C",
            speciesNameTable = "08245EBC",
            itemNameTable = "083DAE64",
            naturePointersAddr = "08463880",
            abilityNameTable = "0824FC40",
            moveNameTable = "08247094",
            mapBank = "020322E4",
            mapNumber = "020322E5"
        },
        trainerPointers = {
            isPointer = true,
            saveBlock1 = "03005008",
            saveBlock2 = "0300500C",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            money = 0x290,
            coins = 0x294,
            pcItems = 0x298,
            itemsPocket = 0x310,
            keyItemsPocket = 0x3B8,
            ballsPocket = 0x430,
            tmhmPocket = 0x464,
            berriesPocket = 0x54C,
            flags = 0x0EE0,
            badgeFlags = 0x104
        },
        romTitle = "POKEMON LEAF"
    },
}

-- ROM hacks database (detected by ROM title)
-- These have the same game code as their base game but different titles
GamesDB.romhacks = {
    -- MARK: Radical Red (FireRed ROM hack)
    ["RADICAL RED"] = {
        gameInfo = {
            gameCode = "BPRE",
            gameName = "Pokemon Radical Red",
            versionName = "Pokemon Radical Red",
            versionColor = "RadicalRed",
            generation = "CFRU",
            platform = "GBA",
            isRomhack = true
        },
        addresses = {
            partyAddr = "02024284",
            enemyPartyAddr = "0202402C",
            gBattleMons = "02023BE4",
            speciesDataTable = "0817B9908",
            speciesNameTable = "0814042D7",
            moveNamesTable = "0810EEEDC",
            pockets = {
                itemsPocket = "0203BB20",
                keyItemsPocket = "0203C228",
                ballsPocket = "0203C354",
                tmhmPocket = "0203C41C",
                berriesPocket = "0203C61C"
            }
        },
        trainerPointers = {
            isPointer = false,
            saveBlock1 = "0202552C",
            saveBlock2 = "02024588",
        },
        pocketSize = {
            pcCount = 30,
            itemsPocket = 42,
            keyItemsPocket = 30,
            ballsPocket = 13,
            tmhmPocket = 58,
            berriesPocket = 43
        },
        trainerOffsets = {
            name = 0x00,
            gender = 0x08,
            trainerID = 0x0A,
            encryptionKey = 0xF20,
            money = 0x290,
            coins = 0x294,
            pcItems = 0x298,
        },
        romTitle = "RADICAL RED"
    },
}

-- Helper function to get game data by game code
function GamesDB.getGameByCode(gameCode)
    return GamesDB.games[gameCode]
end

-- Helper function to get game data by ROM title (for ROM hacks)
function GamesDB.getGameByTitle(romTitle)
    -- First check ROM hacks database
    local hack = GamesDB.romhacks[romTitle]
    if hack then return hack end

    -- Then check main games database
    for code, game in pairs(GamesDB.games) do
        if game.romTitle and game.romTitle == romTitle then
            return game
        end
    end
    return nil
end

-- Helper function to get all games by generation
function GamesDB.getGamesByGeneration(generation)
    local result = {}
    for code, game in pairs(GamesDB.games) do
        if game.gameInfo.generation == generation then
            result[code] = game
        end
    end
    return result
end

-- Helper function to get all games by platform
function GamesDB.getGamesByPlatform(platform)
    local result = {}
    for code, game in pairs(GamesDB.games) do
        if game.gameInfo.platform == platform then
            result[code] = game
        end
    end
    return result
end

-- Helper function to get supported games list
function GamesDB.getSupportedGamesList()
    local games = {}
    for code, game in pairs(GamesDB.games) do
        table.insert(games, game.gameInfo.gameName)
    end
    for title, game in pairs(GamesDB.romhacks) do
        table.insert(games, game.gameInfo.gameName)
    end
    return games
end

-- Helper function to check if a game is supported
function GamesDB.isGameSupported(gameCode)
    return GamesDB.games[gameCode] ~= nil
end

return GamesDB
