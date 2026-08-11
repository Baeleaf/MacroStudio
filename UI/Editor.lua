local _, MacroStudio = ...

local Editor = {
    categoryMenuRows = {},
    addTagMenuRows = {},
    tagMenuRows = {},
}
MacroStudio.Editor = Editor

local NORMAL_COLOR = { 0.82, 0.86, 0.92 }
local WARNING_COLOR = { 1, 0.68, 0.2 }
local ERROR_COLOR = { 1, 0.3, 0.3 }
local SUCCESS_COLOR = { 0.35, 0.9, 0.45 }
local EDITOR_BORDER_NORMAL = { 0.18, 0.22, 0.28, 1 }
local EDITOR_BORDER_FOCUSED = { 0.25, 0.62, 1, 1 }

local function formatSlots(slots)
    local labels = {}
    for index, slot in ipairs(slots or {}) do
        labels[index] = tostring(slot)
    end
    return table.concat(labels, ", ")
end

local function isShiftDown()
    return type(IsShiftKeyDown) == "function" and IsShiftKeyDown() and true or false
end

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

function Editor:SetEditorFocusBorder(focused)
    if not self.editBorder then
        return
    end

    self.editorFocusBorderActive = focused and true or false
    local color = self.editorFocusBorderActive and EDITOR_BORDER_FOCUSED or EDITOR_BORDER_NORMAL
    self.editBorder:SetBackdropBorderColor(unpack(color))
    MacroStudio.Helpers:SetOverlayBorderColor(self.editorFocusBorderEdges, unpack(color))
end


