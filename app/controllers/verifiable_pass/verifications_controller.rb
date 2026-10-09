# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Public verification page /<verify_path>/:token, opened by scanning the QR code.
#
# Shows only: valid or not, and for valid passes the name, member number, organization,
# status lines and the time of the check. Invalid, replaced and unknown tokens all get the
# exact same neutral page, so it cannot be told whether a token exists.
class VerifiablePass::VerificationsController < ActionController::Base # rubocop:disable Rails/ApplicationController
  layout false

  # Simple rate limit per IP address. Uses its own in-memory store because the configured
  # Rails cache (memcached) is often not available in small installations.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)

  rate_limit to: VerifiablePass.config.verify_rate_limit_per_minute.to_i,
    within: 1.minute,
    store: RATE_LIMIT_STORE,
    with: -> { render :rate_limited, status: :too_many_requests }

  def show
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"

    card = VerifiablePass::Card.for_token(params[:token])
    @checked_at = Time.zone.now
    @valid = card.present? && card.valid?(@checked_at.to_date)
    @card = card if @valid
  end
end
