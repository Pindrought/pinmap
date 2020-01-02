function OnScriptError(message) --Standard copy&paste code from onset lua script examples for printing out lua errors
    AddPlayerChat('<span color="#ff0000bb" style="bold" size="10">'..message..'</>')
end
AddEvent("OnScriptError", OnScriptError)

local gui = nil
local devMode = false
local uiLoaded = false

local function PinLog(msg) --I use this instead of the default AddPlayerChat just so it looks pretty and makes it clear what package my messages are from
	AddPlayerChat('<span color="#33DD33" style="bold" size="12">[Pinmap]</> - ' .. msg)
end

local function OnPackageStart()
	local screenX, screenY = GetScreenSize()
	gui = CreateWebUI(0, 0, 0, 0)
	LoadWebFile(gui, "http://asset/pinmap/client/web/map.html")

	SetWebAlignment(gui, 0, 0)
	SetWebAnchors(gui, 0.1, 0.1, 0.9, 0.9) --Set up my web ui to take up the center 80% of the screen

	SetWebVisibility(gui, WEB_HIDDEN)
end
AddEvent("OnPackageStart", OnPackageStart)

function InitializeMapValues() --This will send the width/height of the map which will be used by the WebUI to make sure user does not drag map off screen as well as send the legend info
	local screenX, screenY = GetScreenSize()
	mapWidth = screenX * 0.8
	mapHeight = screenY * 0.8
	jsString = "AssignParameters(" .. mapWidth .. "," .. mapHeight ..");"
	ExecuteWebJS(gui, jsString)

	ExecuteWebJS(gui, "RegisterLegendKey('market', 'Market', 'market.png');")
	ExecuteWebJS(gui, "RegisterBlip('market', 129000, 78521);")

	ExecuteWebJS(gui, "RegisterLegendKey('gunstore', 'Gun Store', 'gunstore.png');")
	ExecuteWebJS(gui, "RegisterBlip('gunstore', 101527, -34633);")
	ExecuteWebJS(gui, "RegisterBlip('gunstore', 135200, 192240);")
	uiLoaded = true
	if (devMode) then
		ExecuteWebJS(gui, "EnableDevMode();") --When EnableDevMode() is called in the js, it adds the menu option for "Teleport Here" in the right click menu on the map
	end

end
AddEvent("OnMapUILoaded", InitializeMapValues) --This event is called by the map.js after the page is loaded. If we try to execute the web js before the page is loaded, it's invalid behavior.

function PinmapEnableDevmode()
	PinLog("Developer mode is enabled! This will allow players to teleport via the map feature. To turn off developer mode, please see the config.ini file in the Pinmap package!")
	devMode = true
	if (uiLoaded) then
		ExecuteWebJS(gui, "EnableDevMode();") --When EnableDevMode() is called in the js, it adds the menu option for "Teleport Here" in the right click menu on the map
	end
end
AddRemoteEvent("PinmapEnableDevmode", PinmapEnableDevmode) --Server will send this event if dev mode is enabled in server config

local fixTeleportTimer = nil --There are inherent issues with LineTrace not being accurate if the collision check is not within render distance. Due to this, I had to rig up this system where it attempts to recalculate/reteleport until it finds an intersection with the actual ground.
local teleportX
local teleportY
function FixTeleport()
	_, _, _, _, teleportZ = LineTrace(teleportX, teleportY, 7000, teleportX, teleportY, 0) --attempt to trace line and get Z value for teleport target
	PinLog("Attempting to retrieve adjusted teleport coordinates: [" .. teleportX .. ", " .. teleportY .. ", " .. teleportZ .. "]")
	if (teleportZ ~= 0) then
		PinLog("Teleporting to fixed coordinates: [" .. teleportX .. ", " .. teleportY .. ", " .. teleportZ .. "]")
		teleportZ = teleportZ + 50 --Teleport above the ground so we don't fall through it 
		SetIgnoreMoveInput(false) --Allow player to move again since we supposedly found the correct teleport coordinates and requested it to server
		DestroyTimer(fixTeleportTimer) --Destroy timer since we don't need to keep checking after we found the correct coordinates
		fixTeleportTimer = nil --assign to nil for checking if timer exists in RequestTeleportToLocation()
		CallRemoteEvent("PinmapRequestTeleport", teleportX, teleportY, teleportZ) --send new teleport request to server
	end
