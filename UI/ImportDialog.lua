local _, MacroStudio = ...

local ImportDialog = {
    MAX_DISPLAY_BYTES = 4 * 1024 * 1024,
}
MacroStudio.ImportDialog = ImportDialog

local SECTION_LABELS = {
    account = "ACCOUNT MACROS",
    character = "CHARACTER MACROS",
    offline = "OFFLINE LIBRARY",
    categories = "CATEGORIES",
    tags = "TAGS",
    favorites = "FAVORITES",
}

local STATUS_LABELS = {
    create = "Create",
    reuse = "Already present",
    add = "New snapshot",
    update = "Update snapshot",
    keep = "Preserved",
    skip_current = "Current character",
    blocked = "Cannot create",
    ambiguous = "Ambiguous",
    disabled = "Disabled",
    new = "New snapshot",
    existing = "Existing / preserved",
    local_newer = "Local newer / preserved",
    preserved = "Preserved",
    current = "Current character",
}

local function conciseError(value)
    local message = tostring(value or "unknown error")
    message = message:gsub("[\r\n]+", " "):gsub("%s+", " ")
    if #message > 420 then message = message:sub(1, 417) .. "..." end
    return message
end

local function lower(value)
    return MacroStudio.Helpers:Trim(tostring(value or "")):lower()
end

local function iconValue(icon)
    return type(icon) == "table" and icon.value or MacroStudio.DEFAULT_ICON
end

local function characterName(source)
    local identity = source and source.identity or {}
    return (identity.name or "Unknown Character") .. " - " .. (identity.realm or "Unknown Realm")
end

local function associationFor(plan, macroId)
    for _, association in ipairs(plan.associations or {}) do
        if association.source.macroId == macroId then return association end
    end
end

local function nativeHasMetadata(plan, item)
    local association = associationFor(plan, item.source.id)
    return association and (
        association.category ~= nil
        or #(association.tags or {}) > 0
        or association.source.favorite
    ) or false
end

local function sourceFavorites(model)
    local count = 0
    for _, association in ipairs(model.organization.associations or {}) do
        if association.favorite then count = count + 1 end
    end
    return count
end

local function isBlocked(section, item)
    if section == "account" or section == "character" then
        return item.action == "blocked" or item.action == "ambiguous" or item.action == "disabled"
    elseif section == "offline" then
        return item.action == "keep" or item.action == "skip_current"
    end
    return false
end

