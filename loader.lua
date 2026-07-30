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
local VisualTab = Window:AddTab("Visual")
local ShadersTab = Window:AddTab("Shaders")
local ConfigTab = Window:AddTab("Config")
local SettingsTab = Window:AddTab("Settings")

-- Anti-Cheat Bypass

local BypassGroup = BypassTab:AddLeftGroupbox("Anti-Cheat Bypass")

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

-- No Spread (hooks Gun.send_shoot to zero spread state)

local SpreadGroup = CombatTab:AddLeftGroupbox("No Spread")

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

local BulletTPGroup = CombatTab:AddRightGroupbox("Bullet TP")

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

BulletTPGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if bulletTPHooked then disableBulletTP() else enableBulletTP() end
    end,
})

-- Silent Aim (hooks ray_damage on Gun to redirect hitscan while keeping visual normal)

local SilentAimGroup = CombatTab:AddRightGroupbox("Silent Aim")

local gunModuleSa = nil
local silentAimHooked = false
local silentAimOrig = nil
local silentAimFov = 60

local function isInFov(targetPos)
    local cam = workspace.CurrentCamera
    if not cam then return true end
    local camPos = cam.CFrame.Position
    local lookVec = cam.CFrame.LookVector
    local toTarget = (targetPos - camPos).Unit
    local dot = lookVec:Dot(toTarget)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= silentAimFov
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
    if not mod then
        Library:Notify("Silent Aim: failed to load Gun module", 3)
        return
    end
    local s, item = pcall(require, ReplicatedStorage.Modules.Items.Item)
    if not s or not item.ray_damage then
        Library:Notify("Silent Aim: failed to load Item module", 3)
        return
    end
    silentAimOrig = item.ray_damage
    mod.ray_damage = function(p1, origin, direction, filter, ...)
        if silentAimHooked then
            local nearest = findNearestEnemy()
            if nearest then
                local head = nearest:FindFirstChild("Head") or nearest:FindFirstChildOfClass("BasePart")
                if head and isInFov(head.Position) then
                    direction = (head.Position - origin)
                end
            end
        end
        return silentAimOrig(p1, origin, direction, filter, ...)
    end
    silentAimHooked = true
    Library:Notify("Silent Aim enabled", 2)
end

local function disableSilentAim()
    if not silentAimHooked then return end
    local mod = getGunModuleSA()
    if mod then mod.ray_damage = nil end
    silentAimHooked = false
    Library:Notify("Silent Aim disabled", 2)
end

SilentAimGroup:AddToggle("SilentAimToggle", {
    Text = "Silent Aim",
    Default = false,
    Tooltip = "Hooks Gun.ray_damage to redirect hitscan to nearest enemy while keeping visual aim normal",
    Callback = function(v)
        if v then enableSilentAim() else disableSilentAim() end
    end,
})

SilentAimGroup:AddDivider()

SilentAimGroup:AddSlider("SilentAimFov", {
    Text = "FOV Radius",
    Default = 60,
    Min = 5,
    Max = 500,
    Rounding = 1,
    Suffix = " deg",
    Tooltip = "Maximum angle from camera look direction to redirect hitscan",
    Callback = function(v)
        silentAimFov = v
    end,
})

SilentAimGroup:AddDivider()

SilentAimGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if silentAimHooked then disableSilentAim() else enableSilentAim() end
    end,
})

-- Recoil Macro (hooks UIS:GetMouseDelta to inject counter-pull while shooting)

local RecoilGroup = CombatTab:AddRightGroupbox("Recoil Macro")

local recoilActive = false
local recoilPullV = 15
local recoilPullH = 0
local oldNamecall = nil
local UIS = game:GetService("UserInputService")

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
    Library:Notify("Recoil Macro enabled", 2)
end

local function macroDisable()
    recoilActive = false
    Library:Notify("Recoil Macro disabled", 2)
end
RecoilGroup:AddToggle("RecoilToggle", {
    Text = "Recoil Macro",
    Default = false,
    Tooltip = "Hooks UIS:GetMouseDelta to add counter-pull while mouse1 is held. 0 fly, no game internals.",
    Callback = function(v)
        if v then macroEnable() else macroDisable() end
    end,
})

