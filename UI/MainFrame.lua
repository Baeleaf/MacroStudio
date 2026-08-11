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

function MacroStudio:SetMainWindowModalBlocked(blocked)
    self.mainWindowModalBlocked = blocked and true or false
    if not self.modalOverlay then
        return
    end

    if self.mainWindowModalBlocked then
        if self.Editor then
            self.Editor:HideMetadataMenus()
        end
        if self.Dialogs and self.Dialogs.inputFrame then
            self.Dialogs.inputFrame:Hide()
        end
        self.Helpers:HideTooltip()
        self.modalOverlay:Show()
    else
        self.modalOverlay:Hide()
    end
end

function MacroStudio:IsMainWindowModalBlocked()
    return self.mainWindowModalBlocked == true
end

function MacroStudio:CreateMainFrame()
    local frame = CreateFrame("Frame", "MacroStudioMainFrame", UIParent, "BackdropTemplate")
    frame:Hide()
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

    local version = self.Helpers:CreateLabel(titleBar, "GameFontDisableSmall", "v" .. self.VERSION)
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

    local modalOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    modalOverlay:SetAllPoints(frame)
    modalOverlay:SetFrameStrata("DIALOG")
    modalOverlay:SetFrameLevel(frame:GetFrameLevel() + 100)
    modalOverlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    modalOverlay:SetBackdropColor(0, 0, 0, 0.42)
    modalOverlay:EnableMouse(true)
    modalOverlay:EnableMouseWheel(true)
    modalOverlay:SetScript("OnMouseDown", function() end)
    modalOverlay:SetScript("OnMouseUp", function() end)
    modalOverlay:SetScript("OnMouseWheel", function() end)
    modalOverlay:Hide()
    self.modalOverlay = modalOverlay
    self.mainWindowModalBlocked = false

    frame:SetScript("OnSizeChanged", function()
        self:SaveWindowGeometry(frame)
    end)
    frame:SetScript("OnShow", function()
        frame:Raise()
    end)
    frame:SetScript("OnHide", function()
        self.Editor.editBox:ClearFocus()
        self.Editor:HideMetadataMenus()
        if self.Dialogs.inputFrame then
            self.Dialogs.inputFrame:Hide()
        end
        if self.MacroDialog.frame then
            self.MacroDialog.frame:Hide()
        end
        if self.IconPicker.frame then
            self.IconPicker.frame:Hide()
        end
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
    if self.CharacterMacroLibrary then
        self.CharacterMacroLibrary:Initialize()
    end

    self.activeFilter = { kind = "all" }
    self.searchQuery = ""
    self:CreateMainFrame()
    self.initialized = true
    self:RefreshMacros("initial")
    self:UpdateCombatState()
end

function MacroStudio:IsOfflineMacro(macro)
    return self.CharacterMacroLibrary and self.CharacterMacroLibrary:IsOfflineMacro(macro) or false
end

function MacroStudio:MacroRecordsEqual(first, second)
    return self.CharacterMacroLibrary:RecordsEqual(first, second)
end

function MacroStudio:GetFilteredMacros()
    local filtered = {}
    local filter = self.activeFilter or { kind = "all" }
    local query = self.searchQuery or ""

    self.characterViewGroups = nil
    if filter.kind == "characters" or filter.kind == "libraryCharacter" then
        local groups = self.CharacterMacroLibrary:GetViewGroups(filter, query, self.MacroRepository:GetAll())
        self.characterViewGroups = groups
        for _, group in ipairs(groups) do
            for _, macro in ipairs(group.macros) do
                filtered[#filtered + 1] = macro
            end
        end
        return filtered
    end

    for _, macro in ipairs(self.MacroRepository:GetAll()) do
        local include = filter.kind == "all"
            or (filter.kind == "account" and macro.scope == "ACCOUNT")
            or (filter.kind == "character" and macro.scope == "CHARACTER")
            or (filter.kind == "favorites" and self.MetadataRepository:IsFavorite(macro))
            or (filter.kind == "category" and self.MetadataRepository:GetCategoryId(macro) == filter.categoryId)
        if include and self.Search:Matches(macro, query) then
            filtered[#filtered + 1] = macro
        end
    end
    return filtered
end

function MacroStudio:UpdateActionControls()
    if not self.MacroList or not self.MacroList.newMacroButton then
        return
    end

    local accountCount, accountLimit = self.MacroRepository:GetCapacity("ACCOUNT")
    local characterCount, characterLimit = self.MacroRepository:GetCapacity("CHARACTER")
    local hasCapacity = accountCount < accountLimit or characterCount < characterLimit
    local dirty = self.Editor and self.Editor:IsDirty()
    local enabled = not self.inCombat and hasCapacity and not dirty
    local reason
    if self.inCombat then
        reason = "Creating macros is unavailable during Combat Lockdown."
    elseif dirty then
        reason = "Save or Revert editor changes before creating and selecting a new macro."
    elseif not hasCapacity then
        reason = "Both Account and Character macro lists are full."
    end
    self.MacroList:SetNewMacroState(enabled, reason)

    if self.MacroDialog and self.MacroDialog:IsShown() then
        self.MacroDialog:UpdateState()
    end
end

function MacroStudio:GetSearchQuery()
    return self.searchQuery or ""
end

function MacroStudio:SetSearchQuery(query)
    query = type(query) == "string" and query or ""
    if query == self.searchQuery then
        return
    end

    self.searchQuery = query
    if self.MacroList and self.MacroList.scrollFrame then
        self:RefreshMacroList()
    end
end

function MacroStudio:RefreshMacroList()
    self.MacroList:Rebuild(
        self:GetFilteredMacros(),
        self.selectedMacro,
        self.activeFilter,
        self:GetSearchQuery(),
        self.characterViewGroups
    )
end

function MacroStudio:RefreshOrganizationUI()
    self.Sidebar:Rebuild(self.activeFilter)
    self:RefreshMacroList()
    self.Editor:RefreshMetadata()
    self:UpdateActionControls()
end

function MacroStudio:SetFilter(kind, categoryId)
    if kind == "category" and not self.MetadataRepository:GetCategory(categoryId) then
        kind = "all"
        categoryId = nil
    end
    if kind == "libraryCharacter" and not self.CharacterMacroLibrary:GetCharacter(categoryId) then
        kind = "characters"
        categoryId = nil
    end
    self.activeFilter = {
        kind = kind or "all",
        categoryId = categoryId,
        characterId = kind == "libraryCharacter" and categoryId or nil,
    }
    self:RefreshOrganizationUI()
end

function MacroStudio:SelectMacro(macro)
    if not macro then
        return
    end
    self.externalConflictResolution = nil
    self.selectedMacro = self.Helpers:CopyMacro(macro)
    self.Editor:SetMacro(self.selectedMacro)
    self:RefreshOrganizationUI()
    self:Debug("macro selected", self.selectedMacro.index)
end

function MacroStudio:RequestSelectMacro(macro)
    if not macro then
        return
    end
    if self.selectedMacro and self:MacroRecordsEqual(self.selectedMacro, macro) then
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

function MacroStudio:RequestPickupMacro(macro)
    if not macro then
        return false
    end
    if self:IsOfflineMacro(macro) then
        local message = "Offline character snapshots cannot be placed on action bars."
        self.Editor:SetNotice(message, true)
        self:Print(message)
        return false
    end

    local draggingDirtySelection = self.selectedMacro
        and self:MacroRecordsEqual(self.selectedMacro, macro)
        and self.Editor
        and self.Editor:IsDirty()
    local pickedUp, current, message = self.MacroRepository:Pickup(macro)
    if not pickedUp then
        message = message or "This macro could not be placed on the cursor."
        if self.Editor then
            self.Editor:SetNotice(message, true)
        end
        self:Print(message)
        return false
    end

    if draggingDirtySelection then
        self.Editor:SetNotice(
            "You have unsaved changes. The saved version was placed on the cursor.",
            false
        )
    end
    self:Debug("native macro picked up", current.index)
    return true, current
end

function MacroStudio:RefreshActionBarUsage(reason)
    if not self.initialized or not self.ActionBarRepository then
        return
    end

    self.ActionBarRepository:Refresh()
    if self.MacroList and self.MacroList.RefreshUsage then
        self.MacroList:RefreshUsage()
    end
    if self.Editor and self.Editor.RefreshActionBarUsage then
        self.Editor:RefreshActionBarUsage()
    end
    self:Debug("action-bar event handled", reason or "unknown")
end

function MacroStudio:OnActionBarChanged(reason)
    if not self.initialized or self.pendingActionBarUsageRefresh then
        return
    end

    self.pendingActionBarUsageRefresh = true
    local function refresh()
        self.pendingActionBarUsageRefresh = false
        if reason == "PLAYER_ENTERING_WORLD" then
            self:RefreshMacros(reason)
        else
            self:RefreshActionBarUsage(reason)
        end
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, refresh)
    else
        refresh()
    end
end

function MacroStudio:ScheduleMacroRefresh(reason)
    if not self.initialized then
        return
    end

    self.pendingMacroRefreshReason = reason or self.pendingMacroRefreshReason or "event"
    if self.macroRefreshScheduled then
        return
    end

    self.macroRefreshScheduled = true
    local function refresh()
        self.macroRefreshScheduled = nil
        if self.nativeMutationInProgress then
            self.pendingMacroRefresh = true
            return
        end

        local refreshReason = self.pendingMacroRefreshReason or "event"
        self.pendingMacroRefreshReason = nil
        self.pendingMacroRefresh = nil
        self:RefreshMacros(refreshReason)
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, refresh)
    else
        refresh()
    end
end

function MacroStudio:FinishNativeMacroMutation(reason)
    self.nativeMutationInProgress = false
    self.pendingMacroRefresh = nil
    self:ScheduleMacroRefresh(reason or "native mutation")
end

function MacroStudio:RefreshMacros(reason)
    if not self.initialized then
        return
    end

    local previousMacros = {}
    for index, macro in ipairs(self.MacroRepository:GetAll()) do
        previousMacros[index] = self.Helpers:CopyMacro(macro)
    end
    local macros = self.MacroRepository:Refresh()
    if self.CharacterMacroLibrary and reason ~= "open" then
        self.CharacterMacroLibrary:RefreshCurrentSnapshot(macros)
    end
    if self.ActionBarRepository then
        self.ActionBarRepository:Refresh()
    end
    self.MetadataRepository:Reconcile(macros)
    local editorWasDirty = self.Editor:IsDirty()
    local exactSelection
    local offlineSelection = self:IsOfflineMacro(self.selectedMacro)
    if offlineSelection and not self.CharacterMacroLibrary:FindSnapshot(self.selectedMacro) then
        self.externalConflictResolution = nil
        self.selectedMacro = nil
        self.Editor:Clear()
        self.Editor:SetNotice("The stored character snapshot no longer exists.", true)
    end

    if self.selectedMacro and not offlineSelection then
        for _, macro in ipairs(macros) do
            if self.MacroRepository:SnapshotsEqual(macro, self.selectedMacro) then
                exactSelection = macro
                break
            end
        end
    end

    if offlineSelection then
        -- Offline selection is preserved without consulting native indices.
        self.externalConflictResolution = nil
    elseif exactSelection then
        self.selectedMacro.duplicateName = exactSelection.duplicateName
        self.selectedMacro.duplicateCount = exactSelection.duplicateCount
        self.Editor.macro = self.selectedMacro
        self.Editor:SetExternalConflict(false)
        self.externalConflictResolution = nil
    elseif self.selectedMacro and editorWasDirty then
        self:Debug("external macro change detected", self.selectedMacro.index)
        local resolution = self.externalConflictResolution
        if not resolution
            or not self.MacroRepository:SnapshotsEqual(resolution.snapshot, self.selectedMacro) then
            resolution = {
                snapshot = self.Helpers:CopyMacro(self.selectedMacro),
                baseline = previousMacros,
            }
            self.externalConflictResolution = resolution
        end
        self.Editor:SetExternalConflict(true)
    elseif self.selectedMacro then
        local latest = self.MacroRepository:ResolveLatest(self.selectedMacro, false)
        if latest then
            self.externalConflictResolution = nil
            self.selectedMacro = self.Helpers:CopyMacro(latest)
            self.Editor:SetMacro(self.selectedMacro)
            self:Debug("selected macro reconciled", self.selectedMacro.index)
        else
            self.externalConflictResolution = nil
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
    if self.nativeMutationInProgress then
        self.pendingMacroRefresh = true
        self.pendingMacroRefreshReason = reason or "UPDATE_MACROS"
        return
    end
    if self.initialized then
        self:Debug("UPDATE_MACROS received")
        self:ScheduleMacroRefresh(reason or "event")
    end
end

function MacroStudio:OnEditorTextChanged()
    if self.Editor then
        self.Editor:UpdateEditorState("callback")
        self:UpdateActionControls()
    end
end

function MacroStudio:SaveSelectedMacro()
    local state = self.Editor and self.Editor.state
    if not self.selectedMacro or not state or not state.canSave then
        self.Editor:SetNotice(state and state.saveReason or "Select a macro before saving.", true)
        return
    end

    local previousMacro = self.Helpers:CopyMacro(self.selectedMacro)
    local _, trustedMetadataId = self.MetadataRepository:GetRecordForMacro(previousMacro)
    local draft = self.Editor:GetDraft()
    self.nativeMutationInProgress = true
    local saved, updatedMacro, message = self.MacroRepository:Update(previousMacro, draft)
    self:FinishNativeMacroMutation("save")

    if not saved then
        self.Editor:SetNotice(message or "The macro could not be saved.", true)
        return
    end
    self.CharacterMacroLibrary:RefreshCurrentSnapshot(self.MacroRepository:GetAll())

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
    self.Editor:SetNotice("Macro name, icon, and body saved.", false)
    self:RefreshOrganizationUI()
end

function MacroStudio:RevertSelectedMacro()
    if not self.selectedMacro then
        self.Editor:SetNotice("Select a macro before reverting.", true)
        return
    end
    if self:IsOfflineMacro(self.selectedMacro) then
        self.Editor:SetNotice("Offline snapshots already show their saved read-only name, icon, and body.", true)
        return
    end

    local baseline = {}
    local resolution = self.externalConflictResolution
    if resolution and self.MacroRepository:SnapshotsEqual(resolution.snapshot, self.selectedMacro) then
        baseline = resolution.baseline
    else
        for index, macro in ipairs(self.MacroRepository:GetAll()) do
            baseline[index] = self.Helpers:CopyMacro(macro)
        end
    end

    local latest, status, message = self.MacroRepository:ResolveExternalConflict(
        self.selectedMacro,
        baseline
    )
    self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
    if not latest then
        self.externalConflictResolution = nil
        self.selectedMacro = nil
        self.Editor:Clear()
        self:RefreshOrganizationUI()
        if status == "deleted" then
            self.Editor:SetNotice(message or "The selected macro was deleted outside MacroStudio.", true)
        else
            self.Editor:SetNotice(
                message or "This macro could not be reconciled safely; selection was cleared.",
                true
            )
        end
        return
    end

    self.externalConflictResolution = nil
    self.selectedMacro = self.Helpers:CopyMacro(latest)
    self.Editor:SetMacro(self.selectedMacro)
    self.Editor:SetNotice("Editor restored from Blizzard's current macro name, icon, and body.", false)
    self:RefreshOrganizationUI()
end

function MacroStudio:ToggleSelectedFavorite()
    if not self.selectedMacro or self:IsOfflineMacro(self.selectedMacro) then
        return
    end
    self.MetadataRepository:ToggleFavorite(self.selectedMacro)
    self:RefreshOrganizationUI()
end

function MacroStudio:AssignSelectedCategory(categoryId)
    if not self.selectedMacro or self:IsOfflineMacro(self.selectedMacro) then
        return
    end
    local ok, message = self.MetadataRepository:SetCategory(self.selectedMacro, categoryId)
    if not ok then
        self.Editor:SetNotice(message, true)
        return
    end
    self:RefreshOrganizationUI()
end

function MacroStudio:AddExistingTag(tag)
    if not self.selectedMacro or self:IsOfflineMacro(self.selectedMacro) then
        return false, "Organization is unavailable for offline character snapshots."
    end
    local ok, message = self.MetadataRepository:AddTag(self.selectedMacro, tag)
    if not ok then
        self.Editor:SetNotice(message, true)
        return false, message
    end
    self:RefreshOrganizationUI()
    return true
end

function MacroStudio:PromptAddTag()
    if not self.selectedMacro or self:IsOfflineMacro(self.selectedMacro) then
        return
    end
    self.Dialogs:ShowAddTag(self.selectedMacro, function(tag)
        local ok, message = self.MetadataRepository:AddTag(self.selectedMacro, tag)
        if not ok then
            return false, message
        end
        self:RefreshOrganizationUI()
        return true
    end)
end

function MacroStudio:RemoveSelectedTag(tag)
    if not self.selectedMacro or self:IsOfflineMacro(self.selectedMacro) then
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
            return false, message
        end
        self:SetFilter("category", category.id)
        return true
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
            return false, result
        end
        self:RefreshOrganizationUI()
        return true
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
function MacroStudio:GetActiveLibraryCharacter()
    if self.activeFilter and self.activeFilter.kind == "libraryCharacter" then
        return self.CharacterMacroLibrary:GetCharacter(self.activeFilter.characterId)
    end
    return nil
end

function MacroStudio:PromptForgetActiveCharacter()
    local character = self:GetActiveLibraryCharacter()
    if not character then
        return
    end
    if self.CharacterMacroLibrary:IsCurrentCharacter(character.id) then
        self:Print("The current character cannot be forgotten.")
        return
    end

    self.Dialogs:ShowForgetCharacter(character, function()
        local ok, result = self.CharacterMacroLibrary:ForgetCharacter(character.id)
        if not ok then
            self:Print(result)
            return
        end
        if self.selectedMacro
            and self:IsOfflineMacro(self.selectedMacro)
            and self.selectedMacro.characterKey == character.id then
            self.selectedMacro = nil
            self.Editor:Clear()
        end
        self:SetFilter("characters")
        self:Print((result.displayName or "Character") .. " removed from the stored macro library.")
    end)
end

function MacroStudio:ShowNewMacroDialog()
    self:UpdateActionControls()
    if self.Editor:IsDirty() then
        self.Editor:SetNotice("Save or Revert editor changes before creating and selecting a new macro.", true)
        return
    end
    if self.inCombat then
        self.Editor:SetNotice("Creating macros is unavailable during Combat Lockdown.", true)
        return
    end
    self.MacroDialog:Open({ scope = "ACCOUNT", icon = self.DEFAULT_ICON })
end

function MacroStudio:CreateNativeMacro(request)
    if self.Editor:IsDirty() then
        return false, "Save or Revert editor changes before creating a macro."
    end

    self.nativeMutationInProgress = true
    local created, macro, message = self.MacroRepository:Create(request)
    self:FinishNativeMacroMutation("create")
    if not created then
        self:UpdateActionControls()
        return false, message or "The macro could not be created."
    end
    self.CharacterMacroLibrary:RefreshCurrentSnapshot(self.MacroRepository:GetAll())

    self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
    if macro then
        self:SelectMacro(macro)
        self.Editor:SetNotice("Native macro created.", false)
    else
        self.selectedMacro = nil
        self.Editor:Clear()
        self:RefreshOrganizationUI()
        self.Editor:SetNotice(message or "Created; select the new macro from the list.", true)
    end
    return true, macro
end
function MacroStudio:CopySelectedSnapshotToCurrentCharacter()
    local snapshot = self.selectedMacro
    if not self:IsOfflineMacro(snapshot) then
        self.Editor:SetNotice("Select an offline character macro to copy it.", true)
        return false
    end

    local source = self.CharacterMacroLibrary:FindSnapshot(snapshot)
    if not source then
        self.Editor:SetNotice("This stored macro snapshot is no longer available.", true)
        return false
    end

    local created, macroOrMessage = self:CreateNativeMacro({
        name = source.name,
        body = source.body,
        icon = source.icon,
        scope = "CHARACTER",
    })
    if not created then
        self.Editor:SetNotice(macroOrMessage or "The snapshot could not be copied.", true)
        return false
    end

    self:SetFilter("character")
    self.Editor:SetNotice("Copied to the current character. The offline snapshot was not changed.", false)
    return true, macroOrMessage
end


function MacroStudio:RequestDeleteSelectedMacro()
    local state = self.Editor and self.Editor.state
    if not self.selectedMacro or not state or not state.canDelete then
        self.Editor:SetNotice(state and state.deleteReason or "Select a macro before deleting.", true)
        return
    end

    local snapshot = self.Helpers:CopyMacro(self.selectedMacro)
    self.Dialogs:ShowDeleteMacro(snapshot, function()
        self:DeleteSelectedMacro(snapshot)
    end)
end

function MacroStudio:DeleteSelectedMacro(snapshot)
    local state = self.Editor and self.Editor.state
    if not self.selectedMacro
        or not self:MacroRecordsEqual(self.selectedMacro, snapshot)
        or not state
        or not state.canDelete then
        self.Editor:SetNotice(state and state.deleteReason or "The selected macro is no longer safe to delete.", true)
        return false
    end

    local _, trustedMetadataId = self.MetadataRepository:GetRecordForMacro(snapshot)
    self.nativeMutationInProgress = true
    local deleted, message = self.MacroRepository:Delete(snapshot)
    self:FinishNativeMacroMutation("delete")
    if not deleted then
        self.Editor:SetNotice(message or "The macro could not be deleted.", true)
        return false
    end
    self.CharacterMacroLibrary:RefreshCurrentSnapshot(self.MacroRepository:GetAll())

    self.MetadataRepository:OnMacroDeleted(snapshot, trustedMetadataId)
    self.MetadataRepository:Reconcile(self.MacroRepository:GetAll())
    self.selectedMacro = nil
    self.Editor:Clear()
    self.Editor:SetNotice("Native macro deleted.", false)
    self:RefreshOrganizationUI()
    return true
end

function MacroStudio:UpdateCombatState()
    self.inCombat = type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
    if self.Editor then
        self.Editor:UpdateEditorState("combat")
    end
    self:UpdateActionControls()
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
        MacroStudio:Print("/macrostudio or /ms - toggle the window")
        MacroStudio:Print("/ms refresh - force a fallback macro refresh")
        MacroStudio:Print("/ms debug [on|off] - control debug logging")
    elseif command == "" then
        MacroStudio:Toggle()
    else
        MacroStudio:Print("Unknown command. Use /ms help.")
    end
end

SLASH_MACROSTUDIO1 = "/macrostudio"
SLASH_MACROSTUDIO2 = "/ms"
SlashCmdList.MACROSTUDIO = handleSlashCommand
