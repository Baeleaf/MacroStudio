local _, MacroStudio = ...

local Editor = {
    categoryMenuRows = {},
    tagMenuRows = {},
}
MacroStudio.Editor = Editor

local NORMAL_COLOR = { 0.82, 0.86, 0.92 }
local WARNING_COLOR = { 1, 0.68, 0.2 }
local ERROR_COLOR = { 1, 0.3, 0.3 }
local SUCCESS_COLOR = { 0.35, 0.9, 0.45 }

local function createPopupMenu(parent, width)
    local menu = MacroStudio.Helpers:CreatePanel(parent)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetWidth(width)
    menu:Hide()
    return menu
end

local function createMenuRow(menu)
    local row = CreateFrame("Button", nil, menu, "BackdropTemplate")
    row:SetHeight(23)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row:SetBackdropColor(0.065, 0.08, 0.105, 1)

    local text = MacroStudio.Helpers:CreateLabel(row, "GameFontNormalSmall", "")
    text:SetPoint("LEFT", 7, 0)
    text:SetPoint("RIGHT", -7, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    row.Text = text

    row:SetScript("OnEnter", function(button)
        button:SetBackdropColor(0.12, 0.24, 0.34, 1)
    end)
    row:SetScript("OnLeave", function(button)
        button:SetBackdropColor(0.065, 0.08, 0.105, 1)
    end)
    return row
end

function Editor:ResizeEditBox()
    if not self.editBox or not self.scrollFrame then
        return
    end

    local availableHeight = math.max(1, self.scrollFrame:GetHeight())
    local contentHeight = 0
    if self.measureText then
        self.measureText:SetWidth(math.max(1, self.editBox:GetWidth() - 16))
        self.measureText:SetText(self.editBox:GetText() or "")
        contentHeight = tonumber(self.measureText:GetStringHeight()) or 0
    end

    -- GetStringHeight belongs to FontString, not EditBox, on Retail.
    self.editBox:SetHeight(math.max(availableHeight, contentHeight + 24))
end

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

    local favoriteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    favoriteButton:SetSize(108, 24)
    favoriteButton:SetPoint("TOPRIGHT", -14, -43)
    favoriteButton:SetText("☆ Favorite")
    favoriteButton:SetScript("OnClick", function()
        MacroStudio:ToggleSelectedFavorite()
    end)
    self.favoriteButton = favoriteButton

    local nameText = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "No macro selected")
    nameText:SetPoint("TOPLEFT", 72, -44)
    nameText:SetPoint("TOPRIGHT", favoriteButton, "TOPLEFT", -10, -1)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    self.nameText = nameText

    local scopeText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "Select a macro from the list.")
    scopeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
    scopeText:SetTextColor(0.6, 0.68, 0.78)
    self.scopeText = scopeText

    local categoryLabel = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalSmall", "Category:")
    categoryLabel:SetPoint("TOPLEFT", 14, -96)

    local categoryButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    categoryButton:SetSize(170, 22)
    categoryButton:SetPoint("LEFT", categoryLabel, "RIGHT", 8, 0)
    categoryButton:SetText("Uncategorized")
    categoryButton:SetScript("OnClick", function()
        self:ToggleCategoryMenu()
    end)
    self.categoryButton = categoryButton

    local tagsLabel = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalSmall", "Tags:")
    tagsLabel:SetPoint("TOPLEFT", 14, -127)

    local addTagButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addTagButton:SetSize(66, 22)
    addTagButton:SetPoint("TOPRIGHT", -14, -119)
    addTagButton:SetText("+ Add")
    addTagButton:SetScript("OnClick", function()
        MacroStudio:PromptAddTag()
    end)
    self.addTagButton = addTagButton

    local removeTagButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    removeTagButton:SetSize(76, 22)
    removeTagButton:SetPoint("RIGHT", addTagButton, "LEFT", -6, 0)
    removeTagButton:SetText("Remove")
    removeTagButton:SetScript("OnClick", function()
        self:ToggleTagMenu()
    end)
    self.removeTagButton = removeTagButton

    local tagsText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "None")
    tagsText:SetPoint("LEFT", tagsLabel, "RIGHT", 8, 0)
    tagsText:SetPoint("RIGHT", removeTagButton, "LEFT", -8, 0)
    tagsText:SetJustifyH("LEFT")
    tagsText:SetWordWrap(false)
    tagsText:SetTextColor(0.68, 0.76, 0.86)
    self.tagsText = tagsText

    local duplicateText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "")
    duplicateText:SetPoint("TOPLEFT", 14, -153)
    duplicateText:SetPoint("TOPRIGHT", -14, -153)
    duplicateText:SetJustifyH("LEFT")
    duplicateText:SetWordWrap(false)
    duplicateText:SetTextColor(unpack(WARNING_COLOR))
    self.duplicateText = duplicateText

    local editBorder = MacroStudio.Helpers:CreatePanel(panel)
    editBorder:SetPoint("TOPLEFT", 14, -176)
    editBorder:SetPoint("BOTTOMRIGHT", -14, 70)
    editBorder:SetBackdropColor(0.018, 0.024, 0.035, 1)
    self.editBorder = editBorder

    local measureText = editBorder:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    measureText:SetPoint("TOPLEFT", editBorder, "TOPLEFT", 0, 0)
    measureText:SetWidth(400)
    measureText:SetJustifyH("LEFT")
    measureText:SetWordWrap(true)
    measureText:SetNonSpaceWrap(true)
    measureText:SetAlpha(0)
    self.measureText = measureText

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
    editBox:SetScript("OnTextChanged", function(_, userInput)
        self:ResizeEditBox()
        if not self.suppressTextChanged then
            self.notice = nil
            self:UpdateEditorState(userInput and "user" or "unsuppressed")
        end
    end)

    scrollFrame:SetScript("OnSizeChanged", function(frame)
        editBox:SetWidth(math.max(1, frame:GetWidth() - 4))
        self:ResizeEditBox()
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

    local categoryMenu = createPopupMenu(panel, 184)
    categoryMenu:SetPoint("TOPLEFT", categoryButton, "BOTTOMLEFT", 0, -2)
    self.categoryMenu = categoryMenu

    local tagMenu = createPopupMenu(panel, 184)
    tagMenu:SetPoint("TOPRIGHT", removeTagButton, "BOTTOMRIGHT", 0, -2)
    self.tagMenu = tagMenu

    self.savedBody = ""
    self.externalConflict = false
    self:Clear()
    return panel
end

function Editor:SetEditorText(text)
    self.suppressTextChanged = true
    self.editBox:SetText(type(text) == "string" and text or "")
    self.editBox:SetCursorPosition(0)
    self.scrollFrame:SetVerticalScroll(0)
    self.suppressTextChanged = false
    self:ResizeEditBox()
    self:UpdateEditorState("programmatic")
end

function Editor:SetMacro(macro)
    self.macro = macro
    self.savedBody = macro and macro.body or ""
    self.externalConflict = false
    self.notice = nil

    self.nameText:SetText(macro and macro.name or "No macro selected")
    self.scopeText:SetText(macro and (macro.scope == "ACCOUNT" and "Account Macro" or "Character Macro") or "Select a macro from the list.")
    self.icon:SetTexture(macro and macro.icon or MacroStudio.DEFAULT_ICON)
    self:HideMetadataMenus()
    self:SetEditorText(self.savedBody)
    self:RefreshMetadata()
end

function Editor:Clear()
    self:SetMacro(nil)
end

function Editor:GetBody()
    return self.editBox and self.editBox:GetText() or ""
end

function Editor:IsDirty()
    return self.state and self.state.dirty or false
end

function Editor:SetExternalConflict(conflicted)
    self.externalConflict = conflicted and true or false
    self:UpdateEditorState("conflict")
end

function Editor:SetNotice(message, isError)
    self.notice = {
        message = message,
        color = isError and ERROR_COLOR or SUCCESS_COLOR,
    }
    self:UpdateEditorState("notice")
end

function Editor:UpdateEditorState(reason)
    if not self.editBox then
        return
    end

    local hasMacro = self.macro ~= nil
    local body = self:GetBody()
    local dirty = hasMacro and body ~= self.savedBody or false
    local length = MacroStudio.Helpers:TextLength(body)
    local overBy = length - MacroStudio.MAX_BODY_LENGTH
    local canSave = hasMacro
        and dirty
        and not MacroStudio.inCombat
        and not self.externalConflict
        and length <= MacroStudio.MAX_BODY_LENGTH
    local canRevert = hasMacro and dirty

    if self.state and self.state.dirty ~= dirty then
        MacroStudio:Debug(dirty and "editor became dirty" or "editor returned clean", reason or "state")
    end

    self.state = {
        body = body,
        dirty = dirty,
        length = length,
        overBy = overBy,
        canSave = canSave,
        canRevert = canRevert,
    }

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
        statusMessage = "Saved version changed outside MacroStudio; unsaved text was preserved. Revert to reload it."
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
    MacroStudio.Helpers:SetButtonEnabled(self.saveButton, canSave)
    MacroStudio.Helpers:SetButtonEnabled(self.revertButton, canRevert)
end

function Editor:RefreshState()
    self:UpdateEditorState("refresh")
end

function Editor:RefreshMetadata()
    local hasMacro = self.macro ~= nil
    local presentation = MacroStudio.MetadataRepository:GetPresentation(self.macro)
    self.favoriteButton:SetText(presentation.favorite and "★ Favorite" or "☆ Favorite")
    self.categoryButton:SetText(presentation.categoryName)
    self.tagsText:SetText(#presentation.tags > 0 and table.concat(presentation.tags, ", ") or "None")

    if self.macro and self.macro.duplicateName then
        self.duplicateText:SetText(string.format(
            "⚠ Duplicate macro name — %d %s macros are named %q.",
            self.macro.duplicateCount or 2,
            self.macro.scope == "ACCOUNT" and "account" or "character",
            self.macro.name
        ))
    else
        self.duplicateText:SetText("")
    end

    MacroStudio.Helpers:SetButtonEnabled(self.favoriteButton, hasMacro)
    MacroStudio.Helpers:SetButtonEnabled(self.categoryButton, hasMacro)
    MacroStudio.Helpers:SetButtonEnabled(self.addTagButton, hasMacro)
    MacroStudio.Helpers:SetButtonEnabled(self.removeTagButton, hasMacro and #presentation.tags > 0)
end

function Editor:HideMetadataMenus()
    if self.categoryMenu then
        self.categoryMenu:Hide()
    end
    if self.tagMenu then
        self.tagMenu:Hide()
    end
end

function Editor:ToggleCategoryMenu()
    if not self.macro then
        return
    end
    self.tagMenu:Hide()
    if self.categoryMenu:IsShown() then
        self.categoryMenu:Hide()
        return
    end

    local items = { { id = nil, name = "Uncategorized" } }
    for _, category in ipairs(MacroStudio.MetadataRepository:GetCategories()) do
        items[#items + 1] = category
    end

    for index, item in ipairs(items) do
        local row = self.categoryMenuRows[index]
        if not row then
            row = createMenuRow(self.categoryMenu)
            row:SetScript("OnClick", function(button)
                self.categoryMenu:Hide()
                MacroStudio:AssignSelectedCategory(button.categoryId)
            end)
            self.categoryMenuRows[index] = row
        end
        row.categoryId = item.id
        row.Text:SetText(item.name)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 23))
        row:SetPoint("TOPRIGHT", -4, -4 - ((index - 1) * 23))
        row:Show()
    end
    for index = #items + 1, #self.categoryMenuRows do
        self.categoryMenuRows[index]:Hide()
    end
    self.categoryMenu:SetHeight(8 + (#items * 23))
    self.categoryMenu:Show()
end

function Editor:ToggleTagMenu()
    if not self.macro then
        return
    end
    self.categoryMenu:Hide()
    if self.tagMenu:IsShown() then
        self.tagMenu:Hide()
        return
    end

    local tags = MacroStudio.MetadataRepository:GetPresentation(self.macro).tags
    if #tags == 0 then
        return
    end

    for index, tag in ipairs(tags) do
        local row = self.tagMenuRows[index]
        if not row then
            row = createMenuRow(self.tagMenu)
            row:SetScript("OnClick", function(button)
                self.tagMenu:Hide()
                MacroStudio:RemoveSelectedTag(button.tag)
            end)
            self.tagMenuRows[index] = row
        end
        row.tag = tag
        row.Text:SetText("Remove " .. tag)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 23))
        row:SetPoint("TOPRIGHT", -4, -4 - ((index - 1) * 23))
        row:Show()
    end
    for index = #tags + 1, #self.tagMenuRows do
        self.tagMenuRows[index]:Hide()
    end
    self.tagMenu:SetHeight(8 + (#tags * 23))
    self.tagMenu:Show()
end