function Editor:CreateFavoriteButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(120, 26)
    button:SetPoint("TOPRIGHT", -14, -42)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("LEFT", 8, 0)
    icon:SetAtlas("PetJournal-FavoritesIcon")
    button.Icon = icon

    local text = MacroStudio.Helpers:CreateLabel(button, "GameFontNormalSmall", "Favorite")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetPoint("RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    button.Text = text

    button:SetScript("OnClick", function()
        MacroStudio:ToggleSelectedFavorite()
    end)
    MacroStudio.Helpers:SetButtonTooltip(button, "Favorite", "Include or remove this macro from the Favorites filter.")
    return button
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

    local usageButton = CreateFrame("Button", nil, panel)
    usageButton:SetSize(170, 20)
    usageButton:SetPoint("TOPRIGHT", -14, -11)
    local usageText = MacroStudio.Helpers:CreateLabel(usageButton, "GameFontNormalSmall", "")
    usageText:SetAllPoints(usageButton)
    usageText:SetJustifyH("RIGHT")
    usageText:SetTextColor(0.35, 0.75, 1)
    usageButton.Text = usageText
    usageButton:Hide()
    MacroStudio.Helpers:SetButtonTooltip(usageButton)
    usageButton:SetScript("OnEnter", function()
        self:UpdateActionBarUsageTooltip()
    end)
    self.usageButton = usageButton

    local iconButton = CreateFrame("Button", nil, panel)
    iconButton:SetSize(46, 46)
    iconButton:SetPoint("TOPLEFT", 14, -43)
    local icon = iconButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconButton)
    icon:SetTexture(MacroStudio.DEFAULT_ICON)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local iconHighlight = iconButton:CreateTexture(nil, "HIGHLIGHT")
    iconHighlight:SetAllPoints(iconButton)
    iconHighlight:SetColorTexture(1, 1, 1, 0.2)
    iconButton.Icon = icon
    iconButton:SetScript("OnClick", function()
        self:ChooseIcon()
    end)
    MacroStudio.Helpers:SetButtonTooltip(iconButton, "Change Macro Icon", "Choose a saved icon for this native macro.")
    self.iconButton = iconButton
    self.icon = icon

    local offlineIcon = panel:CreateTexture(nil, "ARTWORK")
    offlineIcon:SetSize(46, 46)
    offlineIcon:SetPoint("TOPLEFT", 14, -43)
    offlineIcon:SetTexture(MacroStudio.DEFAULT_ICON)
    offlineIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    offlineIcon:Hide()
    self.offlineIcon = offlineIcon

    local favoriteButton = self:CreateFavoriteButton(panel)
    self.favoriteButton = favoriteButton

    local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteButton:SetSize(110, 21)
    deleteButton:SetPoint("TOPRIGHT", -14, -73)
    deleteButton:SetText("Delete Macro")
    deleteButton:SetScript("OnClick", function()
        MacroStudio:RequestDeleteSelectedMacro()
    end)
    self.deleteButton = deleteButton

    local nameBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    nameBox:SetHeight(24)
    nameBox:SetPoint("TOPLEFT", 72, -40)
    nameBox:SetPoint("TOPRIGHT", favoriteButton, "TOPLEFT", -10, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetFontObject(GameFontNormalLarge)
    nameBox:SetMaxLetters(MacroStudio.MAX_NAME_LENGTH)
    nameBox:SetText("No macro selected")
    nameBox:SetScript("OnEscapePressed", function(box)
        box:ClearFocus()
    end)
    nameBox:SetScript("OnEnterPressed", function(box)
        box:ClearFocus()
    end)
    self.nameBox = nameBox

    local offlineNameText = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "")
    offlineNameText:SetPoint("TOPLEFT", 72, -43)
    offlineNameText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -43)
    offlineNameText:SetJustifyH("LEFT")
    offlineNameText:SetWordWrap(false)
    offlineNameText:Hide()
    self.offlineNameText = offlineNameText

    local scopeText = MacroStudio.Helpers:CreateLabel(panel, "GameFontHighlightSmall", "Select a macro from the list.")
    scopeText:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -3)
    scopeText:SetPoint("RIGHT", deleteButton, "LEFT", -8, 0)
    scopeText:SetTextColor(0.6, 0.68, 0.78)
    scopeText:SetWordWrap(false)
    self.scopeText = scopeText

    local categoryLabel = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalSmall", "Category:")
    categoryLabel:SetPoint("TOPLEFT", 14, -101)
    self.categoryLabel = categoryLabel

    local categoryButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    categoryButton:SetSize(170, 22)
    categoryButton:SetPoint("LEFT", categoryLabel, "RIGHT", 8, 0)
    categoryButton:SetText("Uncategorized")
    categoryButton:SetScript("OnClick", function()
        self:ToggleCategoryMenu()
    end)
    self.categoryButton = categoryButton

    local tagsLabel = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalSmall", "Tags:")
    tagsLabel:SetPoint("TOPLEFT", 14, -132)
    self.tagsLabel = tagsLabel

    local addTagButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addTagButton:SetSize(66, 22)
    addTagButton:SetPoint("TOPRIGHT", -14, -124)
    addTagButton:SetText("+ Add")
    addTagButton:SetScript("OnClick", function()
        self:ToggleAddTagMenu()
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
    duplicateText:SetPoint("TOPLEFT", 14, -158)
    duplicateText:SetPoint("TOPRIGHT", -14, -158)
    duplicateText:SetJustifyH("LEFT")
    duplicateText:SetWordWrap(false)
    duplicateText:SetTextColor(unpack(WARNING_COLOR))
    self.duplicateText = duplicateText

    local editBorder = MacroStudio.Helpers:CreatePanel(panel)
    editBorder:SetPoint("TOPLEFT", 14, -181)
    editBorder:SetPoint("BOTTOMRIGHT", -14, 70)
    editBorder:SetBackdropColor(0.018, 0.024, 0.035, 1)
    self.editBorder = editBorder

    local editorHost, editBox, scrollBox, scrollBar = MacroStudio.Helpers:CreateNativeScrollingEditBox(editBorder, 5)
    self.editorHost = editorHost
    self.scrollBox = scrollBox
    self.scrollBar = scrollBar
    self.editBox = editBox

    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(0.9, 0.92, 0.96)
    editBox:SetTextInsets(6, 6, 6, 6)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")

    local focusBorder, focusBorderEdges = MacroStudio.Helpers:CreateOverlayBorder(editBorder, scrollBar, 2)
    self.editorFocusBorder = focusBorder
    self.editorFocusBorderEdges = focusBorderEdges
    self:SetEditorFocusBorder(false)

    editBox:HookScript("OnEscapePressed", function(box)
        box:ClearFocus()
    end)
    editBox:HookScript("OnEditFocusGained", function()
        self:SetEditorFocusBorder(true)
    end)
    editBox:HookScript("OnEditFocusLost", function()
        self:SetEditorFocusBorder(false)
    end)
    editBox:HookScript("OnTextChanged", function(_, userInput)
        if not self.suppressTextChanged and not self.suppressDraftChanged then
            if MacroStudio:IsOfflineMacro(self.macro) and self:GetBody() ~= self.savedBody then
                self.suppressTextChanged = true
                editBox:SetText(self.savedBody)
                self.suppressTextChanged = false
                self.notice = {
                    message = "Offline snapshots are read-only; the saved text was restored.",
                    color = ERROR_COLOR,
                }
                self:UpdateEditorState("read-only")
                return
            end
            self.notice = nil
            self:UpdateEditorState(userInput and "user" or "unsuppressed")
        end
    end)

    nameBox:HookScript("OnTextChanged", function(_, userInput)
        if self.suppressNameChanged or self.suppressDraftChanged then
            return
        end
        if MacroStudio:IsOfflineMacro(self.macro) and self:GetName() ~= self.savedName then
            self:SetEditorName(self.savedName)
            self.notice = {
                message = "Offline snapshots are read-only; the saved name was restored.",
                color = ERROR_COLOR,
            }
            self:UpdateEditorState("read-only")
            return
        end
        if userInput then
            local name = self:GetName()
            local withoutQuotes = name:gsub('"', "")
            if withoutQuotes ~= name then
                self:SetEditorName(withoutQuotes)
                self.notice = {
                    message = "Quotation marks are not supported in native macro names.",
                    color = WARNING_COLOR,
                }
                self:UpdateEditorState("name-sanitized")
                return
            end
        end
        self.notice = nil
        self:UpdateEditorState(userInput and "name-user" or "name-unsuppressed")
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
    local copyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    copyButton:SetSize(190, 24)
    copyButton:SetPoint("TOPRIGHT", -14, -9)
    copyButton:SetText("Copy to Current Character")
    copyButton:SetScript("OnClick", function()
        MacroStudio:CopySelectedSnapshotToCurrentCharacter()
    end)
    copyButton:Hide()
    self.copyButton = copyButton

    local categoryMenu = createPopupMenu(panel, 184)
    categoryMenu:SetPoint("TOPLEFT", categoryButton, "BOTTOMLEFT", 0, -2)
    self.categoryMenu = categoryMenu

    local addTagMenu = createPopupMenu(panel, 200)
    addTagMenu:SetPoint("TOPRIGHT", addTagButton, "BOTTOMRIGHT", 0, -2)
    self.addTagMenu = addTagMenu

    local tagMenu = createPopupMenu(panel, 200)
    tagMenu:SetPoint("TOPRIGHT", removeTagButton, "BOTTOMRIGHT", 0, -2)
    self.tagMenu = tagMenu

    self.savedName = ""
    self.savedIcon = MacroStudio.DEFAULT_ICON
    self.savedBody = ""
    self.externalConflict = false
    self:Clear()
    return panel
end

function Editor:SetEditorText(text)
    self.suppressTextChanged = true
    self.editBox:SetText(type(text) == "string" and text or "")
    self.editBox:SetCursorPosition(0)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.scrollBox)
    self.suppressTextChanged = false
    if not self.suppressDraftChanged then
        self:UpdateEditorState("programmatic")
    end
end

function Editor:SetEditorName(text)
    self.suppressNameChanged = true
    text = type(text) == "string" and text or ""
    self.nameBox:SetText(text)
    self.nameBox:SetCursorPosition(MacroStudio.Helpers:TextLength(text))
    self.suppressNameChanged = false
    if not self.suppressDraftChanged then
        self:UpdateEditorState("name-programmatic")
    end
end

function Editor:SetDraftIcon(icon)
    self.draftIcon = icon or MacroStudio.DEFAULT_ICON
    self.icon:SetTexture(self.draftIcon)
    self.offlineIcon:SetTexture(self.draftIcon)
    if not self.suppressDraftChanged then
        self.notice = nil
        self:UpdateEditorState("icon")
    end
end

function Editor:SetMacro(macro)
    self.macro = macro
    self.savedName = macro and macro.name or ""
    self.savedIcon = macro and (macro.selectedIcon or macro.icon) or MacroStudio.DEFAULT_ICON
    self.savedBody = macro and macro.body or ""
    self.externalConflict = false
    self.notice = nil
    self.suppressDraftChanged = true

    local offline = MacroStudio:IsOfflineMacro(macro)
    self.nameBox:SetShown(not offline)
    self.offlineNameText:SetShown(offline)
    self.iconButton:SetShown(not offline)
    self.offlineIcon:SetShown(offline)

    self.scopeText:ClearAllPoints()
    if offline then
        self.scopeText:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 72, -66)
        self.scopeText:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", -14, -66)
        self.scopeText:SetWordWrap(true)
    else
        self.scopeText:SetPoint("TOPLEFT", self.nameBox, "BOTTOMLEFT", 0, -3)
        self.scopeText:SetPoint("RIGHT", self.deleteButton, "LEFT", -8, 0)
        self.scopeText:SetWordWrap(false)
    end

    self:SetEditorName(macro and macro.name or "No macro selected")
    self.offlineNameText:SetText(macro and macro.name or "")
    if offline then
        self.scopeText:SetText(
            "Viewing " .. (macro.characterDisplayName or "offline character")
                .. "  |  Read-only snapshot  |  Last synced: "
                .. MacroStudio.CharacterMacroLibrary:FormatLastSynced(macro.lastSynced)
        )
    else
        self.scopeText:SetText(
            macro and (macro.scope == "ACCOUNT" and "Account Macro" or "Character Macro")
                or "Select a macro from the list."
        )
    end
    self:SetDraftIcon(self.savedIcon)
    self:HideMetadataMenus()
    self:SetEditorText(self.savedBody)
    self.suppressDraftChanged = false
    self:RefreshMetadata()
    self:UpdateEditorState("selection")
