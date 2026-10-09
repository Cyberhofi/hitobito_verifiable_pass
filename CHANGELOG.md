# hitobito_verifiable_pass Changelog

## 0.1.1

- Specs (59 examples) and GitHub Actions workflow
- Fix: `VerifiablePass::Config` no longer claims to respond to every method, so `present?` and
  `blank?` work on configuration sections
- RuboCop configuration inheriting the core rules

## 0.1.0

- Initial version, extracted from the hitobito_kjv wagon of Kreisjagdverband Bautzen e.V.
- Verification page with configurable path, rate limit and neutral page for invalid tokens
- Online card, new QR code, print sheets as background job
- Configurable validity rule (variant 1) and registrable rules and status lines (variant 2)
- Configurable print layouts with duplex support
