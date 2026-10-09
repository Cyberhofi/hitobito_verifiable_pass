# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Pass data for core views and a later Google/Apple Wallet integration.
class VerifiablePass::WalletDataProvider < ::Passes::WalletDataProvider
  def member_number
    VerifiablePass::Card.new(pass.respond_to?(:object) ? pass.object : pass).member_number ||
      "–"
  end
end
