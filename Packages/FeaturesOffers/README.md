FeaturesOffers module.

Includes:
- shared offer domain entity (`OfferSummary`)
- shared repository contract (`OffersRepository`)
- legacy networking pipeline:
  - request builder
  - retry policy
  - error normalization
  - legacy repository mapping

Used by:
- UIKit offers feed/detail flows
- saved offers and persistence mapping
- modern wallet pathway via shared domain entity reuse
