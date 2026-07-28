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

local function safeGetStack(level, idx)
    local s, v = pcall(getstack, level, idx)
    if s and type(v) == "table" then return v end
    return nil
end

local function safeSetStack(level, idx, val)
    local s = pcall(setstack, level, idx, val)
    return s
end

local function enableBypass()
    if bypassHooked then return end
    local ok, hook = pcall(hookfunction, string.byte, newcclosure(function(a0, a1)
        local okCaller, isCaller = pcall(checkcaller)
        if okCaller and isCaller then
            return oldStrByte(a0, a1)
        end
        if type(a0) ~= 'string' or not (a0:sub(1, 1) == '{' and a0:sub(-1) == '}') then
            return oldStrByte(a0, a1)
        end
        local ok1, luraph = pcall(getstack, 3, 1)
        if ok1 and type(luraph) == "table" and luraph[2] then
            local ok2 = pcall(setstack, 3, 4, #luraph[2])
            return oldStrByte(luraph[2], a1)
        end
        return oldStrByte(a0, a1)
    end))
    if not ok then
        Library:Notify("Bypass hook failed: " .. tostring(hook), 4)
        return
    end
    oldStrByte = hook
    bypassHooked = true
    StatusLabel:SetText("Bypass: Enabled")
    BypassToggle:SetValue(true)
end

local function disableBypass()
    if not bypassHooked or not oldStrByte then return end
    pcall(hookfunction, string.byte, oldStrByte)
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

-- Bullet TP

local BulletTPGroup = CombatTab:AddLeftGroupbox("Bullet TP")

local bulletTPConn = nil
local bulletTPActive = false
local handledBullets = {}
local bulletTpCooldown = 0

local function getTargetPart()
    local myPos = LocalPlayer.Character and LocalPlayer.Character:GetPivot().p
    if not myPos then return nil end
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head") or char:FindFirstChildOfClass("BasePart")
        if not head then continue end
        local dist = (head.Position - myPos).Magnitude
        if dist < closestDist then
            closest = head
            closestDist = dist
        end
    end
    return closest
end

local function enableBulletTP()
    if bulletTPActive then return end
    bulletTPActive = true
    handledBullets = {}

    bulletTPConn = RunService.Heartbeat:Connect(function()
        if not bulletTPActive or not Toggles.BulletTPToggle.Value then return end

        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
        if not root then return end

        local target = getTargetPart()
        if not target then return end

        bulletTpCooldown = bulletTpCooldown + 1
        if bulletTpCooldown % 3 ~= 0 then return end

        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("BasePart") and not handledBullets[v] then
                local dist = (v.Position - root.Position).Magnitude
                local vel = math.max(v.Velocity.Magnitude, v.AssemblyLinearVelocity.Magnitude)
                if dist < 80 and vel > 20 then
                    handledBullets[v] = true
                    v.CFrame = target.CFrame
                    v.Velocity = (target.Position - v.Position).Unit * math.max(v.Velocity.Magnitude, 100)
                end
            end
        end

        for b in pairs(handledBullets) do
            if not b.Parent then handledBullets[b] = nil end
            if #handledBullets > 500 then handledBullets = {} end
        end
    end)
end

local function disableBulletTP()
    bulletTPActive = false
    handledBullets = {}
    if bulletTPConn then bulletTPConn:Disconnect(); bulletTPConn = nil end
end

BulletTPGroup:AddToggle("BulletTPToggle", {
    Text = "Bullet TP",
    Default = false,
    Tooltip = "Teleports nearby high-velocity parts to the nearest enemy",
    Callback = function(v)
        if v then enableBulletTP() else disableBulletTP() end
    end,
})

BulletTPGroup:AddDivider()

BulletTPGroup:AddLabel("Checks workspace parts within 80 studs moving faster than 20 velocity. Only processes every 3 frames.", true)

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
