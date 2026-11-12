#!/usr/bin/env bash
set -euo pipefail
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Library/Developer/CommandLineTools}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/patches/KetamineSafeCore/Sources/KetamineSafeCore"
OUT="$(mktemp -d)/safecore"
mkdir -p "$OUT"

swiftc -module-name KetamineSafeCore -parse-as-library \
  -emit-module -emit-module-path "$OUT/KetamineSafeCore.swiftmodule" \
  -emit-library -o "$OUT/libKetamineSafeCore.dylib" \
  "$SRC"/ContainerIdentity.swift \
  "$SRC"/ThemePackageInspector.swift \
  "$SRC"/WallpaperDescriptorInspector.swift \
  "$SRC"/FeatureAccessState.swift \
  "$SRC"/DiagnosticLog.swift

# Minimal assertions (full XCTest suite lives under patches/KetamineSafeCore/Tests)
cat > "$OUT/Harness.swift" <<'EOF'
import Foundation
import KetamineSafeCore
var f = 0
func expect(_ c: @autoclosure () -> Bool, _ m: String) { if c() { print("PASS:", m) } else { print("FAIL:", m); f += 1 } }
expect(ContainerIdentity.classify("") == .empty, "empty")
expect(!FeatureAccessState.dialerThemeState(cachedHash: nil, privilegedDiscoveryAvailable: false).isReady, "blocked")
do { _ = try ThemePackageInspector.inspect(data: Data("x".utf8)); expect(false, "zip") } catch { expect(true, "zip") }
print(f == 0 ? "ALL PASSED" : "FAILED \(f)")
exit(f == 0 ? 0 : 1)
EOF

swiftc -I "$OUT" -L "$OUT" -lKetamineSafeCore \
  -Xlinker -rpath -Xlinker "$OUT" \
  -o "$OUT/harness" "$OUT/Harness.swift"
"$OUT/harness"
