# frozen_string_literal: true

module Senren
  class CarouselComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(slides: [], label: senren_t('carousel.label', default: 'Carousel'), class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @slides = normalize_slides(slides)
      @label = label
    end

    attr_reader :slides, :label

    def previous_label = senren_t('carousel.previous', default: 'Previous slide')
    def next_label = senren_t('carousel.next', default: 'Next slide')
    def go_to_label(number) = senren_t('carousel.go_to', default: 'Go to slide %{number}', number: number)

    # The announcement as the server first renders it, and the same sentence as a
    # template for the controller, which has to say it again on every slide
    # change. No values are passed for the template, so I18n hands back the
    # `%{current}` and `%{total}` placeholders untouched.
    def status_text = senren_t('carousel.status', default: 'Slide %{current} of %{total}', current: 1, total: slides.size)
    def status_template = senren_t('carousel.status', default: 'Slide %{current} of %{total}')

    private

    def normalize_slides(slides)
      Array(slides).map do |slide|
        if slide.is_a?(Hash)
          {
            title: slide[:title] || slide['title'],
            description: slide[:description] || slide['description'],
            image_url: safe_media_url(slide[:image_url] || slide['image_url']),
            alt: slide[:alt] || slide['alt'],
            badge: slide[:badge] || slide['badge']
          }
        else
          { title: slide.to_s, description: nil, image_url: nil, alt: nil, badge: nil }
        end
      end
    end
  end
end
