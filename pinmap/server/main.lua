local devMode = false

local function PinLog(msg) --Just a custom log function that I use instead of print so it's clear what package the msg is from on server console
    print("[Pinmap] - " .. msg)
end

local function OnPackageStart() 
    if not file_exists("packages/pinmap/config.ini") then
        return PinLog("Failed to load the config.ini file! Critical Error!")
    end
    local ini = ini_open("packages/pinmap/config.ini")
    local devModeValue = ini_read(ini, "developer", "developerModeEnabled")
    if (devModeValue == "true") then
        devMode = true
        AddRemoteEvent("PinmapRequestTeleport", ProcessTeleportRequest) --Enable the remote event for requesting teleports if dev mode is enabled
        PinLog("Developer mode is enabled! This will allow players to teleport. To turn off developer mode, please see the config.ini file in the Pinmap package!")
    end
end
AddEvent("OnPackageStart", OnPackageStart)

local function OnPlayerJoin(player)
    if (devMode) then
        CallRemoteEvent(player, "PinmapEnableDevmode") --If the server is ran in dev mode, we call a remote event to tell the client that it is in dev mode so the client can add the teleport option to right click menu on map
    end
end
AddEvent("OnPlayerJoin", OnPlayerJoin)

function ProcessTeleportRequest(player, worldX, worldY, worldZ) --Teleports player, this will only be called if the remote event is enabled IF the server is ran in dev mode (see config.ini file)
    SetPlayerLocation(player, worldX, worldY, worldZ)
end

function file_exists(filename) --function copy&pasted from onset lua script examples to check if file exists
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    end
    return false
end