local _, MacroStudio = ...

local MetadataRepository = {
    attachedByIndex = {},
    attachedByRecord = {},
    reconciliation = {},
}
MacroStudio.MetadataRepository = MetadataRepository

local MAX_CATEGORY_NAME_LENGTH = 40
local MAX_TAG_LENGTH = 30

local function trim(value)
    return MacroStudio.Helpers:Trim(value)
end

local function normalizedKey(value)
    return trim(value):lower()
end

local function copyTags(tags)
    local result = {}
    if type(tags) == "table" then
        for _, tag in ipairs(tags) do
            if type(tag) == "string" and tag ~= "" then
                result[#result + 1] = tag
            end
        end
    end
    return result
end

local function identityIcon(macro)
    return macro and (macro.selectedIcon or macro.icon)
end

local function copySnapshot(macro)
    return {
        scope = macro.scope,
        lastKnownIndex = macro.index,
        name = macro.name,
        icon = identityIcon(macro),
        body = macro.body,
    }
end

local function recordIsMeaningful(record)
    return record.favorite == true
        or type(record.categoryId) == "string"
        or (type(record.tags) == "table" and #record.tags > 0)
end

function MetadataRepository:GetStore()
    return MacroStudio.db and MacroStudio.db.metadata
end

function MetadataRepository:GetCategoryStore()
    return MacroStudio.db and MacroStudio.db.categories
end

function MetadataRepository:GetRecords()
    local store = self:GetStore()
    return store and store.records or {}
end

function MetadataRepository:GetCategories()
    local store = self:GetCategoryStore()
    local categories = {}
    if not store then
        return categories
    end

    for _, categoryId in ipairs(store.order) do
        local category = store.byId[categoryId]
        if type(category) == "table" and type(category.name) == "string" then
            categories[#categories + 1] = category
        end
    end
    return categories
end

function MetadataRepository:GetCategory(categoryId)
    local store = self:GetCategoryStore()
    return store and store.byId[categoryId] or nil
end

function MetadataRepository:ValidateCategoryName(name, excludedId)
    local cleaned = trim(name)
    if cleaned == "" then
        return nil, "Category name cannot be empty."
    end
    if MacroStudio.Helpers:TextLength(cleaned) > MAX_CATEGORY_NAME_LENGTH then
        return nil, string.format("Category names are limited to %d characters.", MAX_CATEGORY_NAME_LENGTH)
    end

    local wantedKey = normalizedKey(cleaned)
    for _, category in ipairs(self:GetCategories()) do
        if category.id ~= excludedId and normalizedKey(category.name) == wantedKey then
            return nil, "A category with that name already exists."
        end
    end
    return cleaned
end

function MetadataRepository:CreateCategory(name)
    local cleaned, message = self:ValidateCategoryName(name)
    if not cleaned then
        return nil, message
    end

    local store = self:GetCategoryStore()
    local categoryId
    repeat
        categoryId = "category-" .. store.nextId
        store.nextId = store.nextId + 1
    until not store.byId[categoryId]

    local category = {
        id = categoryId,
        name = cleaned,
    }
    store.byId[categoryId] = category
    store.order[#store.order + 1] = categoryId
    MacroStudio:Debug("category created", categoryId, cleaned)
    return category
end

function MetadataRepository:RenameCategory(categoryId, name)
    local category = self:GetCategory(categoryId)
    if not category then
        return false, "The selected category no longer exists."
    end

    local cleaned, message = self:ValidateCategoryName(name, categoryId)
    if not cleaned then
        return false, message
    end

    category.name = cleaned
    MacroStudio:Debug("category renamed", categoryId, cleaned)
    return true, category
end

function MetadataRepository:DeleteCategory(categoryId)
    local store = self:GetCategoryStore()
    local category = store and store.byId[categoryId]
    if not category then
        return false, "The selected category no longer exists."
    end

    store.byId[categoryId] = nil
    for index = #store.order, 1, -1 do
        if store.order[index] == categoryId then
            table.remove(store.order, index)
        end
    end

    local records = self:GetRecords()
    for recordId, record in pairs(records) do
        if record.categoryId == categoryId then
            record.categoryId = nil
            self:PruneRecord(recordId)
        end
    end

    MacroStudio:Debug("category deleted", categoryId, category.name)
    return true, category
end

function MetadataRepository:AllocateRecordId()
    local store = self:GetStore()
    local recordId
    repeat
        recordId = "metadata-" .. store.nextId
        store.nextId = store.nextId + 1
    until not store.records[recordId]
    return recordId
end

function MetadataRepository:Attach(recordId, record, macro)
    local previousIndex = self.attachedByRecord[recordId]
    if previousIndex then
        self.attachedByIndex[previousIndex] = nil
    end

    self.attachedByIndex[macro.index] = recordId
    self.attachedByRecord[recordId] = macro.index
    record.snapshot = copySnapshot(macro)
    self.reconciliation[recordId] = "attached"
end

function MetadataRepository:GetRecordForMacro(macro)
    if type(macro) ~= "table" then
        return nil
    end
    local recordId = self.attachedByIndex[macro.index]
    local record = recordId and self:GetRecords()[recordId] or nil
    return record, recordId
end

function MetadataRepository:EnsureRecordForMacro(macro)
    local record, recordId = self:GetRecordForMacro(macro)
    if record then
        return record, recordId
    end

    recordId = self:AllocateRecordId()
    record = {
        id = recordId,
        favorite = false,
        tags = {},
        snapshot = copySnapshot(macro),
    }
    self:GetRecords()[recordId] = record
    self:Attach(recordId, record, macro)
    return record, recordId
end

function MetadataRepository:PruneRecord(recordId)
    local records = self:GetRecords()
    local record = records[recordId]
    if not record or recordIsMeaningful(record) then
        return
    end

    local index = self.attachedByRecord[recordId]
    if index then
        self.attachedByIndex[index] = nil
    end
    self.attachedByRecord[recordId] = nil
    self.reconciliation[recordId] = nil
    records[recordId] = nil
end

local function getCandidates(macros, available, predicate)
    local candidates = {}
    for _, macro in ipairs(macros) do
        if available[macro.index] and predicate(macro) then
            candidates[#candidates + 1] = macro
        end
    end
    return candidates
end

function MetadataRepository:FindReconciliationCandidate(record, macros, available)
    local snapshot = record.snapshot
    if type(snapshot) ~= "table" then
        return nil, "missing snapshot"
    end

    local exact = getCandidates(macros, available, function(macro)
        return macro.scope == snapshot.scope
            and macro.name == snapshot.name
            and MacroStudio.Helpers:IconsEqual(identityIcon(macro), snapshot.icon)
            and macro.body == snapshot.body
    end)
    if #exact == 1 then
        return exact[1], "exact snapshot"
    elseif #exact > 1 then
        return nil, "ambiguous exact snapshots"
    end

    local nameAndIcon = getCandidates(macros, available, function(macro)
        return macro.scope == snapshot.scope
            and macro.name == snapshot.name
            and MacroStudio.Helpers:IconsEqual(identityIcon(macro), snapshot.icon)
    end)
    if #nameAndIcon == 1 then
        return nameAndIcon[1], "unique scope/name/icon"
    elseif #nameAndIcon > 1 then
        return nil, "ambiguous scope/name/icon"
    end

    local nameAndBody = getCandidates(macros, available, function(macro)
        return macro.scope == snapshot.scope
            and macro.name == snapshot.name
            and macro.body == snapshot.body
    end)
    if #nameAndBody == 1 then
        return nameAndBody[1], "unique scope/name/body"
    elseif #nameAndBody > 1 then
        return nil, "ambiguous scope/name/body"
    end

    return nil, "no confident match"
end

function MetadataRepository:Reconcile(macros)
    self.attachedByIndex = {}
    self.attachedByRecord = {}
    self.reconciliation = {}

    local available = {}
    for _, macro in ipairs(macros or {}) do
        available[macro.index] = true
    end

    local recordIds = {}
    for recordId in pairs(self:GetRecords()) do
        recordIds[#recordIds + 1] = recordId
    end
    table.sort(recordIds)

    for _, recordId in ipairs(recordIds) do
        local record = self:GetRecords()[recordId]
        if type(record) ~= "table" then
            self:GetRecords()[recordId] = nil
        else
            record.tags = copyTags(record.tags)
            record.favorite = record.favorite == true

            if record.categoryId and not self:GetCategory(record.categoryId) then
                record.categoryId = nil
            end

            if recordIsMeaningful(record) then
                local macro, reason = self:FindReconciliationCandidate(record, macros or {}, available)
                if macro then
                    self:Attach(recordId, record, macro)
                    available[macro.index] = nil
                    MacroStudio:Debug("metadata assigned", recordId, "->", macro.index, reason)
                else
                    self.reconciliation[recordId] = reason
                    MacroStudio:Debug("metadata reconciliation ambiguous", recordId, reason)
                end
            else
                self:GetRecords()[recordId] = nil
            end
        end
    end
end

function MetadataRepository:OnMacroSaved(previousMacro, updatedMacro, trustedRecordId)
    local recordId = trustedRecordId
    local record = recordId and self:GetRecords()[recordId] or nil
    if not record then
        record, recordId = self:GetRecordForMacro(previousMacro)
    end
    if record and updatedMacro then
        self:Attach(recordId, record, updatedMacro)
    end
end

function MetadataRepository:GetPresentation(macro)
    local record = self:GetRecordForMacro(macro)
    local category = record and record.categoryId and self:GetCategory(record.categoryId) or nil
    return {
        favorite = record and record.favorite == true or false,
        categoryId = category and category.id or nil,
        categoryName = category and category.name or "Uncategorized",
        tags = record and copyTags(record.tags) or {},
    }
end

function MetadataRepository:IsFavorite(macro)
    local record = self:GetRecordForMacro(macro)
    return record and record.favorite == true or false
end

function MetadataRepository:GetCategoryId(macro)
    local record = self:GetRecordForMacro(macro)
    return record and record.categoryId or nil
end

function MetadataRepository:SetCategory(macro, categoryId)
    if categoryId and not self:GetCategory(categoryId) then
        return false, "The selected category no longer exists."
    end

    local record, recordId = self:EnsureRecordForMacro(macro)
    record.categoryId = categoryId
    self:PruneRecord(recordId)
    MacroStudio:Debug("metadata assigned", recordId, "category", categoryId or "none")
    return true
end

function MetadataRepository:ToggleFavorite(macro)
    local record, recordId = self:EnsureRecordForMacro(macro)
    record.favorite = not record.favorite
    local favorite = record.favorite
    self:PruneRecord(recordId)
    MacroStudio:Debug("metadata assigned", recordId, "favorite", favorite)
    return favorite
end

function MetadataRepository:AddTag(macro, tag)
    local cleaned = trim(tag):gsub("[%c]", "")
    cleaned = cleaned:gsub("%s+", " ")
    if cleaned == "" then
        return false, "Tag cannot be empty."
    end
    if MacroStudio.Helpers:TextLength(cleaned) > MAX_TAG_LENGTH then
        return false, string.format("Tags are limited to %d characters.", MAX_TAG_LENGTH)
    end

    local record, recordId = self:EnsureRecordForMacro(macro)
    local wantedKey = normalizedKey(cleaned)
    for _, existing in ipairs(record.tags) do
        if normalizedKey(existing) == wantedKey then
            return false, "That tag is already assigned to this macro."
        end
    end

    record.tags[#record.tags + 1] = cleaned
    table.sort(record.tags, function(first, second)
        return first:lower() < second:lower()
    end)
    MacroStudio:Debug("metadata assigned", recordId, "tag", cleaned)
    return true, cleaned
end

function MetadataRepository:RemoveTag(macro, tag)
    local record, recordId = self:GetRecordForMacro(macro)
    if not record then
        return false, "This macro has no tags."
    end

    local wantedKey = normalizedKey(tag)
    for index = #record.tags, 1, -1 do
        if normalizedKey(record.tags[index]) == wantedKey then
            local removed = table.remove(record.tags, index)
            self:PruneRecord(recordId)
            MacroStudio:Debug("metadata assigned", recordId, "tag removed", removed)
            return true, removed
        end
    end
    return false, "That tag is no longer assigned to this macro."
end

function MetadataRepository:GetAllTags()
    local byKey = {}
    for _, record in pairs(self:GetRecords()) do
        for _, tag in ipairs(type(record) == "table" and record.tags or {}) do
            local key = normalizedKey(tag)
            if key ~= "" and not byKey[key] then
                byKey[key] = tag
            end
        end
    end

    local tags = {}
    for _, tag in pairs(byKey) do
        tags[#tags + 1] = tag
    end
    table.sort(tags, function(first, second)
        return first:lower() < second:lower()
    end)
    return tags
end

function MetadataRepository:FindExistingTag(tag)
    local wantedKey = normalizedKey(tag)
    if wantedKey == "" then
        return nil
    end
    for _, existing in ipairs(self:GetAllTags()) do
        if normalizedKey(existing) == wantedKey then
            return existing
        end
    end
    return nil
end

function MetadataRepository:IsTagAssigned(macro, tag)
    local record = self:GetRecordForMacro(macro)
    local wantedKey = normalizedKey(tag)
    for _, existing in ipairs(record and record.tags or {}) do
        if normalizedKey(existing) == wantedKey then
            return true
        end
    end
    return false
end

local addTagWithoutCanonicalization = MetadataRepository.AddTag
function MetadataRepository:AddTag(macro, tag)
    local canonical = self:FindExistingTag(tag)
    return addTagWithoutCanonicalization(self, macro, canonical or tag)
end

function MetadataRepository:OnMacroDeleted(macro, trustedRecordId)
    local recordId = trustedRecordId
    if not recordId and type(macro) == "table" then
        recordId = self.attachedByIndex[macro.index]
    end
    if not recordId then
        return
    end

    local index = self.attachedByRecord[recordId]
    if index then
        self.attachedByIndex[index] = nil
    end
    self.attachedByRecord[recordId] = nil
    self.reconciliation[recordId] = nil
    self:GetRecords()[recordId] = nil
    MacroStudio:Debug("metadata removed with native macro", recordId)
end
