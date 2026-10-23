# MacroStudio v1.3.0 release report

Prepared 2026-10-07; updated 2026-10-23 for optional Legacy appearance and Retail
12.1.5. The accepted Warcraft design remains the default. The owner authorized
GitHub publication on 2026-10-23 using the stable `v1.3.0` release tag and the
unchanged tested ZIP. Release page:
https://github.com/Baeleaf/MacroStudio/releases/tag/v1.3.0

Live release smoke tests were signed off by the owner on 2026-10-23 after
testing the exact packaged build. The development copy has been restored and
verified against its pre-test snapshot. The tested ZIP is retained unchanged.

## Exact upload artifact

- Filename: `MacroStudio-v1.3.0.zip`
- Local path: `dist/MacroStudio-v1.3.0.zip`
- Size: **63,192 bytes**
- SHA-256: `c4068777af80c5d7cfc105e724b289e33e25527744da62abaf62e50b48c7104d`
- Contents: **23 files** under one `MacroStudio/` root: 20 Lua modules, the TOC,
  one original runtime TGA and the MIT license.
- Intended upload type: Release, World of Warcraft Retail, game version 12.1.5.
- TOC Interface: `120105`; installed Retail client observed: `12.1.5.70448`.
- Upload the ZIP itself, not the surrounding `dist/` folder or JSON manifest.

