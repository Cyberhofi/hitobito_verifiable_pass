# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Effective configuration: config/verifiable_pass_defaults.yml deep-merged with
# Settings.verifiable_pass of the organization wagon. Access with method calls,
# e.g. VerifiablePass.config.print.layout.
class VerifiablePass::Config
  DEFAULTS_FILE = HitobitoVerifiablePass::Wagon.root.join("config", "verifiable_pass_defaults.yml")

  class << self
    def current
      new(defaults.deep_merge(overrides))
    end

    def defaults
      @defaults ||= YAML.safe_load_file(DEFAULTS_FILE).deep_symbolize_keys.freeze
    end

    private

    def overrides
      Settings.verifiable_pass&.to_hash&.deep_symbolize_keys || {}
    end
  end

  def initialize(hash)
    @hash = hash
  end

  def to_h
    @hash
  end

  def [](key)
    wrap(@hash[key.to_sym])
  end

  def empty?
    @hash.empty?
  end

  # Missing keys return nil like Config::Options, so optional settings can be read directly.
  def method_missing(name, *args)
    return super unless args.empty? && !name.end_with?("=", "?", "!")

    self[name]
  end

  def respond_to_missing?(name, include_private = false)
    @hash.key?(name.to_sym) || super
  end

  def template_key
    @hash[:template_key].to_s
  end

  def organization_name
    @hash[:organization_name].presence || Settings.application.name
  end

  def logo
    @hash[:logo].presence || Settings.application.logo.image
  end

  def member_number_label
    @hash[:member_number_label].presence || I18n.t("verifiable_pass.member_number")
  end

  # Note: use [] for keys that collide with Kernel methods (print, format, ...)
  def layout
    print_config = self[:print]
    name = print_config[:layout].to_s
    print_config[:layouts][name] ||
      raise(KeyError, "Unknown verifiable_pass print layout #{name.inspect}")
  end

  def print_filename
    self[:print][:filename].presence || "passes"
  end

  # Path of an image in app/assets/images of the core or any wagon
  def image_path(file)
    roots = [Rails.root] + Wagons.all.map(&:root)
    roots.map { |root| root.join("app", "assets", "images", file.to_s) }.find(&:exist?)&.to_s ||
      raise(ArgumentError, "Image #{file.inspect} not found in app/assets/images")
  end

  private

  def wrap(value)
    value.is_a?(Hash) ? self.class.new(value) : value
  end
end
