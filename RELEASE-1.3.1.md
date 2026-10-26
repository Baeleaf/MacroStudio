# MacroStudio v1.3.1 release preparation

Prepared 2026-10-25 at the owner's request as a public bugfix release.

## Scope

Based on the v1.3.0 runtime, with the icon save normalization fix, icon search, and all eight raid markers. Includes the subsequent manual release-note packaging configuration. The unfinished 1.4 macro linter is excluded; its development checkout is preserved.

Core.lua and MacroStudio.toc both declare `1.3.1`. Interface remains `120105`; SavedVariables remains `MacroStudioDB` and schema remains 4.

## Upload artifact

- Filename: `MacroStudio-v1.3.1.zip`
- Size: 64,910 bytes
- SHA-256: `dd9b302291cb81c2a845cf4812a216d8fcb4ef22e8eb4467e2802b8cf5d79ce7`
- Contents: 23 runtime/license files under a single `MacroStudio/` directory.
- Intended upload: Release; World of Warcraft Retail 12.1.5.
- Upload the ZIP itself. The JSON manifest and release notes are separate reference files.

## Verification

- Full source preflight, native mutation regressions, icon normalization/readback regression cases, and full UI tests passed in Warcraft and Legacy appearances.
- Archive integrity, exact contents, displayed/manifest versions, source byte parity, preserved MIT license, and absence of unreleased linting verified.
- Live-client retest of the friend's reported icon-save failure remains pending. No live sign-off is claimed.
- No remote tag, GitHub release, or CurseForge upload was created by this preparation.
