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
local origByte = nil
local origChar = nil
local origResetEnv = nil
local healThread = nil

local function stackSwap(level)
    level = level or 3
    local ok1, stack = pcall(getstack, level, 1)
    if ok1 and type(stack) == "table" and stack[2] then
        stack[1] = stack[2]
        stack[5] = #stack[2]
        pcall(setstack, level, 4, stack[5])
        return stack[1]
    end
    return nil
end

local function applyHooks()
    if not bypassHooked then return end

    -- Hook string.byte (stack swap on JSON-like strings)
    local s1, v1 = pcall(hookfunction, string.byte, newcclosure(function(s, i)
        if checkcaller() or type(s) ~= 'string' or not (s:sub(1, 1) == '{' and s:sub(-1) == '}') then
            return origByte(s, i)
        end
        local swapped = stackSwap()
        return origByte(swapped or s, i)
    end))
    if s1 and not origByte then origByte = v1 end

    -- Hook string.char
    local s2, v2 = pcall(hookfunction, string.char, newcclosure(function(...)
        if checkcaller() then
            local args = {...}
            if #args == 0 then return "" end
            return origChar(unpack(args))
        end
        local ok1, stack = pcall(getstack, 3, 1)
        if ok1 and type(stack) == "table" and stack[2] and type(stack[2]) == "string" and stack[2]:sub(1,1) == '{' then
            local swapped = stackSwap()
            if swapped then
                return origChar(swapped:byte(1, #swapped))
            end
        end
        return origChar(...)
    end))
    if s2 and not origChar then origChar = v2 end

    -- Protect shared.extras.ResetEnv (called per-shot)
    local ok3, extras = pcall(function() return shared.extras end)
    if ok3 and type(extras) == "table" and type(extras.ResetEnv) == "function" then
        local needWrap = false
        if not origResetEnv then
            origResetEnv = extras.ResetEnv
            needWrap = true
        elseif extras.ResetEnv ~= origResetEnv and extras.ResetEnv ~= nil then
            origResetEnv = extras.ResetEnv
            needWrap = true
        end
        if needWrap and origResetEnv then
            local wrapped = newcclosure(function(...)
                if bypassHooked then
                    local results = {pcall(origResetEnv, ...)}
                    task.spawn(function()
                        task.wait(0.1)
                        applyHooks()
                    end)
                    return unpack(results, 1, table.maxn(results))
                end
                return origResetEnv(...)
            end)
            pcall(hookfunction, extras.ResetEnv, wrapped)
            extras.ResetEnv = wrapped
        end
    end
end

local function enableBypass()
    if bypassHooked then return end
    bypassHooked = true

    applyHooks()

    -- Self-healing: verify hooks every 3s, reapply if missing
    healThread = task.spawn(function()
        while bypassHooked do
            task.wait(3)
            if not bypassHooked then break end
            local s1, r1 = pcall(string.byte, "test", 1)
            if s1 and r1 ~= 116 then
                pcall(hookfunction, string.byte, newcclosure(function(s, i)
                    if checkcaller() or type(s) ~= 'string' or not (s:sub(1, 1) == '{' and s:sub(-1) == '}') then
                        return origByte(s, i)
                    end
                    local swapped = stackSwap()
                    return origByte(swapped or s, i)
                end))
            end
            local s2, r2 = pcall(string.char, 116)
            if s2 and r2 ~= "t" then
                pcall(hookfunction, string.char, newcclosure(function(...)
                    if checkcaller() then return origChar(...) end
                    return origChar(...)
                end))
            end
        end
    end)

    StatusLabel:SetText("Bypass: Enabled")
    BypassToggle:SetValue(true)
    Library:Notify("Bypass enabled", 2)
end

local function disableBypass()
    bypassHooked = false
    if healThread then task.cancel(healThread); healThread = nil end
    if origByte then pcall(hookfunction, string.byte, origByte); origByte = nil end
    if origChar then pcall(hookfunction, string.char, origChar); origChar = nil end
    if origResetEnv then
        pcall(function()
            local e = shared.extras
            if e and type(e) == "table" and type(origResetEnv) == "function" then
                pcall(hookfunction, e.ResetEnv, origResetEnv)
                e.ResetEnv = origResetEnv
            end
        end)
        origResetEnv = nil
    end
    StatusLabel:SetText("Bypass: Disabled")
    BypassToggle:SetValue(false)
    Library:Notify("Bypass disabled", 2)
end

local StatusLabel = BypassGroup:AddLabel("Bypass: Disabled")

local BypassToggle = BypassGroup:AddToggle("BypassToggle", {
    Text = "Enable Bypass",
    Default = false,
    Tooltip = "Hooks string.byte, string.char, protects shared.extras.ResetEnv, 3s self-healing",
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

InfoGroup:AddLabel("Hooks string.byte and string.char with stack swap. Protects shared.extras.ResetEnv. Auto-heals every 3s.", true)
InfoGroup:AddDivider()
InfoGroup:AddLabel("Keep OFF by default. Enable only when needed.", true)

-- No Spread (hooks Gun.send_shoot to zero spread state)

local SpreadGroup = CombatTab:AddLeftGroupbox("No Spread")
local SpreadInfo = CombatTab:AddRightGroupbox("Info")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local gunModuleSp = nil
local oldSendShoot = nil
local noSpreadHooked = false

local function getGunModule()
    if gunModuleSp then return gunModuleSp end
    local s, m = pcall(require, ReplicatedStorage.Modules.Items.Item.Gun)
    if s then gunModuleSp = m end
    return gunModuleSp
end

local function enableNoSpread()
    if noSpreadHooked then return end
    local mod = getGunModule()
    if not mod then
        Library:Notify("No Spread: failed to load Gun module", 3)
        return
    end
    oldSendShoot = mod.send_shoot
    mod.send_shoot = function(p1, ...)
        if noSpreadHooked and p1 and p1.states and p1.states.spread then
            local orig = p1.states.spread:get()
            p1.states.spread:set(0)
            oldSendShoot(p1, ...)
            p1.states.spread:set(orig)
            return
        end
        return oldSendShoot(p1, ...)
    end
    noSpreadHooked = true
    Library:Notify("No Spread enabled", 2)
end

local function disableNoSpread()
    if not noSpreadHooked then return end
    local mod = getGunModule()
    if mod and oldSendShoot then
        mod.send_shoot = oldSendShoot
    end
    oldSendShoot = nil
    noSpreadHooked = false
    Library:Notify("No Spread disabled", 2)
end

SpreadGroup:AddToggle("NoSpreadToggle", {
    Text = "No Spread",
    Default = false,
    Tooltip = "Hooks Gun.send_shoot to zero spread state before firing",
    Callback = function(v)
        if v then enableNoSpread() else disableNoSpread() end
    end,
})

SpreadGroup:AddDivider()

SpreadGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if noSpreadHooked then disableNoSpread() else enableNoSpread() end
    end,
})

SpreadGroup:AddButton({
    Text = "Reset",
    Func = function()
        disableNoSpread()
        Library:Notify("No Spread reset", 2)
    end,
})

SpreadInfo:AddLabel("Hooks Gun.send_shoot to set p1.states.spread to 0 before the spread calculation, then restores it after.", true)
SpreadInfo:AddDivider()
SpreadInfo:AddLabel("Works with OP1's client-sided hitscan. Zero spread = bullets go exactly where aimed.", true)

-- Bullet TP (hooks Gun.get_shoot_look to redirect aim to nearest enemy)

local BulletTPGroup = CombatTab:AddLeftGroupbox("Bullet TP")

local gunModuleBt = nil
local oldGetShootLook = nil
local bulletTPHooked = false

local function findNearestEnemy()
    local char = Players.LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == Players.LocalPlayer then continue end
        local tChar = player.Character
        if not tChar then continue end
        local hum = tChar:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso")
        if not tRoot then continue end
        local dist = (root.Position - tRoot.Position).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = tChar
        end
    end
    return nearest
end

local function getGunModuleBT()
    if gunModuleBt then return gunModuleBt end
    local s, m = pcall(require, ReplicatedStorage.Modules.Items.Item.Gun)
    if s then gunModuleBt = m end
    return gunModuleBt
end

local function enableBulletTP()
    if bulletTPHooked then return end
    local mod = getGunModuleBT()
    if not mod then
        Library:Notify("Bullet TP: failed to load Gun module", 3)
        return
    end
    oldGetShootLook = mod.get_shoot_look
    mod.get_shoot_look = function(p1)
        if bulletTPHooked then
            local nearest = findNearestEnemy()
            if nearest then
                local head = nearest:FindFirstChild("Head") or nearest:FindFirstChildOfClass("BasePart")
                if head then
                    local cam = workspace.CurrentCamera
                    if cam then
                        return CFrame.lookAt(cam.CFrame.Position, head.Position)
                    end
                end
            end
        end
        return oldGetShootLook(p1)
    end
    bulletTPHooked = true
    Library:Notify("Bullet TP enabled", 2)
end

local function disableBulletTP()
    if not bulletTPHooked then return end
    local mod = getGunModuleBT()
    if mod and oldGetShootLook then
        mod.get_shoot_look = oldGetShootLook
    end
    oldGetShootLook = nil
    bulletTPHooked = false
    Library:Notify("Bullet TP disabled", 2)
end

BulletTPGroup:AddToggle("BulletTPToggle", {
    Text = "Bullet TP",
    Default = false,
    Tooltip = "Hooks Gun.get_shoot_look to redirect bullet direction to nearest enemy",
    Callback = function(v)
        if v then enableBulletTP() else disableBulletTP() end
    end,
})

BulletTPGroup:AddDivider()

BulletTPGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if bulletTPHooked then disableBulletTP() else enableBulletTP() end
    end,
})

BulletTPGroup:AddDivider()

BulletTPGroup:AddLabel("Hooks Gun.get_shoot_look to return a CFrame pointing at the nearest enemy's head. Works with OP1's client-sided hitscan.", true)

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
