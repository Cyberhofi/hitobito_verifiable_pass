# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Creates a new QR code token for a person's pass, e.g. after the card was lost.
# The old QR code leads to "not valid" afterwards.
class VerifiablePass::TokensController < ApplicationController
  skip_authorize_resource

  def create
    person = Person.find(params[:person_id])
    authorize!(:regenerate_verifiable_pass, person)

    card = VerifiablePass::Card.for_person(person)
    if card.present?
      card.regenerate_token!
      flash[:notice] = t(".success")
    else
      flash[:alert] = t(".no_pass")
    end

    redirect_back_or_to group_person_path(params[:group_id], person)
  end
end
