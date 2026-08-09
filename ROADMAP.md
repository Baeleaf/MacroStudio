# MacroStudio Roadmap

Version 0.3.0 completes Milestones 1 through 3, including safe native macro management, virtual organization, modal creation, and reactive search.

## Milestone 1 - Native macro editor

- [x] Standalone addon and movable, resizable workspace
- [x] Account/Character enumeration and multiline body editor
- [x] Live 255-character counter, dirty state, Save, Revert, and discard confirmation
- [x] Combat-aware writes, event refresh, SavedVariables, and Windows Junction tooling

## Milestone 1.1 - Reactive editor state

- [x] Derive dirty, length, limit, Save, and Revert from edit-box text
- [x] Suppress false dirty transitions during programmatic loads
- [x] Reload clean external updates and preserve dirty conflicts
- [x] Keep `/ms refresh` only as an explicit fallback

## Milestone 2 - Organization

- [x] Virtual category creation, rename, deletion, assignment, and removal
- [x] Favorites and multiple tags
- [x] Favorites, All, Account, Character, and category filters
- [x] Opaque metadata IDs and conservative reconciliation
- [x] Scope-aware duplicate-name warnings

## Milestone 2.1 - UX polish and native macro management

- [x] Native mouse caret placement, drag selection, multiline navigation, and scroll tracking in all text fields
- [x] Enter-to-submit, Escape-to-cancel, and persistent visible validation for category/tag dialogs
- [x] Atlas-based Favorites in navigation, list rows, and editor state
- [x] Existing-tag selection plus **Create New Tag...**, excluding already assigned tags
- [x] Filter-aware scope sections with empty organization sections suppressed
- [x] Central visible Save/Delete/Create eligibility and defensive action-time revalidation
- [x] Remove the visible Refresh button while retaining `/ms refresh`
- [x] Create native macros with name, body, scope, icon, capacity, combat, and limit validation
- [x] Delete the exact native macro with confirmation, dirty/combat/conflict guards, and metadata isolation
- [ ] Duplicate Macro (optional; deferred without delaying 2.1)

## Milestone 2.2 - UI polish and modal safety

- [x] Keep the native caret while rendering all four editor focus-border edges above scrolling controls
- [x] Block the complete main workspace with a real mouse-consuming overlay while Create Macro is open
- [x] Move Create Macro only by its title bar and keep it clamped on-screen
- [x] Clear modal state through every close path and restore sensible editor focus
- [x] Preserve the open form and modal blocking through combat without automatic creation
- [x] Promote native macro dragging to action bars as a high-priority future milestone

## Milestone 3 - Search and filtering

- [x] Search macro names and complete bodies with case-insensitive plain-text matching
- [x] Search assigned category names and tags
- [x] Combine search with All, Account, Character, Favorites, and category navigation
- [x] Update results immediately without native re-enumeration, reconciliation, or SavedVariables writes
- [x] Preserve selected and dirty editor buffers when search hides their macro row
- [x] Preserve search/filter state through metadata changes, Create, Delete, and modal interaction
- [x] Suppress empty scope sections during search and show one query-specific no-match message
- [x] Clear search without changing the current navigation filter

## Future advanced search syntax

- [ ] Add filters such as `scope:account`, `scope:character`, `tag:interrupt`, `category:mythic+`, `favorite:true`, `body:mouseover`, and `name:kick`
- [ ] Support understandable combinations such as `tag:interrupt focus` only after defining predictable parsing rules

## Later native management

- [ ] Rename existing native macros
- [ ] Change an existing macro's icon or scope
- [ ] Duplicate Macro
- [ ] Consider recoverable Trash only with a broader history design
- [ ] Warn when destructive operations affect macros placed on action slots

## High priority - Native action-bar placement and usage

### A. Place macros on action bars (implement first)

- [ ] Investigate current supported Retail macro pickup/cursor/drop APIs and secure-action restrictions
- [ ] Drag a Blizzard-native macro from a MacroStudio row, editor icon, or both directly onto action bars
- [ ] Respect combat lockdown and protected actions; never add custom execution or bypass secure restrictions
- [ ] Test Blizzard action bars and reasonable interoperability with popular action-bar addons

### B. Inspect action-bar usage (after placement)

- [ ] Show which action bar and button contain the selected macro, including paging/form/override caveats
- [ ] Resolve associated keybinds only if the result is reliable

## Backups, import, and export

- [ ] Selective metadata-only export/import
- [ ] Categories-only export/import
- [ ] Full-profile export/import with per-macro include/exclude choices
- [ ] Preview incoming changes and conflicts before writing
- [ ] Treat all imported content as untrusted text and never execute it as Lua
- [ ] Snapshot/version history with timestamps and sensible retention

## Launchers

- [ ] Add a minimap or addon-compartment launcher
- [ ] Consider an optional `/m` launcher without replacing Blizzard's `/macro`

## Parser, templates, and optimization

- [ ] Advisory tokenizer/linter and maintainable syntax highlighting
- [ ] Previewable templates and cursor-position snippets
- [ ] Explained, opt-in character-count reduction suggestions

These later tools must never silently rewrite working macros or claim semantic equivalence without sufficient certainty.
