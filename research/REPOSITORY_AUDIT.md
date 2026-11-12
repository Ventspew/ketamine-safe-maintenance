# Repository audit

## Source mismatch (critical)

| Artifact | Version | AirLift / exact dialer error string |
|---|---|---|
| Installed beta ([withered.live/ketamine](https://withered.live/ketamine)) | **2.1 beta 1** | Documents AirLift + worse_query; UI error references AirLift + cached container hash |
| Public GitHub [Nouvborne/Ketamine](https://github.com/Nouvborne/Ketamine) | tags **1.0–1.2.1** (HEAD `63466fc`) | **No** AirLift, **no** `worse_query`, **exact error string not present** |
| Local IPAs on this Mac | up to **1.4.2** | strings scan: **no** AirLift / cached-container-hash message |

**Conclusion:** The reported failure comes from **unpublished 2.1b1** sources. Maintenance in this repo targets the **public GPL 1.x tree** plus a safe application-level module (`KetamineSafeCore`). It does **not** reimplement AirLift, worse_query, or container scanning.

## Cloned references (not redistributed)

| Project | URL | Role in audit |
|---|---|---|
| Ketamine | https://github.com/Nouvborne/Ketamine | App under maintenance |
| kamui-escape | https://github.com/murk-sus/kamui-escape | PosterBoard UX/format comparison |
| bad_query / worse_query | forcequitOS | Documented as restricted; not modified here |

## License

Ketamine: GPL-3.0. This maintenance tree preserves LICENSE and attribution.
