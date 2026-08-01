require 'yaml'

module Senren
  module Rails
    # Loads, validates, and queries the Senren component registry.
    class Registry
      include Enumerable

      REQUIRED_KEYS = %w[category client can_have_client files depends_on pairs_with variants accessibility ai].freeze
      OPTIONAL_KEYS = %w[controller stub].freeze
      ALLOWED_KEYS = (REQUIRED_KEYS + OPTIONAL_KEYS).freeze
      VALID_CATEGORIES = %w[actions forms overlays navigation layout data saas rich].freeze
      NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/

      Component = Struct.new(:name, :category, :client, :can_have_client, :controller, :stub, :files, :depends_on,
                             :pairs_with, :variants, :accessibility, :use_for, :avoid, keyword_init: true) do
        def stub? = stub == true
        def client? = client == true
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
        @raw_components = (components_yaml || {}).fetch('components', {})
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

      def all = @components.values
      def each(&) = all.each(&)
      alias find_each each

      def names = @components.keys

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
          validate_component(name, comp, errors)
        end
      end

      def validate_component(name, comp, errors)
        validate_component_name(name, errors)
        validate_component_keys(name, errors)
        validate_component_category(name, comp, errors)
        validate_component_dependencies(name, comp, errors)
        validate_component_client_contract(name, comp, errors)
        validate_component_file_paths(name, comp, errors)
      end

      # The file-path allowlist is derived from the component name, so an
      # unconstrained name would validate a traversal path against itself.
      def validate_component_name(name, errors)
        return if NAME_PATTERN.match?(name)

        errors << "#{name.inspect}: invalid component name (expected #{NAME_PATTERN.source})"
      end

      def validate_component_keys(name, errors)
        extra_keys = @raw_components.fetch(name).keys - ALLOWED_KEYS
        errors << "#{name}: unknown keys #{extra_keys.sort.join(', ')}" if extra_keys.any?
      end

      def validate_component_category(name, comp, errors)
        return if VALID_CATEGORIES.include?(comp.category)

        errors << "#{name}: invalid category #{comp.category.inspect}"
      end

      def validate_component_dependencies(name, comp, errors)
        comp.depends_on.each do |dep|
          errors << "#{name}: depends_on unknown component #{dep.inspect}" unless @components.key?(dep)
        end
      end

      def validate_component_client_contract(name, comp, errors)
        errors << "#{name}: client=true but can_have_client=false" if comp.client && !comp.can_have_client
        errors << "#{name}: client=true requires a controller identifier" if comp.client && comp.controller.nil?
        return unless comp.client && !controller_file?(name, comp)

        errors << "#{name}: client=true requires a Stimulus controller file"
      end

      def validate_component_file_paths(name, comp, errors)
        comp.files.each do |path|
          next if allowed_component_file?(name, path)

          errors << "#{name}: invalid file path #{path.inspect}"
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

      def controller_file?(name, comp)
        comp.files.include?("app/javascript/controllers/senren/#{name}_controller.js")
      end

      def allowed_component_file?(name, path)
        [
          "app/components/senren/#{name}_component.rb",
          "app/components/senren/#{name}_component.html.erb",
          "app/javascript/controllers/senren/#{name}_controller.js"
        ].include?(path)
      end
    end
  end
end
