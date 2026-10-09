# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# A person's verifiable pass. The single place that decides about validity; the
# verification page, the online card and the PDF all use this class.
#
# Valid means:
#  1. the core Pass is eligible and within its validity dates, i.e. the person has an
#     active role granted by the PassDefinition (PassGrants), and
#  2. the optional attribute rule from the configuration holds (variant 1), and
#  3. all rules registered with VerifiablePass.register_validity_rule hold (variant 2).
#
# Additional status lines (e.g. membership fee) come from VerifiablePass.register_status
# and are shown separately; they do not affect validity.
class VerifiablePass::Card
  attr_reader :pass

  class << self
    def template_key
      VerifiablePass.config.template_key
    end

    def definition
      PassDefinition.find_by(template_key: template_key)
    end

    def for_person(person)
      new(scope.find_by(person: person))
    end

    def for_token(token)
      return new(nil) if token.blank?

      new(scope.includes(:person).find_by(verify_token: token.to_s))
    end

    def for_people(people_ids)
      scope.includes(:person).where(person_id: people_ids, state: "eligible")
        .sort_by { |pass| [pass.person.last_name.to_s, pass.person.first_name.to_s] }
        .map { |pass| new(pass) }
    end

    def verify_url(token)
      Rails.application.routes.url_helpers.verifiable_pass_verify_url(
        token,
        host: Settings.application.hostname,
        protocol: Settings.application.protocol,
        locale: nil
      )
    end

    private

    def scope
      Pass.joins(:pass_definition).where(pass_definitions: {template_key: template_key})
    end
  end

  def initialize(pass)
    @pass = pass
  end

  def present?
    pass.present?
  end

  def person
    pass&.person
  end

  def definition
    pass&.pass_definition
  end

  ### Validity

  def valid?(date = Date.current)
    role_valid?(date) && attribute_rule_valid?(date) &&
      VerifiablePass.validity_rules.values.all? { |rule| rule.call(self, date) }
  end

  def role_valid?(date = Date.current)
    return false unless pass&.eligible?

    pass.valid_from <= date && (pass.valid_until.nil? || pass.valid_until >= date)
  end

  # [{ok: true/false, text: "..."}, ...]
  def statuses(date = Date.current)
    VerifiablePass.status_items.values.filter_map { |item| item.call(self, date) }
  end

  ### Values

  def name
    person.full_name
  end

  def list_name
    [person.last_name, person.first_name].compact_blank.join(", ").presence || person.to_s
  end

  def member_number
    attribute = VerifiablePass.config.member_number_attribute.presence
    attribute && person.public_send(attribute).presence
  end

  def pass_name
    definition&.name.presence || I18n.t("verifiable_pass.title")
  end

  def organization_name
    VerifiablePass.config.organization_name
  end

  ### QR code

  def token
    pass.verify_token
  end

  def verify_url
    self.class.verify_url(token)
  end

  def qr_code
    RQRCode::QRCode.new(verify_url)
  end

  # New token, e.g. after the card was lost. The old QR code becomes invalid.
  def regenerate_token!
    pass.regenerate_verify_token
  end

  private

  def attribute_rule_valid?(date)
    rule = VerifiablePass.config[:validity]
    attribute = rule && rule[:attribute].presence
    return true unless attribute

    value = person.public_send(attribute)
    return false if value.blank?

    case rule[:minimum].to_s
    when "today" then value >= date
    else value.to_i >= date.year # current_year
    end
  end
end
