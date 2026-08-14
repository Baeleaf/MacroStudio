local _, MacroStudio = ...

local ImportPlanner = {}
MacroStudio.ImportPlanner = ImportPlanner

local NATIVE_SECTIONS = {
    account = true,
    character = true,
}

local function sourceId(item)
    return item and item.source and (item.source.id or item.source.sourceId)
end

local function copyChoiceMap(items, previous, defaultSelected)
    local result = {}
    previous = type(previous) == "table" and previous or {}
    for _, item in ipairs(items or {}) do
        local id = sourceId(item)
        if id then
            if type(previous[id]) == "boolean" then
                result[id] = previous[id]
            else
                result[id] = defaultSelected(item)
            end
        end
    end
    return result
end

local function nativeImportable(item)
    return item and (item.action == "create" or item.action == "reuse")
end

local function offlineImportable(item)
    return item and (item.action == "add" or item.action == "update")
end

local function definitionImportable()
    return true
end

local function selectedNativeItems(plan, section)
    local result = { items = {}, create = 0, present = 0, blocked = 0, ambiguous = 0, disabled = 0 }
    local enabled = section ~= "character" or plan.options.importCharacterMacros
    for _, item in ipairs(plan[section].items or {}) do
        if enabled and nativeImportable(item) and plan.selection[section][sourceId(item)] then
            result.items[#result.items + 1] = item
            if item.action == "create" then result.create = result.create + 1
            else result.present = result.present + 1 end
        end
    end
    return result
end

local function selectedOfflineItems(plan)
    local result = { items = {}, added = 0, updated = 0, kept = 0 }
    for _, item in ipairs(plan.offline.items or {}) do
        if offlineImportable(item) and plan.selection.offline[sourceId(item)] then
            result.items[#result.items + 1] = item
            if item.action == "add" then result.added = result.added + 1
            else result.updated = result.updated + 1 end
        end
    end
    return result
end

local function metadataWouldChange(plan, association)
    local item = association.item
    local presentation = association.presentation or {}
    local selected = {
        source = association.source,
        item = item,
        category = nil,
        tags = {},
        favorite = false,
        categoryConflict = association.categoryConflict,
    }
    local changed = false

    if association.category
        and plan.selection.categories[association.category.id]
        and not association.categoryConflict
        and (item.action == "create" or not presentation.categoryId) then
        selected.category = association.category
        changed = true
    end

    for _, tag in ipairs(association.tags or {}) do
        if plan.selection.tags[tag.id] then
            local assigned = item.action == "reuse"
                and MacroStudio.MetadataRepository:IsTagAssigned(item.target, tag.name)
            if not assigned then
                selected.tags[#selected.tags + 1] = tag
                changed = true
            end
        end
    end

    if plan.selection.restoreFavorites and association.source.favorite
        and (item.action == "create" or not presentation.favorite) then
        selected.favorite = true
        changed = true
    end

    return changed, selected
end

local function appendSignature(parts, label, items, choices)
    parts[#parts + 1] = label
    for _, item in ipairs(items or {}) do
        local id = sourceId(item) or ""
        parts[#parts + 1] = id .. ":" .. tostring(item.action) .. ":" .. (choices[id] and "1" or "0")
    end
end

function ImportPlanner:InitializePlan(plan, previous)
    previous = type(previous) == "table" and previous or {}
    plan.selection = {
        account = copyChoiceMap(plan.account.items, previous.account, nativeImportable),
        character = copyChoiceMap(plan.character.items, previous.character, nativeImportable),
        offline = copyChoiceMap(plan.offline.items, previous.offline, offlineImportable),
        categories = copyChoiceMap(plan.categoryItems, previous.categories, definitionImportable),
        tags = copyChoiceMap(plan.tagItems, previous.tags, definitionImportable),
        restoreFavorites = previous.restoreFavorites,
    }
    if plan.selection.restoreFavorites == nil then
        plan.selection.restoreFavorites = true
    end
    self:Recalculate(plan)
    return plan
end

function ImportPlanner:IsSelectable(plan, section, item)
    if NATIVE_SECTIONS[section] then
        if section == "character" and not plan.options.importCharacterMacros then return false end
        return nativeImportable(item)
    elseif section == "offline" then
        return offlineImportable(item)
    elseif section == "categories" or section == "tags" then
        return item ~= nil
    end
    return false
end

function ImportPlanner:IsSelected(plan, section, item)
    local id = sourceId(item)
    return id and self:IsSelectable(plan, section, item)
        and plan.selection[section][id] == true
end

function ImportPlanner:Recalculate(plan)
    local selected = {
        account = selectedNativeItems(plan, "account"),
        character = selectedNativeItems(plan, "character"),
        offline = selectedOfflineItems(plan),
        associations = {},
        categories = {},
        tags = {},
        favorites = 0,
        metadataExisting = 0,
        metadataMacros = 0,
        blockedSkipped = plan.account.blocked + plan.account.ambiguous + plan.account.disabled
            + plan.character.blocked + plan.character.ambiguous + plan.character.disabled,
    }

    local selectedNativeById = {}
    for _, item in ipairs(selected.account.items) do selectedNativeById[sourceId(item)] = item end
    for _, item in ipairs(selected.character.items) do selectedNativeById[sourceId(item)] = item end

    local categoryUsed = {}
    local tagUsed = {}
    local existingMetadata = {}
    for _, association in ipairs(plan.associations or {}) do
        local id = association.source.macroId
        if selectedNativeById[id] then
            local changed, effective = metadataWouldChange(plan, association)
            if changed then
                selected.associations[#selected.associations + 1] = effective
                selected.metadataMacros = selected.metadataMacros + 1
                if association.item.action == "reuse" and not existingMetadata[id] then
                    existingMetadata[id] = true
                    selected.metadataExisting = selected.metadataExisting + 1
                end
                if effective.category then categoryUsed[effective.category.id] = true end
                for _, tag in ipairs(effective.tags) do tagUsed[tag.id] = true end
                if effective.favorite then selected.favorites = selected.favorites + 1 end
            end
        end
    end

    for _, item in ipairs(plan.categoryItems or {}) do
        if categoryUsed[sourceId(item)] then selected.categories[#selected.categories + 1] = item end
    end
    for _, item in ipairs(plan.tagItems or {}) do
        if tagUsed[sourceId(item)] then selected.tags[#selected.tags + 1] = item end
    end

    selected.accountCapacityOK = selected.account.create <= plan.accountAvailable
    selected.characterCapacityOK = selected.character.create <= plan.characterAvailable
    selected.capacityOK = selected.accountCapacityOK and selected.characterCapacityOK
    selected.actionable = (selected.account.create + selected.character.create
        + selected.offline.added + selected.offline.updated
        + #selected.associations) > 0

    plan.selected = selected
    plan.capacityOK = selected.capacityOK
    plan.nativeContentOK = true
    plan.applyOK = selected.actionable and selected.capacityOK
    if not selected.actionable then
        plan.applyReason = "Nothing selected for import."
    elseif not selected.accountCapacityOK then
        plan.applyReason = string.format(
            "Selected Account macros need %d slots, but only %d are available.",
            selected.account.create, plan.accountAvailable
        )
    elseif not selected.characterCapacityOK then
        plan.applyReason = string.format(
            "Selected Character macros need %d slots, but only %d are available.",
            selected.character.create, plan.characterAvailable
        )
    else
        plan.applyReason = nil
    end

    local signature = {
        plan.options.importCharacterMacros and "character:1" or "character:0",
        plan.selection.restoreFavorites and "favorites:1" or "favorites:0",
    }
    appendSignature(signature, "account", plan.account.items, plan.selection.account)
    appendSignature(signature, "character", plan.character.items, plan.selection.character)
    appendSignature(signature, "offline", plan.offline.items, plan.selection.offline)
    appendSignature(signature, "categories", plan.categoryItems, plan.selection.categories)
    appendSignature(signature, "tags", plan.tagItems, plan.selection.tags)
    plan.selectionSignature = table.concat(signature, "|")
    return selected
end

function ImportPlanner:SetItemSelected(plan, section, item, selected)
    if not plan or not self:IsSelectable(plan, section, item) then return false end
    plan.selection[section][sourceId(item)] = selected and true or false
    self:Recalculate(plan)
    return true
end

function ImportPlanner:SetSectionSelected(plan, section, selected)
    if not plan or not plan.selection[section] then return false end
    local items = plan[section] and plan[section].items
        or section == "categories" and plan.categoryItems
        or section == "tags" and plan.tagItems
        or nil
    if not items then return false end
    for _, item in ipairs(items) do
        if self:IsSelectable(plan, section, item) then
            plan.selection[section][sourceId(item)] = selected and true or false
        elseif not selected then
            plan.selection[section][sourceId(item)] = false
        end
    end
    self:Recalculate(plan)
    return true
end

function ImportPlanner:SetAllSelected(plan, selected)
    if not plan then return false end
    if not selected then
        for _, section in ipairs({ "account", "character", "offline", "categories", "tags" }) do
            for id in pairs(plan.selection[section]) do plan.selection[section][id] = false end
        end
    else
        self:SetSectionSelected(plan, "account", true)
        self:SetSectionSelected(plan, "character", true)
        self:SetSectionSelected(plan, "offline", true)
        self:SetSectionSelected(plan, "categories", true)
        self:SetSectionSelected(plan, "tags", true)
    end
    plan.selection.restoreFavorites = selected and true or false
    self:Recalculate(plan)
    return true
end

function ImportPlanner:SetRestoreFavorites(plan, selected)
    if not plan then return false end
    plan.selection.restoreFavorites = selected and true or false
    self:Recalculate(plan)
    return true
end

function ImportPlanner:SetCharacterImportEnabled(plan, enabled)
    if not plan then return nil end
    return MacroStudio.PortableImport:BuildPlan(
        plan.model,
        { importCharacterMacros = enabled and true or false },
        plan.selection
    )
end

function ImportPlanner:GetConfirmationText(plan)
    local selected = plan and plan.selected
    if not selected then return "Apply selected import?" end
    return table.concat({
        "Apply selected import?",
        "",
        "MacroStudio will:",
        string.format("- Create %d Account macros", selected.account.create),
        string.format("- Create %d Character macros", selected.character.create),
        string.format("- Merge metadata for %d existing macros", selected.metadataExisting),
        string.format("- Apply %d offline character snapshots", selected.offline.added + selected.offline.updated),
        string.format("- Add or apply %d categories", #selected.categories),
        string.format("- Add or apply %d tags", #selected.tags),
        string.format("- Restore %d Favorites", selected.favorites),
    }, "\n")
end
