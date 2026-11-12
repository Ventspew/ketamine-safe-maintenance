# iOS 27 compatibility notes

## Product page (2.1b1) vs public source (1.x)

withered.live lists **27.0 stable / 27.0.1** customization via worse_query + AirLift. Public Nouvborne tree still gates “full” support around **27.0 beta 4** (`DeviceCompatibility.newestSupportedBuild = 24A5390f`) and uses **bad_query** only.

On a factory-reset iPhone 15 Pro on **27.0.1**:

- Expect empty `phoneHash` / `pbHash` AppStorage
- Theme **preview/validation** can work with SafeCore
- Theme **installation** remains restricted without a working privileged discovery/write path for that exact build — this fork does not supply one

## Feature matrix (this maintenance fork)

| Feature | Authorized / local | Restricted |
|---|---|---|
| Theme package inspect (ZIP/PNG/key summary) | Yes | |
| Diagnostics screen + exportable logs | Yes | |
| UUID format validation for cached hashes | Yes | |
| Dialer PNG install into Phone container | | Yes |
| PosterBoard descriptor install | | Yes |
| MobileGestalt edits | | Yes |
| Container UUID discovery / scanning | | Yes |