RecoilGroup:AddDivider()

RecoilGroup:AddSlider("RecoilV", {
    Text = "Vertical Pull",
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Suffix = "px",
    Tooltip = "Pixels to pull down per frame while mouse1 held. Start at 15 and adjust.",
    Callback = function(v)
        recoilPullV = v
    end,
})

RecoilGroup:AddSlider("RecoilH", {
    Text = "Horizontal Pull",
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Suffix = "px",
    Tooltip = "Pixels to pull sideways per frame while mouse1 held. For side-drift.",
    Callback = function(v)
        recoilPullH = v
    end,
})

RecoilGroup:AddDivider()

RecoilGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if recoilActive then macroDisable() else macroEnable() end
    end,
})

RecoilGroup:AddDivider()

-- No Gun Movement (hooks Gun.running and neutralizes walking bob to prevent weapon movement)

local NoMoveGroup = VisualTab:AddLeftGroupbox("No Gun Movement")

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
        local ok, cm = pcall(require, game.ReplicatedStorage.Modules.Character)
        if not ok then return end
        local got, char = pcall(cm.get_char)
        if not got or not char or not char.values then return end
        local bob = char.values.bob_cframe
        if bob and type(bob) == "table" and bob.Value then
            bob.Value = CFrame.new()
        end
    end)
end

local function stopNmBobbing()
    if nmBobHb then
        nmBobHb:Disconnect()
        nmBobHb = nil
    end
end

local function enableNoMove()
    if noMoveHooked then return end
    local mod = getGunModuleNM()
    if not mod then
        Library:Notify("No Move: failed to load Gun module", 3)
        return
    end
    oldRunning = mod.running
    mod.running = function(p1, p2, p3)
        if noMoveHooked then
            return
        end
        return oldRunning(p1, p2, p3)
    end
    nmBobbing()
    noMoveHooked = true
    Library:Notify("No Gun Movement enabled", 2)
end

local function disableNoMove()
    if not noMoveHooked then return end
    local mod = getGunModuleNM()
    if mod and oldRunning then
        mod.running = oldRunning
    end
    oldRunning = nil
    stopNmBobbing()
    noMoveHooked = false
    Library:Notify("No Gun Movement disabled", 2)
end

NoMoveGroup:AddToggle("NoMoveToggle", {
    Text = "No Gun Movement",
    Default = false,
    Tooltip = "Hooks Gun.running to prevent weapon animation while moving",
    Callback = function(v)
        if v then enableNoMove() else disableNoMove() end
    end,
})

NoMoveGroup:AddDivider()

NoMoveGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if noMoveHooked then disableNoMove() else enableNoMove() end
    end,
})

-- Bullet Tracers (hooks Gun.trail to create highly visible beam tracers)

local TracerGroup = VisualTab:AddLeftGroupbox("Bullet Tracers")

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
    if not mod then
        Library:Notify("Tracers: failed to load Gun module", 3)
        return
    end
    oldTrail = mod.trail
    mod.trail = function(p1, startPos, endPos, p4)
        if tracerHooked and startPos and endPos then
            local beam = Instance.new("Beam")
            local a1 = Instance.new("Attachment")
            local a2 = Instance.new("Attachment")
            a1.Parent = workspace.Terrain
            a2.Parent = workspace.Terrain
            a1.Position = startPos
            a2.Position = endPos
            beam.Parent = workspace
            beam.Attachment0 = a1
            beam.Attachment1 = a2
            beam.Width0 = tracerWidth
            beam.Width1 = tracerWidth
            beam.Color = ColorSequence.new(tracerColor)
            beam.Transparency = NumberSequence.new(0)
            beam.FaceCamera = true
            game:GetService("Debris"):AddItem(beam, 0.15)
            game:GetService("Debris"):AddItem(a1, 0.15)
            game:GetService("Debris"):AddItem(a2, 0.15)
        end
        if oldTrail then
            return oldTrail(p1, startPos, endPos, p4)
        end
    end
    tracerHooked = true
    Library:Notify("Bullet Tracers enabled", 2)
