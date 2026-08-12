local _, MacroStudio = ...

local PortableExport = {
    FORMAT_NAME = "MacroStudioPortableLibrary",
    FORMAT_VERSION = 1,
}
MacroStudio.PortableExport = PortableExport

local JSON_ESCAPES = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t',
}

local function encodeString(value)
    value = type(value) == "string" and value or ""
    return '"' .. value:gsub('[%z\1-\31\\"]', function(character)
        return JSON_ESCAPES[character] or string.format("\\u%04x", string.byte(character))
    end) .. '"'
end

local function encodeBoolean(value)
    return value and "true" or "false"
end

local function encodeNullableString(value)
    return type(value) == "string" and encodeString(value) or "null"
end

local function encodeNullableInteger(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return "null"
    end
    return tostring(math.floor(value))
end

local function indent(level)
    return string.rep("  ", level)
end

local function addLine(lines, level, text)
    lines[#lines + 1] = indent(level) .. text
end

local function portableIcon(icon)
    if type(icon) == "number" then
        return { kind = "file", value = icon }
    end
    if type(icon) == "string" and icon ~= "" then
        return { kind = "path", value = icon }
    end
    return { kind = "file", value = MacroStudio.DEFAULT_ICON }
end

local function portableIdentity(record)
    record = type(record) == "table" and record or {}
    return {
        guid = type(record.guid) == "string" and record.guid or nil,
        name = type(record.name) == "string" and record.name or "",
        realm = type(record.realm) == "string" and record.realm or "",
        identityCertain = type(record.identityCertain) == "boolean"
            and record.identityCertain
            or (type(record.guid) == "string" and record.guid ~= ""),
    }
end

local function portableMacro(id, order, scope, macro)
    macro = type(macro) == "table" and macro or {}
    return {
        id = id,
        order = order,
        scope = scope,
        name = type(macro.name) == "string" and macro.name or "",
        icon = portableIcon(macro.selectedIcon or macro.icon),
        body = type(macro.body) == "string" and macro.body or "",
    }
end

local function normalizedTag(tag)
    return type(tag) == "string" and tag:lower() or ""
end

function PortableExport:Build()
    local data = {
        format = self.FORMAT_NAME,
        formatVersion = self.FORMAT_VERSION,
        addonVersion = MacroStudio.VERSION,
        accountMacros = {},
        currentCharacter = {
            id = "current-character",
            identity = {},
            macros = {},
        },
        offlineCharacters = {},
        organization = {
            categories = {},
            tags = {},
            associations = {},
        },
    }

    local currentSummary = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    local currentRecord = currentSummary
        and MacroStudio.CharacterMacroLibrary:GetCharacter(currentSummary.id)
        or currentSummary
    data.currentCharacter.identity = portableIdentity(currentRecord)
    local exportIdByNativeIndex = {}
    local accountOrder = 0
    local characterOrder = 0
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        if macro.scope == "ACCOUNT" then
            accountOrder = accountOrder + 1
            local exportId = string.format("account-%03d", accountOrder)
            data.accountMacros[#data.accountMacros + 1] = portableMacro(
                exportId,
                accountOrder,
                "ACCOUNT",
                macro
            )
            exportIdByNativeIndex[macro.index] = exportId
        elseif macro.scope == "CHARACTER" then
            characterOrder = characterOrder + 1
            local exportId = string.format("current-character-%03d", characterOrder)
            data.currentCharacter.macros[#data.currentCharacter.macros + 1] = portableMacro(
                exportId,
                characterOrder,
                "CHARACTER",
                macro
            )
            exportIdByNativeIndex[macro.index] = exportId
        end
    end

    local store = MacroStudio.CharacterMacroLibrary:GetStore()
    for _, characterKey in ipairs(store and store.order or {}) do
        local record = store.characters[characterKey]
        if type(record) == "table"
            and not MacroStudio.CharacterMacroLibrary:IsCurrentCharacter(characterKey) then
            local characterOrderIndex = #data.offlineCharacters + 1
            local character = {
                id = string.format("offline-character-%03d", characterOrderIndex),
                identity = portableIdentity(record),
                lastSynced = tonumber(record.lastSynced),
                macros = {},
            }
            for macroIndex, macro in ipairs(record.macros or {}) do
                character.macros[#character.macros + 1] = portableMacro(
                    string.format("offline-%03d-%03d", characterOrderIndex, macroIndex),
                    macroIndex,
                    "CHARACTER",
                    macro
                )
            end
            data.offlineCharacters[#data.offlineCharacters + 1] = character
        end
    end

    local categoryIdBySourceId = {}
    for categoryIndex, category in ipairs(MacroStudio.MetadataRepository:GetCategories()) do
        local exportId = string.format("category-%03d", categoryIndex)
        data.organization.categories[#data.organization.categories + 1] = {
            id = exportId,
            name = category.name,
        }
        categoryIdBySourceId[category.id] = exportId
    end

    local tagIdByName = {}
    for tagIndex, tag in ipairs(MacroStudio.MetadataRepository:GetAllTags()) do
        local exportId = string.format("tag-%03d", tagIndex)
        data.organization.tags[#data.organization.tags + 1] = {
            id = exportId,
            name = tag,
        }
        tagIdByName[normalizedTag(tag)] = exportId
    end

    local favoriteCount = 0
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        local macroId = exportIdByNativeIndex[macro.index]
        local presentation = macroId and MacroStudio.MetadataRepository:GetPresentation(macro) or nil
        if presentation then
            local tagIds = {}
            for _, tag in ipairs(presentation.tags or {}) do
                local tagId = tagIdByName[normalizedTag(tag)]
                if tagId then
                    tagIds[#tagIds + 1] = tagId
                end
            end
            local categoryId = categoryIdBySourceId[presentation.categoryId]
            local favorite = presentation.favorite == true
            if favorite or categoryId or #tagIds > 0 then
                data.organization.associations[#data.organization.associations + 1] = {
                    macroId = macroId,
                    favorite = favorite,
                    categoryId = categoryId,
                    tagIds = tagIds,
                }
            end
            if favorite then
                favoriteCount = favoriteCount + 1
            end
        end
    end

    local offlineMacroCount = 0
    for _, character in ipairs(data.offlineCharacters) do
        offlineMacroCount = offlineMacroCount + #character.macros
    end
    local summary = {
        accountMacros = #data.accountMacros,
        currentCharacterMacros = #data.currentCharacter.macros,
        offlineCharacters = #data.offlineCharacters,
        offlineMacros = offlineMacroCount,
        categories = #data.organization.categories,
        tags = #data.organization.tags,
        favorites = favoriteCount,
    }
    return data, summary
end

local function writeIcon(lines, level, icon)
    if icon.kind == "file" then
        addLine(lines, level, '"icon": {"kind": "file", "value": ' .. encodeNullableInteger(icon.value) .. '},')
    else
        addLine(lines, level, '"icon": {"kind": "path", "value": ' .. encodeString(icon.value) .. '},')
    end
end

local function writeMacro(lines, level, macro, isLast)
    addLine(lines, level, "{")
    addLine(lines, level + 1, '"id": ' .. encodeString(macro.id) .. ',')
    addLine(lines, level + 1, '"order": ' .. tostring(macro.order) .. ',')
    addLine(lines, level + 1, '"scope": ' .. encodeString(macro.scope) .. ',')
    addLine(lines, level + 1, '"name": ' .. encodeString(macro.name) .. ',')
    writeIcon(lines, level + 1, macro.icon)
    addLine(lines, level + 1, '"body": ' .. encodeString(macro.body))
    addLine(lines, level, "}" .. (isLast and "" or ","))
end

local function writeMacroArray(lines, level, key, macros, trailingComma)
    addLine(lines, level, encodeString(key) .. ": [")
    for index, macro in ipairs(macros) do
        writeMacro(lines, level + 1, macro, index == #macros)
    end
    addLine(lines, level, "]" .. (trailingComma and "," or ""))
end

local function writeIdentity(lines, level, identity, trailingComma)
    addLine(lines, level, '"identity": {')
    addLine(lines, level + 1, '"guid": ' .. encodeNullableString(identity.guid) .. ',')
    addLine(lines, level + 1, '"name": ' .. encodeString(identity.name) .. ',')
    addLine(lines, level + 1, '"realm": ' .. encodeString(identity.realm) .. ',')
    addLine(lines, level + 1, '"identityCertain": ' .. encodeBoolean(identity.identityCertain))
    addLine(lines, level, "}" .. (trailingComma and "," or ""))
end

local function writeCurrentCharacter(lines, level, character)
    addLine(lines, level, '"currentCharacter": {')
    addLine(lines, level + 1, '"id": ' .. encodeString(character.id) .. ',')
    writeIdentity(lines, level + 1, character.identity, true)
    writeMacroArray(lines, level + 1, "macros", character.macros, false)
    addLine(lines, level, "},")
end

local function writeOfflineCharacters(lines, level, characters)
    addLine(lines, level, '"offlineCharacters": [')
    for characterIndex, character in ipairs(characters) do
        addLine(lines, level + 1, "{")
        addLine(lines, level + 2, '"id": ' .. encodeString(character.id) .. ',')
        writeIdentity(lines, level + 2, character.identity, true)
        addLine(lines, level + 2, '"lastSynced": ' .. encodeNullableInteger(character.lastSynced) .. ',')
        writeMacroArray(lines, level + 2, "macros", character.macros, false)
        addLine(lines, level + 1, "}" .. (characterIndex == #characters and "" or ","))
    end
    addLine(lines, level, "],")
end

local function writeCategories(lines, level, categories)
    addLine(lines, level, '"categories": [')
    for index, category in ipairs(categories) do
        addLine(
            lines,
            level + 1,
            '{"id": ' .. encodeString(category.id) .. ', "name": ' .. encodeString(category.name) .. '}'
                .. (index == #categories and "" or ",")
        )
    end
    addLine(lines, level, "],")
end

local function writeTags(lines, level, tags)
    addLine(lines, level, '"tags": [')
    for index, tag in ipairs(tags) do
        addLine(
            lines,
            level + 1,
            '{"id": ' .. encodeString(tag.id) .. ', "name": ' .. encodeString(tag.name) .. '}'
                .. (index == #tags and "" or ",")
        )
    end
    addLine(lines, level, "],")
end

local function writeStringArray(lines, level, key, values, trailingComma)
    local encoded = {}
    for index, value in ipairs(values) do
        encoded[index] = encodeString(value)
    end
    addLine(
        lines,
        level,
        encodeString(key) .. ": [" .. table.concat(encoded, ", ") .. "]" .. (trailingComma and "," or "")
    )
end

local function writeAssociations(lines, level, associations)
    addLine(lines, level, '"associations": [')
    for index, association in ipairs(associations) do
        addLine(lines, level + 1, "{")
        addLine(lines, level + 2, '"macroId": ' .. encodeString(association.macroId) .. ',')
        addLine(lines, level + 2, '"favorite": ' .. encodeBoolean(association.favorite) .. ',')
        addLine(lines, level + 2, '"categoryId": ' .. encodeNullableString(association.categoryId) .. ',')
        writeStringArray(lines, level + 2, "tagIds", association.tagIds, false)
        addLine(lines, level + 1, "}" .. (index == #associations and "" or ","))
    end
    addLine(lines, level, "]")
end

local function writeOrganization(lines, level, organization)
    addLine(lines, level, '"organization": {')
    writeCategories(lines, level + 1, organization.categories)
    writeTags(lines, level + 1, organization.tags)
    writeAssociations(lines, level + 1, organization.associations)
    addLine(lines, level, "}")
end

function PortableExport:Serialize(data)
    local lines = {}
    addLine(lines, 0, "{")
    addLine(lines, 1, '"format": ' .. encodeString(data.format) .. ',')
    addLine(lines, 1, '"formatVersion": ' .. tostring(data.formatVersion) .. ',')
    addLine(lines, 1, '"addonVersion": ' .. encodeString(data.addonVersion) .. ',')
    writeMacroArray(lines, 1, "accountMacros", data.accountMacros, true)
    writeCurrentCharacter(lines, 1, data.currentCharacter)
    writeOfflineCharacters(lines, 1, data.offlineCharacters)
    writeOrganization(lines, 1, data.organization)
    addLine(lines, 0, "}")
    return table.concat(lines, "\n")
end

function PortableExport:Generate()
    local data, summary = self:Build()
    return self:Serialize(data), summary, data
end
