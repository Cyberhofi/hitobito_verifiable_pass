# hitobito_verifiable_pass

A [hitobito](https://github.com/hitobito/hitobito) wagon for membership cards that can be
verified by QR code. Organization-neutral: it works with any group structure and is
configured by the organization wagon.

Built on top of the core pass system (`PassDefinition`, `PassGrant`, `Pass`), it adds:

- **Public verification page** `/<verify_path>/:token` (default `/pass/:token`), opened by
  scanning the QR code. Shows "valid" with name, member number and optional status lines,
  or a neutral "not valid" page. Invalid, replaced and unknown tokens look exactly the same,
  so it cannot be told whether a token exists. `noindex`, `no-store`, rate limited per IP.
- **Online card** for members in their profile (Passes → card), portrait layout for phones,
  with QR code and validity.
- **New QR code** for a person (e.g. after a card was lost); the old code becomes invalid.
- **Print sheets** (PDF, background job) from people lists: selection or the whole filtered
  list. Layout fully configurable: grid, card size, duplex sides, elements.
- **Pluggable validity rules** and **status lines**, see below.

The pass is only reachable through its random token; no other personal data is exposed.

## Requirements

- hitobito core with the pass system (2026 or later)
- An organization wagon that defines the group structure and configures this wagon

Add the wagon next to the core like any other wagon. If your organization wagon depends on
it, add `s.add_dependency "hitobito_verifiable_pass"` to its gemspec.

## Configuration

All defaults are in [`config/verifiable_pass_defaults.yml`](config/verifiable_pass_defaults.yml).
Override them in the `settings.yml` of your organization wagon under `verifiable_pass:`;
hashes are merged deeply. This wagon does not add a settings source itself, so the result
does not depend on the order in which wagons are loaded.

```yaml
verifiable_pass:
  template_key: verifiable_pass        # template_key of the PassDefinition
  verify_path: pass                    # public URL /pass/:token
  organization_name: My Club e.V.      # default: Settings.application.name
  logo: my_logo.png                    # default: Settings.application.logo.image
  member_number_attribute: member_no   # person attribute, empty: no number
  member_number_label: Member no.
  setup:
    name: Membership card
    background_color: "#ffffff"
    logo_icon: my_logo.png             # square, app/assets/images of any wagon
    logo_banner: my_banner.png         # landscape (required by the core)
    eligible_role_types:               # subclasses included
      - Role::Member
  print:
    layout: my_layout
    layouts:
      my_layout: { ... }               # see below
```

Then create the pass definition and its grant (safe to run repeatedly):

```bash
bundle exec rake verifiable_pass:setup
```

The delayed job worker creates the passes for all eligible people.

## Validity

A pass is valid if

1. the person has an active role granted by the pass definition (core `Pass` is eligible
   and within its validity dates), **and**
2. the optional attribute rule holds (variant 1, configuration), **and**
3. all registered rules hold (variant 2, code).

Variant 1, configuration only:

```yaml
verifiable_pass:
  validity:
    attribute: membership_fee_paid_until   # integer year or date column
    minimum: current_year                  # or: today
```

Variant 2, register a rule in `config.to_prepare` of your wagon:

```ruby
VerifiablePass.register_validity_rule(:fee) do |card, date|
  card.person.honorary_member? || card.person.fee_paid_until.to_i >= date.year
end
```

## Status lines

Additional information shown separately from the validity on the verification page and the
online card, e.g. whether the membership fee is paid:

```ruby
VerifiablePass.register_status(:membership_fee) do |card, date|
  paid = card.person.fee_paid_until.to_i >= date.year
  {ok: paid, text: I18n.t("my_wagon.fee.#{paid ? "paid" : "open"}", year: date.year)}
end
```

Return `nil` to hide the line.

## Print layouts

A layout defines the grid and one or more sides. Each side is printed on its own page for
every sheet of cards, so two sides give pages for duplex printing
(`duplex_mirror_columns: true` mirrors the back sides for flipping over the long edge).
Positions are in millimeters from the top left corner of the card.

| Element type | Keys |
| --- | --- |
| `background` | `color` |
| `frame` | `inset`, `radius`, `width` (pt), `color` |
| `image` | `file` (default: configured logo), `x`, `y`, `size` |
| `text` | `x`, `y`, `width`, `font_size`, `style`, `align`, `lines`, `color`, and one of `text` (static), `value` (`name`, `list_name`, `member_number`, `organization_name`, `pass_name`, `issued_year`) or `attribute` (any person attribute, dates localized); optional `format` or `i18n` with `%{value}`, `blank` |
| `line` | `x`, `y`, `width`, `line_width` (pt), `color` |
| `qr` | `x`, `y`, `size` |

Elements are a hash keyed by name, so organization wagons can define their own layouts
without conflicts. See the `default` layout in the defaults file for a complete example.

## Permissions

| Action | Default | Ability |
| --- | --- | --- |
| Create a new QR code for a person | `layer_full` (same layer), `layer_and_below_full` | `:regenerate_verifiable_pass` on `Person` |
| Print passes of a people list | `layer_full` (same layer), `layer_and_below_full` | `:print_verifiable_passes` on `Group` |

Organization wagons can grant these abilities to further permissions in their own ability
modules.

## Extension points in views

The people list multiselect actions get a `render_extensions :multiselect_actions` hook
(`app/views/people/_multiselect_actions.html.haml`, a copy of the core partial). Any wagon
can add actions with a partial `people/_multiselect_actions_<wagon>.html.haml`.

Styles live in their own entrypoint `verifiable_pass.css` and use the instance colors
(`$body-background`, `$page-background`). Set `$vp-accent-color` in your wagon's
`hitobito/customizable/_variables.scss` to change the accent line.

## Development and tests

The specs run against the core test group structure and fixtures
(`RAILS_USE_TEST_GROUPS`), so no organization wagon is needed. With the core checked out
next to this wagon:

```bash
cp ../hitobito/Wagonfile.ci ../hitobito/Wagonfile
cp ../hitobito/Gemfile.lock Gemfile.lock
(cd ../hitobito && bundle install && yarn install && RAILS_ENV=test bundle exec rake assets:build)
bundle install
SKIP_CSS_BUILD=1 SKIP_JS_BUILD=1 RAILS_ENV=test bundle exec rake db:test:prepare
bundle exec rspec
bundle exec rubocop
```

GitHub Actions runs the same steps on every push and weekly against the latest core
(`.github/workflows/tests.yml`).

## Notes on core coupling

The core pass system is new; after core updates, check the verification page, the online
card and the print sheet. `app/views/people/_multiselect_actions.html.haml` is a copy of the
core partial and needs to be compared with the original on updates.

## License

GNU Affero General Public License v3.0 or later, see [LICENSE](LICENSE).
