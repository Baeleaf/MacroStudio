# MacroStudio Roadmap

Version 0.1.0 is Milestone 1 only: a safe proof-of-concept editor for existing Blizzard-native macros. Later milestones stay unimplemented until the preceding work has been tested in game.

## Milestone 1 — Native macro editor

- [x] Standalone addon and Git repository
- [x] Large movable, resizable window
- [x] Account/character macro enumeration
- [x] Multiline body editor and live 255-character counter
- [x] Dirty state, Save, Revert, and discard confirmation
- [x] Combat lockdown behavior that preserves drafts
- [x] Event-driven and manual refresh
- [x] SavedVariables foundation
- [x] Windows Junction tooling and manual test plan

## Milestone 2 — Organization

- [ ] Virtual folders/categories and category management
- [ ] Favorites independent of categories
- [ ] Multiple tags plus one optional primary category
- [ ] SavedVariables metadata storage and migration
- [ ] Careful metadata reconciliation across macro changes
- [ ] Duplicate-name detection and warnings
- [ ] Per-macro notes and last-edited timestamps
- [ ] Preserve unresolved metadata for manual reconciliation rather than guessing

Candidate categories include Favorites, Mythic+, Raid, PvP, Utility, Healing, Class, Profession, and Misc. These remain MacroStudio metadata and never alter Blizzard's storage model.

## Milestone 3 — Search and filtering

- [ ] Search macro name and body
- [ ] Search category and tags
- [ ] Basic filters such as `scope:account`, `scope:character`, `tag:M+`, and `favorite:true`
- [ ] Favor simple, useful filtering before designing a query language

## Milestone 4 — Full macro management

- [ ] New and Duplicate Macro
- [ ] Rename and icon picker
- [ ] Account/character scope selection
- [ ] Delete with explicit confirmation
- [ ] Capacity warnings
- [ ] Investigate a recoverable Trash concept
- [ ] Warn on destructive operations when a macro is used on action slots

All operations must honor combat protection, native name/body/capacity limits, and duplicate names.

## Milestone 5 — Backups and history

- [ ] Snapshot name, body, icon, scope, and timestamp before MacroStudio changes/deletes
- [ ] Browse versions by human-readable time
- [ ] Explicit restore flow
- [ ] Sensible retention limits for SavedVariables growth
- [ ] Trash for macros deleted through MacroStudio, if feasible

## Milestone 6 — Parser and conservative linter

- [ ] Deterministic macro tokenizer/parser
- [ ] Character-budget warnings
- [ ] Possible duplicate conditionals or commands
- [ ] Malformed bracket warnings
- [ ] Suspicious spell/item references where an API can support the check
- [ ] Maintainable syntax highlighting for commands, conditions, targets, and arguments

The linter must be presented as advisory, not an infallible validator. It must not silently rewrite working macros.

## Milestone 7 — Action-bar awareness

- [ ] Show raw action slots that reference the selected macro
- [ ] Map slots to human-friendly bar/button descriptions only where reliable
- [ ] Account for paging, forms/stances, overrides, possess states, and third-party action-bar presentation
- [ ] Investigate keybinding awareness later

## Milestone 8 — Templates and snippets

- [ ] Previewable macro templates such as Mouseover Heal, Focus Interrupt, and Arena Target
- [ ] Insertable snippets such as `[@cursor]`, `[@player]`, and `[mod:shift]`
- [ ] Insert snippets at the editor cursor
- [ ] Keep templates as drafts until the user explicitly creates a native macro

## Milestone 9 — Optimization helpers

- [ ] Suggest conservative character-count reductions
- [ ] Display estimated savings and resulting length
- [ ] Explain each proposed change
- [ ] Never silently apply or claim semantic equivalence without sufficient certainty

## Milestone 10 — Import and export

- [ ] Individual macro sharing
- [ ] Category/template packs
- [ ] Metadata backup/export
- [ ] Preview imports before any native write
- [ ] Treat imported content as untrusted text; never execute imported Lua
