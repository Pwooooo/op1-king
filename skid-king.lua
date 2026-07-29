local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LP = Players:WaitForChild("LocalPlayer", 10) or Players.LocalPlayer
if not LP then warn("skid-king: no LocalPlayer") return end

local spoof = {
    TouchEnabled = false,
    GamepadEnabled = false,
    KeyboardEnabled = true,
    MouseEnabled = true,
}

local function applySpoof(mode)
    if mode == "PC" then
        spoof.TouchEnabled = false; spoof.GamepadEnabled = false
        spoof.KeyboardEnabled = true; spoof.MouseEnabled = true
    elseif mode == "Mobile" then
        spoof.TouchEnabled = true; spoof.GamepadEnabled = false
        spoof.KeyboardEnabled = false; spoof.MouseEnabled = false
    elseif mode == "Console" then
        spoof.TouchEnabled = false; spoof.GamepadEnabled = true
        spoof.KeyboardEnabled = false; spoof.MouseEnabled = false
    end
end

pcall(function()
    local nc
    nc = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "GetService" then
            local name = (...)
            if name == "UserInputService" then
                return setmetatable({}, { __index = function(_, k)
                    if k == "TouchEnabled" then return spoof.TouchEnabled end
                    if k == "GamepadEnabled" then return spoof.GamepadEnabled end
                    if k == "KeyboardEnabled" then return spoof.KeyboardEnabled end
                    if k == "MouseEnabled" then return spoof.MouseEnabled end
                    local v = UIS[k]
                    return type(v) == "function" and function(_, ...) return v(UIS, ...) end or v
                end })
            end
        end
        return nc(self, ...)
    end)
end)

local function make(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end

local sg = make("ScreenGui", { Name = "skid-king", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
local ok, err = pcall(function() sg.Parent = LP:WaitForChild("PlayerGui", 5) end)
if not ok then
    pcall(function() sg.Parent = CoreGui end)
end

local Main = make("Frame", {
    Size = UDim2.new(0, 400, 0, 300),
    Position = UDim2.new(0.5, -200, 0.5, -150),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel = 0,
    Active = true,
    Parent = sg,
})
make("UIStroke", { Color = Color3.fromRGB(40, 40, 40), Thickness = 1, Parent = Main })
make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Main })

local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = Main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Main.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
end)
UIS.InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1,
    Text = "skid-king",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    Parent = Main,
})

local TabBar = make("Frame", { Size = UDim2.new(1, -10, 0, 25), Position = UDim2.new(0, 5, 0, 30), BackgroundTransparency = 1, Parent = Main })
local Content = make("Frame", { Size = UDim2.new(1, -10, 1, -65), Position = UDim2.new(0, 5, 0, 58), BackgroundColor3 = Color3.fromRGB(24, 24, 24), BorderSizePixel = 0, Parent = Main })
make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Content })

local activeTab = nil
local tabFrames = {}
local tabBtns = {}

local function switchTab(name)
    if activeTab then activeTab.Visible = false end
    if tabFrames[name] then
        tabFrames[name].Visible = true
        activeTab = tabFrames[name]
    end
    for n, b in pairs(tabBtns) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(30, 30, 30)
        b.TextColor3 = (n == name) and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6)
    end
end

for i, name in ipairs({ "Main", "Shaders", "Config" }) do
    local btn = make("TextButton", {
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, (i - 1) * 65, 0, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        Text = name, TextColor3 = Color3.new(0.6, 0.6, 0.6),
        TextSize = 13, Font = Enum.Font.Gotham, BorderSizePixel = 0,
        Parent = TabBar,
    })
    make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
    tabBtns[name] = btn

    local tab = make("Frame", { Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), BackgroundTransparency = 1, Visible = false, Parent = Content })
    tabFrames[name] = tab

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    if i == 1 then switchTab(name) end
end

-- Main tab: device spoofer
local gb = make("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = tabFrames.Main })
make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = gb })
make("UIStroke", { Color = Color3.fromRGB(40, 40, 40), Thickness = 1, Parent = gb })

