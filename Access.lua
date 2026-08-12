local _, MacroStudio = ...

local Access = {}
MacroStudio.Access = Access

local TAKEOVER_SETTING = "useMacroStudioSlashCommands"
local NATIVE_COMMAND_FALLBACK = "MACRO"

local function normalizedAlias(value)
    return type(value) == "string" and value:lower() or nil
end

local function isProtectedVariableSecure(container, key)
    if type(issecurevariable) ~= "function" then
        return true
    end
    local ok, secure = pcall(issecurevariable, container, key)
    return ok and secure ~= false
end

function Access:GetNativeCommandKey()
    return type(SLASH_COMMAND) == "table" and SLASH_COMMAND.MACRO or NATIVE_COMMAND_FALLBACK
end

function Access:FindAliasCollision()
    local nativeKey = self.nativeMacroCommandKey or self:GetNativeCommandKey()
    for globalName, alias in pairs(_G) do
        local commandKey = type(globalName) == "string" and globalName:match("^SLASH_(.+)%d+$") or nil
        local normalized = normalizedAlias(alias)
        if commandKey
            and commandKey ~= nativeKey
            and (normalized == "/m" or normalized == "/macro")
            and type(SlashCmdList[commandKey]) == "function" then
            return "Another addon already owns " .. normalized .. " (" .. commandKey .. ")."
        end
    end
    return nil
end

function Access:IsNativeRegistrationTrusted(commandKey, handler)
    if not isProtectedVariableSecure(SlashCmdList, commandKey) then
        return false
    end

    local index = 1
    local aliasGlobal = "SLASH_" .. commandKey .. index
    local alias = _G[aliasGlobal]
    while alias do
        if not isProtectedVariableSecure(_G, aliasGlobal) then
            return false
        end
        local hashKey = type(alias) == "string" and alias:upper() or nil
        local hashedHandler = hashKey and hash_SlashCmdList and hash_SlashCmdList[hashKey] or nil
        if hashedHandler and (hashedHandler ~= handler
            or not isProtectedVariableSecure(hash_SlashCmdList, hashKey)) then
            return false
        end
        index = index + 1
        aliasGlobal = "SLASH_" .. commandKey .. index
        alias = _G[aliasGlobal]
    end
    return true
end

function Access:CaptureNativeHandler()
    local commandKey = self:GetNativeCommandKey()
    self.nativeMacroCommandKey = commandKey
    self.nativeHandlerTrusted = false
    self.nativeMacroHandler = SlashCmdList[commandKey]

    if type(self.nativeMacroHandler) ~= "function" then
        self.unavailableReason = "Blizzard's macro slash handler was not available at login."
        return false
    end
    if not self:IsNativeRegistrationTrusted(commandKey, self.nativeMacroHandler) then
        self.unavailableReason = "Another addon changed Blizzard's macro slash handler before MacroStudio loaded."
        return false
    end
    self.nativeHandlerTrusted = true

    local collision = self:FindAliasCollision()
    if collision then
        self.unavailableReason = collision
        return false
    end

    self.unavailableReason = nil
    return true
end

function Access:IsTakeoverRequested()
    local settings = MacroStudio.db and MacroStudio.db.settings
    return settings and settings[TAKEOVER_SETTING] == true
end

function Access:IsTakeoverActive()
    return self.takeoverActive == true
        and self.nativeMacroCommandKey ~= nil
        and SlashCmdList[self.nativeMacroCommandKey] == self.takeoverHandler
end

function Access:EnableTakeover()
    if not self.initialized then
        return false, "Macro slash access is not initialized yet."
    end
    if self.unavailableReason then
        return false, self.unavailableReason
    end

    local collision = self:FindAliasCollision()
    if collision then
        self.unavailableReason = collision
        self.takeoverActive = false
        return false, collision
    end

    local current = SlashCmdList[self.nativeMacroCommandKey]
    if current == self.takeoverHandler then
        self.takeoverActive = true
        return true
    end
    if current ~= self.nativeMacroHandler then
        self.takeoverActive = false
        self.unavailableReason = "Another addon changed the native macro handler; MacroStudio left it untouched."
        return false, self.unavailableReason
    end

    SlashCmdList[self.nativeMacroCommandKey] = self.takeoverHandler
    self.takeoverActive = SlashCmdList[self.nativeMacroCommandKey] == self.takeoverHandler
    if not self.takeoverActive then
        self.unavailableReason = "MacroStudio could not claim the native macro aliases."
        return false, self.unavailableReason
    end
    MacroStudio:Debug("claimed /m and /macro")
    return true
