//Author: Pindrought
window.onload = OnLoad;

var legendKeys = []; //Legend keys

var mapWidth = 2000;
var mapHeight = 1943;

var mouseScrollX = 0;
var mouseScrollY = 0;
//Used for map dragging
var initialMouseX = 0;
var initialMouseY = 0;
//Store map div x & y offset & map img scale
var mapStartDragX = 0;
var mapStartDragY = 0;
var mapX = -40;
var mapY = -431;
var mapScale = 1;
var prevMapScale = 1;
var windowWidth = 0;
var windowHeight = 0;
var runningFromBrowser = true;

function CustomContextMenu(e) //Custom right click to allow assigning destinations
{
    e.preventDefault();
    var menu = document.getElementById("menu");
    menu.style.display = "block";
    menu.style.left = e.pageX + 'px';
    menu.style.top = e.pageY + 'px';
}

function MenuOptionClicked(option)
{
    var menu = document.getElementById("menu");
    menu.style.display = "none";
    var destinationMarker = document.getElementById("destinationmarker");
    if (option == "SetDestination")
    {
        var mapdiv = document.getElementById('mapdiv');
        var markerX = parseInt(menu.style.left) - parseInt(mapdiv.style.left);
        var markerY = parseInt(menu.style.top) - parseInt(mapdiv.style.top);
        markerX = markerX / mapScale;
        markerY = markerY / mapScale;
        destinationMarker.worldX = MapToWorldX(markerX);
        destinationMarker.worldY = MapToWorldY(markerY);
        destinationMarker.style.display = "block";

        destinationMarker.style.left = (WorldToMapX(destinationMarker.worldX) * mapScale -16) + 'px';
        destinationMarker.style.top = (WorldToMapY(destinationMarker.worldY) * mapScale - 32) + 'px';

        CallEvent("UpdateMapDestination", destinationMarker.worldX, destinationMarker.worldY)
    }
    if (option == "ClearDestination")
    {
        destinationMarker.style.display = "none";
        CallEvent("ClearMapDestination", null);
    }
    if (option == "TeleportHere")
    {
        var mapdiv = document.getElementById('mapdiv');
        var teleportX = parseInt(menu.style.left) - parseInt(mapdiv.style.left);
        var teleportY = parseInt(menu.style.top) - parseInt(mapdiv.style.top);
        teleportX = teleportX / mapScale;
        teleportY = teleportY / mapScale;
        worldX = MapToWorldX(teleportX);
        worldY = MapToWorldY(teleportY);
        CallEvent("RequestTeleportToLocation", worldX, worldY)
    }
}

function OnLoad()
{
    if (typeof ue !== 'undefined') //Determine if we're running from browser
    {
        runningFromBrowser = false;
    }

    var mapdiv = document.getElementById('mapdiv');
    mapdiv.style.top = mapX + 'px';
    mapdiv.style.left = mapY + 'px';
    window.addEventListener('mousedown', MouseDown, false); //mousedown to start drag
    window.addEventListener('mouseup', MouseUp); //mouseup to stop drag
    window.addEventListener('keydown', CloseMap); //keydown to close map with callback when 'M' is pressed
    window.addEventListener('wheel', MouseScroll); //mouse wheel event for scrolling
    window.addEventListener('mousemove', UpdateMousePos, true); //Update mouse pos to be able to retrieve mouse pos when scrolling in&out
    CallEvent('OnMapUILoaded', null);
    RefreshMap();

    if (runningFromBrowser) //Setup stuff that game would normally set up for testing in browser
    {
        AssignParameters(window.innerWidth, window.innerHeight);
        RegisterLegendIcon('market', 'Market', 'market.png');
        RegisterBlip('market', 129000, 78521);

        RegisterLegendIcon('gunstore', 'Gun Store', 'gunstore.png');
        RegisterBlip('gunstore', 101527, -34633);
        RegisterBlip('gunstore', 135200, 192240);
        EnableDevMode();
    }
    
    document.addEventListener('contextmenu', CustomContextMenu);
}

function EnableDevMode()
{
    var menuOptions = document.getElementById("menu-options");
    var menuItem = document.createElement("li");
    menuItem.appendChild(document.createTextNode("Teleport Here"));
    menuItem.className = "menu-option";
    menuItem.onclick = function() { MenuOptionClicked("TeleportHere") };
    menuOptions.appendChild(menuItem);
}

