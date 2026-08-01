local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GS = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Cam = workspace.CurrentCamera

local currentMode = "Console"
local spoofing = true

local deviceTypes = {
    Mobile = Enum.DeviceType.Tablet,
    Console = Enum.DeviceType.Desktop,
    PC = Enum.DeviceType.Desktop,
}

local function getLastInputType(mode)
    if mode == "Mobile" then return Enum.UserInputType.Touch
    elseif mode == "Console" then return Enum.UserInputType.Gamepad1
    else return Enum.UserInputType.MouseMovement end
end

local function getPlatformString(mode)
    if mode == "Mobile" then return "Mobile"
    elseif mode == "Console" then return "Console"
    else return "Windows" end
end

local lockFeature = false
local lockActive = false
local lockTarget = nil
local hitboxMethodLog = ""
local hitboxEnabled = false
local hitboxSize = 2
local hitboxRange = 1
local origHitboxSizes = {}
local function deepDump(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(v)
    if t == "Instance" then
        return v.Name .. "(" .. v.ClassName .. ")"
    elseif t == "Vector3" then
        return "V3(" .. math.floor(v.X) .. "," .. math.floor(v.Y) .. "," .. math.floor(v.Z) .. ")"
    elseif t == "CFrame" then
        return "CF(" .. math.floor(v.Position.X) .. "," .. math.floor(v.Position.Y) .. "," .. math.floor(v.Position.Z) .. ")"
    elseif t == "EnumItem" then
        return tostring(v)
    elseif t == "number" then
        return tostring(math.floor(v * 100) / 100)
    elseif t == "string" then
        return '"' .. v:sub(1, 40) .. '"'
    elseif t == "table" then
        local parts = {}
        local count = 0
        for k2, v2 in pairs(v) do
            count = count + 1
            if count > 8 then table.insert(parts, "...(" .. tostring(count) .. " more)"); break end
            table.insert(parts, tostring(k2) .. "=" .. deepDump(v2, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    else
        return t .. "(" .. tostring(v):sub(1, 20) .. ")"
    end
end

local captureMode = false
local captureResults = {}
local captureLabel = nil
local remoteCapture = false
local remoteResults = {}
local remoteLabel = nil

local function applyHitbox()
    local lp = Players.LocalPlayer
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            for _, part in ipairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local nm = part.Name
                    if nm:sub(1, 6) == "Hitbox" or nm == "FakeHead" then
                        if not origHitboxSizes[part] then
                            origHitboxSizes[part] = part.Size
                        end
                        part.Size = origHitboxSizes[part] * hitboxSize
                    end
                    if plr == lp and (nm == "Right Arm" or nm == "Left Arm" or nm == "Right Leg" or nm == "Left Leg") then
                        if not origHitboxSizes[part] then
                            origHitboxSizes[part] = part.Size
                        end
                        part.Size = origHitboxSizes[part] * hitboxSize
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if hitboxEnabled then
            applyHitbox()
        end
        task.wait(0.03)
    end
end)

local function restoreHitbox()
    for part, orig in pairs(origHitboxSizes) do
        pcall(function() part.Size = orig end)
    end
    origHitboxSizes = {}
end

local function findTarget()
    local closest, closestDist = nil, math.huge
    local pos = Players.LocalPlayer.Character and Players.LocalPlayer.Character:GetPivot().Position
    if not pos then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local tPos = plr.Character.HumanoidRootPart.Position
            local dist = (tPos - pos).Magnitude
            if dist < closestDist then
                closest, closestDist = plr, dist
            end
        end
    end
    return closest
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall

setreadonly(mt, false)

mt.__index = function(t, k)
    if spoofing and t == UIS then
        if k == "TouchEnabled" then return currentMode == "Mobile" end
        if k == "GamepadEnabled" then return currentMode == "Console" end
        if k == "AccelerometerEnabled" then return currentMode == "Mobile" end
        if k == "VREnabled" then return false end
    end
    return oldIndex(t, k)
end

mt.__namecall = function(self, ...)
    if spoofing and (self == UIS or self == GS) then
        local method = getnamecallmethod()
        if self == UIS then
            if method == "GetDeviceType" then return deviceTypes[currentMode] end
            if method == "GetDeviceEnum" then return deviceTypes[currentMode] end
            if method == "GetLastInputType" then return getLastInputType(currentMode) end
            if method == "GetPlatform" then return getPlatformString(currentMode) end
        end
        if method == "IsTouchEnabled" then return currentMode == "Mobile" end
    end
    local method = getnamecallmethod()
    local ml = method:lower()
    if hitboxEnabled and hitboxRange > 1 then
        if ml == "raycast" and self == workspace then
            local origin, direction = select(1, ...), select(2, ...)
            local newDir = direction * hitboxRange
            if select("#", ...) >= 3 then
                local params = select(3, ...)
                return oldNamecall(self, origin, newDir, params)
            else
                return oldNamecall(self, origin, newDir)
            end
        end
        if (ml == "findpartonray" or ml == "findpartonraywithignorelist") and self == workspace then
            local ray, ignoreList = select(1, ...), select(2, ...)
            local newRay = Ray.new(ray.Origin, ray.Direction * hitboxRange)
            if select("#", ...) >= 3 then
                local terrainCasts = select(3, ...)
                return oldNamecall(self, newRay, ignoreList, terrainCasts)
            else
                return oldNamecall(self, newRay, ignoreList)
            end
        end
    end
    if ml == "raycast" or ml == "findpartonray" or ml == "findpartonraywithignorelist" or ml == "getpartsinpart" or ml == "getpartboundsinradius" or ml == "findpartsinregion3" or ml == "findpartsinregion3withwhitelist" or ml == "getpartboundsinbox" then
        hitboxMethodLog = method
    end
    if captureMode then
        local key = self.ClassName .. ":" .. method
        if not captureResults[key] then captureResults[key] = 0 end
        captureResults[key] = captureResults[key] + 1
    end
    if remoteCapture and (ml == "fireserver" or ml == "invokeserver") then
        local name = self.Name
        local className = self.ClassName
        local fullArgs = {}
        for i = 1, select("#", ...) do
            fullArgs[i] = select(i, ...)
        end
        local args = {}
        for i, v in ipairs(fullArgs) do
            args[i] = deepDump(v)
        end
        local key = className .. "." .. name
        if not remoteResults[key] then remoteResults[key] = { count = 0, sample = "" } end
        remoteResults[key].count = remoteResults[key].count + 1
        if remoteResults[key].count <= 5 then
            remoteResults[key].sample = table.concat(args, ", ")
        end
        if remoteResults[key].count <= 3 then
            warn("[REMOTE] " .. key .. " #" .. remoteResults[key].count .. " [" .. table.concat(args, " | "):sub(1, 500) .. "]")
        end
    end
    if hitboxEnabled and ml == "fireserver" then
        local ok, t = pcall(select, 1, ...)
        if ok and type(t) == "table" and t.cframe and t.seq then
            local myChar = Players.LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myPos = myChar.HumanoidRootPart.Position
                local closest, closestDist = nil, 999
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                        if d < closestDist then closest, closestDist = plr, d end
                    end
                end
                if closest and closestDist <= 120 then
                    local dir = (closest.Character.HumanoidRootPart.Position - myPos).Unit
                    local offset = math.min(hitboxRange * 4, closestDist - 4)
                    local fakePos = myPos + dir * offset
                    t.cframe = CFrame.new(fakePos) * (t.cframe - t.cframe.Position)
                end
            end
        end
    end
    local ok, res = pcall(oldNamecall, self, ...)
    if ok then return res end
end

setreadonly(mt, true)

-- Hook getrawmetatable so TSB can't save originals to bypass us
pcall(function()
    local oldGetRawMT = getrawmetatable
    hookfunction(getrawmetatable, function(obj)
        if obj == game then return mt end
        return oldGetRawMT(obj)
    end)
    print("[TSB] hookfunction(getrawmetatable) OK")
end)

print("[TSB] Hooks installed")
print("[TSB] UIS:GetDeviceType() =", UIS:GetDeviceType())

-- UI
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

for _, v in ipairs(PlayerGui:GetChildren()) do
    if v.Name == "TSBSpoofer" then v:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "TSBSpoofer"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 360, 0, 380)
main.Position = UDim2.new(0.5, -180, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(50, 50, 50)
uiStroke.Thickness = 1
uiStroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1, 0, 0, 10)
titleCover.Position = UDim2.new(0, 0, 1, -10)
titleCover.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleCover.BorderSizePixel = 0
titleCover.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "TSB Device Spoofer"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -16, 1, -46)
body.Position = UDim2.new(0, 8, 0, 40)
body.BackgroundTransparency = 1
body.Parent = main

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 2)
padding.Parent = body

