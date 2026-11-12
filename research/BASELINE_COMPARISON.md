# Baseline comparison — Ketamine 2.1b1 vs this project

## Verdict

| Item | Distributed beta | This repository (`ketamine-safe-maintenance`) |
|---|---|---|
| Distribution | https://withered.live/ipa/keta21b1.ipa | Built from public Nouvborne 1.x + local patches |
| Marketing version | **2.1b1** | **1.2.2** (project.yml) |
| CFBundleVersion | **6** | CI unsigned IPA from 1.x tree |
| Bundle id | `uk.nouvborne.ketamine` | `uk.nouvborne.ketamine` |
| GitHub source for this revision | **Not published** (Nouvborne/Ketamine tags stop at 1.2.1; no AirLift/worse_query in git) | Wrong baseline for repairing the installed beta |
| AirLift | Present (RSD / installation_proxy / AirTraffic) | **Absent** |
| worse_query | Present | **Absent** |
| Exact dialer error string | Present in binary | Rephrased later in coordinator; not from beta sources |

**Explicit statement:** The distributed **2.1 beta 1 source is unavailable**. This project was **not** reconstructed from that beta. Prior “repairs” on the 1.x tree cannot restore 2.1b1 AirLift/worse_query behavior.

## How 2.1b1 resolves container IDs (from IPA strings)

1. **AirLift allowlisted:** scan via `installation_proxy` over RSD; write hashes into PosterBoard/dialer settings.
2. **AirLift not allowlisted:** refuse scan; require pasted UUID/path or a prior bad_query/Nugget cache.
3. **Dialer assets:** references `/var/mobile/Library/Caches/TelephonyUI-{8,9,10}` in addition to per-container `…/Library/Caches/TelephonyUI-10`.
4. **Exploit gate:** exact build allowlists for bad_query / worse_query / AirLift / MHA.

## Device failures (user)

| Symptom | Meaning |
|---|---|
| Phone / PosterBoard cache empty | No cached UUID after reset; AirLift scan not available or not used |
| `Could not find container for com.apple.PosterBoard` | 1.x `BadQuery.findAppHash` failed (metadata scan) |
| `No usable cached container identifier for com.apple.mobilephone` | Empty cache; discovery did not yield a UUID |

## Application-level deltas vs KAMUI (MIT) usable without new escapes

| Area | Ketamine 1.x (this tree) | KAMUI / 2.1b1 evidence | Fix attempted here |
|---|---|---|---|
| PB search roots | Application, InternalDaemon, PluginKit | + `/var/containers/Data/System` | Add System root |
| PB identity | MCMMetadataIdentifier == bundle id | Presence of `PRBPosterExtensionDataStore` | Prefer PRB validation |
| PB providers | Collections + Photos | + Mercury (+ modern Collections app id) | Add Mercury / modern ids |
| Dialer location | Only `Application/<uuid>/…/TelephonyUI-10` | Also `/var/mobile/Library/Caches/TelephonyUI-*` | Try global TelephonyUI paths |
| Hash discovery backends | bad_query list only | AirLift installation_proxy / worse_query / multi-strategy escape | **Not implemented** (would be new privileged integration) |

Remaining blocker for reliable install on 27.0.1 after factory reset, when listing/tokens fail: **privileged discovery/write backends present in 2.1b1 or KAMUI, not in this 1.x tree.**
