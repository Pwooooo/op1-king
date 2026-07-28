local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "OP1 King",
    SubTitle = "anti-cheat bypass + combat",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Bypass = Window:AddTab({ Title = "Bypass", Icon = "shield" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Anti-Cheat Bypass

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
end

local function disableBypass()
    if not bypassHooked or not oldStrByte then return end
    hookfunction(string.byte, oldStrByte)
    oldStrByte = nil
    bypassHooked = false
end

do
    Tabs.Bypass:AddParagraph({
        Title = "Anti-Cheat Bypass",
        Content = "Hooks string.byte to swap stack data when the anti-cheat checks payload formatting."
    })

    local BypassToggle = Tabs.Bypass:AddToggle("BypassToggle", {
        Title = "Enable Bypass",
        Default = false
    })

    BypassToggle:OnChanged(function()
        if Options.BypassToggle.Value then
            enableBypass()
            Fluent:Notify({ Title = "OP1 King", Content = "Bypass enabled.", Duration = 3 })
        else
            disableBypass()
            Fluent:Notify({ Title = "OP1 King", Content = "Bypass disabled.", Duration = 3 })
        end
    end)

    Tabs.Bypass:AddButton({
        Title = "Enable Now",
        Description = "Force-enable the bypass immediately",
        Callback = function() Options.BypassToggle:SetValue(true) end
    })

    Tabs.Bypass:AddButton({
        Title = "Disable Now",
        Description = "Force-disable the bypass immediately",
        Callback = function() Options.BypassToggle:SetValue(false) end
    })

    Tabs.Bypass:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
        end
    })
end

-- No Spread

local spreadConn = nil
local spreadActive = false
local spreadIntensity = 100

local function findSpreadProperties(tool)
    local props = {"Spread", "BulletSpread", "Accuracy", "Inaccuracy", "SpreadRadius", "MaxSpread", "MinSpread", "ShotSpread", "SpreadAngle"}
    for _, prop in ipairs(props) do
        local success, val = pcall(function() return tool[prop] end)
        if success and val ~= nil then return prop, val end
    end
    for _, child in ipairs(tool:GetDescendants()) do
        for _, prop in ipairs(props) do
            local success, val = pcall(function() return child[prop] end)
            if success and val ~= nil then return child, prop, val end
        end
    end
end

local function applyNoSpread()
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
        if type(target) == "string" then obj = tool; prop = target end
        pcall(function() obj[prop] = origVal * (1 - spreadIntensity / 100) end)
    end)
end

local function stopNoSpread()
    spreadActive = false
    if spreadConn then spreadConn:Disconnect(); spreadConn = nil end
end

do
    Tabs.Combat:AddParagraph({
        Title = "No Spread",
        Content = "Removes weapon bullet spread by zeroing out spread properties every frame."
    })

    local NoSpreadToggle = Tabs.Combat:AddToggle("NoSpreadToggle", {
        Title = "No Spread",
        Default = false
    })

    NoSpreadToggle:OnChanged(function()
        if Options.NoSpreadToggle.Value then
            applyNoSpread()
        else
            stopNoSpread()
        end
    end)

    local IntensitySlider = Tabs.Combat:AddSlider("SpreadIntensity", {
        Title = "Intensity",
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
        Callback = function(v)
            spreadIntensity = v
            if spreadActive then applyNoSpread() end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Scan Tool",
        Description = "Show current tool's spread property",
        Callback = function()
            local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
            if not char then Fluent:Notify({ Title = "OP1 King", Content = "No character", Duration = 2 }) return end
            local tool = char:FindFirstChildOfClass("Tool")
            if not tool then Fluent:Notify({ Title = "OP1 King", Content = "No tool equipped", Duration = 2 }) return end
            local target, prop, val = findSpreadProperties(tool)
            if target then
                Fluent:Notify({ Title = "OP1 King", Content = "Spread property found: " .. tostring(prop) .. " = " .. tostring(val), Duration = 5 })
            else
                Fluent:Notify({ Title = "OP1 King", Content = "No spread property found on this tool", Duration = 3 })
            end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Reset Spread",
        Description = "Disable No Spread and restore defaults",
        Callback = function()
            stopNoSpread()
            Options.NoSpreadToggle:SetValue(false)
            Fluent:Notify({ Title = "OP1 King", Content = "Spread reset", Duration = 2 })
        end
    })
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("OP1King")
SaveManager:SetFolder("OP1King/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({ Title = "OP1 King", Content = "Loaded. Bypass is OFF.", Duration = 5 })
SaveManager:LoadAutoloadConfig()
