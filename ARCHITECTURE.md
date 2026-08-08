# MacroStudio Architecture

## Scope of version 0.1.0

Milestone 1 is intentionally narrow: enumerate existing native macros, select one, edit its body, validate it, Save, and Revert. Native WoW frames/APIs are used directly; there is no addon framework or third-party runtime dependency.

## Module responsibilities

```text
Core.lua
  ├─ Database.lua
  ├─ MacroRepository.lua
  ├─ Utils/Helpers.lua
  └─ UI/MainFrame.lua
       ├─ UI/MacroList.lua
       └─ UI/Editor.lua
```

- `Core.lua` owns the single addon namespace, constants, event dispatch, combat state, and opt-in debug output.
- `Database.lua` initializes missing SavedVariables fields without replacing an existing database.
- `MacroRepository.lua` owns all calls to `GetNumMacros`, `GetMacroInfo`, and `EditMacro`.
- `UI/MainFrame.lua` coordinates lifecycle, selection, refreshing, confirmation, Save, and Revert.
- `UI/MacroList.lua` renders account and character sections from repository records.
- `UI/Editor.lua` owns the draft buffer and derives dirty/limit/combat UI state.
- `Utils/Helpers.lua` contains only small cross-module utilities.

UI modules do not call raw macro APIs. They ask `MacroRepository` for current snapshots and operations.

## Blizzard-owned data and MacroStudio-owned data

Blizzard remains the source of truth for every native macro's name, body, icon, scope, and current enumeration index. MacroStudio writes only through the native API and never creates a parallel execution mechanism.

`MacroStudioDB` is additive storage with this initial shape:

```lua
MacroStudioDB = {
    schemaVersion = 1,
    settings = {},
    metadata = {},
    history = {},
}
```

Only window settings are currently populated. `metadata` and `history` are migration-ready placeholders, not implemented features. Missing fields are added individually; an existing table is never overwritten wholesale.

If MacroStudio is disabled or removed, native macros remain ordinary Blizzard macros.

## Native macro repository

`MacroRepository:Refresh()` enumerates account macros and character macros, whose native index range begins after `MAX_ACCOUNT_MACROS`. Each record is a current snapshot:

```text
index, scope, name, icon, body
```

The index is used as a short-lived handle because index-based reads/writes avoid the ambiguity of duplicate names. Before Save, the repository re-reads that index and requires the complete snapshot to match. If anything changed externally, Save is blocked and the draft is retained.

After `EditMacro`, the repository refreshes and uses the returned index, original index, or a unique full-field match to reselect the saved macro. It reports ambiguity rather than guessing.

## Macro identity is not solved by an index

Blizzard macro indexes are sorted enumeration positions, not durable primary keys. Renaming or other list changes may move a macro. Names are also insufficient because duplicate names are legal; bodies and icons can change as well.

Therefore future metadata must never use a mapping such as `metadata[17]` with the assumption that index 17 always means the same macro.

A future reconciliation design may retain a signature/snapshot containing:

- scope
- last-known index
- name
- body
- icon
- previous reconciliation evidence

Refresh can then compare multiple fields and assign confidence. Exact unique matches are safe; ambiguous matches must preserve metadata separately and ask the user. MacroStudio must never silently attach a category, history, or backup to a different macro merely because it inherited an old index.

Milestone 1 does not persist per-macro metadata, so it does not prematurely commit to a flawed identity scheme.

## Duplicate names

Enumeration and Save use native indexes, never a macro name lookup. The pre-save full-snapshot check prevents a changed index from silently targeting a same-named neighbor. Revert can follow an exact snapshot or a unique scope/name/icon candidate; it refuses ambiguous duplicates.

Explicit duplicate detection and user reconciliation belong to Milestone 2.

## Dirty-buffer safety

The editor keeps an immutable copy of the body loaded from Blizzard and compares it with the current edit-box text.

- Selecting another macro while dirty opens a discard confirmation.
- Refresh never overwrites a dirty buffer.
- If an external update invalidates the selection, the buffer remains visible and Save becomes blocked.
- Revert deliberately reloads the latest safely resolved Blizzard body without writing anything.
- Hiding and reopening the window preserves the in-memory draft.

Reloading the entire UI cannot preserve an unsaved in-memory draft; persistent drafts are a possible future feature.

## Combat restrictions

`PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, and `InCombatLockdown()` drive state. The editor remains readable and its draft remains editable, but Save is disabled and the repository independently rechecks combat immediately before `EditMacro`.

Leaving combat only re-enables legal actions. It never auto-saves.

## Refresh behavior

`UPDATE_MACROS` triggers repository/list refreshes without polling. Because this event may fire even for non-mutating selection activity in Blizzard's Macro UI, refresh is idempotent and never discards a dirty draft. A manual Refresh button and `/ms refresh` are also available.

## Non-destructive rules

- Never bypass protected actions or the native 255-character limit.
- Never truncate an over-limit body.
- Never choose a duplicate by name when an enumerated index is available.
- Never overwrite external edits when the selected snapshot no longer matches.
- Never execute imported text as Lua.
- Future linting/optimization may suggest changes but must not silently mutate macros.
