# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Generates the print sheet PDF in the background. The result is available for download
# like other exports (core job observations).
class VerifiablePass::PrintJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:people_ids]

  def initialize(user_id, people_ids, options = {})
    super(:pdf, user_id, options)
    @people_ids = people_ids
  end

  def data
    VerifiablePass::Pdf::Sheet.new(VerifiablePass::Card.for_people(@people_ids)).render
  end
end