local function createRow(name, order)
    local row = Instance.new("Frame")
    row.Name = name
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = body
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    return row
end

local function createLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- Status row
local statusRow = createRow("Status", 3)
local statusLabel = createLabel(statusRow, "Status: Spoofing " .. currentMode)
statusLabel.TextColor3 = Color3.fromRGB(0, 200, 150)
statusLabel.TextSize = 11

-- Toggle row
local toggleRow = createRow("Toggle", 1)
createLabel(toggleRow, "Enable Spoofing")

local toggleTrack = Instance.new("TextButton")
toggleTrack.Size = UDim2.new(0, 38, 0, 20)
toggleTrack.Position = UDim2.new(1, -48, 0.5, -10)
toggleTrack.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
toggleTrack.BorderSizePixel = 0
toggleTrack.Text = ""
toggleTrack.Parent = toggleRow
Instance.new("UICorner", toggleTrack).CornerRadius = UDim.new(1, 0)

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.new(0, 16, 0, 16)
toggleKnob.Position = UDim2.new(1, -18, 0.5, -8)
toggleKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
toggleKnob.BorderSizePixel = 0
toggleKnob.Parent = toggleTrack
Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)

local isToggled = true

toggleTrack.MouseButton1Click:Connect(function()
    isToggled = not isToggled
    spoofing = isToggled
    if isToggled then
        toggleTrack.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
        toggleKnob.Position = UDim2.new(1, -18, 0.5, -8)
        statusLabel.Text = "Status: Spoofing " .. currentMode
        statusLabel.TextColor3 = Color3.fromRGB(0, 200, 150)
    else
        toggleTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        toggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
        statusLabel.Text = "Status: Idle"
        statusLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    end
end)

