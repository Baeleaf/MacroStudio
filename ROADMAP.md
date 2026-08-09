# MacroStudio Roadmap

Version 0.2.1 completes Milestones 1, 1.1, and 2, including the Retail multiline-editor compatibility hotfix. Later milestones remain intentionally out of scope until the completed work has been tested in game.

## Milestone 1 - Native macro editor

- [x] Standalone addon and Git repository
- [x] Large movable, resizable window
- [x] Account/character macro enumeration
- [x] Multiline body editor and live 255-character counter
- [x] Dirty state, Save, Revert, and discard confirmation
- [x] Combat lockdown behavior that preserves drafts
- [x] Event-driven and manual refresh
- [x] SavedVariables foundation
- [x] Windows Junction tooling and manual test plan

## Milestone 1.1 - Reactive editor state

- [x] Derive dirty, length, limit, Save, and Revert state directly from edit-box text
- [x] Update all editor controls on every user text-change event
- [x] Suppress text-change handling during programmatic loads, then recompute once
- [x] Keep clean external updates automatic through `UPDATE_MACROS`
- [x] Preserve dirty buffers and block Save on external conflicts
- [x] Retain Refresh only as an explicit fallback

## Milestone 2 - Organization

- [x] Virtual category creation, rename, deletion, assignment, and removal
- [x] Favorites independent of categories
- [x] Multiple tags plus one optional category per macro
- [x] Favorites, All, Account, Character, and category navigation filters
- [x] SavedVariables schema 2 with opaque metadata record IDs
- [x] Conservative metadata reconciliation across index movement
- [x] Preservation of unresolved metadata instead of guessing
- [x] Scope-aware duplicate-name detection and warnings
- [x] Organization actions never create, rename, edit, or delete Blizzard macros

Per-macro notes and last-edited timestamps remain possible future organization enhancements; they were not part of the approved Milestone 2 implementation plan.

## Milestone 3 - Search and filtering

- [ ] Search macro name and body
- [ ] Search category and tags
- [ ] Basic filters such as `scope:account`, `scope:character`, `tag:M+`, and `favorite:true`
- [ ] Favor simple, useful filtering before designing a query language

## Milestone 4 - Full macro management

- [ ] New and Duplicate Macro
- [ ] Rename and icon picker
- [ ] Account/character scope selection
- [ ] Delete with explicit confirmation
- [ ] Capacity warnings
- [ ] Investigate a recoverable Trash concept
- [ ] Warn on destructive operations when a macro is used on action slots

All operations must honor combat protection, native name/body/capacity limits, and duplicate names.

## Milestone 5 - Backups and history

- [ ] Snapshot name, body, icon, scope, and timestamp before MacroStudio changes/deletes
- [ ] Browse versions by human-readable time
- [ ] Explicit restore flow
- [ ] Sensible retention limits for SavedVariables growth
- [ ] Trash for macros deleted through MacroStudio, if feasible

## Milestone 6 - Parser and conservative linter

- [ ] Deterministic macro tokenizer/parser
- [ ] Character-budget warnings
- [ ] Possible duplicate conditionals or commands
- [ ] Malformed bracket warnings
- [ ] Suspicious spell/item references where an API can support the check
- [ ] Maintainable syntax highlighting for commands, conditions, targets, and arguments

The linter must be advisory and must not silently rewrite working macros.

## Milestone 7 - Action-bar awareness

- [ ] Show raw action slots that reference the selected macro
- [ ] Map slots to human-friendly bar/button descriptions only where reliable
- [ ] Account for paging, forms/stances, overrides, possess states, and third-party action-bar presentation
- [ ] Investigate keybinding awareness later

## Milestone 8 - Templates and snippets

- [ ] Previewable macro templates such as Mouseover Heal, Focus Interrupt, and Arena Target
- [ ] Insertable snippets such as `[@cursor]`, `[@player]`, and `[mod:shift]`
- [ ] Insert snippets at the editor cursor
- [ ] Keep templates as drafts until the user explicitly creates a native macro

## Milestone 9 - Optimization helpers

- [ ] Suggest conservative character-count reductions
- [ ] Display estimated savings and resulting length
- [ ] Explain each proposed change
- [ ] Never silently apply or claim semantic equivalence without sufficient certainty

## Milestone 10 - Import and export

- [ ] Individual macro sharing
- [ ] Category/template packs
- [ ] Metadata backup/export
- [ ] Preview imports before any native write
- [ ] Treat imported content as untrusted text; never execute imported Lua
