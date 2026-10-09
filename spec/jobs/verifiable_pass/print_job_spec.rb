# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::PrintJob do
  let(:user) { people(:top_leader) }

  it "renders passes of eligible people only" do
    create_pass(people(:top_leader))
    create_pass(people(:bottom_member), state: "ended")

    job = described_class.new(user.id, [people(:top_leader).id, people(:bottom_member).id])
    text = PDF::Inspector::Text.analyze(job.data).strings.join(" ")

    expect(text).to include people(:top_leader).full_name
    expect(text).not_to include people(:bottom_member).full_name
  end

  it "sorts passes by last and first name" do
    create_pass(people(:top_leader))
    create_pass(people(:bottom_member))

    cards = VerifiablePass::Card.for_people([people(:top_leader).id, people(:bottom_member).id])

    expect(cards.map(&:list_name)).to eq ["Leader, Top", "Member, Bottom"]
  end
end
