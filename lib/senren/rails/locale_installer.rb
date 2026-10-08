# frozen_string_literal: true

require 'senren/rails/safe_write'

module Senren
  module Rails
    # Copies the translations the gem ships into the host app's config/locales.
    #
    # The files are not loaded from the gem. A Rails engine auto-loads
    # `config/locales` from its own root, which would put `:vi` into
    # `I18n.available_locales` of every app that merely bundles senren-ui. They
    # are source, like the components: copied once, then the host's to edit.
    #
    # Nothing is needed for English to work. Every component carries its English
    # as the `default:` of the `senren_t` call, so an app with no locale file at
    # all renders what it always did. That is also why English is not copied
    # unless asked for: Rails loads config/locales in name order, so a copied
    # senren.en.yml loads after the host's en.yml and overrides any senren key
    # set there, and it pins the wording, so a default the gem later improves
    # never reaches the app. Ask for `en` to get a copy to translate from.
    #
    # An existing file is never overwritten without `force:`: it is the host's
    # translation, and a re-run of the installer must not undo it.
    class LocaleInstaller
      LOCALE_PATTERN = /\A[a-z]{2,3}(?:-[A-Za-z0-9]+)*\z/

      attr_reader :paths, :stdout

      def self.source_dir
        File.join(Senren::Rails.templates_root, 'locales')
      end

      # The locales the gem ships a file for.
      def self.available
        Dir[File.join(source_dir, 'senren.*.yml')].map { |path| File.basename(path).split('.')[1] }.sort
      end

      def initialize(paths: HostPaths.new, stdout: $stdout)
        @paths  = paths
        @stdout = stdout
      end

      # Returns the locales actually written. Every name is checked before any
      # file is, so a typo in the second does not leave the first half-installed.
      def install(locales: [], force: false)
        names = Array(locales).flatten.map(&:to_s).reject(&:empty?).uniq
        if names.empty?
          stdout.puts "  skip  no locale named (shipped: #{self.class.available.join(', ')}); English needs no file"
          return []
        end
        names.each { |name| validate!(name) }

        names.select { |name| copy_locale(name, force: force) }
      end

      private

      def validate!(name)
        unless LOCALE_PATTERN.match?(name)
          raise ArgumentError, "#{name.inspect} is not a locale name. Expected something like en or pt-BR."
        end
        return if self.class.available.include?(name)

        raise ArgumentError,
              "Senren ships no #{name} translation (shipped: #{self.class.available.join(', ')}). " \
              "To add #{name}, run bin/rails senren:locales en, copy config/locales/senren.en.yml to " \
              "config/locales/senren.#{name}.yml, change the top-level key to #{name}:, and translate the values."
      end

      def copy_locale(name, force:)
        source = File.join(self.class.source_dir, "senren.#{name}.yml")
        dest = paths.locale_file(name)
        label = "locale #{name}"

        target = SafeWrite.resolve(dest, paths.root, label, io: stdout)
        return false unless target

        if File.exist?(target) && !force
          stdout.puts "  skip  #{dest} (already exists; bin/rails senren:locales #{name} --force replaces it)"
          return false
        end

        SafeWrite.mkdir_p!(paths.locales_dir, paths.root, label)
        SafeWrite.copy!(source, dest, paths.root, label)
        stdout.puts "  copy  #{dest}"
        true
      end
    end
  end
end