-- Dropdown row
local dropRow = createRow("Dropdown", 2)
createLabel(dropRow, "Spoof Device")

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(0, 90, 0, 24)
dropBtn.Position = UDim2.new(1, -100, 0.5, -12)
dropBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
dropBtn.BorderSizePixel = 0
dropBtn.Text = "  Console"
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.Font = Enum.Font.GothamSemibold
dropBtn.TextSize = 12
dropBtn.TextXAlignment = Enum.TextXAlignment.Left
dropBtn.Parent = dropRow
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.new(0, 20, 1, 0)
arrow.Position = UDim2.new(1, -20, 0, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "v"
arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
arrow.Font = Enum.Font.GothamBold
arrow.TextSize = 12
arrow.Parent = dropBtn

local optionsList = Instance.new("Frame")
optionsList.Size = UDim2.new(0, 90, 0, 0)
optionsList.Position = UDim2.new(1, -100, 1, 4)
optionsList.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
optionsList.BorderSizePixel = 0
optionsList.Visible = false
optionsList.ZIndex = 10
optionsList.ClipsDescendants = true
optionsList.Parent = dropRow
Instance.new("UICorner", optionsList).CornerRadius = UDim.new(0, 4)
Instance.new("UIStroke", optionsList).Color = Color3.fromRGB(60, 60, 60)

local optLayout = Instance.new("UIListLayout")
optLayout.SortOrder = Enum.SortOrder.LayoutOrder
optLayout.Parent = optionsList

local options = {"Mobile", "Console", "PC"}
local dropOpen = false

for i, opt in ipairs(options) do
    local optBtn = Instance.new("TextButton")
    optBtn.Size = UDim2.new(1, 0, 0, 28)
    optBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    optBtn.BorderSizePixel = 0
    optBtn.Text = "  " .. opt
    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    optBtn.Font = Enum.Font.GothamSemibold
    optBtn.TextSize = 12
    optBtn.TextXAlignment = Enum.TextXAlignment.Left
    optBtn.ZIndex = 11
    optBtn.LayoutOrder = i
    optBtn.Parent = optionsList

    optBtn.MouseEnter:Connect(function()
        optBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    end)
    optBtn.MouseLeave:Connect(function()
        optBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end)
    optBtn.MouseButton1Click:Connect(function()
        currentMode = opt
        dropBtn.Text = "  " .. opt
        dropOpen = false
        optionsList.Visible = false
        optionsList.Size = UDim2.new(0, 90, 0, 0)
        if isToggled then
            statusLabel.Text = "Status: Spoofing " .. opt
        end
    end)
end

dropBtn.MouseButton1Click:Connect(function()
    dropOpen = not dropOpen
    optionsList.Visible = dropOpen
    if dropOpen then
        optionsList.Size = UDim2.new(0, 90, 0, #options * 28)
    else
        optionsList.Size = UDim2.new(0, 90, 0, 0)
    end
end)

-- Lock-on row
local lockRow = createRow("LockOn", 4)
createLabel(lockRow, "Lock-On [V]")

local lockTrack = Instance.new("TextButton")
lockTrack.Size = UDim2.new(0, 38, 0, 20)
lockTrack.Position = UDim2.new(1, -48, 0.5, -10)
lockTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
lockTrack.BorderSizePixel = 0
lockTrack.Text = ""
lockTrack.Parent = lockRow
Instance.new("UICorner", lockTrack).CornerRadius = UDim.new(1, 0)

local lockKnob = Instance.new("Frame")
lockKnob.Size = UDim2.new(0, 16, 0, 16)
lockKnob.Position = UDim2.new(0, 2, 0.5, -8)
lockKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
lockKnob.BorderSizePixel = 0
lockKnob.Parent = lockTrack
Instance.new("UICorner", lockKnob).CornerRadius = UDim.new(1, 0)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe or not lockFeature then return end
    if input.KeyCode == Enum.KeyCode.V then
        lockActive = not lockActive
        if lockActive then
            lockTarget = findTarget()
            if not lockTarget then
                lockActive = false
                warn("[TSB] No target found")
            end
        else
            lockTarget = nil
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if lockActive and lockTarget and lockTarget.Character then
        local hrp = lockTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            Cam.CFrame = CFrame.new(Cam.CFrame.Position, hrp.Position)
        else
            lockActive = false
            lockTarget = nil
        end
    elseif lockActive then
        lockActive = false
        lockTarget = nil
    end
end)

lockTrack.MouseButton1Click:Connect(function()
    lockFeature = not lockFeature
    if lockFeature then
        lockTrack.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
        lockKnob.Position = UDim2.new(1, -18, 0.5, -8)
        lockActive = true
        lockTarget = findTarget()
        if not lockTarget then
            lockFeature = false
            lockActive = false
            lockTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            lockKnob.Position = UDim2.new(0, 2, 0.5, -8)
            warn("[TSB] No target found")
        end
    else
        lockTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        lockKnob.Position = UDim2.new(0, 2, 0.5, -8)
        lockActive = false
        lockTarget = nil
    end
end)

-- Hitbox expander row
local hitboxRow = createRow("Hitbox", 5)
createLabel(hitboxRow, "Hitbox Expander")

local hitboxTrack = Instance.new("TextButton")
hitboxTrack.Size = UDim2.new(0, 38, 0, 20)
hitboxTrack.Position = UDim2.new(1, -48, 0.5, -10)
hitboxTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
hitboxTrack.BorderSizePixel = 0
hitboxTrack.Text = ""
hitboxTrack.Parent = hitboxRow
Instance.new("UICorner", hitboxTrack).CornerRadius = UDim.new(1, 0)

local hitboxKnob = Instance.new("Frame")
hitboxKnob.Size = UDim2.new(0, 16, 0, 16)
hitboxKnob.Position = UDim2.new(0, 2, 0.5, -8)
hitboxKnob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
hitboxKnob.BorderSizePixel = 0
hitboxKnob.Parent = hitboxTrack
Instance.new("UICorner", hitboxKnob).CornerRadius = UDim.new(1, 0)

local hitboxSizeBox = Instance.new("TextBox")
hitboxSizeBox.Size = UDim2.new(0, 45, 0, 22)
hitboxSizeBox.Position = UDim2.new(1, -100, 0.5, -11)
hitboxSizeBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
hitboxSizeBox.BorderSizePixel = 0
hitboxSizeBox.Text = "2"
hitboxSizeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxSizeBox.Font = Enum.Font.GothamSemibold
hitboxSizeBox.TextSize = 12
hitboxSizeBox.ClearTextOnFocus = false
hitboxSizeBox.Parent = hitboxRow
Instance.new("UICorner", hitboxSizeBox).CornerRadius = UDim.new(0, 4)
-- TextBox for hitbox size label
local szLabel = Instance.new("TextLabel")
szLabel.Size = UDim2.new(0, 14, 1, 0)
szLabel.Position = UDim2.new(1, -114, 0, 0)
szLabel.BackgroundTransparency = 1
szLabel.Text = "S"
szLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
szLabel.Font = Enum.Font.Gotham
szLabel.TextSize = 10
szLabel.Parent = hitboxRow

local hitboxRangeBox = Instance.new("TextBox")
hitboxRangeBox.Size = UDim2.new(0, 45, 0, 22)
hitboxRangeBox.Position = UDim2.new(1, -162, 0.5, -11)
hitboxRangeBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
hitboxRangeBox.BorderSizePixel = 0
hitboxRangeBox.Text = "1"
hitboxRangeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxRangeBox.Font = Enum.Font.GothamSemibold
hitboxRangeBox.TextSize = 12
hitboxRangeBox.ClearTextOnFocus = false
hitboxRangeBox.Parent = hitboxRow
Instance.new("UICorner", hitboxRangeBox).CornerRadius = UDim.new(0, 4)
local rLabel = Instance.new("TextLabel")
rLabel.Size = UDim2.new(0, 14, 1, 0)
rLabel.Position = UDim2.new(1, -176, 0, 0)
rLabel.BackgroundTransparency = 1
rLabel.Text = "R"
rLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
rLabel.Font = Enum.Font.Gotham
rLabel.TextSize = 10
rLabel.Parent = hitboxRow

hitboxTrack.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    if hitboxEnabled then
        hitboxTrack.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
        hitboxKnob.Position = UDim2.new(1, -18, 0.5, -8)
    else
        hitboxTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        hitboxKnob.Position = UDim2.new(0, 2, 0.5, -8)
        restoreHitbox()
    end
end)

