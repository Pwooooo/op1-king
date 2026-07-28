--[[
    OP1 King - Anti-Cheat Bypass
    Fluent UI Loader
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "OP1 King",
    SubTitle = "anti-cheat bypass",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "shield" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local bypassEnabled = false
local oldStrByte = nil

local function enableBypass()
    if bypassEnabled then return end

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

    bypassEnabled = true
end

local function disableBypass()
    if not bypassEnabled or not oldStrByte then return end
    hookfunction(string.byte, oldStrByte)
    oldStrByte = nil
    bypassEnabled = false
end

do
    Tabs.Main:AddParagraph({
        Title = "Anti-Cheat Bypass",
        Content = "Hooks string.byte to swap stack data when the anti-cheat checks payload formatting."
    })

    local BypassToggle = Tabs.Main:AddToggle("BypassToggle", {
        Title = "Enable Bypass",
        Default = false,
        Description = "Toggle the anti-cheat bypass on/off"
    })

    BypassToggle:OnChanged(function()
        if Options.BypassToggle.Value then
            enableBypass()
            Fluent:Notify({
                Title = "OP1 King",
                Content = "Anti-cheat bypass enabled.",
                Duration = 3
            })
        else
            disableBypass()
            Fluent:Notify({
                Title = "OP1 King",
                Content = "Anti-cheat bypass disabled.",
                Duration = 3
            })
        end
    end)

    Tabs.Main:AddButton({
        Title = "Enable Now",
        Description = "Force-enable the bypass immediately",
        Callback = function()
            Options.BypassToggle:SetValue(true)
        end
    })

    Tabs.Main:AddButton({
        Title = "Disable Now",
        Description = "Force-disable the bypass immediately",
        Callback = function()
            Options.BypassToggle:SetValue(false)
        end
    })

    Tabs.Main:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
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

Fluent:Notify({
    Title = "OP1 King",
    Content = "Loaded.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
