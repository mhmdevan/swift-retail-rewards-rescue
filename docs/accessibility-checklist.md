# Accessibility Checklist

## Scope
Primary flows:
- login
- offers feed/detail
- saved offers
- inbox/message detail
- wallet

## Implemented Baseline
- Stable accessibility identifiers for major controls and lists.
- Form controls use platform-native `UITextField`, `UIButton`, `UISwitch`.
- Content state messaging present for loading/empty/error.
- Core typography uses scalable text styles from design system wrappers.

## Identifier Inventory
- `login_email`
- `login_password`
- `login_biometrics_toggle`
- `login_submit`
- `offers_table`
- `offer_card_<id>`
- `offer_detail_save_button`
- `saved_offers_table`
- `saved_offer_card_<id>`
- `inbox_table`
- `inbox_message_<id>`
- `settings_logout`

## Manual Audit Steps (per release)
1. Enable VoiceOver and verify navigation order in each main screen.
2. Increase Dynamic Type to largest sizes and validate no clipped primary actions.
3. Validate color contrast for status/error text in light mode.
4. Confirm all tappable icons/buttons have accessibility labels.
5. Confirm route and diagnostics actions are reachable via Switch Control/VoiceOver.

## Automated Coverage
- `/Tests/UITests/AccessibilityAuditUITests.swift` verifies stable identifiers and core list presence.

## Known Gaps / Next Improvements
- Add explicit accessibility traits for unread inbox rows.
- Add full dynamic type snapshot matrix.
- Add localized accessibility copy for multilingual variants.