end

function Editor:Clear()
    self:SetMacro(nil)
end

function Editor:GetName()
    return self.nameBox and self.nameBox:GetText() or ""
end

function Editor:GetIcon()
    return self.draftIcon or MacroStudio.DEFAULT_ICON
end

function Editor:GetBody()
    return self.editBox and self.editBox:GetText() or ""
end

function Editor:GetDraft()
    return {
        name = self:GetName(),
        icon = self:GetIcon(),
        body = self:GetBody(),
    }
end

function Editor:ChooseIcon()
    if not self.macro or MacroStudio:IsOfflineMacro(self.macro) or MacroStudio:IsMainWindowModalBlocked() then
        return
    end

    local selected = MacroStudio.Helpers:CopyMacro(self.macro)
    MacroStudio:SetMainWindowModalBlocked(true)
    MacroStudio.IconPicker:Open(self:GetIcon(), function(icon)
        if self.macro and MacroStudio.MacroRepository:SnapshotsEqual(self.macro, selected) then
            self:SetDraftIcon(icon)
        end
    end, {
        selectionHelp = "Use this icon when the native macro is saved.",
        onClose = function()
            MacroStudio:SetMainWindowModalBlocked(false)
        end,
    })
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

function Editor:RefreshDuplicateNotice(name, offline)
    if not self.macro then
        self.duplicateText:SetText("")
        return
    end
    if offline then
        if self.macro.duplicateName then
            self.duplicateText:SetText(string.format(
                "Duplicate macro name - %d snapshot macros are named %q.",
                self.macro.duplicateCount or 2,
                self.macro.name
            ))
        else
            self.duplicateText:SetText("")
        end
        return
    end

    local normalized = MacroStudio.MacroRepository:NormalizeMacroName(name)
    local matches = 1
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        if macro.scope == self.macro.scope
            and macro.index ~= self.macro.index
            and macro.name:lower() == normalized:lower() then
            matches = matches + 1
        end
    end
    if normalized ~= "" and matches > 1 then
        self.duplicateText:SetText(string.format(
            "Duplicate name allowed - %d %s macros will share %q.",
            matches,
            self.macro.scope == "ACCOUNT" and "account" or "character",
            normalized
        ))
    else
        self.duplicateText:SetText("")
    end
