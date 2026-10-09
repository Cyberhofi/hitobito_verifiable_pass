# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe Ability do
  subject(:ability) { Ability.new(user) }

  context "with layer_and_below_full" do
    let(:user) { people(:top_leader) }

    it "may regenerate passes and print below" do
      expect(ability).to be_able_to(:regenerate_verifiable_pass, people(:bottom_member))
      expect(ability).to be_able_to(:print_verifiable_passes, groups(:top_group))
      expect(ability).to be_able_to(:print_verifiable_passes, groups(:bottom_layer_one))
    end
  end

  context "with read permissions only" do
    let(:user) { people(:bottom_member) }

    it "may neither regenerate passes nor print" do
      expect(ability).not_to be_able_to(:regenerate_verifiable_pass, people(:top_leader))
      expect(ability).not_to be_able_to(:print_verifiable_passes, groups(:bottom_layer_one))
    end
  end
end
