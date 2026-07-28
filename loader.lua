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
local VisualsTab = Window:AddTab("Visuals")
local CombatTab = Window:AddTab("Combat")
local SettingsTab = Window:AddTab("Settings")

-- Anti-Cheat Bypass

local BypassGroup = BypassTab:AddLeftGroupbox("Anti-Cheat Bypass")
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

-- ESP

local ESPGroup = VisualsTab:AddLeftGroupbox("ESP")
local ESPInfo = VisualsTab:AddRightGroupbox("Info")
local VisualSettings = VisualsTab:AddLeftGroupbox("Settings")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espEnabled = false
local espConn = nil
local espObjects = {}

local function getPlayerHead(player)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then return head end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            return part
        end
    end
end

local function createESP(part, player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 50, 50)
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1

    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Color = Color3.fromRGB(255, 255, 255)
    nameLabel.Size = 14
    nameLabel.Center = true
    nameLabel.Outline = true

    local healthLabel = Drawing.new("Text")
    healthLabel.Visible = false
    healthLabel.Color = Color3.fromRGB(100, 255, 100)
    healthLabel.Size = 12
    healthLabel.Center = true
    healthLabel.Outline = true

    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Color = Color3.fromRGB(200, 200, 200)
    distLabel.Size = 11
    distLabel.Center = true
    distLabel.Outline = true

    espObjects[player] = {
        box = box,
        name = nameLabel,
        health = healthLabel,
        dist = distLabel,
    }
end

local function removeESP(player)
    local objs = espObjects[player]
    if objs then
        objs.box:Remove()
        objs.name:Remove()
        objs.health:Remove()
        objs.dist:Remove()
        espObjects[player] = nil
    end
end

local function wts(pos)
    local vec = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), vec.Z
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local head = getPlayerHead(player)
            if head then createESP(head, player) end
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled then
                local head = getPlayerHead(player)
                if head then createESP(head, player) end
            end
        end)
    end)

    espConn = RunService.RenderStepped:Connect(function()
        if not espEnabled then return end

        for player, objs in pairs(espObjects) do
            if not Toggles.ESPToggle or not Toggles.ESPToggle.Value then break end

            local char = player.Character
            if not char then
                removeESP(player)
                continue
            end

            local head = getPlayerHead(player)
            if not head then
                objs.box.Visible = false
                objs.name.Visible = false
                objs.health.Visible = false
                objs.dist.Visible = false
                continue
            end

            local pos, depth = wts(head.Position)
            if depth < 0 then
                objs.box.Visible = false
                objs.name.Visible = false
                objs.health.Visible = false
                objs.dist.Visible = false
                continue
            end

            local scale = Camera:GetScale()
            local boxSize = Vector2.new(50 * scale.X, 80 * scale.X)
            local boxPos = pos - boxSize / 2

            objs.box.Size = boxSize
            objs.box.Position = boxPos
            objs.box.Visible = true

            objs.name.Text = player.Name
            objs.name.Position = Vector2.new(pos.X, boxPos.Y - 18)
            objs.name.Visible = true

            objs.health.Text = math.floor(player:WaitForChild("leaderstats", 0.1) and player.leaderstats:FindFirstChild("Health") and player.leaderstats.Health.Value or 100)
            objs.health.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 2)
            objs.health.Visible = true

            local dist = (LocalPlayer.Character and LocalPlayer.Character:GetPivot().p or Vector3.new()) - head.Position
            objs.dist.Text = tostring(math.floor(dist.Magnitude)) .. " studs"
            objs.dist.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 16)
            objs.dist.Visible = true
        end
    end)
end

local function disableESP()
    espEnabled = false
    if espConn then espConn:Disconnect(); espConn = nil end
    for player in pairs(espObjects) do
        removeESP(player)
    end
end

ESPGroup:AddToggle("ESPToggle", {
    Text = "ESP",
    Default = false,
    Tooltip = "Draw boxes, names, health and distance on enemies",
    Callback = function(v)
        if v then enableESP() else disableESP() end
    end,
})

ESPGroup:AddDivider()

ESPGroup:AddButton({
    Text = "Refresh ESP",
    Tooltip = "Rebuild all ESP objects",
    Func = function()
        for player in pairs(espObjects) do removeESP(player) end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local head = getPlayerHead(player)
                if head then createESP(head, player) end
            end
        end
        Library:Notify("ESP refreshed", 2)
    end,
})