end

function Editor:UpdateEditorState(reason)
    if not self.editBox then
        return
    end

    local hasMacro = self.macro ~= nil
    local offline = MacroStudio:IsOfflineMacro(self.macro)
    local name = self:GetName()
    local icon = self:GetIcon()
    local body = self:GetBody()
    local nameDirty = hasMacro and not offline and name ~= self.savedName or false
    local iconDirty = hasMacro
        and not offline
        and not MacroStudio.Helpers:IconsEqual(icon, self.savedIcon) or false
    local bodyDirty = hasMacro and not offline and body ~= self.savedBody or false
    local dirty = nameDirty or iconDirty or bodyDirty
    local length = MacroStudio.Helpers:TextLength(body)
    local overBy = length - MacroStudio.MAX_BODY_LENGTH
    local validContent, validationMessage = MacroStudio.MacroRepository:ValidateMacroContent({
        name = name,
        icon = icon,
        body = body,
    })
    local targetSafe = hasMacro
        and not offline
        and MacroStudio.MacroRepository:IsSnapshotCurrent(self.macro) or false
    local canSave = hasMacro
        and not offline
        and dirty
        and not MacroStudio.inCombat
        and not self.externalConflict
        and targetSafe
        and validContent
        and length <= MacroStudio.MAX_BODY_LENGTH
    local canRevert = hasMacro and not offline and dirty
    local canDelete = hasMacro
        and not offline
        and not dirty
        and not MacroStudio.inCombat
        and not self.externalConflict
        and targetSafe

    local canCopy, copyReason = false, nil
    if offline then
        canCopy, copyReason = MacroStudio.MacroRepository:ValidateCreateRequest({
            name = self.macro.name,
            body = self.macro.body,
            icon = self.macro.selectedIcon or self.macro.icon,
            scope = "CHARACTER",
        })
    end

    local saveReason
    if offline then
        saveReason = "Offline character snapshots are read-only."
    elseif not hasMacro then
        saveReason = "Select a macro before saving."
    elseif not dirty then
        saveReason = "There are no unsaved changes."
    elseif not validContent then
        saveReason = validationMessage
    elseif MacroStudio.inCombat then
        saveReason = "Saving is unavailable during Combat Lockdown."
    elseif self.externalConflict or not targetSafe then
        saveReason = "This macro changed outside MacroStudio. Revert to load the latest version."
    elseif length > MacroStudio.MAX_BODY_LENGTH then
        saveReason = string.format("Shorten the body by %d characters.", overBy)
    end

    local deleteReason
    if offline then
        deleteReason = "Offline snapshots cannot delete Blizzard macros."
    elseif not hasMacro then
        deleteReason = "Select a macro before deleting."
    elseif dirty then
        deleteReason = "Save or Revert editor changes before deleting this macro."
    elseif MacroStudio.inCombat then
        deleteReason = "Deleting is unavailable during Combat Lockdown."
    elseif self.externalConflict or not targetSafe then
        deleteReason = "This macro changed outside MacroStudio. Revert before deleting it."
    end

    if self.state and self.state.dirty ~= dirty then
        MacroStudio:Debug(dirty and "editor became dirty" or "editor returned clean", reason or "state")
    end

    self.state = {
        name = name,
        icon = icon,
        body = body,
        nameDirty = nameDirty,
        iconDirty = iconDirty,
        bodyDirty = bodyDirty,
        dirty = dirty,
        validContent = validContent,
        validationMessage = validationMessage,
        length = length,
        overBy = overBy,
        offline = offline,
        targetSafe = targetSafe,
        canSave = canSave,
        saveReason = saveReason,
        canRevert = canRevert,
        canDelete = canDelete,
        deleteReason = deleteReason,
        canCopy = canCopy,
        copyReason = copyReason,
    }

    self.nameBox:SetEnabled(hasMacro and not offline)
    MacroStudio.Helpers:SetButtonEnabled(self.iconButton, hasMacro and not offline)
    self.editBox:SetEnabled(hasMacro)
    if offline then
        MacroStudio.Helpers:SetButtonTooltip(self.iconButton)
    else
        MacroStudio.Helpers:SetButtonTooltip(
            self.iconButton,
            "Change Macro Icon",
            "Choose a saved icon for this native macro."
        )
    end
    if offline then
        self.dirtyText:SetText("")
    else
        self.dirtyText:SetText(dirty and "Unsaved changes" or "")
        self.dirtyText:SetTextColor(unpack(WARNING_COLOR))
    end
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
    self:RefreshDuplicateNotice(name, offline)
    if not hasMacro then
        if self.notice then
            statusMessage = self.notice.message
            statusColor = self.notice.color
        else
            statusMessage = "No macro selected."
        end
    elseif offline then
        if self.notice then
            statusMessage = self.notice.message
            statusColor = self.notice.color
        else
            statusMessage = "Read-only snapshot. Select text or use Copy above."
        end
    elseif self.externalConflict or not targetSafe then
        statusMessage = "This macro changed outside MacroStudio. Revert to load the latest version."
        statusColor = ERROR_COLOR
    elseif not validContent then
        statusMessage = validationMessage
        statusColor = ERROR_COLOR
    elseif MacroStudio.inCombat then
        statusMessage = "Combat Lockdown - native macros cannot be modified until combat ends."
        statusColor = ERROR_COLOR
    elseif overBy > 0 then
        statusMessage = string.format("Too long by %d character%s - cannot save.", overBy, overBy == 1 and "" or "s")
        statusColor = ERROR_COLOR
    elseif self.notice then
        statusMessage = self.notice.message
        statusColor = self.notice.color
    elseif length >= MacroStudio.BODY_WARNING_LENGTH then
        statusMessage = string.format("Approaching the native limit: %d characters remain.", MacroStudio.MAX_BODY_LENGTH - length)
        statusColor = WARNING_COLOR
    elseif dirty then
        statusMessage = "Unsaved macro changes."
        statusColor = WARNING_COLOR
    else
        statusMessage = "Saved macro is up to date."
    end

    self.stateText:ClearAllPoints()
    self.stateText:SetPoint("BOTTOMLEFT", 14, 19)
    if offline then
        self.stateText:SetPoint("BOTTOMRIGHT", self.panel, "BOTTOMRIGHT", -14, 19)
    else
        self.stateText:SetPoint("BOTTOMRIGHT", self.panel, "BOTTOMRIGHT", -190, 19)
    end
    self.stateText:SetText(statusMessage)
    self.stateText:SetTextColor(unpack(statusColor))
    self.saveButton:SetShown(not offline)
    self.revertButton:SetShown(not offline)
    self.deleteButton:SetShown(not offline)
    self.copyButton:SetShown(offline)
    MacroStudio.Helpers:SetButtonEnabled(self.saveButton, canSave)
    MacroStudio.Helpers:SetButtonTooltip(
        self.saveButton,
        "Save Macro",
        canSave and "Save the drafted name, icon, and body to this native macro." or saveReason
    )
    MacroStudio.Helpers:SetButtonEnabled(self.revertButton, canRevert)
    MacroStudio.Helpers:SetButtonTooltip(
        self.revertButton,
        "Revert Editor",
        canRevert and "Discard drafted name, icon, and body changes." or "There are no editor changes to revert."
    )
    MacroStudio.Helpers:SetButtonEnabled(self.deleteButton, canDelete)
    MacroStudio.Helpers:SetButtonTooltip(self.deleteButton, "Delete Native Macro", canDelete and "Permanently delete this exact Blizzard-native macro." or deleteReason)
    MacroStudio.Helpers:SetButtonEnabled(self.copyButton, canCopy)
    MacroStudio.Helpers:SetButtonTooltip(
        self.copyButton,
        "Copy to Current Character",
        canCopy and "Create a new native Character macro from this snapshot." or copyReason
    )
    if MacroStudio.UpdateActionControls then
        MacroStudio:UpdateActionControls()
    end
