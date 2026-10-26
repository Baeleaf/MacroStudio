local _, MacroStudio = ...
local Repository = {}
MacroStudio.StudioActionBarRepository = Repository

function Repository:GetLinks()
    local db = MacroStudio.db
    if type(db.studioActionBarCopies) ~= "table" then db.studioActionBarCopies = {} end
    local key = MacroStudio.StudioMacroRepository:GetCharacterKey()
    if not key then return nil end
    if type(db.studioActionBarCopies[key]) ~= "table" then db.studioActionBarCopies[key] = {} end
    return db.studioActionBarCopies[key]
end

local function contentMatches(macro, content)
    return macro and content and macro.name == content.name and macro.body == content.body
        and MacroStudio.Helpers:IconsEqual(macro.selectedIcon or macro.icon, content.selectedIcon or content.icon)
end

-- Native indices can move when macros are renamed or removed. A link is only
-- reusable when exactly one native macro still matches its complete snapshot.
function Repository:FindCopy(id, refresh)
    local links = self:GetLinks()
    local snapshot = links and links[id]
    if type(snapshot) ~= "table" then return nil end
    local native = MacroStudio.MacroRepository
    if refresh then native:Refresh() end
    local found, count = nil, 0
    for _, macro in ipairs(native:GetAll()) do
        if macro.scope == snapshot.scope and contentMatches(macro, snapshot) then
            found, count = macro, count + 1
        end
    end
    if count == 1 then return found end
end

function Repository:Mutate(callback)
    if InCombatLockdown() then return false, nil, "Action-bar copies cannot be changed during combat." end
    local previousGate = MacroStudio.nativeMutationInProgress
    MacroStudio.nativeMutationInProgress = true
    local ok, success, result, reason = pcall(callback)
    if not previousGate then MacroStudio:FinishNativeMacroMutation("studio action-bar copy") end
    if not ok then return false, nil, "WoW rejected the action-bar copy: " .. tostring(success) end
    return success, result, reason
end

function Repository:UpdateCopy(studio, copy, content)
    if contentMatches(copy, content) then return true, copy end
    local ok, updated, reason = self:Mutate(function()
        return MacroStudio.MacroRepository:Update(copy, content)
    end)
    if not ok or not updated then return false, nil, reason or "The action-bar copy could not be verified." end
    self:GetLinks()[studio.studioId] = MacroStudio.Helpers:CopyMacro(updated)
    return true, updated
end

function Repository:Sync(studio, content)
    local links = self:GetLinks()
    if not links or not links[studio.studioId] then return true end
    local copy = self:FindCopy(studio.studioId, true)
    if not copy then
        return false, "The linked action-bar copy changed outside MacroStudio. Drag the saved macro again to create a fresh copy, then retry Save."
    end
    local ok, _, reason = self:UpdateCopy(studio, copy, content)
    return ok, reason
end

function Repository:Pickup(snapshot)
    local studio = MacroStudio.StudioMacroRepository
    if InCombatLockdown() then return false, nil, "Macros cannot be dragged to action bars during combat." end
    if not studio:IsSnapshotCurrent(snapshot) then return false, nil, "This macro changed before the drag started. Select it again." end
    if type(PickupMacro) ~= "function" then return false, nil, "WoW's macro pickup API is unavailable." end
    if type(GetCursorInfo) == "function" and GetCursorInfo() then
        return false, nil, "Clear the item or action on your cursor before dragging a macro."
    end
    local links = self:GetLinks()
    if not links then return false, nil, "Character identity is unavailable." end
    MacroStudio.MacroRepository:Refresh()
    local copy = self:FindCopy(snapshot.studioId)
    local replacedLink = links[snapshot.studioId] ~= nil and not copy
    local message
    if copy then
        local ok, updated, reason = self:UpdateCopy(snapshot, copy, snapshot)
        if not ok then return false, nil, reason end
        copy = updated
    else
        local native = MacroStudio.MacroRepository
        local characterCount, characterLimit = native:GetCapacity("CHARACTER")
        local accountCount, accountLimit = native:GetCapacity("ACCOUNT")
        local scope = characterCount < characterLimit and "CHARACTER" or accountCount < accountLimit and "ACCOUNT"
        if not scope then
            return false, nil, "Action-bar placement needs one free Account or Character macro slot. Your shared library and direct keybindings are still available."
        end
        local ok, created, reason = self:Mutate(function()
            return native:Create({ name = snapshot.name, icon = snapshot.selectedIcon or snapshot.icon,
                body = snapshot.body, scope = scope })
        end)
        if not ok or not created then return false, nil, reason or "The action-bar copy could not be verified." end
        copy = created
        links[snapshot.studioId] = MacroStudio.Helpers:CopyMacro(copy)
        message = "Linked action-bar copy created using one " .. (scope == "CHARACTER" and "Character" or "Account") .. " slot."
        if replacedLink then message = message .. " The externally changed copy was left untouched." end
    end
    local ok, current, reason = MacroStudio.MacroRepository:Pickup(copy)
    return ok, current, reason or message
end

function Repository:Remove(studio)
    local links = self:GetLinks()
    if not links or not links[studio.studioId] then return true end
    local copy = self:FindCopy(studio.studioId, true)
    if copy then
        local _, metadataId = MacroStudio.MetadataRepository:GetRecordForMacro(copy)
        local ok, _, reason = self:Mutate(function()
            local deleted, failure = MacroStudio.MacroRepository:Delete(copy)
            return deleted, nil, failure
        end)
        if not ok then return false, reason end
        MacroStudio.MetadataRepository:OnMacroDeleted(copy, metadataId)
    end
    -- An externally changed copy is no longer ours to edit or delete.
    links[studio.studioId] = nil
    return true
end

function Repository:GetUsage(studio)
    local copy = self:FindCopy(studio.studioId)
    if not copy then return 0, {} end
    return MacroStudio.ActionBarRepository:GetUsage(copy)
end

function Repository:ReconcileCurrentCopies()
    if InCombatLockdown() then self.pendingSync = true; return end
    self.pendingSync = nil
    local links = self:GetLinks()
    local ids = {}
    for id in pairs(links or {}) do ids[#ids + 1] = id end
    for _, id in ipairs(ids) do
        local studio = MacroStudio.StudioMacroRepository:GetById(id)
        if studio then
            local ok, reason = self:Sync(studio, studio)
            if not ok then MacroStudio:Print(studio.name .. ": " .. reason) end
        elseif MacroStudio.StudioMacroRepository:GetStore().records[id] == nil then
            self:Remove({ studioId = id })
        end
    end
end
