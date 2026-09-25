-- Sky Linoria shim for Blade Ball: replaces the embedded NeverZen lib (lines 1-4092).
-- Blade Ball main below is UNTOUCHED: same NeverZen.new/AddTab/AddSection/
-- AddToggle/AddSlider/AddKeybind/AddDivider/AddDropdown/AddInput/AddButton/
-- AddLabel calls, same handles (SetValue/SetText/GetValue/Fire), same
-- NeverZen:Track/CreateNotifier/Unload. Linoria renders it all.
-- Hardened: every Linoria call is pcall'd and named in F9 on failure, so one
-- bad element can never silently abort the rest of the UI. Progress visible
-- live via getgenv().SkyBB.Built.
repeat task.wait() until game:IsLoaded()

local IsSupported = true
if not setfflag or
    not hookmetamethod or
    not newcclosure or
    not islclosure or
    not getconnections or
    not debug.getupvalues or
    not checkcaller or
    not getgc or
    not setthreadidentity or
    not getthreadidentity then
    IsSupported = false
end

-- Chunk-level service locals: the original embedded lib defined these and the
-- Blade Ball main uses them bare throughout. Without them everything is nil.
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local Stats = cloneref(game:GetService("Stats"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Workspace = cloneref(game:GetService("Workspace"))
local TextService = cloneref(game:GetService('TextService'))
local Debris = cloneref(game:GetService("Debris"))

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua"))()

local NeverZen = { Version = "linoria-2" }
NeverZen.ProtectGui = protectgui or protect_gui or (syn and syn.protect_gui) or function() end
NeverZen.Theme = {
    Hightlight = Color3.fromRGB(200, 215, 230),
    BackgroundColor = Color3.fromRGB(32, 32, 32),
    StrokeColor = Color3.fromRGB(40, 40, 40),
}
NeverZen.Connections = {}
function NeverZen:Track(conn)
    table.insert(NeverZen.Connections, conn)
    return conn
end

local __uid = 0
local function __nextId(name)
    __uid = __uid + 1
    local clean = tostring(name or "el"):gsub("%W", "")
    if clean == "" then clean = "el" end
    return "SkyBB_" .. clean .. "_" .. __uid
end

local function __noop() end

local function __fail(kind, name, err)
    warn("[SkyBB] " .. tostring(kind) .. " '" .. tostring(name) .. "' failed: " .. tostring(err))
end

local __built = 0
local function __count()
    __built += 1
    pcall(function()
        if getgenv then
            local g = getgenv()
            g.SkyBB = g.SkyBB or {}
            g.SkyBB.Library = Library
            g.SkyBB.Built = __built
        end
    end)
end

local __dummySection
__dummySection = function()
    local h = function()
        return {
            SetValue = __noop, SetText = __noop, SetValues = __noop,
            GetValue = function() return nil end, Fire = __noop,
            Visible = __noop, Destroy = __noop,
        }
    end
    return {
        AddToggle = h, AddSlider = h, AddButton = h, AddLabel = h,
        AddDivider = h, AddDropdown = h, AddInput = h, AddKeybind = h,
    }
end

function NeverZen:CreateNotifier()
    return {
        new = function(head, body, duration)
            pcall(function()
                Library:Notify(tostring(head) .. " - " .. tostring(body), tonumber(duration) or 5)
            end)
        end,
    }
end

function NeverZen:Unload()
    for _, c in ipairs(NeverZen.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(NeverZen.Connections)
    pcall(function()
        if Library.Toggled ~= false then Library:Toggle() end
    end)
end

function NeverZen.new(config)
    config = config or {}
    local Window = Library:CreateWindow({
        Title = tostring(config.Name or "Sky"),
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2,
        -- OS cursor: Drawing renders nothing on this setup.
        ShowCustomCursor = false,
    })
    Library.ShowCustomCursor = false
    pcall(function()
        game:GetService("UserInputService").MouseIconEnabled = true
    end)
    pcall(function()
        Library.BackgroundColor = Color3.fromRGB(12, 12, 12)
        Library.MainColor = Color3.fromRGB(20, 20, 20)
        Library.AccentColor = Color3.fromRGB(200, 215, 230)
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library.OutlineColor = Color3.fromRGB(40, 40, 40)
        Library.FontColor = Color3.fromRGB(255, 255, 255)
        Library:UpdateColorsUsingRegistry()
    end)
    local bindKey = config.Keybind or Enum.KeyCode.LeftControl
    NeverZen:Track(game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == bindKey then
            pcall(function() Library:Toggle() end)
        end
    end))

    local WindowSignal = {}
    -- NeverZen sidebar titles ('General', 'Miscellaneous') have no Linoria
    -- equivalent; tabs keep creation order, titles are skipped.
    function WindowSignal:AddLabel(_)
        return {}
    end
    function WindowSignal:AddTab(cfg)
        cfg = cfg or {}
        local ok, tab = pcall(function() return Window:AddTab(tostring(cfg.Name or "Tab")) end)
        if not ok or not tab then
            __fail("tab", cfg and cfg.Name, tab)
            return { AddSection = function() return __dummySection() end }
        end
        local TabSignal = {}
        function TabSignal:AddSection(scfg)
            scfg = scfg or {}
            local ok2, gb = pcall(function()
                if tostring(scfg.Position or "left"):lower() == "right" then
                    return tab:AddRightGroupbox(tostring(scfg.Name or "Section"))
                else
                    return tab:AddLeftGroupbox(tostring(scfg.Name or "Section"))
                end
            end)
            if not ok2 or not gb then
                __fail("section", scfg and scfg.Name, gb)
                return __dummySection()
            end
            local S = {}

            function S:AddToggle(tcfg)
                tcfg = tcfg or {}
                local idx = __nextId(tcfg.Name)
                local ok3, err = pcall(function()
                    gb:AddToggle(idx, {
                        Text = tostring(tcfg.Name or "Toggle"),
                        Default = (tcfg.Default == true),
                        Callback = function(v) pcall(tcfg.Callback or __noop, v) end,
                    })
                end)
                if not ok3 then
                    __fail("toggle", tcfg.Name, err)
                    return { SetValue = __noop, Visible = __noop }
                end
                __count()
                return {
                    SetValue = function(_, v)
                        pcall(function() Library.Toggles[idx]:SetValue(not not v) end)
                    end,
                    Visible = __noop,
                }
            end

            function S:AddSlider(ccfg)
                ccfg = ccfg or {}
                local idx = __nextId(ccfg.Name)
                local ok3, err = pcall(function()
                    gb:AddSlider(idx, {
                        Text = tostring(ccfg.Name or "Slider"),
                        Default = tonumber(ccfg.Default) or tonumber(ccfg.Min) or 0,
                        Min = tonumber(ccfg.Min) or 0,
                        Max = tonumber(ccfg.Max) or 100,
                        Rounding = tonumber(ccfg.Round) or 0,
                        Suffix = tostring(ccfg.Type or ""),
                        Callback = function(v) pcall(ccfg.Callback or __noop, v) end,
                    })
                end)
                if not ok3 then
                    __fail("slider", ccfg.Name, err)
                    return { SetValue = __noop, Fire = __noop, Visible = __noop }
                end
                __count()
                return {
                    SetValue = function(_, v)
                        pcall(function() Library.Options[idx]:SetValue(v) end)
                    end,
                    Fire = ccfg.Callback or __noop,
                    Visible = __noop,
                }
            end

            function S:AddButton(bcfg)
                bcfg = bcfg or {}
                local cb = bcfg.Callback or __noop
                local ok3, err = pcall(function()
                    gb:AddButton({
                        Text = tostring(bcfg.Name or "Button"),
                        Func = function() pcall(cb) end,
                    })
                end)
                if not ok3 then
                    __fail("button", bcfg.Name, err)
                    return { Fire = __noop, Visible = __noop }
                end
                __count()
                return { Fire = cb, Visible = __noop }
            end

            function S:AddLabel(text)
                local ok3, lab = pcall(function() return gb:AddLabel(tostring(text or "")) end)
                if not ok3 or not lab then
                    __fail("label", text, lab)
                    return { SetValue = __noop, Visible = __noop }
                end
                __count()
                return {
                    SetValue = function(_, v)
                        pcall(function() lab:SetText(tostring(v)) end)
                    end,
                    Visible = __noop,
                }
            end

            function S:AddDivider(_)
                local ok3 = pcall(function() gb:AddDivider() end)
                __count()
                if ok3 then
                    return { Visible = __noop, Destroy = __noop }
                end
                local _, lab = pcall(function() return gb:AddLabel("") end)
                return { Visible = __noop, Destroy = function() pcall(function() lab:Destroy() end) end }
            end

            function S:AddDropdown(dcfg)
                dcfg = dcfg or {}
                local idx = __nextId(dcfg.Name)
                local vals = dcfg.Values or {}
                local def = dcfg.Default
                if def == nil then def = vals[1] end
                local ok3, err = pcall(function()
                    gb:AddDropdown(idx, {
                        Values = vals,
                        Default = def,
                        Multi = (dcfg.Multi == true),
                        Text = tostring(dcfg.Name or "Dropdown"),
                        Callback = function(v) pcall(dcfg.Callback or __noop, v) end,
                    })
                end)
                if not ok3 then
                    __fail("dropdown", dcfg.Name, err)
                    return { SetValue = __noop, SetValues = __noop, Fire = __noop, Visible = __noop }
                end
                __count()
                return {
                    SetValue = function(_, v)
                        pcall(function() Library.Options[idx]:SetValue(v) end)
                    end,
                    SetValues = function(_, v)
                        pcall(function() Library.Options[idx]:SetValues(v) end)
                    end,
                    Fire = dcfg.Callback or __noop,
                    Visible = __noop,
                }
            end

            -- Custom row (not Linoria AddInput): NeverZen fires realtime on
            -- every keystroke and Blade Ball's skin inputs rely on that.
            function S:AddInput(icfg)
                icfg = icfg or {}
                local cb = icfg.Callback or __noop
                local box
                local ok3, err = pcall(function()
                    gb:AddLabel(tostring(icfg.Name or "Input"))
                    local gui = gb.Container
                    box = Instance.new("TextBox")
                    box.Size = UDim2.new(1, -8, 0, 22)
                    box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    box.BorderSizePixel = 0
                    box.Text = tostring(icfg.Default or "")
                    box.PlaceholderText = tostring(icfg.Placeholder or "Type here...")
                    box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
                    box.TextColor3 = Color3.fromRGB(255, 255, 255)
                    box.Font = Enum.Font.Gotham
                    box.TextSize = 13
                    box.ClearTextOnFocus = false
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 4)
                    corner.Parent = box
                    box.Parent = gui
                    NeverZen:Track(box:GetPropertyChangedSignal("Text"):Connect(function()
                        pcall(cb, box.Text)
                    end))
                end)
                if not ok3 or not box then
                    __fail("input", icfg.Name, err)
                    pcall(function()
                        gb:AddInput(__nextId(icfg.Name), {
                            Default = tostring(icfg.Default or ""),
                            Numeric = false,
                            Finished = false,
                            Text = tostring(icfg.Name or "Input"),
                            Placeholder = tostring(icfg.Placeholder or "Type here..."),
                            Callback = function(v) pcall(cb, v) end,
                        })
                    end)
                end
                __count()
                return {
                    SetValue = function(_, v)
                        if box then box.Text = tostring(v) end
                        pcall(cb, tostring(v))
                    end,
                    GetValue = function()
                        if box then return box.Text end
                        return tostring(icfg.Default or "")
                    end,
                    Visible = __noop,
                    Fire = cb,
                }
            end

            -- Bind-only keybind: main stores the KeyCode and runs its own
            -- press handler, so the shim just rebinds + fires the callback.
            function S:AddKeybind(kcfg)
                kcfg = kcfg or {}
                local cb = kcfg.Callback or __noop
                local current = kcfg.Default
                local function fmt(k)
                    if typeof(k) == "EnumItem" then return k.Name end
                    return "NONE"
                end
                local ok3, disp = pcall(function()
                    return gb:AddLabel(tostring(kcfg.Name or "Keybind") .. ": [ " .. fmt(current) .. " ]")
                end)
                if not ok3 or not disp then
                    __fail("keybind", kcfg.Name, disp)
                    return { SetValue = __noop, Fire = __noop, Visible = __noop }
                end
                local binding = false
                local function refresh()
                    local t = tostring(kcfg.Name or "Keybind") .. ": [ " .. (binding and "..." or fmt(current)) .. " ]"
                    pcall(function() disp:SetText(t) end)
                end
                local ok4, err4 = pcall(function()
                    gb:AddButton({
                        Text = "Set keybind",
                        Func = function() binding = true refresh() end,
                    })
                end)
                if not ok4 then
                    __fail("keybind-button", kcfg.Name, err4)
                end
                NeverZen:Track(game:GetService("UserInputService").InputBegan:Connect(function(inp)
                    if not binding then return end
                    if inp.KeyCode == Enum.KeyCode.Unknown then return end
                    binding = false
                    current = inp.KeyCode
                    refresh()
                    pcall(cb, current)
                end))
                __count()
                return {
                    SetValue = function(_, v)
                        current = v
                        refresh()
                        pcall(cb, current)
                    end,
                    Fire = cb,
                    Visible = __noop,
                }
            end

            return S
        end
        return TabSignal
    end
    return WindowSignal
end

local NZNotification = NeverZen:CreateNotifier()

if not IsSupported then
    NZNotification.new('Sky', 'Your executor was not supported.', 10)
    return
end

local ACHAOTICASSETS = {
    CurrentCamera = nil,
    ServerStatsItem = nil,
    SwordAPI = nil,
    swordInstancesInstance = nil,
    swordInstances = nil,
    SwordController = nil,
    Replion = nil,
    Runtime = nil,
}

local ParryDATA = {
    ParryFunction = nil,
    ParryRemote = nil,
    ParryIndex = 0.500,
}
       
-- Direct resolution: the game pre-creates its own per-server parry remote.
-- The old getgc shape-scan matches nothing on current versions and a full
-- GC sweep is exactly the kind of bulk enumeration BAC watches for.
local function AttemptFunctionFetch()
    local ParryDATACache = {
        ParryFunction = nil,
        ParryRemote = nil,
    }
    pcall(function()
        local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
        local remote = netFolder:FindFirstChild("RE/" .. string.gsub(game.JobId, '-', ''))
        if remote then
            ParryDATACache.ParryRemote = remote
            ParryDATACache.ParryFunction = function(...)
                return remote:FireServer(...)
            end
        end
    end)
    return ParryDATACache
end

NZNotification.new('Sky', 'Attempting to fetch game data', 5)

local Result = AttemptFunctionFetch()
ParryDATA.ParryFunction = Result.ParryFunction
ParryDATA.ParryRemote = Result.ParryRemote

if ParryDATA.ParryFunction and ParryDATA.ParryRemote then
    NZNotification.new('Sky', 'Successfully fetched game data.', 5)
else 
    NZNotification.new('Sky', 'Failed to fetch game data, please check developer console.', 5)
end
print(string.format("[Sky]:[DEBUG]\nParryFunction: %s\nParryRemote: %s", tostring(ParryDATA.ParryFunction), tostring(ParryDATA.ParryRemote)))

NZNotification.new('Sky', 'Attempting to load main script.', 5)

ACHAOTICASSETS.CurrentCamera = Workspace.CurrentCamera
ACHAOTICASSETS.ServerStatsItem = Stats.Network.ServerStatsItem
ACHAOTICASSETS.SwordAPI = ReplicatedStorage.Shared.SwordAPI
ACHAOTICASSETS.swordInstancesInstance = ReplicatedStorage.Shared.ReplicatedInstances.Swords
ACHAOTICASSETS.DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
ACHAOTICASSETS.ThreadSafeTargetingHelper = require(ReplicatedStorage.Shared.ThreadSafeTargetingHelper)
do
    local OldThreadIdentity = (getthreadidentity and getthreadidentity()) or 2
    if setthreadidentity then setthreadidentity(2) end
    ACHAOTICASSETS.swordInstances = require(ACHAOTICASSETS.swordInstancesInstance)
    if setthreadidentity then setthreadidentity(OldThreadIdentity) end
end
ACHAOTICASSETS.SwordController = nil
ACHAOTICASSETS.Runtime = Workspace:WaitForChild("Runtime")

do
    for _, connection in pairs(getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent)) do
        if connection.Function and islclosure(connection.Function) then
            local upvalues = debug.getupvalues(connection.Function)
            if #upvalues == 1 and type(upvalues[1]) == "table" then
                ACHAOTICASSETS.SwordController = upvalues[1]
                break
            end
        end
    end
end