end

function Editor:RefreshState()
    self:UpdateEditorState("refresh")
end

function Editor:UpdateActionBarUsageTooltip()
    local count = self.actionBarUsageCount or 0
    if count == 0 then
        MacroStudio.Helpers:SetButtonTooltip(self.usageButton)
        return
    end

    local tooltip
    if count == 1 then
        tooltip = "This saved native macro is on an action bar."
    else
        tooltip = string.format(
            "This saved native macro is on an action bar in %d placements.",
            count
        )
    end
    if isShiftDown() then
        tooltip = tooltip .. "\n\nAction Bar slots: " .. formatSlots(self.actionBarUsageSlots)
    end
    MacroStudio.Helpers:SetButtonTooltip(self.usageButton, "Action Bar Usage", tooltip)
end

function Editor:RefreshActionBarUsage()
    if not self.usageButton then
        return
    end
    if MacroStudio:IsOfflineMacro(self.macro) then
        self.actionBarUsageCount = 0
        self.actionBarUsageSlots = nil
        self.usageButton:Hide()
        MacroStudio.Helpers:SetButtonTooltip(self.usageButton)
        return
    end

    local count, slots = MacroStudio.ActionBarRepository:GetUsage(self.macro)
    self.actionBarUsageCount = count
    self.actionBarUsageSlots = slots
    if count == 0 then
        self.usageButton:Hide()
        MacroStudio.Helpers:SetButtonTooltip(self.usageButton)
        return
    end

    self.usageButton.Text:SetText(string.format(
        "On action bars: %d %s",
        count,
        count == 1 and "slot" or "slots"
    ))
    self:UpdateActionBarUsageTooltip()
    self.usageButton:Show()
