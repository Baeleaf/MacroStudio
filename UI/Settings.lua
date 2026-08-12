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

    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(470, 310)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "MacroStudio Settings")
    title:SetPoint("TOPLEFT", 18, -16)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    local heading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "GENERAL")
    heading:SetPoint("TOPLEFT", 20, -54)
    heading:SetTextColor(0.35, 0.75, 1)

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

    local dataHeading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "DATA")
    dataHeading:SetPoint("TOPLEFT", 20, -194)
    dataHeading:SetTextColor(0.35, 0.75, 1)

    local export = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    export:SetSize(210, 26)
    export:SetPoint("TOPLEFT", dataHeading, "BOTTOMLEFT", 0, -9)
    export:SetText("Export MacroStudio Library")
    export:SetScript("OnClick", function()
        MacroStudio:Debug("Settings Export button invoked")
        MacroStudio.Access:OpenExport("settings")
    end)
    MacroStudio.Helpers:SetButtonTooltip(export, "Portable Export", "Open a selectable, copyable export of saved macro-library content.")
    self.exportButton = export

    local done = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
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
    self.statusText:SetText(MacroStudio.Access:GetStatusText())
    if MacroStudio.Access:IsTakeoverRequested() and not MacroStudio.Access:IsTakeoverActive() then
        self.statusText:SetTextColor(1, 0.4, 0.35)
    else
        self.statusText:SetTextColor(0.68, 0.72, 0.8)
    end
end

function Settings:ShowExportError(message)
    if not self.frame or not self.frame:IsShown() then
        return
    end
    self.statusText:SetText(message or "MacroStudio Export failed.")
    self.statusText:SetTextColor(1, 0.4, 0.35)
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
