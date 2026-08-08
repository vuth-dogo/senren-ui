# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'yaml'
require 'erb_lint'
require 'erb_lint/all'

# erb_lint turns a linter on unless the config says otherwise, so a linter you
# never named is not off -- it is on, and nobody chose that.
#
# `.erb_lint.yml` named nine linters and its header said "structural rules
# only". Thirteen were running: eight formatting linters had been enabled by
# default the whole time, silently, and passed only because the templates
# happened to satisfy them. Nothing was broken, which is why nothing surfaced
# it, and it is the same shape of gap either way -- the config described a lint
# policy the project was not running.
#
# The fix is not "disable them"; several are worth having. It is that the file
# names every linter, so the next gem upgrade that ships a fourteenth fails
# here, with a message about the config, instead of appearing as a mystery CI
# failure in whichever pull request happens to be open.
class ErbLintConfigTest < ActiveSupport::TestCase
  CONFIG_PATH = File.expand_path('../../.erb_lint.yml', __dir__)

  def configured
    @configured ||= YAML.load_file(CONFIG_PATH).fetch('linters').keys.to_set
  end

  def registered
    @registered ||= ERBLint::LinterRegistry.linters.to_set(&:simple_name)
  end

  def test_every_registered_linter_is_named_in_the_config
    unnamed = (registered - configured).sort

    assert_empty unnamed,
                 "these linters run (or not) by erb_lint's default rather than by a decision " \
                 "recorded in .erb_lint.yml: #{unnamed.join(', ')}. Add each with an explicit " \
                 'enabled: true/false and a line saying why.'
  end

  # The other direction: a linter renamed or dropped upstream leaves an entry
  # that reads as policy and configures nothing.
  def test_the_config_names_no_linter_that_no_longer_exists
    stale = (configured - registered).sort

    assert_empty stale, "these .erb_lint.yml entries match no linter erb_lint ships: #{stale.join(', ')}"
  end

  # The header's claim, asserted rather than trusted -- it is the claim that was
  # wrong last time.
  def test_the_structural_linters_are_on
    %w[ErbSafety ParserErrors].each do |name|
      assert YAML.load_file(CONFIG_PATH).dig('linters', name, 'enabled'),
             "#{name} is the reason this config exists and it is off"
    end
  end
end
