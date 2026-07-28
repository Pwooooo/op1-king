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