hitboxSizeBox.FocusLost:Connect(function()
    local n = tonumber(hitboxSizeBox.Text)
    if n and n >= 0.5 then hitboxSize = n end
    hitboxSizeBox.Text = tostring(hitboxSize)
end)

hitboxRangeBox.FocusLost:Connect(function()
    local n = tonumber(hitboxRangeBox.Text)
    if n and n >= 1 then hitboxRange = n end
    hitboxRangeBox.Text = tostring(hitboxRange)
end)

local methodLabel = Instance.new("TextLabel")
methodLabel.Size = UDim2.new(1, -16, 0, 14)
methodLabel.Position = UDim2.new(0, 10, 0, 0)
methodLabel.BackgroundTransparency = 1
methodLabel.Text = ""
methodLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
methodLabel.Font = Enum.Font.Gotham
methodLabel.TextSize = 10
methodLabel.TextXAlignment = Enum.TextXAlignment.Left
methodLabel.LayoutOrder = 6
methodLabel.Parent = body

local captureBtn = Instance.new("TextButton")
captureBtn.Size = UDim2.new(0, 60, 0, 20)
captureBtn.Position = UDim2.new(1, -70, 0, -22)
captureBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
captureBtn.BorderSizePixel = 0
captureBtn.Text = "Capture"
captureBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
captureBtn.Font = Enum.Font.GothamSemibold
captureBtn.TextSize = 11
captureBtn.Parent = body
Instance.new("UICorner", captureBtn).CornerRadius = UDim.new(0, 4)

