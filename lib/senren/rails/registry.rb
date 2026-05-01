require 'yaml'

module Senren
  module Rails
    # Loads, validates, and queries the Senren component registry.
    #
    #   reg = Senren::Rails::Registry.load!
    #   reg.find("button")           # => Component struct
    #   reg.dependencies("dialog")    # => [<button>]
    #   reg.group("forms")            # => [<form>, <input>, ...]
    class Registry
      include Enumerable

      REQUIRED_KEYS = %w[category client can_have_client files depends_on pairs_with variants accessibility ai].freeze
      VALID_CATEGORIES = %w[actions forms overlays navigation layout data saas rich].freeze

      Component = Struct.new(
        :name, :category, :client, :can_have_client, :controller, :stub,
        :files, :depends_on, :pairs_with, :variants, :accessibility,
        :use_for, :avoid,
        keyword_init: true
      ) do
        def stub? = stub == true
        def client? = client == true

        def to_h_full
          to_h.merge(stub: stub?, client: client?)
        end
      end

      attr_reader :components, :groups, :recipes

      def self.load!(
        components_path: Senren::Rails.registry_path,
        groups_path:     Senren::Rails.groups_path,
        recipes_path:    Senren::Rails.recipes_path
      )
        new(
          YAML.safe_load_file(components_path, aliases: false),
          YAML.safe_load_file(groups_path, aliases: false),
          YAML.safe_load_file(recipes_path, aliases: false)
        ).tap(&:validate!)
      end

      def initialize(components_yaml, groups_yaml, recipes_yaml)
        @components = parse_components(components_yaml)
        @groups     = (groups_yaml || {}).fetch('groups', [])
        @recipes    = (recipes_yaml || {}).fetch('recipes', {})
      end

      def find(name)
        @components[name.to_s]
      end

      def fetch(name)
        find(name) or raise ArgumentError, "Unknown component: #{name.inspect}. " \
                                           "Known: #{@components.keys.sort.join(', ')}"
      end

      def all
        @components.values
      end

      def each(&block)
        all.each(&block)
      end

      def find_each(&block)
        each(&block)
      end

      def names
        @components.keys
      end

      def group(category_id)
        @components.values.select { |c| c.category == category_id.to_s }
      end

      def recipe(id)
        @recipes.fetch(id.to_s) { raise ArgumentError, "Unknown recipe: #{id}" }
      end

      # Returns the transitive dependency closure for one or more components,
      # in install order (deps first), de-duplicated.
      def dependencies(*requested)
        requested = requested.flatten.map(&:to_s)
        result = []
        visiting = []

        visit = lambda do |name|
          return if result.include?(name)
          raise "Circular dependency: #{(visiting + [name]).join(' -> ')}" if visiting.include?(name)

          visiting << name
          comp = fetch(name)
          comp.depends_on.each { |dep| visit.call(dep) }
          visiting.pop
          result << name
        end

        requested.each { |name| visit.call(name) }
        result
      end

      def validate!
        errors = []

        validate_components(errors)
        validate_recipes(errors)

        raise "Registry validation failed:\n - #{errors.join("\n - ")}" if errors.any?

        self
      end

      private

      def validate_components(errors)
        @components.each do |name, comp|
          errors << "#{name}: invalid category #{comp.category.inspect}" unless VALID_CATEGORIES.include?(comp.category)
          comp.depends_on.each do |dep|
            errors << "#{name}: depends_on unknown component #{dep.inspect}" unless @components.key?(dep)
          end
          errors << "#{name}: client=true but can_have_client=false" if comp.client && !comp.can_have_client
          errors << "#{name}: client=true requires a controller identifier" if comp.client && comp.controller.nil?
        end
      end

      def validate_recipes(errors)
        @recipes.each do |id, recipe|
          recipe.fetch('components', []).each do |component|
            errors << "recipe #{id}: unknown component #{component.inspect}" unless @components.key?(component)
          end
        end
      end

      def parse_components(yaml)
        raw = (yaml || {}).fetch('components', {})
        raw.each_with_object({}) do |(name, data), hash|
          ai = data.fetch('ai', {})
          hash[name] = Component.new(
            name: name,
            category: data.fetch('category'),
            client: data.fetch('client', false),
            can_have_client: data.fetch('can_have_client', false),
            controller: data['controller'],
            stub: data.fetch('stub', false),
            files: Array(data['files']),
            depends_on: Array(data['depends_on']),
            pairs_with: Array(data['pairs_with']),
            variants: Array(data['variants']),
            accessibility: Array(data['accessibility']),
            use_for: Array(ai['use_for']),
            avoid: Array(ai['avoid'])
          ).freeze
        end
      end
    end
  end
end