local ACHAOTICDATA = {
    Player = {
        LocalPlayer = Players.LocalPlayer,
        Character = nil,
        Humanoid = nil,
    },
    Connections = {},
    Balls = Workspace:WaitForChild("Balls"),
    Parry = {},
    Global = {
        LastInput = nil,
        AutoParryParried = false,
        Parries = 0,
        SuccessParries = 0,
        TornadoTime = 0,
        LerpRadians = 0,
        lastParryTime = 0,
        AutoParryCurrentAccuracy = 0,
        AutoSpamParryCurrentAccuracy = 0,
    },
    Config = {
        AutoParry = {
            Enabled = false,
            AntiCurveEnabled = true,
            AnimationFix = false
        },
        LobbyAutoParry = {
            Enabled = false,
            AntiCurveEnabled = true,
            AnimationFix = false
        },
        AutoSpamParry = {
            Enabled = false,
            Keybind = nil,
            DetectionMode = "Speed",
            AnimationFix = false,
            Spamming = false,
            Threshold = 3
        },
        ManualSpamParry = {
            Spamming = false,
            UI = false,
            Keybind = nil,
            AnimationFix = false
        },
        TriggerBot = {
            Enabled = false,
            UI = false,
            Keybind = nil,
            AnimationFix = false,
            InfinityDetection = false
        },
        BallStats = {
            Enabled = false
        },
        ClientStats = {
            Enabled = false
        },
        Animation = {
            GrabParry = nil,
            AnimationCache = {},
            AnimationDelay = 1,
            SpamAnimationParries = 0,
            AnimationSpammingMode = false,
        },
        ParrySettings = {
            Detections = {
                InfinityBall = {
                    Enabled = false,
                    Flag = false
                },
                DeathSlashBall = {
                    Enabled = false,
                    Flag = false
                },
                TimeHole = {
                    Enabled = false,
                    Flag = false
                },
                SlashesofFury = {
                    Enabled = false,
                    Flag = false,
                    Count = 0
                }
            },
            SpeedDivisorMultiplier = 1.1,
            AutoParryAccuracy = 80,
            AutoParryAutoAccuracy = false,
            ParryMethod = "Blatant",
            SlashesofFuryDetectionMaxParryCount = 36,
            SlashesofFuryDetectionParryDelay = 0.05,
            SpammingRPS = 180,
            ParryCurveDirection = "Camera",
            FastBallProtection = false,
            LobbyAutoParryAccuracy = 80,
            LobbySpeedDivisorMultiplier = 1.1,
            VisualiserParries = 0,
            SafeMode = true,
            RemoveCooldown = false
        }
    }
}

local TriggerBotParried = false

local Visuals = {
    VisualisersEnabled = false,
    VisualiserService = {},
    HitEffectEnabled = false,
    HitEffectService = {
        BallEffects = {}
    },
    VisualParts = {}
}

function Visuals.VisualiserService:ClearAll()
    for _, part in pairs(Visuals.VisualParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    Visuals.VisualParts = {}
end

local Immortality = {
    Enabled = false,
    SpeedBypassEnabled = true,
    Angle = 72,
    Height = 15,
    Depth = -8,
    SquareRadius = 10,
    UI = false
}

local ImmortalityUIService = {}

local SkinChanger = {
    Enabled = false,
    Targets = {
        SwordModel = {
            Enabled = false,
            ModelName = ""
        },
        SwordAnimation = {
            Enabled = false,
            AnimationName = ""
        },
        SwordFX = {
            Enabled = false,
            FXName = ""
        }
    },
    System = {
        SlashName = "SlashEffect",
        parrySuccessAllConnection = nil,
        parrySuccessClientConnection = nil,
        playParryFunc = nil,
        lastOtherParryTimestamp = 0,
        OriginalEquipSwordTo = nil,
        functions = {}
    }
}

local Optimization = {
    NoRenderEnabled = false,
    HideServerRendering = false
}

local UI = {
    Window = NeverZen.new({
        Name = "Sky",
        SubTitle = "Blade Ball",
        Keybind = Enum.KeyCode.LeftControl,
        Scale = UDim2.new(0, 611, 0, 396),
        Resizable = true,
        Shadow = false,
        Acrylic = false,
        ShowProfile = false
    }),
    AutoParryToggle = nil,
    ManualSpamParryToggle = nil,
    SpamLoopRPSLabel = nil,
    SpamAccumulatorLabel = nil,
    TriggerBotToggle = nil,
    BallStats = {
        ScreenGui = nil,
        Handler = nil,
        SpeedValue = nil,
        PeakSpeedValue = nil,
        PeakSpeed = 0,
    },
    TriggerBotUI = {
        ScreenGui = nil,
        Handler = nil,
        ToggleButton = nil,
    },
    ImmortalityToggle = nil,
    SpamUI = {
        ScreenGui = nil,
        Handler = nil,
        SpamButton = nil,
    },
    ImmortalityUI = {
        ScreenGui = nil,
        Handler = nil,
        ToggleButton = nil,
    },
    StatsUI = {
        ScreenGui = nil,
        Handler = nil,
        States ={
            FPS = nil,
            PING = nil,
            CPU = nil,
            MEMORY = nil
        }
    }
}

local Debug = {
    Spamming = {
        Speed = 0,
        LastRepeat = 0,
        RepeatedAmount = 0,
    }
}

local ManualSpamParryUIService = {}

local TriggerBotUIService = {}
local BallStatsUIService = {}

local StatsUIService = {}

local AnimationFixService = {
    Rate = 180,
    FEMode = false,
    Cache = {}
}

local ClearCache = nil
local ResetAccumulator = nil

local UnloadACHT = nil

local function GetCharacter()
    return ACHAOTICDATA.Player.LocalPlayer.Character
end

local function GetHumanoid()
    local character = GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function StopAnimation(animationtrack, FadeTime)
    local StopFadeTime = FadeTime or animationtrack:GetAttribute("StopFadeTime")
    animationtrack:Stop(StopFadeTime)
end

local function PlayGrabAnimation(animationtrack)
    local PlayFadeTime = animationtrack:GetAttribute("PlayFadeTime")
    local PlayWeight = animationtrack:GetAttribute("PlayWeight")
    local PlaySpeed = animationtrack:GetAttribute("PlaySpeed")
    animationtrack:Play(PlayFadeTime, PlayWeight, PlaySpeed)
end

local function GetParryAnimation(swordName)
    local character = GetCharacter()
    if not character then return nil end
    
    if not swordName then 
        return ACHAOTICASSETS.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    end
    
    if AnimationFixService.Cache[swordName] then
        return AnimationFixService.Cache[swordName]
    end
    
    local success, swordData = pcall(function()
        return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(swordName)
    end)
    
    if not success or not swordData or type(swordData) ~= "table" then
        AnimationFixService.Cache[swordName] = ACHAOTICASSETS.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        return AnimationFixService.Cache[swordName]
    end
    
    if not swordData.AnimationType or type(swordData.AnimationType) ~= "string" then
        AnimationFixService.Cache[swordName] = ACHAOTICASSETS.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        return AnimationFixService.Cache[swordName]
    end
    
    local swordCollection = ACHAOTICASSETS.SwordAPI.Collection
    for _, object in pairs(swordCollection:GetChildren()) do
        if object.Name == swordData.AnimationType then
            local animation = object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab")
            if animation then
                AnimationFixService.Cache[swordName] = animation
                return animation
            end
        end
    end
    
    AnimationFixService.Cache[swordName] = ACHAOTICASSETS.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    return AnimationFixService.Cache[swordName]
end

local SpamAnimationFixLastPlayed = 0
local SpamAnimationFixBypass = false

local function PlayParry_Animation()
    local IsBlockLegit = true

    local LocalPlayer = ACHAOTICDATA.Player.LocalPlayer
    local Character = GetCharacter()
    if not Character then IsBlockLegit = false end
    if Character:GetAttribute("Stunned") then
        IsBlockLegit = false
    end
    local IsInLobbyTrainning = LocalPlayer:GetAttribute("LobbyTraining") and (Character.Parent == workspace.Dead and true or false)
    if Character.Parent ~= Workspace.Alive and not (ACHAOTICASSETS.DebugFlags.LobbyParry or (LocalPlayer:GetAttribute("LobbyParry") or IsInLobbyTrainning)) then
        IsBlockLegit = false
    end
    if Character:GetAttribute("DoNotParry") or Character:GetAttribute("ChargingAdrenaline") and LocalPlayer.Upgrades["Qi-Charge"].Value < 2 then
        IsBlockLegit = false
    end
    if LocalPlayer:GetAttribute("LobbyParry") and LocalPlayer:GetAttribute("InLobbyParryCooldown") then
        IsBlockLegit = false
    end

    local SafeModeEnabled = ACHAOTICDATA.Config.ParrySettings.SafeMode
    local ShouldExecuteRemoteFireServer = (IsBlockLegit and SafeModeEnabled) or not SafeModeEnabled
    if not ShouldExecuteRemoteFireServer then
        return
    end

    local humanoid = GetHumanoid()
    if not humanoid then return end

    local currentSword = nil
    if SkinChanger.Enabled and SkinChanger.Targets.SwordAnimation.Enabled and SkinChanger.Targets.SwordAnimation.AnimationName ~= "" then
        currentSword = SkinChanger.Targets.SwordAnimation.AnimationName
    else
        local character = GetCharacter()
        if not character then return end
        currentSword = character:GetAttribute("CurrentlyEquippedSword")
    end
    
    local animation = GetParryAnimation(currentSword)
    if not animation then 
        animation = ACHAOTICASSETS.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        if not animation then return end
    end
    
    for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
        if track.Name == "GrabParry" or track.Name == "Grab" then
            if not ACHAOTICDATA.Config.Animation.AnimationSpammingMode and not AnimationFixService.FEMode then
                track.TimePosition = 0
            end
            StopAnimation(track)
        elseif track.Name == "SuccessParry" or track.Name == "Success" then
            if ACHAOTICDATA.Config.Animation.AnimationSpammingMode and not AnimationFixService.FEMode then
                track.TimePosition = 0
            end
            StopAnimation(track)
        end
    end
    ACHAOTICDATA.Config.Animation.GrabParry = humanoid.Animator:LoadAnimation(animation)
    PlayGrabAnimation(ACHAOTICDATA.Config.Animation.GrabParry)
end

local AnimationFixDelayLimit = 0

local function SpamParry_Animation()
    if os.clock() - AnimationFixDelayLimit >= (1/AnimationFixService.Rate) then
        AnimationFixDelayLimit = os.clock()
        if ((os.clock() - SpamAnimationFixLastPlayed) >= 0.1) or SpamAnimationFixBypass or ACHAOTICDATA.Config.Animation.AnimationSpammingMode then
            SpamAnimationFixLastPlayed = os.clock()
            SpamAnimationFixBypass = false
            PlayParry_Animation()
        end
    end
end

NeverZen:Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    ACHAOTICDATA.Global.LastInput = input.UserInputType
end))

do 
    SkinChanger.System.functions.setSword = function()
        pcall(function()
            debug.setupvalue(SkinChanger.System.OriginalEquipSwordTo,3,false)
        end)
        
        if SkinChanger.Targets.SwordModel.Enabled and SkinChanger.Targets.SwordModel.ModelName ~= "" then
            ACHAOTICASSETS.swordInstances:EquipSwordTo(GetCharacter(), SkinChanger.Targets.SwordModel.ModelName)
        end
        
        if SkinChanger.Targets.SwordAnimation.Enabled and SkinChanger.Targets.SwordAnimation.AnimationName ~= "" and ACHAOTICASSETS.SwordController then
            ACHAOTICASSETS.SwordController:SetSword(SkinChanger.Targets.SwordAnimation.AnimationName)
        end
    end

    SkinChanger.System.functions.getSlashName = function(swordName)
        local swordData = ACHAOTICASSETS.swordInstances:GetSword(swordName)
        return (swordData and swordData.SlashName) or "SlashEffect"
    end

    SkinChanger.System.functions.updateSword = function()
        if SkinChanger.Targets.SwordFX.Enabled and SkinChanger.Targets.SwordFX.FXName ~= "" then
            SkinChanger.System.SlashName = SkinChanger.System.functions.getSlashName(SkinChanger.Targets.SwordFX.FXName)
        end
        SkinChanger.System.functions.setSword()
    end 
end

local function GetParry_Data(curveDirection, IsInLobbyTrainning)
    local PlayerPositions = {}
    local Vector2_Mouse_Location
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local isRelevantInput = ACHAOTICDATA.Global.LastInput and (
        ACHAOTICDATA.Global.LastInput == Enum.UserInputType.MouseButton1 or 
        ACHAOTICDATA.Global.LastInput == Enum.UserInputType.MouseButton2 or 
        ACHAOTICDATA.Global.LastInput == Enum.UserInputType.Keyboard
    )
    
    if isRelevantInput and not isMobile then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        local viewportSize = ACHAOTICASSETS.CurrentCamera.ViewportSize
        Vector2_Mouse_Location = {viewportSize.X / 2, viewportSize.Y / 2}
    end
    
    if IsInLobbyTrainning then
        for _, player_character in workspace.Dead:GetChildren() do
            local player = Players:GetPlayerFromCharacter(player_character)

            if player and (player:GetAttribute("LobbyTraining") and player_character.PrimaryPart) then
                PlayerPositions[player_character.Name] = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
            end
        end

        for _, target in CollectionService:GetTagged("LobbyTrainingTarget") do
            PlayerPositions[target.Name] = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(target.Position)
        end
    else
        local CurrentlySelectedMode = Workspace:GetAttribute("CurrentlySelectedMode")

        if CurrentlySelectedMode == "Hovergoal" or CurrentlySelectedMode == "Soccer" then
            local TeamNumber
            if ACHAOTICASSETS.ThreadSafeTargetingHelper.GetPlayerTeam(ACHAOTICDATA.Player.LocalPlayer) == 1 then TeamNumber = 2 else TeamNumber = 1 end

            for _, hovergoalgoal in CollectionService:GetTagged("HovergoalGoal") do
                if hovergoalgoal.Name == ("Goal%*"):format((tostring(TeamNumber))) then
                    PlayerPositions[hovergoalgoal.Name] = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(hovergoalgoal.Target.Position)

                    break
                end
            end

            for _, player_character in Workspace.Alive:GetChildren() do
                if player_character.PrimaryPart and player_character:GetAttribute("IsTheRisingZombie") then
                    PlayerPositions[player_character.Name] = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
                end
            end
        else
            for _, player_character in Workspace.Alive:GetChildren() do
                if player_character.PrimaryPart then
                    PlayerPositions[player_character.Name] = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
                end
            end
        end
    end
    
    if curveDirection == 'Camera' then
        return {ACHAOTICASSETS.CurrentCamera.CFrame, PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Straight' then
        local closestEntity = nil
        local closestDistance = math.huge
        local mouseVector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])

        if IsInLobbyTrainning then
            for _, player_character in workspace.Dead:GetChildren() do
                local player = Players:GetPlayerFromCharacter(player_character)

                if player and (player:GetAttribute("LobbyTraining") and player_character:FindFirstChild("HumanoidRootPart")) then
                    local screenPos, isOnScreen = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
                    if isOnScreen then
                        local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                        local distance = (mouseVector - playerScreenPos).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestEntity = player_character
                        end
                    end
                end
            end

            for _, target in CollectionService:GetTagged("LobbyTrainingTarget") do
                local screenPos, isOnScreen = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(target.Position)
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (mouseVector - playerScreenPos).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestEntity = target
                    end
                end
            end
        else
            local CurrentlySelectedMode = Workspace:GetAttribute("CurrentlySelectedMode")

            if CurrentlySelectedMode == "Hovergoal" or CurrentlySelectedMode == "Soccer" then
                local TeamNumber
                if ACHAOTICASSETS.ThreadSafeTargetingHelper.GetPlayerTeam(ACHAOTICDATA.Player.LocalPlayer) == 1 then TeamNumber = 2 else TeamNumber = 1 end

                for _, hovergoalgoal in CollectionService:GetTagged("HovergoalGoal") do
                    if hovergoalgoal.Name == ("Goal%*"):format((tostring(TeamNumber))) then
                        local screenPos, isOnScreen = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(hovergoalgoal.Target.Position)
                        if isOnScreen then
                            local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (mouseVector - playerScreenPos).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestEntity = hovergoalgoal.Target
                            end
                        end
                        break
                    end
                end

                for _, player_character in Workspace.Alive:GetChildren() do
                    if player_character.PrimaryPart and player_character:GetAttribute("IsTheRisingZombie") then
                        local screenPos, isOnScreen = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
                        if isOnScreen then
                            local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (mouseVector - playerScreenPos).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestEntity = player_character
                            end
                        end
                    end
                end
            else
                for _, player_character in Workspace.Alive:GetChildren() do
                    if player_character.PrimaryPart then
                        local screenPos, isOnScreen = ACHAOTICASSETS.CurrentCamera:WorldToScreenPoint(player_character.PrimaryPart.Position)
                        if isOnScreen then
                            local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (mouseVector - playerScreenPos).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestEntity = player_character
                            end
                        end
                    end
                end
            end
        end
        
        if closestEntity and closestEntity.PrimaryPart then
            return {CFrame.new(GetCharacter().PrimaryPart.Position, closestEntity.PrimaryPart.Position), PlayerPositions, Vector2_Mouse_Location}
        else
            return {ACHAOTICASSETS.CurrentCamera.CFrame, PlayerPositions, Vector2_Mouse_Location}
        end
    elseif curveDirection == 'Up' then
        local upDirection = ACHAOTICASSETS.CurrentCamera.CFrame.UpVector * 1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + upDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Down' then
        local downDirection = ACHAOTICASSETS.CurrentCamera.CFrame.UpVector * -1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + downDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Left' then
        local leftDirection = ACHAOTICASSETS.CurrentCamera.CFrame.RightVector * -1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + leftDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Right' then
        local rightDirection = ACHAOTICASSETS.CurrentCamera.CFrame.RightVector * 1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + rightDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Backward' then
        local backDirection = ACHAOTICASSETS.CurrentCamera.CFrame.LookVector * -1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + backDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Random' then
        local randomDirection = Vector3.new(math.random(-1e9, 1e9), math.random(-1e9, 1e9), math.random(-1e9, 1e9))
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + randomDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Accelerate' then
        local accelerateDirection = ACHAOTICASSETS.CurrentCamera.CFrame.LookVector * 10 + Vector3.new(0,7,0)
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + accelerateDirection), PlayerPositions, Vector2_Mouse_Location}
    elseif curveDirection == 'Decelerate' then
        local decelerateDirection = Vector3.new(0, -1, 0) * 1e9
        return {CFrame.new(ACHAOTICASSETS.CurrentCamera.CFrame.Position, ACHAOTICASSETS.CurrentCamera.CFrame.Position + decelerateDirection), PlayerPositions, Vector2_Mouse_Location}
    else
        return {
            ACHAOTICASSETS.CurrentCamera.CFrame,
            PlayerPositions,
            Vector2_Mouse_Location
        }
    end