function RegisterLegendIcon(id, text, iconpath)
{
    var key = [];
    key.id = id;
    key.text = text;
    key.iconpath = iconpath;
    key.blips = [];
    legendKeys.push(key);
    var legendKeyDiv = document.getElementById('legend-key');

    var keyDiv = document.createElement('div');
    keyDiv.style.display = 'block';
    keyDiv.style.whiteSpace = 'nowrap';

    var checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.id = 'checkbox_' + id;
    checkbox.checked = true;
    checkbox.onclick = function() { LegendKeyClick(id) }; 
    checkbox.className = 'checkbox-custom';

    var img = document.createElement('img');
    img.src = iconpath;
    img.className = 'legend-img';
    img.draggable = false;

    var label = document.createElement('label')
    label.htmlFor = checkbox.id;
    label.style.fontSize = '24px';
    label.textContent = text;

    keyDiv.appendChild(checkbox);
    keyDiv.appendChild(img);
    keyDiv.appendChild(label);

    legendKeyDiv.appendChild(keyDiv);
}

function RegisterBlip(id, worldX, worldY)
{
    var key = null;
    legendKeys.forEach(e =>
        {
            if (e.id == id)
            {
                key = e;
            }
        });
    if (key != null)
    {
        var blipimg = document.createElement('img');
        blipimg.src = key.iconpath;
        blipimg.className = "blip";
        blipimg.draggable = false;
        blipimg.worldX = worldX;
        blipimg.worldY = worldY;
        blipimg.style.zIndex = 3;
        blipimg.style.left = (WorldToMapX(blipimg.worldX) * mapScale -12) + 'px';
        blipimg.style.top = (WorldToMapY(blipimg.worldY) * mapScale -12) + 'px';
        key.blips.push(blipimg);

        var mapdiv = document.getElementById('mapdiv');
        mapdiv.appendChild(blipimg);
    }
}

function LegendKeyClick(id)
{
    var cb = document.getElementById('checkbox_'+id);
    var key = null;
    legendKeys.forEach(e =>
        {
            if (e.id == id)
            {
                key = e;
            }
        });
    if (cb.checked == true)
    {
        key.blips.forEach(element => 
        {
            element.style.visibility = 'visible';
        });
    }
    else
    {
        key.blips.forEach(element => 
        {
            element.style.visibility = 'hidden';
        });
    }
}

function AssignParameters(_windowWidth, _windowHeight) //After the WebUI is loaded, a callback event is called 'OnMapUILoaded' where the map.lua will call AssignParameters and pass in the window Width/Height
{
    windowWidth = Math.floor(_windowWidth);
    windowHeight = Math.floor(_windowHeight);
}

function MouseUp()
{
    window.removeEventListener('mousemove', MapMove, true);
}

function UpdateMousePos(e)
{
    mouseScrollX = e.clientX;
    mouseScrollY = e.clientY;
}

function MouseDown(e)
{
    if (e.button == 2) //If right click, exit since right click is just used for context menu
    {
        return;
    }
    if (e.button == 1) //middle mouse click
    {
        e.preventDefault(); //We prevent default for middle mouse click so user can drag around even when zoomed in
    }
    var menu = document.getElementById("menu");
    if (menu.style.display == "block")
    {
        var leftX = parseInt(menu.style.left);
        var rightX = leftX + menu.offsetWidth;
        var topY = parseInt(menu.style.top);
        var bottomY = topY + menu.offsetHeight;
        if (e.clientX >= leftX &&
            e.clientX <= rightX &&
            e.clientY >= topY &&
            e.clientY <= bottomY)
        {
            return;
        }
        menu.style.display = "none";
    }

    initialMouseX = e.clientX;
    initialMouseY = e.clientY;
    var mapdiv = document.getElementById('mapdiv');
    mapStartDragX = parseInt(mapdiv.style.left, 10);
    mapStartDragY = parseInt(mapdiv.style.top, 10);
    window.addEventListener('mousemove', MapMove, true);
}

function FixMapLocation() //This function is called to ensure that the map does not go off the screen.
{
    var mapimg = document.getElementById('mapimg');
    
    if (mapX > windowWidth*0.8)
    {
        mapX = windowWidth*0.8;
    }

    if ((mapX+mapimg.width) < windowWidth * 0.2)
    {
        mapX = windowWidth*0.2-mapimg.width;
    }

    if (mapY > windowHeight*0.8)
    {
        mapY = windowHeight*0.8;
    }

    if ((mapY+mapimg.height) < windowHeight * 0.2)
    {
        mapY = windowHeight*0.2-mapimg.height;
    }
}

