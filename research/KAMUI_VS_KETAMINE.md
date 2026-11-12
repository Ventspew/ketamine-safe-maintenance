# KAMUI vs Ketamine — wallpaper (application logic)

Evidence from public trees only. Install paths that depend on privileged container access are noted as **restricted**, not ported.

| Component | Ketamine (1.x public) | KAMUI (kamui-escape) | Difference | Action |
|---|---|---|---|---|
| Wallpaper import | Copy `.tendies` into app Documents (`PosterBoardManager.importTendies`) | Copy into `Documents/tendies` (`PosterBoardVC`) | Same idea: sandbox-local store first | Keep; shared pattern |
| Pack format | ZIP magic `PK`; `.tendies` | `.tendies` / `.zip` | Compatible | Validate ZIP before apply |
| Descriptor detection | Folder containing `com.apple.posterkit.provider.descriptor.identifier`; video parent → Photos provider | `BQApplyTendies` writes descriptor folders into PosterBoard providers | Same marker file convention | SafeCore `WallpaperDescriptorInspector` |
| Resource resolution | Needs PosterBoard app container UUID (`pbHash` / `findPosterBoardHash`) | `BQFindPosterBoardContainer` via privileged core | Both need privileged resolve for install | Diagnostics only; no new discovery |
| PosterBoard open | `LSApplicationWorkspace` private API | `BQOpenPosterBoard` | Same goal | Unchanged |
| Apply UX | Install queue + respring helper | Apply All + explicit Open → kill → Respring steps | KAMUI instructions clearer | Document in diagnostics guide |
| Cache handling | `@AppStorage("pbHash")` | Settings probe for PB path | Both cache/discover identifiers | Validate UUID format |
| Error reporting | Generic alerts | Per-pack errors aggregated | KAMUI richer | Improved dialer/diagnostics logging in this fork |
| Reset | Wipe descriptors under extension store | `BQResetPosterBoard` | Similar | Restricted |

**Transferable safely:** tendies ZIP validation, descriptor marker checks, clearer post-apply instructions, UUID cache validation.  
**Not transferred:** privileged container open/write implementations.
