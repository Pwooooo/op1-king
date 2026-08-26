-- Project Exodus | PWO | Obsidian v5 PERSISTENT DROPPER
-- Fixes: ore flying at high speed (stabilizer + capped velocity), dropper produce actually faster (OreLimit + DropRate + duplication)
-- Features: Ore Speed 1-50x (stabilized), Auto TP To Sell, Dropper Produce Faster 1-50x, Ore Value Maxer 1-50x

local cloneref = (cloneref or clonereference or function(i) return i end)
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))

local LocalPlayer = Players.LocalPlayer
local PlayerActions = ReplicatedStorage:WaitForChild("PlayerActions")
local OreActions = PlayerActions:WaitForChild("OreActions")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Project Exodus | PWO ULTRA",
    Footer = "opp pwo hehehehe v3 ultra sell",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Automation = Window:AddTab("Automation", "zap"),
    Settings = Window:AddTab("Settings", "settings"),
}

local function getPlot()
    local ok, plot = pcall(function()
        local owned = LocalPlayer:FindFirstChild("OwnedPlot") or LocalPlayer:WaitForChild("OwnedPlot", 3)
        if owned and owned.Value then return owned.Value end
        return nil
    end)
    if ok and plot and plot.Parent then return plot end
    for _, slot in ipairs(Workspace:WaitForChild("PlayerPlots"):GetChildren()) do
        local p = slot:FindFirstChild("Plot")
        if p and tostring(p:GetAttribute("OwnedBy")) == tostring(LocalPlayer.UserId) then return p end
    end
    local best, max = nil, -1
    for _, slot in ipairs(Workspace.PlayerPlots:GetChildren()) do
        local p = slot:FindFirstChild("Plot")
        if p and p:FindFirstChild("Placed") and #p.Placed:GetChildren() > max then max = #p.Placed:GetChildren() best = p end
    end
    return best
end

local function getFurnace(plot)
    plot = plot or getPlot()
    if not plot then return nil end
    for _, inst in ipairs(plot:FindFirstChild("Placed"):GetChildren()) do
        if inst.Name:lower():find("furnace") then
            local furnacePart = inst:FindFirstChild("Furnace")
            if furnacePart and furnacePart:IsA("BasePart") then return furnacePart, inst end
            return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart"), inst
        end
    end
    return nil
end

local function getUpgraders(plot)
    plot = plot or getPlot()
    if not plot or not plot:FindFirstChild("Placed") then return {} end
    local list, seen = {}, {}
    for _, inst in ipairs(plot.Placed:GetChildren()) do
        for _, d in ipairs(inst:GetDescendants()) do
            if d.Name == "Upgrader" and d:IsA("BasePart") then
                if not seen[d] then seen[d]=true table.insert(list, {part=d, model=inst}) end
            end
        end
        local up = inst:FindFirstChild("Upgrader")
        if up and up:IsA("BasePart") and not seen[up] then seen[up]=true table.insert(list, {part=up, model=inst}) end
    end
    return list
end

local function getDroppers(plot)
    plot = plot or getPlot()
    if not plot then return {} end
    local list = {}
    for _, inst in ipairs(plot.Placed:GetChildren()) do
        local key = inst:GetAttribute("PlacedKey")
        if (key and tostring(key):lower():find("dropper")) or inst.Name:lower():find("dropper") then table.insert(list, inst) end
    end
    return list
end

local function getOres(plot)
    plot = plot or getPlot()
    if not plot then return {} end
    local co = plot:FindFirstChild("ClientOres")
    if not co then return {} end
    local out = {}
    for _, ore in ipairs(co:GetChildren()) do
        if ore:IsA("BasePart") then table.insert(out, ore)
        elseif ore:IsA("Model") and ore.PrimaryPart then table.insert(out, ore.PrimaryPart) end
    end
    return out
end

local function getAllConveyors(plot)
    plot = plot or getPlot()
    if not plot then return {} end
    local out = {}
    for _, inst in ipairs(plot.Placed:GetDescendants()) do
        if inst:IsA("BasePart") and inst:GetAttribute("Speed") ~= nil then table.insert(out, inst) end
    end
    return out