end
local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))

local Camera = workspace.CurrentCamera

local PRY = require(ReplicatedStorage:FindFirstChild('PRY', true))

local Network = getupvalue(PRY, 6)
local Constants = getupvalue(PRY, 3)
local Convert = getupvalue(PRY, 4)

local Hash1 = getupvalue(PRY, 8)
-- v6361 moved the TIME key: Constants[2] is now a nested table, the key
-- string lives at Constants[3] (verified live via Convert probe).
local Hash2 = (type(Constants[2]) == "string" and Constants[2]) or Constants[3]
local Hash3 = function()
    local Constant = Convert(Hash2, 'TIME')
    local Time = tostring(math.floor(workspace:GetServerTimeNow() * 100))
    local Encoded = {}
    for i = 1, #Time do
        local s1 = string.byte(Constant, ((i - 1) % #Constant) + 1)
        Encoded[i] = string.char(bit32.bxor((string.byte(Time, i) + i) % 256, s1))
    end
    return table.concat(Encoded)
end

-- Lookup only: the game pre-creates its own per-server parry remote.
-- Minting it via setfenv-spoofed Network.RemoteEvent trips BAC instantly.
local ParryRemote = nil; do
    local RemoteName = string.gsub(game.JobId, '-', '')
    local netFolder = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    ParryRemote = netFolder:WaitForChild("RE/" .. RemoteName, 15)
    if not ParryRemote then
        warn("[Sky] parry remote not present yet - blatant will idle until it replicates")
        task.spawn(function()
            ParryRemote = netFolder:WaitForChild("RE/" .. RemoteName, 60)
        end)
    end
end

local function Parry()
    -- Proven live path (SwordsController:700): ParryButtonPress (BindableEvent)
    -- :Fire() -> game fires ParryAttempt:FireServer() with no args.
    -- NOTE: old code called :FireServer() on the BindableEvent -> silent no-op.
    pcall(function()
        local pb = ReplicatedStorage.Remotes:FindFirstChild("ParryButtonPress")
        if pb then pb:Fire() end
    end)
    pcall(function()
        ReplicatedStorage.Remotes.ParryAttempt:FireServer()
        if ACHAOTICDATA.Config.ParrySettings.RemoveCooldown then
            ReplicatedStorage.Remotes.UnParry:FireServer()
            ReplicatedStorage.Remotes.ResetAbilityCooldown:FireServer()
            ReplicatedStorage.Remotes.EndCD:FireServer()
            ReplicatedStorage.Remotes.SecondaryEndCD:FireServer()
        end
    end)
    -- Hash fallback (looked-up RE/<jobid> remote, no minting). Kept for
    -- servers where the plain path is gated; guarded so a dead hash can't
    -- kill the parry above.
    pcall(function()
        if not ParryRemote then return end
        local PlayerPositions = {}
        for _, char in next, workspace.Alive:GetChildren() do
            if char:FindFirstChild('HumanoidRootPart') then
                PlayerPositions[char.Name] = char.HumanoidRootPart.Position
            end
        end
        local CameraCenter = Camera.ViewportSize / 2
        local CameraData = {CameraCenter.X, CameraCenter.Y}
        ParryRemote:FireServer(Hash1, Hash2, Hash3(), 0.025, Camera.CFrame, PlayerPositions, CameraData, false)
    end)
    ACHAOTICDATA.Global.PingStart = os.clock()
end
local ExecuteRemoteFireServer = function(ParryData)
    Parry()
end

local FireParry = function()
    local ParryMethod = ACHAOTICDATA.Config.ParrySettings.ParryMethod
    if ParryMethod == "Blatant" then
        local IsBlockLegit = true

        local LocalPlayer = ACHAOTICDATA.Player.LocalPlayer
        local Character = GetCharacter()
        if not Character then IsBlockLegit = false end
        if Character:GetAttribute("Stunned") then
            IsBlockLegit = false
        end
        local IsInLobbyTrainning = LocalPlayer:GetAttribute("LobbyTraining") and (Character.Parent == workspace.Dead and true or false)
        if Character.Parent ~= Workspace.Alive and not (ACHAOTICASSETS.DebugFlags.LobbyParry or (LocalPlayer:GetAttribute("LobbyParry") or IsInLobbyTrainning)) then
            IsBlockLegit = false
        end
        if Character:GetAttribute("DoNotParry") or Character:GetAttribute("ChargingAdrenaline") and LocalPlayer.Upgrades["Qi-Charge"].Value < 2 then
            IsBlockLegit = false
        end
        if LocalPlayer:GetAttribute("LobbyParry") and LocalPlayer:GetAttribute("InLobbyParryCooldown") then
            IsBlockLegit = false
        end

        local SafeModeEnabled = ACHAOTICDATA.Config.ParrySettings.SafeMode
        local ShouldExecuteRemoteFireServer = (IsBlockLegit and SafeModeEnabled) or not SafeModeEnabled
        if ShouldExecuteRemoteFireServer then
            -- GetParry_Data's return value is unused (ExecuteRemoteFireServer
            -- ignores it), but any error inside it silently kills the parry
            -- (F9 showed FIRING with Parry() never running). Never let it block.
            local okPD, ParryData = pcall(GetParry_Data, ACHAOTICDATA.Config.ParrySettings.ParryCurveDirection, IsInLobbyTrainning)
            if not okPD then ParryData = nil end
            ExecuteRemoteFireServer(ParryData)
        end
    elseif ParryMethod == "Legit" then
        local BlockButton = ACHAOTICDATA.Player.LocalPlayer.PlayerGui.Hotbar.Block
        firesignal(BlockButton.Activated)
    end

if ACHAOTICDATA.Global.Parries <= 1000 then
        ACHAOTICDATA.Global.Parries += 1
        task.delay(0.5, function()
            if ACHAOTICDATA.Global.Parries > 0 then
                ACHAOTICDATA.Global.Parries -= 1
            end
        end)
    end
end

do
    task.spawn(function()
        local Hotbar
        pcall(function()
            Hotbar = game.Players.LocalPlayer.PlayerGui:WaitForChild('Hotbar')
        end)
        if not Hotbar then
            return
        end
        local Block = Hotbar:WaitForChild('Block')
        local Gradient = Block:WaitForChild('UIGradient')
        local VisualCD = Hotbar:FindFirstChild('VisualCD')
        local SecondaryVisualCD = Hotbar:FindFirstChild('SecondaryVisualCD')
        while true do
            task.wait()
            pcall(function()
                Gradient.Offset = Vector2.new(0, 0.5)
                if VisualCD and VisualCD.Visible then
                    VisualCD.Visible = false
                end
                if SecondaryVisualCD and SecondaryVisualCD.Visible then
                    SecondaryVisualCD.Visible = false
                end
            end)
        end
    end)
end

do
    ACHAOTICDATA.Global.RealtimePing = 30
    ACHAOTICDATA.Global.PingStart = nil
    ACHAOTICDATA.Global.PingFresh = 0
    local PingEMA = 30
    task.spawn(function()
        while true do
            task.wait(0.1)
            local ok, Data = pcall(function()
                return Stats.Network.ServerStatsItem['Data Ping']:GetValue()
            end)
            if ok and type(Data) == 'number' and Data > 0 then
                PingEMA = (PingEMA * 0.7) + (Data * 0.3)
                if os.clock() - (ACHAOTICDATA.Global.PingFresh or 0) > 2 then
                    ACHAOTICDATA.Global.RealtimePing = math.clamp(PingEMA, 15, 400)
                end
            end
        end
    end)
    local okPS, PS = pcall(function()
        return ReplicatedStorage.Remotes.ParrySuccess
    end)
    if okPS and PS then
        PS.OnClientEvent:Connect(function()
            local Start = ACHAOTICDATA.Global.PingStart
            if Start then
                ACHAOTICDATA.Global.PingStart = nil
                local Measured = math.clamp((os.clock() - Start) * 1000, 15, 400)
                ACHAOTICDATA.Global.RealtimePing = Measured
                ACHAOTICDATA.Global.PingFresh = os.clock()
            end
        end)
    end
end

local function Get_Balls()
    local BallInstances = {}
    for _, Instance in pairs(ACHAOTICDATA.Balls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            table.insert(BallInstances, Instance)
        end
    end
    return BallInstances
end

local function GetTraining_Balls()
    local BallInstances = {}
    for _, Instance in pairs(Workspace:WaitForChild("TrainingBalls"):GetChildren()) do
        if Instance:GetAttribute("realBall") then
            table.insert(BallInstances, Instance)
        end
    end
    return BallInstances
end

local function GetLinear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local function IsBall_Curved(Ball, Ping, char)
    if not Ball then
        return false
    end

    local Zoomies = Ball:FindFirstChild("zoomies")

    if not Zoomies then
        return false
    end

    local velocity = Zoomies.VectorVelocity
    local ball_direction = velocity.Unit
    local direction = (char.PrimaryPart.Position - Ball.Position).Unit
    local dot = direction:Dot(ball_direction)
    local speed = velocity.Magnitude
    local speed_threshold = math.min(speed / 100, 40)
    local direction_difference = (ball_direction - velocity).Unit
    local direction_similarity = direction:Dot(direction_difference)
    local dot_difference = dot - direction_similarity
    local distance = (char.PrimaryPart.Position - Ball.Position).Magnitude
    local dot_threshold = 0.5 - (Ping / 1000)
    local reach_time = distance / speed - (Ping / 1000)
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.rad(math.asin(clamped_dot))

    ACHAOTICDATA.Parry[Ball].lerp_radians = GetLinear_Interpolation(ACHAOTICDATA.Parry[Ball].lerp_radians, radians, 0.8)
    if speed > 0 and reach_time > Ping / 10 then
        ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
    end

    if distance < ball_distance_threshold then
        return false
    end
    if dot_difference < dot_threshold then
        return true
    end
    if ACHAOTICDATA.Parry[Ball].lerp_radians < 0.018 then
        ACHAOTICDATA.Parry[Ball].last_warping = tick()
    end
    if (tick() - ACHAOTICDATA.Parry[Ball].last_warping) < (reach_time / 1.5) then
        return true
    end
    if (tick() - ACHAOTICDATA.Parry[Ball].curving) < (reach_time / 1.5) then
        return true
    end

    return dot < dot_threshold
end

local function GetClosest_Player()
    local closestPlayer = nil
    local closestDistance = math.huge
    local lpCharacter = GetCharacter()
    if not lpCharacter or not lpCharacter.PrimaryPart then
        return nil
    end

    for _, entity in ipairs(Workspace.Alive:GetChildren()) do
        if entity ~= lpCharacter and entity.PrimaryPart then
            local distance = (lpCharacter.PrimaryPart.Position - entity.PrimaryPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = entity
            end
        end
    end

    return closestPlayer, closestDistance
end        

local function MainConnection()
    if not GetCharacter() or not GetCharacter().PrimaryPart then
        return
    end
    local IsSpamming = ACHAOTICDATA.Config.AutoSpamParry.Spamming or ACHAOTICDATA.Config.ManualSpamParry.Spamming 
    do
        local BallsList = Get_Balls()
        if ACHAOTICDATA.Config.AutoParry.Enabled and not IsSpamming and not ACHAOTICDATA.Config.TriggerBot.Enabled then
            for _, Ball in pairs(BallsList) do
                if not Ball then
                end

if not ACHAOTICDATA.Parry[Ball] then
                    ACHAOTICDATA.Parry[Ball] = {
                        lastVelUnit = nil,
                        velHistory = {},
                        lerp_radians = 0,
                        last_warping = 0,
                        curving = tick(),
                        LastParry = 0,
                        LobbyParried = false,
                        LobbyLastParry = os.clock(),
                        FireGate = 0,
                        LobbyFireGate = 0,
                        TargetConn = Ball:GetAttributeChangedSignal('target'):Connect(function()
                            ACHAOTICDATA.Global.AutoParryParried = false
                            ACHAOTICDATA.Parry[Ball].FireGate = 0
                            ACHAOTICDATA.Parry[Ball].LobbyFireGate = 0
                        end)
                    }
                end

                local zoomies = Ball:FindFirstChild('zoomies')
                if not zoomies then
                    continue
                end

Ball:GetAttributeChangedSignal('target'):Once(function()
                    ACHAOTICDATA.Global.AutoParryParried = false
                end)

                local ball_target = Ball:GetAttribute('target')
                local velocity = zoomies.VectorVelocity
                local distance = (GetCharacter().PrimaryPart.Position - Ball.Position).Magnitude
                local ping = ACHAOTICDATA.Global.RealtimePing or 30
                local ping_threshold = math.clamp(ping / 10, 5, 17)
                local speed = velocity.Magnitude
                local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
                local speed_divisor = (2.4 + capped_speed_diff * 0.002) * ACHAOTICDATA.Config.ParrySettings.SpeedDivisorMultiplier
                local parry_accuracy = math.min(ping_threshold + math.max(speed / speed_divisor, 9.5), 48)
                local okC, curved = pcall(IsBall_Curved, Ball, ping, GetCharacter())
                curved = okC and curved or false

                ACHAOTICDATA.Global.AutoParryCurrentAccuracy = parry_accuracy

                if Ball:FindFirstChild('AeroDynamicSlashVFX') then
                    ACHAOTICDATA.Global.TornadoTime = tick()
                end

                if ACHAOTICASSETS.Runtime:FindFirstChild('Tornado') then
                    if (tick() - ACHAOTICDATA.Global.TornadoTime) < (ACHAOTICASSETS.Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
                    end
                end

                if Ball:FindFirstChild('ComboCounter') then continue end
                if GetCharacter().PrimaryPart:FindFirstChild('SingularityCape') then continue end
                if ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Enabled and ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Flag then continue end
                if ACHAOTICDATA.Config.ParrySettings.Detections.DeathSlashBall.Enabled and ACHAOTICDATA.Config.ParrySettings.Detections.DeathSlashBall.Flag then continue end
                if ACHAOTICDATA.Config.ParrySettings.Detections.TimeHole.Enabled and ACHAOTICDATA.Config.ParrySettings.Detections.TimeHole.Flag then continue end
                if ACHAOTICDATA.Config.AutoParry.AntiCurveEnabled and curved then continue end

                if getgenv().CooldownProtection then
                    local ok, ParryCD = pcall(function() return ACHAOTICDATA.Player.LocalPlayer.PlayerGui.Hotbar.Block.UIGradient end)
                    if ok and ParryCD and ParryCD.Offset.Y < 0.4 then
                        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                    end
                end

                if os.clock() - ACHAOTICDATA.Parry[Ball].FireGate < 0.15 then
                    continue
                end

                if ball_target == tostring(ACHAOTICDATA.Player.LocalPlayer) and distance <= parry_accuracy then
                    local parry_time = os.clock()
                    local time_view = parry_time - ACHAOTICDATA.Parry[Ball].LastParry
                    if time_view > 0.25 and ACHAOTICDATA.Config.AutoParry.AnimationFix and ACHAOTICDATA.Config.ParrySettings.ParryMethod ~= "Legit" then
                        PlayParry_Animation()
                    end
                    FireParry()
                    ACHAOTICDATA.Parry[Ball].LastParry = parry_time
                    ACHAOTICDATA.Parry[Ball].FireGate = parry_time
                end
            end
        else
            ACHAOTICDATA.Global.AutoParryCurrentAccuracy = 0
        end

        if ACHAOTICDATA.Config.LobbyAutoParry.Enabled then
            local LobbyBallsList = GetTraining_Balls()
            for _, Ball in pairs(LobbyBallsList) do
                if not Ball then
                    return
                end
                
                if not ACHAOTICDATA.Parry[Ball] then
                    ACHAOTICDATA.Parry[Ball] = {
                        lastVelUnit = nil,
                        velHistory = {},
                        lerp_radians = 0,
                        last_warping = 0,
                        curving = tick(),
                        LastParry = os.clock(),
                        LobbyParried = false,
                        LobbyLastParry = os.clock(),
                        FireGate = 0,
                        LobbyFireGate = 0,
                        TargetConn = Ball:GetAttributeChangedSignal('target'):Connect(function()
                            ACHAOTICDATA.Parry[Ball].LobbyParried = false
                            ACHAOTICDATA.Parry[Ball].FireGate = 0
                            ACHAOTICDATA.Parry[Ball].LobbyFireGate = 0
                        end)
                    }
                end
                
                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then
                    return
                end

                local Ball_Target = Ball:GetAttribute('target')
                local Velocity = Zoomies.VectorVelocity
                local Distance = (GetCharacter().PrimaryPart.Position - Ball.Position).Magnitude - 5
                local Ping = ACHAOTICDATA.Global.RealtimePing or 30
                local Ping_Threshold = math.clamp(Ping / 20, 5, 17)
                local Speed = Velocity.Magnitude * 1.5
                local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002
                local speed_divisor = speed_divisor_base * ACHAOTICDATA.Config.ParrySettings.LobbySpeedDivisorMultiplier
                local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5) + (Distance / 75)
                local Curved = false --IsBall_Curved(Ball, Ping, GetCharacter())

                local CurveVaildation = Curved and ACHAOTICDATA.Config.LobbyAutoParry.AntiCurveEnabled

                if os.clock() - ACHAOTICDATA.Parry[Ball].LobbyFireGate < 0.15 then
                    continue
                end

                if Ball_Target == tostring(ACHAOTICDATA.Player.LocalPlayer) and Distance <= Parry_Accuracy and not CurveVaildation then
                    local Parry_Time = os.clock()
                    local Time_View = Parry_Time - (ACHAOTICDATA.Parry[Ball].LobbyLastParry)
                    if Time_View > 0.25 and ACHAOTICDATA.Config.LobbyAutoParry.AnimationFix and ACHAOTICDATA.Config.ParrySettings.ParryMethod ~= "Legit" then
                        PlayParry_Animation()
                    end

                    FireParry()

                    ACHAOTICDATA.Parry[Ball].LobbyLastParry = Parry_Time
                    ACHAOTICDATA.Parry[Ball].LobbyFireGate = Parry_Time
                end
            end
        end

        if ACHAOTICDATA.Config.AutoSpamParry.Enabled then
            for _, Ball in pairs(BallsList) do
                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then 
                    ACHAOTICDATA.Config.AutoSpamParry.Spamming = false 
                    return 
                end

                local Closest_Entity, Closest_Distance = GetClosest_Player()
                local Root = GetCharacter() and GetCharacter().PrimaryPart
                
                if not Root then 
                    ACHAOTICDATA.Config.AutoSpamParry.Spamming = false 
                    return
                end
                
                if not Closest_Entity or not Closest_Entity.PrimaryPart then 
                    ACHAOTICDATA.Config.AutoSpamParry.Spamming = false 
                    return 
                end
                
                local Ping = ACHAOTICDATA.Global.RealtimePing or 30
                local PingFactor = Ping / 500
                local BallSpeed = Zoomies.VectorVelocity.Magnitude
                
                local TargetCheck = 30.3
                if Ping <= 0 or Ping >= 130 then
                    if Ping <= 131 or Ping >= 160 then
                        if Ping <= 161 or Ping >= 225 then
                            if Ping > 226 and Ping < 500 then
                                TargetCheck = math.clamp(math.floor(math.max(BallSpeed / 4 + PingFactor, 32.5)), 32.5, 80)
                            end
                        else
                            TargetCheck = math.clamp(math.floor(math.max(BallSpeed / 4.25 + PingFactor, 29.5)), 29.5, 70)
                        end
                    else
                        TargetCheck = math.clamp(math.floor(math.max(BallSpeed / 4.65 + PingFactor, 27.25)), 27.25, 70)
                    end
                else
                    TargetCheck = math.clamp(math.floor(math.max(BallSpeed / 5 + PingFactor, 26)), 26, 70)
                end
                
                local RootPos = Root.Position
                local BallPos = Ball.Position
                local TargetPos = Closest_Entity.PrimaryPart.Position
                
                local DistToBall = (RootPos - BallPos).Magnitude
                local DistToTarget = (RootPos - TargetPos).Magnitude
                
                ACHAOTICDATA.Global.AutoSpamParryCurrentAccuracy = TargetCheck * 1.5

                local SpamVaildation = false
                if ACHAOTICDATA.Config.AutoSpamParry.DetectionMode == "Speed" then
                    SpamVaildation = ACHAOTICDATA.Global.Parries > 1
                elseif ACHAOTICDATA.Config.AutoSpamParry.DetectionMode == "Distance" then
                    SpamVaildation = true
                end
                ACHAOTICDATA.Config.AutoSpamParry.Spamming =  DistToBall <= TargetCheck * 1.5 and DistToTarget <= TargetCheck and SpamVaildation
            end
        else
            ACHAOTICDATA.Config.AutoSpamParry.Spamming = false
            ACHAOTICDATA.Global.AutoSpamParryCurrentAccuracy = 0
        end

        if ACHAOTICDATA.Config.TriggerBot.Enabled and not IsSpamming then
            for _, Ball in pairs(BallsList) do
                if not Ball then continue end

                Ball:GetAttributeChangedSignal('target'):Once(function()
                    TriggerBotParried = false
                end)

                if TriggerBotParried then continue end

                local Ball_Target = Ball:GetAttribute('target')
                local Singularity_Cape = ACHAOTICDATA.Player.LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape')

                if Singularity_Cape then continue end
                if ACHAOTICDATA.Config.TriggerBot.InfinityDetection and ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Flag then continue end

                if Ball_Target == tostring(ACHAOTICDATA.Player.LocalPlayer) then
                    if ACHAOTICDATA.Config.TriggerBot.AnimationFix then
                        PlayParry_Animation()
                    end
                    FireParry()
                    TriggerBotParried = true
                end
            end
        end
        if #BallsList <= 0 then
            ACHAOTICDATA.Global.AutoSpamParryCurrentAccuracy = 0
        end
    end
end

NeverZen:Track(ACHAOTICDATA.Balls.ChildRemoved:Connect(function(Child)
    if ACHAOTICDATA.Parry[Child] then
        ACHAOTICDATA.Parry[Child].TargetConn:Disconnect()
        ACHAOTICDATA.Parry[Child] = nil
    end
    if Visuals.HitEffectService.BallEffects[Child] then
        local hit = Visuals.HitEffectService.BallEffects[Child]
        if hit and hit.Parent then hit:Destroy() end
        Visuals.HitEffectService.BallEffects[Child] = nil
    end
    ACHAOTICDATA.Global.Parries = 0
    ACHAOTICDATA.Config.Animation.SpamAnimationParries = 0
    ACHAOTICDATA.Config.AutoSpamParry.Spamming = false
    UI.BallStats.PeakSpeed = 0
end))

NeverZen:Track(Workspace:WaitForChild("TrainingBalls").ChildRemoved:Connect(function(Child)
    if ACHAOTICDATA.Parry[Child] then
        ACHAOTICDATA.Parry[Child].TargetConn:Disconnect()
        ACHAOTICDATA.Parry[Child] = nil
    end
    if Visuals.HitEffectService.BallEffects[Child] then
        local hit = Visuals.HitEffectService.BallEffects[Child]
        if hit and hit.Parent then hit:Destroy() end
        Visuals.HitEffectService.BallEffects[Child] = nil
    end
end))

local function MakeDraggable(Recv, update, speed)
    local dragToggle = nil
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(update, TweenInfo.new(speed), {Position = position}):Play()
    end

    Recv.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
            dragToggle = true
            dragStart = input.Position
            startPos = update.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    NeverZen:Track(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragToggle then
                updateInput(input)
            end
        end
    end))
end

function Visuals.VisualiserService:Enabled(value)
    if value then
        for _, VisualPart in pairs(Visuals.VisualParts) do
            VisualPart.Transparency = 0
        end
    else
        for _, VisualPart in pairs(Visuals.VisualParts) do
            VisualPart.Transparency = 1
        end
    end
end

function Visuals.VisualiserService:SetColor(color)
    for _, Part in pairs(Visuals.VisualParts) do
        TweenService:Create(Part, TweenInfo.new(0.2), {Color = color}):Play()
    end
end

function Visuals.VisualiserService:Update(hrp, position, size)
    local visualPart = Visuals.VisualParts[hrp]
    if visualPart and not visualPart.Parent then
        visualPart = nil
        Visuals.VisualParts[hrp] = nil
    end

    if not visualPart then
        local NewPart = Instance.new("Part")
        NewPart.Name = "VisualPart"
        NewPart.Anchored = true
        NewPart.CanCollide = false
        NewPart.CastShadow = false
        NewPart.Shape = Enum.PartType.Ball
        NewPart.Transparency = Visuals.VisualisersEnabled and 0 or 1
        NewPart.Material = Enum.Material.ForceField
        NewPart.Color = Color3.fromRGB(255, 255, 255)
        NewPart.Size = Vector3.new(size, size, size)
        NewPart.Parent = Workspace

        Visuals.VisualParts[hrp] = NewPart
        visualPart = NewPart
    end

    visualPart.Position = position
    if visualPart.Parent ~= Workspace then
        visualPart.Parent = Workspace
    end

    TweenService:Create(visualPart, TweenInfo.new(0.2), {Size = Vector3.new(size, size, size)}):Play()
end

function Visuals.HitEffectService:Emit(ball, position)
    if not Visuals.HitEffectService.BallEffects[ball] then
        local HitEffect = Instance.new("Attachment")
        local Arcs = Instance.new("ParticleEmitter")

        HitEffect.Name = "HitEffect"
        HitEffect.Parent = ball
        Arcs.Enabled = false
        Arcs.RotSpeed = NumberRange.new(250)
        Arcs.VelocitySpread = -360
        Arcs.Texture = "rbxassetid://8084911316"
        Arcs.ZOffset = 1
        Arcs.LightEmission = 1
        Arcs.Rotation = NumberRange.new(-360, 360)
        Arcs.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1, 0),
            NumberSequenceKeypoint.new(0.25, 0, 0),
            NumberSequenceKeypoint.new(0.75, 0, 0),
            NumberSequenceKeypoint.new(1, 1, 0)
        })
        Arcs.Name = "Arcs"
        Arcs.Lifetime = NumberRange.new(1)
        Arcs.Speed = NumberRange.new(math.random(1, 3))
        Arcs.SpreadAngle = Vector2.new(-360, 360)
        Arcs.Rate = 0
        Arcs.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
        Arcs.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 10, 0),
            NumberSequenceKeypoint.new(1, 10, 0)
        })

        Arcs.Parent = HitEffect
        Visuals.HitEffectService.BallEffects[ball] = HitEffect
    end

    local BallEffect = Visuals.HitEffectService.BallEffects[ball].Arcs
    BallEffect:Emit(1)