end

function Access:DisableTakeover()
    if not self.initialized then
        return true
    end

    local current = SlashCmdList[self.nativeMacroCommandKey]
    if current == self.takeoverHandler then
        SlashCmdList[self.nativeMacroCommandKey] = self.nativeMacroHandler
        MacroStudio:Debug("restored Blizzard /m and /macro handler")
    elseif self.takeoverActive then
        MacroStudio:Debug("native macro handler changed after takeover; leaving the newer handler untouched")
    end
    self.takeoverActive = false
    return true
end

function Access:SetTakeoverEnabled(enabled)
    enabled = enabled and true or false
    MacroStudio.db.settings[TAKEOVER_SETTING] = enabled
    local ok, reason
    if enabled then
        ok, reason = self:EnableTakeover()
    else
        ok, reason = self:DisableTakeover()
    end
    if MacroStudio.Settings then
        MacroStudio.Settings:Refresh()
    end
    return ok, reason
end

function Access:GetStatusText()
    if not self:IsTakeoverRequested() then
        return "Blizzard handles /m and /macro. /ms always opens MacroStudio."
    end
    if self:IsTakeoverActive() then
        return "MacroStudio handles /m and /macro."
    end
    return self.unavailableReason or "MacroStudio could not claim /m and /macro."
end

function Access:OpenBlizzardMacroUI()
    if self.nativeHandlerTrusted and type(self.nativeMacroHandler) == "function" then
        local ok = pcall(self.nativeMacroHandler, "")
        if ok then
            return true
        end
    end

    -- ShowMacroFrame is Blizzard's supported Retail entry point. In 12.1 it is
    -- provided by Blizzard_MacroUI's load-on-demand bootstrap.
    if type(ShowMacroFrame) == "function" then
        local ok = pcall(ShowMacroFrame)
        if ok then
            return true
        end
    end

    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        pcall(C_AddOns.LoadAddOn, "Blizzard_MacroUI")
    end
    if type(MacroFrame_Show) == "function" then
        local ok = pcall(MacroFrame_Show)
        if ok then
            return true
        end
    end

    MacroStudio:Print("Blizzard's Macro UI could not be opened.")
    return false
end

function Access:IsSettingsShown()
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    return settingsFrame and settingsFrame:IsShown() or false
end

local function conciseExportError(value)
    local message = tostring(value or "unknown error")
    message = message:gsub("[\r\n]+", " "):gsub("%s+", " ")
    if #message > 320 then
        message = message:sub(1, 317) .. "..."
    end
    return message
end

function Access:OpenExport(source)
    MacroStudio:Debug("Export controller invoked", source or "unknown")
    self.lastExportFailure = nil
    local ok, result = xpcall(function()
        return MacroStudio.ExportDialog:Open(source)
    end, conciseExportError)
    if ok then
        return result
    end

    local stage = MacroStudio.ExportDialog:GetStage()
        or MacroStudio.PortableExport:GetStage()
        or "unknown stage"
    local message = "Export failed at " .. stage .. ": " .. result
    self.lastExportFailure = {
        stage = stage,
        message = result,
    }
    MacroStudio.ExportDialog:HandleFailure()
    MacroStudio:Print(message)
    if MacroStudio.Settings then
        MacroStudio.Settings:ShowExportError(message)
    end
    MacroStudio:Debug("Export failure contained", stage, result)
    return false
end

