# MacroStudio Architecture

## Scope of version 0.2.2

Version 0.2.2 edits, creates, and deletes Blizzard-native macros and provides virtual organization through categories, Favorites, and tags. It does not implement search, history/Trash, existing-macro rename/icon/scope changes, duplication, import/export, or launchers.

Native WoW frames and APIs are used directly. Runtime addon code has no third-party dependency. The Python/Lupa headless harness is development-only.

## Module responsibilities

```text
Core.lua
|-- Database.lua
|-- MacroRepository.lua
|-- MetadataRepository.lua
|-- Utils/Helpers.lua
`-- UI/MainFrame.lua
    |-- UI/Dialogs.lua
    |-- UI/IconPicker.lua
    |-- UI/MacroDialog.lua
    |-- UI/Sidebar.lua
    |-- UI/MacroList.lua
    `-- UI/Editor.lua
```

- `MacroRepository.lua` is the only layer that calls `GetNumMacros`, `GetMacroInfo`, `EditMacro`, `CreateMacro`, or `DeleteMacro`.
- `MetadataRepository.lua` owns virtual organization records and removes the trusted record for a MacroStudio-deleted macro before reconciliation.
- `Utils/Helpers.lua` centralizes native EditBox mouse/focus/cursor scrolling, tooltips, and disabled styling.
- `UI/Editor.lua` derives Save/Delete state from the draft, combat, conflict, length, and exact target snapshot.
- `UI/MacroDialog.lua` derives Create state from name/body/icon/scope/capacity/combat validation.
- `UI/IconPicker.lua` uses Blizzard's icon provider when available and compatible API fallbacks otherwise.
- `UI/MacroList.lua` decides which scope headers are meaningful for the active filter.
- `UI/MainFrame.lua` coordinates selection, event suppression during native mutations, organization refresh, and dialogs.

UI modules never call raw native macro mutation APIs.

## Blizzard-owned and MacroStudio-owned data

Blizzard owns every native macro's name, body, icon, scope, and current enumeration index. MacroStudio writes through the native macro APIs and never creates a parallel execution mechanism.

`MacroStudioDB` schema 2 stores only settings and virtual metadata. Organization records use opaque IDs and carry a reconciliation snapshot:

```text
scope, lastKnownIndex, name, icon, body
```

The last-known index is evidence, not a durable key. Categories, Favorites, and tags have no effect on native execution.

## Exact native mutation rules

Every Save and Delete starts from a copied snapshot. Immediately before the mutation, the repository re-reads the enumerated index and requires index, scope, name, icon, and body to match. This prevents a shifted neighbor or same-name duplicate from becoming the target.

Save passes the enumerated index to `EditMacro`, refreshes, and resolves the returned/original/unique full-field result. Create refreshes capacity, validates all fields, calls `CreateMacro`, refreshes, and selects the returned or uniquely matching record. Delete refreshes, revalidates the exact snapshot, calls `DeleteMacro(index)`, and requires the relevant scope count to decrease by one.

`UPDATE_MACROS` can fire around a native mutation. `UI/MainFrame.lua` defers that event while the repository is operating, then performs one controlled metadata reconciliation. For Delete, the trusted metadata record is removed first so a shifted neighbor cannot inherit it.

## Duplicate names and metadata reconciliation

Duplicate detection is case-insensitive and isolated by scope. Names are never used alone for Save or Delete.

Meaningful metadata records reconcile against currently unclaimed macros using decreasing confidence:

1. unique scope/name/icon/body;
2. unique scope/name/icon;
3. unique scope/name/body.

Ambiguous or unmatched records remain stored but unattached. Each current macro can receive at most one record. Empty records are pruned.

## Central editor and action state

`Editor:UpdateEditorState()` derives:

```text
body, dirty, length, overBy, targetSafe,
canSave, saveReason, canRevert, canDelete, deleteReason
```

Save requires a selected dirty target, at most 255 characters, no combat, no external conflict, and an exact current snapshot. Delete additionally requires a clean buffer. Create is disabled while combat-locked, at capacity, or while automatic selection would discard a dirty draft. Repository methods repeat the important validation defensively.

The editor uses the native multiline `EditBox`. `EnableMouse(true)` preserves click placement and drag selection; `OnCursorChanged` only adjusts the enclosing ScrollFrame to keep the native caret visible. A hidden FontString measures content because Retail EditBox objects do not provide `GetStringHeight()`.

Programmatic loads suppress text-change handling, then recompute once. External refresh never overwrites a dirty draft.

## Input and Favorite UI

Category and tag text input uses one custom dialog. Enter invokes the same validated submit path as the visible button, Escape cancels, and invalid input stays in the dialog with an inline error.

Tag Add menus contain all unique existing tags not assigned to the selected macro, plus **Create New Tag...**. Tag spelling is canonicalized case-insensitively.

Favorites use Blizzard's `PetJournal-FavoritesIcon` atlas rather than Unicode font glyphs. The editor also changes the atlas treatment, label, and backdrop so active state is obvious without relying on color alone.

## Combat and non-destructive invariants

- The workspace and drafts remain readable/editable in combat; native Create, Save, and Delete are blocked.
- Leaving combat recomputes eligibility and never auto-saves.
- Over-limit text is never truncated.
- Dirty drafts are never silently replaced.
- Ambiguous native targets and metadata are never guessed.
- Category/tag/Favorite actions never mutate a native macro.
- Imported text, when implemented, must never be executed as Lua.
