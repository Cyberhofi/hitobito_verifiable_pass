# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

namespace :verifiable_pass do
  desc "Create or update the PassDefinition and its grant for the root group from the " \
       "configuration (verifiable_pass.setup). Safe to run repeatedly."
  task setup: :environment do
    Rails.application.eager_load!

    config = VerifiablePass.config
    setup = config[:setup]
    root = Group.root || abort("No root group found.")

    attach_logo = lambda do |definition, name, file|
      Globalized.languages.each do |lang|
        attachment = definition.public_send(:"#{name}_#{lang}")
        next if attachment.attached?

        path = config.image_path(file)
        attachment.attach(io: File.open(path), filename: File.basename(path),
          content_type: Marcel::MimeType.for(Pathname.new(path)))
      end
    end

    definition = PassDefinition.find_or_initialize_by(template_key: config.template_key)
    definition.owner ||= root
    definition.name = setup[:name]
    definition.background_color = setup[:background_color]
    attach_logo.call(definition, :logo_icon, setup[:logo_icon].presence || config.logo)
    # The core requires a landscape banner, the square logo cannot be used as fallback
    banner = setup[:logo_banner].presence || abort("verifiable_pass.setup.logo_banner is empty.")
    attach_logo.call(definition, :logo_banner, banner)
    definition.save!
    puts "PassDefinition ##{definition.id}: #{definition.name} (#{root.name})"

    base_types = Array(setup[:eligible_role_types]).map(&:constantize)
    abort("verifiable_pass.setup.eligible_role_types is empty.") if base_types.empty?

    role_types = Role.all_types
      .select { |type| base_types.any? { |base| type <= base } }
      .map(&:sti_name).sort

    grant = PassGrant.find_or_initialize_by(pass_definition: definition, grantor: root)
    grant.role_types = role_types
    grant.save!

    puts "Granting role types:"
    role_types.each { |type| puts "  - #{type}" }
    puts "Passes for all eligible people are created in the background (delayed job worker)."
  end
end
