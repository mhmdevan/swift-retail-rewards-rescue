# Demo Script (10-12 Minutes)

## 1. Positioning (1 min)
- “This is a UIKit-first legacy rescue app, not a greenfield sample.”
- “I kept legacy patterns where realistic and added modern seams incrementally.”

## 2. Core User Flow (4 min)
1. Login with demo credentials.
2. Open Offers feed:
   - loading/empty/error/content support
   - paginated cards with cached images
3. Open Offer detail and save/unsave.
4. Open Saved tab:
   - persisted Core Data list updates automatically
5. Open Inbox:
   - local-first rendering
   - unread/read transition
6. Open Wallet:
   - SwiftUI island embedded in UIKit

## 3. Legacy Interop + Routing (2 min)
- Open Membership tab and explain Objective-C barcode formatter bridge.
- Trigger deep-link examples from Diagnostics screen.
- Show custom scheme and universal-link path parity.

## 4. Operational Maturity (2 min)
- Open Diagnostics:
  - app/build/runtime metadata
  - background refresh trigger
  - MetricKit summary
  - cache clear
  - test non-fatal capture and debug crash trigger

## 5. Engineering Quality (1-2 min)
- Show test structure (package/app/ui/snapshot/performance).
- Show CI workflow and Fastlane lanes.
- Point to docs: architecture, migration, observability, release checklist.
