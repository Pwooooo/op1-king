--[[
    OP1 King - Anti-Cheat Bypass
    LinoriaLib UI
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()

getgenv().SaveManager = SaveManager
getgenv().ThemeManager = ThemeManager

local Window = Library:CreateWindow({
    Title = "OP1 King",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(550, 500),
})

local MainTab = Window:AddTab("Bypass")
local CombatTab = Window:AddTab("Combat")
local SettingsTab = Window:AddTab("Settings")

local BypassGroup = MainTab:AddLeftGroupbox("Anti-Cheat Bypass")
local InfoGroup = MainTab:AddRightGroupbox("Information")
local StatusGroup = MainTab:AddLeftGroupbox("Status")

local bypassHooked = false
local oldStrByte = nil

local function enableBypass()
    if bypassHooked then return end

    oldStrByte = hookfunction(string.byte, newcclosure(function(a0, a1)
        if (checkcaller() or type(a0) ~= 'string' or not (a0:sub(1, 1) == '{' and a0:sub(-1) == '}')) then
            return oldStrByte(a0, a1)
        end

        local luraph = getstack(3, 1)
        luraph[1] = luraph[2]
        luraph[5] = #luraph[2]
        setstack(3, 4, luraph[5])

        return oldStrByte(luraph[1], a1)
    end))

    bypassHooked = true
    StatusLabel:SetText("Bypass: Enabled")
    BypassToggle:SetValue(true)
end

local function disableBypass()
    if not bypassHooked or not oldStrByte then return end
    hookfunction(string.byte, oldStrByte)
    oldStrByte = nil
    bypassHooked = false
    StatusLabel:SetText("Bypass: Disabled")
    BypassToggle:SetValue(false)
end

local StatusLabel = StatusGroup:AddLabel("Bypass: Disabled")
StatusGroup:AddDivider()

local BypassToggle = BypassGroup:AddToggle("BypassToggle", {
    Text = "Enable Bypass",
    Default = false,
    Tooltip = "Hooks string.byte to swap stack data on anti-cheat checks",
    Callback = function(v)
        if v then
            enableBypass()
        else
            disableBypass()
        end
    end,
})

BypassGroup:AddDivider()

BypassGroup:AddButton({
    Text = "Enable Now",
    Func = function()
        enableBypass()
        Library:Notify("Bypass enabled", 2)
    end,
})

BypassGroup:AddButton({
    Text = "Disable Now",
    Func = function()
        disableBypass()
        Library:Notify("Bypass disabled", 2)
    end,
})

BypassGroup:AddDivider()

BypassGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end,
})

InfoGroup:AddLabel("This bypass hooks string.byte to detect when the anti-cheat checks payload formatting and swaps the stack data to evade detection.", true)

InfoGroup:AddDivider()

InfoGroup:AddLabel("Toggle the bypass ON/OFF using the toggle above. ON by default is NOT recommended â€” enable only when needed.", true)

-- No Spread

local SpreadGroup = CombatTab:AddLeftGroupbox("No Spread")
local SpreadInfo = CombatTab:AddRightGroupbox("Info")

local function findSpreadProperties(tool)
    local props = {"Spread", "BulletSpread", "Accuracy", "Inaccuracy", "SpreadRadius", "MaxSpread", "MinSpread", "ShotSpread", "SpreadAngle"}
    for _, prop in ipairs(props) do
        local success, val = pcall(function() return tool[prop] end)
        if success and val ~= nil then
            return prop, val
        end
    end
    for _, child in ipairs(tool:GetDescendants()) do
        for _, prop in ipairs(props) do
            local success, val = pcall(function() return child[prop] end)
            if success and val ~= nil then
                return child, prop, val
            end
        end
    end
end

local spreadConn = nil
local spreadActive = false
local spreadIntensity = 100

local function applyNoSpread(intensity)
    spreadActive = true
    if spreadConn then return end

    local player = game.Players.LocalPlayer
    if not player then return end

    spreadConn = game:GetService("RunService").Heartbeat:Connect(function()
        if not spreadActive then return end

        local char = player.Character
        if not char then return end

        local tool = char:FindFirstChildOfClass("Tool") or char:FindFirstChildOfClass("HopperBin")
        if not tool then return end

        local target, propName, origVal = findSpreadProperties(tool)
        if not target then return end

        local obj, prop = target, propName
        if type(target) == "string" then
            obj = tool
            prop = target
        end

        local newVal = origVal * (1 - spreadIntensity / 100)
        pcall(function() obj[prop] = newVal end)
    end)
end

local function stopNoSpread()
    spreadActive = false
    if spreadConn then
        spreadConn:Disconnect()
        spreadConn = nil
    end
end

SpreadGroup:AddToggle("NoSpreadToggle", {
    Text = "No Spread",
    Default = false,
    Tooltip = "Removes weapon bullet spread",
    Callback = function(v)
        if v then
            applyNoSpread(spreadIntensity)
        else
            stopNoSpread()
        end
    end,
})

SpreadGroup:AddDivider()

local SpreadIntensitySlider = SpreadGroup:AddSlider("SpreadIntensity", {
    Text = "Intensity",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Suffix = "%",
    Tooltip = "How much spread to remove",
    Callback = function(v)
        spreadIntensity = v
        if spreadActive then
            applyNoSpread(v)
        end
    end,
})

SpreadGroup:AddDivider()

SpreadGroup:AddButton({
    Text = "Scan Tool",
    Tooltip = "Print current tool's spread properties to console",
    Func = function()
        local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
        if not char then Library:Notify("No character", 2) return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then Library:Notify("No tool equipped", 2) return end
        local target, prop, val = findSpreadProperties(tool)
        if target then
            local name = type(target) == "string" and target or target:GetFullName()
            Library:Notify("Spread: " .. tostring(prop) .. " = " .. tostring(val), 4)
        else
            Library:Notify("No spread property found on tool", 3)
        end
    end,
})

SpreadGroup:AddButton({
    Text = "Reset Spread",
    Func = function()
        stopNoSpread()
        Toggles.NoSpreadToggle:SetValue(false)
        Library:Notify("Spread reset", 2)
    end,
})

SpreadInfo:AddLabel("Scans your equipped tool for spread-related properties and zeros them out every frame.", true)

SpreadInfo:AddDivider()

SpreadInfo:AddLabel("Not all games use client-side spread properties. Some calculate spread server-side, in which case this won't work.", true)

Library:SetWatermark("OP1 King")

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetIgnoreIndexes({})
SaveManager:SetFolder("OP1King/configs")
ThemeManager:SetFolder("OP1King")

SaveManager:BuildConfigSection(SettingsTab)
ThemeManager:ApplyToTab(SettingsTab)

Window:SelectTab(1)

Library:Notify("OP1 King loaded. Bypass is OFF.", 4)
