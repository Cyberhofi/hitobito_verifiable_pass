# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Who may print the passes of a people list. Organization wagons may grant this to
# further permissions in their own abilities.
module VerifiablePass::GroupAbility
  extend ActiveSupport::Concern

  included do
    on(Group) do
      permission(:layer_full).may(:print_verifiable_passes).in_same_layer
      permission(:layer_and_below_full).may(:print_verifiable_passes).in_same_layer_or_below
    end
  end
end
