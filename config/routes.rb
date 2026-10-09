# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

Rails.application.routes.draw do
  extend LanguageRouteScope

  # Public verification page (QR code), no login. Path configurable: verifiable_pass.verify_path
  get "/#{VerifiablePass.config.verify_path.to_s.delete("/")}/:token" =>
        "verifiable_pass/verifications#show",
    as: :verifiable_pass_verify,
    constraints: {token: /[A-Za-z0-9_-]{1,64}/}

  language_scope do
    resources :groups, only: [] do
      scope module: "verifiable_pass", as: "verifiable_pass" do
        resource :print, only: [:create]

        resources :people, only: [] do
          resource :token, only: [:create]
        end
      end
    end
  end
end
