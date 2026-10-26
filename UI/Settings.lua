local _, MacroStudio = ...

local Settings = {}
MacroStudio.Settings = Settings

local function createCheckbox(parent, anchor, text)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    local label = MacroStudio.Helpers:CreateLabel(parent, "GameFontHighlight", text)
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.label = label
    return checkbox
end

function Settings:Create()
    if self.frame then
        return self.frame
    end

    local frame = MacroStudio.Helpers:CreateWindow(UIParent)
    frame:SetSize(470, 390)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "MacroStudio Settings")
    title:SetPoint("TOPLEFT", 18, -16)
    MacroStudio.Theme:Dialog(frame, title)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    local heading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "GENERAL")
    heading:SetPoint("TOPLEFT", 20, -54)
    heading:SetTextColor(unpack(MacroStudio.Theme.palette.gold))

    local takeover = createCheckbox(frame, heading, "Use MacroStudio for /m and /macro")
    takeover:SetScript("OnClick", function(owner)
        MacroStudio.Access:SetTakeoverEnabled(owner:GetChecked())
    end)
    self.takeoverCheckbox = takeover

    local minimap = createCheckbox(frame, takeover, "Show minimap button")
    minimap:SetScript("OnClick", function(owner)
        MacroStudio.MinimapButton:SetShown(owner:GetChecked())
    end)
    self.minimapCheckbox = minimap

    local status = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    status:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 4, -14)
    status:SetSize(420, 34)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetWordWrap(true)
    self.statusText = status

    local styleHeading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "COLOR STYLE")
    styleHeading:SetPoint("TOPLEFT", 20, -196)
    self.styleButtons = {}
    for index, style in ipairs(MacroStudio.Theme.colorStyles) do
        local id = style.id
        local radio = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate")
        radio:SetSize(18, 18)
        radio:SetPoint("TOPLEFT", 20 + ((index - 1) % 2) * 215, -222 - math.floor((index - 1) / 2) * 26)
        radio:SetHitRectInsets(0, -180, 0, 0)
        local label = MacroStudio.Helpers:CreateLabel(radio, "GameFontHighlight", style.name)
        label:SetPoint("LEFT", radio, "RIGHT", 4, 0)
        label:SetTextColor(unpack(style.color or style.swatch or MacroStudio.Theme.palette.text))
        radio.label = label
        radio:SetScript("OnClick", function()
            MacroStudio.Theme:SetColorStyle(id)
            self:Refresh()
        end)
        self.styleButtons[id] = radio
    end

    local styleHelp = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    styleHelp:SetPoint("TOPLEFT", 24, -306)
    styleHelp:SetSize(420, 34)
    styleHelp:SetJustifyH("LEFT")
    styleHelp:SetJustifyV("TOP")
    styleHelp:SetWordWrap(true)
    MacroStudio.Theme:SecondaryText(styleHelp)
    self.styleHelp = styleHelp

    local reload = MacroStudio.Helpers:CreateButton(frame)
    reload:SetSize(110, 26)
    reload:SetPoint("BOTTOMLEFT", 20, 16)
    reload:SetText("Reload UI")
    reload:SetScript("OnClick", function() self:ApplyAppearance() end)
    self.reloadButton = reload

    local done = MacroStudio.Helpers:CreateButton(frame)
    done:SetSize(90, 26)
    done:SetPoint("BOTTOMRIGHT", -18, 16)
    done:SetText("Done")
    done:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetScript("OnShow", function()
        self:Refresh()
        MacroStudio:Debug("settings frame OnShow")
    end)
    frame:SetScript("OnHide", function()
        MacroStudio:SetMainWindowModalBlocked(false)
        MacroStudio:Debug("settings frame OnHide")
    end)

    return frame
end

function Settings:Refresh()
    if not self.frame then
        return
    end
    local settings = MacroStudio.db and MacroStudio.db.settings or {}
    self.takeoverCheckbox:SetChecked(settings.useMacroStudioSlashCommands == true)
    self.minimapCheckbox:SetChecked(settings.showMinimapButton == true)
    local style = MacroStudio.Theme:GetColorStyle()
    for id, radio in pairs(self.styleButtons) do
        radio:SetChecked(id == style.id)
    end
    local pending = MacroStudio.Theme:HasPendingAppearance()
    local canReload = pending and self:CanReloadAppearance()
    self.reloadButton:SetShown(pending)
    MacroStudio.Helpers:SetButtonEnabled(self.reloadButton, canReload)
    self.styleHelp:SetText(pending and (canReload and "Reload UI to apply your style. Your macros and settings are kept."
        or "Save or Revert your macro changes and close any macro dialog before reloading.")
        or "Choose a style above. Reload UI applies your selection.")
    self.statusText:SetText(MacroStudio.Access:GetStatusText())
    if MacroStudio.Access:IsTakeoverRequested() and not MacroStudio.Access:IsTakeoverActive() then
        self.statusText:SetTextColor(unpack(MacroStudio.Theme.palette.error))
    else
        self.statusText:SetTextColor(unpack(MacroStudio.Theme.palette.muted))
    end
end

function Settings:CanReloadAppearance()
    return not (MacroStudio.Editor and MacroStudio.Editor:IsDirty())
        and not (MacroStudio.MacroDialog and MacroStudio.MacroDialog:IsShown())
end

function Settings:ApplyAppearance()
    -- Recheck on click as well as refresh: never discard an unsaved macro.
    if not MacroStudio.Theme:HasPendingAppearance() or not self:CanReloadAppearance() then
        self:Refresh()
        return false
    end
    ReloadUI()
    return true
end

function Settings:Open()
    MacroStudio:Show()
    local frame = self:Create()
    if MacroStudio:IsMainWindowModalBlocked() and not frame:IsShown() then
        MacroStudio:Print("Close the current dialog before opening Settings.")
        return false
    end
    MacroStudio:SetMainWindowModalBlocked(true)
    frame:Show()
    frame:Raise()
    return true
end
