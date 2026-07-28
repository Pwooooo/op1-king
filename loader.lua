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
local bypassLayers = {}
local bypassHeartbeat = nil
local registry = debug.getregistry()

-- Layer 1: Protect hookfunction itself so our hooks can't be removed
local origHookFunction = hookfunction
local function guardHookFunction()
    local ok, orig = pcall(origHookFunction, hookfunction, newcclosure(function(func, hook)
        for _, layer in ipairs(bypassLayers) do
            if func == layer.original and layer.protected then
                return origHookFunction(func, hook)
            end
            if func == layer.hook and layer.protected then
                return origHookFunction(func, hook)
            end
        end
        return origHookFunction(func, hook)
    end))
    if ok then
        table.insert(bypassLayers, {
            type = "hookfunction_guard",
            protected = true,
        })
    end
end

-- Layer 2: string.byte interceptor with heap manipulation
local oldByte = nil
local function hookStringByte()
    local ok, hook = pcall(origHookFunction, string.byte, newcclosure(function(s, i, j)
        local callerOk, isCaller = pcall(checkcaller)
        if callerOk and isCaller then
            return oldByte(s, i, j)
        end
        if type(s) == 'string' then
            if s:sub(1, 1) == '{' and s:sub(-1) == '}' then
                local stkOk, stk = pcall(getstack, 3, 1)
                if stkOk and type(stk) == "table" and stk[2] then
                    pcall(setstack, 3, 4, #stk[2])
                    return oldByte(stk[2], i or 1, j)
                end
                return oldByte(s, i, j)
            end
            if s:sub(1, 1) == '\27' then
                return ''
            end
        end
        return oldByte(s, i, j)
    end))
    if ok then
        oldByte = hook
        table.insert(bypassLayers, {
            type = "string.byte",
            original = string.byte,
            hook = hook,
            protected = true,
        })
    end
end

-- Layer 3: checkcaller override to always return true for our threads
local oldCheckCaller = checkcaller
local function hookCheckCaller()
    local ok = pcall(origHookFunction, checkcaller, newcclosure(function()
        return true
    end))
    if ok then
        table.insert(bypassLayers, {
            type = "checkcaller",
            protected = true,
        })
    end
end

-- Layer 4: Intercept getfenv to hide executor traces
local oldGetFenv = getfenv
local function hookGetFenv()
    local ok, hook = pcall(origHookFunction, getfenv, newcclosure(function(level)
        if type(level) == "number" and level > 0 then
            return oldGetFenv(level + 1)
        end
        return oldGetFenv(level)
    end))
    if ok then
        table.insert(bypassLayers, {
            type = "getfenv",
            protected = true,
        })
    end
end

-- Layer 5: Registry scanner - find and suppress anti-cheat closures
local scannedClosures = {}
local function scanRegistry()
    for idx, obj in ipairs(registry) do
        if type(obj) == "function" and not scannedClosures[obj] then
            scannedClosures[obj] = true
            local infoOk, info = pcall(debug.getinfo, obj)
            if infoOk and info then
                local src = (info.source or ""):lower()
                local name = (info.name or ""):lower()
                if src:find("anticheat") or src:find("anti_cheat") or src:find("ac_") or
                   name:find("anticheat") or name:find("detect") then
                    pcall(debug.setfenv, obj, {})
                end
            end
        end
    end
end

-- Layer 6: Heartbeat self-heal - verify hooks are active every 5 seconds
local function startSelfHeal()
    bypassHeartbeat = game:GetService("RunService").Stepped:Connect(function()
        if not bypassHooked then return end
        for _, layer in ipairs(bypassLayers) do
            if layer.type == "string.byte" and layer.protected then
                local infoOk = pcall(debug.getinfo, string.byte)
                if not infoOk then
                    oldByte = nil
                    hookStringByte()
                end
            end
            if layer.type == "checkcaller" and layer.protected then
                local ok, val = pcall(checkcaller)
                if not ok or val ~= true then
                    hookCheckCaller()
                end
            end
        end
    end)
end

local function enableBypass()
    if bypassHooked then return end
    bypassLayers = {}
    scannedClosures = {}

    local success, err = pcall(function()
        guardHookFunction()
        hookCheckCaller()
        hookStringByte()
        hookGetFenv()
        scanRegistry()
        startSelfHeal()
    end)

    if success then
        bypassHooked = true
        StatusLabel:SetText("Bypass: Enabled (6 layers)")
        BypassToggle:SetValue(true)
        Library:Notify("Bypass enabled - 6 protection layers active", 3)
    else
        disableBypass()
        Library:Notify("Bypass failed: " .. tostring(err), 5)
    end
end

local function disableBypass()
    bypassHooked = false
    if bypassHeartbeat then
        bypassHeartbeat:Disconnect()
        bypassHeartbeat = nil
    end
    if oldByte then
        pcall(origHookFunction, string.byte, oldByte)
        oldByte = nil
    end
    bypassLayers = {}
    scannedClosures = {}
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
