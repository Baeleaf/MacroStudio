local _, MacroStudio = ...

local Editor = {}
MacroStudio.Editor = Editor

local NORMAL_COLOR = { 0.82, 0.86, 0.92 }
local WARNING_COLOR = { 1, 0.68, 0.2 }
local ERROR_COLOR = { 1, 0.3, 0.3 }
local SUCCESS_COLOR = { 0.35, 0.9, 0.45 }

function Editor:Create(parent)
    local panel = MacroStudio.Helpers:CreatePanel(parent)
    self.panel = panel

    local heading = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "EDITOR")
    heading:SetPoint("TOPLEFT", 14, -14)

    local dirtyText = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormal", "")
    dirtyText:SetPoint("LEFT", heading, "RIGHT", 12, 0)
    dirtyText:SetTextColor(1, 0.68, 0.2)
    self.dirtyText = dirtyText

    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(46, 46)
    icon:SetPoint("TOPLEFT", 14, -43)
    icon:SetTexture(MacroStudio.DEFAULT_ICON)
    self.icon = icon

    local nameText = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "No macro selected")
    nameText:SetPoint("TOPLEFT", 72, -44)
    nameText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -44)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    self.nameText = nameText

    local scopeText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "Select a macro from the list.")
    scopeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
    scopeText:SetTextColor(0.6, 0.68, 0.78)
    self.scopeText = scopeText

    local editBorder = MacroStudio.Helpers:CreatePanel(panel)
    editBorder:SetPoint("TOPLEFT", 14, -104)
    editBorder:SetPoint("BOTTOMRIGHT", -14, 70)
    editBorder:SetBackdropColor(0.018, 0.024, 0.035, 1)
    self.editBorder = editBorder

    local scrollFrame = CreateFrame("ScrollFrame", nil, editBorder, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 5)
    self.scrollFrame = scrollFrame

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(0.9, 0.92, 0.96)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetMaxLetters(0)
    editBox:SetWidth(400)
    editBox:SetHeight(100)
    scrollFrame:SetScrollChild(editBox)
    self.editBox = editBox

    editBox:SetScript("OnEscapePressed", function(box)
        box:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        editBorder:SetBackdropBorderColor(0.25, 0.62, 1, 1)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        editBorder:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)
    end)
    editBox:SetScript("OnTextChanged", function(box)
        local availableHeight = math.max(1, scrollFrame:GetHeight())
        box:SetHeight(math.max(availableHeight, box:GetStringHeight() + 24))
        if not self.loading then
            self.notice = nil
            MacroStudio:OnEditorTextChanged()
        end
    end)

    scrollFrame:SetScript("OnSizeChanged", function(frame)
        editBox:SetWidth(math.max(1, frame:GetWidth() - 4))
        editBox:SetHeight(math.max(frame:GetHeight(), editBox:GetStringHeight() + 24))
    end)

    local countText = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormal", "0 / 255")
    countText:SetPoint("BOTTOMLEFT", 14, 43)
    self.countText = countText

    local stateText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "No macro selected.")
    stateText:SetPoint("BOTTOMLEFT", 14, 19)
    stateText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -190, 19)
    stateText:SetJustifyH("LEFT")
    stateText:SetWordWrap(false)
    self.stateText = stateText

    local saveButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveButton:SetSize(82, 24)
    saveButton:SetPoint("BOTTOMRIGHT", -14, 16)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        MacroStudio:SaveSelectedMacro()
    end)
    self.saveButton = saveButton

    local revertButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    revertButton:SetSize(82, 24)
    revertButton:SetPoint("RIGHT", saveButton, "LEFT", -8, 0)
    revertButton:SetText("Revert")
    revertButton:SetScript("OnClick", function()
        MacroStudio:RevertSelectedMacro()
    end)
    self.revertButton = revertButton

    self.savedBody = ""
    self.externalConflict = false
    self:Clear()
    return panel
