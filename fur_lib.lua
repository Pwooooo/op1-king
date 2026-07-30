return function(ctx, Modules)
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

    local okLibrary, Library = pcall(function()
        return loadstring(game:HttpGet(repo .. "Library.lua"))()
    end)

    if not okLibrary then
        warn("[uilib] Obsidian load failed:", Library)
        return
    end

    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true

    local okTheme, ThemeManager = pcall(function()
        return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    end)

    local okSave, SaveManager = pcall(function()
        return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    end)
local Window = Library:CreateWindow({
    Title = "FURRY MAN",
    Footer = "FREE YENO",
    Center = true,
    AutoShow = true,
    ShowCustomCursor = true,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightControl, 
})
    local Tabs = {
        Combat = Window:AddTab("Combat"),
        Visuals = Window:AddTab("Visuals"),
        World = Window:AddTab("World"),
        Misc = Window:AddTab("Misc"),
        UI = Window:AddTab("UI Settings")
    }

    local Gun = Tabs.Combat:AddLeftGroupbox("Gun Mods")
    Gun:AddToggle("gm_en", {
        Text = "Enable Gun Mods",
        Default = Modules.GunMods.enabled
    }):OnChanged(function(v)
        Modules.GunMods:SetEnabled(v)
    end)
    Gun:AddSlider("gm_recoil", {
        Text = "Recoil Mult",
        Default = Modules.GunMods.recoilReduction,
        Min = 0,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.GunMods:SetRecoilReduction(v)
    end)
    Gun:AddSlider("gm_hrecoil", {
        Text = "Horizontal Recoil",
        Default = Modules.GunMods.horizontalRecoil,
        Min = 0,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.GunMods:SetHorizontalRecoil(v)
    end)
    Gun:AddToggle("gm_nospread", {
        Text = "No Spread",
        Default = Modules.GunMods.noSpread
    }):OnChanged(function(v)
        Modules.GunMods:SetNoSpread(v)
    end)
    Gun:AddSlider("gm_acc", {
        Text = "Accuracy",
        Default = Modules.GunMods.accuracyMultiplier,
        Min = 0,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.GunMods:SetAccuracyMultiplier(v)
    end)
    Gun:AddSlider("gm_rate", {
        Text = "Firerate",
        Default = Modules.GunMods.customFirerate,
        Min = 100,
        Max = 3000,
        Rounding = 0
    }):OnChanged(function(v)
        Modules.GunMods:SetCustomFirerate(v)
    end)
    Gun:AddSlider("gm_reload", {
        Text = "Reload",
        Default = Modules.GunMods.reloadSpeed,
        Min = 0.05,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.GunMods:SetReloadSpeed(v)
    end)
    Gun:AddToggle("gm_auto", {
        Text = "Force Auto",
        Default = Modules.GunMods.forceAuto
    }):OnChanged(function(v)
        Modules.GunMods:SetForceAuto(v)
    end)
    Gun:AddToggle("gm_ads", {
        Text = "Instant ADS",
        Default = Modules.GunMods.instantADS
    }):OnChanged(function(v)
        Modules.GunMods:SetInstantADS(v)
    end)
    Gun:AddSlider("gm_zoom", {
        Text = "Zoom",
        Default = Modules.GunMods.customZoom,
        Min = 1,
        Max = 4,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.GunMods:SetCustomZoom(v)
    end)

    local SA = Tabs.Combat:AddRightGroupbox("Silent Aim")
    SA:AddToggle("sa_en", {
        Text = "Enable Silent Aim",
        Default = Modules.SilentAim.enabled
    }):OnChanged(function(v)
        Modules.SilentAim:SetEnabled(v)
    end)
    SA:AddSlider("sa_fov", {
        Text = "FOV",
        Default = Modules.SilentAim.fov,
        Min = 20,
        Max = 1000,
        Rounding = 0
    }):OnChanged(function(v)
        Modules.SilentAim:SetFov(v)
    end)
    SA:AddToggle("sa_fov_circle", {
        Text = "Show FOV Circle",
        Default = Modules.SilentAim.fovVisible
    }):OnChanged(function(v)
        Modules.SilentAim:SetFovVisible(v)
    end)
    SA:AddSlider("sa_smooth", {
        Text = "Smoothness",
        Default = Modules.SilentAim.smoothness,
        Min = 0.05,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.SilentAim:SetSmoothness(v)
    end)
    SA:AddToggle("sa_p", {
        Text = "Target Players",
        Default = Modules.SilentAim.targetPlayers
    }):OnChanged(function(v)
        Modules.SilentAim:SetTargetPlayers(v)
    end)
    SA:AddToggle("sa_g", {
        Text = "Target Gadgets",
        Default = Modules.SilentAim.targetGadgets
    }):OnChanged(function(v)
        Modules.SilentAim:SetTargetGadgets(v)
    end)
    SA:AddToggle("sa_c", {
        Text = "Target Cameras",
        Default = Modules.SilentAim.targetCameras
    }):OnChanged(function(v)
        Modules.SilentAim:SetTargetCameras(v)
    end)

    local HB = Tabs.Combat:AddRightGroupbox("Hitbox")
    HB:AddToggle("hb_en", {
        Text = "Enable Hitbox",
        Default = Modules.Hitbox.enabled
    }):OnChanged(function(v)
        Modules.Hitbox:SetEnabled(v)
    end)
    HB:AddToggle("hb_team", {
        Text = "Team Check",
        Default = Modules.Hitbox.teamCheck
    }):OnChanged(function(v)
        Modules.Hitbox:SetTeamCheck(v)
    end)
    HB:AddSlider("hb_size", {
        Text = "Size",
        Default = Modules.Hitbox.size,
        Min = 1,
        Max = 10,
        Rounding = 1
    }):OnChanged(function(v)
        Modules.Hitbox:SetSize(v)
    end)
    HB:AddSlider("hb_t", {
        Text = "Transparency",
        Default = Modules.Hitbox.transparency,
        Min = 0,
        Max = 1,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.Hitbox:SetTransparency(v)
    end)
    HB:AddLabel("Hitbox Color"):AddColorPicker("hb_color", {
        Default = Modules.Hitbox.color,
        Title = "Hitbox Color",
        Callback = function(v)
            Modules.Hitbox:SetColor(v)
        end
    })

    local ESP = Tabs.Visuals:AddLeftGroupbox("ESP")
    ESP:AddToggle("esp_en", {
        Text = "Enable ESP",
        Default = Modules.ESP.enabled
    }):OnChanged(function(v)
        Modules.ESP:SetEnabled(v)
    end)
    ESP:AddToggle("esp_team", {
        Text = "Team Check",
        Default = Modules.ESP.teamCheck
    }):OnChanged(function(v)
        Modules.ESP:SetTeamCheck(v)
    end)
    ESP:AddToggle("esp_player", {
        Text = "Player Boxes",
        Default = Modules.ESP.playerBoxEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetPlayerBoxEnabled(v)
    end)
    ESP:AddToggle("esp_object", {
        Text = "Object Boxes",
        Default = Modules.ESP.objectBoxEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetObjectBoxEnabled(v)
    end)
    ESP:AddSlider("esp_pt", {
        Text = "Player Thickness",
        Default = Modules.ESP.playerThickness,
        Min = 1,
        Max = 5,
        Rounding = 1
    }):OnChanged(function(v)
        Modules.ESP:SetPlayerThickness(v)
    end)
    ESP:AddSlider("esp_ot", {
        Text = "Object Thickness",
        Default = Modules.ESP.objectThickness,
        Min = 1,
        Max = 5,
        Rounding = 1
    }):OnChanged(function(v)
        Modules.ESP:SetObjectThickness(v)
    end)

    local ESPColors = Tabs.Visuals:AddRightGroupbox("ESP Colors")
    ESPColors:AddLabel("Players"):AddColorPicker("esp_pc", {
        Default = Modules.ESP.playerColor,
        Title = "Player",
        Callback = function(v)
            Modules.ESP:SetPlayerColor(v)
        end
    })
    ESPColors:AddLabel("Drone"):AddColorPicker("esp_dc", {
        Default = Modules.ESP.droneColor,
        Title = "Drone",
        Callback = function(v)
            Modules.ESP:SetDroneColor(v)
        end
    })
    ESPColors:AddLabel("Claymore"):AddColorPicker("esp_cc", {
        Default = Modules.ESP.claymoreColor,
        Title = "Claymore",
        Callback = function(v)
            Modules.ESP:SetClaymoreColor(v)
        end
    })
    ESPColors:AddLabel("Proximity"):AddColorPicker("esp_prc", {
        Default = Modules.ESP.proximityColor,
        Title = "Proximity",
        Callback = function(v)
            Modules.ESP:SetProximityColor(v)
        end
    })
    ESPColors:AddLabel("Sticky"):AddColorPicker("esp_sc", {
        Default = Modules.ESP.stickyColor,
        Title = "Sticky Camera",
        Callback = function(v)
            Modules.ESP:SetStickyColor(v)
        end
    })
    ESPColors:AddLabel("Remote C4"):AddColorPicker("esp_rc4", {
        Default = Modules.ESP.remoteC4Color,
        Title = "Remote C4",
        Callback = function(v)
            Modules.ESP:SetRemoteC4Color(v)
        end
    })
    ESPColors:AddLabel("Thermite"):AddColorPicker("esp_th", {
        Default = Modules.ESP.thermiteColor,
        Title = "Thermite Charge",
        Callback = function(v)
            Modules.ESP:SetThermiteColor(v)
        end
    })
    ESPColors:AddLabel("Toxic"):AddColorPicker("esp_tx", {
        Default = Modules.ESP.toxicColor,
        Title = "Toxic Charge",
        Callback = function(v)
            Modules.ESP:SetToxicColor(v)
        end
    })
    ESPColors:AddLabel("HardBreachCharge"):AddColorPicker("esp_hb", {
        Default = Modules.ESP.hardBreachChargeColor,
        Title = "HardBreachCharge",
        Callback = function(v)
            Modules.ESP:SetHardBreachChargeColor(v)
        end
    })
    ESPColors:AddLabel("Shock Battery"):AddColorPicker("esp_sb", {
        Default = Modules.ESP.shockBatteryColor,
        Title = "Shock Battery",
        Callback = function(v)
            Modules.ESP:SetShockBatteryColor(v)
        end
    })
    ESPColors:AddLabel("Deployable Shield"):AddColorPicker("esp_ds", {
        Default = Modules.ESP.deployableShieldColor,
        Title = "Deployable Shield",
        Callback = function(v)
            Modules.ESP:SetDeployableShieldColor(v)
        end
    })
    ESPColors:AddLabel("Barbed Wire"):AddColorPicker("esp_bw", {
        Default = Modules.ESP.barbedWireColor,
        Title = "Barbed Wire",
        Callback = function(v)
            Modules.ESP:SetBarbedWireColor(v)
        end
    })
    ESPColors:AddLabel("SignalDisruptor"):AddColorPicker("esp_sj", {
        Default = Modules.ESP.signalDisruptorColor,
        Title = "SignalDisruptor",
        Callback = function(v)
            Modules.ESP:SetSignalDisruptorColor(v)
        end
    })
    ESPColors:AddLabel("BulletproofCamera"):AddColorPicker("esp_bpc", {
        Default = Modules.ESP.bulletproofCameraColor,
        Title = "BulletproofCamera",
        Callback = function(v)
            Modules.ESP:SetBulletproofCameraColor(v)
        end
    })
    ESPColors:AddLabel("BreachCharge"):AddColorPicker("esp_bc", {
        Default = Modules.ESP.breachChargeColor,
        Title = "BreachCharge",
        Callback = function(v)
            Modules.ESP:SetBreachChargeColor(v)
        end
    })

    local ESPObjects = Tabs.Visuals:AddRightGroupbox("ESP Objects")
    ESPObjects:AddToggle("esp_obj_drone", {
        Text = "Drone",
        Default = Modules.ESP.droneEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetDroneEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_claymore", {
        Text = "Claymore",
        Default = Modules.ESP.claymoreEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetClaymoreEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_prox", {
        Text = "Proximity Alarm",
        Default = Modules.ESP.proximityEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetProximityEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_sticky", {
        Text = "Sticky Camera",
        Default = Modules.ESP.stickyEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetStickyEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_rc4", {
        Text = "Remote C4",
        Default = Modules.ESP.remoteC4Enabled
    }):OnChanged(function(v)
        Modules.ESP:SetRemoteC4Enabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_th", {
        Text = "Thermite Charge",
        Default = Modules.ESP.thermiteEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetThermiteEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_tx", {
        Text = "Toxic Charge",
        Default = Modules.ESP.toxicEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetToxicEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_hb", {
        Text = "HardBreachCharge",
        Default = Modules.ESP.hardBreachChargeEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetHardBreachChargeEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_sb", {
        Text = "Shock Battery",
        Default = Modules.ESP.shockBatteryEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetShockBatteryEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_ds", {
        Text = "Deployable Shield",
        Default = Modules.ESP.deployableShieldEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetDeployableShieldEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_bw", {
        Text = "Barbed Wire",
        Default = Modules.ESP.barbedWireEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetBarbedWireEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_sj", {
        Text = "SignalDisruptor",
        Default = Modules.ESP.signalDisruptorEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetSignalDisruptorEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_bpc", {
        Text = "BulletproofCamera",
        Default = Modules.ESP.bulletproofCameraEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetBulletproofCameraEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_bc", {
        Text = "BreachCharge",
        Default = Modules.ESP.breachChargeEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetBreachChargeEnabled(v)
    end)
    ESPObjects:AddToggle("esp_obj_names", {
        Text = "Object Names",
        Default = Modules.ESP.objectNameEnabled
    }):OnChanged(function(v)
        Modules.ESP:SetObjectNameEnabled(v)
    end)
    ESPObjects:AddSlider("esp_obj_name_size", {
        Text = "Name Size",
        Default = Modules.ESP.objectNameSize,
        Min = 10,
        Max = 28,
        Rounding = 0
    }):OnChanged(function(v)
        Modules.ESP:SetObjectNameSize(v)
    end)

    local WR = Tabs.World:AddLeftGroupbox("World")
    WR:AddToggle("fb_en", {
        Text = "Fullbright",
        Default = Modules.Fullbright.enabled
    }):OnChanged(function(v)
        Modules.Fullbright:SetEnabled(v)
    end)
    WR:AddSlider("fb_brightness", {
        Text = "Brightness",
        Default = Modules.Fullbright.brightness,
        Min = 0,
        Max = 10,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.Fullbright:SetBrightness(v)
    end)
    WR:AddSlider("fb_clock", {
        Text = "Clock Time",
        Default = Modules.Fullbright.clockTime,
        Min = 0,
        Max = 24,
        Rounding = 2
    }):OnChanged(function(v)
        Modules.Fullbright:SetClockTime(v)
    end)
    WR:AddSlider("fb_fog", {
        Text = "Fog End",
        Default = Modules.Fullbright.fogEnd,
        Min = 100,
        Max = 1000000,
        Rounding = 0
    }):OnChanged(function(v)
        Modules.Fullbright:SetFogEnd(v)
    end)
    WR:AddToggle("fb_shadows", {
        Text = "Global Shadows",
        Default = Modules.Fullbright.globalShadows
    }):OnChanged(function(v)
        Modules.Fullbright:SetGlobalShadows(v)
    end)
    WR:AddLabel("Ambient Color"):AddColorPicker("fb_ambient", {
        Default = Modules.Fullbright.ambient,
        Title = "Ambient Color",
        Callback = function(v)
            Modules.Fullbright:SetAmbient(v)
        end
    })

    local NSF = Tabs.Misc:AddLeftGroupbox("No Smoke / Flash")
    NSF:AddToggle("nsf_en", {
        Text = "Enable",
        Default = Modules.NoSmokeFlash.enabled
    }):OnChanged(function(v)
        Modules.NoSmokeFlash:SetEnabled(v)
    end)
    NSF:AddToggle("nsf_smoke", {
        Text = "No Smoke",
        Default = Modules.NoSmokeFlash.noSmoke
    }):OnChanged(function(v)
        Modules.NoSmokeFlash:SetNoSmoke(v)
    end)
    NSF:AddToggle("nsf_flash", {
        Text = "No Flash",
        Default = Modules.NoSmokeFlash.noFlash
    }):OnChanged(function(v)
        Modules.NoSmokeFlash:SetNoFlash(v)
    end)

    local RF = Tabs.Misc:AddRightGroupbox("Rappel Fly")
    RF:AddToggle("rf_en", {
        Text = "Enable",
        Default = Modules.RappelFly.enabled
    }):OnChanged(function(v)
        Modules.RappelFly:SetEnabled(v)
    end)
 RF:AddLabel("Fly Key"):AddKeyPicker("rf_key", {
    Default = "G",
    NoUI = true,
    Text = "Fly Key",
    ChangedCallback = function(new)
        Modules.RappelFly:SetFlyKey(new.Name)
    end,
})
    RF:AddSlider("rf_speed", {
        Text = "Fly Speed",
        Default = Modules.RappelFly.speed,
        Min = 1,
        Max = 9,
        Rounding = 1
    }):OnChanged(function(v)
        Modules.RappelFly:SetSpeed(v)
    end)
    RF:AddSlider("rf_pull", {
        Text = "Pull Speed",
        Default = Modules.RappelFly.pullSpeed,
        Min = 0.1,
        Max = 10,
        Rounding = 1
    }):OnChanged(function(v)
        Modules.RappelFly:SetPullSpeed(v)
    end)

    local UIG = Tabs.UI:AddLeftGroupbox("Menu")
   UIG:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu Keybind",
    ChangedCallback = function(new)
        Library.ToggleKeybind = new 
    end,
})
    UIG:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = true
    }):OnChanged(function(v)
        Library.ShowCustomCursor = v
    end)
    UIG:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(value)
            value = value:gsub("%%", "")
            local dpi = tonumber(value)
            if dpi then
                Library:SetDPIScale(dpi)
            end
        end
    })
    UIG:AddDivider()
    UIG:AddLabel("Use the controls above to tune the menu feel")

    if okTheme then
        ThemeManager:SetLibrary(Library)
        ThemeManager:ApplyToTab(Tabs.UI)
    end

    if okSave then
        SaveManager:SetLibrary(Library)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({"MenuKeybind", "rf_key", "DPIDropdown"})
        SaveManager:SetFolder("obsfurr")
        SaveManager:BuildConfigSection(Tabs.UI)
    end

   --[[ if Options.rf_key and Options.rf_key.OnClick then
        Options.rf_key:OnClick(function()
            Modules.RappelFly:SetFlyKey(Options.rf_key.Value)
        end)
    end]]

  
end