end

-- Speed system FIXED: capped + stabilizer
local oreSpeed = 1
local dropperSpeed = 1
local originalSpeeds = setmetatable({}, {__mode="k"})
local function effectiveSpeed(base, mult)
    -- curve so 50x slider does not give 50*base (flying)
    -- map 1-50 -> 1x to ~3.5x base, capped at 45
    local curved = math.pow(math.clamp(mult,1,50), 0.62) * 1.35
    return math.clamp(base * curved, 0, 45)
end
local function applyOreSpeed(mult)
    for _, part in ipairs(getAllConveyors()) do
        if originalSpeeds[part] == nil then originalSpeeds[part] = part:GetAttribute("Speed") end
        local base = originalSpeeds[part] or 12
        part:SetAttribute("Speed", effectiveSpeed(base, mult))
        -- keep texture speed reasonable
        part.AssemblyLinearVelocity = part.CFrame.LookVector * effectiveSpeed(base, mult)
    end
end

-- Stabilizer: keeps ores centered on conveyor, prevents flying
local stabilizeEnabled = true
local oreStabilizeConn = nil
local function startStabilizer()
    if oreStabilizeConn then oreStabilizeConn:Disconnect() end
    oreStabilizeConn = RunService.PreSimulation:Connect(function()
        if not stabilizeEnabled then return end
        if oreSpeed <= 10 and dropperSpeed <= 10 then return end
        for _, ore in ipairs(getOres()) do
            if ore and ore.Parent and not ore:GetAttribute("IsTeleporting") then
                local vel = ore.AssemblyLinearVelocity
                -- clamp extreme velocity that causes flying
                if vel.Magnitude > 60 then
                    local dir = vel.Unit
                    ore.AssemblyLinearVelocity = dir * 45
                end
                -- keep ore from flying: clamp Y velocity
                if math.abs(vel.Y) > 25 then
                    ore.AssemblyLinearVelocity = Vector3.new(vel.X, math.clamp(vel.Y, -15, 15), vel.Z)
                end
                -- if ore is way above conveyor (flying), snap down
                local ray = Workspace:Raycast(ore.Position, Vector3.new(0,-10,0), RaycastParams.new())
                if ray and ray.Instance and ray.Instance:GetAttribute("Speed") ~= nil then
                    if (ore.Position.Y - ray.Position.Y) > 6 then
                        ore.CFrame = CFrame.new(ore.Position.X, ray.Position.Y + ore.Size.Y/2 + 0.4, ore.Position.Z)
                        ore.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
                    end
                end
            end
        end
    end)
end
startStabilizer()

local function tpOre(ore, targetPart)
    if not ore or not ore.Parent or not targetPart or not targetPart.Parent then return end
    if ore:GetAttribute("IsTeleporting") then return end
    ore:SetAttribute("IsTeleporting", true)
    local wasAnchored = ore.Anchored
    ore.Anchored = true
    ore.CFrame = targetPart.CFrame * CFrame.new(0, ore.Size.Y/2 + 1.5, 0)
    ore.AssemblyLinearVelocity = Vector3.new(0,0,0)
    ore.AssemblyAngularVelocity = Vector3.new(0,0,0)
    task.wait(0.03)
    ore.Anchored = wasAnchored
    task.wait(0.02)
    ore:SetAttribute("IsTeleporting", false)
end

-- Auto Sell
local autoSell = false
local autoSellThread = nil
local function startAutoSell()
    if autoSellThread then task.cancel(autoSellThread) end
    autoSellThread = task.spawn(function()
        while autoSell do
            local furnacePart = getFurnace()
            if furnacePart then
                local ores = getOres()
                for _, ore in ipairs(ores) do
                    if not autoSell then break end
                    if ore and ore.Parent and ore:GetAttribute("Worth") and not ore:GetAttribute("IsTeleporting") then
                        pcall(function()
                            ore:PivotTo(furnacePart.CFrame * CFrame.new(0, ore.Size.Y/2 + 1.5, 0))
                            ore.AssemblyLinearVelocity = Vector3.new(0,0,0)
                            ore.AssemblyAngularVelocity = Vector3.new(0,0,0)
                            OreActions:FireServer({{"Process", ore.Name, furnacePart}})
                        end)
                    end
                end
            end
            task.wait(math.clamp(0.04 / math.clamp(sellSpeed,1,50), 0.005, 0.04))
        end
    end)