The single root directory matches `MacroStudio.toc`, as required by
[CurseForge's WoW packaging guidance](https://support.curseforge.com/support/solutions/articles/9000196615).
Choose the matching Retail game-version designation when submitting later.
CurseForge server validation/moderation follows its automatic packaging flow
and is separate from the tested local artifact and GitHub publication.

The artifact excludes tests and cached Blizzard audit sources, build scripts,
editable SVG and PNG exports, old logos, screenshots, development documentation,
release reports, manifests, Git/GitHub files, credentials and SavedVariables.
The required MIT notice was missing from the old local packaging script; it is
now included. No external runtime libraries or copied Blizzard art are shipped.

## Exact archive manifest

```text
MacroStudio/
  MacroStudio.toc
  LICENSE
  Core.lua
  Database.lua
  Access.lua
  MinimapButton.lua
  MacroRepository.lua
  CharacterMacroLibrary.lua
  ActionBarRepository.lua
  MetadataRepository.lua
  Search.lua
  Utils/Helpers.lua
  UI/WarcraftTheme.lua
  UI/LegacyTheme.lua
  UI/Dialogs.lua
  UI/IconPicker.lua
  UI/MacroDialog.lua
  UI/Editor.lua
  UI/MacroList.lua
  UI/Sidebar.lua
  UI/Settings.lua
  UI/MainFrame.lua
  Media/MacroStudioIcon.tga
```

Per-file sizes and SHA-256 digests are recorded separately in
`dist/MacroStudio-v1.3.0.manifest.json`; that development manifest is not inside
the upload artifact.

## Version and saved-data audit

`MacroStudio.toc` and `Core.lua` both declare `1.3.0`. The title reads the runtime
constant, so it displays `v1.3.0`. The packaging command and ZIP name use the same
version; packaging refuses mismatched requested, TOC or runtime versions. The
preflight expectations were updated. No other current hardcoded `1.2.0`
version metadata remains. Historical changelog and milestone references to
1.2.0 and 1.2.0-r3 remain intact.

The SavedVariables name remains `MacroStudioDB` and the database schema remains
**4**. No database reset, new migration or macro repository behavior change is
part of v1.3.0. The additive `settings.appearance` preference defaults to
`warcraft` unless a valid saved choice already exists. `legacy` selects the
original blue/gray presentation after reload. Both appearances use the same
feature controllers and repositories. Automated tests preserve prior settings, window geometry,
metadata, categories, history and character-library records, including repeated
initialization and explicit access preferences. Live saved-data preservation
is recorded as passed with the owner's smoke-test sign-off below.

## Automated validation results

| Check | Result |
| --- | --- |
| Complete existing suite: `py tests/preflight.py` | PASS |
| Lua 5.1 compilation of all addon Lua sources | PASS |
| Full TOC construction and UI interaction suite, invoked through `tests/ui_smoke.py` | PASS in both Warcraft and Legacy |
| Appearance default, saved Legacy startup, invalid preference fallback, pending/canceled changes and explicit reload | PASS |
| Appearance reload preserves data and blocks unsaved editor drafts / open macro-creation forms | PASS |
| Macro create/edit/save/delete, exact targets, duplicates, combat and external-change safety | PASS in stubbed Retail APIs |
| Favorites, search, category create/assign and new rename/delete preservation regression | PASS |
| Live/current/offline-library navigation, copy guards and snapshot preservation | PASS in headless suite |
| Settings, slash toggles, launchers, native editor focus, modal cleanup and multi-page picker scroll | PASS in headless suite |
| Schema migration/idempotence and saved-data preservation fixtures | PASS |
| Package build: `scripts/package.ps1 -Version 1.3.0` | PASS |
| Exact archive verification: `py tests/release_artifact.py 1.3.0` | PASS |
| ZIP CRC integrity, one matching root/TOC, portable paths, no duplicates or unexpected files | PASS |
| Every packaged byte matches the validated source; TOC/runtime versions and license checked | PASS |
| Packaging rejects an old requested version rather than emitting a mislabeled ZIP | PASS |
| `git diff --check` | PASS |

`tests/preflight.py` is the complete existing suite entry point; it invokes
`run_ui_smoke`, rather than requiring a separate standalone run of that module.
The added artifact verifier writes the digest manifest after checking the ZIP.
The complete UI behavior suite runs twice, once per appearance. Current
Blizzard source definitions for the button/window templates and scroll APIs
were rechecked, including
[`UIPanelButtonTemplate` and `PortraitFrameTemplate`](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml)
and [ScrollUtil](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Shared/Scroll/ScrollUtil.lua).
Changing the TOC removes the stale compatibility declaration for 12.1.5; it
does not establish a real-client functional or taint certification.
The separate live results below are owner-reported, rather than inferred from
that metadata change or the automated suite.

## Live release smoke-test checklist

**Status: PASS — owner sign-off received 2026-10-23.** After testing the exact
installed release package, the owner reported, "Testing looks good," and
explicitly instructed that the release smoke tests be marked passed. The
checklist results below record that sign-off; the agent did not independently
observe the in-game steps or capture error logs. No additional observations or
test measurements are implied.

The tested artifact was `MacroStudio-v1.3.0.zip`, SHA-256
`c4068777af80c5d7cfc105e724b289e33e25527744da62abaf62e50b48c7104d`.
The temporary installation contained exactly its 23 files, each verified against
the package manifest. The entire original 102-file development tree, including
Git history and uncommitted work, was restored byte-for-byte before updating
these release records. SavedVariables were not changed by installation or
restoration. The tested installation and original backup remain preserved
outside AddOns. The ZIP has not been rebuilt since the owner's test.

The following steps are retained as the release smoke procedure, with all
results marked passed on the owner's explicit instruction:

- [x] **Addon load:** extract the single `MacroStudio` folder into Retail's
  `Interface/AddOns`, launch/login, confirm enabled addon version 1.3.0 and no
  dependency/load error or out-of-date warning on 12.1.5. No startup window should open unexpectedly.
- [x] **`/ms` open/close:** invoke `/ms` twice and confirm one shared window opens
  then closes. Reopen and confirm the title shows `v1.3.0`.
- [x] **`/reload`:** reload with MacroStudio enabled, reopen with `/ms` and check
  the title, editor, dialogs and launcher behavior remain functional.
- [x] **Create/edit/save/delete macro:** create a disposable Account macro and
  a disposable current-character macro. Edit name, icon and body, save, and
  compare against Blizzard's Macro UI. Delete each through confirmation; verify
  neighboring macros remain intact. Cancel a delete once as well.
- [x] **Favorite:** favorite a disposable macro, open Favorites and verify it
  appears; toggle it off and verify removal without modifying its native body.
- [x] **Navigation:** browse All, Account, Current Character and character
  library entries. Confirm offline entries are read-only. Switch characters and
  confirm snapshots remain associated with the correct character.
- [x] **Category create/rename/delete:** create a temporary category, assign a
  disposable macro, rename it and verify assignment/filter updates. Delete it
  through confirmation; confirm only the category/assignment is removed and
  the macro, other categories, Favorites and tags remain intact.
- [x] **Settings:** open/close using the footer control and `/ms settings`.
  Toggle minimap visibility and slash takeover, verify effects, restore the
  original preferences and confirm persistence after reload.
- [x] **Appearance:** new and upgraded installs without an explicit preference
  should use Warcraft. Choose Settings → Appearance → Legacy, confirm it does
  not reload automatically, then click Reload UI. Confirm the original blue/gray
  panels and title, all dialogs and macro workflows work. In Legacy, Settings
  is in the title area. Select Warcraft and reload again to verify the accepted
  design returns. Repeat with an unsaved editor draft or open macro-creation
  form: the Settings reload action must be blocked and the data must remain.
  Repeat the functional checklist in both appearances.
- [x] **List scrolling:** use enough macros/categories/library entries to
  overflow the viewport. Check wheel, track, thumb and arrows, top/bottom limits
  and row selection after scrolling. Also check multiline editor scrolling.
- [x] **Existing saved data:** compare upgrade data before/after reload:
  categories, Favorites, tags, character snapshots, window geometry, minimap
  position and Settings. Confirm no unexpected reset or native macro change.
- [x] **Absence of Lua errors:** complete every step with script errors enabled;
  confirm no MacroStudio errors, blocked-action/taint warnings or failed frames.
  A silent headless run does not establish this real-client result.

## Release notes for submission

MacroStudio 1.3.0 introduces a Warcraft-native workbench with a sculpted metal
frame, textured charcoal interior and recessed macro editor. An original
scroll-and-quill medallion anchors the title. Library, Macros and Macro Editor
share one inset with engraved separators, native button states, physical scope
tabs and full scrollbars. Secondary dialogs and footer Settings follow the same
game UI treatment. The final polish improves title emphasis, metadata
readability and editor depth.

Warcraft is the default. Players can choose the original blue/gray Legacy
appearance in Settings and apply it with Reload UI. The preference is saved
without resetting macros or organization data. Retail compatibility now targets
WoW 12.1.5 (Interface 120105).

Existing macro features, safeguards and schema 4 saved data are retained. This
release adds no import/export, macro history or other new macro-management
features. Full versioned notes are in `CHANGELOG.md`.

## Remaining blockers and handoff

The exact v1.3.0 ZIP is built and ready for manual CurseForge submission from a
metadata, contents and automated-validation standpoint. There are **no known
automated-test or package blockers**.

The final packaged-addon live smoke checklist is passed by owner sign-off.
There are no remaining known smoke-test or artifact blockers. No additional
visual redesign or visual-approval gate is requested. The v1.3.0 ZIP is retained
unchanged for the authorized GitHub release upload.

The existing active GitHub push webhook targets CurseForge project `1646556`.
Publishing the stable `v1.3.0` tag is authorized to trigger its automatic
packaging. The webhook configuration is retained. GitHub publishes the exact
tested ZIP as a release asset; CurseForge builds its own archive from the tagged
source using `.pkgmeta`. Its final processing status must be verified separately.
