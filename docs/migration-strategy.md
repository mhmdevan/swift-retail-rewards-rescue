# Migration Strategy

## Objective
Modernize a legacy UIKit application incrementally while preserving stability, release cadence, and feature parity.

## Current Baseline
- Legacy shell: UIKit + coordinator navigation + CocoaPods-managed dependencies
- New modules: SPM packages for reusable domain, networking, routing, persistence, and saved-offer policy
- Active migration seam #1: offers domain served by both legacy (Alamofire) and modern (URLSession async/await) repositories
- Active migration seam #2: SwiftUI rewards wallet embedded in UIKit shell
- Active legacy interop seam: Objective-C barcode formatter wrapped behind Swift adapter

## Boundary Contract
1. Legacy UI and app lifecycle remain UIKit-first.
2. New feature/domain code is added as SPM modules where possible.
3. Shared entities/contracts live in module boundaries, not view controllers.
4. Objective-C modules are wrapped behind Swift-facing adapters.
5. New networking capabilities can use async/await without rewriting legacy Rx/Alamofire paths.
6. Reactive legacy features keep RxSwift ViewModel input/output conventions with injectable schedulers.

## Coverage Summary
1. Foundation and shell: bootstrap, navigation, auth/session/biometrics.
2. Product flows: offers feed/detail/save, persistence, saved offers, inbox local-first UX.
3. Modernization seams: Objective-C membership bridge and SwiftUI wallet island.
4. Platform concerns: deep links/universal links, background sync policy, observability and diagnostics.
5. Delivery quality: expanded test matrix, CI/Fastlane automation, release and portfolio docs.

## Risk Controls
- Keep old and new stacks explicitly separated by module contracts.
- Prefer additive migrations over rewrites.
- Add focused tests at each seam (routing, session, reactive state, persistence policy).
- Document every boundary before expanding scope.
- Keep a deterministic demo transport (`URLProtocol`) so both legacy and modern network paths are verifiable without live backend dependency.

## Rollback Strategy
Each migration step is scoped so features can be disabled or reverted without replacing the full app shell:
- Keep legacy routes untouched while introducing new route handlers.
- Keep existing repositories while introducing modernized alternatives.
- Keep UIKit navigation source of truth while embedding isolated SwiftUI features.
- Keep Objective-C module behind one Swift bridge type to isolate interop risk.
