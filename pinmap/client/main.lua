function OnScriptError(message)
    AddPlayerChat('<span color="#ff0000bb" style="bold" size="10">'..message..'</>')
end
AddEvent("OnScriptError", OnScriptError)

local gui = nil

local function OnPackageStart()
	local screenX, screenY = GetScreenSize()
	mapWidth = screenX * 0.8
	mapHeight = screenY * 0.8
	gui = CreateWebUI(0, 0, mapWidth, mapHeight)
	LoadWebFile(gui, "http://asset/pinmap/client/web/map.html")

	SetWebAlignment(gui, 0.5, 0.5)
	SetWebAnchors(gui, 0.5, 0.5, 0.5, 0.5)

	SetWebVisibility(gui, WEB_HIDDEN)
end
AddEvent("OnPackageStart", OnPackageStart)

local isMapOpen = false
local timeMapClosed = GetTimeSeconds() --This is to prevent the map from automatically opening again
function OnKeyPress(key)
	if (key == "M") then
		dt = GetTimeSeconds() - timeMapClosed
		if (dt < 0.5) then
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

function InitializeMapValues()
	local screenX, screenY = GetScreenSize()
	mapWidth = screenX * 0.8
	mapHeight = screenY * 0.8
	jsString = "AssignParameters(" .. mapWidth .. "," .. mapHeight ..");"
	AddPlayerChat(jsString);
	ExecuteWebJS(gui, jsString)
end
AddEvent("OnMapUILoaded", InitializeMapValues)

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
