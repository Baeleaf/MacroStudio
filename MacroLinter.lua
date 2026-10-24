local _, MacroStudio = ...

local MacroLinter = {}
MacroStudio.MacroLinter = MacroLinter

-- Deliberately command-specific. Unknown commands and action payloads are opaque.
local commands = { ["/cast"] = true, ["/use"] = true, ["/castsequence"] = true }

local function add(diagnostics, code, severity, line, column, message)
    diagnostics[#diagnostics + 1] = {
        code = code, severity = severity, line = line, column = column, message = message,
    }
end

local function skipSpace(text, position)
    return text:find("%S", position) or (#text + 1)
end

local function checkBranch(text, first, last, command, line, diagnostics)
    local position = skipSpace(text, first)
    local malformed = false
    while position <= last do
        local character = text:sub(position, position)
        if character == "]" then
            add(diagnostics, "UNEXPECTED_CLOSE", "Error", line, position,
                "Unexpected ] before the action. Remove it or add its opening [.")
            malformed = true
            position = skipSpace(text, position + 1)
        elseif character == "[" then
            local opening = position
            position = position + 1
            while position <= last and text:sub(position, position) ~= "]" do
                if text:sub(position, position) == "[" then
                    add(diagnostics, "NESTED_CONDITIONAL", "Error", line, position,
                        "Conditional groups cannot nest. Close the first group before starting another.")
                    malformed = true
                end
                position = position + 1
            end
            if position > last then
                add(diagnostics, "UNCLOSED_CONDITIONAL", "Error", line, opening,
                    "This conditional [ has no closing ]. Add ] before the spell or item.")
                return false, true
            end
            position = skipSpace(text, position + 1)
        else
            break
        end
    end

    local action = text:sub(position, last):match("^%s*(.-)%s*$")
    -- Empty alternatives can intentionally suppress an action. Warn only if the
    -- entire command has no action, not for each empty semicolon alternative.
    if command == "/castsequence" and action:match("^reset=%S*%s*$") then
        return false, malformed
    end
    return action ~= "", malformed
end

local function checkCommand(text, first, command, line, diagnostics)
    local position, branchStart = first, first
    local hasAction, malformed = false, false
    while position <= #text + 1 do
        if text:sub(position, position + 1) == "|H" then
            -- Links may contain brackets and separators in both data and label.
            local label = text:find("|h", position + 2, true)
            local ending = label and text:find("|h", label + 2, true)
            position = ending and (ending + 2) or (#text + 1)
        elseif position > #text or text:sub(position, position) == ";" then
            local action, bad = checkBranch(text, branchStart, position - 1, command, line, diagnostics)
            hasAction = hasAction or action
            malformed = malformed or bad
            branchStart = position + 1
            position = position + 1
        else
            position = position + 1
        end
    end
    if not hasAction and not malformed then
        add(diagnostics, "MISSING_ARGUMENT", "Warning", line, first,
            command == "/castsequence"
                and "/castsequence has no spell or item sequence after its conditions/reset option. Add an action if intended."
                or (command .. " has no spell or item argument. Add an action if intended."))
    end
end

function MacroLinter:Analyze(body)
    local diagnostics = {}
    body = type(body) == "string" and body or ""
    body = body:gsub("\r\n", "\n"):gsub("\r", "\n")
    local line, tooltipLine = 0, nil
    for text in (body .. "\n"):gmatch("([^\n]*)\n") do
        line = line + 1
        local first = text:find("%S")
        if first then
            local token = text:match("^(%S+)", first):lower()
            if commands[token] then
                checkCommand(text, first + #token, token, line, diagnostics)
            elseif token == "#showtooltip" then
                if tooltipLine then
                    add(diagnostics, "DUPLICATE_SHOWTOOLTIP", "Warning", line, first,
                        "Repeated #showtooltip (first on line " .. tooltipLine
                            .. "). Keep one directive and use conditional options if needed.")
                else
                    tooltipLine = line
                end
            end
        end
    end
    table.sort(diagnostics, function(left, right)
        if left.line ~= right.line then return left.line < right.line end
        if left.column ~= right.column then return left.column < right.column end
        return left.code < right.code
    end)
    return diagnostics
end
