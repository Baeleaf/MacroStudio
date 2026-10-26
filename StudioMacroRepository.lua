local _, MacroStudio = ...

local Repository = { macros = {}, buttons = {} }
MacroStudio.StudioMacroRepository = Repository

local SPECIAL_KEYS = {}
for key in ("SPACE TAB ENTER BACKSPACE INSERT DELETE HOME END PAGEUP PAGEDOWN UP DOWN LEFT RIGHT "
    .. "PAUSE CAPSLOCK NUMLOCK SCROLLLOCK PRINTSCREEN NUMPADPLUS NUMPADMINUS NUMPADMULTIPLY "
    .. "NUMPADDIVIDE NUMPADDECIMAL NUMPADENTER MOUSEWHEELUP MOUSEWHEELDOWN"):gmatch("%S+") do SPECIAL_KEYS[key] = true end
local function validKey(key)
    if type(key) ~= "string" or #key > 80 then return false end
    local base = key:gsub("^ALT%-", ""):gsub("^CTRL%-", ""):gsub("^SHIFT%-", "")
    if base:match("^[A-Z0-9]$") or SPECIAL_KEYS[base] or base:match("^NUMPAD[0-9]$") then return true end
    local mouseButton = tonumber(base:match("^BUTTON(%d+)$"))
    if mouseButton and mouseButton >= 3 and mouseButton <= 31 and base == "BUTTON" .. mouseButton then return true end
    local functionKey = tonumber(base:match("^F(%d+)$"))
    if functionKey and functionKey >= 1 and functionKey <= 24 and base == "F" .. functionKey then return true end
    return #base == 1 and ("`,./;'[]\\-="):find(base, 1, true) ~= nil
end

function Repository:IsStudio(macro)
    return type(macro) == "table" and macro.source == "STUDIO"
end

function Repository:GetCharacterKey()
    local character = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    return character and character.id
end

function Repository:GetStore()
    local db = MacroStudio.db
    if type(db.studioMacros) ~= "table" then db.studioMacros = {} end
    local store = db.studioMacros
    if type(store.records) ~= "table" then store.records = {} end
    store.nextId = math.max(1, math.floor(tonumber(store.nextId) or 1))
    if store.version ~= 2 then
        -- Keep IDs, text, metadata and per-character bindings from the first
        -- development build; previously character-owned entries now join the
        -- same shared library without merging or discarding duplicate names.
        for _, record in pairs(store.records) do
            if type(record) == "table" and (record.scope == "ACCOUNT" or record.scope == "CHARACTER") then
                record.scope, record.owner = "STUDIO", nil
            end
        end
        store.version = 2
    end
    if type(db.studioBindings) ~= "table" then db.studioBindings = {} end
    return store
end

function Repository:GetBindings()
    self:GetStore()
    local key = self:GetCharacterKey()
    if not key then return {} end
    local bindings = MacroStudio.db.studioBindings
    if type(bindings[key]) ~= "table" then bindings[key] = {} end
    return bindings[key]
end

function Repository:GetById(id)
    local record = self:GetStore().records[id]
    if type(record) ~= "table" or record.id ~= id then return nil end
    if type(record.name) ~= "string" or type(record.body) ~= "string" then return nil end
    if record.scope ~= "STUDIO" then return nil end
    if not MacroStudio.MacroRepository:ValidateMacroContent(record) then return nil end
    return {
        source = "STUDIO", studioId = id, index = "studio:" .. id,
        scope = "STUDIO", revision = record.revision,
        name = record.name, icon = record.icon, selectedIcon = record.icon, body = record.body,
    }
end

