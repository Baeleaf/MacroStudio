local _, MacroStudio = ...

function MacroStudio:RestoreWindowGeometry(frame)
    local settings = self.db and self.db.settings and self.db.settings.window or nil
    local screenWidth = UIParent:GetWidth() or self.DEFAULT_WIDTH
    local screenHeight = UIParent:GetHeight() or self.DEFAULT_HEIGHT
    local maximumWidth = math.max(self.MIN_WIDTH, screenWidth * 0.95)
    local maximumHeight = math.max(self.MIN_HEIGHT, screenHeight * 0.95)

    local width = self.Helpers:Clamp(settings and settings.width or self.DEFAULT_WIDTH, self.MIN_WIDTH, maximumWidth)
    local height = self.Helpers:Clamp(settings and settings.height or self.DEFAULT_HEIGHT, self.MIN_HEIGHT, maximumHeight)
    frame:SetSize(width, height)
    frame:ClearAllPoints()

    if settings and type(settings.point) == "string" and type(settings.relativePoint) == "string" then
        frame:SetPoint(
            settings.point,
            UIParent,
            settings.relativePoint,
            tonumber(settings.x) or 0,
            tonumber(settings.y) or 0
        )
    else
        frame:SetPoint("CENTER")
    end
end

function MacroStudio:SaveWindowGeometry(frame)
    if not self.db or not self.db.settings or self.restoringGeometry then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local window = self.db.settings.window
    if type(window) ~= "table" then
        window = {}
        self.db.settings.window = window
    end

    window.width = math.floor(frame:GetWidth() + 0.5)
    window.height = math.floor(frame:GetHeight() + 0.5)
    window.point = point or "CENTER"
    window.relativePoint = relativePoint or "CENTER"
    window.x = math.floor((x or 0) + 0.5)
    window.y = math.floor((y or 0) + 0.5)
end

function MacroStudio:CreateMainFrame()
    local frame = CreateFrame("Frame", "MacroStudioMainFrame", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.025, 0.03, 0.045, 0.99)
    frame:SetBackdropBorderColor(0.25, 0.3, 0.38, 1)

    if frame.SetResizeBounds then
        frame:SetResizeBounds(self.MIN_WIDTH, self.MIN_HEIGHT)
    else
        frame:SetMinResize(self.MIN_WIDTH, self.MIN_HEIGHT)
    end

    self.restoringGeometry = true
    self:RestoreWindowGeometry(frame)
    self.restoringGeometry = false

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
        self:SaveWindowGeometry(frame)
    end)

    local title = self.Helpers:CreateLabel(titleBar, "GameFontNormalHuge", "MacroStudio")
    title:SetPoint("LEFT", 15, 0)
    title:SetTextColor(0.35, 0.75, 1)

    local version = self.Helpers:CreateLabel(titleBar, "GameFontDisableSmall", "v" .. self.VERSION .. " · Milestone 2")
    version:SetPoint("LEFT", title, "RIGHT", 10, -2)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -3, -3)

    local sidebarPanel = self.Sidebar:Create(frame)
    sidebarPanel:SetPoint("TOPLEFT", 14, -48)
    sidebarPanel:SetPoint("BOTTOMLEFT", 14, 14)
    sidebarPanel:SetWidth(180)

    local listPanel = self.MacroList:Create(frame)
    listPanel:SetPoint("TOPLEFT", sidebarPanel, "TOPRIGHT", 12, 0)
    listPanel:SetPoint("BOTTOMLEFT", sidebarPanel, "BOTTOMRIGHT", 12, 0)
    listPanel:SetWidth(280)

    local editorPanel = self.Editor:Create(frame)
    editorPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 12, 0)
    editorPanel:SetPoint("BOTTOMRIGHT", -14, 14)

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(18, 18)
    resizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        self:SaveWindowGeometry(frame)
    end)

    frame:SetScript("OnSizeChanged", function()
        self:SaveWindowGeometry(frame)
    end)
    frame:SetScript("OnShow", function()
        frame:Raise()
    end)
    frame:SetScript("OnHide", function()
        self.Editor.editBox:ClearFocus()
        self.Editor:HideMetadataMenus()
    end)

    frame:Hide()
    self.frame = frame

    if UISpecialFrames then
        UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
    end
end

function MacroStudio:Initialize()
    if self.initialized then
        return
    end
    if not self.db and self.Database then
        self.Database:Initialize()
    end

    self.activeFilter = { kind = "all" }
    self:CreateMainFrame()
    self.initialized = true
    self:RefreshMacros("initial")
    self:UpdateCombatState()
end

