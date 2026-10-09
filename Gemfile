#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require File.expand_path("../app_root", __FILE__)

source "https://rubygems.org"

gemspec

# Load application Gemfile for all application dependencies.
eval File.read(File.expand_path("Gemfile", ENV["APP_ROOT"])) # rubocop:disable Security/Eval
