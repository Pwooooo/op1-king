-- Project Exodus | PWO | Obsidian
-- Features: Ore Speed 1-50x, Auto TP To Sell, Dropper Produce Faster 1-50x, Ore Value Maxer 1-50x
-- Place: [NEW HEIGHTS] Project Exodus (128736833482079)
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/Pwooooo/op1-king/main/opp%20pwo%20hehehehe"))()

local cloneref = (cloneref or clonereference or function(i) return i end)
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local PlayerActions = ReplicatedStorage:WaitForChild("PlayerActions")
local OreActions = PlayerActions:WaitForChild("OreActions")

-- Obsidian
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Project Exodus | PWO",
    Footer = "opp pwo hehehehe",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Automation = Window:AddTab("Automation", "zap"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- Helpers
local function getPlot()
    local ok, plot = pcall(function()
        local owned = LocalPlayer:FindFirstChild("OwnedPlot") or LocalPlayer:WaitForChild("OwnedPlot", 3)
        if owned and owned.Value then return owned.Value end
        return nil
    end)
    if ok and plot and plot.Parent then return plot end
    for _, slot in ipairs(Workspace:WaitForChild("PlayerPlots"):GetChildren()) do
        local p = slot:FindFirstChild("Plot")
        if p and tostring(p:GetAttribute("OwnedBy")) == tostring(LocalPlayer.UserId) then
            return p
        end
    end
    local best, max = nil, -1
    for _, slot in ipairs(Workspace.PlayerPlots:GetChildren()) do
        local p = slot:FindFirstChild("Plot")
        if p and p:FindFirstChild("Placed") and #p.Placed:GetChildren() > max then
            max = #p.Placed:GetChildren()
            best = p
        end
    end
    return best
end

local function getFurnace(plot)
    plot = plot or getPlot()
    if not plot then return nil end
    for _, inst in ipairs(plot:FindFirstChild("Placed"):GetChildren()) do
        if inst.Name:lower():find("furnace") then
            local furnacePart = inst:FindFirstChild("Furnace")
            if furnacePart and furnacePart:IsA("BasePart") then
                return furnacePart, inst
            end
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
        if (key and tostring(key):lower():find("dropper")) or inst.Name:lower():find("dropper") then
            table.insert(list, inst)
        end
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
        if inst:IsA("BasePart") and inst:GetAttribute("Speed") ~= nil then
            table.insert(out, inst)
        end
    end
    return out
end

-- Speed system
local oreSpeed = 1
local dropperSpeed = 1
local originalSpeeds = setmetatable({}, {__mode="k"})
local function applyOreSpeed(mult)
    for _, part in ipairs(getAllConveyors()) do
        if originalSpeeds[part] == nil then
            originalSpeeds[part] = part:GetAttribute("Speed")
        end
        local base = originalSpeeds[part] or 10
        part:SetAttribute("Speed", base * mult)
    end
end

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
            local furnacePart, furnaceModel = getFurnace()
            if furnacePart then
                for _, ore in ipairs(getOres()) do
                    if not autoSell then break end
                    if ore and ore.Parent and ore:GetAttribute("Worth") then
                        pcall(function()
                            ore.CFrame = furnacePart.CFrame * CFrame.new(0, ore.Size.Y/2 + 1.5, 0)
                            ore.AssemblyLinearVelocity = Vector3.new(0,0,0)
                            OreActions:FireServer({{"Process", ore.Name, furnacePart}})
                        end)
                        task.wait(0.02)
                    end
                end
            end
            task.wait(0.15)
        end
    end)
end

-- Dropper Faster
local dropperFasterEnabled = false
local dropperThread = nil
local function startDropperFaster()
    if dropperThread then task.cancel(dropperThread) end
    dropperThread = task.spawn(function()
        while dropperFasterEnabled do
            applyOreSpeed(math.max(oreSpeed, dropperSpeed))
            task.wait(math.clamp(1 / math.max(1, dropperSpeed), 0.02, 0.5))
        end
    end)
end

-- Value Maxer
local valueMaxerEnabled = false
local valueMaxerTimes = 10
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
local LeftMain = Tabs.Main:AddLeftGroupbox("Ore Control")
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
        Library:Notify(string.format("Ore Speed: %dx", v), 2)
    end,
})
LeftMain:AddToggle("ApplyOreSpeed", {
    Text = "Apply Ore Speed Continuously",
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
                        d:SetAttribute("Speed", (originalSpeeds[d] or 10) * oreSpeed)
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
        if dropperFasterEnabled then applyOreSpeed(math.max(oreSpeed, dropperSpeed)) end
    end,
})
LeftMain:AddToggle("DropperFaster", {
    Text = "Dropper Produce Faster",
    Default = false,
    Callback = function(v)
        dropperFasterEnabled = v
        if v then startDropperFaster() Library:Notify("Dropper Faster: ON ("..dropperSpeed.."x)", 2)
        else if dropperThread then task.cancel(dropperThread) dropperThread=nil end applyOreSpeed(oreSpeed) Library:Notify("Dropper Faster: OFF", 2) end
    end,
})
LeftMain:AddButton({
    Text = "Produce Burst (instant 50x)",
    Func = function()
        local droppers = getDroppers()
        Library:Notify("Droppers: "..#droppers, 2)
        applyOreSpeed(50)
        task.delay(2, function() applyOreSpeed(oreSpeed) end)
    end,
})

local RightMain = Tabs.Main:AddRightGroupbox("Sell")
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
LeftAuto:AddButton({
    Text = "List Upgraders",
    Func = function()
        local ups=getUpgraders()
        Library:Notify("Upgraders: "..#ups,3)
        for i,up in ipairs(ups) do print(i, up.model.Name, tostring(up.part.Position)) if i>8 then break end end
    end,
})

local RightAuto = Tabs.Automation:AddRightGroupbox("Info")
RightAuto:AddLabel("Plot: "..(getPlot() and getPlot():GetFullName() or "none"), true)
RightAuto:AddButton({
    Text = "Copy Plot Info",
    Func = function()
        local p=getPlot()
        if p then setclipboard(p:GetFullName()) Library:Notify("Copied "..p:GetFullName(),2) end
    end,
})
RightAuto:AddLabel("How it works:\n- Ore Speed: multiplies Speed attr on conveyors.\n- Dropper Faster: keeps Speed maxed + droppers enabled.\n- TP Sell: moves ClientOres to Furnace + fires Process.\n- Value Maxer: tps each ore through every Upgrader N times + fires Upgrade.", true)
RightAuto:AddDivider()
RightAuto:AddButton({
    Text = "Unload",
    Func = function() Library:Unload() end,
})

Library:Notify("Project Exodus loaded — PWO", 3)
task.spawn(function()
    task.wait(1)
    local plot = getPlot()
    if plot then Library:Notify("Plot: "..plot.Parent.Name.." | Placed: "..#plot.Placed:GetChildren().." | Ores: "..#getOres(), 3) end
end)
