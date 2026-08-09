local _, MacroStudio = ...

local Search = {}
MacroStudio.Search = Search

function Search:NormalizeQuery(query)
    if type(query) ~= "string" then
        return ""
    end
    return MacroStudio.Helpers:Trim(query):lower()
end

local function contains(haystack, needle)
    return type(haystack) == "string" and haystack:lower():find(needle, 1, true) ~= nil
end

function Search:Matches(macro, query)
    local needle = self:NormalizeQuery(query)
    if needle == "" then
        return true
    end
    if type(macro) ~= "table" then
        return false
    end

    if contains(macro.name, needle) or contains(macro.body, needle) then
        return true
    end

    local presentation = MacroStudio.MetadataRepository:GetPresentation(macro)
    if presentation.categoryId and contains(presentation.categoryName, needle) then
        return true
    end
    for _, tag in ipairs(presentation.tags or {}) do
        if contains(tag, needle) then
            return true
        end
    end

    return false
end
