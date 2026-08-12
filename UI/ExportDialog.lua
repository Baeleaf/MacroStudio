local _, MacroStudio = ...

local ExportDialog = {
    MAX_DISPLAY_BYTES = 4 * 1024 * 1024,
}
MacroStudio.ExportDialog = ExportDialog

local function summaryText(summary)
    return string.format(
        "Account macros: %d    Current-character macros: %d    Offline characters: %d\n"
            .. "Offline macro snapshots: %d    Categories: %d    Tags: %d    Favorites: %d",
        summary.accountMacros,
        summary.currentCharacterMacros,
        summary.offlineCharacters,
        summary.offlineMacros,
        summary.categories,
        summary.tags,
        summary.favorites
    )
end

function ExportDialog:Create()
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame("Frame", "MacroStudioExportFrame", UIParent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.025, 0.03, 0.045, 0.99)
    frame:SetBackdropBorderColor(0.25, 0.3, 0.38, 1)
    frame:SetSize(780, 610)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(42)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local title = MacroStudio.Helpers:CreateLabel(titleBar, "GameFontNormalLarge", "Export MacroStudio Library")
    title:SetPoint("LEFT", 17, 0)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    local explanation = MacroStudio.Helpers:CreateLabel(
        frame,
        "GameFontHighlightSmall",
        "This portable text contains saved macro-library content for future import or restore. "
            .. "Unsaved editor drafts and local UI settings are not included. Select the text and copy it manually."
    )
    explanation:SetPoint("TOPLEFT", 18, -50)
    explanation:SetPoint("TOPRIGHT", -18, -50)
    explanation:SetHeight(34)
    explanation:SetJustifyH("LEFT")
    explanation:SetJustifyV("TOP")
    explanation:SetWordWrap(true)

    local format = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalSmall", "Portable format version 1")
    format:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -7)
    format:SetTextColor(0.35, 0.75, 1)
    self.formatText = format

    local summary = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    summary:SetPoint("TOPLEFT", format, "BOTTOMLEFT", 0, -7)
    summary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -103)
    summary:SetHeight(36)
    summary:SetJustifyH("LEFT")
    summary:SetJustifyV("TOP")
    summary:SetWordWrap(true)
    self.summaryText = summary

    local textPanel = MacroStudio.Helpers:CreatePanel(frame)
    textPanel:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -9)
    textPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 52)

    local _, editBox, scrollBox = MacroStudio.Helpers:CreateNativeScrollingEditBox(textPanel, 6)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(0.86, 0.9, 0.96)
    editBox:SetWordWrap(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    editBox:HookScript("OnTextChanged", function(owner, userInput)
        if self.settingText or not userInput or not self.exportText then
            return
        end
        if owner:GetText() ~= self.exportText then
            self.settingText = true
            owner:SetText(self.exportText)
            self.settingText = false
            owner:SetFocus()
        end
    end)
    self.editBox = editBox
    self.scrollBox = scrollBox

    local selectAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAll:SetSize(120, 26)
    selectAll:SetPoint("BOTTOMLEFT", 18, 16)
    selectAll:SetText("Select All")
    selectAll:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    MacroStudio.Helpers:SetButtonTooltip(
        selectAll,
        "Select Export Text",
        "Select all text, then press Ctrl+C to copy it. WoW does not allow addons to write directly to the system clipboard."
    )
    self.selectAllButton = selectAll

    local done = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    done:SetSize(90, 26)
    done:SetPoint("BOTTOMRIGHT", -18, 16)
    done:SetText("Done")
    done:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame:SetScript("OnHide", function()
        editBox:ClearFocus()
        MacroStudio:SetMainWindowModalBlocked(false)
    end)

    if UISpecialFrames then
        UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
    end
    self.frame = frame
    MacroStudio:Debug("Export frame created")
    return frame
end

function ExportDialog:SetExport(text, summary)
    local frame = self:Create()
    self.formatText:SetText("Portable format version " .. MacroStudio.PortableExport.FORMAT_VERSION)
    self.summaryText:SetText(summaryText(summary))

    if type(text) ~= "string" or text == "" then
        self.settingText = true
        self.editBox:SetText("")
        self.settingText = false
        MacroStudio.Helpers:SetButtonEnabled(self.selectAllButton, false)
        self.exportText = nil
        self.summaryText:SetText("Export failed: no portable text was generated.")
        self.summaryText:SetTextColor(1, 0.35, 0.3)
        return false
    end
    if #text > self.MAX_DISPLAY_BYTES then
        self.settingText = true
        self.editBox:SetText("")
        self.settingText = false
        MacroStudio.Helpers:SetButtonEnabled(self.selectAllButton, false)
        self.exportText = nil
        self.summaryText:SetText(string.format(
            "Export failed visibly: %d bytes exceeds the %d-byte display safety limit. No partial export was shown.",
            #text,
            self.MAX_DISPLAY_BYTES
        ))
        self.summaryText:SetTextColor(1, 0.35, 0.3)
        return false
    end

    self.settingText = true
    local ok = pcall(self.editBox.SetText, self.editBox, text)
    self.settingText = false
    if not ok or self.editBox:GetText() ~= text then
        self.exportText = nil
        self.editBox:SetText("")
        self.summaryText:SetText("Export failed visibly because the complete text could not be displayed. No partial export was shown.")
        self.summaryText:SetTextColor(1, 0.35, 0.3)
        MacroStudio.Helpers:SetButtonEnabled(self.selectAllButton, false)
        return false
    end

    self.exportText = text
    MacroStudio.Helpers:SetButtonEnabled(self.selectAllButton, true)
    self.summaryText:SetTextColor(0.72, 0.78, 0.88)
    self.editBox:SetCursorPosition(0)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.scrollBox)
    frame:Raise()
    return true
end

function ExportDialog:Open(source)
    MacroStudio:Debug("export open invoked", source or "unknown")
    if not MacroStudio.initialized then
        MacroStudio:Initialize()
    end
    local frame = self:Create()
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    local settingsShown = settingsFrame and settingsFrame:IsShown() or false
    if MacroStudio:IsMainWindowModalBlocked() and not frame:IsShown() and not settingsShown then
        MacroStudio:Print("Close the current dialog before opening Export.")
        return false
    end

    MacroStudio:Debug("Export serialization start")
    local text, summary = MacroStudio.PortableExport:Generate()
    MacroStudio:Debug("Export serialization complete", type(text) == "string" and #text or 0, "bytes")
    local displayComplete = self:SetExport(text, summary)

    if settingsShown then
        settingsFrame:Hide()
    end

    MacroStudio:SetMainWindowModalBlocked(true)
    frame:Show()
    frame:Raise()
    MacroStudio:Debug("Export frame shown", frame:IsShown())
    return displayComplete
end
