# Foreground/Background Sync Policy

## Objective
Avoid duplicate refresh work while keeping offers/inbox state reasonably fresh.

## Triggers
- Foreground trigger: on scene active.
- Background trigger: BGProcessingTask handler.
- Manual trigger: diagnostics screen action.

## Throttling
Implemented in `/App/Platform/Background/BackgroundRefreshManager.swift`.

- Foreground TTL: 5 minutes
- Background TTL: 30 minutes
- Manual diagnostics trigger: no throttle
- Duplicate guard: if one refresh is in progress, additional triggers are ignored

## Pipeline Order
1. Fetch latest offers metadata (legacy repository path).
2. Reconcile expired saved offers.
3. Merge inbox updates.
4. Record last successful refresh timestamp.
5. Log structured success/failure event and capture non-fatal error when needed.

## Safety
- Failures do not mutate session state.
- Partial pipeline failures are logged and surfaced via diagnostics.
- BG task rescheduling is always attempted before pipeline execution.
