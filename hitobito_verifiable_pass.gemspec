$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "hitobito_verifiable_pass/version"

Gem::Specification.new do |s|
  s.name = "hitobito_verifiable_pass"
  s.version = HitobitoVerifiablePass::VERSION
  s.authors = ["Stefan Hofmann"]
  s.email = ["mail@stefanhofmann.net"]
  s.homepage = "https://github.com/Cyberhofi/hitobito_verifiable_pass"
  s.license = "AGPL-3.0-or-later"
  s.summary = "Membership card with QR code verification for hitobito"
  s.description = "Organization-neutral hitobito wagon: membership card based on the core pass " \
                  "system with a public QR verification page, an online card for members, " \
                  "configurable print sheets (PDF) and pluggable validity rules."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
end
