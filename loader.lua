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
local ScannerTab = Window:AddTab("Scanner")
local SettingsTab = Window:AddTab("Settings")

-- Anti-Cheat Bypass

local BypassGroup = BypassTab:AddLeftGroupbox("Anti-Cheat Bypass")
local StatusGroup = BypassTab:AddRightGroupbox("Status")
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

local StatusLabel = StatusGroup:AddLabel("Bypass: Disabled")
BypassGroup:AddDivider()

local BypassToggle = BypassGroup:AddToggle("BypassToggle", {
    Text = "Enable Bypass",
    Default = false,
    Tooltip = "Hooks string.byte to swap stack data on anti-cheat checks",
    Callback = function(v)
        if v then enableBypass() else disableBypass() end
    end,
})

BypassGroup:AddDivider()

BypassGroup:AddButton({
    Text = "Enable Now",
    Func = function() enableBypass() Library:Notify("Bypass enabled", 2) end,
})

BypassGroup:AddButton({
    Text = "Disable Now",
    Func = function() disableBypass() Library:Notify("Bypass disabled", 2) end,
})

BypassGroup:AddDivider()

BypassGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end,
})

InfoGroup:AddLabel("Hooks string.byte to detect when the anti-cheat checks payload formatting and swaps stack data to evade detection.", true)
InfoGroup:AddDivider()
InfoGroup:AddLabel("Keep OFF by default. Enable only when needed.", true)

-- No Spread

local SpreadGroup = CombatTab:AddLeftGroupbox("No Spread")
local SpreadInfo = CombatTab:AddRightGroupbox("Info")

local spreadConn = nil
local spreadActive = false
local spreadIntensity = 100

local function findSpreadProperties(tool)
    local props = {"Spread", "BulletSpread", "Accuracy", "Inaccuracy", "SpreadRadius", "MaxSpread", "MinSpread", "ShotSpread", "SpreadAngle"}
    for _, prop in ipairs(props) do
        local s, v = pcall(function() return tool[prop] end)
        if s and v ~= nil then return prop, v end
    end
    for _, child in ipairs(tool:GetDescendants()) do
        for _, prop in ipairs(props) do
            local s, v = pcall(function() return child[prop] end)
            if s and v ~= nil then return child, prop, v end
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

SpreadGroup:AddToggle("NoSpreadToggle", {
    Text = "No Spread",
    Default = false,
    Tooltip = "Removes weapon bullet spread every frame",
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
        if spreadActive then applyNoSpread() end
    end,
})

SpreadGroup:AddDivider()

