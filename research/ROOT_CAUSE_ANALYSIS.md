# Root cause — Phone dialer “cached container hash”

## Reported (2.1 beta 1) message

```
Could not update theme

Phone dialer has no cached container hash.
AirLift can't scan /var/mobile/Containers,
so the bundle's UUID has to come from a
past bad_query or Nugget session.
```

Exact string is **not** in public Nouvborne/Ketamine 1.x. Behavior is reconstructed from the beta product page + analogous 1.x code.

## Public 1.x call chain (audited)

1. `PasscodeThemeView.apply` (`CustomizationView.swift`)
2. Reads `@AppStorage("phoneHash")`
3. If empty → `BadQuery.findMobilePhoneHash()` (privileged enumeration)
4. `PasscodeThemeManager.applyTheme` writes under  
   `/var/mobile/Containers/Data/Application/<uuid>/Library/Caches/TelephonyUI-10`

## Classification of the failure

| Hypothesis | Verdict |
|---|---|
| Incorrect theme assets (`colored_numbers`) | Unlikely — UI already reported `10 images · 10 keys styled` |
| Stale UUID reused after reset | Possible if settings survived; factory-reset + new device setup usually clears AppStorage |
| Missing configuration / empty cache | **Primary** — no stored Phone container UUID after reset |
| Misleading error | 2.1 message correctly states AirLift cannot *scan*; still a hard stop for install |
| OS permission restriction | **Yes** — ordinary apps cannot list other containers; discovery needs a privileged path |

**Root cause category:** missing cached identifier after reset + no authorized scan path in-app. Not a bad PNG package.

## Safe fix shipped here

- Validate theme packages without installing
- Classify empty / invalid / present cache states
- Refuse path construction from non-UUID values
- Surface accurate diagnostics instead of a generic failure
- **Do not** add sandbox escapes or UUID guessing