end

function ManualSpamParryUIService:Visible(value)
    UI.SpamUI.ScreenGui.Enabled = value
end

function ManualSpamParryUIService:SetColor(value)
    if value then
        local TargetColor = NeverZen.Theme.Hightlight
        local BackgroundColorTween = TweenService:Create(UI.SpamUI.SpamButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.SpamUI.SpamButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.SpamUI.SpamButton.Text = "SPAMMING"
    else
        local TargetColor = Color3.new(152/255, 152/255, 152/255)
        local BackgroundColorTween = TweenService:Create(UI.SpamUI.SpamButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.SpamUI.SpamButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.SpamUI.SpamButton.Text = "SPAM"
    end
end

function TriggerBotUIService:Visible(value)
    UI.TriggerBotUI.ScreenGui.Enabled = value
end

function TriggerBotUIService:SetColor(value)
    if value then
        local TargetColor = NeverZen.Theme.Hightlight
        local BackgroundColorTween = TweenService:Create(UI.TriggerBotUI.TriggerButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.TriggerBotUI.TriggerButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.TriggerBotUI.TriggerButton.Text = "TB ACTIVE"
    else
        local TargetColor = Color3.new(152/255, 152/255, 152/255)
        local BackgroundColorTween = TweenService:Create(UI.TriggerBotUI.TriggerButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.TriggerBotUI.TriggerButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.TriggerBotUI.TriggerButton.Text = "TRIGGER BOT"
    end
end

function ImmortalityUIService:Visible(value)
    if UI.ImmortalityUI.ScreenGui then
        UI.ImmortalityUI.ScreenGui.Enabled = value
    end
end

function ImmortalityUIService:SetColor(value)
    if value then
        local TargetColor = NeverZen.Theme.Hightlight
        local BackgroundColorTween = TweenService:Create(UI.ImmortalityButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.ImmortalityButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.ImmortalityButton.Text = "IMMO ACTIVE"
    else
        local TargetColor = Color3.new(152/255, 152/255, 152/255)
        local BackgroundColorTween = TweenService:Create(UI.ImmortalityButton, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor})
        local StrokeColorTween = TweenService:Create(UI.ImmortalityButton.UIStroke, TweenInfo.new(0.2), {Color = TargetColor})
        BackgroundColorTween:Play()
        StrokeColorTween:Play()
        UI.ImmortalityButton.Text = "Immortality"
    end
end

function BallStatsUIService:Visible(value)
    if UI.BallStats.ScreenGui then
        UI.BallStats.ScreenGui.Enabled = value
    end
end

function StatsUIService:Visible(value)
    if UI.StatsUI.ScreenGui then
        UI.StatsUI.ScreenGui.Enabled = value
    end
end

do
    UI.Window:AddLabel('General')

    local CombatTab = UI.Window:AddTab({
        Name = "Combat",
        Icon = "swords"
    })

    local VisualTab = UI.Window:AddTab({
        Name = "Visuals",
        Icon = "box"
    })

    local AutoParrySection = CombatTab:AddSection({
        Name = "Auto Parry",
        Position = "left"
    })

    local LobbyAutoParrySection = CombatTab:AddSection({
        Name = "Lobby Auto Parry",
        Position = "left"
    })

    local AutoSpamParrySection = CombatTab:AddSection({
        Name = "Auto Spam Parry [BETA]",
        Position = "right"
    })

    local ManualSpamParrySection = CombatTab:AddSection({
        Name = "Manual Spam Parry",
        Position = "right"
    })

    local TriggerBotSection = CombatTab:AddSection({
        Name = "Trigger Bot",
        Position = "left"
    })

    do
        UI.AutoParryToggle = AutoParrySection:AddToggle({
            Name = 'Enabled',
            Default = ACHAOTICDATA.Config.AutoParry.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.AutoParry.Enabled = value
            end,
        })

        AutoParrySection:AddSlider({
            Name = "Accuracy",
            Min = 0,
            Max = 100,
            Round = 1,
            Default = ACHAOTICDATA.Config.ParrySettings.AutoParryAccuracy,
            Type = "%",
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.SpeedDivisorMultiplier = 0.7 + (value - 0.8) * (0.35 / 99)
            end,
        })

        AutoParrySection:AddToggle({
            Name = 'Auto Accuracy',
            Default = ACHAOTICDATA.Config.ParrySettings.AutoParryAutoAccuracy,
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.AutoParryAutoAccuracy = value
            end,
        })

        AutoParrySection:AddKeybind({
            Name = "Keybind",
            Default = ACHAOTICDATA.Config.AutoParry.Keybind,
            Callback = function(key)
                ACHAOTICDATA.Config.AutoParry.Keybind = key
            end,
        })

        AutoParrySection:AddToggle({
            Name = 'Animation Fix',
            Default = ACHAOTICDATA.Config.AutoParry.AnimationFix,
            Callback = function(value)
                ACHAOTICDATA.Config.AutoParry.AnimationFix = value
            end,
        })

        AutoParrySection:AddDivider({
            Color = Color3.fromRGB(50, 50, 50),
            Height = 1
        })

        AutoParrySection:AddToggle({
            Name = 'Anti Curve',
            Default = ACHAOTICDATA.Config.AutoParry.AntiCurveEnabled,
            Callback = function(value)
                ACHAOTICDATA.Config.AutoParry.AntiCurveEnabled = value
            end,
        })

        AutoParrySection:AddDivider({
            Color = Color3.fromRGB(50, 50, 50),
            Height = 1
        })

        AutoParrySection:AddToggle({
            Name = 'Infinity Detection',
            Default = ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Enabled = value
            end,
        })

        AutoParrySection:AddToggle({
            Name = 'Death Slash Detection',
            Default = ACHAOTICDATA.Config.ParrySettings.Detections.DeathSlashBall.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.Detections.DeathSlashBall.Enabled = value
            end,
        })

        AutoParrySection:AddToggle({
            Name = 'Time Hole Detection',
            Default = ACHAOTICDATA.Config.ParrySettings.Detections.TimeHole.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.Detections.TimeHole.Enabled = value
            end,
        })

        AutoParrySection:AddDivider({
            Color = Color3.fromRGB(50, 50, 50),
            Height = 1
        })

        AutoParrySection:AddToggle({
            Name = 'Slashes of Fury Detection',
            Default = ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Enabled = value
            end,
        })

        AutoParrySection:AddSlider({
            Name = "Count",
            Min = 1,
            Max = 36,
            Round = 1,
            Default = ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionMaxParryCount,
            Type = "",
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionMaxParryCount = value
            end,
        })

        AutoParrySection:AddSlider({
            Name = "Delay",
            Min = 0,
            Max = 1,
            Round = 1,
            Default = ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionParryDelay,
            Type = "",
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionParryDelay = value
            end,
        })
    end

    do
        LobbyAutoParrySection:AddToggle({
            Name = 'Enabled',
            Default = ACHAOTICDATA.Config.LobbyAutoParry.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.LobbyAutoParry.Enabled = value
            end,
        })

        LobbyAutoParrySection:AddSlider({
            Name = "Accuracy",
            Min = 0,
            Max = 100,
            Round = 1,
            Default = ACHAOTICDATA.Config.ParrySettings.LobbyAutoParryAccuracy,
            Type = "%",
            Callback = function(value)
                ACHAOTICDATA.Config.ParrySettings.LobbySpeedDivisorMultiplier = 0.7 + (value - 0.8) * (0.35 / 99)
            end,
        })

        LobbyAutoParrySection:AddToggle({
            Name = 'Anti Curve',
            Default = ACHAOTICDATA.Config.LobbyAutoParry.AntiCurveEnabled,
            Callback = function(value)
                ACHAOTICDATA.Config.LobbyAutoParry.AntiCurveEnabled = value
            end,
        })

        LobbyAutoParrySection:AddToggle({
            Name = 'Animation Fix',
            Default = ACHAOTICDATA.Config.LobbyAutoParry.AnimationFix,
            Callback = function(value)
                ACHAOTICDATA.Config.LobbyAutoParry.AnimationFix = value
            end,
        })
    end
    
    do
        AutoSpamParrySection:AddToggle({
            Name = 'Enabled',
            Default = ACHAOTICDATA.Config.AutoSpamParry.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.AutoSpamParry.Enabled = value
            end,
        })

        AutoSpamParrySection:AddDropdown({
            Name = "Detection Mode",
            Default = ACHAOTICDATA.Config.AutoSpamParry.DetectionMode,
            Values = {"Distance", "Speed"},
            Callback = function(value)
                ACHAOTICDATA.Config.AutoSpamParry.DetectionMode = value
            end,
        })
        
        AutoSpamParrySection:AddToggle({
            Name = 'Animation Fix',
            Default = ACHAOTICDATA.Config.AutoSpamParry.AnimationFix,
            Callback = function(value)
                ACHAOTICDATA.Config.AutoSpamParry.AnimationFix = value
            end,
        })
    end 
    
    do
        UI.ManualSpamParryToggle = ManualSpamParrySection:AddToggle({
            Name = 'Active',
            Default = ACHAOTICDATA.Config.ManualSpamParry.Spamming,
            Callback = function(value)
                ACHAOTICDATA.Config.ManualSpamParry.Spamming = value
                ManualSpamParryUIService:SetColor(value)
            end,
        })

        ManualSpamParrySection:AddToggle({
            Name = 'UI',
            Default = ACHAOTICDATA.Config.ManualSpamParry.UI,
            Callback = function(value)
                ACHAOTICDATA.Config.ManualSpamParry.UI = value
                ManualSpamParryUIService:Visible(value)
            end,
        })

        ManualSpamParrySection:AddKeybind({
            Name = "Keybind",
            Default = ACHAOTICDATA.Config.ManualSpamParry.Keybind,
            Callback = function(key)
                ACHAOTICDATA.Config.ManualSpamParry.Keybind = key
            end,
        })

        ManualSpamParrySection:AddToggle({
            Name = 'Animation Fix',
            Default = ACHAOTICDATA.Config.ManualSpamParry.AnimationFix,
            Callback = function(value)
                ACHAOTICDATA.Config.ManualSpamParry.AnimationFix = value
            end,
        })
    end

    do
        UI.TriggerBotToggle = TriggerBotSection:AddToggle({
            Name = 'Active',
            Default = ACHAOTICDATA.Config.TriggerBot.Enabled,
            Callback = function(value)
                ACHAOTICDATA.Config.TriggerBot.Enabled = value
                TriggerBotUIService:SetColor(value)
            end,
        })

        TriggerBotSection:AddToggle({
            Name = 'UI',
            Default = ACHAOTICDATA.Config.TriggerBot.UI,
            Callback = function(value)
                ACHAOTICDATA.Config.TriggerBot.UI = value
                TriggerBotUIService:Visible(value)
            end,
        })

        TriggerBotSection:AddKeybind({
            Name = "Keybind",
            Default = ACHAOTICDATA.Config.TriggerBot.Keybind,
            Callback = function(key)
                ACHAOTICDATA.Config.TriggerBot.Keybind = key
            end,
        })

        TriggerBotSection:AddToggle({
            Name = 'Animation Fix',
            Default = ACHAOTICDATA.Config.TriggerBot.AnimationFix,
            Callback = function(value)
                ACHAOTICDATA.Config.TriggerBot.AnimationFix = value
            end,
        })

        TriggerBotSection:AddDivider({
            Color = Color3.fromRGB(50, 50, 50),
            Height = 1
        })

        TriggerBotSection:AddToggle({
            Name = 'Infinity Detection',
            Default = ACHAOTICDATA.Config.TriggerBot.InfinityDetection,
            Callback = function(value)
                ACHAOTICDATA.Config.TriggerBot.InfinityDetection = value
            end,
        })
    end

    local VisualiserSection = VisualTab:AddSection({
        Name = "Visualiser",
        Position = "left"
    })

    VisualiserSection:AddToggle({
        Name = 'Enabled',
        Default = Visuals.VisualisersEnabled,
        Callback = function(value)
            Visuals.VisualisersEnabled = value
            Visuals.VisualiserService:Enabled(value)
        end,
    })

    local EffectSection = VisualTab:AddSection({
        Name = "Effects",
        Position = "right"
    })

    EffectSection:AddToggle({
        Name = 'Hit Effect',
        Default = Visuals.HitEffectEnabled,
        Callback = function(value)
            Visuals.HitEffectEnabled = value
        end,
    })

    UI.Window:AddLabel('Miscellaneous')

    local ExclusiveTab = UI.Window:AddTab({
        Name = "Exclusive",
        Icon = "layers"
    })

    local AnimationDisablerSection = ExclusiveTab:AddSection({
        Name = "Animation Disabler",
        Position = "left"
    })

    AnimationDisablerSection:AddToggle({
        Name = 'Disable Parry Animation',
        Default = false,
        Callback = function(value)
            for _, v in pairs(ACHAOTICASSETS.SwordAPI.Collection:GetDescendants()) do
                if v.Name == "SuccessParry" then
                    v:SetAttribute("SuccessParry", not value)
                end
            end
        end,
    })

    AnimationDisablerSection:AddToggle({
        Name = 'Disable Grab Animation',
        Default = false,
        Callback = function(value)
            for _, v in pairs(ACHAOTICASSETS.SwordAPI.Collection:GetDescendants()) do
                if v.Name == "GrabParry" then
                    v:SetAttribute("GrabParry", not value)
                end
            end
        end,
    })

    local ImmortalitySection = ExclusiveTab:AddSection({
        Name = "Immortality",
        Position = "left"
    })

    UI.ImmortalityToggle = ImmortalitySection:AddToggle({
        Name = 'Enabled',
        Default = Immortality.Enabled,
        Callback = function(value)
            Immortality.Enabled = value
            if Immortality.SetDesyncHook then Immortality.SetDesyncHook(value) end
            ImmortalityUIService:SetColor(value)
        end,
    })

    ImmortalitySection:AddToggle({
        Name = 'Speed Bypass',
        Default = Immortality.SpeedBypassEnabled,
        Callback = function(value)
            Immortality.SpeedBypassEnabled = value
        end,
    })

    ImmortalitySection:AddToggle({
        Name = 'UI',
        Default = Immortality.UI,
        Callback = function(value)
            Immortality.UI = value
            ImmortalityUIService:Visible(value)
        end,
    })

    ImmortalitySection:AddSlider({
        Name = "Angle",
        Min = 0,
        Max = 100,
        Round = 1,
        Default = Immortality.Angle,
        Type = " degrees",
        Callback = function(value)
            Immortality.Angle = value
        end,
    })

    ImmortalitySection:AddSlider({
        Name = "Height",
        Min = 0,
        Max = 270,
        Round = 1,
        Default = Immortality.Height,
        Type = " studs",
        Callback = function(value)
            Immortality.Height = value
        end,
    })

    ImmortalitySection:AddSlider({
        Name = "Depth",
        Min = 0,
        Max = 8,
        Round = 1,
        Default = -Immortality.Depth,
        Type = " studs",
        Callback = function(value)
            Immortality.Depth = -value
        end,
    })

    ImmortalitySection:AddSlider({
        Name = "Radius",
        Min = 10,
        Max = 100,
        Round = 1,
        Default = Immortality.SquareRadius,
        Type = " studs",
        Callback = function(value)
            Immortality.SquareRadius = value
        end,
    })

    local OpitimizationSection = ExclusiveTab:AddSection({
        Name = "Optimization",
        Position = "left"
    })

    OpitimizationSection:AddToggle({
        Name = 'No Render',
        Default = Optimization.NoRenderEnabled,
        Callback = function(value)
            Optimization.NoRenderEnabled = value
        end,
    })

    OpitimizationSection:AddToggle({
        Name = 'Hide Server Rendering',
        Default = Optimization.HideServerRendering,
        Callback = function(value)
            Optimization.HideServerRendering = value
        end,
    })

    local StatsSection = ExclusiveTab:AddSection({
        Name = "Stats",
        Position = "right"
    })

    StatsSection:AddToggle({
        Name = 'Ball Stats',
        Default = ACHAOTICDATA.Config.BallStats.Enabled,
        Callback = function(value)
            ACHAOTICDATA.Config.BallStats.Enabled = value
            BallStatsUIService:Visible(value)
        end,
    })

    StatsSection:AddToggle({
        Name = 'Client Stats',
        Default = ACHAOTICDATA.Config.ClientStats.Enabled,
        Callback = function(value)
            ACHAOTICDATA.Config.ClientStats.Enabled = value
            StatsUIService:Visible(value)
        end,
    })

    local skinChangerSection = ExclusiveTab:AddSection({
        Name = "Skin Changer [BETA]",
        Position = "right"
    })

    skinChangerSection:AddToggle({
        Name = 'Enabled',
        Default = SkinChanger.Enabled,
        Callback = function(value)
            SkinChanger.Enabled = value
            if SkinChanger.System.ApplyHooks then SkinChanger.System.ApplyHooks(value) end
            if SkinChanger.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 2
    })

    skinChangerSection:AddToggle({
        Name = 'Change Model',
        Default = SkinChanger.Targets.SwordModel.Enabled,
        Callback = function(value)
            SkinChanger.Targets.SwordModel.Enabled = value
            if SkinChanger.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddInput({
        Name = "Model",
        Default = "",
        Callback = function(value)
            SkinChanger.Targets.SwordModel.ModelName = value
            if SkinChanger.Enabled and SkinChanger.Targets.SwordModel.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 1
    })

    skinChangerSection:AddToggle({
        Name = 'Change Animations',
        Default = SkinChanger.Targets.SwordAnimation.Enabled,
        Callback = function(value)
            SkinChanger.Targets.SwordAnimation.Enabled = value
            if SkinChanger.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddInput({
        Name = "Animation",
        Default = "",
        Callback = function(value)
            SkinChanger.Targets.SwordAnimation.AnimationName = value
            if SkinChanger.Enabled and SkinChanger.Targets.SwordAnimation.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 1
    })

    skinChangerSection:AddToggle({
        Name = 'Change FX',
        Default = SkinChanger.Targets.SwordFX.Enabled,
        Callback = function(value)
            SkinChanger.Targets.SwordFX.Enabled = value
        end,
    })

    skinChangerSection:AddInput({
        Name = "FX",
        Default = "",
        Callback = function(value)
            SkinChanger.Targets.SwordFX.FXName = value
            if SkinChanger.Enabled and SkinChanger.Targets.SwordFX.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    skinChangerSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 2
    })

    skinChangerSection:AddButton({
        Name = "Refresh Skin",
        Callback = function()
            if SkinChanger.Enabled then
                SkinChanger.System.functions.updateSword(SkinChanger.Targets.SwordModel.ModelName)
            end
        end,
    })

    local SettingsTab = UI.Window:AddTab({
        Name = "Settings",
        Icon = "settings"
    })

    local SpammingSection = SettingsTab:AddSection({
        Name = "Spamming",
        Position = "left"
    })

    UI.SpamLoopRPSLabel = SpammingSection:AddLabel("Loop RPS: 0")
    UI.SpamAccumulatorLabel = SpammingSection:AddLabel("Accumulator: 0")
    
    SpammingSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 1
    })

SpammingSection:AddSlider({
        Name = "Target RPS",
        Min = 60,
        Max = 2000,
        Round = 1,
        Default = ACHAOTICDATA.Config.ParrySettings.SpammingRPS,
        Type = " rps",
        Callback = function(value)
            ACHAOTICDATA.Config.ParrySettings.SpammingRPS = value
        end,
    })

    SpammingSection:AddButton({
        Name = "Reset Accumulator",
        Callback = function()
            ResetAccumulator()
        end,
    })

    local ParrySystemSection = SettingsTab:AddSection({
        Name = "Parry System",
        Position = "right"
    })

    ParrySystemSection:AddDropdown({
        Name = "Method",
        Default = ACHAOTICDATA.Config.ParrySettings.ParryMethod,
        Values = {"Legit", "Blatant"},
        Callback = function(value)
            ACHAOTICDATA.Config.ParrySettings.ParryMethod = value
        end,
    })

    ParrySystemSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 2
    })

    ParrySystemSection:AddButton({
        Name = "Refetch function",
        Callback = function()
            NZNotification.new("Sky", "Attempting to re-fetch parry function, might cause a possible freeze", 5)
            local Result = AttemptFunctionFetch()
            ParryDATA.ParryFunction = Result.ParryFunction
            ParryDATA.ParryRemote = Result.ParryRemote

            if ParryDATA.ParryFunction and ParryDATA.ParryRemote then
                NZNotification.new('Sky', 'Successfully fetched game data.', 5)
            else 
                NZNotification.new('Sky', 'Failed to fetch game data, please check developer console.', 5)
            end
        end,
    })

    ParrySystemSection:AddDivider({
        Color = Color3.fromRGB(50, 50, 50),
        Height = 1
    })

    ParrySystemSection:AddDropdown({
        Name = "Curve Direction",
        Default = ACHAOTICDATA.Config.ParrySettings.ParryCurveDirection,
        Values = {"Camera", "Straight", "Up", "Down", "Left", "Right", "Backward", "Accelerate", "Decelerate", "Random"},
        Callback = function(value)
            ACHAOTICDATA.Config.ParrySettings.ParryCurveDirection = value
        end,
    })

    ParrySystemSection:AddToggle({
        Name = 'Safe Mode',
        Default = ACHAOTICDATA.Config.ParrySettings.SafeMode,
        Callback = function(value)
            ACHAOTICDATA.Config.ParrySettings.SafeMode = value
        end,
    })

    ParrySystemSection:AddToggle({
        Name = 'Remove Cooldown (risk)',
        Default = ACHAOTICDATA.Config.ParrySettings.RemoveCooldown,
        Callback = function(value)
            ACHAOTICDATA.Config.ParrySettings.RemoveCooldown = value
        end,
    })

    local AnimationFixSection = SettingsTab:AddSection({
        Name = "Animation Fix",
        Position = "left"
    })

    AnimationFixSection:AddSlider({
        Name = "Max Rate",
        Min = 30,
        Max = 240,
        Round = 1,
        Default = AnimationFixService.Rate,
        Type = " FPS",
        Callback = function(value)
            AnimationFixService.Rate = value
        end,
    })

    AnimationFixSection:AddToggle({
        Name = 'Spam FE',
        Default = AnimationFixService.FEMode,
        Callback = function(value)
            AnimationFixService.FEMode = value
        end,
    })

    local MaintenceSection = SettingsTab:AddSection({
        Name = "Maintenance",
        Position = "right"
    })

    MaintenceSection:AddButton({
        Name = "Clear Cache",
        Callback = function()
            ClearCache()
        end,
    })    
    
    MaintenceSection:AddButton({
        Name = "Unload",
        Callback = function()
            UnloadACHT()
        end,
    })    
end

do
    UI.SpamUI.ScreenGui = Instance.new("ScreenGui")
    UI.SpamUI.ScreenGui.Name = "ScreenGui"
    UI.SpamUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.SpamUI.ScreenGui.ResetOnSpawn = false
    UI.SpamUI.ScreenGui.IgnoreGuiInset = true
    UI.SpamUI.ScreenGui.Parent = (gethui and gethui()) or CoreGui

    NeverZen.ProtectGui(UI.SpamUI.ScreenGui)

    UI.SpamUI.Handler = Instance.new("CanvasGroup")
    UI.SpamUI.Handler.Name = "Handler"
    UI.SpamUI.Handler.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.SpamUI.Handler.Size = UDim2.new(0, 140, 0, 80)
    UI.SpamUI.Handler.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.SpamUI.Handler.BackgroundTransparency = 1
    UI.SpamUI.Handler.BorderSizePixel = 0
    UI.SpamUI.Handler.BorderColor3 = Color3.new(0, 0, 0)
    UI.SpamUI.Handler.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.SpamUI.Handler.Transparency = 1
    UI.SpamUI.Handler.ClipsDescendants = true
    UI.SpamUI.Handler.Active = true
    UI.SpamUI.Handler.Parent = UI.SpamUI.ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.Name = "UICorner"
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = UI.SpamUI.Handler

    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Name = "ButtonFrame"
    ButtonFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    ButtonFrame.Size = UDim2.new(1, 0, 1, 0)
    ButtonFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
    ButtonFrame.BackgroundTransparency = 0.1
    ButtonFrame.BorderSizePixel = 0
    ButtonFrame.BorderColor3 = Color3.new(0, 0, 0)
    ButtonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ButtonFrame.Transparency = 0.1
    ButtonFrame.Parent = UI.SpamUI.Handler

    UI.SpamUI.SpamButton = Instance.new("TextButton")
    UI.SpamUI.SpamButton.Name = "SpamButton"
    UI.SpamUI.SpamButton.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.SpamUI.SpamButton.Size = UDim2.new(1, -15, 1, -15)
    UI.SpamUI.SpamButton.BackgroundColor3 = Color3.new(152/255, 152/255, 152/255)
    UI.SpamUI.SpamButton.BackgroundTransparency = 0.75
    UI.SpamUI.SpamButton.BorderSizePixel = 0
    UI.SpamUI.SpamButton.BorderColor3 = Color3.new(0, 0, 0)
    UI.SpamUI.SpamButton.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.SpamUI.SpamButton.TextTransparency = 0.25
    UI.SpamUI.SpamButton.Text = "SPAM"
    UI.SpamUI.SpamButton.TextColor3 = Color3.new(1, 1, 1)
    UI.SpamUI.SpamButton.TextSize = 18
    UI.SpamUI.SpamButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    UI.SpamUI.SpamButton.TextScaled = false
    UI.SpamUI.SpamButton.TextWrapped = true
    UI.SpamUI.SpamButton.Parent = ButtonFrame

    local UICorner2 = Instance.new("UICorner")
    UICorner2.Name = "UICorner"
    UICorner2.CornerRadius = UDim.new(0, 2)
    UICorner2.Parent = UI.SpamUI.SpamButton

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Name = "UIStroke"
    UIStroke.Color = Color3.new(152/255, 152/255, 152/255)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = UI.SpamUI.SpamButton

    local UIStroke2 = Instance.new("UIStroke")
    UIStroke2.Name = "UIStroke"
    UIStroke2.Color = Color3.new(0, 0.0980392, 0.133333)
    UIStroke2.Transparency = 0.85
    UIStroke2.Parent = UI.SpamUI.Handler

    local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
    UIAspectRatioConstraint.AspectRatio = 2
    UIAspectRatioConstraint.Parent = UI.SpamUI.Handler

    local function ToggleSpam()
        ACHAOTICDATA.Config.ManualSpamParry.Spamming = not ACHAOTICDATA.Config.ManualSpamParry.Spamming
        UI.ManualSpamParryToggle:SetValue(ACHAOTICDATA.Config.ManualSpamParry.Spamming)
        ManualSpamParryUIService:SetColor(ACHAOTICDATA.Config.ManualSpamParry.Spamming)
    end

    UI.SpamUI.SpamButton.MouseButton1Click:Connect(ToggleSpam)
    MakeDraggable(UI.SpamUI.Handler, UI.SpamUI.Handler, 0.2)
end

do 
    UI.TriggerBotUI.ScreenGui = Instance.new("ScreenGui")
    UI.TriggerBotUI.ScreenGui.Name = "TriggerScreenGui"
    UI.TriggerBotUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.TriggerBotUI.ScreenGui.ResetOnSpawn = false
    UI.TriggerBotUI.ScreenGui.IgnoreGuiInset = true
    UI.TriggerBotUI.ScreenGui.Parent = (gethui and gethui()) or CoreGui

    NeverZen.ProtectGui(UI.TriggerBotUI.ScreenGui)

    UI.TriggerBotUI.Handler = Instance.new("CanvasGroup")
    UI.TriggerBotUI.Handler.Name = "TriggerHandler"
    UI.TriggerBotUI.Handler.Position = UDim2.new(0.3, 0, 0.5, 0)
    UI.TriggerBotUI.Handler.Size = UDim2.new(0, 140, 0, 80)
    UI.TriggerBotUI.Handler.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.TriggerBotUI.Handler.BackgroundTransparency = 1
    UI.TriggerBotUI.Handler.BorderSizePixel = 0
    UI.TriggerBotUI.Handler.BorderColor3 = Color3.new(0, 0, 0)
    UI.TriggerBotUI.Handler.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.TriggerBotUI.Handler.Transparency = 1
    UI.TriggerBotUI.Handler.ClipsDescendants = true
    UI.TriggerBotUI.Handler.Active = true
    UI.TriggerBotUI.Handler.Parent = UI.TriggerBotUI.ScreenGui

    local UICornerTrigger = Instance.new("UICorner")
    UICornerTrigger.Name = "UICorner"
    UICornerTrigger.CornerRadius = UDim.new(0, 4)
    UICornerTrigger.Parent = UI.TriggerBotUI.Handler

    local TriggerButtonFrame = Instance.new("Frame")
    TriggerButtonFrame.Name = "TriggerButtonFrame"
    TriggerButtonFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TriggerButtonFrame.Size = UDim2.new(1, 0, 1, 0)
    TriggerButtonFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
    TriggerButtonFrame.BackgroundTransparency = 0.1
    TriggerButtonFrame.BorderSizePixel = 0
    TriggerButtonFrame.BorderColor3 = Color3.new(0, 0, 0)
    TriggerButtonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    TriggerButtonFrame.Transparency = 0.1
    TriggerButtonFrame.Parent = UI.TriggerBotUI.Handler

    UI.TriggerBotUI.TriggerButton = Instance.new("TextButton")
    UI.TriggerBotUI.TriggerButton.Name = "TriggerButton"
    UI.TriggerBotUI.TriggerButton.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.TriggerBotUI.TriggerButton.Size = UDim2.new(1, -15, 1, -15)
    UI.TriggerBotUI.TriggerButton.BackgroundColor3 = Color3.new(152/255, 152/255, 152/255)
    UI.TriggerBotUI.TriggerButton.BackgroundTransparency = 0.75
    UI.TriggerBotUI.TriggerButton.BorderSizePixel = 0
    UI.TriggerBotUI.TriggerButton.BorderColor3 = Color3.new(0, 0, 0)
    UI.TriggerBotUI.TriggerButton.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.TriggerBotUI.TriggerButton.TextTransparency = 0.25
    UI.TriggerBotUI.TriggerButton.Text = "TRIGGER BOT"
    UI.TriggerBotUI.TriggerButton.TextColor3 = Color3.new(1, 1, 1)
    UI.TriggerBotUI.TriggerButton.TextSize = 18
    UI.TriggerBotUI.TriggerButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    UI.TriggerBotUI.TriggerButton.TextScaled = false
    UI.TriggerBotUI.TriggerButton.TextWrapped = true
    UI.TriggerBotUI.TriggerButton.Parent = TriggerButtonFrame

    local UICornerTrigger2 = Instance.new("UICorner")
    UICornerTrigger2.Name = "UICorner"
    UICornerTrigger2.CornerRadius = UDim.new(0, 2)
    UICornerTrigger2.Parent = UI.TriggerBotUI.TriggerButton

    local UIStrokeTrigger = Instance.new("UIStroke")
    UIStrokeTrigger.Name = "UIStroke"
    UIStrokeTrigger.Color = Color3.new(152/255, 152/255, 152/255)
    UIStrokeTrigger.Transparency = 0.5
    UIStrokeTrigger.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStrokeTrigger.Parent = UI.TriggerBotUI.TriggerButton

    local UIStrokeTrigger2 = Instance.new("UIStroke")
    UIStrokeTrigger2.Name = "UIStroke"
    UIStrokeTrigger2.Color = Color3.new(0, 0.0980392, 0.133333)
    UIStrokeTrigger2.Transparency = 0.85
    UIStrokeTrigger2.Parent = UI.TriggerBotUI.Handler

    local UIAspectRatioConstraintTrigger = Instance.new("UIAspectRatioConstraint")
    UIAspectRatioConstraintTrigger.Name = "UIAspectRatioConstraint"
    UIAspectRatioConstraintTrigger.AspectRatio = 2
    UIAspectRatioConstraintTrigger.Parent = UI.TriggerBotUI.Handler

    local function ToggleTriggerBot()
        ACHAOTICDATA.Config.TriggerBot.Enabled = not ACHAOTICDATA.Config.TriggerBot.Enabled
        UI.TriggerBotToggle:SetValue(ACHAOTICDATA.Config.TriggerBot.Enabled)
        TriggerBotUIService:SetColor(ACHAOTICDATA.Config.TriggerBot.Enabled)
    end

    UI.TriggerBotUI.TriggerButton.MouseButton1Click:Connect(ToggleTriggerBot)
    MakeDraggable(UI.TriggerBotUI.Handler, UI.TriggerBotUI.Handler, 0.2)
end

do
    UI.ImmortalityUI.ScreenGui = Instance.new("ScreenGui")
    UI.ImmortalityUI.ScreenGui.Name = "ImmortalityScreenGui"
    UI.ImmortalityUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.ImmortalityUI.ScreenGui.ResetOnSpawn = false
    UI.ImmortalityUI.ScreenGui.IgnoreGuiInset = true
    UI.ImmortalityUI.ScreenGui.Parent = (gethui and gethui()) or CoreGui

    NeverZen.ProtectGui(UI.ImmortalityUI.ScreenGui)

    UI.ImmortalityUI.Handler = Instance.new("CanvasGroup")
    UI.ImmortalityUI.Handler.Name = "ImmortalityHandler"
    UI.ImmortalityUI.Handler.Position = UDim2.new(0.1, 0, 0.5, 0)
    UI.ImmortalityUI.Handler.Size = UDim2.new(0, 140, 0, 80)
    UI.ImmortalityUI.Handler.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.ImmortalityUI.Handler.BackgroundTransparency = 1
    UI.ImmortalityUI.Handler.BorderSizePixel = 0
    UI.ImmortalityUI.Handler.BorderColor3 = Color3.new(0, 0, 0)
    UI.ImmortalityUI.Handler.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.ImmortalityUI.Handler.Transparency = 1
    UI.ImmortalityUI.Handler.ClipsDescendants = true
    UI.ImmortalityUI.Handler.Active = true
    UI.ImmortalityUI.Handler.Parent = UI.ImmortalityUI.ScreenGui

    local UICornerImm = Instance.new("UICorner")
    UICornerImm.Name = "UICorner"
    UICornerImm.CornerRadius = UDim.new(0, 4)
    UICornerImm.Parent = UI.ImmortalityUI.Handler

    local ImmButtonFrame = Instance.new("Frame")
    ImmButtonFrame.Name = "ImmButtonFrame"
    ImmButtonFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    ImmButtonFrame.Size = UDim2.new(1, 0, 1, 0)
    ImmButtonFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
    ImmButtonFrame.BackgroundTransparency = 0.1
    ImmButtonFrame.BorderSizePixel = 0
    ImmButtonFrame.BorderColor3 = Color3.new(0, 0, 0)
    ImmButtonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ImmButtonFrame.Transparency = 0.1
    ImmButtonFrame.Parent = UI.ImmortalityUI.Handler

    UI.ImmortalityButton = Instance.new("TextButton")
    UI.ImmortalityButton.Name = "ImmortalityButton"
    UI.ImmortalityButton.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.ImmortalityButton.Size = UDim2.new(1, -15, 1, -15)
    UI.ImmortalityButton.BackgroundColor3 = Color3.new(152/255, 152/255, 152/255)
    UI.ImmortalityButton.BackgroundTransparency = 0.75
    UI.ImmortalityButton.BorderSizePixel = 0
    UI.ImmortalityButton.BorderColor3 = Color3.new(0, 0, 0)
    UI.ImmortalityButton.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.ImmortalityButton.TextTransparency = 0.25
    UI.ImmortalityButton.Text = "Immortality"
    UI.ImmortalityButton.TextColor3 = Color3.new(1, 1, 1)
    UI.ImmortalityButton.TextSize = 18
    UI.ImmortalityButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    UI.ImmortalityButton.TextScaled = false
    UI.ImmortalityButton.TextWrapped = true
    UI.ImmortalityButton.Parent = ImmButtonFrame

    local UICornerImm2 = Instance.new("UICorner")
    UICornerImm2.Name = "UICorner"
    UICornerImm2.CornerRadius = UDim.new(0, 2)
    UICornerImm2.Parent = UI.ImmortalityButton

    local UIStrokeImm = Instance.new("UIStroke")
    UIStrokeImm.Name = "UIStroke"
    UIStrokeImm.Color = Color3.new(152/255, 152/255, 152/255)
    UIStrokeImm.Transparency = 0.5
    UIStrokeImm.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStrokeImm.Parent = UI.ImmortalityButton

    local UIStrokeImm2 = Instance.new("UIStroke")
    UIStrokeImm2.Name = "UIStroke"
    UIStrokeImm2.Color = Color3.new(0, 0.0980392, 0.133333)
    UIStrokeImm2.Transparency = 0.85
    UIStrokeImm2.Parent = UI.ImmortalityUI.Handler

    local UIAspectImm = Instance.new("UIAspectRatioConstraint")
    UIAspectImm.Name = "UIAspectRatioConstraint"
    UIAspectImm.AspectRatio = 2
    UIAspectImm.Parent = UI.ImmortalityUI.Handler

    local function ToggleImmortality()
        Immortality.Enabled = not Immortality.Enabled
        UI.ImmortalityToggle:SetValue(Immortality.Enabled)
        ImmortalityUIService:SetColor(Immortality.Enabled)
    end

    UI.ImmortalityButton.MouseButton1Click:Connect(ToggleImmortality)
    MakeDraggable(UI.ImmortalityUI.Handler, UI.ImmortalityUI.Handler, 0.2)
end

do
    UI.BallStats.ScreenGui = Instance.new("ScreenGui")
    UI.BallStats.ScreenGui.Name = "BallStatsUI"
    UI.BallStats.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.BallStats.ScreenGui.ResetOnSpawn = false
    UI.BallStats.ScreenGui.IgnoreGuiInset = true
    UI.BallStats.ScreenGui.Enabled = false
    UI.BallStats.ScreenGui.Parent = (gethui and gethui()) or CoreGui

    NeverZen.ProtectGui(UI.BallStats.ScreenGui)

    UI.BallStats.Handler = Instance.new("CanvasGroup")
    UI.BallStats.Handler.Name = "Handler"
    UI.BallStats.Handler.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.BallStats.Handler.Size = UDim2.new(0, 170, 0, 90)
    UI.BallStats.Handler.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.BallStats.Handler.BackgroundTransparency = 1
    UI.BallStats.Handler.BorderSizePixel = 0
    UI.BallStats.Handler.BorderColor3 = Color3.new(0, 0, 0)
    UI.BallStats.Handler.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.BallStats.Handler.ClipsDescendants = true
    UI.BallStats.Handler.Active = true
    UI.BallStats.Handler.Parent = UI.BallStats.ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.Name = "UICorner"
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = UI.BallStats.Handler

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.BorderColor3 = Color3.new(0, 0, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Parent = UI.BallStats.Handler

    local LabelFrame = Instance.new("Frame")
    LabelFrame.Name = "LabelFrame"
    LabelFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    LabelFrame.Size = UDim2.new(1, -15, 1, -15)
    LabelFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    LabelFrame.BackgroundTransparency = 1
    LabelFrame.BorderSizePixel = 0
    LabelFrame.BorderColor3 = Color3.new(0, 0, 0)
    LabelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    LabelFrame.Parent = MainFrame

    local Speed = Instance.new("Frame")
    Speed.Name = "Speed"
    Speed.Size = UDim2.new(1, 0, 0.5, 0)
    Speed.BackgroundColor3 = Color3.new(1, 1, 1)
    Speed.BackgroundTransparency = 1
    Speed.BorderSizePixel = 0
    Speed.BorderColor3 = Color3.new(0, 0, 0)
    Speed.Parent = LabelFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Position = UDim2.new(0.5, 0, 0, 10)
    Title.Size = UDim2.new(1, 0, 0, 10)
    Title.BackgroundColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.BorderSizePixel = 0
    Title.BorderColor3 = Color3.new(0, 0, 0)
    Title.AnchorPoint = Vector2.new(0.5, 0.5)
    Title.Text = "CURRENT SPEED"
    Title.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title.TextSize = 14
    Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Speed

    UI.BallStats.SpeedValue = Instance.new("TextLabel")
    UI.BallStats.SpeedValue.Name = "Value"
    UI.BallStats.SpeedValue.Position = UDim2.new(0.5, 0, 1, 0)
    UI.BallStats.SpeedValue.Size = UDim2.new(1, 0, 0, 20)
    UI.BallStats.SpeedValue.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.BallStats.SpeedValue.BackgroundTransparency = 1
    UI.BallStats.SpeedValue.BorderSizePixel = 0
    UI.BallStats.SpeedValue.BorderColor3 = Color3.new(0, 0, 0)
    UI.BallStats.SpeedValue.AnchorPoint = Vector2.new(0.5, 1)
    UI.BallStats.SpeedValue.Text = "0"
    UI.BallStats.SpeedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.BallStats.SpeedValue.TextSize = 20
    UI.BallStats.SpeedValue.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.BallStats.SpeedValue.TextXAlignment = Enum.TextXAlignment.Left
    UI.BallStats.SpeedValue.Parent = Speed

    local PeakSpeed = Instance.new("Frame")
    PeakSpeed.Name = "PeakSpeed"
    PeakSpeed.Position = UDim2.new(0, 0, 0.5, 0)
    PeakSpeed.Size = UDim2.new(1, 0, 0.5, 0)
    PeakSpeed.BackgroundColor3 = Color3.new(1, 1, 1)
    PeakSpeed.BackgroundTransparency = 1
    PeakSpeed.BorderSizePixel = 0
    PeakSpeed.BorderColor3 = Color3.new(0, 0, 0)
    PeakSpeed.Parent = LabelFrame

    UI.BallStats.PeakSpeedValue = Instance.new("TextLabel")
    UI.BallStats.PeakSpeedValue.Name = "Value"
    UI.BallStats.PeakSpeedValue.Position = UDim2.new(0.5, 0, 1, 0)
    UI.BallStats.PeakSpeedValue.Size = UDim2.new(1, 0, 0, 20)
    UI.BallStats.PeakSpeedValue.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.BallStats.PeakSpeedValue.BackgroundTransparency = 1
    UI.BallStats.PeakSpeedValue.BorderSizePixel = 0
    UI.BallStats.PeakSpeedValue.BorderColor3 = Color3.new(0, 0, 0)
    UI.BallStats.PeakSpeedValue.AnchorPoint = Vector2.new(0.5, 1)
    UI.BallStats.PeakSpeedValue.Text = "0"
    UI.BallStats.PeakSpeedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.BallStats.PeakSpeedValue.TextSize = 20
    UI.BallStats.PeakSpeedValue.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.BallStats.PeakSpeedValue.TextXAlignment = Enum.TextXAlignment.Left
    UI.BallStats.PeakSpeedValue.Parent = PeakSpeed

    local Title2 = Instance.new("TextLabel")
    Title2.Name = "Title"
    Title2.Position = UDim2.new(0.5, 0, 0, 10)
    Title2.Size = UDim2.new(1, 0, 0, 10)
    Title2.BackgroundColor3 = Color3.new(1, 1, 1)
    Title2.BackgroundTransparency = 1
    Title2.BorderSizePixel = 0
    Title2.BorderColor3 = Color3.new(0, 0, 0)
    Title2.AnchorPoint = Vector2.new(0.5, 0.5)
    Title2.Text = "PEAK SPEED"
    Title2.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title2.TextSize = 14
    Title2.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title2.TextXAlignment = Enum.TextXAlignment.Left
    Title2.Parent = PeakSpeed

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Name = "UIStroke"
    UIStroke.Color = Color3.new(0, 0.0980392, 0.133333)
    UIStroke.Transparency = 0.85
    UIStroke.Parent = UI.BallStats.Handler

    MakeDraggable(UI.BallStats.Handler, UI.BallStats.Handler, 0.2)
end

do
    UI.StatsUI.ScreenGui = Instance.new("ScreenGui")
    UI.StatsUI.ScreenGui.Name = "StatsUI"
    UI.StatsUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.StatsUI.ScreenGui.ResetOnSpawn = false
    UI.StatsUI.ScreenGui.IgnoreGuiInset = true
    UI.StatsUI.ScreenGui.Enabled = false
    UI.StatsUI.ScreenGui.Parent = (gethui and gethui()) or CoreGui

    NeverZen.ProtectGui(UI.StatsUI.ScreenGui)

    UI.StatsUI.Handler = Instance.new("CanvasGroup")
    UI.StatsUI.Handler.Name = "Handler"
    UI.StatsUI.Handler.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.StatsUI.Handler.Size = UDim2.new(0, 327, 0, 45)
    UI.StatsUI.Handler.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.Handler.BackgroundTransparency = 1
    UI.StatsUI.Handler.BorderSizePixel = 0
    UI.StatsUI.Handler.BorderColor3 = Color3.new(0, 0, 0)
    UI.StatsUI.Handler.AnchorPoint = Vector2.new(0.5, 0.5)
    UI.StatsUI.Handler.ClipsDescendants = true
    UI.StatsUI.Handler.Active = true
    UI.StatsUI.Handler.Parent = UI.StatsUI.ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.Name = "UICorner"
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = UI.StatsUI.Handler

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Color3.new(0.0470588, 0.0470588, 0.0470588)
    MainFrame.BackgroundTransparency = 0.10000000149011612
    MainFrame.BorderSizePixel = 0
    MainFrame.BorderColor3 = Color3.new(0, 0, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Parent = UI.StatsUI.Handler

    local LabelFrame = Instance.new("Frame")
    LabelFrame.Name = "LabelFrame"
    LabelFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    LabelFrame.Size = UDim2.new(1, -15, 1, -15)
    LabelFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    LabelFrame.BackgroundTransparency = 1
    LabelFrame.BorderSizePixel = 0
    LabelFrame.BorderColor3 = Color3.new(0, 0, 0)
    LabelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    LabelFrame.Parent = MainFrame

    local FPS = Instance.new("Frame")
    FPS.Name = "FPS"
    FPS.Position = UDim2.new(0, 0, 0.5, 0)
    FPS.Size = UDim2.new(0, 78, 1, 0)
    FPS.BackgroundColor3 = Color3.new(1, 1, 1)
    FPS.BackgroundTransparency = 1
    FPS.BorderSizePixel = 0
    FPS.BorderColor3 = Color3.new(0, 0, 0)
    FPS.AnchorPoint = Vector2.new(0, 0.5)
    FPS.Parent = LabelFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Position = UDim2.new(0.5, 0, 0, 0)
    Title.Size = UDim2.new(1, 0, 0, 10)
    Title.BackgroundColor3 = Color3.new(1, 1, 1)
    Title.BackgroundTransparency = 1
    Title.BorderSizePixel = 0
    Title.BorderColor3 = Color3.new(0, 0, 0)
    Title.AnchorPoint = Vector2.new(0.5, 0)
    Title.Text = "FPS"
    Title.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title.TextSize = 12
    Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = FPS

    UI.StatsUI.States.FPS = Instance.new("TextLabel")
    UI.StatsUI.States.FPS.Name = "Value"
    UI.StatsUI.States.FPS.Position = UDim2.new(0.5, 0, 1, 0)
    UI.StatsUI.States.FPS.Size = UDim2.new(1, 0, 0, 20)
    UI.StatsUI.States.FPS.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.FPS.BackgroundTransparency = 1
    UI.StatsUI.States.FPS.BorderSizePixel = 0
    UI.StatsUI.States.FPS.BorderColor3 = Color3.new(0, 0, 0)
    UI.StatsUI.States.FPS.AnchorPoint = Vector2.new(0.5, 1)
    UI.StatsUI.States.FPS.Text = "0"
    UI.StatsUI.States.FPS.TextColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.FPS.TextSize = 17
    UI.StatsUI.States.FPS.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.StatsUI.States.FPS.TextXAlignment = Enum.TextXAlignment.Left
    UI.StatsUI.States.FPS.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.StatsUI.States.FPS.Parent = FPS

    local PING = Instance.new("Frame")
    PING.Name = "PING"
    PING.Position = UDim2.new(0.5, 0, 0.5, 0)
    PING.Size = UDim2.new(0, 78, 1, 0)
    PING.BackgroundColor3 = Color3.new(1, 1, 1)
    PING.BackgroundTransparency = 1
    PING.BorderSizePixel = 0
    PING.BorderColor3 = Color3.new(0, 0, 0)
    PING.AnchorPoint = Vector2.new(0, 0.5)
    PING.Parent = LabelFrame

    local Title2 = Instance.new("TextLabel")
    Title2.Name = "Title"
    Title2.Position = UDim2.new(0.5, 0, 0, 0)
    Title2.Size = UDim2.new(1, 0, 0, 10)
    Title2.BackgroundColor3 = Color3.new(1, 1, 1)
    Title2.BackgroundTransparency = 1
    Title2.BorderSizePixel = 0
    Title2.BorderColor3 = Color3.new(0, 0, 0)
    Title2.AnchorPoint = Vector2.new(0.5, 0)
    Title2.Text = "PING"
    Title2.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title2.TextSize = 12
    Title2.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title2.TextXAlignment = Enum.TextXAlignment.Left
    Title2.Parent = PING

    UI.StatsUI.States.PING = Instance.new("TextLabel")
    UI.StatsUI.States.PING.Name = "Value"
    UI.StatsUI.States.PING.Position = UDim2.new(0.5, 0, 1, 0)
    UI.StatsUI.States.PING.Size = UDim2.new(1, 0, 0, 20)
    UI.StatsUI.States.PING.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.PING.BackgroundTransparency = 1
    UI.StatsUI.States.PING.BorderSizePixel = 0
    UI.StatsUI.States.PING.BorderColor3 = Color3.new(0, 0, 0)
    UI.StatsUI.States.PING.AnchorPoint = Vector2.new(0.5, 1)
    UI.StatsUI.States.PING.Text = "0ms"
    UI.StatsUI.States.PING.TextColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.PING.TextSize = 17
    UI.StatsUI.States.PING.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.StatsUI.States.PING.TextXAlignment = Enum.TextXAlignment.Left
    UI.StatsUI.States.PING.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.StatsUI.States.PING.Parent = PING

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Name = "UIListLayout"
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = LabelFrame

    local CPU = Instance.new("Frame")
    CPU.Name = "CPU"
    CPU.Position = UDim2.new(0, 0, 0.5, 0)
    CPU.Size = UDim2.new(0, 78, 1, 0)
    CPU.BackgroundColor3 = Color3.new(1, 1, 1)
    CPU.BackgroundTransparency = 1
    CPU.BorderSizePixel = 0
    CPU.BorderColor3 = Color3.new(0, 0, 0)
    CPU.AnchorPoint = Vector2.new(0, 0.5)
    CPU.Parent = LabelFrame

    local Title3 = Instance.new("TextLabel")
    Title3.Name = "Title"
    Title3.Position = UDim2.new(0.5, 0, 0, 0)
    Title3.Size = UDim2.new(1, 0, 0, 10)
    Title3.BackgroundColor3 = Color3.new(1, 1, 1)
    Title3.BackgroundTransparency = 1
    Title3.BorderSizePixel = 0
    Title3.BorderColor3 = Color3.new(0, 0, 0)
    Title3.AnchorPoint = Vector2.new(0.5, 0)
    Title3.Text = "CPU"
    Title3.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title3.TextSize = 12
    Title3.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title3.TextXAlignment = Enum.TextXAlignment.Left
    Title3.Parent = CPU

    UI.StatsUI.States.CPU = Instance.new("TextLabel")
    UI.StatsUI.States.CPU.Name = "Value"
    UI.StatsUI.States.CPU.Position = UDim2.new(0.5, 0, 1, 0)
    UI.StatsUI.States.CPU.Size = UDim2.new(1, 0, 0, 20)
    UI.StatsUI.States.CPU.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.CPU.BackgroundTransparency = 1
    UI.StatsUI.States.CPU.BorderSizePixel = 0
    UI.StatsUI.States.CPU.BorderColor3 = Color3.new(0, 0, 0)
    UI.StatsUI.States.CPU.AnchorPoint = Vector2.new(0.5, 1)
    UI.StatsUI.States.CPU.Text = "0%"
    UI.StatsUI.States.CPU.TextColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.CPU.TextSize = 17
    UI.StatsUI.States.CPU.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.StatsUI.States.CPU.TextXAlignment = Enum.TextXAlignment.Left
    UI.StatsUI.States.CPU.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.StatsUI.States.CPU.Parent = CPU

    local MEMORY = Instance.new("Frame")
    MEMORY.Name = "MEMORY"
    MEMORY.Position = UDim2.new(0.5, 0, 0.5, 0)
    MEMORY.Size = UDim2.new(0, 78, 1, 0)
    MEMORY.BackgroundColor3 = Color3.new(1, 1, 1)
    MEMORY.BackgroundTransparency = 1
    MEMORY.BorderSizePixel = 0
    MEMORY.BorderColor3 = Color3.new(0, 0, 0)
    MEMORY.AnchorPoint = Vector2.new(0, 0.5)
    MEMORY.Parent = LabelFrame

    local Title4 = Instance.new("TextLabel")
    Title4.Name = "Title"
    Title4.Position = UDim2.new(0.5, 0, 0, 0)
    Title4.Size = UDim2.new(1, 0, 0, 10)
    Title4.BackgroundColor3 = Color3.new(1, 1, 1)
    Title4.BackgroundTransparency = 1
    Title4.BorderSizePixel = 0
    Title4.BorderColor3 = Color3.new(0, 0, 0)
    Title4.AnchorPoint = Vector2.new(0.5, 0)
    Title4.Text = "MEMORY"
    Title4.TextColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    Title4.TextSize = 12
    Title4.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    Title4.TextXAlignment = Enum.TextXAlignment.Left
    Title4.Parent = MEMORY

    UI.StatsUI.States.MEMORY = Instance.new("TextLabel")
    UI.StatsUI.States.MEMORY.Name = "Value"
    UI.StatsUI.States.MEMORY.Position = UDim2.new(0.5, 0, 1, 0)
    UI.StatsUI.States.MEMORY.Size = UDim2.new(1, 0, 0, 20)
    UI.StatsUI.States.MEMORY.BackgroundColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.MEMORY.BackgroundTransparency = 1
    UI.StatsUI.States.MEMORY.BorderSizePixel = 0
    UI.StatsUI.States.MEMORY.BorderColor3 = Color3.new(0, 0, 0)
    UI.StatsUI.States.MEMORY.AnchorPoint = Vector2.new(0.5, 1)
    UI.StatsUI.States.MEMORY.Text = "2300mb"
    UI.StatsUI.States.MEMORY.TextColor3 = Color3.new(1, 1, 1)
    UI.StatsUI.States.MEMORY.TextSize = 17
    UI.StatsUI.States.MEMORY.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
    UI.StatsUI.States.MEMORY.TextXAlignment = Enum.TextXAlignment.Left
    UI.StatsUI.States.MEMORY.TextYAlignment = Enum.TextYAlignment.Bottom
    UI.StatsUI.States.MEMORY.Parent = MEMORY

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Name = "UIStroke"
    UIStroke.Color = Color3.new(0, 0.0980392, 0.133333)
    UIStroke.Transparency = 0.85
    UIStroke.Parent = UI.StatsUI.Handler

    MakeDraggable(UI.StatsUI.Handler, UI.StatsUI.Handler, 0.2)
end

NeverZen:Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == ACHAOTICDATA.Config.AutoParry.Keybind then
        ACHAOTICDATA.Config.AutoParry.Enabled = not ACHAOTICDATA.Config.AutoParry.Enabled
        UI.AutoParryToggle:SetValue(ACHAOTICDATA.Config.AutoParry.Enabled)
    end
    if input.KeyCode == ACHAOTICDATA.Config.ManualSpamParry.Keybind then
        ACHAOTICDATA.Config.ManualSpamParry.Spamming = not ACHAOTICDATA.Config.ManualSpamParry.Spamming
        UI.ManualSpamParryToggle:SetValue(ACHAOTICDATA.Config.ManualSpamParry.Spamming)
    end
    if input.KeyCode == ACHAOTICDATA.Config.TriggerBot.Keybind then
        ACHAOTICDATA.Config.TriggerBot.Enabled = not ACHAOTICDATA.Config.TriggerBot.Enabled
        UI.TriggerBotToggle:SetValue(ACHAOTICDATA.Config.TriggerBot.Enabled)
    end
end))

do
    local DesyncTypes = {}

    NeverZen:Track(RunService.Heartbeat:Connect(function()
        if Immortality.Enabled and GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart") then
            if Immortality.SpeedBypassEnabled then  
                setfflag("S2PhysicsSenderRate", "1333335")
            end
            local hrp = GetCharacter().HumanoidRootPart
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.01, 0)
            DesyncTypes[1] = hrp.CFrame
            DesyncTypes[2] = hrp.AssemblyLinearVelocity

            local currentTime = tick()
            local CalculatedAngle = currentTime * math.pi * 2 * Immortality.Angle / 5
            local CalculatedCycle = math.floor(currentTime * 29) % 2
            local CalculatedYOffset = (CalculatedCycle == 0) and Immortality.Depth or Immortality.Height

            local Calculatedoffset = Vector3.new(
                math.cos(CalculatedAngle) * Immortality.SquareRadius,
                CalculatedYOffset,
                math.sin(CalculatedAngle) * Immortality.SquareRadius
            )

            local TargetCFrame = DesyncTypes[1] + Calculatedoffset

            hrp.CFrame = TargetCFrame
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

            RunService.RenderStepped:Wait()

            hrp.CFrame = DesyncTypes[1]
            hrp.AssemblyLinearVelocity = DesyncTypes[2]
        end
    end))

    -- Lazy desync hook: installing hookmetamethod at load trips BAC's
    -- metatable integrity heartbeat (~20s). Installed only while
    -- Immortality is on; pristine __index restored when turned off.
    Immortality.DesyncHooked = false
    Immortality.DesyncOldIndex = nil
    Immortality.SetDesyncHook = function(on)
        if on and not Immortality.DesyncHooked then
            Immortality.DesyncHooked = true
            Immortality.DesyncOldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if Immortality.Enabled and not checkcaller() then
                    if key == "CFrame" and GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart") then
                        if self == GetCharacter().HumanoidRootPart then
                            return DesyncTypes[1] or CFrame.new()
                        elseif self == GetCharacter():FindFirstChild("Head") then
                            return DesyncTypes[1] and DesyncTypes[1] + Vector3.new(0, GetCharacter().HumanoidRootPart.Size / 2 + 0.5, 0) or CFrame.new()
                        end
                    end
                end
                local old = Immortality.DesyncOldIndex
                return old(self, key)
            end))
        elseif not on and Immortality.DesyncHooked then
            Immortality.DesyncHooked = false
            local old = Immortality.DesyncOldIndex
            Immortality.DesyncOldIndex = nil
            if old then pcall(hookmetamethod, game, "__index", old) end
        end
    end
end

do 
    do
        do
            SkinChanger.System.OriginalSetSword = ACHAOTICASSETS.SwordController.SetSword
            SkinChanger.System.PatchedSetSword = function(self, anim)
                if SkinChanger.Enabled and SkinChanger.Targets.SwordAnimation.Enabled and SkinChanger.Targets.SwordAnimation.AnimationName and SkinChanger.Targets.SwordAnimation.AnimationName ~= "" then
                    anim = SkinChanger.Targets.SwordAnimation.AnimationName
                end
                return SkinChanger.System.OriginalSetSword(self, anim)
            end
        end
        do 
            SkinChanger.System.OriginalEquipSwordTo = ACHAOTICASSETS.swordInstances.EquipSwordTo
            SkinChanger.System.PatchedEquipSwordTo = function(self, char, swordName)
                if SkinChanger.Enabled and SkinChanger.Targets.SwordModel.Enabled and SkinChanger.Targets.SwordModel.ModelName and SkinChanger.Targets.SwordModel.ModelName ~= "" and char == GetCharacter() then
                    swordName = SkinChanger.Targets.SwordModel.ModelName
                end
                return SkinChanger.System.OriginalEquipSwordTo(self, char, swordName)
            end
        end
    end

    -- Game mutations (module patches + connection Disables) install ONLY
    -- while SkinChanger is on. Doing them at load trips BAC integrity sweeps.
    SkinChanger.System.ApplyHooks = function(on)
        if on then
            ACHAOTICASSETS.SwordController.SetSword = SkinChanger.System.PatchedSetSword
            ACHAOTICASSETS.swordInstances.EquipSwordTo = SkinChanger.System.PatchedEquipSwordTo
            for _, v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
                if v.Function and debug.getinfo(v.Function).name == "parrySuccessAll" then
                    SkinChanger.System.parrySuccessAllConnection = v
                    SkinChanger.System.playParryFunc = v.Function
                    print("[ACHAOTIC]:[DEBUG] Found parrySuccessAll connection")
                    v:Disable()
                    break
                end
            end
            for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
                if v.Function and debug.getinfo(v.Function).name == "parrySuccessAll" then
                    SkinChanger.System.parrySuccessClientConnection = v
                    print("[Sky]:[DEBUG] Found parrySuccessClient connection")
                    v:Disable()
                end
            end
        else
            if SkinChanger.System.OriginalSetSword then
                ACHAOTICASSETS.SwordController.SetSword = SkinChanger.System.OriginalSetSword
            end
            if SkinChanger.System.OriginalEquipSwordTo then
                ACHAOTICASSETS.swordInstances.EquipSwordTo = SkinChanger.System.OriginalEquipSwordTo
            end
            if SkinChanger.System.parrySuccessAllConnection then
                pcall(function() SkinChanger.System.parrySuccessAllConnection:Enable() end)
            end
            if SkinChanger.System.parrySuccessClientConnection then
                pcall(function() SkinChanger.System.parrySuccessClientConnection:Enable() end)
            end
        end
    end

    NeverZen:Track(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
        if not SkinChanger.System.playParryFunc then
            return
        end

        local args = {...}
        if Optimization.NoRenderEnabled then
            args[1] = nil
            args[3] = nil
            return SkinChanger.System.playParryFunc(unpack(args))
        end
        if tostring(args[4]) ~= ACHAOTICDATA.Player.LocalPlayer.Name then
            SkinChanger.System.lastOtherParryTimestamp = tick()
        elseif SkinChanger.Enabled and SkinChanger.Targets.SwordFX.Enabled and SkinChanger.Targets.SwordFX.FXName and SkinChanger.Targets.SwordFX.FXName ~= "" then
            if SkinChanger.System.SlashName then
                args[1] = SkinChanger.System.SlashName
            end
            args[3] = SkinChanger.Targets.SwordFX.FXName
        end
        return SkinChanger.System.playParryFunc(unpack(args))
    end))
