# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

module HitobitoVerifiablePass
  class Wagon < Rails::Engine
    include Wagons::Wagon

    app_requirement ">= 0"

    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    # This wagon deliberately does not add a settings source. Its defaults live in
    # config/verifiable_pass_defaults.yml and are merged with Settings.verifiable_pass at
    # read time (see VerifiablePass::Config), so the result does not depend on the order
    # in which wagons are loaded.

    config.to_prepare do
      PersonAbility.include VerifiablePass::PersonAbility
      GroupAbility.include VerifiablePass::GroupAbility

      Passes::TemplateRegistry.register(VerifiablePass.config.template_key,
        pdf_class: VerifiablePass::Pdf::SinglePass,
        pass_view_partial: "verifiable_pass",
        wallet_data_provider: VerifiablePass::WalletDataProvider)
    end
  end
end
