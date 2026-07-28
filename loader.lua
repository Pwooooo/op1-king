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

local BypassTab = Window:AddTab("Bypass")
local CombatTab = Window:AddTab("Combat")
local SettingsTab = Window:AddTab("Settings")

-- Anti-Cheat Bypass

local BypassGroup = BypassTab:AddLeftGroupbox("Anti-Cheat Bypass")
local InfoGroup = BypassTab:AddRightGroupbox("Information")

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

local StatusLabel = BypassGroup:AddLabel("Bypass: Disabled")

local BypassToggle = BypassGroup:AddToggle("BypassToggle", {
    Text = "Enable Bypass",
    Default = false,
    Tooltip = "Hooks string.byte to swap stack data on anti-cheat checks",
    Callback = function(v)
        if v then enableBypass() else disableBypass() end
    end,
})

BypassGroup:AddButton({
    Text = "Enable Now",
    Func = function() enableBypass() Library:Notify("Bypass enabled", 2) end,
})

BypassGroup:AddButton({
    Text = "Disable Now",
    Func = function() disableBypass() Library:Notify("Bypass disabled", 2) end,
})

BypassGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end,
})

InfoGroup:AddLabel("Hooks string.byte to swap stack data on anti-cheat checks.", true)
InfoGroup:AddDivider()
InfoGroup:AddLabel("Keep OFF by default. Enable only when needed.", true)

-- No Spread

local SpreadGroup = CombatTab:AddLeftGroupbox("No Spread")
local SpreadInfo = CombatTab:AddRightGroupbox("Info")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local spreadConn = nil
local spreadActive = false
local spreadIntensity = 100

local spreadProps = {"Spread", "BulletSpread", "Accuracy", "Inaccuracy", "SpreadRadius", "MaxSpread", "MinSpread", "ShotSpread", "SpreadAngle", "Deviation", "Randomness"}

local function scanForSpread(obj)
    local results = {}
    local function recurse(o, depth)
        if depth > 10 then return end
        for _, prop in ipairs(spreadProps) do
            local s, v = pcall(function() return o[prop] end)
            if s and v ~= nil then
                table.insert(results, { obj = o, prop = prop, val = v })
            end
        end
        for _, child in ipairs(o:GetChildren()) do
            recurse(child, depth + 1)
        end
    end
    recurse(obj, 0)
    return results
end

local function applyNoSpread()
    spreadActive = true
    if spreadConn then return end

    spreadConn = RunService.Heartbeat:Connect(function()
        if not spreadActive then return end

        local char = LocalPlayer.Character
        if not char then return end

        local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:WaitForChild("Backpack", 0.1)

        for _, scope in ipairs({char, backpack, Players}) do
            if not scope then continue end
            local found = scanForSpread(scope)
            for _, entry in ipairs(found) do
                local newVal = entry.val * (1 - spreadIntensity / 100)
                pcall(function() entry.obj[entry.prop] = newVal end)
            end
        end
    end)
end

local function stopNoSpread()
    spreadActive = false
    if spreadConn then spreadConn:Disconnect(); spreadConn = nil end
end

SpreadGroup:AddToggle("NoSpreadToggle", {
    Text = "No Spread",
    Default = false,
    Tooltip = "Scans character, backpack, and Players for spread properties and zeros them",
    Callback = function(v)
        if v then applyNoSpread() else stopNoSpread() end
    end,
})

SpreadGroup:AddDivider()

SpreadGroup:AddSlider("SpreadIntensity", {
    Text = "Intensity",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Suffix = "%",
    Tooltip = "How much spread to remove",
    Callback = function(v)
        spreadIntensity = v
    end,
})

SpreadGroup:AddDivider()

SpreadGroup:AddButton({
    Text = "Scan for Spread",
    Tooltip = "Find spread properties on your character and tools",
    Func = function()
        local char = LocalPlayer.Character
        if not char then Library:Notify("No character", 2) return end
        local total = 0
        local function scan(o, depth)
            if depth > 8 then return end
            for _, prop in ipairs(spreadProps) do
                local s, v = pcall(function() return o[prop] end)
                if s and v ~= nil then
                    total = total + 1
                end
            end
            for _, child in ipairs(o:GetChildren()) do
                scan(child, depth + 1)
            end
        end
        scan(char, 0)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then scan(bp, 0) end
        Library:Notify("Found " .. total .. " spread props", 3)
    end,
})

SpreadGroup:AddButton({
    Text = "Reset",
    Func = function()
        stopNoSpread()
        Toggles.NoSpreadToggle:SetValue(false)
        Library:Notify("No Spread reset", 2)
    end,
})

SpreadInfo:AddLabel("Scans character, backpack, and all children recursively for spread-related properties and zeros them every frame.", true)
SpreadInfo:AddDivider()
SpreadInfo:AddLabel("Works with any character type. Not guaranteed in all games.", true)

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
