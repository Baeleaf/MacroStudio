local _, MacroStudio = ...

local PortableImport = {
    MAX_INPUT_BYTES = 4 * 1024 * 1024,
    MAX_DEPTH = 32,
    MAX_VALUES = 100000,
}
MacroStudio.PortableImport = PortableImport

local ARRAY_MT = {}
local OBJECT_MT = {}
local JSON_NULL = {}

local function fail(path, reason)
    error("Invalid portable import at " .. path .. ": " .. reason, 0)
end

local function codepointToUtf8(codepoint)
    if codepoint <= 0x7F then
        return string.char(codepoint)
    elseif codepoint <= 0x7FF then
        return string.char(
            0xC0 + math.floor(codepoint / 0x40),
            0x80 + (codepoint % 0x40)
        )
    elseif codepoint <= 0xFFFF then
        return string.char(
            0xE0 + math.floor(codepoint / 0x1000),
            0x80 + (math.floor(codepoint / 0x40) % 0x40),
            0x80 + (codepoint % 0x40)
        )
    end
    return string.char(
        0xF0 + math.floor(codepoint / 0x40000),
        0x80 + (math.floor(codepoint / 0x1000) % 0x40),
        0x80 + (math.floor(codepoint / 0x40) % 0x40),
        0x80 + (codepoint % 0x40)
    )
end

local function newParser(text)
    return {
        text = text,
        length = #text,
        index = 1,
        values = 0,
    }
end

local function skipWhitespace(parser)
    local index = parser.index
    while index <= parser.length do
        local byte = string.byte(parser.text, index)
        if byte ~= 0x20 and byte ~= 0x09 and byte ~= 0x0A and byte ~= 0x0D then
            break
        end
        index = index + 1
    end
    parser.index = index
end

local function parserError(parser, reason)
    fail("JSON byte " .. parser.index, reason)
end

local function parseHex(parser)
    local value = parser.text:sub(parser.index, parser.index + 3)
    if #value ~= 4 or not value:match("^[0-9a-fA-F]+$") then
        parserError(parser, "expected four hexadecimal digits after \\u")
    end
    parser.index = parser.index + 4
    return tonumber(value, 16)
end