function Repository:Refresh()
    local macros = {}
    for id in pairs(self:GetStore().records) do
        if type(id) == "string" and id:match("^%d+$") then
            local macro = self:GetById(id)
            if macro then macros[#macros + 1] = macro end
        end
    end
    table.sort(macros, function(a, b) return tonumber(a.studioId) < tonumber(b.studioId) end)
    self.macros = macros
    return macros
end

function Repository:GetAll() return self.macros end

function Repository:SnapshotsEqual(a, b)
    return self:IsStudio(a) and self:IsStudio(b) and a.studioId == b.studioId
        and a.scope == b.scope and a.owner == b.owner and a.revision == b.revision
        and a.name == b.name and a.body == b.body
        and MacroStudio.Helpers:IconsEqual(a.selectedIcon or a.icon, b.selectedIcon or b.icon)
end

function Repository:IsSnapshotCurrent(snapshot)
    return self:IsStudio(snapshot) and self:SnapshotsEqual(snapshot, self:GetById(snapshot.studioId))
end

function Repository:ValidateCreateRequest(request)
    if InCombatLockdown() then return false, "MacroStudio macros cannot be changed during combat." end
    return MacroStudio.MacroRepository:ValidateMacroContent(request)
end

function Repository:Create(request)
    local valid, reason, content = self:ValidateCreateRequest(request)
    if not valid then return false, nil, reason end
    local store = self:GetStore()
    local id
    repeat id = tostring(store.nextId); store.nextId = store.nextId + 1 until not store.records[id]
    content.id, content.scope, content.revision = id, "STUDIO", 1
    store.records[id] = content
    self:Refresh()
    self:RebuildBindings()
    return true, self:GetById(id)
end

function Repository:Update(snapshot, draft)
    if InCombatLockdown() then return false, nil, "MacroStudio macros cannot be changed during combat." end
    if not self:IsSnapshotCurrent(snapshot) then return false, nil, "This MacroStudio macro changed. Revert before saving." end
    local valid, reason, content = MacroStudio.MacroRepository:ValidateMacroContent(draft)
    if not valid then return false, nil, reason end
    if MacroStudio.StudioActionBarRepository then
        local synced, failure = MacroStudio.StudioActionBarRepository:Sync(snapshot, content)
        if not synced then return false, nil, failure end
    end
    local record = self:GetStore().records[snapshot.studioId]
    record.name, record.icon, record.body = content.name, content.icon, content.body
    record.revision = (tonumber(record.revision) or 0) + 1
    self:Refresh()
    self:RebuildBindings()
    return true, self:GetById(snapshot.studioId)
end

function Repository:Delete(snapshot)
    if InCombatLockdown() then return false, "MacroStudio macros cannot be deleted during combat." end
    if not self:IsSnapshotCurrent(snapshot) then return false, "This MacroStudio macro changed. Revert before deleting." end
    if MacroStudio.StudioActionBarRepository then
        local removed, reason = MacroStudio.StudioActionBarRepository:Remove(snapshot)
        if not removed then return false, reason end
    end
    self:GetStore().records[snapshot.studioId] = nil
    for _, bindings in pairs(MacroStudio.db.studioBindings) do
        if type(bindings) == "table" then bindings[snapshot.studioId] = nil end
    end
    self:Refresh()
    self:RebuildBindings()
    return true
end

function Repository:GetBinding(macro)
    local key = self:IsStudio(macro) and self:GetBindings()[macro.studioId] or nil
    return type(key) == "string" and key ~= "" and key or nil
end

function Repository:ValidateBinding(macro, key)
    if InCombatLockdown() then return false, "Bindings cannot be changed during combat." end
    if not self:IsSnapshotCurrent(macro) then return false, "This macro changed. Revert or select it again before changing its keybind." end
    if key == nil then return true end
    if not validKey(key) then
        return false, "Use a keyboard key, middle/extra mouse button, or scroll wheel. Esc cancels."
    end
    for _, other in ipairs(self:GetAll()) do
        if other.studioId ~= macro.studioId and self:GetBinding(other) == key then
            return false, "That key is already assigned to " .. other.name .. ". Clear its binding first."
        end
    end
    return true
end

function Repository:SetBinding(macro, key)
    local valid, reason = self:ValidateBinding(macro, key)
    if not valid then return false, reason end
    self:GetBindings()[macro.studioId] = key
    self:RebuildBindings()
    return true
end

-- Only secure snippets execute macro text, in response to real hardware input.
-- A state driver releases our keys in vehicles, pet battles and override bars.
local UPDATE_BINDINGS = [[
    self:ClearBindings()
    local context = self:GetAttribute("state-context")
    if context and context ~= "ready" then return end
    for i = 1, self:GetAttribute("binding-count") or 0 do
        self:SetBindingClick(true, self:GetAttribute("binding-key-" .. i),
            self:GetAttribute("binding-button-" .. i), "LeftButton")
    end
]]

function Repository:RebuildBindings()
    if InCombatLockdown() then self.pendingRebuild = true; return false end
    self.pendingRebuild = nil
    if not self.bindingOwner then
        self.bindingOwner = CreateFrame("Frame", "MacroStudioBindingOwner", UIParent, "SecureHandlerStateTemplate")
        self.bindingOwner:SetAttribute("update-bindings", UPDATE_BINDINGS)
        self.bindingOwner:SetAttribute("_onstate-context", [[self:RunAttribute("update-bindings")]])
        RegisterStateDriver(self.bindingOwner, "context", "[petbattle][vehicleui][possessbar][overridebar] blocked; ready")
    end
    for _, button in pairs(self.buttons) do button:SetAttribute("macrotext", nil) end
    local count = 0
    local usedKeys = {}
    for _, macro in ipairs(self:Refresh()) do
        local key = self:GetBinding(macro)
        if key and self:ValidateBinding(macro, key) and not usedKeys[key] then
            usedKeys[key] = true
            local button = self.buttons[macro.studioId]
            if not button then
                button = CreateFrame("Button", "MacroStudioAction" .. macro.studioId, UIParent, "SecureActionButtonTemplate")
                button:RegisterForClicks("AnyDown", "AnyUp")
                button:SetAttribute("useOnKeyDown", true)
                self.buttons[macro.studioId] = button
            end
            button:SetAttribute("type", "macro")
            button:SetAttribute("macrotext", macro.body)
            count = count + 1
            self.bindingOwner:SetAttribute("binding-key-" .. count, key)
            self.bindingOwner:SetAttribute("binding-button-" .. count, button:GetName())
        end
    end
    self.bindingOwner:SetAttribute("binding-count", count)
    self.bindingOwner:Execute([[self:RunAttribute("update-bindings")]])
    return true
end
