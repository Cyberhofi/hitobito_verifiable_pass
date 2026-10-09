# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::Config do
  subject(:config) { described_class.current }

  context "without settings of an organization wagon" do
    before { allow(Settings).to receive(:verifiable_pass).and_return(nil) }

    it "uses the defaults" do
      expect(config.template_key).to eq "verifiable_pass"
      expect(config.verify_path).to eq "pass"
      expect(config[:print][:layout]).to eq "default"
    end

    it "falls back to the application name and logo" do
      expect(config.organization_name).to eq Settings.application.name
      expect(config.logo).to eq Settings.application.logo.image
    end

    it "translates the member number label" do
      expect(config.member_number_label).to eq I18n.t("verifiable_pass.member_number")
    end

    it "resolves the default layout" do
      expect(config.layout[:columns]).to eq 2
      expect(config.layout[:rows]).to eq 5
    end
  end

  context "with settings of an organization wagon" do
    before do
      stub_verifiable_pass_settings(
        organization_name: "My Club",
        member_number_label: "Club no.",
        print: {layout: "club", layouts: {club: {columns: 1, rows: 1}}}
      )
    end

    it "overrides only the given values" do
      expect(config.organization_name).to eq "My Club"
      expect(config.member_number_label).to eq "Club no."
      expect(config.template_key).to eq "verifiable_pass"
    end

    it "keeps the default layouts next to the own one" do
      expect(config.layout[:columns]).to eq 1
      expect(config[:print][:layouts][:default]).to be_present
    end
  end

  it "raises for an unknown layout" do
    stub_verifiable_pass_settings(print: {layout: "missing"})

    expect { config.layout }.to raise_error(KeyError, /missing/)
  end

  it "finds images in app/assets/images of the core" do
    expect(config.image_path("logo.png")).to end_with("app/assets/images/logo.png")
  end

  it "raises for unknown images" do
    expect { config.image_path("nope.png") }.to raise_error(ArgumentError, /nope.png/)
  end
end
