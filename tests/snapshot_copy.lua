local _, ms = ...
local editor, library = ms.Editor, ms.CharacterMacroLibrary
combat, deferTimers = false, false
ms:SetMainWindowModalBlocked(false)
ms:SetSearchQuery("")

local accounts = {{ name="Native Account", icon=101, body="/say account" }}
local characters = {{ name="Native Character", icon=102, body="/say character" }}
local writes = 0
local function lookup(index)
    local group, offset = index <= 3 and accounts or characters, index <= 3 and index or index - 3
    return group[offset]
end
GetNumMacros = function() return #accounts, #characters end
GetMacroInfo = function(index)
    local macro = lookup(index)
    if macro then return macro.name, macro.icon, macro.body end
end
C_Macro.GetSelectedMacroIcon = function(index) local m = lookup(index); return m and m.icon end
CreateMacro = function(name, icon, body, character)
    local group, limit = character and characters or accounts, character and 2 or 3
    assert(#group < limit, "copy must validate destination capacity before native writes")
    group[#group + 1] = { name=name, icon=icon, body=body }
    writes = writes + 1
    ms:OnMacrosChanged("UPDATE_MACROS")
    return (character and 3 or 0) + #group
end
EditMacro = function() error("copy must never edit an existing native macro") end
DeleteMacro = function() error("copy must never delete a native macro") end
actionSlots = {}
ms.MacroRepository:Refresh()

local store = library:GetStore()
local id = "guid:Player-1-COPY-SOURCE"
local source = { order=1, name="Snapshot Copy", icon=135846, body="/say copied snapshot" }
local other = { order=2, name="Other Snapshot", icon=134400, body="/say other snapshot" }
store.characters[id] = { id=id, name="Source", realm="Test Realm", displayName="Source - Test Realm",
    normalizedDisplay="source - test realm", lastSynced=100, macros={source, other} }
store.order[#store.order+1] = id
local function snapshot(macro)
    return { source="SNAPSHOT", scope="CHARACTER", characterKey=id, snapshotOrder=macro.order,
        name=macro.name, icon=macro.icon, body=macro.body, characterDisplayName="Source - Test Realm" }
end
local original = snapshot(source)
local function openCopy()
    ms:SelectMacro(original)
    editor.copyButton:TriggerScript("OnClick")
    assert(editor.copyMenu:IsShown() and #editor.copyMenuRows == 3)
end

-- Real menu interactions must copy exact content into each repository/scope.
openCopy()
assert(editor.copyButton:GetText() == "Copy to..." and editor.copyMenuRows[1].Text:GetText() == "Current Character"
    and editor.copyMenuRows[2].Text:GetText() == "Account Macros"
    and editor.copyMenuRows[3].Text:GetText() == "MacroStudio Macros")
local hovered = editor.copyButton
MouseIsOver = function(frame) return frame == hovered end
editor.copyMenu:TriggerScript("OnEvent", "GLOBAL_MOUSE_DOWN")
assert(editor.copyMenu:IsShown(), "pressing the dropdown itself must allow normal toggle behavior")
hovered = editor.copyMenu
editor.copyMenu:TriggerScript("OnEvent", "GLOBAL_MOUSE_DOWN")
assert(editor.copyMenu:IsShown())
hovered = nil
editor.copyMenu:TriggerScript("OnEvent", "GLOBAL_MOUSE_DOWN")
assert(not editor.copyMenu:IsShown(), "an outside click must dismiss the dropdown")
editor.copyButton:TriggerScript("OnClick")
editor.copyMenuRows[1]:TriggerScript("OnClick")
assert(writes == 1 and #characters == 2 and ms.selectedMacro.scope == "CHARACTER"
    and ms.activeFilter.kind == "character" and not editor.copyMenu:IsShown())
assert(characters[2].name == source.name and characters[2].icon == source.icon and characters[2].body == source.body)
openCopy()
assert(not editor.copyMenuRows[1]:IsEnabled() and editor.copyMenuRows[2]:IsEnabled())
editor.copyMenuRows[2]:TriggerScript("OnClick")
assert(writes == 2 and #accounts == 2 and ms.selectedMacro.scope == "ACCOUNT" and ms.activeFilter.kind == "account")
assert(accounts[2].name == source.name and accounts[2].icon == source.icon and accounts[2].body == source.body)
openCopy()
editor.copyMenuRows[3]:TriggerScript("OnClick")
local managed = ms.selectedMacro
assert(managed.source == "STUDIO" and ms.activeFilter.kind == "studio" and writes == 2
    and managed.name == source.name and managed.icon == source.icon and managed.body == source.body)
assert(not ms.StudioMacroRepository:GetBinding(managed)
    and not ms.StudioActionBarRepository:GetLinks()[managed.studioId], "a shared copy must not allocate a native copy or a key")
assert(store.characters[id].macros[1] == source and source.body == original.body and source.name == original.name
    and source.icon == original.icon and not original.index, "all destinations must leave source snapshots untouched")

-- Full native scopes must leave shared storage available, with per-row reasons.
accounts[3] = {name="Fill",icon=103,body="/say full"}
ms.MacroRepository:Refresh()
openCopy()
assert(editor.copyButton:IsEnabled() and not editor.copyMenuRows[1]:IsEnabled()
    and not editor.copyMenuRows[2]:IsEnabled() and editor.copyMenuRows[3]:IsEnabled())
assert(editor.copyMenuRows[1].macroStudioTooltipText:find("full",1,true)
    and editor.copyMenuRows[2].macroStudioTooltipText:find("full",1,true))
assert(not ms:CopySelectedSnapshot("ACCOUNT") and not ms:CopySelectedSnapshot("CHARACTER") and writes == 2)
editor.copyMenuRows[3]:TriggerScript("OnClick")
assert(ms.selectedMacro.source == "STUDIO" and writes == 2, "copying to shared storage must work with both native scopes full")

-- Combat, modal changes, stale menus and removed snapshots must fail before writes.
openCopy()
combat = true
ms:UpdateCombatState()
assert(not editor.copyMenu:IsShown() and not editor.copyButton:IsEnabled())
assert(not ms:CopySelectedSnapshot("STUDIO") and not ms:CopySelectedSnapshot("ACCOUNT") and writes == 2)
combat = false
ms:UpdateCombatState()
assert(not editor.copyMenu:IsShown() and writes == 2, "leaving combat must never retry copying")
openCopy()
ms:SetMainWindowModalBlocked(true)
assert(not editor.copyMenu:IsShown() and not ms:CopySelectedSnapshot("STUDIO"))
ms:SetMainWindowModalBlocked(false)
ms:SelectMacro(original)
editor.copyButton:TriggerScript("OnClick")
local expected = ms.Helpers:CopyMacro(editor.copyMenuRows[3].snapshot)
ms:SelectMacro(snapshot(other))
assert(not editor.copyMenu:IsShown() and not ms:CopySelectedSnapshot("STUDIO", expected))
openCopy()
store.characters[id].macros = {}
assert(not ms:CopySelectedSnapshot("STUDIO") and not editor.copyButton:IsEnabled() and not editor.copyMenu:IsShown())
store.characters[id].macros = {source, other}
ms:SelectMacro(original)
assert(not ms:CopySelectedSnapshot("UNEXPECTED") and writes == 2)

local invalid = {order=3, name="Too Long", icon=134400, body=string.rep("x",256)}
store.characters[id].macros[3] = invalid
ms:SelectMacro(snapshot(invalid))
assert(not editor.copyButton:IsEnabled() and not ms:CopySelectedSnapshot("STUDIO") and writes == 2)
ms:SelectMacro(ms.MacroRepository:GetAll()[1])
assert(not editor.copyButton:IsShown() and not editor.copyMenu:IsShown() and not ms:CopySelectedSnapshot("ACCOUNT"))
print("PASS snapshot copy dropdown: all destinations, exact content, capacity, outside click, source preservation and stale/combat/modal guards")
