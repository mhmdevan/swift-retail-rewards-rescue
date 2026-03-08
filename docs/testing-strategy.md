# Testing Strategy

## Pyramid
1. Package unit tests (`swift test`) for domain/data contracts.
2. App unit tests (`xcodebuild test`) for UIKit orchestration seams.
3. UI smoke/accessibility tests for critical user path.
4. Snapshot/performance tests for regression and baseline tracking.

## Unit Tests (SPM)
Covered areas:
- session persistence and launch destination logic
- legacy and modern networking mapping/error normalization
- routing parser contracts
- Core Data saved offers/inbox stores
- saved/expiry business rules

Command:
```bash
./scripts/test.sh
```

## App Unit Tests
Covered areas:
- offer save service behavior
- Objective-C bridge wrapper behavior
- reactive offers feed VM behavior (RxTest + RxBlocking)

Command:
```bash
./scripts/test_app.sh
```

## UI Tests
Covered areas:
- login -> offers -> detail/save -> saved -> inbox -> wallet smoke flow
- accessibility identifier presence for core screens

Command:
```bash
./scripts/test_ui.sh
```

## Snapshot Tests
Covered areas:
- offer card states
- offer detail expired state
- content state empty/error rendering

Approach:
- deterministic view-hierarchy snapshot assertions in `/Tests/SnapshotTests`.

## Performance Tests
Covered areas:
- saved offers fetch latency baseline
- expiry reconciliation latency baseline

Location:
- `/Tests/PerformanceTests/PersistencePerformanceTests.swift`

## CI Gates
GitHub Actions workflow (`/.github/workflows/ci.yml`) runs:
- lint + package tests
- app tests (unit/snapshot/performance)
- UI smoke tests
- artifact upload for logs and `.xcresult`