end

local function disableTracers()
    if not tracerHooked then return end
    local mod = getGunModuleTR()
    if mod and oldTrail then
        mod.trail = oldTrail
    end
    oldTrail = nil
    tracerHooked = false
    Library:Notify("Bullet Tracers disabled", 2)
end

TracerGroup:AddToggle("TracerToggle", {
    Text = "Bullet Tracers",
    Default = false,
    Tooltip = "Hooks Gun.trail to create visible beam tracers on each shot",
    Callback = function(v)
        if v then enableTracers() else disableTracers() end
    end,
})

TracerGroup:AddDivider()

TracerGroup:AddSlider("TracerWidth", {
    Text = "Width",
    Default = 0.5,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Suffix = " studs",
    Tooltip = "Width of the tracer beam",
    Callback = function(v)
        tracerWidth = v
    end,
})

TracerGroup:AddDivider()

TracerGroup:AddColorPicker("TracerColor", {
    Text = "Tracer Color",
    Default = Color3.fromRGB(255, 200, 50),
    Tooltip = "Color of the tracer beam",
    Callback = function(color)
        tracerColor = color
    end,
})

TracerGroup:AddDivider()

TracerGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if tracerHooked then disableTracers() else enableTracers() end
    end,
})

-- No Screen Shake (stops all screenshaking — recoil, WindShake, bobbing)

local NoShakeGroup = VisualTab:AddLeftGroupbox("No Screen Shake")

local noShakeHooked = false
local windShakePaused = false
local bobHb = nil
local nsRecoilThread = nil
local nsCharMod = nil

local function getItemsModule()
    local s, m = pcall(require, ReplicatedStorage.Modules.Items)
    return s and m
end

local function getWindShake()
    local s, m = pcall(require, ReplicatedStorage.Modules.WindShake)
    return s and m
end

local function pauseWindShake()
    local ws = getWindShake()
    if ws and not windShakePaused then
        pcall(ws.Pause, ws)
        windShakePaused = true
    end
end

local function resumeWindShake()
    local ws = getWindShake()
    if ws and windShakePaused then
        pcall(ws.Resume, ws)
        windShakePaused = false
    end
end

local function noopBobbing()
    if bobHb then return end
    bobHb = game:GetService("RunService").Heartbeat:Connect(function()
        local ok, char = pcall(nsCharMod.get_char)
        if not ok or not char or not char.values then return end
        local bob = char.values.bob_cframe
        if bob and type(bob) == "table" and bob.Value then
            bob.Value = CFrame.new()
        end
    end)
end

local function stopBobbing()
    if bobHb then
        bobHb:Disconnect()
        bobHb = nil
    end
end

local function enableNoShake()
    if noShakeHooked then return end
    noShakeHooked = true
    getgenv()._op1_ns_recoil = true
    local ok, cm = pcall(require, game.ReplicatedStorage.Modules.Character)
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
    pauseWindShake()
    noopBobbing()
    Library:Notify("No Screen Shake enabled", 2)
end

local function disableNoShake()
    if not noShakeHooked then return end
    noShakeHooked = false
    getgenv()._op1_ns_recoil = false
    if nsRecoilThread then task.cancel(nsRecoilThread); nsRecoilThread = nil end
    resumeWindShake()
    stopBobbing()
    Library:Notify("No Screen Shake disabled", 2)
end

NoShakeGroup:AddToggle("NoShakeToggle", {
    Text = "No Screen Shake",
    Default = false,
    Tooltip = "Neutralizes recoil camera shake, pauses WindShake (explosions / world shake), and stops head bobbing",
    Callback = function(v)
        if v then enableNoShake() else disableNoShake() end
    end,
})

NoShakeGroup:AddDivider()

NoShakeGroup:AddButton({
    Text = "Toggle",
    Func = function()
        if noShakeHooked then disableNoShake() else enableNoShake() end
    end,
})


