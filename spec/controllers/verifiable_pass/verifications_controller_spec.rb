# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::VerificationsController do
  render_views

  let(:person) { people(:top_leader) }
  let!(:pass) { create_pass(person) }

  # Response body without the time of the check, to compare pages
  def body_without_timestamp
    response.body.gsub(/<div class="vp-checked">.*?<\/div>/m, "")
  end

  it "is reachable without login" do
    get :show, params: {token: pass.verify_token}

    expect(response).to have_http_status(:ok)
  end

  it "shows a valid pass with name and status lines" do
    VerifiablePass.register_status(:fee) { |_card, _date| {ok: true, text: "Fee paid"} }

    get :show, params: {token: pass.verify_token}

    expect(response.body).to include "vp-state-valid"
    expect(response.body).to include person.full_name
    expect(response.body).to include "Fee paid"
  end

  it "shows the member number when configured" do
    stub_verifiable_pass_settings(member_number_attribute: "email", member_number_label: "No.")

    get :show, params: {token: pass.verify_token}

    expect(response.body).to include "No.:"
    expect(response.body).to include person.email
  end

  it "does not reveal personal data of an invalid pass" do
    pass.update_column(:state, "ended")

    get :show, params: {token: pass.verify_token}

    expect(response.body).to include "vp-state-invalid"
    expect(response.body).not_to include person.full_name
    expect(response.body).not_to include person.last_name
  end

  it "shows the same page for invalid and unknown tokens" do
    pass.update_column(:state, "ended")

    get :show, params: {token: pass.verify_token}
    invalid = body_without_timestamp
    get :show, params: {token: "doesnotexist1234567890"}
    unknown = body_without_timestamp

    expect(invalid).to eq unknown
  end

  it "applies validity rules" do
    VerifiablePass.register_validity_rule(:never) { |_card, _date| false }

    get :show, params: {token: pass.verify_token}

    expect(response.body).to include "vp-state-invalid"
  end

  it "prevents indexing and caching" do
    get :show, params: {token: pass.verify_token}

    expect(response.headers["X-Robots-Tag"]).to eq "noindex, nofollow"
    expect(response.headers["Cache-Control"]).to include "no-store"
    robots = Nokogiri::HTML(response.body).at_css("meta[name=robots]")
    expect(robots["content"]).to eq "noindex, nofollow"
  end

  it "limits the number of checks per IP address" do
    limit = VerifiablePass.config.verify_rate_limit_per_minute.to_i
    limit.times { get :show, params: {token: "unknown"} }

    get :show, params: {token: pass.verify_token}

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).not_to include person.full_name
  end

  it "is routed to the configured path" do
    expect(get: "/#{VerifiablePass.config.verify_path}/abc123")
      .to route_to("verifiable_pass/verifications#show", token: "abc123")
  end
end
