# frozen_string_literal: true

module Senren
  module Rails
    # Replaces the content between a START/END marker pair, preserving
    # everything outside it.
    #
    # These markers delimit generated instructions inside files that humans and
    # AI agents also edit (CLAUDE.md, AGENTS.md, .senren/skill.md). A tampered
    # or duplicated marker pair is treated as an error rather than something to
    # work around: silently "repairing" it produces a block that regeneration
    # can never clean up again, which is indistinguishable from a persistent
    # prompt injection.
    module MarkerBlock
      class MalformedMarkers < StandardError; end

      module_function

      # Returns `existing` with the marker block replaced by `generated`.
      # Appends a fresh block when no markers are present yet.
      def inject(existing, generated, start_marker:, end_marker:, label: nil)
        existing = existing.to_s
        body = generated.to_s.strip

        assert_body_is_marker_free!(body, start_marker, end_marker, label)
        assert_well_formed!(existing, start_marker, end_marker, label)

        block = "#{start_marker}\n\n#{body}\n\n#{end_marker}"
        return append(existing, block) unless existing.include?(start_marker)

        pattern = /#{Regexp.escape(start_marker)}.*?#{Regexp.escape(end_marker)}/m
        # Block form is required. Given a replacement *string*, String#sub
        # expands \0, \1 and \& as backreferences: a body containing one would
        # splice the old block — markers and all — back into the new one,
        # resurrecting stale content and duplicating the delimiters. The block
        # form takes the return value literally.
        existing.sub(pattern) { block }
      end

      # A generated block that contains its own delimiters produces a file this
      # module then refuses to parse: the writer corrupts its own output and the
      # error blames the user for hand-editing. Fail at the source instead.
      def assert_body_is_marker_free!(body, start_marker, end_marker, label)
        found = [start_marker, end_marker].select { |marker| body.include?(marker) }
        return if found.empty?

        where = label ? " for #{label}" : ''
        raise MalformedMarkers,
              "Generated content#{where} contains #{found.join(' and ')}. " \
              'The data this block is rendered from must not contain the markers themselves.'
      end

      def append(existing, block)
        head = existing.rstrip
        head.empty? ? "#{block}\n" : "#{head}\n\n#{block}\n"
      end

      # A file is well formed when it has either no markers at all, or exactly
      # one START followed by exactly one END.
      def assert_well_formed!(existing, start_marker, end_marker, label)
        starts = existing.scan(start_marker).size
        ends   = existing.scan(end_marker).size

        return if starts.zero? && ends.zero?

        where = label ? " in #{label}" : ''
        if starts != 1 || ends != 1
          raise MalformedMarkers,
                "Expected exactly one #{start_marker} and one #{end_marker}#{where}, " \
                "found #{starts} and #{ends}. Fix the markers by hand, then re-run the sync."
        end

        return if existing.index(start_marker) < existing.index(end_marker)

        raise MalformedMarkers,
              "#{end_marker} appears before #{start_marker}#{where}. " \
              'Fix the marker order by hand, then re-run the sync.'
      end
    end
  end
end
