"""MacroStudio headless preflight.

Requires Python 3 and lupa. The embedded Lua runtime compiles every addon file,
then WoW API stubs exercise repository mutation, metadata, and section filters.
"""

from pathlib import Path

from lupa.lua51 import LuaRuntime


from ui_smoke import run_ui_smoke

ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
globals_ = lua.globals()
load = lua.eval("loadstring")


def compile_lua(path: Path):
    result = load(path.read_text(encoding="utf-8"), "@" + path.relative_to(ROOT).as_posix())
    chunk, error = result if isinstance(result, tuple) else (result, None)
    assert chunk is not None, f"{path.name}: {error}"
    return chunk


def load_addon_file(relative_path: str, namespace):
    compile_lua(ROOT / relative_path)("MacroStudio", namespace)


for lua_path in sorted(ROOT.rglob("*.lua")):
    compile_lua(lua_path)

lua.execute(
    r"""
    Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 3, MAX_CHARACTER_MACROS = 2 } }
    MAX_ACCOUNT_MACROS = 3
    MAX_CHARACTER_MACROS = 2
    SlashCmdList = {}
    CANCEL = "Cancel"
    combat = false
    function InCombatLockdown() return combat end
    function strlenutf8(value) return #value end

    accountMacros = {
        { name = "Twin", icon = 101, body = "/say first" },
        { name = "Twin", icon = 102, body = "/say second" },
    }
    characterMacros = {
        { name = "Solo", icon = 103, body = "/cast Spell" },
    }

    function GetNumMacros()
        return #accountMacros, #characterMacros
    end

    function GetMacroInfo(index)
        local macro
        if index <= MAX_ACCOUNT_MACROS then
            macro = accountMacros[index]
        else
            macro = characterMacros[index - MAX_ACCOUNT_MACROS]
        end
        if not macro then return nil end
        return macro.name, macro.icon, macro.body
    end

    function CreateMacro(name, icon, body, perCharacter)
        local target = perCharacter and characterMacros or accountMacros
        local capacity = perCharacter and MAX_CHARACTER_MACROS or MAX_ACCOUNT_MACROS
        if #target >= capacity then return nil end
        target[#target + 1] = { name = name, icon = icon, body = body }
        return perCharacter and (MAX_ACCOUNT_MACROS + #target) or #target
    end

    function EditMacro(index, name, icon, body)
        local target, offset
        if index <= MAX_ACCOUNT_MACROS then
            target, offset = accountMacros, 0
        else
            target, offset = characterMacros, MAX_ACCOUNT_MACROS
        end
        local macro = target[index - offset]
        if not macro then return nil end
        macro.name = name or macro.name
        macro.icon = icon or macro.icon
        macro.body = body or macro.body
        return index
    end

    function DeleteMacro(index)
        if index <= MAX_ACCOUNT_MACROS then
            table.remove(accountMacros, index)
        else
            table.remove(characterMacros, index - MAX_ACCOUNT_MACROS)
        end
    end
    """
)

namespace = lua.table()
namespace.VERSION = "0.2.2"
namespace.MAX_BODY_LENGTH = 255
namespace.MAX_NAME_LENGTH = 16
namespace.DEFAULT_ICON = 134400
namespace.BODY_WARNING_LENGTH = 230
namespace.Debug = lua.eval("function() end")
namespace.Print = lua.eval("function() end")
globals_.MacroStudioDB = None

load_addon_file("Utils/Helpers.lua", namespace)
load_addon_file("MacroRepository.lua", namespace)
load_addon_file("MetadataRepository.lua", namespace)
load_addon_file("UI/MacroList.lua", namespace)
load_addon_file("UI/MainFrame.lua", namespace)

setup_namespace = load(
    r"""
    local _, ms = ...
    ms.db = {
        metadata = { records = {}, nextId = 1 },
        categories = { byId = {}, order = {}, nextId = 1 },
        settings = { window = {} },
    }
    """,
    "@preflight-setup",
)
setup_namespace("MacroStudio", namespace)

