# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# PDF of a single pass ("Print" in the person's pass view). Implements the pdf_class
# interface of the core Passes::TemplateRegistry using the configured print layout.
class VerifiablePass::Pdf::SinglePass
  def initialize(pass)
    @pass = pass
  end

  def render
    VerifiablePass::Pdf::Sheet.new([VerifiablePass::Card.new(@pass)]).render
  end

  def filename
    "#{VerifiablePass.config.print_filename}-#{@pass.person.full_name.parameterize}.pdf"
  end
end
