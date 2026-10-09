# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::PrintsController do
  let(:group) { groups(:top_group) }

  it "enqueues the print job for the selected people" do
    sign_in(people(:top_leader))

    expect do
      post :create, params: {group_id: group.id, ids: people(:top_leader).id.to_s}
    end.to change { Delayed::Job.where("handler LIKE '%VerifiablePass::PrintJob%'").count }.by(1)

    expect(response).to redirect_to(group_people_path(group, returning: true))
  end

  it "denies users without permission" do
    sign_in(people(:bottom_member))

    expect do
      post :create, params: {group_id: group.id}
    end.to raise_error(CanCan::AccessDenied)
  end
end
