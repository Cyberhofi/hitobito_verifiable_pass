# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Verifiable membership pass on top of the hitobito core pass system.
#
# Extension points for organization wagons (call them in config.to_prepare):
#
#   # Additional validity rule (variant 2). All rules must return true.
#   VerifiablePass.register_validity_rule(:fee_exempt_or_paid) do |card, date|
#     ...
#   end
#
#   # Additional status line on the verification page and the online card, shown
#   # separately from the validity. Return nil to hide it, or a hash:
#   #   { ok: true/false, text: "Membership fee 2026 paid" }
#   VerifiablePass.register_status(:membership_fee) do |card, date|
#     ...
#   end
module VerifiablePass
  class << self
    def config
      VerifiablePass::Config.current
    end

    def validity_rules
      @validity_rules ||= {}
    end

    def register_validity_rule(key, &block)
      validity_rules[key.to_sym] = block
    end

    def status_items
      @status_items ||= {}
    end

    def register_status(key, &block)
      status_items[key.to_sym] = block
    end
  end
end
