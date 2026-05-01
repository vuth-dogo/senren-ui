# frozen_string_literal: true

module Senren
  class CarouselComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(slides: [], label: 'Carousel', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @slides = normalize_slides(slides)
      @label = label
    end

    attr_reader :slides, :label

    private

    def normalize_slides(slides)
      Array(slides).map do |slide|
        if slide.is_a?(Hash)
          {
            title: slide[:title] || slide['title'],
            description: slide[:description] || slide['description'],
            image_url: slide[:image_url] || slide['image_url'],
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