local function resultText(success, result)
    local lines = {
        success and "IMPORT COMPLETE" or "IMPORT STOPPED",
        "",
        string.format("Account macros created: %d", result.accountCreated or 0),
        string.format("Account macros already present: %d", result.accountPresent or 0),
        string.format("Character macros created: %d", result.characterCreated or 0),
        string.format("Character macros already present: %d", result.characterPresent or 0),
        string.format("Offline characters added: %d", result.offlineAdded or 0),
        string.format("Offline snapshots updated: %d", result.offlineUpdated or 0),
        string.format("Offline snapshots preserved: %d", result.offlineKept or 0),
        string.format("Categories added: %d", result.categoriesAdded or 0),
        string.format("Tags added: %d", result.tagsAdded or 0),
        string.format("Favorites restored: %d", result.favoritesRestored or 0),
        string.format("Skipped/ambiguous native records: %d", result.ambiguousSkipped or 0),
        string.format("Metadata mappings skipped as ambiguous: %d", result.metadataSkipped or 0),
        string.format("Destination category conflicts preserved: %d", result.metadataConflicts or 0),
    }
    if result.message then
        lines[#lines + 1] = ""
        lines[#lines + 1] = result.message
    elseif success then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "No existing native macros were overwritten or deleted."
    end
    return table.concat(lines, "\n")
end

function ImportDialog:SetStage(stage)
    self.stage = stage
    MacroStudio:Debug("Import stage", stage)
end

function ImportDialog:GetStage()
    return self.stage
end

function ImportDialog:SetStatus(message, isError)
    self.statusText:SetText(message or "")
    if isError then self.statusText:SetTextColor(1, 0.35, 0.3)
    else self.statusText:SetTextColor(0.68, 0.75, 0.86) end
end

function ImportDialog:SetOutput(text)
    self.outputText = text or ""
    self.settingOutput = true
    self.outputEditBox:SetText(self.outputText)
    self.settingOutput = false
    self.outputEditBox:SetCursorPosition(0)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.outputScrollBox)
end

function ImportDialog:SetMode(mode)
    self.mode = mode
    local paste = mode == "paste"
    local preview = mode == "preview"
    local result = mode == "result"
    self.inputPanel:SetShown(paste)
    self.characterCheckbox:SetShown(paste)
    self.characterLabel:SetShown(paste)
    self.previewPanel:SetShown(preview)
    self.outputPanel:SetShown(result)
    self.validateButton:SetShown(paste)
    self.applyButton:SetShown(preview)
    self.backButton:SetShown(preview or result)
    self.closeButton:SetShown(paste or result)
    self.backButton:SetText(result and "Import Another" or "Back")
    self.closeButton:SetText(result and "Done" or "Cancel")
    self.heading:SetText(result and "Import Results" or (preview and "Import Preview" or "Paste Portable Export"))
end

function ImportDialog:CreatePreviewRow()
    local row = CreateFrame("Button", nil, self.previewScrollChild)
    row:SetHeight(24)
    row:EnableMouse(true)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetPoint("LEFT", row, "LEFT", 2, 0)
    check:SetScript("OnClick", function(owner)
        self:TogglePreviewRow(row, owner:GetChecked())
    end)
    row.checkbox = check

    local label = MacroStudio.Helpers:CreateLabel(row, "GameFontHighlightSmall", "")
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    row.label = label

    local status = MacroStudio.Helpers:CreateLabel(row, "GameFontDisableSmall", "")
    status:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    status:SetWidth(118)
    status:SetJustifyH("RIGHT")
    status:SetWordWrap(false)
    row.status = status

    local sectionNone = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    sectionNone:SetSize(44, 20)
    sectionNone:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    sectionNone:SetText("None")
    sectionNone:SetScript("OnClick", function()
        self:SetSectionSelected(row.section, false)
    end)
    row.sectionNone = sectionNone

    local sectionAll = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    sectionAll:SetSize(38, 20)
    sectionAll:SetPoint("RIGHT", sectionNone, "LEFT", -3, 0)
    sectionAll:SetText("All")
    sectionAll:SetScript("OnClick", function()
        self:SetSectionSelected(row.section, true)
    end)
    row.sectionAll = sectionAll

    row:SetScript("OnClick", function()
        self:ActivatePreviewRow(row)
    end)
    self.previewRowPool[#self.previewRowPool + 1] = row
    return row
end

function ImportDialog:AcquirePreviewRow()
    local index = #self.visiblePreviewRows + 1
    local row = self.previewRowPool[index] or self:CreatePreviewRow()
    self.visiblePreviewRows[index] = row
    row:Show()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.previewScrollChild, "TOPLEFT", 2, self.previewNextY)
    row:SetPoint("TOPRIGHT", self.previewScrollChild, "TOPRIGHT", -2, self.previewNextY)
    self.previewNextY = self.previewNextY - 24
    return row
end

function ImportDialog:ReleasePreviewRows()
    for _, row in ipairs(self.previewRowPool or {}) do
        row:Hide()
        row.kind, row.section, row.item, row.offlineMacro = nil, nil, nil, nil
    end
    self.visiblePreviewRows = {}
    self.previewNextY = -2
end

function ImportDialog:ConfigurePreviewRow(row, options)
    row.kind = options.kind
    row.section = options.section
    row.item = options.item
    row.offlineMacro = options.offlineMacro
    row.label:ClearAllPoints()
    row.status:SetText(options.status or "")
    row.label:SetText(options.label or "")
    row.label:SetTextColor(options.disabled and 0.52 or 0.88, options.disabled and 0.55 or 0.9, options.disabled and 0.6 or 0.96)

    row.sectionAll:Hide()
    row.sectionNone:Hide()
    row.status:Show()
    if options.checkable then
        row.checkbox:Show()
        row.checkbox:SetEnabled(not options.disabled)
        row.checkbox:SetAlpha(options.disabled and 0.45 or 1)
        row.checkbox:SetChecked(options.checked)
        row.label:SetPoint("LEFT", row.checkbox, "RIGHT", options.indent or 3, 0)
    else
        row.checkbox:Hide()
        row.label:SetPoint("LEFT", row, "LEFT", options.indent or 8, 0)
    end
    if options.kind == "section" and options.section ~= "favorites" then
        row.status:Hide()
        row.sectionAll:Show()
        row.sectionNone:Show()
        row.label:SetPoint("RIGHT", row.sectionAll, "LEFT", -5, 0)
    else
        row.label:SetPoint("RIGHT", row.status, "LEFT", -6, 0)
    end
end

function ImportDialog:GetSectionSummary(section)
    local plan = self.plan
    if section == "account" or section == "character" then
        local scope = plan[section]
        return string.format("%d total / %d Create / %d Present", #scope.items, scope.create, scope.present)
    elseif section == "offline" then
        return string.format("%d characters / %d New / %d Update", #plan.offline.items, plan.offline.added, plan.offline.updated)
    elseif section == "categories" then
        return string.format("%d total / %d Add", #plan.categoryItems, plan.categoriesAdded)
    elseif section == "tags" then
        return string.format("%d total / %d Add", #plan.tagItems, plan.tagsAdded)
    end
    return string.format("%d source Favorites", sourceFavorites(plan.model))
end

function ImportDialog:SetSectionSelected(section, selected)
    if not self.plan or section == "favorites" then return end
    MacroStudio.ImportPlanner:SetSectionSelected(self.plan, section, selected)
    MacroStudio.PortableImport:SetActivePlan(self.plan)
    self:RebuildPreview()
end

function ImportDialog:AddSection(section)
    local row = self:AcquirePreviewRow()
    local expanded = self.sectionExpanded[section] ~= false
    self:ConfigurePreviewRow(row, {
        kind = "section",
        section = section,
        label = (expanded and "|cff59b8ff[-]|r " or "|cff59b8ff[+]|r ")
            .. SECTION_LABELS[section] .. "  " .. self:GetSectionSummary(section),
        status = "",
        indent = 6,
    })
end

function ImportDialog:MatchesSearch(values)
    local query = lower(self.previewSearchBox:GetText())
    if query == "" then return true end
    for _, value in ipairs(values) do
        if lower(value):find(query, 1, true) then return true end
    end
    return false
end

function ImportDialog:MatchesFilter(section, item)
    if self.previewFilter == "all" then return true end
    if self.previewFilter == "blocked" then return isBlocked(section, item) end
    if section == "account" or section == "character" then
        return item.action == "create" or isBlocked(section, item) or nativeHasMetadata(self.plan, item)
    elseif section == "offline" then
        return item.action == "add" or item.action == "update" or isBlocked(section, item)
    elseif section == "categories" or section == "tags" then
        return item.hasAssociation == true
    end
    return true
end

function ImportDialog:AddNativeRows(section)
    for _, item in ipairs(self.plan[section].items or {}) do
        if self:MatchesFilter(section, item)
            and self:MatchesSearch({ item.source.name, item.source.body, section, item.blockReason }) then
            local selectable = MacroStudio.ImportPlanner:IsSelectable(self.plan, section, item)
            local status = STATUS_LABELS[item.action] or item.action
            if item.action == "reuse" and nativeHasMetadata(self.plan, item) then
                status = "Present / metadata"
            end
            local row = self:AcquirePreviewRow()
            self:ConfigurePreviewRow(row, {
                kind = "item",
                section = section,
                item = item,
                label = item.source.name,
                status = status,
                checkable = true,
                checked = MacroStudio.ImportPlanner:IsSelected(self.plan, section, item),
                disabled = not selectable,
            })
        end
    end
end

function ImportDialog:AddOfflineRows()
    for _, item in ipairs(self.plan.offline.items or {}) do
        local source = item.source
        local searchValues = { characterName(source), item.blockReason }
        for _, macro in ipairs(source.macros or {}) do
            searchValues[#searchValues + 1] = macro.name
            searchValues[#searchValues + 1] = macro.body
        end
        if self:MatchesFilter("offline", item) and self:MatchesSearch(searchValues) then
            local selectable = MacroStudio.ImportPlanner:IsSelectable(self.plan, "offline", item)
            local expanded = self.offlineExpanded[source.sourceId] == true or lower(self.previewSearchBox:GetText()) ~= ""
            local status = string.format("%s / %d macros", STATUS_LABELS[item.status] or item.status or item.action, #(source.macros or {}))
            local row = self:AcquirePreviewRow()
            self:ConfigurePreviewRow(row, {
                kind = "offline",
                section = "offline",
                item = item,
                label = (expanded and "[-] " or "[+] ") .. characterName(source),
                status = status,
                checkable = true,
                checked = MacroStudio.ImportPlanner:IsSelected(self.plan, "offline", item),
                disabled = not selectable,
            })
            if expanded then
                for index, macro in ipairs(source.macros or {}) do
                    local child = self:AcquirePreviewRow()
                    self:ConfigurePreviewRow(child, {
                        kind = "offlineMacro",
                        section = "offline",
                        item = item,
                        offlineMacro = macro,
                        label = string.format("%d. %s", index, macro.name),
                        status = "Inspect only",
                        indent = 34,
                    })
                end
            end
        end
    end
end

function ImportDialog:AddDefinitionRows(section, items)
    for _, item in ipairs(items or {}) do
        if self:MatchesFilter(section, item)
            and self:MatchesSearch({ item.source.name, section }) then
            local row = self:AcquirePreviewRow()
            self:ConfigurePreviewRow(row, {
                kind = "item",
                section = section,
                item = item,
                label = item.source.name,
                status = item.action == "create" and "Add" or "Already present",
                checkable = true,
                checked = MacroStudio.ImportPlanner:IsSelected(self.plan, section, item),
            })
        end
    end
end
function ImportDialog:AddFavoriteRow()
    if self.previewFilter ~= "blocked" and sourceFavorites(self.plan.model) > 0
        and self:MatchesSearch({ "Favorites", "favorite" }) then
        local row = self:AcquirePreviewRow()
        self:ConfigurePreviewRow(row, {
            kind = "favorite",
            section = "favorites",
            label = "Restore Favorites",
            status = string.format("%d source Favorites", sourceFavorites(self.plan.model)),
            checkable = true,
            checked = self.plan.selection.restoreFavorites,
        })
    end
end

function ImportDialog:RebuildPreview()
    if not self.plan or not self.previewScrollChild then return end
    self:ReleasePreviewRows()
    local sections = {
        { "account", function() self:AddNativeRows("account") end },
        { "character", function() self:AddNativeRows("character") end },
        { "offline", function() self:AddOfflineRows() end },
        { "categories", function() self:AddDefinitionRows("categories", self.plan.categoryItems) end },
        { "tags", function() self:AddDefinitionRows("tags", self.plan.tagItems) end },
        { "favorites", function() self:AddFavoriteRow() end },
    }
    for _, definition in ipairs(sections) do
        local section, populate = definition[1], definition[2]
        self:AddSection(section)
        if self.sectionExpanded[section] ~= false then populate() end
    end
    self.previewScrollChild:SetHeight(math.max(340, -self.previewNextY + 8))
    self:RefreshPreviewState()
end

function ImportDialog:ActivatePreviewRow(row)
    if row.kind == "section" then
        self.sectionExpanded[row.section] = not (self.sectionExpanded[row.section] ~= false)
        self:RebuildPreview()
        return
    elseif row.kind == "offline" then
        local id = row.item.source.id or row.item.source.sourceId
        self.offlineExpanded[id] = not (self.offlineExpanded[id] == true)
        self:ShowPreviewDetails(row)
        self:RebuildPreview()
        return
    end
    self:ShowPreviewDetails(row)
end

function ImportDialog:TogglePreviewRow(row, checked)
    if not self.plan then return end
    if row.kind == "favorite" then
        MacroStudio.ImportPlanner:SetRestoreFavorites(self.plan, checked)
    elseif row.item then
        MacroStudio.ImportPlanner:SetItemSelected(self.plan, row.section, row.item, checked)
    end
    MacroStudio.PortableImport:SetActivePlan(self.plan)
    self:RebuildPreview()
end

function ImportDialog:SetPreviewFilter(filter)
    self.previewFilter = filter
    for key, button in pairs(self.filterButtons or {}) do
        button:SetText(key == filter and ("[" .. button.filterLabel .. "]") or button.filterLabel)
    end
    self:RebuildPreview()
end

function ImportDialog:ShowPreviewDetails(row)
    local title, metadata, body, icon = "Import Selection", "", "", nil
    if row.kind == "item" and (row.section == "account" or row.section == "character") then
        local item = row.item
        local association = associationFor(self.plan, item.source.id)
        title = item.source.name
        icon = iconValue(item.source.icon)
        local scopeText = row.section == "account" and "Account macro" or "Source Character macro"
        local actionText = STATUS_LABELS[item.action] or item.action
        if item.action == "create" then
            actionText = "Create new " .. (row.section == "account" and "Account" or "Character") .. " macro"
        elseif item.action == "reuse" then
            actionText = "Existing exact match; no native macro will be created. Selected metadata may merge."
        end
        local details = {
            scopeText,
            "Planned action: " .. actionText,
        }
        if row.section == "character" then
            details[#details + 1] = "Source: " .. characterName(self.plan.model.currentCharacter)
        end
        if item.sameNameExists and item.action == "create" then
            details[#details + 1] = "A same-name macro exists, but its exact body/icon identity differs; this remains a separate macro."
        end
        if association then
            if association.category then details[#details + 1] = "Category: " .. association.category.name end
            local names = {}
            for _, tag in ipairs(association.tags or {}) do names[#names + 1] = tag.name end
            if #names > 0 then details[#details + 1] = "Tags: " .. table.concat(names, ", ") end
            if association.source.favorite then details[#details + 1] = "Favorite: Yes" end
        end
        if item.blockReason then details[#details + 1] = item.blockReason end
        metadata = table.concat(details, "\n")
        body = item.source.body or ""
    elseif row.kind == "offline" then
        local source = row.item.source
        title = characterName(source)
        metadata = table.concat({
            "Planned action: " .. (STATUS_LABELS[row.item.action] or row.item.action),
            string.format("Snapshot macros: %d", #(source.macros or {})),
            "Last synced: " .. tostring(source.lastSynced or "Unknown"),
            "Offline snapshots are selected atomically by character so order and character identity remain coherent.",
            row.item.blockReason or "",
        }, "\n")
    elseif row.kind == "offlineMacro" then
        local source, macro = row.item.source, row.offlineMacro
        title = macro.name
        icon = iconValue(macro.icon)
        metadata = table.concat({
            "Read-only snapshot from " .. characterName(source),
            "Snapshot order: " .. tostring(macro.order or ""),
            "Inspect only; selection belongs to the complete character snapshot above.",
        }, "\n")
        body = macro.body or ""
    elseif row.kind == "item" and (row.section == "categories" or row.section == "tags") then
        title = row.item.source.name
        metadata = (row.section == "categories" and "Category" or "Tag")
            .. "\nPlanned action: " .. (row.item.action == "create" and "Add definition when used" or "Reuse existing definition")
            .. "\nDeselecting this item prunes its metadata from selected macros."
    elseif row.kind == "favorite" then
        title = "Restore Favorites"
        metadata = "Restore Favorite status only for selected macros. Deselecting a macro or this option leaves destination Favorites untouched."
    end
    self.detailsTitle:SetText(title)
    self.detailsMetadata:SetText(metadata)
    self.detailsIcon:SetShown(icon ~= nil)
    if icon then self.detailsIcon:SetTexture(icon) end
    self.detailsBodyText = body
    self.settingDetailBody = true
    self.detailsBody:SetText(body)
    self.settingDetailBody = false
    self.detailsBody:SetCursorPosition(0)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.detailsBodyScroll)
end

function ImportDialog:RefreshPreviewState()
    if not self.plan then return end
    local selected = self.plan.selected
    self.previewSource:SetText(string.format(
        "Source: MacroStudio %s / format %d / %d Account / %d Character / %d offline characters / %d categories / %d tags",
        self.plan.model.addonVersion,
        self.plan.model.formatVersion,
        #self.plan.model.accountMacros,
        #self.plan.model.currentCharacter.macros,
        #self.plan.model.offlineCharacters,
        #self.plan.model.organization.categories,
        #self.plan.model.organization.tags
    ))
    self.previewDestination:SetText("Destination: Account macros / Character: " .. self.plan.currentCharacter)
    self.previewCharacterCheckbox:SetChecked(self.plan.options.importCharacterMacros)
    self.previewSummary:SetText(string.format(
        "Selected: %d Account create / %d Character create / %d existing metadata / %d offline changes / %d categories / %d tags / %d Favorites / %d unavailable. Capacity: Account %d/%d, Character %d/%d.",
        selected.account.create,
        selected.character.create,
        selected.metadataExisting,
        selected.offline.added + selected.offline.updated,
        #selected.categories,
        #selected.tags,
        selected.favorites,
        selected.blockedSkipped,
        selected.account.create,
        self.plan.accountAvailable,
        selected.character.create,
        self.plan.characterAvailable
    ))
    MacroStudio.Helpers:SetButtonEnabled(self.applyButton, self.plan.applyOK)
    if self.plan.applyOK then
        self:SetStatus("Selected plan is ready. Existing native macros will not be overwritten or deleted.", false)
    else
        self:SetStatus(self.plan.applyReason or "Nothing selected for import.", true)
    end
end

function ImportDialog:FindVisiblePreviewRow(section, sourceId, kind)
    for _, row in ipairs(self.visiblePreviewRows or {}) do
        local item = rawget(row, "item")
        local id = item and item.source and (item.source.id or item.source.sourceId)
        if row.section == section and (not sourceId or id == sourceId)
            and (not kind or row.kind == kind) then
            return row
        end
    end
end

function ImportDialog:Create()
    if self.frame then return self.frame end
    self:SetStage("creating import window")
    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(980, 690)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(42)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local title = MacroStudio.Helpers:CreateLabel(titleBar, "GameFontNormalLarge", "Import MacroStudio Library")
    title:SetPoint("LEFT", 17, 0)

    local windowClose = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    windowClose:SetPoint("TOPRIGHT", -3, -3)

    local explanation = MacroStudio.Helpers:CreateLabel(
        frame, "GameFontHighlightSmall",
        "Paste portable JSON created by MacroStudio Export. Validation and Preview are read-only; native macros change only after Apply Selected Import and confirmation."
    )
    explanation:SetPoint("TOPLEFT", 18, -50)
    explanation:SetPoint("TOPRIGHT", -18, -50)
    explanation:SetHeight(34)
    explanation:SetJustifyH("LEFT")
    explanation:SetJustifyV("TOP")
    explanation:SetWordWrap(true)

    local heading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Paste Portable Export")
    heading:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -8)
    heading:SetTextColor(0.35, 0.75, 1)
    self.heading = heading

    local inputPanel = MacroStudio.Helpers:CreatePanel(frame)
    inputPanel:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    inputPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 122)
    self.inputPanel = inputPanel

    local _, inputEditBox, inputScrollBox = MacroStudio.Helpers:CreateNativeScrollingEditBox(inputPanel, 6)
    inputEditBox:SetFontObject(ChatFontNormal)
    inputEditBox:SetTextColor(0.86, 0.9, 0.96)
    inputEditBox:SetAutoFocus(false)
    inputEditBox:SetMaxLetters(0)
    inputEditBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    inputEditBox:HookScript("OnTextChanged", function(_, userInput)
        if userInput then
            self.plan = nil
            MacroStudio.PortableImport:SetActivePlan(nil)
            self:SetStatus("", false)
        end
    end)
    self.inputEditBox = inputEditBox
    self.inputScrollBox = inputScrollBox

    local previewPanel = MacroStudio.Helpers:CreatePanel(frame)
    previewPanel:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    previewPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 82)
    self.previewPanel = previewPanel

    local source = MacroStudio.Helpers:CreateLabel(previewPanel, "GameFontHighlightSmall", "")
    source:SetPoint("TOPLEFT", 10, -9)
    source:SetPoint("TOPRIGHT", -10, -9)
    source:SetJustifyH("LEFT")
    self.previewSource = source

    local destination = MacroStudio.Helpers:CreateLabel(previewPanel, "GameFontHighlightSmall", "")
    destination:SetPoint("TOPLEFT", source, "BOTTOMLEFT", 0, -5)
    destination:SetPoint("TOPRIGHT", source, "BOTTOMRIGHT", 0, -5)
    destination:SetJustifyH("LEFT")
    self.previewDestination = destination

    local previewCharacter = CreateFrame("CheckButton", nil, previewPanel, "UICheckButtonTemplate")
    previewCharacter:SetSize(24, 24)
    previewCharacter:SetPoint("TOPRIGHT", -252, -38)
    previewCharacter:SetScript("OnClick", function(owner)
        local rebuilt = MacroStudio.ImportPlanner:SetCharacterImportEnabled(self.plan, owner:GetChecked())
        if rebuilt then
            self.plan = rebuilt
            MacroStudio.PortableImport:SetActivePlan(rebuilt)
            self:RebuildPreview()
        end
    end)
    self.previewCharacterCheckbox = previewCharacter

    local previewCharacterLabel = MacroStudio.Helpers:CreateLabel(previewPanel, "GameFontHighlightSmall", "Import source Character macros")
    previewCharacterLabel:SetPoint("LEFT", previewCharacter, "RIGHT", 3, 0)

    local selectAll = CreateFrame("Button", nil, previewPanel, "UIPanelButtonTemplate")
    selectAll:SetSize(74, 23)
    selectAll:SetPoint("TOPLEFT", 10, -40)
    selectAll:SetText("Select All")
    selectAll:SetScript("OnClick", function()
        MacroStudio.ImportPlanner:SetAllSelected(self.plan, true)
        MacroStudio.PortableImport:SetActivePlan(self.plan)
        self:RebuildPreview()
    end)
    self.previewSelectAllButton = selectAll

    local selectNone = CreateFrame("Button", nil, previewPanel, "UIPanelButtonTemplate")
    selectNone:SetSize(74, 23)
    selectNone:SetPoint("LEFT", selectAll, "RIGHT", 5, 0)
    selectNone:SetText("None")
    selectNone:SetScript("OnClick", function()
        MacroStudio.ImportPlanner:SetAllSelected(self.plan, false)
        MacroStudio.PortableImport:SetActivePlan(self.plan)
        self:RebuildPreview()
    end)
    self.previewSelectNoneButton = selectNone

    local searchLabel = MacroStudio.Helpers:CreateLabel(previewPanel, "GameFontHighlightSmall", "Search:")
    searchLabel:SetPoint("LEFT", selectNone, "RIGHT", 10, 0)
    local search = CreateFrame("EditBox", nil, previewPanel, "InputBoxTemplate")
    search:SetSize(190, 24)
    search:SetPoint("LEFT", searchLabel, "RIGHT", 7, 0)
    MacroStudio.Helpers:ConfigureEditBox(search)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function(_, userInput)
        if userInput and self.mode == "preview" then self:RebuildPreview() end
    end)
    self.previewSearchBox = search

    self.filterButtons = {}
    local previous
    for _, definition in ipairs({ { "changes", "Changes" }, { "all", "All" }, { "blocked", "Blocked" } }) do
        local key, label = definition[1], definition[2]
        local button = CreateFrame("Button", nil, previewPanel, "UIPanelButtonTemplate")
        button:SetSize(72, 23)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else button:SetPoint("TOPRIGHT", -154, -68) end
        button.filterLabel = label
        button:SetText(label)
        button:SetScript("OnClick", function() self:SetPreviewFilter(key) end)
        self.filterButtons[key] = button
        previous = button
    end

    local listPanel = MacroStudio.Helpers:CreatePanel(previewPanel)
    listPanel:SetPoint("TOPLEFT", 8, -98)
    listPanel:SetPoint("BOTTOMLEFT", 8, 42)
    listPanel:SetWidth(455)
    self.previewListPanel = listPanel

    local scroll = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", -27, 5)
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(415)
    scrollChild:SetHeight(340)
    scroll:SetScrollChild(scrollChild)
    self.previewScroll = scroll
    self.previewScrollChild = scrollChild
    self.previewRowPool = {}
    self.visiblePreviewRows = {}

    local detailsPanel = MacroStudio.Helpers:CreatePanel(previewPanel)
    detailsPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 8, 0)
    detailsPanel:SetPoint("BOTTOMRIGHT", -8, 42)
    self.previewDetailsPanel = detailsPanel

    local detailsIcon = detailsPanel:CreateTexture(nil, "ARTWORK")
    detailsIcon:SetSize(40, 40)
    detailsIcon:SetPoint("TOPLEFT", 10, -10)
    self.detailsIcon = detailsIcon

    local detailsTitle = MacroStudio.Helpers:CreateLabel(detailsPanel, "GameFontNormalLarge", "Select an item to inspect")
    detailsTitle:SetPoint("TOPLEFT", 60, -12)
    detailsTitle:SetPoint("TOPRIGHT", -10, -12)
    detailsTitle:SetJustifyH("LEFT")
    detailsTitle:SetWordWrap(false)
    self.detailsTitle = detailsTitle

    local detailsMetadata = MacroStudio.Helpers:CreateLabel(detailsPanel, "GameFontHighlightSmall", "")
    detailsMetadata:SetPoint("TOPLEFT", 10, -60)
    detailsMetadata:SetPoint("TOPRIGHT", -10, -60)
    detailsMetadata:SetHeight(102)
    detailsMetadata:SetJustifyH("LEFT")
    detailsMetadata:SetJustifyV("TOP")
    detailsMetadata:SetWordWrap(true)
    self.detailsMetadata = detailsMetadata

    local bodyPanel = MacroStudio.Helpers:CreatePanel(detailsPanel)
    bodyPanel:SetPoint("TOPLEFT", detailsMetadata, "BOTTOMLEFT", 0, -7)
    bodyPanel:SetPoint("BOTTOMRIGHT", -10, 10)
    local _, detailsBody, detailsBodyScroll = MacroStudio.Helpers:CreateNativeScrollingEditBox(bodyPanel, 5)
    detailsBody:SetFontObject(ChatFontNormal)
    detailsBody:SetTextColor(0.82, 0.87, 0.94)
    detailsBody:SetAutoFocus(false)
    detailsBody:SetMaxLetters(0)
    detailsBody:HookScript("OnTextChanged", function(owner, userInput)
        if self.settingDetailBody or not userInput then return end
        self.settingDetailBody = true
        owner:SetText(self.detailsBodyText or "")
        self.settingDetailBody = false
        owner:ClearFocus()
    end)
    self.detailsBody = detailsBody
    self.detailsBodyScroll = detailsBodyScroll

    local summary = MacroStudio.Helpers:CreateLabel(previewPanel, "GameFontHighlightSmall", "")
    summary:SetPoint("BOTTOMLEFT", 10, 8)
    summary:SetPoint("BOTTOMRIGHT", -10, 8)
    summary:SetHeight(29)
    summary:SetJustifyH("LEFT")
    summary:SetJustifyV("TOP")
    summary:SetWordWrap(true)
    self.previewSummary = summary
    local outputPanel = MacroStudio.Helpers:CreatePanel(frame)
    outputPanel:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    outputPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 52)
    self.outputPanel = outputPanel

    local _, outputEditBox, outputScrollBox = MacroStudio.Helpers:CreateNativeScrollingEditBox(outputPanel, 6)
    outputEditBox:SetFontObject(ChatFontNormal)
    outputEditBox:SetTextColor(0.82, 0.87, 0.94)
    outputEditBox:SetAutoFocus(false)
    outputEditBox:SetMaxLetters(0)
    outputEditBox:HookScript("OnTextChanged", function(owner, userInput)
        if self.settingOutput or not userInput then return end
        self.settingOutput = true
        owner:SetText(self.outputText or "")
        self.settingOutput = false
        owner:ClearFocus()
    end)
    self.outputEditBox = outputEditBox
    self.outputScrollBox = outputScrollBox

    local characterCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    characterCheckbox:SetSize(24, 24)
    characterCheckbox:SetPoint("BOTTOMLEFT", 18, 81)
    characterCheckbox:SetChecked(true)
    self.characterCheckbox = characterCheckbox

    local characterLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    characterLabel:SetPoint("LEFT", characterCheckbox, "RIGHT", 5, 0)
    characterLabel:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    characterLabel:SetJustifyH("LEFT")
    self.characterLabel = characterLabel

    local status = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    status:SetPoint("BOTTOMLEFT", 18, 47)
    status:SetPoint("BOTTOMRIGHT", -18, 47)
    status:SetHeight(28)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetWordWrap(true)
    self.statusText = status

    local validate = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    validate:SetSize(150, 26)
    validate:SetPoint("BOTTOMLEFT", 18, 16)
    validate:SetText("Validate & Preview")
    validate:SetScript("OnClick", function() self:ValidateAndPreview() end)
    self.validateButton = validate

    local back = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    back:SetSize(110, 26)
    back:SetPoint("BOTTOMLEFT", 18, 16)
    back:SetScript("OnClick", function() self:BackToPaste() end)
    self.backButton = back

    local apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    apply:SetSize(170, 26)
    apply:SetPoint("BOTTOMRIGHT", -116, 16)
    apply:SetText("Apply Selected Import")
    apply:SetScript("OnClick", function() self:RequestApply() end)
    self.applyButton = apply

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(90, 26)
    close:SetPoint("BOTTOMRIGHT", -18, 16)
    close:SetScript("OnClick", function() frame:Hide() end)
    self.closeButton = close

    frame:SetScript("OnHide", function()
        inputEditBox:ClearFocus()
        outputEditBox:ClearFocus()
        detailsBody:ClearFocus()
        search:ClearFocus()
        self.plan = nil
        MacroStudio.PortableImport:SetActivePlan(nil)
        MacroStudio:SetMainWindowModalBlocked(false)
    end)
    self.sectionExpanded = {
        account = true, character = true, offline = true,
        categories = true, tags = true, favorites = true,
    }
    self.offlineExpanded = {}
    self.previewFilter = "changes"
    self:SetMode("paste")
    self:SetStatus("", false)
    self:SetStage(nil)
    return frame
end

function ImportDialog:RefreshDestination()
    local current = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    local destination = current and ((current.name or "Unknown Character") .. " - " .. (current.realm or "Unknown Realm"))
        or "Current Character"
    self.characterLabel:SetText("Import source Character macros to this character: " .. destination)
end

function ImportDialog:BackToPaste()
    self.plan = nil
    MacroStudio.PortableImport:SetActivePlan(nil)
    self:SetStatus("", false)
    self:SetMode("paste")
    self.inputEditBox:SetFocus()
end

function ImportDialog:ValidateAndPreview()
    self:SetStage("validating pasted JSON")
    local ok, plan = xpcall(function()
        return MacroStudio.PortableImport:Preview(self.inputEditBox:GetText() or "", {
            importCharacterMacros = self.characterCheckbox:GetChecked() == true,
        })
    end, conciseError)
    if not ok then
        self.plan = nil
        MacroStudio.PortableImport:SetActivePlan(nil)
        self:SetStatus(plan, true)
        self:SetStage(nil)
        return false
    end
    self.plan = plan
    MacroStudio.PortableImport:SetActivePlan(plan)
    self.previewSearchBox:SetText("")
    self.previewFilter = "changes"
    self.detailsTitle:SetText("Select an item to inspect")
    self.detailsMetadata:SetText("Use the checkboxes to choose exactly what MacroStudio will apply.")
    self.detailsIcon:Hide()
    self.detailsBodyText = ""
    self.settingDetailBody = true
    self.detailsBody:SetText("")
    self.settingDetailBody = false
    self:SetMode("preview")
    self:SetPreviewFilter("changes")
    self:SetStage(nil)
    return true
end

function ImportDialog:RequestApply()
    if not self.plan or not self.plan.applyOK then return false end
    return MacroStudio.Dialogs:ShowConfirmImport(self.plan, function() self:ApplyConfirmed() end)
end

function ImportDialog:ApplyConfirmed()
    local values
    self:SetStage("revalidating selected import")
    local ok, failure = xpcall(function()
        values = { MacroStudio.PortableImport:Apply(self.plan) }
    end, conciseError)
    if not ok then
        self:SetStatus("Import stopped safely: " .. failure, true)
        self:SetStage(nil)
        return false
    end
    local success, result, message = unpack(values)
    if result then
        self:SetOutput(resultText(success, result))
        self:SetMode("result")
        self:SetStatus(success and "Import finished." or "Import stopped; review the result before retrying.", not success)
    else
        self:SetStatus(message or "Import could not be applied. Run Validate & Preview again if repository state changed.", true)
    end
    self:SetStage(nil)
    return success
end

function ImportDialog:Open(source)
    MacroStudio:Debug("import open invoked", source or "unknown")
    if not MacroStudio.initialized then MacroStudio:Initialize() end
    local frame = self:Create()
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    local settingsShown = settingsFrame and settingsFrame:IsShown() or false
    if MacroStudio:IsMainWindowModalBlocked() and not frame:IsShown() and not settingsShown then
        MacroStudio:Print("Close the current dialog before opening Import.")
        return false
    end
    if not frame:IsShown() then
        self.inputEditBox:SetText("")
        self.characterCheckbox:SetChecked(true)
        self:RefreshDestination()
        self:SetStatus("", false)
        self:SetMode("paste")
        frame:Show()
    end
    frame:Raise()
    if settingsShown then settingsFrame:Hide() end
    MacroStudio:SetMainWindowModalBlocked(true)
    self.inputEditBox:SetFocus()
    return true
end

function ImportDialog:HandleFailure()
    if self.frame then self.frame:Hide() end
    self.plan = nil
    MacroStudio.PortableImport:SetActivePlan(nil)
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    MacroStudio:SetMainWindowModalBlocked(settingsFrame and settingsFrame:IsShown() or false)
end