end

function Editor:RefreshMetadata()
    local hasMacro = self.macro ~= nil
    local offline = MacroStudio:IsOfflineMacro(self.macro)
    local presentation = offline
        and { favorite = false, categoryName = "Unavailable", tags = {} }
        or MacroStudio.MetadataRepository:GetPresentation(self.macro)

    self.favoriteButton:SetShown(not offline)
    self.categoryLabel:SetShown(not offline)
    self.categoryButton:SetShown(not offline)
    self.tagsLabel:SetShown(not offline)
    self.tagsText:SetShown(not offline)
    self.addTagButton:SetShown(not offline)
    self.removeTagButton:SetShown(not offline)

    self.favoriteButton.Icon:SetDesaturated(not presentation.favorite)
    self.favoriteButton.Icon:SetAlpha(presentation.favorite and 1 or 0.45)
    self.favoriteButton.Text:SetText(presentation.favorite and "Favorited" or "Favorite")
    self.favoriteButton:SetBackdropColor(presentation.favorite and 0.22 or 0.06, presentation.favorite and 0.16 or 0.08, 0.05, 1)
    self.favoriteButton:SetBackdropBorderColor(presentation.favorite and 1 or 0.24, presentation.favorite and 0.65 or 0.28, 0.12, 1)
    self.categoryButton:SetText(presentation.categoryName)
    self.tagsText:SetText(#presentation.tags > 0 and table.concat(presentation.tags, ", ") or "None")

    MacroStudio.Helpers:SetButtonEnabled(self.favoriteButton, hasMacro and not offline)
    MacroStudio.Helpers:SetButtonEnabled(self.categoryButton, hasMacro and not offline)
    MacroStudio.Helpers:SetButtonEnabled(self.addTagButton, hasMacro and not offline)
    MacroStudio.Helpers:SetButtonEnabled(self.removeTagButton, hasMacro and not offline and #presentation.tags > 0)
    self:RefreshActionBarUsage()
end

function Editor:HideMetadataMenus()
    if self.categoryMenu then
        self.categoryMenu:Hide()
    end
    if self.addTagMenu then
        self.addTagMenu:Hide()
    end
    if self.tagMenu then
        self.tagMenu:Hide()
    end
end

function Editor:ToggleCategoryMenu()
    if not self.macro or MacroStudio:IsOfflineMacro(self.macro) then
        return
    end
    self.addTagMenu:Hide()
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

function Editor:ToggleAddTagMenu()
    if not self.macro or MacroStudio:IsOfflineMacro(self.macro) then
        return
    end
    self.categoryMenu:Hide()
    self.tagMenu:Hide()
    if self.addTagMenu:IsShown() then
        self.addTagMenu:Hide()
        return
    end

    local items = {}
    for _, tag in ipairs(MacroStudio.MetadataRepository:GetAllTags()) do
        if not MacroStudio.MetadataRepository:IsTagAssigned(self.macro, tag) then
            items[#items + 1] = { tag = tag, text = tag }
        end
    end
    items[#items + 1] = { createNew = true, text = "Create New Tag..." }

    for index, item in ipairs(items) do
        local row = self.addTagMenuRows[index]
        if not row then
            row = createMenuRow(self.addTagMenu)
            row:SetScript("OnClick", function(button)
                self.addTagMenu:Hide()
                if button.createNew then
                    MacroStudio:PromptAddTag()
                else
                    MacroStudio:AddExistingTag(button.tag)
                end
            end)
            self.addTagMenuRows[index] = row
        end
        row.tag = item.tag
        row.createNew = item.createNew
        row.Text:SetText(item.text)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 23))
        row:SetPoint("TOPRIGHT", -4, -4 - ((index - 1) * 23))
        row:Show()
    end
    for index = #items + 1, #self.addTagMenuRows do
        self.addTagMenuRows[index]:Hide()
    end
    self.addTagMenu:SetHeight(8 + (#items * 23))
    self.addTagMenu:Show()
end

function Editor:ToggleTagMenu()
    if not self.macro or MacroStudio:IsOfflineMacro(self.macro) then
        return
    end
    self.categoryMenu:Hide()
    self.addTagMenu:Hide()
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
