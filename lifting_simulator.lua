import pathlib
p = pathlib.Path(r"C:\Users\Sabri\AppData\Local\Temp\opencode\lifting_simulator.lua")
t = """-- Lifting Simulator: Remastered | Auto Farm Script
-- Features: Unlimited Muscle Multiplier, Unlock All Gamepasses, Lifting Speed Multiplier
-- Place: Lifting Simulator: Remastered (PlaceId: 78544923215308)

local cloneref = (cloneref or clonereference or function(i) return i end)
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

-- Obsidian Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Lifting Simulator | PWO",
    Footer = "opp pwo hehehehe",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "dumbbell"),
    Automation = Window:AddTab("Automation", "zap"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- State variables
local muscleMultiplier = 100
local liftingSpeedMultiplier = 1
local autoGainMuscle = false
local autoGainThread = nil
local gamepassesUnlocked = false

-- Hook into ClientRemoteController_Module to modify PlayerData
local function hookPlayerData()
    local ClientModuleStorage = ReplicatedStorage:WaitForChild("ClientModuleStorage")
    local ClientRemoteController_Module = require(ClientModuleStorage:WaitForChild("ClientRemoteController_Module"))
    
    -- Store original functions
    local originalCreateOnClientRemoteEvent = ClientRemoteController_Module.CreateOnClientRemoteEvent
    
    -- Override CreateOnClientRemoteEvent to intercept PlayerData
    ClientRemoteController_Module.CreateOnClientRemoteEvent = function(p1)
        local result = originalCreateOnClientRemoteEvent(p1)
        
        -- After PlayerData is set, apply our modifications
        task.wait(0.5)
        if ClientRemoteController_Module.t and ClientRemoteController_Module.t.PlayerData then
            local PlayerData = ClientRemoteController_Module.t.PlayerData
            
            -- Unlimited Muscle Multiplier (bypass 100 cap)
            if muscleMultiplier > 100 then
                PlayerData.Multiplier = muscleMultiplier
                PlayerData.Multiplier2 = muscleMultiplier
            end
            
            -- Unlock all gamepasses
            if gamepassesUnlocked and PlayerData.GamePass then
                for k, v in pairs(PlayerData.GamePass) do
                    PlayerData.GamePass[k] = true
                end
            end
            
            -- Lifting speed multiplier
            if liftingSpeedMultiplier > 1 then
                -- Will be applied to WalkSpeed via character hook
            end
        end
        
        return result
    end
    
    return ClientRemoteController_Module
end

-- Character hook for WalkSpeed
local function hookCharacter()
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if liftingSpeedMultiplier > 1 then
                    humanoid.WalkSpeed = 16 * liftingSpeedMultiplier
                end
            end)
            -- Initial set
            if liftingSpeedMultiplier > 1 then
                humanoid.WalkSpeed = 16 * liftingSpeedMultiplier
            end
        end
    end
    
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
end

-- Auto Gain Muscle (fires GainMuscle rapidly)
local function startAutoGainMuscle()
    if autoGainThread then task.cancel(autoGainThread) end
    autoGainThread = task.spawn(function()
        local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
        while autoGainMuscle do
            -- Check if character is alive
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                RemoteEvent:FireServer({ "GainMuscle" })
            end
            task.wait(0.005) -- 200 times per second
        end
    end)
end

-- Build UI
local LeftMain = Tabs.Main:AddLeftGroupbox("Muscle")
LeftMain:AddSlider("MuscleMultiplier", {
    Text = "Muscle Multiplier",
    Default = 100,
    Min = 1,
    Max = 10000,
    Rounding = 0,
    Suffix = "x",
    Callback = function(v)
        muscleMultiplier = v
        -- Apply to PlayerData if available
        pcall(function()
            local ClientModuleStorage = ReplicatedStorage:WaitForChild("ClientModuleStorage")
            local ClientRemoteController_Module = require(ClientModuleStorage:WaitForChild("ClientRemoteController_Module"))
            if ClientRemoteController_Module.t and ClientRemoteController_Module.t.PlayerData then
                ClientRemoteController_Module.t.PlayerData.Multiplier = v
                ClientRemoteController_Module.t.PlayerData.Multiplier2 = v
            end
        end)
        Library:Notify(string.format("Muscle Multiplier: %dx", v), 2)
    end,
})
LeftMain:AddToggle("AutoGainMuscle", {
    Text = "Auto Gain Muscle (Fast)",
    Default = false,
    Tooltip = "Fires GainMuscle 200x/sec while alive",
    Callback = function(v)
        autoGainMuscle = v
        if v then
            startAutoGainMuscle()
            Library:Notify("Auto Gain Muscle: ON (200x/sec)", 3)
        else
            if autoGainThread then task.cancel(autoGainThread) autoGainThread=nil end
            Library:Notify("Auto Gain Muscle: OFF", 2)
        end
    end,
})
LeftMain:AddDivider()
LeftMain:AddSlider("LiftingSpeedMultiplier", {
    Text = "Lifting Speed Multiplier",
    Default = 1,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Suffix = "x",
    Callback = function(v)
        liftingSpeedMultiplier = v
        -- Apply to current character
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16 * v
        end
        Library:Notify(string.format("Lifting Speed: %dx", v), 2)
    end,
})

local RightMain = Tabs.Main:AddRightGroupbox("Gamepasses")
RightMain:AddToggle("UnlockGamepasses", {
    Text = "Unlock All Gamepasses",
    Default = false,
    Tooltip = "Sets all GamePass flags to true locally",
    Callback = function(v)
        gamepassesUnlocked = v
        if v then
            pcall(function()
                local ClientModuleStorage = ReplicatedStorage:WaitForChild("ClientModuleStorage")
                local ClientRemoteController_Module = require(ClientModuleStorage:WaitForChild("ClientRemoteController_Module"))
                if ClientRemoteController_Module.t and ClientRemoteController_Module.t.PlayerData and ClientRemoteController_Module.t.PlayerData.GamePass then
                    for k, v in pairs(ClientRemoteController_Module.t.PlayerData.GamePass) do
                        ClientRemoteController_Module.t.PlayerData.GamePass[k] = true
                    end
                end
            end)
            Library:Notify("All Gamepasses: UNLOCKED (local)", 3)
        else
            Library:Notify("Gamepasses: RESET (requires rejoin)", 2)
        end
    end,
})
RightMain:AddButton({
    Text = "Force Unlock All Now",
    Func = function()
        pcall(function()
            local ClientModuleStorage = ReplicatedStorage:WaitForChild("ClientModuleStorage")
            local ClientRemoteController_Module = require(ClientModuleStorage:WaitForChild("ClientRemoteController_Module"))
            if ClientRemoteController_Module.t and ClientRemoteController_Module.t.PlayerData and ClientRemoteController_Module.t.PlayerData.GamePass then
                for k, v in pairs(ClientRemoteController_Module.t.PlayerData.GamePass) do
                    ClientRemoteController_Module.t.PlayerData.GamePass[k] = true
                end
                Library:Notify("All Gamepasses forced to TRUE", 3)
            else
                Library:Notify("PlayerData not ready yet", 2)
            end
        end)
    end,
})
RightMain:AddLabel("Gamepasses: DoubleStrength, DoubleDamage, DoubleCoin, DoubleHealth, FastLifter, FastRunner, InfiniteSize, VIP, ConcealPower, PlayerHunter, DoubleFame", true)

local LeftAuto = Tabs.Automation:AddLeftGroupbox("Auto Farm")
LeftAuto:AddToggle("AutoGainMuscleToggle", {
    Text = "Auto Gain Muscle (Toggle)",
    Default = false,
    Callback = function(v)
        autoGainMuscle = v
        if v then startAutoGainMuscle() else if autoGainThread then task.cancel(autoGainThread) autoGainThread=nil end end
    end,
})
LeftAuto:AddSlider("AutoGainRate", {
    Text = "GainMuscle Rate (ms)",
    Default = 5,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Suffix = "ms",
    Callback = function(v)
        if autoGainThread then task.cancel(autoGainThread) end
        autoGainMuscle = false
        autoGainThread = task.spawn(function()
            local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
            while autoGainMuscle do
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                    RemoteEvent:FireServer({ "GainMuscle" })
                end
                task.wait(v / 1000)
            end
        end)
    end,
})

local RightAuto = Tabs.Automation:AddRightGroupbox("Settings")
RightAuto:AddButton({
    Text = "Re-hook PlayerData",
    Func = function()
        pcall(hookPlayerData)
        Library:Notify("PlayerData hooks refreshed", 2)
    end,
})
RightAuto:AddButton({
    Text = "Re-hook Character",
    Func = function()
        pcall(hookCharacter)
        Library:Notify("Character hooks refreshed", 2)
    end,
})
RightAuto:AddButton({
    Text = "Reset WalkSpeed",
    Func = function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end,
})

RightAuto:AddDivider()
RightAuto:AddButton({ Text = "Unload Script", Func = function()
    if autoGainThread then task.cancel(autoGainThread) end
    Library:Unload()
end })

-- Initialize hooks
task.spawn(function()
    task.wait(1)
    pcall(hookPlayerData)
    pcall(hookCharacter)
    Library:Notify("Lifting Simulator script loaded!", 3)
end)

-- Handle rejoin
LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        if autoGainThread then task.cancel(autoGainThread) end
    end
end)

Library:Notify("Lifting Simulator: Remastered loaded!", 3)
"""
p.write_text(t, encoding="utf-8")
print("done", len(t))
