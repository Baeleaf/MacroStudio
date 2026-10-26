local _, ms = ...
local studio, bridge, native = ms.StudioMacroRepository, ms.StudioActionBarRepository, ms.MacroRepository
combat, deferTimers = false, false
ms.Settings.frame:Hide()
ms.MacroDialog:Close()
ms.Editor:SetEditorText(ms.Editor.savedBody)

-- Model mutable native lists, including shifts, capacity and synchronous events.
local accounts = {{name="Unrelated",icon=101,selectedIcon=101,body="/say do not change"}}
local characters = {{name="Other Character",icon=102,selectedIcon=102,body="/say keep me"}}
local writes, edits, deletes, pickups = 0,0,0,{}
local busyCursor = false
local function group(index)
    return index <= 3 and accounts or characters, index <= 3 and index or index - 3
end
GetNumMacros = function() return #accounts,#characters end
GetMacroInfo = function(index)
    local list, offset = group(index)
    local m = list[offset]
    if m then return m.name,m.icon,m.body end
end
C_Macro.GetSelectedMacroIcon = function(index)
    local list, offset = group(index)
    return list[offset] and list[offset].selectedIcon
end
GetMacroSpell = function() end
GetMacroItem = function() end
GetCursorInfo = function() if busyCursor then return "item",123 end end
CreateMacro = function(name,icon,body,character)
    local list, limit = character and characters or accounts, character and 2 or 3
    if #list >= limit then return nil end
    list[#list+1] = {name=name,icon=icon,selectedIcon=icon,body=body}
    writes = writes + 1
    ms:OnMacrosChanged("UPDATE_MACROS")
    return (character and 3 or 0) + #list
end
EditMacro = function(index,name,icon,body)
    local list, offset = group(index)
    if not list[offset] then return nil end
    local m = list[offset]
    m.name,m.icon,m.selectedIcon,m.body = name,icon,icon,body
    edits = edits + 1
    ms:OnMacrosChanged("UPDATE_MACROS")
    return index
end
DeleteMacro = function(index)
    local list, offset = group(index)
    table.remove(list,offset)
    deletes = deletes + 1
    ms:OnMacrosChanged("UPDATE_MACROS")
end
PickupMacro = function(index) assert(GetMacroInfo(index)); pickups[#pickups+1]=index end
actionSlots = {}
native:Refresh()

local ok, managed = studio:Create({name="Drag Test",icon=135846,body="/say saved drag"})
assert(ok)
ms:SelectMacro(managed)
ms:SetFilter("studio")
local function rowFor(id)
    for _,row in ipairs(ms.MacroList.visibleRows) do
        if row.macro.studioId == id then return row end
    end
    error("missing studio row")
end
local row = rowFor(managed.studioId)
assert(row.dragButton == "LeftButton" and ms.Editor.iconButton.dragButton == "LeftButton",
    "both list rows and the editor icon must register for dragging")
row:TriggerScript("OnDragStart")
local copy = assert(bridge:FindCopy(managed.studioId,true))
assert(writes == 1 and copy.scope == "CHARACTER" and pickups[#pickups] == copy.index,
    "first drag must create one Character copy and put its native index on the cursor")
assert(copy.body == managed.body and copy.selectedIcon == managed.selectedIcon and copy.name == managed.name)
ms.Editor.iconButton:TriggerScript("OnDragStart")
assert(writes == 1 and #pickups == 2, "editor dragging must reuse the list's linked copy")

-- Ordinary native editor dragging still calls the native pickup path directly.
ms:SelectMacro(native:GetByIndex(1))
ms.Editor.iconButton:TriggerScript("OnDragStart")
assert(pickups[#pickups] == 1 and writes == 1)
ms:SelectMacro(studio:GetById(managed.studioId))

-- Unsaved editor contents never leak into an action-bar copy.
ms.Editor.editBox:SetUserText("/say UNSAVED drag")
ms.Editor.iconButton:TriggerScript("OnDragStart")
assert(ms.Editor:IsDirty() and ms.Editor:GetBody() == "/say UNSAVED drag"
    and bridge:FindCopy(managed.studioId,true).body == managed.body,
    "dragging must use saved text without changing or saving the draft")
ms:SaveSelectedMacro()
managed = studio:GetById(managed.studioId)
copy = bridge:FindCopy(managed.studioId,true)
assert(managed.body == "/say UNSAVED drag" and copy.body == managed.body and edits == 1,
    "Save must synchronize an existing verified native copy")

-- Removing another native macro shifts indices; repeat dragging must follow it.
table.remove(characters,1)
ms.Editor.iconButton:TriggerScript("OnDragStart")
copy = bridge:FindCopy(managed.studioId,true)
assert(copy.index == 4 and pickups[#pickups] == 4 and writes == 1,
    "reusing a shifted native copy must not target the old index or create duplicates")
actionSlots[60] = {"macro",copy.index,nil,copy.name,copy.icon}
ms.ActionBarRepository:Refresh()
ms.Editor:RefreshActionBarUsage()
ms.MacroList:RefreshUsage()
assert(ms.Editor.actionBarUsageCount == 1 and ms.Editor.usageButton.Text:GetText():find("On Bar",1,true)
    and rowFor(managed.studioId).usageText:IsShown(), "managed records must report linked action-bar usage")

local writesBefore, pickupsBefore = writes, #pickups
combat = true
ms:UpdateCombatState()
assert(not ms:RequestPickupMacro(managed) and writes == writesBefore and #pickups == pickupsBefore)
combat = false
ms:UpdateCombatState()
busyCursor = true
assert(not ms:RequestPickupMacro(managed) and writes == writesBefore and #pickups == pickupsBefore)
busyCursor = false

-- Same-scope identical copies are ambiguous and must never be overwritten.
characters[2] = {name=copy.name,icon=copy.icon,selectedIcon=copy.selectedIcon,body=copy.body}
local success, _, reason = studio:Update(managed,{name=managed.name,icon=managed.icon,body="/say ambiguous"})
assert(not success and reason:find("changed outside",1,true) and edits == 1
    and studio:GetById(managed.studioId).body == managed.body)
table.remove(characters,2)

-- Manual edits invalidate ownership. A new drag may append a fresh copy only.
characters[1].body = "/say external native edit"
ms.Editor.editBox:SetUserText("/say new draft")
ms:SaveSelectedMacro()
assert(ms.Editor:IsDirty() and studio:GetById(managed.studioId).body == managed.body
    and characters[1].body == "/say external native edit", "external edits must stop Save and preserve the draft")
ms.Editor.iconButton:TriggerScript("OnDragStart")
assert(writes == 2 and #characters == 2 and characters[1].body == "/say external native edit"
    and ms.Editor:IsDirty(), "repair dragging must leave the external macro and draft untouched")
ms:SaveSelectedMacro()
managed = studio:GetById(managed.studioId)
assert(managed.body == "/say new draft" and characters[2].body == managed.body)
assert(accounts[1].body == "/say do not change", "native neighbors must remain untouched")

-- Deleting the managed definition removes only its verified current copy.
ms:DeleteSelectedMacro(ms.Helpers:CopyMacro(ms.selectedMacro))
assert(deletes == 1 and #characters == 1 and characters[1].body == "/say external native edit"
    and not studio:GetById(managed.studioId) and not bridge:GetLinks()[managed.studioId])

-- Character slots full: fall back to Account; both full: fail without mutation.
characters[2] = {name="Full Character",icon=103,selectedIcon=103,body="/say fill"}
local _, fallback = studio:Create({name="Fallback Drag",icon=135846,body="/say fallback"})
assert(ms:RequestPickupMacro(fallback))
assert(bridge:FindCopy(fallback.studioId,true).scope == "ACCOUNT" and #accounts == 2)
accounts[3] = {name="Full Account",icon=104,selectedIcon=104,body="/say fill"}
local _, full = studio:Create({name="No Slots",icon=135846,body="/say no slots"})
writesBefore, pickupsBefore = writes,#pickups
local picked, _, capacityReason = bridge:Pickup(full)
assert(not picked and capacityReason:find("one free",1,true) and writes == writesBefore
    and #pickups == pickupsBefore and not bridge:GetLinks()[full.studioId])
assert(studio:SetBinding(full,"CTRL-F12"), "native slot exhaustion must not affect direct managed keybindings")

-- Saved links synchronize on returning to a character, including deletions.
local link = bridge:GetLinks()[fallback.studioId]
local raw = studio:GetStore().records[fallback.studioId]
raw.body,raw.revision = "/say changed on alt",raw.revision+1
bridge:ReconcileCurrentCopies()
assert(bridge:FindCopy(fallback.studioId,true).body == raw.body)
studio:GetStore().records[fallback.studioId] = nil
bridge:ReconcileCurrentCopies()
assert(not bridge:GetLinks()[fallback.studioId] and #accounts == 2)
print("PASS studio action-bar dragging: list/editor, reuse, sync, shifts, drafts, capacity, combat and external edits")