end

-- Dropper Faster FIXED: now actually increases spawn rate
local dropperFasterEnabled = false
local dropperThread = nil
-- try to patch DropRate client-side
pcall(function()
    local OreStats = require(ReplicatedStorage.ItemIds:WaitForChild("OreStats"))
    if OreStats and OreStats.Drop then
        for _, data in pairs(OreStats.Drop) do
            if type(data) == "table" and data.DropRate then
                data._OriginalDropRate = data.DropRate
            end
        end
    end
end)
local function patchDropRate(mult)
    pcall(function()
        local OreStats = require(ReplicatedStorage.ItemIds.OreStats)
        for _, data in pairs(OreStats.Drop) do
            if type(data)=="table" and data._OriginalDropRate then
                -- lower interval = faster, so divide
                data.DropRate = math.max(0.08, data._OriginalDropRate / math.clamp(mult,1,50))
            end
        end
    end)
end
local function startDropperFaster()
    if dropperThread then task.cancel(dropperThread) end
    dropperThread = task.spawn(function()
        local lastClone = 0
        while dropperFasterEnabled do
            -- re-apply every tick so server resets dont stick
            pcall(function()
                local plot = getPlot()
                if plot then plot:SetAttribute("OreLimit", 1000) end
            end)
            patchDropRate(dropperSpeed)
            applyOreSpeed(math.max(oreSpeed, dropperSpeed))
            -- duplication to simulate faster production
            if tick() - lastClone > (0.28 / math.clamp(dropperSpeed,1,50)) then
                lastClone = tick()
                pcall(function()
                    local plot = getPlot()
                    if not plot then return end
                    local droppers = getDroppers()
                    if #droppers == 0 then return end
                    local ores = getOres()
                    if #ores == 0 then return end
                    local dropper = droppers[math.random(1,#droppers)]
                    local dropPart = dropper:FindFirstChild("Drop") or dropper.PrimaryPart or dropper:FindFirstChildWhichIsA("BasePart")
                    local template = ores[math.random(1,#ores)]
                    if not dropPart or not template then return end
                    -- use OreLimit not 90
                    local oreLimit = plot:GetAttribute("OreLimit") or 1000
                    if #ores >= math.clamp(oreLimit - 5, 50, 995) then return end
                    -- find conveyor direction near dropper for proper placement
                    local conveyorDir = nil
                    local bestDist = math.huge
                    for _, part in ipairs(getAllConveyors(plot)) do
                        local d = (part.Position - dropPart.Position).Magnitude
                        if d < bestDist and d < 20 then
                            bestDist = d
                            conveyorDir = part.CFrame.LookVector
                        end
                    end
                    if not conveyorDir then conveyorDir = Vector3.new(0,0,1) end
                    local clone = template:Clone()
                    clone.Name = tostring(LocalPlayer.UserId).."_"..tostring(math.random(1000000,9999999))
                    -- place normally: directly above Drop part, same orientation as template, not rotated weirdly
                    clone.CFrame = CFrame.new(dropPart.Position + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(math.random(0,360)), 0)
                    clone.AssemblyLinearVelocity = Vector3.new(0, -3, 0)
                    clone.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    clone.Anchored = false
                    clone.CanCollide = true
                    clone.Parent = plot:FindFirstChild("ClientOres")
                    local worth = template:GetAttribute("Worth") or 100
                    clone:SetAttribute("Worth", worth)
                    clone:SetAttribute("IsTeleporting", false)
                    -- copy other attributes from template
                    for k,v in pairs(template:GetAttributes()) do
                        if k ~= "IsTeleporting" then pcall(function() clone:SetAttribute(k,v) end) end
                    end
                    task.delay(0.12, function()
                        if clone and clone.Parent and conveyorDir then
                            -- now push onto conveyor direction gently, not flying
                            clone.AssemblyLinearVelocity = conveyorDir * math.clamp(effectiveSpeed(12, math.min(dropperSpeed, 15)), 8, 28)
                        end
                    end)
                    task.delay(10, function() if clone and clone.Parent then pcall(function() clone:Destroy() end) end end)
                end)
            end
            task.wait(0.05)
        end
    end)
end

-- Value Maxer
local valueMaxerEnabled = false
local valueMaxerTimes = 10
local sellSpeed = 50
local valueMaxerThread = nil
local function startValueMaxer()
    if valueMaxerThread then task.cancel(valueMaxerThread) end
    valueMaxerThread = task.spawn(function()
        while valueMaxerEnabled do
            local ups = getUpgraders()
            if #ups > 0 then
                for _, ore in ipairs(getOres()) do
                    if not valueMaxerEnabled then break end
                    if ore and ore.Parent and ore:GetAttribute("Worth") and not ore:GetAttribute("IsTeleporting") then
                        for t = 1, valueMaxerTimes do
                            for _, up in ipairs(ups) do
                                if not ore.Parent then break end
                                if not valueMaxerEnabled then break end
                                pcall(function()
                                    tpOre(ore, up.part)
                                    OreActions:FireServer({{"Upgrade", ore.Name, up.part}})
                                end)
                                task.wait(0.03)
                            end
                        end
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- UI
local LeftMain = Tabs.Main:AddLeftGroupbox("Ore Control (FIXED)")
LeftMain:AddSlider("OreSpeed", {
    Text = "Ore Speed",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = "x",
    Callback = function(v)
        oreSpeed = v
        applyOreSpeed(v)
        Library:Notify(string.format("Ore Speed: %dx (effective %.1f)", v, effectiveSpeed(12, v)), 2)
    end,
})
LeftMain:AddToggle("Stabilize", {
    Text = "Stabilize Ores (anti-fly)",
    Default = true,
    Callback = function(v) stabilizeEnabled = v end,
})
LeftMain:AddToggle("ApplyOreSpeed", {
    Text = "Apply Continuously",
    Default = false,
    Callback = function(v)
        if v then
            applyOreSpeed(oreSpeed)
            local plot = getPlot()
            if plot and plot:FindFirstChild("Placed") then
                plot.Placed.DescendantAdded:Connect(function(d)
                    if d:IsA("BasePart") and d:GetAttribute("Speed") ~= nil then
                        task.wait(0.05)
                        if originalSpeeds[d] == nil then originalSpeeds[d] = d:GetAttribute("Speed") end
                        d:SetAttribute("Speed", effectiveSpeed(originalSpeeds[d] or 12, oreSpeed))
                    end
                end)
            end
        end
    end,
})
LeftMain:AddDivider()
LeftMain:AddSlider("DropperSpeed", {
    Text = "Dropper Produce Speed",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = "x",
    Callback = function(v)
        dropperSpeed = v
        if dropperFasterEnabled then applyOreSpeed(math.max(oreSpeed, dropperSpeed)) patchDropRate(v) end
        Library:Notify("Dropper Speed: "..v.."x",1)
    end,
})
LeftMain:AddToggle("DropperFaster", {
    Text = "Dropper Produce Faster (FIXED)",
    Default = false,
    Callback = function(v)
        dropperFasterEnabled = v
        if v then startDropperFaster() Library:Notify("Dropper Faster: ON ("..dropperSpeed.."x) - OreLimit 1000 + DropRate patched + duplication", 3)
        else if dropperThread then task.cancel(dropperThread) dropperThread=nil end patchDropRate(1) applyOreSpeed(oreSpeed) Library:Notify("Dropper Faster: OFF", 2) end
    end,
})
LeftMain:AddButton({
    Text = "Produce Burst (instant 50x 2s)",
    Func = function()
        local droppers = getDroppers()
        Library:Notify("Droppers: "..#droppers, 2)
        applyOreSpeed(50)
        task.delay(2, function() applyOreSpeed(oreSpeed) end)
    end,
})

local RightMain = Tabs.Main:AddRightGroupbox("Sell")
RightMain:AddSlider("SellSpeed", {
    Text = "Sell TP Speed",
    Default = 50,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = "x",
    Callback = function(v) sellSpeed = v end,
})
RightMain:AddToggle("AutoSell", {
    Text = "Auto TP To Sell (Furnace)",
    Default = false,
    Callback = function(v)
        autoSell = v
        if v then startAutoSell() Library:Notify("Auto TP Sell: ON", 2)
        else if autoSellThread then task.cancel(autoSellThread) autoSellThread=nil end Library:Notify("Auto TP Sell: OFF", 2) end
    end,
})
RightMain:AddButton({
    Text = "TP All Ores To Sell NOW",
    Func = function()
        local fp, fm = getFurnace()
        if not fp then Library:Notify("No Furnace found", 3) return end
        local n=0
        for _, ore in ipairs(getOres()) do
            pcall(function() tpOre(ore, fp) OreActions:FireServer({{"Process", ore.Name, fp}}) n+=1 end)
        end
        Library:Notify("Teleported "..n.." ores to "..fm.Name, 2)
    end,
})
RightMain:AddButton({
    Text = "Show Furnace Location",
    Func = function()
        local fp,fm = getFurnace()
        if fp then Library:Notify(fm.Name.." @ "..tostring(fp.Position), 4) end
    end,
})

local LeftAuto = Tabs.Automation:AddLeftGroupbox("Ore Value Maxer")
LeftAuto:AddSlider("ValueMaxTimes", {
    Text = "Value Maxer Loops (tps in front of upgraders)",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Suffix = "x Times",
    Callback = function(v) valueMaxerTimes = v end,
})
LeftAuto:AddToggle("ValueMaxer", {
    Text = "Enable Ore Value Maxer",
    Default = false,
    Callback = function(v)
        valueMaxerEnabled = v
        if v then startValueMaxer() Library:Notify("Value Maxer: ON ("..valueMaxerTimes.."x)", 2)
        else if valueMaxerThread then task.cancel(valueMaxerThread) valueMaxerThread=nil end Library:Notify("Value Maxer: OFF", 2) end
    end,
})
LeftAuto:AddLabel("Teleports ores in front of each Upgrader.\nLoops x times per ore for max value.", true)
LeftAuto:AddButton({
    Text = "Max Single Ore NOW",
    Func = function()
        local ups = getUpgraders()
        local ores = getOres()
        if #ores==0 or #ups==0 then Library:Notify("No ores/upgraders",3) return end
        local ore = ores[1]
        for i=1,valueMaxerTimes do
            for _, up in ipairs(ups) do
                tpOre(ore, up.part)
                pcall(function() OreActions:FireServer({{"Upgrade", ore.Name, up.part}}) end)
                task.wait(0.04)
            end
        end
        Library:Notify("Maxed 1 ore "..valueMaxerTimes.."x via "..#ups.." upgraders",2)
    end,
})
LeftAuto:AddButton({ Text = "List Upgraders", Func = function()
        local ups=getUpgraders()
        Library:Notify("Upgraders: "..#ups,3)
        for i,up in ipairs(ups) do print(i, up.model.Name, tostring(up.part.Position)) if i>8 then break end end
    end,
})

local RightAuto = Tabs.Automation:AddRightGroupbox("Info FIXED")
RightAuto:AddLabel("Fixes:\n- Speed now capped at 45 + curved (50x = ~42) + anti-fly stabilizer.\n- Dropper now patches DropRate + OreLimit 1000 + clones ores at Drop part.", true)
RightAuto:AddButton({ Text = "Copy Plot Info", Func = function() local p=getPlot() if p then setclipboard(p:GetFullName()) Library:Notify("Copied "..p:GetFullName(),2) end end,})
RightAuto:AddDivider()
RightAuto:AddButton({ Text = "Unload", Func = function() Library:Unload() if oreStabilizeConn then oreStabilizeConn:Disconnect() end end,})

Library:Notify("Project Exodus FIXED loaded â€” PWO", 3)
task.spawn(function()
    task.wait(1)
    local plot = getPlot()
    if plot then Library:Notify("Plot: "..plot.Parent.Name.." | Placed: "..#plot.Placed:GetChildren().." | Ores: "..#getOres(), 3) end
end)
