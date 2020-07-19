
--If developerModeEnabled is set to true, it will allow for teleporting when the map is open via right click.
developerModeEnabled = true

legendkeys = {}

legendkeys[1] = {}
legendkeys[1].iconPath = "http://asset/" .. GetPackageName() .. "/client/web/icons/shopping-cart.png"
legendkeys[1].displayText = "Market"
legendkeys[1].blips = {
    {129000, 78521},
    {49000, 133000},
}

legendkeys[2] = {}
legendkeys[2].iconPath = "http://asset/" .. GetPackageName() .. "/client/web/icons/shield.png"
legendkeys[2].displayText = "Gun Store"
legendkeys[2].blips = {
    {101527, -34633},
    {135200, 192240},
}