-- Shaders tab

local bloomFx = nil
local bloomSettings = { intensity = 1, size = 24, threshold = 0.5 }

local SfxGroup = ShadersTab:AddLeftGroupbox("Bloom")

SfxGroup:AddToggle("BloomToggle", {
    Text = "Bloom",
    Default = false,
    Tooltip = "Bright surfaces bleed light into surrounding pixels",
    Callback = function(v)
        pcall(function()
            if v then
                if not bloomFx then
                    bloomFx = Instance.new("BloomEffect")
                    bloomFx.Intensity = bloomSettings.intensity
                    bloomFx.Size = bloomSettings.size
                    bloomFx.Threshold = bloomSettings.threshold
                end
                bloomFx.Parent = game:GetService("Lighting")
            else
                if bloomFx then bloomFx:Destroy(); bloomFx = nil end
            end
        end)
    end,
})

SfxGroup:AddDivider()

SfxGroup:AddSlider("BloomIntensity", {
    Text = "Intensity",
    Default = 1, Min = 0, Max = 5, Rounding = 2, Suffix = "x",
    Callback = function(v)
        bloomSettings.intensity = v
        if bloomFx then pcall(function() bloomFx.Intensity = v end) end
    end,
})

SfxGroup:AddSlider("BloomSize", {
    Text = "Size",
    Default = 24, Min = 0, Max = 100, Rounding = 1, Suffix = "",
    Callback = function(v)
        bloomSettings.size = v
        if bloomFx then pcall(function() bloomFx.Size = v end) end
    end,
})

SfxGroup:AddSlider("BloomThreshold", {
    Text = "Threshold",
    Default = 0.5, Min = 0, Max = 2, Rounding = 2, Suffix = "",
    Callback = function(v)
        bloomSettings.threshold = v
        if bloomFx then pcall(function() bloomFx.Threshold = v end) end
    end,
})

-- Color Grading
local ccFx = nil
local ccSettings = { saturation = 0.2, contrast = 0.1, brightness = 0, tint = Color3.new(1, 1, 1) }

local CgGroup = ShadersTab:AddLeftGroupbox("Color Grading")

CgGroup:AddToggle("ColorToggle", {
    Text = "Color Grading",
    Default = false,
    Tooltip = "Adjust saturation, contrast, brightness, and tint",
    Callback = function(v)
        pcall(function()
            if v then
                if not ccFx then
                    ccFx = Instance.new("ColorCorrectionEffect")
                    ccFx.Saturation = ccSettings.saturation
                    ccFx.Contrast = ccSettings.contrast
                    ccFx.Brightness = ccSettings.brightness
                    ccFx.TintColor = ccSettings.tint
                end
                ccFx.Parent = game:GetService("Lighting")
            else
                if ccFx then ccFx:Destroy(); ccFx = nil end
            end
        end)
    end,
})

CgGroup:AddDivider()

CgGroup:AddSlider("ColorSaturation", {
    Text = "Saturation",
    Default = 0.2, Min = -1, Max = 1, Rounding = 2, Suffix = "",
    Tooltip = "-1 = grayscale, 0 = normal, 1 = oversaturated",
    Callback = function(v)
        ccSettings.saturation = v
        if ccFx then pcall(function() ccFx.Saturation = v end) end
    end,
})

CgGroup:AddSlider("ColorContrast", {
    Text = "Contrast",
    Default = 0.1, Min = -1, Max = 1, Rounding = 2, Suffix = "",
    Callback = function(v)
        ccSettings.contrast = v
        if ccFx then pcall(function() ccFx.Contrast = v end) end
    end,
})

CgGroup:AddSlider("ColorBrightness", {
    Text = "Brightness",
    Default = 0, Min = -1, Max = 1, Rounding = 2, Suffix = "",
    Callback = function(v)
        ccSettings.brightness = v
        if ccFx then pcall(function() ccFx.Brightness = v end) end
    end,
})

CgGroup:AddDivider()

