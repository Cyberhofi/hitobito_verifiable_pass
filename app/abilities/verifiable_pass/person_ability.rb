# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Who may create a new QR code token for a person's pass (e.g. after the card was lost).
# Organization wagons may grant this to further permissions in their own abilities.
module VerifiablePass::PersonAbility
  extend ActiveSupport::Concern

  included do
    on(Person) do
      permission(:layer_full).may(:regenerate_verifiable_pass).in_same_layer
      permission(:layer_and_below_full)
        .may(:regenerate_verifiable_pass)
        .in_same_layer_or_visible_below
    end
  end
end
