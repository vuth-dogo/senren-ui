# frozen_string_literal: true

module Senren
  module Rails
    # Ruby appended to a host app's existing BaseComponent when it predates the
    # URL-aware component templates.
    #
    # This duplicates the helpers in
    # lib/generators/senren/install/templates/base_component.rb.tt, because
    # apps installed before those helpers existed never receive the template
    # again. The two definitions are pinned together by
    # test/security/component_url_security_test.rb: if they drift, migrated apps
    # silently keep an older, weaker safe_url.
    module BaseComponentPatch
      # Single-quoted heredoc: the body is emitted verbatim, so the backslash
      # escapes inside safe_url survive into the host app's file.
      URL_HELPERS = <<~'RUBY'

        # Added by senren:add for compatibility with URL-aware component templates.
        require 'uri'

        module Senren
          class BaseComponent
            SAFE_URL_PROTOCOLS = %w[http https mailto tel].freeze unless const_defined?(:SAFE_URL_PROTOCOLS)
            SAFE_MEDIA_URL_PROTOCOLS = %w[http https].freeze unless const_defined?(:SAFE_MEDIA_URL_PROTOCOLS)

            private

            def safe_url(value, fallback: '#', protocols: SAFE_URL_PROTOCOLS)
              url = value.to_s.strip
              return fallback if url.empty?
              # Browsers treat "\" as "/" for special schemes and strip TAB/CR/LF
              # before parsing, so "/\evil.example" and "/<TAB>/evil.example" would
              # both slip past a plain "//" check and resolve off-origin.
              return fallback if url.include?('\\')
              return fallback if url.match?(/[[:cntrl:]]/)
              return url if url.start_with?('#')
              # Any leading "//" is protocol-relative regardless of how many slashes
              # follow. Rejecting here rather than relying on URI.parse matters:
              # URI.parse("///evil.example") reports no scheme and no host, so the
              # scheme-less fallback below would otherwise hand back a URL the browser
              # resolves to https://evil.example/.
              return fallback if url.start_with?('//')
              return url if url.start_with?('/')

              uri = URI.parse(url)
              return url if uri.scheme && Array(protocols).map(&:to_s).include?(uri.scheme.downcase)
              return fallback if uri.host
              return url unless uri.scheme

              fallback
            rescue URI::InvalidURIError
              fallback
            end

            def safe_media_url(value, fallback: nil)
              safe_url(value, fallback: fallback, protocols: SAFE_MEDIA_URL_PROTOCOLS)
            end
          end
        end
      RUBY
    end
  end
end