CgGroup:AddColorPicker("ColorTint", {
    Title = "Tint Color",
    Default = Color3.new(1, 1, 1),
    Tooltip = "Color tint applied to the scene",
    Callback = function(v)
        ccSettings.tint = v
        if ccFx then pcall(function() ccFx.TintColor = v end) end
    end,
})

-- Right column: Vignette, Glossy, FOV

local VigGroup = ShadersTab:AddRightGroupbox("Vignette")

local vigGui = nil
local vigImg = nil

VigGroup:AddToggle("VignetteToggle", {
    Text = "Vignette",
    Default = false,
    Tooltip = "Darkens screen corners for cinematic look",
    Callback = function(v)
        pcall(function()
            if v then
                if not vigGui then
                    vigGui = Instance.new("ScreenGui")
                    vigGui.Name = "VignetteOverlay"
                    vigGui.ResetOnSpawn = false
                    vigGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                    vigGui.IgnoreGuiInset = true
                    vigImg = Instance.new("ImageLabel")
                    vigImg.Size = UDim2.new(1, 0, 1, 0)
                    vigImg.BackgroundTransparency = 1
                    vigImg.Image = "rbxassetid://4316120033"
                    vigImg.ImageColor3 = Color3.new(0, 0, 0)
                    vigImg.ImageTransparency = 0.5
                    vigImg.Parent = vigGui
                end
                pcall(function() vigGui.Parent = LP:WaitForChild("PlayerGui", 5) end)
                if not vigGui.Parent then
                    pcall(function() vigGui.Parent = CoreGui end)
                end
            else
                if vigGui then vigGui:Destroy(); vigGui = nil; vigImg = nil end
            end
        end)
    end,
})

VigGroup:AddDivider()

VigGroup:AddSlider("VignetteIntensity", {
    Text = "Darkness",
    Default = 0.5, Min = 0, Max = 1, Rounding = 2, Suffix = "",
    Tooltip = "How dark the vignette edges are",
    Callback = function(v)
        if vigImg then pcall(function() vigImg.ImageTransparency = 1 - v end) end
    end,
})

-- Glossy
local GlossyGroup = ShadersTab:AddRightGroupbox("Glossy OP1")

GlossyGroup:AddToggle("GlossyToggle", {
    Text = "Glossy OP1",
    Default = false,
    Tooltip = "ForceField material + max brightness",
    Callback = function(v)
        pcall(function()
            local lighting = game:GetService("Lighting")
            if v then
                lighting.Brightness = 2.5
                lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                lighting.Ambient = Color3.new(1, 1, 1)
                lighting.GlobalShadows = false
                lighting.FogEnd = 1e5
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and not p:IsA("Terrain") then
                        p.Material = Enum.Material.ForceField
                    end
                end
            else
                lighting.Brightness = 1
                lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
                lighting.Ambient = Color3.new()
                lighting.GlobalShadows = true
                lighting.FogEnd = 1e5
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and not p:IsA("Terrain") then
                        p.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
        end)
    end,
})

GlossyGroup:AddDivider()

GlossyGroup:AddSlider("FOVSlider", {
    Text = "FOV",
    Default = 90, Min = 60, Max = 120, Rounding = 1, Suffix = " deg",
    Tooltip = "Camera field of view",
    Callback = function(v)
        pcall(function() workspace.CurrentCamera.FieldOfView = v end)
    end,
})

Library:SetWatermark("OP1 King")

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetIgnoreIndexes({})
SaveManager:SetFolder("OP1King/configs")
ThemeManager:SetFolder("OP1King")

SaveManager:BuildConfigSection(ConfigTab)

local ConfigInfo = ConfigTab:AddLeftGroupbox("Config Info")
ConfigInfo:AddButton({
    Text = "Refresh Config List",
    Func = function()
        Options.SaveManager_ConfigList:SetValues(SaveManager:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
        Library:Notify("Config list refreshed", 2)
    end,
})

ThemeManager:ApplyToTab(SettingsTab)

Window:SelectTab(1)

Library:Notify("OP1 King loaded. Bypass auto-enabled.", 4)

enableBypass()