local function parseString(parser)
    if parser.text:sub(parser.index, parser.index) ~= '"' then
        parserError(parser, "expected a JSON string")
    end
    parser.index = parser.index + 1
    local parts = {}
    local start = parser.index
    while parser.index <= parser.length do
        local byte = string.byte(parser.text, parser.index)
        if byte == 0x22 then
            if parser.index > start then
                parts[#parts + 1] = parser.text:sub(start, parser.index - 1)
            end
            parser.index = parser.index + 1
            return table.concat(parts)
        elseif byte == 0x5C then
            if parser.index > start then
                parts[#parts + 1] = parser.text:sub(start, parser.index - 1)
            end
            parser.index = parser.index + 1
            local escaped = parser.text:sub(parser.index, parser.index)
            local simple = {
                ['"'] = '"', ['\\'] = '\\', ['/'] = '/',
                b = '\b', f = '\f', n = '\n', r = '\r', t = '\t',
            }
            if simple[escaped] then
                parts[#parts + 1] = simple[escaped]
                parser.index = parser.index + 1
            elseif escaped == "u" then
                parser.index = parser.index + 1
                local codepoint = parseHex(parser)
                if codepoint >= 0xD800 and codepoint <= 0xDBFF then
                    if parser.text:sub(parser.index, parser.index + 1) ~= "\\u" then
                        parserError(parser, "high surrogate is missing its low surrogate")
                    end
                    parser.index = parser.index + 2
                    local low = parseHex(parser)
                    if low < 0xDC00 or low > 0xDFFF then
                        parserError(parser, "invalid low surrogate")
                    end
                    codepoint = 0x10000 + ((codepoint - 0xD800) * 0x400) + (low - 0xDC00)
                elseif codepoint >= 0xDC00 and codepoint <= 0xDFFF then
                    parserError(parser, "unexpected low surrogate")
                end
                parts[#parts + 1] = codepointToUtf8(codepoint)
            else
                parserError(parser, "unsupported escape sequence")
            end
            start = parser.index
        elseif byte < 0x20 then
            parserError(parser, "unescaped control character in string")
        else
            parser.index = parser.index + 1
        end
    end
    parserError(parser, "unterminated string")
end

local parseValue

local function countValue(parser)
    parser.values = parser.values + 1
    if parser.values > PortableImport.MAX_VALUES then
        parserError(parser, "input contains too many values")
    end
end

local function parseArray(parser, depth)
    parser.index = parser.index + 1
    local result = setmetatable({}, ARRAY_MT)
    skipWhitespace(parser)
    if parser.text:sub(parser.index, parser.index) == "]" then
        parser.index = parser.index + 1
        return result
    end
    while true do
        result[#result + 1] = parseValue(parser, depth + 1)
        skipWhitespace(parser)
        local character = parser.text:sub(parser.index, parser.index)
        if character == "]" then
            parser.index = parser.index + 1
            return result
        elseif character ~= "," then
            parserError(parser, "expected ',' or ']' in array")
        end
        parser.index = parser.index + 1
        skipWhitespace(parser)
    end
end

local function parseObject(parser, depth)
    parser.index = parser.index + 1
    local result = setmetatable({}, OBJECT_MT)
    skipWhitespace(parser)
    if parser.text:sub(parser.index, parser.index) == "}" then
        parser.index = parser.index + 1
        return result
    end
    while true do
        local key = parseString(parser)
        if rawget(result, key) ~= nil then
            parserError(parser, "duplicate object key '" .. key .. "'")
        end
        skipWhitespace(parser)
        if parser.text:sub(parser.index, parser.index) ~= ":" then
            parserError(parser, "expected ':' after object key")
        end
        parser.index = parser.index + 1
        result[key] = parseValue(parser, depth + 1)
        skipWhitespace(parser)
        local character = parser.text:sub(parser.index, parser.index)
        if character == "}" then
            parser.index = parser.index + 1
            return result
        elseif character ~= "," then
            parserError(parser, "expected ',' or '}' in object")
        end
        parser.index = parser.index + 1
        skipWhitespace(parser)
    end
end

local function parseNumber(parser)
    local start = parser.index
    if parser.text:sub(parser.index, parser.index) == "-" then
        parser.index = parser.index + 1
    end
    local first = parser.text:sub(parser.index, parser.index)
    if first == "0" then
        parser.index = parser.index + 1
        if parser.text:sub(parser.index, parser.index):match("%d") then
            parserError(parser, "leading zero in number")
        end
    elseif first:match("[1-9]") then
        repeat
            parser.index = parser.index + 1
        until not parser.text:sub(parser.index, parser.index):match("%d")
    else
        parserError(parser, "invalid number")
    end
    if parser.text:sub(parser.index, parser.index) == "." then
        parser.index = parser.index + 1
        if not parser.text:sub(parser.index, parser.index):match("%d") then
            parserError(parser, "fraction requires a digit")
        end
        repeat
            parser.index = parser.index + 1
        until not parser.text:sub(parser.index, parser.index):match("%d")
    end
    local exponent = parser.text:sub(parser.index, parser.index)
    if exponent == "e" or exponent == "E" then
        parser.index = parser.index + 1
        local sign = parser.text:sub(parser.index, parser.index)
        if sign == "+" or sign == "-" then
            parser.index = parser.index + 1
        end
        if not parser.text:sub(parser.index, parser.index):match("%d") then
            parserError(parser, "exponent requires a digit")
        end
        repeat
            parser.index = parser.index + 1
        until not parser.text:sub(parser.index, parser.index):match("%d")
    end
    local value = tonumber(parser.text:sub(start, parser.index - 1))
    if not value or value ~= value or value == math.huge or value == -math.huge then
        parserError(parser, "number is outside the supported range")
    end
    return value
end

parseValue = function(parser, depth)
    if depth > PortableImport.MAX_DEPTH then
        parserError(parser, "input is nested too deeply")
    end
    skipWhitespace(parser)
    countValue(parser)
    local character = parser.text:sub(parser.index, parser.index)
    if character == '"' then
        return parseString(parser)
    elseif character == "{" then
        return parseObject(parser, depth)
    elseif character == "[" then
        return parseArray(parser, depth)
    elseif character == "-" or character:match("%d") then
        return parseNumber(parser)
    elseif parser.text:sub(parser.index, parser.index + 3) == "true" then
        parser.index = parser.index + 4
        return true
    elseif parser.text:sub(parser.index, parser.index + 4) == "false" then
        parser.index = parser.index + 5
        return false
    elseif parser.text:sub(parser.index, parser.index + 3) == "null" then
        parser.index = parser.index + 4
        return JSON_NULL
    end
    parserError(parser, "unexpected token")
end

function PortableImport:ParseJSON(text)
    if type(text) ~= "string" or MacroStudio.Helpers:Trim(text) == "" then
        fail("root", "paste a MacroStudio portable export")
    end
    if #text > self.MAX_INPUT_BYTES then
        fail("root", "input exceeds the 4 MiB safety limit")
    end
    local parser = newParser(text)
    local value = parseValue(parser, 0)
    skipWhitespace(parser)
    if parser.index <= parser.length then
        parserError(parser, "unexpected content after the root value")
    end
    return value
end

local function expectObject(value, path)
    if type(value) ~= "table" or getmetatable(value) ~= OBJECT_MT then
        fail(path, "expected an object")
    end
    return value
end

local function expectArray(value, path)
    if type(value) ~= "table" or getmetatable(value) ~= ARRAY_MT then
        fail(path, "expected an array")
    end
    return value
end

local function checkKeys(value, path, keys)
    local allowed = {}
    for _, key in ipairs(keys) do
        allowed[key] = true
    end
    for key in pairs(value) do
        if not allowed[key] then
            fail(path .. "." .. tostring(key), "unsupported field")
        end
    end
end

local function required(value, key, path)
    local field = rawget(value, key)
    if field == nil then
        fail(path .. "." .. key, "missing required field")
    end
    return field
end

local function expectString(value, path, nullable)
    if value == JSON_NULL and nullable then
        return nil
    end
    if type(value) ~= "string" then
        fail(path, nullable and "expected a string or null" or "expected a string")
    end
    return value
end

local function expectInteger(value, path, nullable)
    if value == JSON_NULL and nullable then
        return nil
    end
    if type(value) ~= "number" or value ~= math.floor(value) then
        fail(path, nullable and "expected an integer or null" or "expected an integer")
    end
    return value
end

local function expectBoolean(value, path)
    if type(value) ~= "boolean" then
        fail(path, "expected a boolean")
    end
    return value
end

local function importIcon(value, path)
    value = expectObject(value, path)
    checkKeys(value, path, { "kind", "value" })
    local kind = expectString(required(value, "kind", path), path .. ".kind")
    local iconValue = required(value, "value", path)
    if kind == "file" then
        iconValue = expectInteger(iconValue, path .. ".value")
        if iconValue <= 0 then
            fail(path .. ".value", "file ID must be positive")
        end
    elseif kind == "path" then
        iconValue = expectString(iconValue, path .. ".value")
        if iconValue == "" then
            fail(path .. ".value", "icon path must not be empty")
        end
    else
        fail(path .. ".kind", "expected 'file' or 'path'")
    end
    return { kind = kind, value = iconValue }
end

local function importMacro(value, path, expectedScope)
    value = expectObject(value, path)
    checkKeys(value, path, { "id", "order", "scope", "name", "icon", "body" })
    local macro = {
        id = expectString(required(value, "id", path), path .. ".id"),
        order = expectInteger(required(value, "order", path), path .. ".order"),
        scope = expectString(required(value, "scope", path), path .. ".scope"),
        name = expectString(required(value, "name", path), path .. ".name"),
        icon = importIcon(required(value, "icon", path), path .. ".icon"),
        body = expectString(required(value, "body", path), path .. ".body"),
    }
    if macro.scope ~= expectedScope then
        fail(path .. ".scope", "expected " .. expectedScope)
    end
    local valid, reason, normalized = MacroStudio.MacroRepository:ValidateMacroContent({
        name = macro.name,
        icon = macro.icon.value,
        body = macro.body,
    })
    if not valid then
        fail(path, reason)
    end
    if normalized.name ~= macro.name then
        fail(path .. ".name", "cannot be recreated exactly by the native macro API")
    end
    return macro
end

local function importMacroArray(value, path, expectedScope, maximum)
    value = expectArray(value, path)
    if #value > maximum then
        fail(path, "contains more records than the safety limit")
    end
    local result = {}
    for index, macro in ipairs(value) do
        result[index] = importMacro(macro, path .. "[" .. index .. "]", expectedScope)
    end
    return result
end

local function importIdentity(value, path)
    value = expectObject(value, path)
    checkKeys(value, path, { "guid", "name", "realm", "identityCertain" })
    local guid = expectString(required(value, "guid", path), path .. ".guid", true)
    if guid == "" then fail(path .. ".guid", "GUID must be a nonempty string or null") end
    local identityCertain = expectBoolean(required(value, "identityCertain", path), path .. ".identityCertain")
    if identityCertain ~= (guid ~= nil) then
        fail(path .. ".identityCertain", "must reflect whether a GUID is present")
    end
    return {
        guid = guid,
        name = expectString(required(value, "name", path), path .. ".name"),
        realm = expectString(required(value, "realm", path), path .. ".realm"),
        identityCertain = identityCertain,
    }
end

local function normalizedName(value)
    return MacroStudio.Helpers:Trim(value):lower()
end

function PortableImport:BuildModel(raw)
    raw = expectObject(raw, "root")
    checkKeys(raw, "root", {
        "format", "formatVersion", "addonVersion", "accountMacros",
        "currentCharacter", "offlineCharacters", "organization",
    })
    local format = expectString(required(raw, "format", "root"), "format")
    local version = expectInteger(required(raw, "formatVersion", "root"), "formatVersion")
    if format ~= MacroStudio.PortableExport.FORMAT_NAME then
        fail("format", "this is not a MacroStudio portable library")
    end
    if version ~= MacroStudio.PortableExport.FORMAT_VERSION then
        error(string.format(
            "This export uses portable format version %s. This version of MacroStudio supports format version %d.",
            tostring(version),
            MacroStudio.PortableExport.FORMAT_VERSION
        ), 0)
    end

    local model = {
        format = format,
        formatVersion = version,
        addonVersion = expectString(required(raw, "addonVersion", "root"), "addonVersion"),
        accountMacros = importMacroArray(required(raw, "accountMacros", "root"), "accountMacros", "ACCOUNT", 1000),
        offlineCharacters = {},
        organization = { categories = {}, tags = {}, associations = {} },
    }
    if MacroStudio.Helpers:Trim(model.addonVersion) == "" then fail("addonVersion", "must not be empty") end

    local current = expectObject(required(raw, "currentCharacter", "root"), "currentCharacter")
    checkKeys(current, "currentCharacter", { "id", "identity", "macros" })
    model.currentCharacter = {
        id = expectString(required(current, "id", "currentCharacter"), "currentCharacter.id"),
        identity = importIdentity(required(current, "identity", "currentCharacter"), "currentCharacter.identity"),
        macros = importMacroArray(required(current, "macros", "currentCharacter"), "currentCharacter.macros", "CHARACTER", 1000),
    }
    if model.currentCharacter.id == "" then fail("currentCharacter.id", "must not be empty") end
    local characterIds = { [model.currentCharacter.id] = true }

    local offline = expectArray(required(raw, "offlineCharacters", "root"), "offlineCharacters")
    if #offline > 1000 then
        fail("offlineCharacters", "contains more records than the safety limit")
    end
    for index, source in ipairs(offline) do
        local path = "offlineCharacters[" .. index .. "]"
        source = expectObject(source, path)
        checkKeys(source, path, { "id", "identity", "lastSynced", "macros" })
        model.offlineCharacters[index] = {
            id = expectString(required(source, "id", path), path .. ".id"),
            identity = importIdentity(required(source, "identity", path), path .. ".identity"),
            lastSynced = expectInteger(required(source, "lastSynced", path), path .. ".lastSynced", true),
            macros = importMacroArray(required(source, "macros", path), path .. ".macros", "CHARACTER", 1000),
        }
        if model.offlineCharacters[index].lastSynced and model.offlineCharacters[index].lastSynced < 0 then
            fail(path .. ".lastSynced", "must not be negative")
        end
        local characterId = model.offlineCharacters[index].id
        if characterIds[characterId] then fail(path .. ".id", "duplicates another character record ID") end
        characterIds[characterId] = true

    end

    local organization = expectObject(required(raw, "organization", "root"), "organization")
    checkKeys(organization, "organization", { "categories", "tags", "associations" })
    local categories = expectArray(required(organization, "categories", "organization"), "organization.categories")
    if #categories > 1000 then fail("organization.categories", "contains more records than the safety limit") end
    local categoryNames = {}
    for index, source in ipairs(categories) do
        local path = "organization.categories[" .. index .. "]"
        source = expectObject(source, path)
        checkKeys(source, path, { "id", "name" })
        local category = {
            id = expectString(required(source, "id", path), path .. ".id"),
            name = expectString(required(source, "name", path), path .. ".name"),
        }
        local cleaned = MacroStudio.Helpers:Trim(category.name)
        if cleaned == "" then fail(path .. ".name", "category name must not be empty") end
        if cleaned ~= category.name then fail(path .. ".name", "category name must not have surrounding whitespace") end
        if MacroStudio.Helpers:TextLength(category.name) > 40 then fail(path .. ".name", "category exceeds 40 characters") end
        if category.name:find("[%c]") then fail(path .. ".name", "category contains a control character") end
        local key = normalizedName(category.name)
        if categoryNames[key] then
            fail(path .. ".name", "duplicates another category name")
        end
        categoryNames[key] = true
        model.organization.categories[index] = category
    end

    local tags = expectArray(required(organization, "tags", "organization"), "organization.tags")
    if #tags > 5000 then fail("organization.tags", "contains more records than the safety limit") end
    local tagNames = {}
    for index, source in ipairs(tags) do
        local path = "organization.tags[" .. index .. "]"
        source = expectObject(source, path)
        checkKeys(source, path, { "id", "name" })
        local tag = {
            id = expectString(required(source, "id", path), path .. ".id"),
            name = expectString(required(source, "name", path), path .. ".name"),
        }
        local cleanedTag = MacroStudio.Helpers:Trim(tag.name):gsub("[%c]", ""):gsub("%s+", " ")
        if cleanedTag ~= tag.name then
            fail(path .. ".name", "tag cannot be recreated exactly by MacroStudio")
        end
        if normalizedName(tag.name) == "" then
            fail(path .. ".name", "tag name must not be empty")
        end
        if MacroStudio.Helpers:TextLength(tag.name) > 30 then
            fail(path .. ".name", "tag exceeds 30 characters")
        end
        local key = normalizedName(tag.name)
        if tagNames[key] then
            fail(path .. ".name", "duplicates another tag name")
        end
        tagNames[key] = true
        model.organization.tags[index] = tag
    end

    local associations = expectArray(required(organization, "associations", "organization"), "organization.associations")
    if #associations > 5000 then fail("organization.associations", "contains more records than the safety limit") end
    for index, source in ipairs(associations) do
        local path = "organization.associations[" .. index .. "]"
        source = expectObject(source, path)
        checkKeys(source, path, { "macroId", "favorite", "categoryId", "tagIds" })
        local association = {
            macroId = expectString(required(source, "macroId", path), path .. ".macroId"),
            favorite = expectBoolean(required(source, "favorite", path), path .. ".favorite"),
            categoryId = expectString(required(source, "categoryId", path), path .. ".categoryId", true),
            tagIds = {},
        }
        local tagIds = expectArray(required(source, "tagIds", path), path .. ".tagIds")
        if #tagIds > 1000 then fail(path .. ".tagIds", "contains more records than the safety limit") end
        local seenTagIds = {}
        for tagIndex, value in ipairs(tagIds) do
            local tagId = expectString(value, path .. ".tagIds[" .. tagIndex .. "]")
            if seenTagIds[tagId] then fail(path .. ".tagIds[" .. tagIndex .. "]", "duplicates another tag reference") end
            seenTagIds[tagId] = true
            association.tagIds[tagIndex] = tagId
        end
        model.organization.associations[index] = association
    end

    MacroStudio.PortableExport:Validate(model)
    local identityGuids = {}
    local function rememberIdentity(identity, path)
        if identity.guid then
            local key = identity.guid:lower()
            if identityGuids[key] then fail(path .. ".guid", "duplicates another character GUID") end
            identityGuids[key] = true
        end
    end
    rememberIdentity(model.currentCharacter.identity, "currentCharacter.identity")
    for index, character in ipairs(model.offlineCharacters) do
        rememberIdentity(character.identity, "offlineCharacters[" .. index .. "].identity")
    end
    local nativeIds = {}
    for _, macro in ipairs(model.accountMacros) do nativeIds[macro.id] = true end
    for _, macro in ipairs(model.currentCharacter.macros) do nativeIds[macro.id] = true end
    for index, association in ipairs(model.organization.associations) do
        if not nativeIds[association.macroId] then
            fail("organization.associations[" .. index .. "].macroId", "must reference an Account or source-current macro")
        end
    end
    return model
end

function PortableImport:ParseAndValidate(text)
    local raw = self:ParseJSON(text)
    return self:BuildModel(raw)
end

local function iconValue(portableIcon)
    return portableIcon and portableIcon.value or MacroStudio.DEFAULT_ICON
end

local function identityKey(macro)
    local name = macro.name or ""
    local body = macro.body or ""
    local icon = MacroStudio.Helpers:GetIconIdentity(iconValue(macro.icon) or macro.selectedIcon or macro.icon) or ""
    return #name .. ":" .. name .. #body .. ":" .. body .. #icon .. ":" .. icon
end

local function nativeIdentityKey(macro)
    return identityKey({
        name = macro.name,
        body = macro.body,
        icon = { value = macro.selectedIcon or macro.icon },
    })
end

local function copyPortableSnapshot(source)
    local macros = {}
    for index, macro in ipairs(source.macros or {}) do
        macros[index] = {
            order = index,
            name = macro.name,
            icon = iconValue(macro.icon),
            body = macro.body,
        }
    end
    return {
        sourceId = source.id,
        guid = source.identity.guid,
        name = source.identity.name,
        realm = source.identity.realm,
        identityCertain = source.identity.identityCertain,
        lastSynced = source.lastSynced,
        macros = macros,
    }
end

local function snapshotsEqual(first, second)
    if type(first) ~= "table" or type(second) ~= "table" or #(first.macros or {}) ~= #(second.macros or {}) then
        return false
    end
    if (first.name or "") ~= (second.name or "") or (first.realm or "") ~= (second.realm or "") then
        return false
    end
    for index, macro in ipairs(first.macros or {}) do
        local other = second.macros[index]
        if not other or macro.name ~= other.name or macro.body ~= other.body
            or not MacroStudio.Helpers:IconsEqual(macro.icon, other.icon) then
            return false
        end
    end
    return true
end

local function findLocalCharacter(source)
    local store = MacroStudio.CharacterMacroLibrary:GetStore()
    local guidMatches = {}
    local exactMatches = {}
    for _, characterId in ipairs(store and store.order or {}) do
        local record = store.characters[characterId]
        if type(record) == "table" then
            if source.guid and record.guid == source.guid then
                guidMatches[#guidMatches + 1] = record
            elseif not source.guid and not record.guid and snapshotsEqual(source, record) then
                exactMatches[#exactMatches + 1] = record
            end
        end
    end
    if source.guid then
        return #guidMatches == 1 and guidMatches[1] or nil, #guidMatches
    end
    return #exactMatches == 1 and exactMatches[1] or nil, #exactMatches
end

function PortableImport:BuildOfflinePlan(model)
    local sources = {}
    local current = copyPortableSnapshot({
        id = "source-current-character",
        identity = model.currentCharacter.identity,
        macros = model.currentCharacter.macros,
        lastSynced = nil,
    })
    sources[#sources + 1] = current
    for _, source in ipairs(model.offlineCharacters) do
        sources[#sources + 1] = copyPortableSnapshot(source)
    end

    local destination = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    local plan = { items = {}, added = 0, updated = 0, kept = 0, skippedCurrent = 0, warnings = {} }
    for _, source in ipairs(sources) do
        local item = { source = source }
        if source.guid and destination and source.guid == destination.guid then
            item.action = "skip_current"
            plan.skippedCurrent = plan.skippedCurrent + 1
        else
            local localRecord, matchCount = findLocalCharacter(source)
            if matchCount > 1 then
                item.action = "keep"
                plan.kept = plan.kept + 1
                plan.warnings[#plan.warnings + 1] = "An offline character identity is ambiguous locally and will be preserved without changes."
            elseif not localRecord then
                item.action = "add"
                plan.added = plan.added + 1
            elseif snapshotsEqual(source, localRecord) then
                item.action = "keep"
                item.targetId = localRecord.id
                plan.kept = plan.kept + 1
            else
                local sourceTime = tonumber(source.lastSynced)
                local localTime = tonumber(localRecord.lastSynced)
                if source.guid and sourceTime and localTime and sourceTime > localTime then
                    item.action = "update"
                    item.targetId = localRecord.id
                    plan.updated = plan.updated + 1
                else
                    item.action = "keep"
                    item.targetId = localRecord.id
                    plan.kept = plan.kept + 1
                    plan.warnings[#plan.warnings + 1] = "A local offline snapshot was newer or could not be compared, so it will be preserved."
                end
            end
        end
        plan.items[#plan.items + 1] = item
    end
    return plan
end

local function buildNativePlanForScope(sourceMacros, scope, importEnabled)
    local result = { items = {}, create = 0, present = 0, ambiguous = 0, disabled = 0 }
    local sourceCounts = {}
    local destinationGroups = {}
    for _, source in ipairs(sourceMacros) do
        local key = identityKey(source)
        sourceCounts[key] = (sourceCounts[key] or 0) + 1
    end
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        if macro.scope == scope then
            local key = nativeIdentityKey(macro)
            destinationGroups[key] = destinationGroups[key] or {}
            destinationGroups[key][#destinationGroups[key] + 1] = macro
        end
    end
    for _, source in ipairs(sourceMacros) do
        local key = identityKey(source)
        local matches = destinationGroups[key] or {}
        local item = {
            source = source,
            request = { name = source.name, body = source.body, icon = iconValue(source.icon), scope = scope },
        }
        if not importEnabled then
            item.action = "disabled"
            result.disabled = result.disabled + 1
        elseif #matches == 0 then
            item.action = "create"
            result.create = result.create + 1
        elseif #matches == 1 and sourceCounts[key] == 1 then
            item.action = "reuse"
            item.target = matches[1]
            result.present = result.present + 1
        else
            item.action = "ambiguous"
            result.ambiguous = result.ambiguous + 1
        end
        result.items[#result.items + 1] = item
    end
    return result
end

local function currentDestinationText()
    local current = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    if not current then
        return "Current Character"
    end
    return (current.name or "Unknown Character") .. " - " .. (current.realm or "Unknown Realm")
end

function PortableImport:BuildPlan(model, options)
    options = options or {}
    local importCharacterMacros = options.importCharacterMacros ~= false
    local account = buildNativePlanForScope(model.accountMacros, "ACCOUNT", true)
    local character = buildNativePlanForScope(model.currentCharacter.macros, "CHARACTER", importCharacterMacros)
    local accountCount, accountCapacity = MacroStudio.MacroRepository:GetCapacity("ACCOUNT")
    local characterCount, characterCapacity = MacroStudio.MacroRepository:GetCapacity("CHARACTER")
    local plan = {
        model = model,
        options = { importCharacterMacros = importCharacterMacros },
        account = account,
        character = character,
        accountAvailable = math.max(0, accountCapacity - accountCount),
        characterAvailable = math.max(0, characterCapacity - characterCount),
        currentCharacter = currentDestinationText(),
        offline = self:BuildOfflinePlan(model),
        warnings = {},
    }
    plan.capacityOK = account.create <= plan.accountAvailable and character.create <= plan.characterAvailable
    if account.create > plan.accountAvailable then
        plan.warnings[#plan.warnings + 1] = string.format(
            "Import needs %d Account macro slots, but only %d are available.",
            account.create, plan.accountAvailable
        )
    end
    if character.create > plan.characterAvailable then
        plan.warnings[#plan.warnings + 1] = string.format(
            "Import needs %d Character macro slots, but only %d are available.",
            character.create, plan.characterAvailable
        )
    end
    if account.ambiguous + character.ambiguous > 0 then
        plan.warnings[#plan.warnings + 1] = "Indistinguishable duplicate exact matches are ambiguous and will be skipped rather than guessed."
    end

    local localCategories = {}
    for _, category in ipairs(MacroStudio.MetadataRepository:GetCategories()) do
        localCategories[normalizedName(category.name)] = category
    end
    local categoryById = {}
    plan.categoriesAdded = 0
    for _, category in ipairs(model.organization.categories) do
        categoryById[category.id] = category
        if not localCategories[normalizedName(category.name)] then
            plan.categoriesAdded = plan.categoriesAdded + 1
        end
    end
    local localTags = {}
    for _, tag in ipairs(MacroStudio.MetadataRepository:GetAllTags()) do
        localTags[normalizedName(tag)] = tag
    end
    local tagById = {}
    for _, tag in ipairs(model.organization.tags) do tagById[tag.id] = tag end
    local itemById = {}
    for _, item in ipairs(account.items) do itemById[item.source.id] = item end
    for _, item in ipairs(character.items) do itemById[item.source.id] = item end
    plan.associations = {}
    plan.tagsAdded = 0
    plan.favoritesRestored = 0
    plan.categoryConflicts = 0
    local newTagNames = {}
    for _, association in ipairs(model.organization.associations) do
        local item = itemById[association.macroId]
        if item and (item.action == "create" or item.action == "reuse") then
            local associationPlan = { source = association, item = item, category = categoryById[association.categoryId], tags = {} }
            if association.favorite then plan.favoritesRestored = plan.favoritesRestored + 1 end
            for _, tagId in ipairs(association.tagIds) do
                local tag = tagById[tagId]
                associationPlan.tags[#associationPlan.tags + 1] = tag
                local key = normalizedName(tag.name)
                if not localTags[key] and not newTagNames[key] then
                    newTagNames[key] = true
                    plan.tagsAdded = plan.tagsAdded + 1
                end
            end
            if item.action == "reuse" and associationPlan.category then
                local presentation = MacroStudio.MetadataRepository:GetPresentation(item.target)
                if presentation.categoryId then
                    local existing = MacroStudio.MetadataRepository:GetCategory(presentation.categoryId)
                    if existing and normalizedName(existing.name) ~= normalizedName(associationPlan.category.name) then
                        associationPlan.categoryConflict = true
                        plan.categoryConflicts = plan.categoryConflicts + 1
                    end
                end
            end
            plan.associations[#plan.associations + 1] = associationPlan
        end
    end
    if plan.categoryConflicts > 0 then
        plan.warnings[#plan.warnings + 1] = "Existing destination categories win when an exact macro already belongs to a different category."
    end
    for _, warning in ipairs(plan.offline.warnings) do plan.warnings[#plan.warnings + 1] = warning end
    local stateText = MacroStudio.PortableExport:Generate()
    plan.stateSignature = stateText
    return plan
end

function PortableImport:Preview(text, options)
    local model = self:ParseAndValidate(text)
    return self:BuildPlan(model, options)
end

local function findCategoryByName(name)
    local key = normalizedName(name)
    for _, category in ipairs(MacroStudio.MetadataRepository:GetCategories()) do
        if normalizedName(category.name) == key then return category end
    end
end

local function finishMutationBatch()
    MacroStudio.nativeMutationInProgress = false
    MacroStudio.pendingMacroRefresh = nil
    MacroStudio.pendingMacroRefreshReason = nil
end

local function finalMappedMacros(plan)
    local sourceCounts = {}
    local destinationGroups = {}
    local function groupKey(scope, macro, portable)
        return scope .. ":" .. (portable and identityKey(macro) or nativeIdentityKey(macro))
    end
    local function countSources(scopePlan, scope)
        for _, item in ipairs(scopePlan.items) do
            if item.action == "create" or item.action == "reuse" then
                local key = groupKey(scope, item.source, true)
                sourceCounts[key] = (sourceCounts[key] or 0) + 1
            end
        end
    end
    countSources(plan.account, "ACCOUNT")
    countSources(plan.character, "CHARACTER")
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        local key = groupKey(macro.scope, macro, false)
        destinationGroups[key] = destinationGroups[key] or {}
        destinationGroups[key][#destinationGroups[key] + 1] = macro
    end
    local mapped, unresolved = {}, 0
    local function mapScope(scopePlan, scope)
        for _, item in ipairs(scopePlan.items) do
            if item.action == "create" or item.action == "reuse" then
                local key = groupKey(scope, item.source, true)
                local matches = destinationGroups[key] or {}
                if sourceCounts[key] == 1 and #matches == 1 then
                    mapped[item.source.id] = matches[1]
                else
                    unresolved = unresolved + 1
                end
            end
        end
    end
    mapScope(plan.account, "ACCOUNT")
    mapScope(plan.character, "CHARACTER")
    return mapped, unresolved
end

local function applyMetadata(plan, mapped, result)
    local categoryMap = {}
    for _, source in ipairs(plan.model.organization.categories) do
        local category = findCategoryByName(source.name)
        if not category then
            category = MacroStudio.MetadataRepository:CreateCategory(source.name)
            if category then result.categoriesAdded = result.categoriesAdded + 1 end
        end
        categoryMap[source.id] = category
    end
    local knownTags = {}
    for _, tag in ipairs(MacroStudio.MetadataRepository:GetAllTags()) do
        knownTags[normalizedName(tag)] = true
    end
    for _, association in ipairs(plan.associations) do
        local target = mapped[association.source.macroId]
        if target then
            local presentation = MacroStudio.MetadataRepository:GetPresentation(target)
            if association.source.favorite and not presentation.favorite then
                MacroStudio.MetadataRepository:ToggleFavorite(target)
                result.favoritesRestored = result.favoritesRestored + 1
            end
            if association.category and not presentation.categoryId then
                local category = categoryMap[association.category.id]
                if category then MacroStudio.MetadataRepository:SetCategory(target, category.id) end
            elseif association.categoryConflict then
                result.metadataConflicts = result.metadataConflicts + 1
            end
            for _, tag in ipairs(association.tags) do
                if not MacroStudio.MetadataRepository:IsTagAssigned(target, tag.name) then
                    local ok = MacroStudio.MetadataRepository:AddTag(target, tag.name)
                    if ok and not knownTags[normalizedName(tag.name)] then
                        knownTags[normalizedName(tag.name)] = true
                        result.tagsAdded = result.tagsAdded + 1
                    end
                end
            end
        end
    end
end

function PortableImport:Apply(plan)
    if type(plan) ~= "table" or plan ~= self.activePlan then
        return false, nil, "Validate and Preview this import again before applying it."
    end
    if MacroStudio.Editor and MacroStudio.Editor:IsDirty() then
        return false, nil, "Finish or Revert your current macro draft before importing native macros."
    end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false, nil, "Apply Import is unavailable during Combat Lockdown. Leave combat and confirm again."
    end

    MacroStudio.MacroRepository:Refresh()
    MacroStudio.MetadataRepository:Reconcile(MacroStudio.MacroRepository:GetAll())
    local refreshed = self:BuildPlan(plan.model, plan.options)
    if refreshed.stateSignature ~= plan.stateSignature then
        return false, nil, "Native macros or MacroStudio library data changed after Preview. Run Validate & Preview again."
    end
    if not refreshed.capacityOK then
        return false, nil, table.concat(refreshed.warnings, " ")
    end
    plan = refreshed
    self.activePlan = plan

    local result = {
        accountCreated = 0, accountPresent = plan.account.present,
        characterCreated = 0, characterPresent = plan.character.present,
        ambiguousSkipped = plan.account.ambiguous + plan.character.ambiguous,
        categoriesAdded = 0, tagsAdded = 0, favoritesRestored = 0,
        metadataConflicts = 0, metadataSkipped = 0, offlineAdded = 0, offlineUpdated = 0, offlineKept = plan.offline.kept,
        partial = false, message = nil,
    }
    local mapped = {}
    for _, item in ipairs(plan.account.items) do
        if item.action == "reuse" then mapped[item.source.id] = item.target end
    end
    for _, item in ipairs(plan.character.items) do
        if item.action == "reuse" then mapped[item.source.id] = item.target end
    end

    MacroStudio.nativeMutationInProgress = true
    local function createItems(items, counter)
        for _, item in ipairs(items) do
            if item.action == "create" then
                local created, macro, message = MacroStudio.MacroRepository:Create(item.request)
                if not created or not macro then
                    return false, message or "WoW could not confirm an imported macro's exact identity."
                end
                mapped[item.source.id] = macro
                result[counter] = result[counter] + 1
            end
        end
        return true
    end
    local batchOK, created, failure = xpcall(function()
        local completed, message = createItems(plan.account.items, "accountCreated")
        if completed then completed, message = createItems(plan.character.items, "characterCreated") end
        return completed, message
    end, function(value) return tostring(value) end)
    finishMutationBatch()
    if not batchOK then
        failure = created
        created = false
    end

    if not created then
        result.partial = true
        result.message = string.format(
            "Import stopped after confirming %d of %d planned native macros. No existing macros were modified or deleted. %s Re-run Preview before retrying.",
            result.accountCreated + result.characterCreated,
            plan.account.create + plan.character.create,
            failure or ""
        )
        MacroStudio.MacroRepository:Refresh()
        MacroStudio.MetadataRepository:Reconcile(MacroStudio.MacroRepository:GetAll())
        MacroStudio.CharacterMacroLibrary:RefreshCurrentSnapshot(MacroStudio.MacroRepository:GetAll())
        if MacroStudio.ActionBarRepository then MacroStudio.ActionBarRepository:Refresh() end
        MacroStudio:RefreshOrganizationUI()
        self.activePlan = nil
        return false, result, result.message
    end

    MacroStudio.MacroRepository:Refresh()
    MacroStudio.MetadataRepository:Reconcile(MacroStudio.MacroRepository:GetAll())
    mapped, result.metadataSkipped = finalMappedMacros(plan)
    local mergeOK, mergeFailure = xpcall(function()
        applyMetadata(plan, mapped, result)
        for _, item in ipairs(plan.offline.items) do
            if item.action == "add" or item.action == "update" then
                local ok = MacroStudio.CharacterMacroLibrary:ApplyPortableSnapshot(item)
                if ok then
                    if item.action == "add" then result.offlineAdded = result.offlineAdded + 1
                    else result.offlineUpdated = result.offlineUpdated + 1 end
                end
            end
        end
    end, function(value) return tostring(value) end)
    if not mergeOK then
        result.partial = true
        result.message = "Native macros were confirmed, but the MacroStudio library merge stopped safely: "
            .. mergeFailure .. " No existing macros were modified or deleted. Re-run Preview before retrying."
        MacroStudio.MacroRepository:Refresh()
        MacroStudio.MetadataRepository:Reconcile(MacroStudio.MacroRepository:GetAll())
        MacroStudio.CharacterMacroLibrary:RefreshCurrentSnapshot(MacroStudio.MacroRepository:GetAll())
        if MacroStudio.ActionBarRepository then MacroStudio.ActionBarRepository:Refresh() end
        MacroStudio:RefreshOrganizationUI()
        self.activePlan = nil
        return false, result, result.message
    end
    MacroStudio.CharacterMacroLibrary:RefreshCurrentSnapshot(MacroStudio.MacroRepository:GetAll())
    MacroStudio.MetadataRepository:Reconcile(MacroStudio.MacroRepository:GetAll())
    if MacroStudio.ActionBarRepository then MacroStudio.ActionBarRepository:Refresh() end
    MacroStudio:RefreshOrganizationUI()
    self.activePlan = nil
    return true, result
end

function PortableImport:SetActivePlan(plan)
    self.activePlan = plan
end