SpreadGroup:AddButton({
    Text = "Scan Tool",
    Tooltip = "Show current tool's spread property",
    Func = function()
        local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
        if not char then Library:Notify("No character", 2) return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then Library:Notify("No tool equipped", 2) return end
        local target, prop, val = findSpreadProperties(tool)
        if target then
            Library:Notify("Spread: " .. tostring(prop) .. " = " .. tostring(val), 5)
        else
            Library:Notify("No spread property found", 3)
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

SpreadInfo:AddLabel("Scans your equipped tool for spread properties and zeros them every frame.", true)
SpreadInfo:AddDivider()
SpreadInfo:AddLabel("Only works on client-side spread. Server-authoritative spread cannot be modified.", true)

-- Scanner

local ScanGroup = ScannerTab:AddLeftGroupbox("Actions")
local ToolInfoGroup = ScannerTab:AddLeftGroupbox("Tool Info")
local ScriptGroup = ScannerTab:AddRightGroupbox("Scripts / Events")
local OutputGroup = ScannerTab:AddRightGroupbox("Scan Output")

local function getTool()
    local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool") or char:FindFirstChildOfClass("HopperBin")
end

local function scanToolProperties()
    local tool = getTool()
    if not tool then return "No tool equipped" end

    local lines = {"=== TOOL ===", tool:GetFullName(), "Class: " .. tool.ClassName, ""}

    local interested = {
        "Spread", "BulletSpread", "Accuracy", "Inaccuracy", "SpreadRadius",
        "MaxSpread", "MinSpread", "ShotSpread", "SpreadAngle",
        "Damage", "DamageMin", "DamageMax", "FireRate", "FireDelay",
        "Range", "MaxRange", "BulletsPerShot", "NumberOfBullets",
        "ReloadTime", "Ammo", "MaxAmmo", "Recoil", "RecoilX", "RecoilY",
        "AutoFire", "CanAutoFire", "SemiAuto",
        "Velocity", "BulletVelocity", "ProjectileSpeed",
        "Handle", "Grip", "GripUp", "GripForward", "GripPos",
        "ToolTip", "RequiresHandle",
    }

    for _, prop in ipairs(interested) do
        local s, v = pcall(function() return tool[prop] end)
        if s and v ~= nil then
            table.insert(lines, prop .. " = " .. tostring(v))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "--- Descendants ---")
    for _, child in ipairs(tool:GetDescendants()) do
        for _, prop in ipairs(interested) do
            local s, v = pcall(function() return child[prop] end)
            if s and v ~= nil then
                local short = child.Name:sub(1, 30)
                table.insert(lines, child.ClassName .. "[" .. short .. "]." .. prop .. " = " .. tostring(v))
            end
        end
    end

    local result = table.concat(lines, "\n")
    return result
end

local function scanToolRecursive()
    local tool = getTool()
    if not tool then return "No tool equipped" end

    local lines = {}
    local scanned = {}

    local function scanObj(obj, depth)
        if depth > 5 or scanned[obj] then return end
        scanned[obj] = true

        local prefix = string.rep("  ", depth)
        local name = obj.Name or "?"
        local class = obj.ClassName
        local props = ""

        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local len = #obj.Source
            props = " [" .. tostring(len) .. " chars]"
        elseif class == "RemoteEvent" or class == "RemoteFunction" or class == "BindableEvent" or class == "BindableFunction" then
            props = " <REMOTE>"
        end

        table.insert(lines, prefix .. name .. " [" .. class .. "]" .. props)

        for _, child in ipairs(obj:GetChildren()) do
            scanObj(child, depth + 1)
        end
    end

    scanObj(tool, 0)

    return table.concat(lines, "\n")
end

local function scanRemotes()
    local lines = {"RemoteEvent/Function connections:", ""}
    local tool = getTool()
    if not tool then return "No tool equipped" end

    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            table.insert(lines, child:GetFullName() .. " [" .. child.ClassName .. "]")
        end
    end

    if #lines == 2 then
        table.insert(lines, "No remotes found in tool")
    end

    return table.concat(lines, "\n")
end

local function scanScriptsSource()
    local tool = getTool()
    if not tool then return "No tool equipped" end

    local lines = {}
    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("LocalScript") or child:IsA("Script") then
            table.insert(lines, "=== " .. child:GetFullName() .. " ===")
            local trimmed = child.Source:sub(1, 1000)
            table.insert(lines, trimmed)
            table.insert(lines, "")
        end
    end

    if #lines == 0 then
        return "No scripts found in tool"
    end

    return table.concat(lines, "\n")
end

local function scanMouseConnections()
    local tool = getTool()
    if not tool then return "No tool equipped" end

    local lines = {"Firing mechanism detection:", ""}

    -- Check for common firing patterns
    local hasActivated = tool:FindFirstChild("Activated") ~= nil
    local hasDeactivated = tool:FindFirstChild("Deactivated") ~= nil
    local hasHandle = tool:FindFirstChild("Handle") ~= nil

    if hasActivated then table.insert(lines, "Has Activated event") end
    if hasDeactivated then table.insert(lines, "Has Deactivated event") end
    if hasHandle then table.insert(lines, "Has Handle (melee)") end

    -- Scan for MouseButton1 references in scripts
    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("LocalScript") then
            if child.Source:find("MouseButton1") or child.Source:find("MouseButton2") then
                table.insert(lines, "Script " .. child.Name .. " uses MouseButton click")
            end
            if child.Source:find("RemoteEvent") or child.Source:find("RemoteFunction") then
                table.insert(lines, "Script " .. child.Name .. " uses Remote")
            end
            if child.Source:find("FireServer") then
                table.insert(lines, "Script " .. child.Name .. " calls FireServer")
            end
        end
    end

    if #lines == 2 then
        table.insert(lines, "No firing mechanism detected")
    end

    return table.concat(lines, "\n")
end

local scanOutput = OutputGroup:AddLabel("Run a scan â†’", true)

ScanGroup:AddButton({
    Text = "Scan Tool Properties",
    Tooltip = "List all weapon stats (spread, damage, rate, etc.)",
    Func = function()
        scanOutput:SetText(scanToolProperties())
    end,
})

ScanGroup:AddButton({
    Text = "Scan Full Hierarchy",
    Tooltip = "Recursively list every object in the tool",
    Func = function()
        scanOutput:SetText(scanToolRecursive())
    end,
})

ScanGroup:AddDivider()

ScanGroup:AddButton({
    Text = "Scan Remotes",
    Tooltip = "Find RemoteEvent/RemoteFunction objects in the tool",
    Func = function()
        scanOutput:SetText(scanRemotes())
    end,
})

ScanGroup:AddButton({
    Text = "Scan Scripts Source",
    Tooltip = "Show source code of all LocalScripts/Scripts in the tool",
    Func = function()
        scanOutput:SetText(scanScriptsSource())
    end,
})

ScanGroup:AddButton({
    Text = "Scan Firing Mechanism",
    Tooltip = "Detect how the weapon fires (MouseButton, Remote, etc.)",
    Func = function()
        scanOutput:SetText(scanMouseConnections())
    end,
})

ScanGroup:AddDivider()

ScanGroup:AddButton({
    Text = "Copy Output",
    Tooltip = "Copy scan results to clipboard",
    Func = function()
        local text = scanOutput.TextLabel.Text
        pcall(setclipboard, text)
        Library:Notify("Copied to clipboard", 2)
    end,
})

ScanGroup:AddButton({
    Text = "Clear Output",
    Func = function()
        scanOutput:SetText("Cleared. Run a scan.")
    end,
})

ToolInfoGroup:AddLabel("Equip your weapon, then press a scan button. Results appear on the right.", true)
ToolInfoGroup:AddDivider()
ToolInfoGroup:AddLabel("Full Hierarchy shows every child object. Scripts Source dumps all code (max 1000 chars per script).", true)

-- Watermark & Managers

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