ESPInfo:AddLabel("Works with any character type. Finds the Head or any BasePart.", true)
ESPInfo:AddDivider()
ESPInfo:AddLabel("Shows name, health (from leaderstats if available), and distance.", true)

-- Aimbot

local AimbotGroup = CombatTab:AddLeftGroupbox("Aimbot")
local TriggerGroup = CombatTab:AddLeftGroupbox("Triggerbot")
local AimbotInfo = CombatTab:AddRightGroupbox("Info")

local aimConn = nil
local aimActive = false

local function getClosestPlayer(fov)
    local closest, closestDist = nil, fov
    local mPos = Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local head = getPlayerHead(player)
        if not head then continue end

        local scrPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local dist = (mPos - Vector2.new(scrPos.X, scrPos.Y)).Magnitude
        if dist < closestDist then
            closest = player
            closestDist = dist
        end
    end

    return closest
end

local function isPlayerOnScreen(player)
    local head = getPlayerHead(player)
    if not head then return false end
    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
    return onScreen and pos.Z > 0
end

local function enableAimbot()
    if aimActive then return end
    aimActive = true

    aimConn = RunService.RenderStepped:Connect(function()
        if not aimActive then return end
        if not Toggles.AimbotToggle or not Toggles.AimbotToggle.Value then return end

        local target = getClosestPlayer(Options.AimbotFOV and Options.AimbotFOV.Value or 200)
        if not target then return end

        local head = getPlayerHead(target)
        if not head then return end

        local char = LocalPlayer.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChildOfClass("BasePart")
        if not hrp then return end

        local lookVec = (head.Position - hrp.Position).Unit
        local newCF = CFrame.lookAt(hrp.Position, hrp.Position + lookVec)

        local smoothing = Options.AimbotSmooth and Options.AimbotSmooth.Value or 0
        if smoothing > 0 then
            local current = hrp.CFrame
            local alpha = 1 / (smoothing * 60)
            newCF = current:Lerp(newCF, alpha)
        end

        hrp.CFrame = newCF
    end)
end

local function disableAimbot()
    aimActive = false
    if aimConn then aimConn:Disconnect(); aimConn = nil end
end

AimbotGroup:AddToggle("AimbotToggle", {
    Text = "Aimbot",
    Default = false,
    Tooltip = "Snap character toward nearest enemy within FOV",
    Callback = function(v)
        if v then enableAimbot() else disableAimbot() end
    end,
})

AimbotGroup:AddSlider("AimbotFOV", {
    Text = "FOV",
    Default = 200,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Suffix = "px",
    Tooltip = "Maximum distance from crosshair to target",
})

AimbotGroup:AddSlider("AimbotSmooth", {
    Text = "Smoothing",
    Default = 5,
    Min = 0,
    Max = 20,
    Rounding = 1,
    Tooltip = "Higher = smoother but slower aim",
})

-- Triggerbot

local triggerConn = nil
local triggerActive = false

local function enableTriggerbot()
    if triggerActive then return end
    triggerActive = true

    triggerConn = RunService.RenderStepped:Connect(function()
        if not triggerActive then return end
        if not Toggles.TriggerToggle or not Toggles.TriggerToggle.Value then return end

        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        if not target then return end

        local char = target:FindFirstAncestorOfClass("Model")
        if not char then return end

        local player = Players:GetPlayerFromCharacter(char)
        if not player or player == LocalPlayer then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then return end

        mouse1click()
        if Options.TriggerDelay then
            task.wait(Options.TriggerDelay.Value / 1000)
        end
    end)
end

local function disableTriggerbot()
    triggerActive = false
    if triggerConn then triggerConn:Disconnect(); triggerConn = nil end
end

TriggerGroup:AddToggle("TriggerToggle", {
    Text = "Triggerbot",
    Default = false,
    Tooltip = "Auto-fire when crosshair is over an enemy",
    Callback = function(v)
        if v then enableTriggerbot() else disableTriggerbot() end
    end,
})

TriggerGroup:AddSlider("TriggerDelay", {
    Text = "Delay",
    Default = 0,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Suffix = "ms",
    Tooltip = "Delay before firing",
})

AimbotInfo:AddLabel("Aimbot rotates your character toward the nearest enemy within the FOV.", true)
AimbotInfo:AddDivider()
AimbotInfo:AddLabel("Triggerbot fires when your mouse is hovering over an enemy model.", true)

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
