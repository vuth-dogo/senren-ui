module Senren
  class CalendarComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(date: Date.current, selected: nil, name: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @date = date.to_date
      @selected = selected&.to_date
      @name = name
    end

    attr_reader :date, :selected, :name

    def month_start = date.beginning_of_month
    def month_end = date.end_of_month
    def title = date.strftime('%B %Y')
    def weekday_labels = Date::ABBR_DAYNAMES

    def calendar_days
      start_day = month_start.beginning_of_week(:sunday)
      end_day = month_end.end_of_week(:sunday)
      (start_day..end_day).to_a
    end

    def selected?(day)
      selected && day == selected
    end
  end
end
