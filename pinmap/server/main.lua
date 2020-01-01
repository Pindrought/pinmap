local devMode = false

local function PinLog(msg)
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
        AddRemoteEvent("PinmapRequestTeleport", ProcessTeleportRequest)
        PinLog("Developer mode is enabled! This will allow players to teleport. To turn off developer mode, please see the config.ini file in the Pinmap package!")
    end
end
AddEvent("OnPackageStart", OnPackageStart)

local function OnPlayerJoin(player)
    if (devMode) then
        CallRemoteEvent(player, "PinmapEnableDevmode")
    end
end
AddEvent("OnPlayerJoin", OnPlayerJoin)

function ProcessTeleportRequest(player, worldX, worldY, worldZ)
    SetPlayerLocation(player, worldX, worldY, worldZ)
end

function file_exists(filename)
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    end
    return false
end