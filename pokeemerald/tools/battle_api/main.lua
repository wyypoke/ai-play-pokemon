-- Battle API - Main Entry
-- HTTP server for Pokemon Emerald battle control
-- Run this script in BizHawk

local Server = require("server")

-- Initialize
console.log("=== Battle API ===")
console.log("Initializing...")

-- Start server
if Server.start() then
    console.log("Server ready!")
else
    console.log("Failed to start server")
    return
end

-- Register frame callback
event.onframeend(function()
    Server.update()
end, "BattleAPI")

console.log("Registered frame callback")
console.log("Press Ctrl+Shift+T to stop")
