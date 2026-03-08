# Observability Plan

## Goals
- Detect failures early without exposing sensitive user data.
- Make demo flows inspectable during interview/demo sessions.
- Keep observability consistent across foreground and background paths.

## Logging
Implementation: `/App/Platform/Observability/AppLogger.swift`

### Categories
- `app`
- `auth`
- `offers`
- `inbox`
- `membership`
- `background`
- `routing`

### Rules
- Use structured metadata for operational context.
- Redact sensitive fields using `redactedKeys`.
- Keep verbose `debug` logs debug-only.

## Crash/Error Reporting (Sentry)
Implementation: `/App/Platform/Observability/SentryCrashReporter.swift`

### Config
- `environment` tag (`debug`/`release`)
- `release` tag format: `retail-rewards-rescue@<version>+<build>`
- `sendDefaultPii = false`
- DSN from `Info.plist` key `SENTRY_DSN`

### Capture Policy
- Capture non-fatal errors on user-impacting failure paths:
  - offer save/unsave failure
  - inbox refresh failure
  - background refresh pipeline failure

## MetricKit
Implementation: `/App/Platform/Observability/MetricKitObserver.swift`

### Captured
- metric payload count
- diagnostic payload count
- latest payload summary displayed in diagnostics screen

## Diagnostics Screen
Implementation: `/App/Diagnostics/DiagnosticsViewController.swift`

### Surface
- app version/build/build type
- background task identifier + last successful refresh timestamp
- latest MetricKit summary
- route test shortcuts + custom route input
- manual background refresh trigger
- cache clear action
- test error capture
- debug-only crash trigger

## Data Sensitivity
- Do not log auth token, refresh token, raw credentials, or untrusted deep-link payloads in clear text.
- Redact route raw values in routing error logs.
