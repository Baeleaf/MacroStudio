# MacroStudio Roadmap

The roadmap records shipped capabilities and likely future directions; unchecked items are not commitments or release dates.

## Shipped in 1.0.0

### Native macro editor and safety

- [x] Movable, resizable Account and Character macro workspace.
- [x] Native multiline caret, selection, keyboard navigation, copy/paste, and scrolling.
- [x] Live 255-character validation, dirty state, Save, Revert, and discard confirmation.
- [x] Combat-aware native writes with action-time target and eligibility revalidation.
- [x] Automatic event synchronization, clean external reloads, and protected dirty conflicts.
- [x] Native Account and Character macro creation and confirmed exact-target deletion.

### Organization and search

- [x] Virtual categories with create, rename, delete, assign, and remove workflows.
- [x] Multiple tags and Favorites.
- [x] All, Account, Character, Favorites, and category navigation.
- [x] Case-insensitive live search across names, complete bodies, assigned categories, and tags.
- [x] Search/navigation combinations that preserve the selected macro and dirty draft.
- [x] Opaque metadata records with conservative reconciliation against Blizzard macros.

### User experience

- [x] Movable modal macro creation with native icon selection and capacity feedback.
- [x] Complete modal input blocking, Escape cleanup, combat preservation, and focus restoration.
- [x] Window position and size persistence.
- [x] Event-driven synchronization with `/ms refresh` retained only as a fallback.

## Public release checklist

- [x] Public-facing README, changelog, contributing guide, and issue forms.
- [x] Runtime-only release packaging script and local 1.0.0 release candidate.
- [x] MIT license present and included in the v1.3.0 distribution.
- [ ] Add privacy-reviewed screenshots.
- [x] Final v1.3.0 packaged-addon smoke tests passed by owner sign-off on 2026-10-23; see `RELEASE-1.3.0.md`.
- [x] Reviewed commit-author identity (public GitHub noreply address), public repository, default branch and existing CurseForge webhook for v1.3.0.
- [x] Public GitHub repository and earlier version tags/releases are established; owner authorized v1.3.0 publication on 2026-10-23.

## High priority: native action-bar workflows

- [x] Investigate current Retail macro pickup, cursor, drop, and secure-action restrictions.
- [x] Drag Blizzard-native macros from MacroStudio onto action bars outside combat.
- [x] Preserve protected-action rules and hand off a native macro cursor payload without hardcoded action-bar frames.
- [ ] Validate third-party action-bar compatibility with public testers.
- [x] Inspect native action slots and show exact saved-macro usage counts and raw slot locations.
- [ ] Report associated keybinds only when the result is reliable.

## Shipped in 1.2.0: cross-character macro library

- [x] Store complete account-wide, GUID-keyed snapshots of Character macros for characters seen by MacroStudio.
- [x] Browse all known characters or one character with live current-character data and read-only offline snapshots.
- [x] Copy an offline snapshot into the current character through the existing native creation safeguards.
- [x] Search offline macro names, complete bodies, character names, and realms without native rescans.
- [x] Forget one offline snapshot with confirmation while preserving Blizzard macros and unrelated MacroStudio data.

## Next active milestone: macro linting and diagnostics (Milestone 10)

MacroStudio's next active feature after 1.3.0 is an **advisory, read-only linter** for native WoW macro text. The implementation checklist and test cases are tracked in [issue #1](https://github.com/Baeleaf/MacroStudio/issues/1). This work is independent of the unmerged Milestone 9 import/export branch.

- [x] Implement a deterministic macro-aware analyzer for the current saved/draft body; return severity, line, column, and explanatory message without running or rewriting macro text (unreleased MVP).
- [x] Detect leading conditional-bracket errors on `/cast`, `/use`, `/castsequence`, missing action arguments, and duplicate `#showtooltip`. Preserve valid `[]` fallbacks, advanced conditionals, custom addon commands, and literal Lua strings.
- [x] Show a compact summary and paged tooltip for all findings before Save, through the shared Warcraft and Legacy editor.
- [x] Keep diagnostics advisory; existing native length, combat, exact-target, and dirty-draft validations remain the sole Save blockers.
- [x] Cover the linter and editor integration in Lua 5.1 headless tests under both appearances.
- [ ] Complete the Milestone 10 Retail in-game checklist in `TESTING.md` before release.
- [x] State limitations honestly: static linting cannot prove a spell is usable or that a macro will function in live combat.

