# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::Card do
  let(:person) { people(:top_leader) }
  let!(:pass) { create_pass(person) }

  subject(:card) { described_class.for_person(person) }

  describe "lookup" do
    it "finds the pass of a person" do
      expect(card.pass).to eq pass
    end

    it "finds the pass by token" do
      expect(described_class.for_token(pass.verify_token).pass).to eq pass
    end

    it "is empty for unknown or blank tokens" do
      expect(described_class.for_token("unknown")).not_to be_present
      expect(described_class.for_token("")).not_to be_present
    end

    it "ignores passes of other pass definitions" do
      pass.pass_definition.update_column(:template_key, "default")

      expect(described_class.for_person(person)).not_to be_present
    end
  end

  describe "#valid?" do
    it "is valid for an eligible pass within its dates" do
      expect(card).to be_valid
    end

    it "is not valid before valid_from" do
      pass.update_column(:valid_from, Date.current + 1.day)

      expect(card).not_to be_valid
    end

    it "is not valid after valid_until" do
      pass.update_column(:valid_until, Date.current - 1.day)

      expect(card).not_to be_valid
    end

    it "is not valid for ended or revoked passes" do
      pass.update_column(:state, "ended")
      expect(described_class.for_person(person)).not_to be_valid

      pass.update_column(:state, "revoked")
      expect(described_class.for_person(person)).not_to be_valid
    end

    it "is not valid without pass" do
      expect(described_class.new(nil)).not_to be_valid
    end

    context "with attribute rule (variant 1)" do
      before do
        stub_verifiable_pass_settings(validity: {attribute: "birthday", minimum: "today"})
      end

      it "is not valid when the attribute is blank" do
        person.update_column(:birthday, nil)

        expect(card).not_to be_valid
      end

      it "compares dates with today" do
        person.update_column(:birthday, Date.current + 1.day)
        expect(described_class.for_person(person)).to be_valid

        person.update_column(:birthday, Date.current - 1.day)
        expect(described_class.for_person(person)).not_to be_valid
      end

      it "compares integers with the current year" do
        stub_verifiable_pass_settings(validity: {attribute: "sign_in_count",
                                                 minimum: "current_year"})

        person.update_column(:sign_in_count, Date.current.year)
        expect(described_class.for_person(person)).to be_valid

        person.update_column(:sign_in_count, Date.current.year - 1)
        expect(described_class.for_person(person)).not_to be_valid
      end
    end

    context "with registered rules (variant 2)" do
      it "requires all rules to hold" do
        VerifiablePass.register_validity_rule(:always) { |_card, _date| true }
        expect(card).to be_valid

        VerifiablePass.register_validity_rule(:never) { |_card, _date| false }
        expect(card).not_to be_valid
      end

      it "passes card and date to the rule" do
        date = Date.new(2030, 1, 1)
        received = nil
        VerifiablePass.register_validity_rule(:spy) { |c, d| received = [c, d] }

        card.valid?(date)

        expect(received).to eq [card, date]
      end
    end
  end

  describe "#statuses" do
    it "is empty without registered status lines" do
      expect(card.statuses).to eq []
    end

    it "collects registered status lines and skips nil" do
      VerifiablePass.register_status(:fee) { |_card, date| {ok: false, text: "Fee #{date.year}"} }
      VerifiablePass.register_status(:hidden) { |_card, _date| nil }

      expect(card.statuses(Date.new(2027, 2, 1))).to eq [{ok: false, text: "Fee 2027"}]
    end
  end

  describe "values" do
    it "builds list name as last name, first name" do
      expect(card.list_name).to eq "Leader, Top"
    end

    it "has no member number without configured attribute" do
      expect(card.member_number).to be_nil
    end

    it "reads the configured member number attribute" do
      stub_verifiable_pass_settings(member_number_attribute: "email")

      expect(card.member_number).to eq person.email
    end

    it "uses the pass definition name" do
      expect(card.pass_name).to eq pass.pass_definition.name
    end
  end

  describe "QR code" do
    it "points to the configured verification path" do
      stub_verifiable_pass_settings(verify_path: "pass")

      expect(card.verify_url).to end_with "/pass/#{pass.verify_token}"
    end

    it "encodes the verification URL" do
      expect(card.qr_code).to be_a RQRCode::QRCode
    end

    it "invalidates the old token when regenerating" do
      old_token = card.token

      card.regenerate_token!

      expect(described_class.for_token(old_token)).not_to be_present
      expect(described_class.for_token(pass.reload.verify_token).pass).to eq pass
    end
  end
end
