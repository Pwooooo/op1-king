-- Sky Linoria lib: drop-in replacement for NeverZen_lib.lua (drain water UI subset).
-- Same module shape the drain main expects:
--   NeverZen.new({Name, Keybind}) -> Window:AddTab({Name}) ->
--   Tab:AddSection({Name, Position}) -> Section:AddToggle/AddSlider/AddButton/AddLabel
-- Backed by Linoria (mstudio45). Game logic files need ZERO changes.
-- Overwrite NeverZen_lib.lua on GitHub with this file; the HttpGet URL stays the same.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua"))()

local NeverZen = { Version = "linoria-1" }

local __uid = 0
local function __nextId(name)
    __uid = __uid + 1
    local clean = tostring(name or "el"):gsub("%W", "")
    if clean == "" then clean = "el" end
    return "Sky_" .. clean .. "_" .. __uid
end

function NeverZen.new(config)
    config = config or {}

    local Window = Library:CreateWindow({
        Title = tostring(config.Name or "Sky"),
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2,
        -- OS cursor: this setup's Drawing renders nothing, so Linoria's
        -- triangle would hide the cursor with no replacement.
        ShowCustomCursor = false,
    })
    Library.ShowCustomCursor = false
    pcall(function()
        game:GetService("UserInputService").MouseIconEnabled = true
    end)

    -- Sky blackout to match the old NeverZen theme
    pcall(function()
        Library.BackgroundColor = Color3.fromRGB(12, 12, 12)
        Library.MainColor = Color3.fromRGB(20, 20, 20)
        Library.AccentColor = Color3.fromRGB(200, 215, 230)
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library.OutlineColor = Color3.fromRGB(40, 40, 40)
        Library.FontColor = Color3.fromRGB(255, 255, 255)
        Library:UpdateColorsUsingRegistry()
    end)

    -- NeverZen-style toggle key (default LeftControl), same as before
    local bindKey = config.Keybind or Enum.KeyCode.LeftControl
    pcall(function()
        game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == bindKey then
                pcall(function() Library:Toggle() end)
            end
        end)
    end)

    local WindowSignal = {}

    function WindowSignal:AddTab(cfg)
        cfg = cfg or {}
        local tab = Window:AddTab(tostring(cfg.Name or "Tab"))
        local TabSignal = {}

        function TabSignal:AddSection(scfg)
            scfg = scfg or {}
            local pos = tostring(scfg.Position or "left"):lower()
            local gb
            if pos == "right" then
                gb = tab:AddRightGroupbox(tostring(scfg.Name or "Section"))
            else
                gb = tab:AddLeftGroupbox(tostring(scfg.Name or "Section"))
            end
            local SectionSignal = {}

            function SectionSignal:AddToggle(tcfg)
                tcfg = tcfg or {}
                local idx = __nextId(tcfg.Name)
                gb:AddToggle(idx, {
                    Text = tostring(tcfg.Name or "Toggle"),
                    Default = (tcfg.Default == true),
                    Callback = function(v)
                        pcall(tcfg.Callback or function() end, v)
                    end,
                })
                return {
                    SetValue = function(_, v)
                        pcall(function() Library.Toggles[idx]:SetValue(not not v) end)
                    end,
                }
            end

            function SectionSignal:AddSlider(scfg2)
                scfg2 = scfg2 or {}
                local idx = __nextId(scfg2.Name)
                gb:AddSlider(idx, {
                    Text = tostring(scfg2.Name or "Slider"),
                    Default = tonumber(scfg2.Default) or tonumber(scfg2.Min) or 0,
                    Min = tonumber(scfg2.Min) or 0,
                    Max = tonumber(scfg2.Max) or 100,
                    Rounding = tonumber(scfg2.Round) or 0,
                    Suffix = tostring(scfg2.Type or ""),
                    Callback = function(v)
                        pcall(scfg2.Callback or function() end, v)
                    end,
                })
                return {
                    SetValue = function(_, v)
                        pcall(function() Library.Options[idx]:SetValue(v) end)
                    end,
                }
            end

            function SectionSignal:AddButton(bcfg)
                bcfg = bcfg or {}
                gb:AddButton({
                    Text = tostring(bcfg.Name or "Button"),
                    Func = function()
                        pcall(bcfg.Callback or function() end)
                    end,
                })
                return {}
            end

            function SectionSignal:AddLabel(text)
                local lab = gb:AddLabel(tostring(text or ""))
                return {
                    -- NeverZen calls it SetValue; Linoria calls it SetText.
                    SetValue = function(_, v)
                        pcall(function() lab:SetText(tostring(v)) end)
                    end,
                }
            end

            return SectionSignal
        end

        return TabSignal
    end

    return WindowSignal
end

return NeverZen
