# frozen_string_literal: true

module Senren
  class PaginationComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(current_page: 1, total_pages: 1, path: nil, label: 'Pagination', class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @total_pages = [total_pages.to_i, 1].max
      @current_page = current_page.to_i.clamp(1, @total_pages)
      @path = path
      @label = label
    end

    attr_reader :current_page, :total_pages, :path, :label

    def page_url(page)
      return '#' unless path

      safe_page = page.to_i.clamp(1, total_pages)
      safe_url(path.respond_to?(:call) ? path.call(safe_page) : path.to_s.gsub(':page', safe_page.to_s))
    end
  end
end
