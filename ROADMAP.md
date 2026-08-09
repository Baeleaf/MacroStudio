# MacroStudio Roadmap

Version 0.2.2 completes Milestones 1, 1.1, 2, and 2.1. Search remains the next product milestone; it was intentionally not started as part of the 2.1 work.

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

## Milestone 3 - Search and filtering

- [ ] Search macro name and body
- [ ] Search categories and tags
- [ ] Add simple filters such as `scope:account`, `scope:character`, `tag:M+`, and `favorite:true`
- [ ] Prefer a small understandable filter language

## Later native management

- [ ] Rename existing native macros
- [ ] Change an existing macro's icon or scope
- [ ] Duplicate Macro
- [ ] Consider recoverable Trash only with a broader history design
- [ ] Warn when destructive operations affect macros placed on action slots

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

## Parser, action bars, templates, and optimization

- [ ] Advisory tokenizer/linter and maintainable syntax highlighting
- [ ] Action-slot awareness with paging/form/override caveats
- [ ] Previewable templates and cursor-position snippets
- [ ] Explained, opt-in character-count reduction suggestions

These later tools must never silently rewrite working macros or claim semantic equivalence without sufficient certainty.
