# Architecture Overview

## Why UIKit-First
The primary objective is legacy maintenance and safe evolution. UIKit-first mirrors the structure of real established iOS apps where navigation, lifecycle, and view stacks are heavily UIKit-driven.

## Why RxSwift
RxSwift is retained in the legacy shell because many production teams still depend on reactive flows. Keeping it in place demonstrates maintainability in a non-greenfield codebase.

## Why Objective-C Bridge
The membership/loyalty domain often carries older utility modules (barcode payload formatting, eligibility parsing, SDK wrappers). Objective-C interop is part of the production reality and must be handled safely.

## Why CocoaPods Root + SPM Modules
- CocoaPods at the app root keeps legacy dependency management believable and compatible with classic UIKit app setups.
- SPM modules are used for newer shared code to reduce coupling and improve incremental migration.
- This combination reflects real migration stages instead of "all-at-once" rewrites.

## Layered Structure
- App Layer: lifecycle, root coordinator, navigation shell, dependency container
- Feature Layer: screen and view model orchestration per user feature
- Domain Layer: entities, use-cases, repository contracts, routing contracts
- Data Layer: network clients, DTO mapping, persistence adapters
- Platform Layer: logging, crash reporting, background tasks, deep link integration

## Current Boundaries
- `App/`: UIKit app shell and coordinator graph
- `Packages/Core`: app-shell domain primitives (session, launch resolution)
- `Packages/DesignSystem`: reusable visual primitives and state views
- `Packages/Routing`: route contracts and parser
- `Packages/FeaturesOffers`: shared offers contracts + legacy repository pipeline
- `Packages/NetworkingModern`: modern async endpoint client + modern offers repository
- `Packages/Persistence`: Core Data stack and storage adapters for saved offers + inbox
- `Packages/FeaturesSavedOffers`: saved/expiry business-rule service
- `Legacy/LegacyNetworking`: Alamofire adapter that fulfills shared legacy networking protocol
- `Legacy/LegacyLoyaltyKit`: Objective-C barcode payload formatter used by membership screen

## Dependency Boundaries
- App target depends on `Core`, `DesignSystem`, `Routing`, `FeaturesOffers`, `NetworkingModern`
- App target also depends on `Persistence` and uses `FeaturesSavedOffers` through app-layer service
- Feature screens consume interfaces from `Core` and shared UI from `DesignSystem`
- Route parsing stays in `Routing` to keep navigation input parsing independent from UIKit
- Offers feature uses RxSwift input/output conventions with scheduler injection for testability
- Legacy transport remains Alamofire-based, while modernized subflows consume URLSession async/await clients through repository contracts
- Shared `AppNetworkError` normalization keeps error handling consistent across old and new paths
- Background refresh and observability are centralized under `App/Platform` and surfaced in diagnostics