captureBtn.MouseButton1Click:Connect(function()
    captureMode = true
    captureResults = {}
    captureBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    captureBtn.Text = "Recording..."
    task.delay(3, function()
    captureMode = false
    captureBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    captureBtn.Text = "Capture"
    local parts = {}
    for k, v in pairs(captureResults) do
        if v >= 3 then
            table.insert(parts, k .. ":" .. v)
        end
    end
    table.sort(parts, function(a, b)
        local na = tonumber(a:match(":(%d+)$")) or 0
        local nb = tonumber(b:match(":(%d+)$")) or 0
        return na > nb
    end)
    if #parts > 0 then
        captureLabel.Text = table.concat(parts, " | ")
    else
        captureLabel.Text = "(nothing fired)"
    end
    end)
end)

captureLabel = Instance.new("TextLabel")
captureLabel.Size = UDim2.new(1, -16, 0, 14)
captureLabel.Position = UDim2.new(0, 10, 0, 0)
captureLabel.BackgroundTransparency = 1
captureLabel.Text = "press Capture then M1"
captureLabel.TextColor3 = Color3.fromRGB(0, 170, 127)
captureLabel.Font = Enum.Font.Gotham
captureLabel.TextSize = 10
captureLabel.TextXAlignment = Enum.TextXAlignment.Left
captureLabel.LayoutOrder = 7
captureLabel.Parent = body

