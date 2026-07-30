
local repo              = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/";
local Library           = loadstring(game:HttpGet(repo .. "Library.lua"))();

end

Loader.Execute();

-- == TSB Device Spoofer ==
do
    local UIS = game:GetService("UserInputService")
    local currentMode = nil
    local spoofValues = {}
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = function(self, key)
        if self == UIS and spoofValues[key] ~= nil then
            return spoofValues[key]
        end
        return oldIndex(self, key)
    end
    setreadonly(mt, true)

    local function applySpoof(mode)
        if mode == currentMode then return end
        currentMode = mode
        if mode == "Mobile" then
            spoofValues = { TouchEnabled = true, KeyboardEnabled = false, MouseEnabled = false, GamepadEnabled = false }
        elseif mode == "Console" then
            spoofValues = { TouchEnabled = false, KeyboardEnabled = false, MouseEnabled = false, GamepadEnabled = true }
        elseif mode == "PC" then
            spoofValues = { TouchEnabled = false, KeyboardEnabled = true, MouseEnabled = true, GamepadEnabled = false }
        end
    end

    local win = Library:CreateWindow({
        Name = "TSB Spoofer",
        Description = "Device Spoofer",
        Resize = true,
    })

    local tab = win:AddTab("Spoofer")
    local g = tab:AddLeftGroupbox("Device Type")
    g:AddDropdown("device_select", {
        Text = "Select Device",
        Values = { "Mobile", "Console", "PC" },
        Default = "PC",
        Callback = function(v)
            applySpoof(v)
            Library:Notify("Device spoofed to: " .. v, 2)
        end,
    })
    g:AddButton({ Text = "Reset", Func = function()
        spoofValues = {}
        currentMode = nil
        Library:Notify("Device spoof reset", 2)
    end })
end