end

do
    NeverZen:Track(ACHAOTICASSETS.Runtime.ChildAdded:Connect(function(child)
        if Optimization.HideServerRendering then
            Debris:AddItem(child, 0)
        end
    end))
end

do 
    NeverZen:Track(ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_, value)
        ACHAOTICDATA.Config.ParrySettings.Detections.DeathSlashBall.Flag = value
    end))

    NeverZen:Track(ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_, value)
        ACHAOTICDATA.Config.ParrySettings.Detections.InfinityBall.Flag = value
    end))

    NeverZen:Track(ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(_, value)
        ACHAOTICDATA.Config.ParrySettings.Detections.TimeHole.Flag = value
    end))

    NeverZen:Track(ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args = {...}
        local player = args[1]
        
        if player == ACHAOTICDATA.Player.LocalPlayer or player == ACHAOTICDATA.Player.LocalPlayer.Name or (player and player.Name == ACHAOTICDATA.Player.LocalPlayer.Name) then
            ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Flag = true
            ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Count = 0
        end
    end))

    NeverZen:Track(ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Flag = false
        ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Count = 0
    end))

    NeverZen:Track(ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function()
        ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Count = ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Count + 1
    end))

    NeverZen:Track(ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
        task.spawn(function()
            while ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Flag and ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Count < ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionMaxParryCount do
                if ACHAOTICDATA.Config.ParrySettings.Detections.SlashesofFury.Enabled then
                    FireParry()
                    task.wait(ACHAOTICDATA.Config.ParrySettings.SlashesofFuryDetectionParryDelay)
                else
                    break
                end
            end
        end)
    end))
