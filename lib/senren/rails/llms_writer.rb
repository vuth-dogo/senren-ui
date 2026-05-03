# frozen_string_literal: true

module Senren
  module Rails
    # Backward-compatible wrapper around AgentRulesWriter.
    #
    # Legacy llms generation now maps to agent rules synchronization and no longer
    # writes public llms files.
    class LlmsWriter
      attr_reader :registry, :paths

      def initialize(registry: Registry.load!, paths: HostPaths.new)
        @registry = registry
        @paths    = paths
      end

      def generate!
        AgentRulesWriter.new(registry: registry, paths: paths).sync!
      end
    end
  end
end