tests = load(
    r"""
    local _, ms = ...
    local repo = ms.MacroRepository
    local metadata = ms.MetadataRepository

    local macros = repo:Refresh()
    assert(#macros == 3, "refresh should enumerate both scopes")
    assert(repo.accountCount == 2 and repo.characterCount == 1, "scope counts")
    assert(macros[1].duplicateName and macros[2].duplicateName, "duplicate detection")
    assert(macros[3].scope == "CHARACTER" and macros[3].index == 4, "character index offset")

    local valid, reason = repo:ValidateCreateRequest({
        name = "", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("name"), "blank names should fail")
    valid = repo:ValidateCreateRequest({
        name = "ThisNameIsFarTooLong", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid, "long names should fail")
    combat = true
    valid, reason = repo:ValidateCreateRequest({
        name = "Blocked", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("Combat"), "combat should block creation")
    combat = false

    local created, createdMacro = repo:Create({
        name = "New", body = "/say new", icon = 134400, scope = "ACCOUNT",
    })
    assert(created and createdMacro and createdMacro.index == 3, "create should return exact new macro")
    valid, reason = repo:ValidateCreateRequest({
        name = "Full", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("full"), "capacity should block creation")

    local firstTwin = ms.Helpers:CopyMacro(repo:GetAll()[1])
    local secondTwin = ms.Helpers:CopyMacro(repo:GetAll()[2])
    local deleted, deleteReason = repo:Delete(secondTwin)
    assert(deleted, deleteReason)
    assert(accountMacros[1].body == firstTwin.body, "delete should preserve first duplicate")
    assert(accountMacros[2].name == "New", "delete should target duplicate by exact index")
    deleted = repo:Delete(secondTwin)
    assert(not deleted, "stale snapshot should not delete shifted neighbor")
    assert(accountMacros[2].name == "New", "stale delete must leave neighbor intact")

    combat = true
    deleted, deleteReason = repo:Delete(ms.Helpers:CopyMacro(repo:GetAll()[1]))
    assert(not deleted and deleteReason:find("Combat"), "combat should block deletion")
    combat = false

    metadata:Reconcile(repo:GetAll())
    local first = repo:GetAll()[1]
    local second = repo:GetAll()[2]
    metadata:ToggleFavorite(first)
    local ok, tag = metadata:AddTag(first, "Raid")
    assert(ok and tag == "Raid", "new tag")
    ok = metadata:AddTag(first, "raid")
    assert(not ok, "assigned tags should be rejected case-insensitively")
    ok, tag = metadata:AddTag(second, "raid")
    assert(ok and tag == "Raid", "existing tag spelling should be canonical")
    assert(#metadata:GetAllTags() == 1, "tag choices should be unique")

    local _, firstRecordId = metadata:GetRecordForMacro(first)
    metadata:OnMacroDeleted(first, firstRecordId)
    assert(metadata:GetRecords()[firstRecordId] == nil, "deleted macro metadata should be removed")
    metadata:Reconcile({ second })
    assert(not metadata:IsFavorite(second), "neighbor must not inherit deleted favorite metadata")

    local list = ms.MacroList
    local sectionTitles = {}
    list.ReleaseVisibleItems = function(self)
        self.visibleRows, self.visibleHeaders, self.visibleEmptyLabels = {}, {}, {}
    end
    list.AddSection = function(self, title, sectionMacros, y, showEmpty)
        if #sectionMacros == 0 and not showEmpty then return y, false end
        sectionTitles[#sectionTitles + 1] = title
        return y + 1, true
    end
    list.AddEmptyMessage = function(self, _, y) return y + 1 end
    list.SetSelected = function() end
    list.scrollChild = { SetHeight = function() end }
    list.scrollFrame = { GetHeight = function() return 100 end }

    sectionTitles = {}
    list:Rebuild({ first, second }, nil, { kind = "all" })
    assert(#sectionTitles == 2, "All should render both scope headers")
    sectionTitles = {}
    list:Rebuild({ first }, nil, { kind = "account" })
    assert(#sectionTitles == 1 and sectionTitles[1] == "ACCOUNT MACROS", "Account filter header")
    sectionTitles = {}
    list:Rebuild({ second }, nil, { kind = "favorites" })
    assert(#sectionTitles == 1, "organization filters should omit empty scope headers")
    """,
    "@preflight-tests",
)
tests("MacroStudio", namespace)

macro_list_source = (ROOT / "UI" / "MacroList.lua").read_text(encoding="utf-8")
sidebar_source = (ROOT / "UI" / "Sidebar.lua").read_text(encoding="utf-8")
editor_source = (ROOT / "UI" / "Editor.lua").read_text(encoding="utf-8")
macro_dialog_source = (ROOT / "UI" / "MacroDialog.lua").read_text(encoding="utf-8")
helpers_source = (ROOT / "Utils" / "Helpers.lua").read_text(encoding="utf-8")
dialogs_source = (ROOT / "UI" / "Dialogs.lua").read_text(encoding="utf-8")

assert 'SetAtlas("PetJournal-FavoritesIcon")' in macro_list_source
assert 'atlas = "PetJournal-FavoritesIcon"' in sidebar_source and "SetAtlas(atlas)" in sidebar_source
assert 'SetAtlas("PetJournal-FavoritesIcon")' in editor_source
assert "favoritePrefix" not in macro_list_source
assert '"ScrollingEditBoxTemplate"' in helpers_source
assert "SetMouseClickEnabled(true)" in helpers_source
assert "SetMouseMotionEnabled(true)" in helpers_source
assert "CreateNativeScrollingEditBox(editBorder, 5)" in editor_source
assert "CreateNativeScrollingEditBox(bodyBorder, 5)" in macro_dialog_source
assert '"OnCursorChanged"' not in helpers_source
assert '"OnEnterPressed"' in dialogs_source and '"OnEscapePressed"' in dialogs_source

run_ui_smoke(ROOT)
print("PASS MacroStudio Milestone 2.1 preflight")