end

function Editor:SetMacro(macro)
    self.loading = true
    self.macro = macro
    self.savedBody = macro and macro.body or ""
    self.externalConflict = false
    self.notice = nil

    self.nameText:SetText(macro and macro.name or "No macro selected")
    self.scopeText:SetText(macro and (macro.scope == "ACCOUNT" and "Account Macro" or "Character Macro") or "Select a macro from the list.")
    self.icon:SetTexture(macro and macro.icon or MacroStudio.DEFAULT_ICON)
    self.editBox:SetText(self.savedBody)
    self.editBox:SetCursorPosition(0)
    self.scrollFrame:SetVerticalScroll(0)
    self.loading = false
    self:RefreshState()
end

function Editor:Clear()
    self:SetMacro(nil)
end

function Editor:GetBody()
    return self.editBox and self.editBox:GetText() or ""
end

function Editor:IsDirty()
    return self.macro ~= nil and self:GetBody() ~= self.savedBody
end

function Editor:SetExternalConflict(conflicted)
    self.externalConflict = conflicted and true or false
    self:RefreshState()
end

function Editor:SetNotice(message, isError)
    self.notice = {
        message = message,
        color = isError and ERROR_COLOR or SUCCESS_COLOR,
    }
    self:RefreshState()
end

function Editor:RefreshState()
    if not self.editBox then
        return
    end

    local hasMacro = self.macro ~= nil
    local dirty = self:IsDirty()
    local length = MacroStudio.Helpers:TextLength(self:GetBody())
    local overBy = length - MacroStudio.MAX_BODY_LENGTH

    self.editBox:SetEnabled(hasMacro)
    self.dirtyText:SetText(dirty and "Unsaved changes" or "")
    self.countText:SetText(string.format("%d / %d", length, MacroStudio.MAX_BODY_LENGTH))

    if length > MacroStudio.MAX_BODY_LENGTH then
        self.countText:SetTextColor(unpack(ERROR_COLOR))
    elseif length >= MacroStudio.BODY_WARNING_LENGTH then
        self.countText:SetTextColor(unpack(WARNING_COLOR))
    else
        self.countText:SetTextColor(unpack(NORMAL_COLOR))
    end

    local statusMessage
    local statusColor = NORMAL_COLOR
    if not hasMacro then
        statusMessage = "No macro selected."
    elseif MacroStudio.inCombat then
        statusMessage = "Combat Lockdown — native macros cannot be modified until combat ends."
        statusColor = ERROR_COLOR
    elseif self.externalConflict then
        statusMessage = "This macro changed outside MacroStudio. Save is blocked; Revert or select it again."
        statusColor = ERROR_COLOR
    elseif overBy > 0 then
        statusMessage = string.format("Too long by %d character%s — cannot save.", overBy, overBy == 1 and "" or "s")
        statusColor = ERROR_COLOR
    elseif self.notice then
        statusMessage = self.notice.message
        statusColor = self.notice.color
    elseif length >= MacroStudio.BODY_WARNING_LENGTH then
        statusMessage = string.format("Approaching the native limit: %d characters remain.", MacroStudio.MAX_BODY_LENGTH - length)
        statusColor = WARNING_COLOR
    elseif dirty then
        statusMessage = "Unsaved editor changes."
        statusColor = WARNING_COLOR
    else
        statusMessage = "Saved body is up to date."
    end

    self.stateText:SetText(statusMessage)
    self.stateText:SetTextColor(unpack(statusColor))

    local canSave = hasMacro
        and dirty
        and not MacroStudio.inCombat
        and not self.externalConflict
        and length <= MacroStudio.MAX_BODY_LENGTH
    local canRevert = hasMacro and dirty
    MacroStudio.Helpers:SetButtonEnabled(self.saveButton, canSave)
    MacroStudio.Helpers:SetButtonEnabled(self.revertButton, canRevert)
end
