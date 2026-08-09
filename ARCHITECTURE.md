# MacroStudio Architecture

## Scope of version 0.2.1

Version 0.2.1 edits bodies of existing Blizzard-native macros and adds virtual organization through categories, favorites, and tags. It also uses a hidden FontString to measure multiline editor content because Retail EditBox objects do not expose `GetStringHeight()`. It does not implement search or native macro creation, rename, icon change, duplication, deletion, or scope changes. Native WoW frames and APIs are used directly; there is no addon framework or third-party runtime dependency.

## Module responsibilities

```text
Core.lua
|-- Database.lua
|-- MacroRepository.lua
|-- MetadataRepository.lua
|-- Utils/Helpers.lua
`-- UI/MainFrame.lua
    |-- UI/Dialogs.lua
    |-- UI/Sidebar.lua
    |-- UI/MacroList.lua
    `-- UI/Editor.lua
```

- `Core.lua` owns the addon namespace, constants, event dispatch, combat state, and opt-in debug output.
- `Database.lua` initializes and migrates SavedVariables fields without replacing existing data.
- `MacroRepository.lua` owns all calls to `GetNumMacros`, `GetMacroInfo`, and `EditMacro` and annotates scope-local duplicate names.
- `MetadataRepository.lua` owns virtual categories, favorites, tags, metadata records, and reconciliation.
- `UI/MainFrame.lua` coordinates lifecycle, filtering, selection, refreshing, conflict handling, Save, and Revert.
- `UI/Dialogs.lua` owns discard confirmations and category/tag input prompts.
- `UI/Sidebar.lua` renders built-in and user-created navigation filters.
- `UI/MacroList.lua` renders account and character sections from filtered repository records.
- `UI/Editor.lua` owns the draft buffer, organization controls, and derived reactive editor state.
- `Utils/Helpers.lua` contains small cross-module utilities.

UI modules do not call raw native macro APIs. They use `MacroRepository` for current snapshots and writes and `MetadataRepository` for virtual organization.

## Blizzard-owned and MacroStudio-owned data

Blizzard is the source of truth for every native macro's name, body, icon, scope, and current enumeration index. MacroStudio writes a body only through `EditMacro` and never creates a parallel execution mechanism.

`MacroStudioDB` schema 2 is additive:

```lua
MacroStudioDB = {
    schemaVersion = 2,
    settings = {
        window = {},
    },
    metadata = {
        nextId = 1,
        records = {
            ["metadata-1"] = {
                id = "metadata-1",
                favorite = true,
                categoryId = "category-1",
                tags = { "Burst", "Raid" },
                snapshot = {
                    scope = "ACCOUNT",
                    lastKnownIndex = 7,
                    name = "Cooldowns",
                    icon = 134400,
                    body = "/cast Example",
                },
            },
        },
    },
    categories = {
        nextId = 2,
        order = { "category-1" },
        byId = {
            ["category-1"] = { id = "category-1", name = "Raid" },
        },
    },
    history = {},
}
```

Migration adds missing fields individually, preserves settings and reserved history data, and never downgrades a database created by a newer addon. Organization records are keyed by opaque IDs, never by a macro index or name. `lastKnownIndex` and name are reconciliation evidence inside a snapshot, not persistent table keys.

Deleting a category removes only MacroStudio metadata assignments. It never invokes a native macro write or deletion API. If MacroStudio is disabled or removed, native macros remain ordinary Blizzard macros.

## Native macro repository and duplicate names

`MacroRepository:Refresh()` enumerates account and character indexes and produces current snapshots:

```text
index, scope, name, icon, body, duplicateName, duplicateCount
```

Duplicate detection is case-insensitive and isolated by scope. Warnings are informational; enumeration and Save always use native indexes, never name lookup.

Before Save, the repository re-reads the selected index and requires the complete original snapshot to match. An external change blocks the write and preserves the draft. After `EditMacro`, the repository refreshes and uses the returned index, original index, or a unique full-field match. Ambiguity is reported instead of guessed.

## Metadata reconciliation

Macro indexes are sorted enumeration positions rather than durable identities, and names can be duplicated. Each meaningful organization record therefore stores a snapshot and is reconciled against currently available macros with decreasing confidence:

1. unique scope/name/icon/body match;
2. unique scope/name/icon match;
3. unique scope/name/body match.

Each current macro can receive at most one metadata record during a reconciliation pass. If a tier produces multiple candidates, or no confident candidate exists, the record remains stored but unattached. The last-known index is never used as sufficient evidence. A later refresh can attach the preserved record when the ambiguity clears.

Empty records are pruned after their category, favorite, and tags are all removed. Meaningful unresolved records are retained.

## Central reactive editor state

The editor keeps the body loaded from Blizzard as `savedBody`. `UpdateEditorState()` compares that immutable baseline with the current edit-box text and derives one state object:

```text
body, dirty, length, overBy, canSave, canRevert
```

The edit box calls this function directly from `OnTextChanged`, so a keystroke updates the count, dirty label, limit message, Save, and Revert immediately without refreshing the repository or rebuilding the list.

Programmatic loads use `SetEditorText()`, which raises `suppressTextChanged`, calls `SetText`, clears the suppression flag, and performs exactly one explicit state update. This prevents selection, Save, Revert, and external refreshes from creating false dirty transitions.

The derived Save condition requires a selected macro, a dirty body at or below 255 characters, no combat lockdown, and no external conflict. Revert remains available for any dirty selected body, including an over-limit or conflicted draft.

## Dirty-buffer and refresh safety

- Selecting another macro while dirty opens a discard confirmation.
- `UPDATE_MACROS` automatically refreshes repository and organization state.
- A clean selection reloads when its native body changes.
- A dirty editor buffer is never overwritten by refresh.
- If the selected native snapshot changes while dirty, the editor enters an external-conflict state and Save is blocked.
- Revert deliberately resolves and loads Blizzard's current body without writing.
- Manual Refresh and `/ms refresh` remain fallback diagnostics, not prerequisites for editor state.
- Hiding and reopening preserves the in-memory draft; reloading the whole UI cannot.

## Combat restrictions

`PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, and `InCombatLockdown()` drive state. The editor remains readable and editable, but Save is disabled, and the repository independently checks combat immediately before `EditMacro`.

Leaving combat only recomputes legal actions. It never auto-saves.

## Non-destructive rules

- Never bypass protected actions or the native 255-character limit.
- Never truncate an over-limit body.
- Never choose a duplicate by name when an enumerated index is available.
- Never overwrite external edits when the selected snapshot no longer matches.
- Never key durable metadata by macro index or name.
- Never attach ambiguous metadata by guesswork.
- Never let a category/tag/favorite action mutate or delete a native macro.
- Never execute imported text as Lua.
- Future linting or optimization may suggest changes but must not silently mutate macros.