make("TextLabel", {
    Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 8, 0, 5),
    BackgroundTransparency = 1, Text = "Device Spoofer",
    TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = gb,
})

local currentMode = "PC"
local modeNames = { "PC", "Mobile", "Console" }

local ddBox = make("Frame", { Size = UDim2.new(0, 150, 0, 22), Position = UDim2.new(0, 8, 0, 28), BackgroundColor3 = Color3.fromRGB(18, 18, 18), BorderSizePixel = 0, Parent = gb })
make("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ddBox })
local ddText = make("TextLabel", {
    Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 6, 0, 0),
    BackgroundTransparency = 1, Text = "PC", TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = ddBox,
})
make("TextLabel", {
    Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -16, 0.5, -6),
    BackgroundTransparency = 1, Text = ">", TextColor3 = Color3.new(0.6, 0.6, 0.6),
    TextSize = 12, Font = Enum.Font.Gotham, Parent = ddBox,
})

local ddList = make("Frame", {
    Size = UDim2.new(0, 150, 0, 66), Position = UDim2.new(0, 0, 0, 24),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18), BorderSizePixel = 0,
    Visible = false, ZIndex = 10, Parent = ddBox,
})
make("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ddList })

local mobileTimer = nil

for _, name in ipairs(modeNames) do
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        Text = name, TextColor3 = Color3.new(0.8, 0.8, 0.8),
        TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0, ZIndex = 11, Parent = ddList,
    })
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(18, 18, 18) end)
    b.MouseButton1Click:Connect(function()
        currentMode = name; ddText.Text = name; ddList.Visible = false
        applySpoof(name)
        if mobileTimer then mobileTimer:Cancel(); mobileTimer = nil end
        if name == "Mobile" then
            mobileTimer = task.delay(5, function()
                currentMode = "PC"; ddText.Text = "PC"; applySpoof("PC"); mobileTimer = nil
            end)
        end
    end)
end

ddBox.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        ddList.Visible = not ddList.Visible
    end
end)

UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 and ddList.Visible then
        task.wait()
        local mp = Vector2.new(i.Position.X, i.Position.Y)
        local a, s = ddList.AbsolutePosition, ddList.AbsoluteSize
        if mp.X < a.X or mp.X > a.X + s.X or mp.Y < a.Y or mp.Y > a.Y + s.Y then
            ddList.Visible = false
        end
    end
end)

make("TextLabel", {
    Size = UDim2.new(1, -10, 0, 12), Position = UDim2.new(0, 8, 0, 55),
    BackgroundTransparency = 1, Text = "Mobile auto-reverts to PC after 5s",
    TextColor3 = Color3.fromRGB(140, 140, 140), TextSize = 10,
    Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = gb,
})

-- Shaders tab: Glossy OP1

local shadeEnable = false
local shadeHbs = {}

local function toggleGlossy(v)
    shadeEnable = v
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
        shadeHbs.desc = workspace.DescendantAdded:Connect(function(p)
            task.wait()
            if p:IsA("BasePart") and not p:IsA("Terrain") then
                p.Material = Enum.Material.ForceField
            end
        end)
        shadeHbs.char = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            for _, p in pairs(workspace:GetDescendants()) do
                if p:IsA("BasePart") and not p:IsA("Terrain") then
                    p.Material = Enum.Material.ForceField
                end
            end
        end)
        shadeHbs.fps = game:GetService("RunService").RenderStepped:Connect(function()
            lighting.Brightness = 2.5
            lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            lighting.Ambient = Color3.new(1, 1, 1)
            lighting.GlobalShadows = false
        end)
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
        for _, c in pairs(shadeHbs) do pcall(c.Disconnect, c) end
        shadeHbs = {}
    end
end

local shdGb = make("Frame", { Size = UDim2.new(1, 0, 0, 100), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = tabFrames.Shaders })
make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = shdGb })
make("UIStroke", { Color = Color3.fromRGB(40, 40, 40), Thickness = 1, Parent = shdGb })
make("TextLabel", { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 8, 0, 5), BackgroundTransparency = 1, Text = "Glossy OP1 Shaders", TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = shdGb })