end

    -- Connection Disables moved into SkinChanger.System.ApplyHooks above
    -- (runs only while SkinChanger is on).

NeverZen:Track(ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if ACHAOTICDATA.Config.Animation.SpamAnimationParries < 5 then
        ACHAOTICDATA.Config.Animation.SpamAnimationParries += 1
        task.delay(0.05, function()
            if ACHAOTICDATA.Config.Animation.SpamAnimationParries > 0 then
                ACHAOTICDATA.Config.Animation.SpamAnimationParries -= 1
            end
        end)
    end

    if ACHAOTICDATA.Config.ParrySettings.VisualiserParries < 10 then
        ACHAOTICDATA.Config.ParrySettings.VisualiserParries += 1
        task.delay(0.25, function()
            if ACHAOTICDATA.Config.ParrySettings.VisualiserParries > 0 then
                ACHAOTICDATA.Config.ParrySettings.VisualiserParries -= 1
            end
        end)
    end
    
    SpamAnimationFixBypass = true
    local humanoid = GetHumanoid()
    if humanoid and ACHAOTICDATA.Config.ParrySettings.ParryMethod ~= "Legit" then
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Name == "GrabParry" or track.Name == "Grab" then
                if not ACHAOTICDATA.Config.Animation.AnimationSpammingMode and not AnimationFixService.FEMode then
                    track.TimePosition = 0
                end
                StopAnimation(track)
            end
        end
    end
    
    if Visuals.HitEffectEnabled then
        for _, Ball in pairs(Get_Balls()) do
            Visuals.HitEffectService:Emit(Ball, Ball.Position)
        end
    end
end))

