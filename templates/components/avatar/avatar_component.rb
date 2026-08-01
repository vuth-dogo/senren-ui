# frozen_string_literal: true

module Senren
  class AvatarComponent < BaseComponent
    VARIANTS = { default: '' }.freeze

    SIZES = {
      sm: 'h-8 w-8 text-xs',
      md: 'h-10 w-10 text-sm',
      lg: 'h-14 w-14 text-base'
    }.freeze

    def initialize(src: nil, alt: nil, fallback: nil, initials: nil, size: :md, class_name: nil, **html)
      super(variant: :default, size: size, class_name: class_name, **html)
      @src = src
      @alt = alt
      @fallback = fallback.presence || initials.presence || initials_from_alt
    end

    attr_reader :alt, :fallback

    # Avatar sources are user-controlled by nature — a profile URL is the
    # canonical example — and this one reaches image_tag. Rails' asset_path
    # incidentally neutralises `javascript:`, so this is not XSS, but an
    # off-origin `//tracker.example/x.gif` is a beacon that fires for every
    # viewer of the page. safe_media_url is the media-specific policy.
    def src = @src && safe_media_url(@src)

    private

    def initials_from_alt
      return '' if alt.blank?

      alt.split.map(&:first).first(2).join.upcase
    end
  end
end
