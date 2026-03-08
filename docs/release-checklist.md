# Release Checklist

## 1. Build Integrity
1. Run `./scripts/lint.sh`.
2. Run `./scripts/test.sh`.
3. Run `./scripts/test_app.sh`.
4. Run `./scripts/test_ui.sh`.
5. Confirm CI workflow is green on target commit.

## 2. Smoke Validation
1. Login works with demo credentials.
2. Offers feed loads and paginates.
3. Offer detail save/unsave updates feed + saved list.
4. Inbox unread/read and detail route handling work.
5. Wallet SwiftUI screen renders and refreshes.
6. Membership barcode payload renders and invalid payload path is handled.

## 3. Routing Validation
1. Test `retailrescue://offers`.
2. Test `retailrescue://offers/detail/<id>`.
3. Test `retailrescue://inbox/message/<id>`.
4. Test `retailrescue://wallet`.
5. Test one malformed route and verify safe no-crash behavior.

## 4. Background Refresh Validation
1. Confirm BG task registration at startup.
2. Trigger diagnostics manual refresh and verify:
   - offers fetch attempted
   - inbox merge happened
   - last refresh timestamp updated
3. Send app to background and confirm schedule log line.

## 5. Observability Validation
1. Confirm structured logs by category (`offers`, `inbox`, `background`, `routing`).
2. Trigger diagnostics test error capture.
3. Confirm Sentry release/environment tags attached.
4. Confirm MetricKit summary view updates when payload is received.

## 6. Metadata and Packaging
1. Verify app version/build in `Info.plist`.
2. Verify entitlements include associated domains.
3. Verify README and docs reflect current architecture and commands.
4. Verify release notes include key risk and rollback plan.
