# Retail Rewards Rescue Product Brief

## Target User
Retail loyalty program members who regularly browse promotional offers, save deals for later use, and check rewards/status from their phone during shopping.

## Core Flows
1. User signs in (or restores session) and lands in the primary tab shell.
2. User browses offer feed, opens details, and saves relevant offers.
3. User reviews saved offers offline and sees expiry-aware state.
4. User checks inbox messages and follows message deep links.
5. User opens digital membership card for scanning at checkout.
6. User accesses rewards wallet (SwiftUI island inside UIKit shell).

## Included Features
- Authentication with persisted session and optional biometrics
- Offers feed (pagination + loading/empty/error states)
- Offer detail and save/unsave flow
- Saved offers offline persistence
- Inbox with read/unread state and local-first rendering
- Membership card backed by Objective-C bridge logic
- SwiftUI rewards wallet embedded in UIKit
- Deep links + universal links routing
- Background refresh and expiry reconciliation
- Diagnostics screen for build/runtime visibility

## Explicitly Excluded
- GraphQL/Apollo
- Firebase
- Realm
- Map/geo tracking features
- VIPER/ReactorKit architecture expansion
- Multiple crash vendors or image pipelines
- Demo-only "keyword stuffing" technologies with no product role

## Migration Story
The app intentionally keeps a UIKit + RxSwift + Alamofire legacy shell while introducing modern seams gradually: SwiftUI is used for one isolated feature (wallet), async/await is used in modernized modules, and Objective-C interoperability remains active where legacy utility logic is still valuable.

## Technical Goals
- Show safe modernization in a mixed architecture
- Keep boundaries explicit between legacy and modern stacks
- Preserve production concerns: persistence, routing, background work, observability, testability
- Ensure changes are incremental and reversible

## Portfolio Positioning
**App 1** demonstrates greenfield modern iOS architecture. **App 2 (this project)** demonstrates how to join and evolve a legacy UIKit production codebase without destabilizing existing user flows.