This incorporates the plan from `docs/priority-macro-linting-20261024` (`a7c78b0`); do not apply that roadmap change again. Implementation and headless checks are complete; live-client acceptance remains pending.

Follow-on editing assistance can add compile-only Lua syntax checks (never execute imported or typed Lua), token coloring, snippets, and opt-in optimization after feasibility and safety are established.

## Portability, backups, and history (Milestone 9 workstream)

The existing `feature/import-export` branch contains substantial implementation and tests for import/export, previews, conflict choices, and untrusted-data validation. It has **not** been merged into `main` or released; review and rebase/test it independently before marking its work complete on the release roadmap.

- [ ] Full-profile import/export.
- [ ] Selective macro and metadata import/export.
- [ ] Categories-only import/export.
- [ ] Preview incoming changes and conflicts before writing native macros.
- [ ] Treat imported content as untrusted text and never execute it as Lua.
- [ ] Snapshot/version history, backups, and recoverable deletion with sensible retention.

## Editing assistance

- [ ] Previewable templates and cursor-position snippets.
- [ ] Maintainable syntax highlighting and richer editor navigation (after the linting MVP).
- [ ] Explained, opt-in character-count reduction suggestions.
- [ ] Advanced search fields such as scope, tag, category, Favorite, body, and name.

Editing assistance must never silently rewrite a working macro or claim semantic equivalence without sufficient certainty.

## Shipped in 1.2.0: native macro identity editing

- [x] Edit an existing native macro's name and icon after creation through one safely revalidated `EditMacro` operation.
- [x] Treat name, saved icon, and body as one draft with unified Save and Revert behavior.
- [x] Preserve duplicate-name and action-bar identity safety through native identity edits.
- [x] Recover external conflicts conservatively and clear selection after external deletion rather than target a neighbor.
- [x] Present offline snapshot names and icons as display-only while keeping body text selectable and copyable.

## Native macro management

- [ ] Change an existing macro's scope.
- [ ] Duplicate a native macro.
- [ ] Warn when destructive changes affect macros currently placed on action slots.

## Shipped in 1.2.0: default macro window and access settings

- [x] Route `/m` and `/macro` to MacroStudio by default while preserving `/ms` and `/macrostudio`.
- [x] Restore the exact captured Blizzard handler immediately when takeover is disabled.
- [x] Keep Blizzard's native Macro UI available through `/ms blizzard`.
- [x] Provide a compact settings panel with persistent access and launcher preferences.
- [x] Route the title-bar button, `/ms settings`, and minimap right-click through one frame-state-aware Settings controller.
- [x] Add an optional draggable minimap launcher with remembered radial position.
- [x] Register through the supported AddOn Compartment TOC metadata without manipulating Blizzard frames.
- [x] Detect pre-existing slash ownership conservatively and retain `/ms` instead of entering a command conflict.

## MacroStudio macros and named styles (1.4.0)

- [x] Store shared MacroStudio definitions independently of Blizzard slots, with stable IDs, revision-checked edits, and a migration from the original split library.
- [x] Share editor, icon search, Favorites, categories, tags and search with native macro workflows.
- [x] Bind saved macros directly to per-character keyboard assignments through secure buttons; protect combat and override contexts.
- [x] Offer Warcraft (default), Legacy, Emerald, Violet and Ember through one mutually exclusive radio selector, with no separate Appearance section.
- [x] Cover native-slot isolation, both native count limits, key isolation/cleanup and named styles in headless checks.
- [x] Drag saved macros from list rows and editor icons; bridge shared macros to reusable native action-bar copies with guarded synchronization.
- [x] Move keybinding to an inline themed button below Tags, with readable key labels, immediate keyboard/mouse/wheel capture, right-click clearing and Esc cancellation.
- [x] Copy offline snapshots into Current Character, Account Macros or MacroStudio Macros using one themed dropdown, with independent capacity and stale-source guards.
- [x] Promote the completed feature build to the 1.4.0 release and prepare readable GitHub/CurseForge release notes.
- [ ] Finish the recorded live-client checklist; automated checks do not verify actual key routing, native drops, or taint.
- [ ] Evaluate mouse/hovercast separately after keyboard execution is accepted.
