# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::TokensController do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let!(:pass) { create_pass(person) }

  it "creates a new token for authorized users" do
    sign_in(people(:top_leader))
    old_token = pass.verify_token

    post :create, params: {group_id: group.id, person_id: person.id}

    expect(pass.reload.verify_token).not_to eq old_token
    expect(flash[:notice]).to be_present
  end

  it "denies users without permission" do
    sign_in(people(:bottom_member))

    expect do
      post :create, params: {group_id: group.id, person_id: person.id}
    end.to raise_error(CanCan::AccessDenied)

    expect(pass.reload.verify_token).to eq pass.verify_token
  end

  it "reports people without pass" do
    sign_in(people(:top_leader))
    pass.destroy!

    post :create, params: {group_id: group.id, person_id: person.id}

    expect(flash[:alert]).to be_present
  end
end
