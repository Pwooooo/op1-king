local kyri = loadstring(game:HttpGet("https://raw.githubusercontent.com/Justanewplayer19/KyriLib/refs/heads/main/source.lua"))()

local w = kyri.new("OP1 King", {
    GameName = "OP1King",
    AutoLoad = "default"
})

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ============================================================
-- Bypass tab
-- ============================================================
local bypassTab = w:tab("Bypass", "shield")

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
    local s1, v1 = pcall(hookfunction, string.byte, newcclosure(function(s, i)
        if checkcaller() or type(s) ~= 'string' or not (s:sub(1, 1) == '{' and s:sub(-1) == '}') then
            return origByte(s, i)
        end
        local swapped = stackSwap()
        return origByte(swapped or s, i)
    end))
    if s1 and not origByte then origByte = v1 end
    local s2, v2 = pcall(hookfunction, string.char, newcclosure(function(...)
        if checkcaller() then
            local args = {...}
            if #args == 0 then return "" end
            return origChar(unpack(args))
        end
        local ok1, stack = pcall(getstack, 3, 1)
        if ok1 and type(stack) == "table" and stack[2] and type(stack[2]) == "string" and stack[2]:sub(1,1) == '{' then
            local swapped = stackSwap()
            if swapped then return origChar(swapped:byte(1, #swapped)) end
        end
        return origChar(...)
    end))
    if s2 and not origChar then origChar = v2 end
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
                    task.spawn(function() task.wait(0.1); applyHooks() end)
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
    healThread = task.spawn(function()
        while bypassHooked do
            task.wait(3)
            if not bypassHooked then break end
            local s1, r1 = pcall(string.byte, "test", 1)
            if s1 and r1 ~= 116 then
                pcall(hookfunction, string.byte, newcclosure(function(s, i)
                    if checkcaller() or type(s) ~= 'string' or not (s:sub(1, 1) == '{' and s:sub(-1) == '}') then return origByte(s, i) end
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
    w:notify("Bypass", "enabled", 2)
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
    w:notify("Bypass", "disabled", 2)
end

bypassTab:toggle("Enable Bypass", false, function(v)
    if v then enableBypass() else disableBypass() end
end)

bypassTab:button("Enable Now", function() enableBypass() end)
bypassTab:button("Disable Now", function() disableBypass() end)
bypassTab:button("Rejoin Server", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end)

-- ============================================================
-- Combat tab
-- ============================================================
local combatTab = w:tab("Combat", "crosshair")

-- No Spread
combatTab:label("No Spread")

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
    if not mod then w:notify("No Spread", "failed to load Gun module", 3) return end
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
    w:notify("No Spread", "enabled", 2)
end

local function disableNoSpread()
    if not noSpreadHooked then return end
    local mod = getGunModule()
    if mod and oldSendShoot then mod.send_shoot = oldSendShoot end
    oldSendShoot = nil; noSpreadHooked = false
    w:notify("No Spread", "disabled", 2)
end

combatTab:toggle("No Spread", false, function(v)
    if v then enableNoSpread() else disableNoSpread() end
end)
combatTab:button("Toggle No Spread", function()
    if noSpreadHooked then disableNoSpread() else enableNoSpread() end
end)
combatTab:button("Reset No Spread", function() disableNoSpread(); w:notify("No Spread", "reset", 2) end)

combatTab:divider()

-- Bullet TP
combatTab:label("Bullet TP")

local gunModuleBt = nil
local oldGetShootLook = nil
local bulletTPHooked = false

local function findNearestEnemy()
    local char = LP.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LP then continue end
        local tChar = player.Character
        if not tChar then continue end
        local hum = tChar:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso")
        if not tRoot then continue end
        local dist = (root.Position - tRoot.Position).Magnitude
        if dist < nearestDist then nearestDist = dist; nearest = tChar end
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
    if not mod then w:notify("Bullet TP", "failed to load Gun module", 3) return end
    oldGetShootLook = mod.get_shoot_look
    mod.get_shoot_look = function(p1)
        if bulletTPHooked then
            local nearest = findNearestEnemy()
            if nearest then
                local head = nearest:FindFirstChild("Head") or nearest:FindFirstChildOfClass("BasePart")
                if head and workspace.CurrentCamera then
                    return CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, head.Position)
                end
            end
        end
        return oldGetShootLook(p1)
    end
    bulletTPHooked = true
    w:notify("Bullet TP", "enabled", 2)
end

local function disableBulletTP()
    if not bulletTPHooked then return end
    local mod = getGunModuleBT()
    if mod and oldGetShootLook then mod.get_shoot_look = oldGetShootLook end
    oldGetShootLook = nil; bulletTPHooked = false
    w:notify("Bullet TP", "disabled", 2)
end

combatTab:toggle("Bullet TP", false, function(v)
    if v then enableBulletTP() else disableBulletTP() end
end)
combatTab:button("Toggle Bullet TP", function()
    if bulletTPHooked then disableBulletTP() else enableBulletTP() end
end)

combatTab:divider()

-- Silent Aim
combatTab:label("Silent Aim")

local gunModuleSa = nil
local silentAimHooked = false
local silentAimOrig = nil
local silentAimFov = 60

local function isInFov(targetPos)
    local cam = workspace.CurrentCamera
    if not cam then return true end
    local dot = cam.CFrame.LookVector:Dot((targetPos - cam.CFrame.Position).Unit)
    return math.deg(math.acos(math.clamp(dot, -1, 1))) <= silentAimFov
end

local function getGunModuleSA()
    if gunModuleSa then return gunModuleSa end
    local s, m = pcall(require, ReplicatedStorage.Modules.Items.Item.Gun)
    if s then gunModuleSa = m end
    return gunModuleSa
end

local function enableSilentAim()
    if silentAimHooked then return end
    local mod = getGunModuleSA()
    if not mod then w:notify("Silent Aim", "failed to load Gun module", 3) return end
    local s, item = pcall(require, ReplicatedStorage.Modules.Items.Item)
    if not s or not item.ray_damage then w:notify("Silent Aim", "failed to load Item module", 3) return end
    silentAimOrig = item.ray_damage
    mod.ray_damage = function(p1, origin, direction, filter, ...)
        if silentAimHooked then
            local nearest = findNearestEnemy()
            if nearest then
                local head = nearest:FindFirstChild("Head") or nearest:FindFirstChildOfClass("BasePart")
                if head and isInFov(head.Position) then direction = (head.Position - origin) end
            end
        end
        return silentAimOrig(p1, origin, direction, filter, ...)
    end
    silentAimHooked = true
    w:notify("Silent Aim", "enabled", 2)
end

local function disableSilentAim()
    if not silentAimHooked then return end
    local mod = getGunModuleSA()
    if mod then mod.ray_damage = nil end
    silentAimHooked = false
    w:notify("Silent Aim", "disabled", 2)
end

combatTab:toggle("Silent Aim", false, function(v)
    if v then enableSilentAim() else disableSilentAim() end
end)
combatTab:slider("FOV Radius", 5, 500, 60, " deg", function(v) silentAimFov = v end)
combatTab:button("Toggle Silent Aim", function()
    if silentAimHooked then disableSilentAim() else enableSilentAim() end
end)

combatTab:divider()

-- Recoil Macro
combatTab:label("Recoil Macro")

local recoilActive = false
local recoilPullV = 15
local recoilPullH = 0
local oldNamecall = nil

local function macroEnable()
    if recoilActive then return end
    recoilActive = true
    if not oldNamecall then
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if recoilActive and method == "GetMouseDelta" and self == UIS then
                local delta = oldNamecall(self, ...)
                if self:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    return Vector2.new(delta.X + recoilPullH, delta.Y + recoilPullV)
                end
                return delta
            end
            return oldNamecall(self, ...)
        end)
    end
    w:notify("Recoil Macro", "enabled", 2)
end

local function macroDisable()
    recoilActive = false
    w:notify("Recoil Macro", "disabled", 2)
end

combatTab:toggle("Recoil Macro", false, function(v)
    if v then macroEnable() else macroDisable() end
end)
combatTab:slider("Vertical Pull", 0, 50, 15, "px", function(v) recoilPullV = v end)
combatTab:slider("Horizontal Pull", 0, 50, 0, "px", function(v) recoilPullH = v end)
combatTab:button("Toggle Recoil", function()
    if recoilActive then macroDisable() else macroEnable() end
end)

-- ============================================================
-- Visual tab
-- ============================================================
local visualTab = w:tab("Visual", "eye")

-- No Gun Movement
visualTab:label("No Gun Movement")

local gunModuleNm = nil
local oldRunning = nil
local noMoveHooked = false
local nmBobHb = nil

local function getGunModuleNM()
    if gunModuleNm then return gunModuleNm end
    local s, m = pcall(require, ReplicatedStorage.Modules.Items.Item.Gun)
    if s then gunModuleNm = m end
    return gunModuleNm
end

local function nmBobbing()
    if nmBobHb then return end
    nmBobHb = game:GetService("RunService").Heartbeat:Connect(function()
        local ok, cm = pcall(require, ReplicatedStorage.Modules.Character)
        if not ok then return end
        local got, char = pcall(cm.get_char)
        if not got or not char or not char.values then return end
        local bob = char.values.bob_cframe
        if bob and type(bob) == "table" and bob.Value then bob.Value = CFrame.new() end
    end)
end

local function stopNmBobbing()
    if nmBobHb then nmBobHb:Disconnect(); nmBobHb = nil end
end

local function enableNoMove()
    if noMoveHooked then return end
    local mod = getGunModuleNM()
    if not mod then w:notify("No Move", "failed to load Gun module", 3) return end
    oldRunning = mod.running
    mod.running = function(p1, p2, p3)
        if noMoveHooked then return end
        return oldRunning(p1, p2, p3)
    end
    nmBobbing(); noMoveHooked = true
    w:notify("No Gun Movement", "enabled", 2)
end

local function disableNoMove()
    if not noMoveHooked then return end
    local mod = getGunModuleNM()
    if mod and oldRunning then mod.running = oldRunning end
    oldRunning = nil; stopNmBobbing(); noMoveHooked = false
    w:notify("No Gun Movement", "disabled", 2)
end

visualTab:toggle("No Gun Movement", false, function(v)
    if v then enableNoMove() else disableNoMove() end
end)
visualTab:button("Toggle No Move", function()
    if noMoveHooked then disableNoMove() else enableNoMove() end
end)

visualTab:divider()

-- Bullet Tracers
visualTab:label("Bullet Tracers")

local gunModuleTr = nil
local oldTrail = nil
local tracerHooked = false
local tracerWidth = 0.5
local tracerColor = Color3.fromRGB(255, 200, 50)

local function getGunModuleTR()
    if gunModuleTr then return gunModuleTr end
    local s, m = pcall(require, ReplicatedStorage.Modules.Items.Item.Gun)
    if s then gunModuleTr = m end
    return gunModuleTr
end

local function enableTracers()
    if tracerHooked then return end
    local mod = getGunModuleTR()
    if not mod then w:notify("Tracers", "failed to load Gun module", 3) return end
    oldTrail = mod.trail
    mod.trail = function(p1, startPos, endPos, p4)
        if tracerHooked and startPos and endPos then
            local beam = Instance.new("Beam")
            local a1 = Instance.new("Attachment"); local a2 = Instance.new("Attachment")
            a1.Parent = workspace.Terrain; a2.Parent = workspace.Terrain
            a1.Position = startPos; a2.Position = endPos
            beam.Parent = workspace; beam.Attachment0 = a1; beam.Attachment1 = a2
            beam.Width0 = tracerWidth; beam.Width1 = tracerWidth
            beam.Color = ColorSequence.new(tracerColor)
            beam.Transparency = NumberSequence.new(0); beam.FaceCamera = true
            game:GetService("Debris"):AddItem(beam, 0.15)
            game:GetService("Debris"):AddItem(a1, 0.15); game:GetService("Debris"):AddItem(a2, 0.15)
        end
        if oldTrail then return oldTrail(p1, startPos, endPos, p4) end
    end
    tracerHooked = true
    w:notify("Bullet Tracers", "enabled", 2)
end

local function disableTracers()
    if not tracerHooked then return end
    local mod = getGunModuleTR()
    if mod and oldTrail then mod.trail = oldTrail end
    oldTrail = nil; tracerHooked = false
    w:notify("Bullet Tracers", "disabled", 2)
end

visualTab:toggle("Bullet Tracers", false, function(v)
    if v then enableTracers() else disableTracers() end
end)
visualTab:slider("Width", 0.1, 3, 0.5, " studs", function(v) tracerWidth = v end)
visualTab:colorpicker("Tracer Color", Color3.fromRGB(255, 200, 50), false, function(v) tracerColor = v end)
visualTab:button("Toggle Tracers", function()
    if tracerHooked then disableTracers() else enableTracers() end
end)

visualTab:divider()

-- No Screen Shake
visualTab:label("No Screen Shake")

local noShakeHooked = false
local windShakePaused = false
local bobHb = nil
local nsRecoilThread = nil
local nsCharMod = nil

local function getWindShake()
    local s, m = pcall(require, ReplicatedStorage.Modules.WindShake)
    return s and m
end

local function pauseWindShake()
    local ws = getWindShake()
    if ws and not windShakePaused then pcall(ws.Pause, ws); windShakePaused = true end
end

local function resumeWindShake()
    local ws = getWindShake()
    if ws and windShakePaused then pcall(ws.Resume, ws); windShakePaused = false end
end

local function noopBobbing()
    if bobHb then return end
    bobHb = game:GetService("RunService").Heartbeat:Connect(function()
        local ok, char = pcall(nsCharMod.get_char)
        if not ok or not char or not char.values then return end
        local bob = char.values.bob_cframe
        if bob and type(bob) == "table" and bob.Value then bob.Value = CFrame.new() end
    end)
end

local function stopBobbing()
    if bobHb then bobHb:Disconnect(); bobHb = nil end
end

local function enableNoShake()
    if noShakeHooked then return end
    noShakeHooked = true
    getgenv()._op1_ns_recoil = true
    local ok, cm = pcall(require, ReplicatedStorage.Modules.Character)
    if ok then nsCharMod = cm end
    nsRecoilThread = task.spawn(function()
        while noShakeHooked do
            if nsCharMod then
                local got, char = pcall(nsCharMod.get_char)
                if got and char and char.values then
                    local gun = char.values.equipped
                    if gun and gun.states then
                        pcall(gun.states.recoil_up.set, gun.states.recoil_up, 0)
                        pcall(gun.states.recoil_side.set, gun.states.recoil_side, 0)
                    end
                end
            end
            task.wait()
        end
    end)
    pauseWindShake(); noopBobbing()
    w:notify("No Screen Shake", "enabled", 2)
end

local function disableNoShake()
    if not noShakeHooked then return end
    noShakeHooked = false
    getgenv()._op1_ns_recoil = false
    if nsRecoilThread then task.cancel(nsRecoilThread); nsRecoilThread = nil end
    resumeWindShake(); stopBobbing()
    w:notify("No Screen Shake", "disabled", 2)
end

visualTab:toggle("No Screen Shake", false, function(v)
    if v then enableNoShake() else disableNoShake() end
end)
visualTab:button("Toggle No Shake", function()
    if noShakeHooked then disableNoShake() else enableNoShake() end
end)

-- ============================================================
-- Shaders tab
-- ============================================================
local shadersTab = w:tab("Shaders", "palette")

local bloomFx, bloomS = nil, { i = 1, s = 24, t = 0.5 }
local ccFx, ccS = nil, { sat = 0.2, con = 0.1, bri = 0, tint = Color3.new(1, 1, 1) }
local vigGui, vigImg = nil, nil

shadersTab:label("Bloom")
shadersTab:toggle("Bloom", false, function(v)
    pcall(function()
        if v then
            if not bloomFx then bloomFx = Instance.new("BloomEffect"); bloomFx.Intensity = bloomS.i; bloomFx.Size = bloomS.s; bloomFx.Threshold = bloomS.t end
            bloomFx.Parent = game:GetService("Lighting")
        elseif bloomFx then bloomFx:Destroy(); bloomFx = nil end
    end)
end)
shadersTab:slider("Intensity", 0, 5, 1, "x", function(v) bloomS.i = v; if bloomFx then pcall(function() bloomFx.Intensity = v end) end end)
shadersTab:slider("Size", 0, 100, 24, "", function(v) bloomS.s = v; if bloomFx then pcall(function() bloomFx.Size = v end) end end)
shadersTab:slider("Threshold", 0, 2, 0.5, "", function(v) bloomS.t = v; if bloomFx then pcall(function() bloomFx.Threshold = v end) end end)

shadersTab:divider()
shadersTab:label("Color Grading")
shadersTab:toggle("Color Grading", false, function(v)
    pcall(function()
        if v then
            if not ccFx then ccFx = Instance.new("ColorCorrectionEffect"); ccFx.Saturation = ccS.sat; ccFx.Contrast = ccS.con; ccFx.Brightness = ccS.bri; ccFx.TintColor = ccS.tint end
            ccFx.Parent = game:GetService("Lighting")
        elseif ccFx then ccFx:Destroy(); ccFx = nil end
    end)
end)
shadersTab:slider("Saturation", -1, 1, 0.2, "", function(v) ccS.sat = v; if ccFx then pcall(function() ccFx.Saturation = v end) end end)
shadersTab:slider("Contrast", -1, 1, 0.1, "", function(v) ccS.con = v; if ccFx then pcall(function() ccFx.Contrast = v end) end end)
shadersTab:slider("Brightness", -1, 1, 0, "", function(v) ccS.bri = v; if ccFx then pcall(function() ccFx.Brightness = v end) end end)
shadersTab:colorpicker("Tint", Color3.new(1, 1, 1), false, function(v) ccS.tint = v; if ccFx then pcall(function() ccFx.TintColor = v end) end end)

shadersTab:divider()
shadersTab:label("Vignette")
shadersTab:toggle("Vignette", false, function(v)
    pcall(function()
        if v then
            if not vigGui then
                vigGui = Instance.new("ScreenGui"); vigGui.Name = "Vignette"; vigGui.ResetOnSpawn = false; vigGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; vigGui.IgnoreGuiInset = true
                vigImg = Instance.new("ImageLabel"); vigImg.Size = UDim2.new(1, 0, 1, 0); vigImg.BackgroundTransparency = 1; vigImg.Image = "rbxassetid://4316120033"; vigImg.ImageColor3 = Color3.new(0, 0, 0); vigImg.ImageTransparency = 0.5; vigImg.Parent = vigGui
            end
            pcall(function() vigGui.Parent = LP:WaitForChild("PlayerGui", 5) end)
            if not vigGui.Parent then pcall(function() vigGui.Parent = CoreGui end) end
        elseif vigGui then vigGui:Destroy(); vigGui = nil; vigImg = nil end
    end)
end)
shadersTab:slider("Darkness", 0, 1, 0.5, "", function(v) if vigImg then pcall(function() vigImg.ImageTransparency = 1 - v end) end end)

shadersTab:divider()
shadersTab:label("Glossy OP1")
shadersTab:toggle("Glossy OP1", false, function(v)
    pcall(function()
        local l = game:GetService("Lighting")
        if v then
            l.Brightness = 2.5; l.OutdoorAmbient = Color3.new(1, 1, 1); l.Ambient = Color3.new(1, 1, 1); l.GlobalShadows = false; l.FogEnd = 1e5
            for _, p in pairs(workspace:GetDescendants()) do if p:IsA("BasePart") and not p:IsA("Terrain") then p.Material = Enum.Material.ForceField end end
        else
            l.Brightness = 1; l.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5); l.Ambient = Color3.new(); l.GlobalShadows = true; l.FogEnd = 1e5
            for _, p in pairs(workspace:GetDescendants()) do if p:IsA("BasePart") and not p:IsA("Terrain") then p.Material = Enum.Material.SmoothPlastic end end
        end
    end)
end)
shadersTab:slider("FOV", 60, 120, 90, " deg", function(v) pcall(function() workspace.CurrentCamera.FieldOfView = v end) end)

-- Auto-enable bypass
task.wait(0.5)
enableBypass()
w:notify("OP1 King", "loaded. Bypass auto-enabled.", 4)