end

function RequestTeleportToLocation(worldX, worldY)
	_, _, _, _, worldZ = LineTrace(worldX, worldY, 10000, worldX, worldY, 0)
	worldX = math.ceil(worldX)
	worldY = math.ceil(worldY)
	worldZ = math.ceil(worldZ) + 50 --Round everything up and try to teleport 50 units above the target coordinate that LineTrace calculated
	PinLog("Requesting teleport to: [" .. worldX .. ", " .. worldY .. ", " .. worldZ .. "]")
	if (worldZ == 50) then --If the z calculation failed... This can happen due to the intersection being out of render distance or LineTrace just failing - it has issues with certain surfaces
		SetIgnoreMoveInput(true) --Do not allow user to move while we try to fix the failed teleport
		teleportX = worldX --store the target x,y teleport coordinates, and we'll try to recalculate the z in FixTeleport()
		teleportY = worldY
		if (fixTeleportTimer == nil) then --if the fix teleport timer isn't active, lets create one to start attempting to recalculate/reteleport
			fixTeleportTimer = CreateTimer(FixTeleport, 100) --Create timer where the FixTeleport callback function is called approximately 10 times/sec (100ms)
		end
	else --If z calculation looks accurate (LineTrace didn't fail on us)
		if (fixTeleportTimer ~= nil) then --If a fix teleport timer exists/is running, let's clean that up
			DestroyTimer(fixTeleportTimer)
			fixTeleportTimer = nil --Assign to nil so that we can properly check if it is running or not in the future
		end
		SetIgnoreMoveInput(false) --Allow user to move again in case it was disabled
	end
	CallRemoteEvent("PinmapRequestTeleport", worldX, worldY, worldZ) --Request to server to teleport us to target location
end
AddEvent("RequestTeleportToLocation", RequestTeleportToLocation) --This event is called by the map.js file when you try to teleport from the UI

local isMapOpen = false
local timeMapClosed = GetTimeSeconds() --Store the last time map was closed
function OnKeyPress(key)
	if (key == "M") then
		dt = GetTimeSeconds() - timeMapClosed
		if (dt < 0.5) then --If the map was opened or closed in the last 0.5 seconds, ignore this. This is to try to prevent map from being automatically opened/closed again. This threshold could be reduced, but I felt like 0.5 was safe.
			return false
		end
		if (isMapOpen) then
			CloseMap()
		else
			isMapOpen = true
			UpdatePositionOnMap()
			SetWebVisibility(gui, WEB_VISIBLE)
			SetInputMode(INPUT_GAMEANDUI)
			ShowMouseCursor(true)
		end
	end
end
AddEvent("OnKeyPress", OnKeyPress)

local destinationWP = nil
function UpdateMapDestination(worldX, worldY)
	_, _, _, _, worldZ = LineTrace(worldX, worldY, 10000, worldX, worldY, 0)
	if (destinationWP ~= nil) then --If we have an existing waypoint, destroy it before creating this new one
		DestroyWaypoint(destinationWP)
	end
	destinationWP = CreateWaypoint(worldX, worldY, worldZ, "Destination")
end
AddEvent("UpdateMapDestination", UpdateMapDestination)

function ClearMapDestination()
	if (destinationWP ~= nil) then
		DestroyWaypoint(destinationWP)
		destinationWP = nil
	end
end
AddEvent("ClearMapDestination", ClearMapDestination)

function UpdatePositionOnMap()
	if (isMapOpen == true) then
		local x, y, z = GetPlayerLocation()
		heading = GetPlayerHeading() + 90
		if (heading < 0) then
			heading = heading + 360
		end
		jsString = "UpdatePlayerPosition(" .. x .. "," .. y .. "," .. z .. "," .. heading .. ");"
		ExecuteWebJS(gui, jsString)
	end
end
CreateTimer(UpdatePositionOnMap, 250)

function CloseMap()
	SetWebVisibility(gui, WEB_HIDDEN)
	SetInputMode(INPUT_GAME)
	timeMapClosed = GetTimeSeconds()
	isMapOpen = false
	ShowMouseCursor(false)
end
AddEvent("CloseMap", CloseMap)