function Access:OpenSettings(source)
    MacroStudio:Debug("settings open invoked", source or "unknown")
    local opened = MacroStudio.Settings:Open()
    MacroStudio:Debug("settings frame shown", self:IsSettingsShown())
    return opened
end

function Access:CloseSettings(closeMainWindow, source)
    MacroStudio:Debug("settings close invoked", source or "unknown", closeMainWindow and "with main" or "settings only")
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    if settingsFrame and settingsFrame:IsShown() then
        settingsFrame:Hide()
    end
    if closeMainWindow and MacroStudio.frame and MacroStudio.frame:IsShown() then
        MacroStudio.frame:Hide()
    end
    return true
end

function Access:ToggleSettings(source, closeMainWindow)
    MacroStudio:Debug("settings toggle invoked", source or "unknown", self:IsSettingsShown())
    if self:IsSettingsShown() then
        self:CloseSettings(closeMainWindow, source)
        return false
    end
    return self:OpenSettings(source)
end

function Access:HandleSlashCommand(message)
    local command = MacroStudio.Helpers:Trim(message):lower()
    if command == "debug" then
        MacroStudio:SetDebug(not MacroStudio.debug)
    elseif command == "debug on" then
        MacroStudio:SetDebug(true)
    elseif command == "debug off" then
        MacroStudio:SetDebug(false)
    elseif command == "refresh" then
        if not MacroStudio.initialized then
            MacroStudio:Initialize()
        end
        MacroStudio:RefreshMacros("manual")
        MacroStudio.frame:Show()
    elseif command == "blizzard" then
        self:OpenBlizzardMacroUI()
    elseif command == "export" then
        MacroStudio:Debug("/ms export dispatch")
        self:OpenExport("slash")
    elseif command == "settings" then
        self:OpenSettings("slash")
    elseif command == "help" then
        MacroStudio:Print("/macrostudio or /ms - toggle MacroStudio")
        MacroStudio:Print("/ms settings - open MacroStudio settings")
        MacroStudio:Print("/ms export - export the portable MacroStudio library")
        MacroStudio:Print("/ms blizzard - open Blizzard's Macro UI")
        MacroStudio:Print("/ms refresh - force a fallback macro refresh")
        MacroStudio:Print("/ms debug [on|off] - control debug logging")
    elseif command == "" then
        MacroStudio:Toggle()
    else
        MacroStudio:Print("Unknown command. Use /ms help.")
    end
end

function Access:HandleLauncherClick(buttonName)
    if buttonName == "RightButton" then
        self:ToggleSettings("minimap", true)
    else
        MacroStudio:Toggle()
    end
end

function Access:ShowLauncherTooltip(owner)
    MacroStudio.Helpers:ShowTooltip(
        owner,
        "MacroStudio",
        "Left-click to toggle MacroStudio. Right-click for settings."
    )
end

function Access:Initialize()
    if self.initialized then
        return
    end
    self.takeoverHandler = function()
        MacroStudio:Toggle()
    end
    self.initialized = true
    self:CaptureNativeHandler()
    if self:IsTakeoverRequested() then
        local ok, reason = self:EnableTakeover()
        if not ok then
            MacroStudio:Debug("/m and /macro takeover unavailable", reason or "unknown reason")
        end
    end
end

function Access:ScheduleInitialize()
    if self.initialized or self.initializeScheduled then
        return
    end
    self.initializeScheduled = true
    local function initialize()
        self.initializeScheduled = false
        self:Initialize()
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, initialize)
    else
        initialize()
    end
end

SLASH_MACROSTUDIO1 = "/macrostudio"
SLASH_MACROSTUDIO2 = "/ms"
SlashCmdList.MACROSTUDIO = function(message)
    Access:HandleSlashCommand(message or "")
end

function MacroStudio_AddonCompartmentOnClick(_, buttonName)
    Access:HandleLauncherClick(buttonName)
end

function MacroStudio_AddonCompartmentOnEnter(_, button)
    Access:ShowLauncherTooltip(button)
end

function MacroStudio_AddonCompartmentOnLeave()
    MacroStudio.Helpers:HideTooltip()
end