-- Toggle switch
local togBg = make("Frame", { Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 28), BackgroundColor3 = Color3.fromRGB(22, 22, 22), BorderSizePixel = 0, Parent = shdGb })
make("UICorner", { CornerRadius = UDim.new(0, 3), Parent = togBg })
make("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1, Text = "Glossy", TextColor3 = Color3.new(0.9, 0.9, 0.9), TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = togBg })
local togSwitch = make("Frame", { Size = UDim2.new(0, 28, 0, 16), Position = UDim2.new(1, -34, 0.5, -8), BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, Parent = togBg })
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = togSwitch })
local togKnob = make("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 1, 0.5, -7), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = togSwitch })
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = togKnob })
local glossOn = false
togBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        glossOn = not glossOn
        togSwitch.BackgroundColor3 = glossOn and Color3.fromRGB(60, 160, 80) or Color3.fromRGB(60, 60, 60)
        togKnob:TweenPosition(glossOn and UDim2.new(0, 13, 0.5, -7) or UDim2.new(0, 1, 0.5, -7), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        toggleGlossy(glossOn)
    end
end)

-- FOV slider
local fovLbl = make("TextLabel", { Name = "FOVLabel", Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 62), BackgroundTransparency = 1, Text = "FOV: 90", TextColor3 = Color3.new(0.9, 0.9, 0.9), TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = shdGb })
local fovTrack = make("Frame", { Size = UDim2.new(1, -16, 0, 4), Position = UDim2.new(0, 8, 0, 84), BackgroundColor3 = Color3.fromRGB(60, 60, 60), BorderSizePixel = 0, Parent = shdGb })
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovTrack })
local fovFill = make("Frame", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(60, 160, 80), BorderSizePixel = 0, Parent = fovTrack })
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovFill })
local fovDrag = make("Frame", { Size = UDim2.new(0, 10, 0, 12), Position = UDim2.new(0.5, -5, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = fovTrack })
make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovDrag })
local fovDragState = false
fovDrag.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then fovDragState = true end
end)
fovDrag.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then fovDragState = false end
end)
UIS.InputChanged:Connect(function(i)
    if fovDragState and i.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = math.clamp((i.Position.X - fovTrack.AbsolutePosition.X) / fovTrack.AbsoluteSize.X, 0, 1)
        fovFill.Size = UDim2.new(rel, 0, 1, 0)
        fovDrag.Position = UDim2.new(rel, -5, 0.5, -6)
        local fv = math.floor(60 + rel * 60)
        pcall(function() fovLbl.Text = "FOV: " .. fv end)
        pcall(function() game:GetService("Workspace").CurrentCamera.FieldOfView = fv end)
    end
end)

-- Config tab
local cfgGb = make("Frame", { Size = UDim2.new(1, 0, 0, 100), BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = tabFrames.Config })
make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cfgGb })
make("UIStroke", { Color = Color3.fromRGB(40, 40, 40), Thickness = 1, Parent = cfgGb })

make("TextLabel", {
    Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 8, 0, 5),
    BackgroundTransparency = 1, Text = "Config",
    TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = cfgGb,
})

local function saveConfig()
    pcall(function() writefile("skid-king-config.json", Http:JSONEncode({ mode = currentMode })) end)
end

local function loadConfig()
    pcall(function()
        local data = Http:JSONDecode(readfile("skid-king-config.json"))
        if data and data.mode then
            currentMode = data.mode; ddText.Text = data.mode; applySpoof(data.mode)
        end
    end)
end

local function makeBtn(text, x, color)
    local b = make("TextButton", {
        Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(0, x, 0, 30),
        BackgroundColor3 = color, Text = text, TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0, Parent = cfgGb,
    })
    make("UICorner", { CornerRadius = UDim.new(0, 3), Parent = b })
    return b
end

makeBtn("Save", 8, Color3.fromRGB(40, 120, 60)).MouseButton1Click:Connect(saveConfig)
makeBtn("Load", 96, Color3.fromRGB(50, 50, 120)).MouseButton1Click:Connect(loadConfig)

task.defer(function() task.wait(0.5); loadConfig() end)
