# Routing and Links

## Route Contracts
Defined in `/Packages/Routing/Sources/Routing/AppRoute.swift`:
- `offers`
- `offerDetail(id:)`
- `inbox`
- `inboxMessage(id:)`
- `wallet`

## Supported Entry Points
### Custom URL Scheme
- Scheme: `retailrescue`
- Examples:
  - `retailrescue://offers`
  - `retailrescue://offers/detail/offer-123`
  - `retailrescue://inbox/message/msg-9`
  - `retailrescue://wallet`

### Universal Links
- Domain: `retailrewardsrescue.app`
- Examples:
  - `https://retailrewardsrescue.app/offers`
  - `https://retailrewardsrescue.app/offers/detail/offer-123`
  - `https://retailrewardsrescue.app/inbox/message/msg-9`
  - `https://retailrewardsrescue.app/wallet`

## iOS Wiring
- URL scheme registration: `/App/Resources/Info.plist`
- Associated domains entitlement: `/App/Resources/RetailRewardsRescue.entitlements`
- Runtime routing handlers:
  - `/App/Application/SceneDelegate.swift`
  - `/App/Coordinator/AppCoordinator.swift`

## AASA Hosting Notes
Host `apple-app-site-association` at:
- `https://retailrewardsrescue.app/.well-known/apple-app-site-association`

Minimal example:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.evan.retailrewardsrescue",
        "paths": [
          "/offers/*",
          "/inbox/*",
          "/wallet"
        ]
      }
    ]
  }
}
```

## Failure Handling
- Invalid hosts/paths return `nil` in parser.
- Nil route is ignored without crash.
- Malformed message deep links are blocked in message detail screen with safe fallback text.
