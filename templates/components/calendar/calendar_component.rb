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

    def title
      senren_t('calendar.title', default: '%{month} %{year}',
                                 month: month_names.fetch(date.month - 1), year: date.strftime('%Y'))
    end

    # Spelled out call by call rather than looped over a table, so each name is
    # a literal key that bin/i18n-sync can read and a translator can find.
    def month_names
      [
        senren_t('calendar.months.january', default: 'January'),
        senren_t('calendar.months.february', default: 'February'),
        senren_t('calendar.months.march', default: 'March'),
        senren_t('calendar.months.april', default: 'April'),
        senren_t('calendar.months.may', default: 'May'),
        senren_t('calendar.months.june', default: 'June'),
        senren_t('calendar.months.july', default: 'July'),
        senren_t('calendar.months.august', default: 'August'),
        senren_t('calendar.months.september', default: 'September'),
        senren_t('calendar.months.october', default: 'October'),
        senren_t('calendar.months.november', default: 'November'),
        senren_t('calendar.months.december', default: 'December')
      ]
    end

    # Sunday first, matching calendar_days.
    def weekday_labels
      [
        senren_t('calendar.weekdays.sun', default: 'Sun'),
        senren_t('calendar.weekdays.mon', default: 'Mon'),
        senren_t('calendar.weekdays.tue', default: 'Tue'),
        senren_t('calendar.weekdays.wed', default: 'Wed'),
        senren_t('calendar.weekdays.thu', default: 'Thu'),
        senren_t('calendar.weekdays.fri', default: 'Fri'),
        senren_t('calendar.weekdays.sat', default: 'Sat')
      ]
    end

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
