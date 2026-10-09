# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

module VerifiablePassHelpers
  # Overrides Settings.verifiable_pass for one example (deep merged with the defaults)
  def stub_verifiable_pass_settings(hash)
    allow(Settings).to receive(:verifiable_pass).and_return(Config::Options.new.merge!(hash))
  end

  # The core fixture top_layer_pass grants passes to Group::TopGroup::Leader and
  # Group::TopLayer::Leader. It is switched to the template of this wagon.
  def verifiable_pass_definition
    pass_definitions(:top_layer_pass).tap do |definition|
      definition.update_column(:template_key, VerifiablePass.config.template_key)
    end
  end

  def create_pass(person, valid_from: Date.current - 1.year, valid_until: nil, state: "eligible")
    Pass.create!(person: person, pass_definition: verifiable_pass_definition,
      state: "eligible", valid_from: valid_from, valid_until: valid_until).tap do |pass|
      pass.update_column(:state, state) unless state == "eligible"
    end
  end
end

RSpec.configure do |config|
  config.include VerifiablePassHelpers

  config.before(:suite) do
    Passes::TemplateRegistry.register(VerifiablePass.config.template_key,
      pdf_class: VerifiablePass::Pdf::SinglePass,
      pass_view_partial: "verifiable_pass",
      wallet_data_provider: VerifiablePass::WalletDataProvider)
  end

  config.before do
    VerifiablePass.validity_rules.clear
    VerifiablePass.status_items.clear
    VerifiablePass::VerificationsController::RATE_LIMIT_STORE.clear
  end
end