local LastIteration = 0
local FrameUpdateTable = {}
local FpsStart = os.clock()

local function RefreshVM(deltaTime)
    ACHAOTICDATA.Config.Animation.AnimationSpammingMode = ACHAOTICDATA.Config.Animation.SpamAnimationParries > 1
    
    if Visuals.VisualisersEnabled then
        if GetCharacter() and GetCharacter():FindFirstChild("HumanoidRootPart") then
            local char = GetCharacter()
            local hrp = char.HumanoidRootPart
            local isclashing = ACHAOTICDATA.Config.AutoSpamParry.Spamming or ACHAOTICDATA.Config.ManualSpamParry.Spamming
            local color = isclashing and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
            local size = (isclashing and 40 + ACHAOTICDATA.Config.ParrySettings.VisualiserParries or math.clamp(ACHAOTICDATA.Global.AutoParryCurrentAccuracy, 10, 220))
            Visuals.VisualiserService:SetColor(color)
            Visuals.VisualiserService:Update(char, hrp.Position, size)
        end
    end

    if ACHAOTICDATA.Config.BallStats.Enabled then
        local BallsList = Get_Balls()
        local BallSpeed = 0
        for _, Ball in pairs(BallsList) do
            if Ball then
                local CacheSpeed = Ball.AssemblyLinearVelocity.Magnitude
                BallSpeed = CacheSpeed
                if CacheSpeed > UI.BallStats.PeakSpeed then
                    UI.BallStats.PeakSpeed = CacheSpeed
                end
                break
            end
        end
        UI.BallStats.SpeedValue.Text = tostring(math.floor(BallSpeed))
        UI.BallStats.PeakSpeedValue.Text = tostring(math.floor(UI.BallStats.PeakSpeed))
    end

    if ACHAOTICDATA.Config.ClientStats.Enabled then
        local Fps = 0
        local Ping = 0
        local Cpu = 0
        local Memory = 0
        
        do
            LastIteration = os.clock()
            for Index = #FrameUpdateTable, 1, -1 do
                FrameUpdateTable[Index + 1] = FrameUpdateTable[Index] >= LastIteration - 1 and FrameUpdateTable[Index] or nil
            end

            FrameUpdateTable[1] = LastIteration
            Fps = (math.floor(os.clock() - FpsStart >= 1 and #FrameUpdateTable or #FrameUpdateTable / (os.clock() - FpsStart)))
        end

Ping = ACHAOTICDATA.Global.RealtimePing or 30
        Memory = Stats:GetTotalMemoryUsageMb()
        Cpu = math.clamp(Memory / 50, 1, 100)

        UI.StatsUI.States.FPS.Text = tostring(math.floor(Fps))
        UI.StatsUI.States.PING.Text = string.format("%sms", tostring(math.floor(Ping)))
        UI.StatsUI.States.CPU.Text = tostring(math.floor(Cpu)).. "%"
        UI.StatsUI.States.MEMORY.Text = string.format("%smb", tostring(math.floor(Memory)))
    end
end

local RequestSpamParry = function()
    do
        Debug.Spamming.RepeatedAmount += 1
        if tick() - Debug.Spamming.LastRepeat > 1 then
            Debug.Spamming.LastRepeat = tick()
            Debug.Spamming.Speed = Debug.Spamming.RepeatedAmount
            UI.SpamLoopRPSLabel:SetValue(string.format("Loop RPS: %d", Debug.Spamming.Speed))
            Debug.Spamming.RepeatedAmount = 0
        end
    end
    if ACHAOTICDATA.Config.AutoSpamParry.Spamming or ACHAOTICDATA.Config.ManualSpamParry.Spamming then  
        FireParry()
        if (ACHAOTICDATA.Config.AutoSpamParry.AnimationFix and ACHAOTICDATA.Config.AutoSpamParry.Spamming) or (ACHAOTICDATA.Config.ManualSpamParry.AnimationFix and ACHAOTICDATA.Config.ManualSpamParry.Spamming) and ACHAOTICDATA.Config.ParrySettings.ParryMethod ~= "Legit" then
            SpamParry_Animation()
        end
    end
end

local function LoopConnection(deltaTime)
    pcall(MainConnection)
    RefreshVM(deltaTime)
end

do
    local timeAccumulator = 0
    NeverZen:Track(RunService.RenderStepped:Connect(function(deltaTime)
        local TargetSpeed = ACHAOTICDATA.Config.ParrySettings.SpammingRPS
        timeAccumulator += deltaTime
        UI.SpamAccumulatorLabel:SetValue(string.format("Accumulator: %.3f", timeAccumulator))
        local packetsToFire = math.floor(timeAccumulator * TargetSpeed)
        if packetsToFire > 0 then
            timeAccumulator -= (packetsToFire / TargetSpeed)
            for _=1, packetsToFire do
                RequestSpamParry()
            end
        end
    end))
    ResetAccumulator = function()
        timeAccumulator = 0
    end
end

ManualSpamParryUIService:Visible(ACHAOTICDATA.Config.ManualSpamParry.UI)
TriggerBotUIService:Visible(ACHAOTICDATA.Config.TriggerBot.UI)
ImmortalityUIService:Visible(Immortality.UI)

NeverZen:Track(RunService.Heartbeat:Connect(LoopConnection))

ClearCache = function()
    AnimationFixService.Cache = {}
    NZNotification.new('Sky ', 'Cleared internal caches.', 5)
end

UnloadACHT = function()
    NeverZen:Unload()
    local ACHTConfig = ACHAOTICDATA.Config
    ACHTConfig.AutoParry.Enabled = false
    ACHTConfig.ManualSpamParry.Spamming = false
    ACHTConfig.TriggerBot.Enabled = false
    ACHTConfig.AutoSpamParry.Enabled = false
    Immortality.Enabled = false
    if Immortality.SetDesyncHook then Immortality.SetDesyncHook(false) end
    if SkinChanger.System.ApplyHooks then SkinChanger.System.ApplyHooks(false) end
    Visuals.VisualiserService:ClearAll()
    SkinChanger.Enabled = false
    SkinChanger.System.parrySuccessAllConnection:Enable()
    SkinChanger.System.parrySuccessClientConnection:Enable()
    UI.StatsUI.ScreenGui:Destroy()
    UI.BallStats.ScreenGui:Destroy()
    UI.SpamUI.ScreenGui:Destroy()
    UI.TriggerBotUI.ScreenGui:Destroy()
    UI.ImmortalityUI.ScreenGui:Destroy()

    NeverZen:Unload()
end

NeverZen:Track(ACHAOTICDATA.Player.LocalPlayer.CharacterAdded:Connect(function()
    Visuals.VisualiserService:ClearAll()
    task.delay(1.5, function()
        if SkinChanger.Targets.SwordModel.Enabled and SkinChanger.Targets.SwordModel.ModelName and SkinChanger.Targets.SwordModel.ModelName ~= "" then
            SkinChanger.System.functions.setSword()
        end
    end)
end))

NZNotification.new('Sky', 'Loaded.', 10)
