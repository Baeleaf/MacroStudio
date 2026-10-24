# Contributing to MacroStudio

MacroStudio is not accepting code contributions or pull requests right now. The best way to help is by sharing bugs, ideas, and feedback through GitHub Issues.

## Development build identification

Every development build handed off for in-game testing must use an explicit prerelease version in both `Core.lua` (`MacroStudio.VERSION`) and `MacroStudio.toc` (`## Version`). For example, `1.4.0-dev.ms10.1` identifies Milestone 10 development build 1; increment the final build number for subsequent code builds handed to testers. Never display the plain live-release version on an unreleased development build. Keep both values identical; preflight and packaging verify consistency. Only remove the development suffix as part of an explicitly authorized release preparation.

## Found a bug?

[Open a Bug Report](https://github.com/Baeleaf/MacroStudio/issues/new?template=bug_report.yml).

Helpful bug reports include:

- Your MacroStudio version.
- Your WoW version.
- What you were doing.
- What you expected to happen.
- What actually happened.
- The Lua error, if one appeared.
- A screenshot, if it helps explain the problem.

## Have an idea?

[Open a Feature Request](https://github.com/Baeleaf/MacroStudio/issues/new?template=feature_request.yml).

## General feedback?

[Choose an issue form](https://github.com/Baeleaf/MacroStudio/issues/new/choose).