function MapMove(e)
{
    var mapdiv = document.getElementById('mapdiv');
    mapdiv.style.position = 'absolute';
    dx = e.clientX - initialMouseX;
    dy = e.clientY - initialMouseY;
    mapX = mapStartDragX+dx;
    mapY = mapStartDragY+dy;


    FixMapLocation();
    mapdiv.style.left = (mapX) + 'px';
    mapdiv.style.top = (mapY) + 'px';
}

function MouseScroll(e)
{
    const delta = Math.sign(e.deltaY);
    if (delta == -1) //zooming in
    {
        if (mapScale < 3.0)
        {
            mapScale = mapScale / 0.8;
        }
    }
    else //zooming out
    {
        if (mapScale > 0.3)
        {
            mapScale = mapScale * 0.8;
        }
    }
    RefreshMap();
    RefreshPlayerMarker();
    prevMapScale = mapScale;
}

function RefreshMap() //This is intended to be called after scaling the map to recalculate the dx/dy offsets and reposition the map accordingly.
{
    var map = document.getElementById('mapimg');
    var mapdiv = document.getElementById('mapdiv');

    mapX = parseInt(mapdiv.style.left, 10); //Current Map X
    mapY = parseInt(mapdiv.style.top, 10); //Current Map Y

    map.width = mapWidth * mapScale; //Adjust Width for new Map Scale
    map.height = mapHeight * mapScale; //Adjust Height for new Map Scale

    factor = mapScale/prevMapScale;
    var dx = (mouseScrollX - mapX) * (factor-1);
    var dy = (mouseScrollY - mapY) * (factor-1);
    mapX = mapX - dx;
    mapY = mapY- dy;

    FixMapLocation(); //Adjusts map location if it is going off screen
    mapdiv.style.left = (mapX) + 'px';
    mapdiv.style.top = (mapY) + 'px';
    RefreshBlips(); //Adjust blip locations for landmarks
}

function WorldToMapX(worldX)
{
    return (worldX + 234002.2054794521) / 241.041095890411;
}

function WorldToMapY(worldY)
{
    return (worldY + 231101.3928571428) / 242.5535714285714;
}

function MapToWorldX(mapX)
{
    return 241.041095890411*mapX - 234002.2054794521;
}

function MapToWorldY(mapY)
{
    return 242.5535714285714*mapY - 231101.3928571428;
}

function RefreshPlayerMarker() //Called when map is resized to reposition player marker.
{
    var playerMarker = document.getElementById('playermarker');
    playerMarker.style.left = (playerMarker.imgX * mapScale -16) + 'px';
    playerMarker.style.top = (playerMarker.imgY * mapScale -16) + 'px';
}

function RefreshBlips() //Called when map is resized to reposition player marker.
{
    legendKeys.forEach(key =>
    {
        key.blips.forEach(blip =>
        {
            blip.style.left = (WorldToMapX(blip.worldX) * mapScale -12) + 'px';
            blip.style.top = (WorldToMapY(blip.worldY) * mapScale -12) + 'px';
        });
    });
    //Refresh destination (if one exists)
    var destinationMarker = document.getElementById("destinationmarker");
    if (destinationMarker.style.display == 'block') //If destination marker is visible, update position
    {
        destinationMarker.style.left = (WorldToMapX(destinationMarker.worldX) * mapScale -16) + 'px';
        destinationMarker.style.top = (WorldToMapY(destinationMarker.worldY) * mapScale - 32) + 'px';
    }
}

function UpdatePlayerPosition(worldX, worldY, worldZ, angle) //Called from map.lua
{
    var imgX = WorldToMapX(worldX);
    var imgY = WorldToMapY(worldY);
    var playerMarker = document.getElementById('playermarker');
    imgX = Math.floor(imgX);
    imgY = Math.floor(imgY);
    playerMarker.imgX = imgX;
    playerMarker.imgY = imgY;
    playerMarker.style.transform = 'rotate('+Math.floor(angle)+'deg)';
    RefreshPlayerMarker();
}

function CloseMap(e) 
{
    var keyCode = e.keyCode;
    if (keyCode==77) //77 = M
    {
        CallEvent('CloseMap', null);
    }
}