function MacroStudio:GetFilteredMacros()
    local filtered = {}
    local filter = self.activeFilter or { kind = "all" }

    for _, macro in ipairs(self.MacroRepository:GetAll()) do
        local include = filter.kind == "all"
            or (filter.kind == "account" and macro.scope == "ACCOUNT")
            or (filter.kind == "character" and macro.scope == "CHARACTER")
            or (filter.kind == "favorites" and self.MetadataRepository:IsFavorite(macro))
            or (filter.kind == "category" and self.MetadataRepository:GetCategoryId(macro) == filter.categoryId)
        if include then
            filtered[#filtered + 1] = macro
        end
    end
    return filtered
end

function MacroStudio:RefreshOrganizationUI()
    self.Sidebar:Rebuild(self.activeFilter)
    self.MacroList:Rebuild(self:GetFilteredMacros(), self.selectedMacro)
    self.Editor:RefreshMetadata()
end

function MacroStudio:SetFilter(kind, categoryId)
    if kind == "category" and not self.MetadataRepository:GetCategory(categoryId) then
        kind = "all"
        categoryId = nil
    end
    self.activeFilter = {
        kind = kind or "all",
        categoryId = categoryId,
    }
    self:RefreshOrganizationUI()
end

function MacroStudio:SelectMacro(macro)
    self.selectedMacro = self.Helpers:CopyMacro(macro)
    self.Editor:SetMacro(self.selectedMacro)
    self:RefreshOrganizationUI()
    self:Debug("macro selected", self.selectedMacro.index)
end

function MacroStudio:RequestSelectMacro(macro)
    if not macro then
        return
    end
    if self.selectedMacro and self.MacroRepository:SnapshotsEqual(self.selectedMacro, macro) then
        return
    end

    if self.Editor:IsDirty() then
        if not self.Dialogs:ShowDiscardChanges(macro) then
            self.Editor:SetNotice("Save or Revert the current macro before selecting another.", true)
        end
        return
    end

    self:SelectMacro(macro)
end

function MacroStudio:RefreshMacros(reason)
    if not self.initialized then
        return
    end

    local macros = self.MacroRepository:Refresh()
    self.MetadataRepository:Reconcile(macros)
    local editorWasDirty = self.Editor:IsDirty()
    local exactSelection

    if self.selectedMacro then
        for _, macro in ipairs(macros) do
            if self.MacroRepository:SnapshotsEqual(macro, self.selectedMacro) then
                exactSelection = macro
                break
            end
        end
    end

    if exactSelection then
        self.selectedMacro.duplicateName = exactSelection.duplicateName
        self.selectedMacro.duplicateCount = exactSelection.duplicateCount
        self.Editor.macro = self.selectedMacro
        self.Editor:SetExternalConflict(false)
    elseif self.selectedMacro and editorWasDirty then
        self:Debug("external macro change detected", self.selectedMacro.index)
        self.Editor:SetExternalConflict(true)
    elseif self.selectedMacro then
        local latest = self.MacroRepository:ResolveLatest(self.selectedMacro, false)
        if latest then
            self.selectedMacro = self.Helpers:CopyMacro(latest)
            self.Editor:SetMacro(self.selectedMacro)
            self:Debug("selected macro reconciled", self.selectedMacro.index)
        else
            self.selectedMacro = nil
            self.Editor:Clear()
            self.Editor:SetNotice("The previously selected macro no longer exists.", true)
        end
    end

    if not self.selectedMacro and #macros > 0 and (reason == "initial" or reason == "open") then
        self:SelectMacro(macros[1])
    else
        self:RefreshOrganizationUI()
    end
end

function MacroStudio:OnMacrosChanged(reason)
    if self.initialized then
        self:Debug("UPDATE_MACROS received")
        self:RefreshMacros(reason or "event")
    end
end

function MacroStudio:OnEditorTextChanged()
    if self.Editor then
        self.Editor:UpdateEditorState("callback")
    end
end

function MacroStudio:SaveSelectedMacro()
    if not self.selectedMacro then
        self.Editor:SetNotice("Select a macro before saving.", true)
        return
    end

    local previousMacro = self.Helpers:CopyMacro(self.selectedMacro)
    local _, trustedMetadataId = self.MetadataRepository:GetRecordForMacro(previousMacro)
    local body = self.Editor:GetBody()
    local saved, updatedMacro, message = self.MacroRepository:Update(previousMacro, body)
    if not saved then
        self.Editor:SetNotice(message or "The macro could not be saved.", true)
        return
    end

    if not updatedMacro then
        self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
        self:RefreshOrganizationUI()
        self.Editor:SetExternalConflict(true)
        self.Editor:SetNotice(message or "Saved, but the macro must be selected again.", true)
        return
    end

    self.MetadataRepository:OnMacroSaved(previousMacro, updatedMacro, trustedMetadataId)
    self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
    self.selectedMacro = self.Helpers:CopyMacro(updatedMacro)
    self.Editor:SetMacro(self.selectedMacro)
    self.Editor:SetNotice("Macro saved.", false)
    self:RefreshOrganizationUI()
end

function MacroStudio:RevertSelectedMacro()
    if not self.selectedMacro then
        self.Editor:SetNotice("Select a macro before reverting.", true)
        return
    end

    local latest, message = self.MacroRepository:ResolveLatest(self.selectedMacro)
    self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
    if not latest then
        self:RefreshOrganizationUI()
        self.Editor:SetExternalConflict(true)
        self.Editor:SetNotice(message or "The macro could not be resolved safely.", true)
        return
    end

    self.selectedMacro = self.Helpers:CopyMacro(latest)
    self.Editor:SetMacro(self.selectedMacro)
    self.Editor:SetNotice("Editor restored from Blizzard's current macro body.", false)
    self:RefreshOrganizationUI()
end

function MacroStudio:ToggleSelectedFavorite()
    if not self.selectedMacro then
        return
    end
    self.MetadataRepository:ToggleFavorite(self.selectedMacro)
    self:RefreshOrganizationUI()
end

function MacroStudio:AssignSelectedCategory(categoryId)
    if not self.selectedMacro then
        return
    end
    local ok, message = self.MetadataRepository:SetCategory(self.selectedMacro, categoryId)
    if not ok then
        self.Editor:SetNotice(message, true)
        return
    end
    self:RefreshOrganizationUI()
end

function MacroStudio:PromptAddTag()
    if not self.selectedMacro then
        return
    end
    self.Dialogs:ShowAddTag(self.selectedMacro, function(tag)
        local ok, message = self.MetadataRepository:AddTag(self.selectedMacro, tag)
        if not ok then
            self.Editor:SetNotice(message, true)
            return
        end
        self:RefreshOrganizationUI()
    end)
end

function MacroStudio:RemoveSelectedTag(tag)
    if not self.selectedMacro then
        return
    end
    local ok, message = self.MetadataRepository:RemoveTag(self.selectedMacro, tag)
    if not ok then
        self.Editor:SetNotice(message, true)
        return
    end
    self:RefreshOrganizationUI()
end

function MacroStudio:PromptCreateCategory()
    self.Dialogs:ShowNewCategory(function(name)
        local category, message = self.MetadataRepository:CreateCategory(name)
        if not category then
            self:Print(message)
            return
        end
        self:SetFilter("category", category.id)
    end)
end

function MacroStudio:GetActiveCategory()
    if self.activeFilter and self.activeFilter.kind == "category" then
        return self.MetadataRepository:GetCategory(self.activeFilter.categoryId)
    end
    return nil
end

function MacroStudio:PromptRenameCategory()
    local category = self:GetActiveCategory()
    if not category then
        return
    end
    self.Dialogs:ShowRenameCategory(category, function(name)
        local ok, result = self.MetadataRepository:RenameCategory(category.id, name)
        if not ok then
            self:Print(result)
            return
        end
        self:RefreshOrganizationUI()
    end)
end

function MacroStudio:PromptDeleteCategory()
    local category = self:GetActiveCategory()
    if not category then
        return
    end
    self.Dialogs:ShowDeleteCategory(category, function()
        local ok, message = self.MetadataRepository:DeleteCategory(category.id)
        if not ok then
            self:Print(message)
            return
        end
        self:SetFilter("all")
    end)
end

function MacroStudio:UpdateCombatState()
    self.inCombat = InCombatLockdown() and true or false
    if self.Editor then
        self.Editor:UpdateEditorState("combat")
    end
end

function MacroStudio:Toggle()
    if not self.initialized then
        self:Initialize()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self:RefreshMacros("open")
        self.frame:Show()
    end
end

local function handleSlashCommand(message)
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
    elseif command == "help" then
        MacroStudio:Print("/macrostudio or /ms — toggle the window")
        MacroStudio:Print("/ms refresh — force a fallback macro refresh")
        MacroStudio:Print("/ms debug [on|off] — control debug logging")
    elseif command == "" then
        MacroStudio:Toggle()
    else
        MacroStudio:Print("Unknown command. Use /ms help.")
    end
end

SLASH_MACROSTUDIO1 = "/macrostudio"
SLASH_MACROSTUDIO2 = "/ms"
SlashCmdList.MACROSTUDIO = handleSlashCommand
