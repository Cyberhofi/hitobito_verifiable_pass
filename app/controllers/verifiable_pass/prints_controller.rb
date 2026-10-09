# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# "Print passes" from a people list: selection or the whole (filtered) list.
# The PDF is generated in the background like other exports.
class VerifiablePass::PrintsController < ApplicationController
  include FilteredPeople
  include ExportableRedirect

  skip_authorize_resource

  def create
    authorize!(:print_verifiable_passes, group)

    people = person_filter(PersonFullReadables).entries
    ids = Person.from(people.select("people.id AS person_id")).pluck(:person_id)
    VerifiablePass::PrintJob.new(
      current_user.id, ids, filename: "#{VerifiablePass.config.print_filename}_#{group.id}"
    ).enqueue!

    redirect_after_enqueued_export(group_people_path(group, returning: true))
  end

  private

  def group
    @group ||= Group.find(params[:group_id])
  end
end
