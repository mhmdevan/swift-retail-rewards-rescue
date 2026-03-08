Routing module.

Includes:
- strongly typed app route contracts (`AppRoute`)
- parser for:
  - custom scheme links (`retailrescue://...`)
  - universal links (`https://retailrewardsrescue.app/...`)

Invalid hosts/paths are rejected safely (`nil` route).
