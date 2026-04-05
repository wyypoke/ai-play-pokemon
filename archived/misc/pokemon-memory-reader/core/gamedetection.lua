-- Game Detection Module for Pokemon Memory Reader
-- This module handles detecting which Pokemon game is currently loaded in BizHawk
-- Uses game code and ROM title for detection (supports modified ROMs)

local gameDetection = {}
local GamesDB = require("data.gamesdb")
local gameUtils = require("utils.gameutils")

-- Main detection function
function gameDetection.detectGame()
    console.log("Detecting game...")

    -- Get system ID
    local systemID = gameUtils.getSystem()
    if not systemID or systemID == "NULL" then
        console.log("No system detected")
        return nil
    end

    console.log("System: " .. systemID)

    -- Get ROM game code
    local gameCode = gameUtils.getROMGameCode()
    if not gameCode then
        console.log("Could not get game code from ROM")
        return nil
    end

    console.log("Game code: " .. gameCode)

    -- Get ROM title for additional identification (especially for ROM hacks)
    local romTitle = gameUtils.getROMTitle()
    if romTitle then
        console.log("ROM title: " .. romTitle)
    end

    -- First try to identify by ROM title (for ROM hacks that have custom titles)
    if romTitle then
        local gameData = GamesDB.getGameByTitle(romTitle)
        if gameData then
            console.log("Game found by title: " .. gameData.gameInfo.gameName)
            return gameData
        end
    end

    -- Then try to identify by game code
    local gameData = GamesDB.getGameByCode(gameCode)
    if gameData then
        console.log("Game found by code: " .. gameData.gameInfo.gameName)
        return gameData
    end

    console.log("Unknown " .. systemID .. " game detected")
    console.log("Game code: " .. gameCode)
    if romTitle then
        console.log("ROM title: " .. romTitle)
    end
    console.log("If you believe this game should be supported, please open an issue on GitHub.")

    return nil
end

-- Function to read game code from ROM (kept for compatibility)
function gameDetection.findGameCode()
    return gameUtils.getROMGameCode()
end

-- Get supported games list
function gameDetection.getSupportedGames()
    return GamesDB.getSupportedGamesList()
end

-- Validate if current game is supported
function gameDetection.isGameSupported()
    local gameCode = gameUtils.getROMGameCode()
    if not gameCode then
        return false
    end

    return GamesDB.isGameSupported(gameCode)
end

return gameDetection
