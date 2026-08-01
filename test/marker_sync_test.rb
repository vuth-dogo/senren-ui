# frozen_string_literal: true

require 'test_helper'
require 'senren/rails/marker_block'

module Senren
  module Rails
    class MarkerSyncTest < Minitest::Test
      START_MARKER = '<!-- senren:test:start -->'
      END_MARKER   = '<!-- senren:test:end -->'

      def test_replaces_the_generated_block_and_preserves_surrounding_content
        existing = "intro\n\n#{START_MARKER}\n\nOLD\n\n#{END_MARKER}\n\noutro\n"

        result = inject(existing, 'NEW')

        assert_includes result, 'intro'
        assert_includes result, 'outro'
        assert_includes result, 'NEW'
        refute_includes result, 'OLD'
        assert_equal 1, result.scan(START_MARKER).size
        assert_equal 1, result.scan(END_MARKER).size
      end

      def test_appends_a_block_when_the_file_has_no_markers
        result = inject("existing notes\n", 'NEW')

        assert_includes result, 'existing notes'
        assert_equal 1, result.scan(START_MARKER).size
        assert_equal 1, result.scan(END_MARKER).size
      end

      def test_is_idempotent_across_repeated_syncs
        first  = inject('', 'NEW')
        second = inject(first, 'NEW')

        assert_equal first, second, 'repeated syncs must not grow the file'
      end

      # These files are AI-agent instruction files that say "regenerated, do
      # not edit by hand". A planted or reordered marker previously produced a
      # block that regeneration could never clean up, which is indistinguishable
      # from a persistent prompt injection.
      # Regression: replacement was done with `String#sub(pattern, string)`,
      # which expands \0, \1 and \& as backreferences. A body containing one
      # spliced the *old* block — markers included — back into the new one, so
      # stale content reappeared and the file gained a second marker pair, which
      # then made every later sync raise. Silent, destructive, and reachable via
      # any registry free-text field that mentions a regex or a Windows path.
      def test_backreference_sequences_in_the_body_are_written_verbatim
        existing = "head\n\n#{START_MARKER}\n\nSTALE\n\n#{END_MARKER}\n\ntail"

        ['see \0 here', 'see \1 here', 'path C:\\dir', 'A \& B'].each do |payload|
          result = inject(existing, payload)

          assert_includes result, payload, "#{payload.inspect} must survive verbatim"
          refute_includes result, 'STALE', "#{payload.inspect} must not resurrect the old block"
          assert_equal 1, result.scan(START_MARKER).size, "#{payload.inspect} must not duplicate markers"
          assert_equal 1, result.scan(END_MARKER).size, "#{payload.inspect} must not duplicate markers"
        end
      end

      # The generated body is rendered from registry and ledger data. If that
      # data ever contains a marker, the writer would emit a file it then
      # refuses to parse — corrupting its own output and blaming the user.
      def test_rejects_a_generated_body_that_contains_a_marker
        [START_MARKER, END_MARKER].each do |marker|
          error = assert_raises(MarkerBlock::MalformedMarkers) do
            inject('', "rows:\n- item #{marker} more")
          end

          assert_includes error.message, 'Generated content'
        end
      end

      def test_rejects_an_end_marker_placed_before_the_start_marker
        tampered = "X #{END_MARKER} injected instructions #{START_MARKER} OLD #{END_MARKER} Z"

        error = assert_raises(MarkerBlock::MalformedMarkers) { inject(tampered, 'NEW') }

        assert_includes error.message, 'CLAUDE.md'
      end

      def test_rejects_duplicated_markers
        tampered = "#{START_MARKER} a #{START_MARKER} b #{END_MARKER}"

        assert_raises(MarkerBlock::MalformedMarkers) { inject(tampered, 'NEW') }
      end

      def test_rejects_a_start_marker_with_no_end_marker
        assert_raises(MarkerBlock::MalformedMarkers) { inject("head #{START_MARKER} body", 'NEW') }
      end

      private

      def inject(existing, body)
        MarkerBlock.inject(
          existing, body,
          start_marker: START_MARKER, end_marker: END_MARKER, label: 'CLAUDE.md'
        )
      end
    end
  end
end