local remoteBtn = Instance.new("TextButton")
remoteBtn.Size = UDim2.new(0, 60, 0, 20)
remoteBtn.Position = UDim2.new(1, -70, 0, -22)
remoteBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
remoteBtn.BorderSizePixel = 0
remoteBtn.Text = "Remotes"
remoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
remoteBtn.Font = Enum.Font.GothamSemibold
remoteBtn.TextSize = 11
remoteBtn.Parent = body
Instance.new("UICorner", remoteBtn).CornerRadius = UDim.new(0, 4)

remoteBtn.MouseButton1Click:Connect(function()
    remoteCapture = true
    remoteResults = {}
    remoteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    remoteBtn.Text = "Recording..."
    task.delay(3, function()
        remoteCapture = false
        remoteBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        remoteBtn.Text = "Remotes"
        local parts = {}
        for k, v in pairs(remoteResults) do
            if v.count <= 50 then
                table.insert(parts, k .. " x" .. v.count .. " [" .. v.sample:sub(1, 80) .. "]")
            else
                table.insert(parts, k .. " x" .. v.count .. " (SPAM)")
            end
        end
        table.sort(parts, function(a, b)
            local na = tonumber(a:match("x(%d+)")) or 0
            local nb = tonumber(b:match("x(%d+)")) or 0
            return na > nb
        end)
        if #parts > 0 then
            remoteLabel.Text = parts[1]
            for i = 2, math.min(#parts, 5) do
                remoteLabel.Text = remoteLabel.Text .. " || " .. parts[i]
            end
        else
            remoteLabel.Text = "(no remotes fired)"
        end
    end)
end)

remoteLabel = Instance.new("TextLabel")
remoteLabel.Size = UDim2.new(1, -16, 0, 42)
remoteLabel.Position = UDim2.new(0, 10, 0, 0)
remoteLabel.BackgroundTransparency = 1
remoteLabel.Text = "press Remotes then M1"
remoteLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
remoteLabel.Font = Enum.Font.Gotham
remoteLabel.TextSize = 10
remoteLabel.TextWrapped = true
remoteLabel.TextXAlignment = Enum.TextXAlignment.Left
remoteLabel.TextYAlignment = Enum.TextYAlignment.Top
remoteLabel.LayoutOrder = 8
remoteLabel.Parent = body

-- Info labels
local info1 = Instance.new("TextLabel")
info1.Size = UDim2.new(1, 0, 0, 16)
info1.BackgroundTransparency = 1
info1.Text = "Mobile = aim assist"
info1.TextColor3 = Color3.fromRGB(100, 100, 100)
info1.Font = Enum.Font.Gotham
info1.TextSize = 11
info1.LayoutOrder = 6
info1.Parent = body

local info2 = Instance.new("TextLabel")
info2.Size = UDim2.new(1, 0, 0, 16)
info2.BackgroundTransparency = 1
info2.Text = "Console = controller aimbot"
info2.TextColor3 = Color3.fromRGB(100, 100, 100)
info2.Font = Enum.Font.Gotham
info2.TextSize = 11
info2.LayoutOrder = 7
info2.Parent = body

local info3 = Instance.new("TextLabel")
info3.Size = UDim2.new(1, 0, 0, 16)
info3.BackgroundTransparency = 1
info3.Text = "PC = keyboard & mouse"
info3.TextColor3 = Color3.fromRGB(100, 100, 100)
info3.Font = Enum.Font.Gotham
info3.TextSize = 11
info3.LayoutOrder = 8
info3.Parent = body

-- Dump character parts buttons
local dumpRow = createRow("DumpParts", 8)

local watchBtn = Instance.new("TextButton")
watchBtn.Size = UDim2.new(0, 70, 0, 24)
watchBtn.Position = UDim2.new(1, -290, 0.5, -12)
watchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
watchBtn.BorderSizePixel = 0
watchBtn.Text = "Watch"
watchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
watchBtn.Font = Enum.Font.GothamSemibold
watchBtn.TextSize = 12
watchBtn.Parent = dumpRow
Instance.new("UICorner", watchBtn).CornerRadius = UDim.new(0, 4)

local watching = false
local watchLog = {}
local watchParts = {}
watchBtn.MouseButton1Click:Connect(function()
    watching = not watching
    if watching then
        watchBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
        watchBtn.Text = "Watch*"
        watchLog = {}
        watchParts = {}
        task.spawn(function()
            while watching do
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character then
                        for _, part in ipairs(plr.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local nm = part.Name
                                if (nm:find("Hit") or nm:find("M1") or nm:find("Punch") or nm:find("Kick") or nm:find("Attack") or nm:find("Swing") or nm:find("Damage") or nm:find("Box") or nm:find("Ability") or nm:find("Skill")) and not watchParts[part] then
                                    watchParts[part] = true
                                    local entry = nm .. " sz=" .. tostring(part.Size) .. " tr=" .. part.Transparency
                                    table.insert(watchLog, entry)
                                    warn("[TSB] NEW: " .. entry)
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        watchBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        watchBtn.Text = "Watch"
        print("[TSB] Watch done (" .. #watchLog .. " entries)")
    end
end)

local watchCopy = Instance.new("TextButton")
watchCopy.Size = UDim2.new(0, 60, 0, 24)
watchCopy.Position = UDim2.new(1, -212, 0.5, -12)
watchCopy.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
watchCopy.BorderSizePixel = 0
watchCopy.Text = "Copy"
watchCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
watchCopy.Font = Enum.Font.GothamSemibold
watchCopy.TextSize = 12
watchCopy.Parent = dumpRow
Instance.new("UICorner", watchCopy).CornerRadius = UDim.new(0, 4)
watchCopy.MouseButton1Click:Connect(function()
    local text = table.concat(watchLog, "\n")
    pcall(function() setclipboard(text) end)
    print("[TSB] Copied " .. #watchLog .. " watch entries")
end)

local partsBtn = Instance.new("TextButton")
partsBtn.Size = UDim2.new(0, 80, 0, 24)
partsBtn.Position = UDim2.new(1, -144, 0.5, -12)
partsBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
partsBtn.BorderSizePixel = 0
partsBtn.Text = "Parts Only"
partsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
partsBtn.Font = Enum.Font.GothamSemibold
partsBtn.TextSize = 12
partsBtn.Parent = dumpRow
Instance.new("UICorner", partsBtn).CornerRadius = UDim.new(0, 4)
partsBtn.MouseButton1Click:Connect(function()
    local lines = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(lines, "--- " .. plr.Name .. " ---")
        if plr.Character then
            local function dump(inst, depth)
                if inst:IsA("BasePart") then
                    local pad = string.rep("  ", depth)
                    table.insert(lines, pad .. "Part \"" .. inst.Name .. "\" sz=" .. tostring(inst.Size) .. " tr=" .. inst.Transparency .. " cfc=" .. tostring(inst.CFrame.Position))
                end
                for _, c in ipairs(inst:GetChildren()) do
                    dump(c, depth + 1)
                end
            end
            dump(plr.Character, 0)
        else
            table.insert(lines, "  No character")
        end
    end
    local text = table.concat(lines, "\n")
    pcall(function() setclipboard(text) end)
    print("[TSB] Copied " .. #lines .. " parts to clipboard")
end)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 80, 0, 24)
copyBtn.Position = UDim2.new(1, -56, 0.5, -12)
copyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
copyBtn.BorderSizePixel = 0
copyBtn.Text = "Copy All"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamSemibold
copyBtn.TextSize = 12
copyBtn.Parent = dumpRow
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)
copyBtn.MouseButton1Click:Connect(function()
    local lines = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(lines, "--- " .. plr.Name .. " ---")
        if plr.Character then
            local function dump(inst, depth)
                local pad = string.rep("  ", depth)
                local sz = ""
                if inst:IsA("BasePart") then
                    sz = " sz=" .. tostring(inst.Size) .. " tr=" .. inst.Transparency
                end
                table.insert(lines, pad .. inst.ClassName .. " \"" .. inst.Name .. "\"" .. sz)
                for _, c in ipairs(inst:GetChildren()) do
                    dump(c, depth + 1)
                end
            end
            dump(plr.Character, 0)
        else
            table.insert(lines, "  No character")
        end
    end
    local text = table.concat(lines, "\n")
    pcall(function() setclipboard(text) end)
    print("[TSB] Copied " .. #lines .. " lines to clipboard")
end)

-- Insert key to toggle menu
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        main.Visible = not main.Visible
    end
end)

-- Draggable
local dragging, dragInput, mousePos, framePos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        main.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)
