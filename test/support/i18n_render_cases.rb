# frozen_string_literal: true

require 'date'

# Arguments that make a component show every string it has to show.
#
# A default render does not reach them all: the calendar shows one month name at
# a time, a cart has a different sentence when it is empty, a product card says
# "Out of stock" only when it is, and a tab with no label falls back to "Tab 1".
# Each entry below is one render that reaches something a default one does not.
#
# Used by the rendering test to prove every key in the catalogue appears in real
# markup. Plain data, so a script outside the suite can render the same cases.
module I18nRenderCases
  MONTHS = (1..12).map { |month| ['calendar', { date: Date.new(2026, month, 1), name: 'day' }] }

  CASES = [
    ['accordion', { items: [{ content: 'Body' }, { title: 'Named', content: 'Body' }] }],
    ['alert_dialog', {}],
    ['api_key_field', { value: 'not-a-real-key' }],
    ['app_shell', {}],
    ['breadcrumb', { items: [['Home', '/'], ['Page']] }],
    ['bulk_action_bar', {}],
    ['bulk_action_bar', { selected_count: 3 }],
    *MONTHS,
    ['carousel', { slides: %w[One Two Three] }],
    ['cart', { items: [{ id: 'sku-1', name: 'Mug', price_cents: 1_450, quantity: 2 }], checkout_url: '/checkout' }],
    ['cart', {}],
    ['clipboard', { value: 'copy me' }],
    ['collapsible', {}],
    ['combobox', { name: 'status', options: [%w[a A]] }],
    ['command', { items: [{ label: 'Open file' }] }],
    ['data_table', { columns: [:name], rows: [] }],
    ['data_table', { columns: [:name], rows: [{ name: 'Row' }] }],
    ['date_picker', { name: 'day' }],
    ['dialog', {}],
    ['filter_bar', {}],
    ['invite_member_dialog', {}],
    ['pagination', { current_page: 2, total_pages: 3 }],
    ['product_card', { title: 'Mug', price: '$14.50', url: '/cart/items' }],
    ['product_card', { title: 'Mug', price: '$14.50', url: '/cart/items', available: false }],
    ['rich_text_editor_lite', {}],
    ['search_input', {}],
    ['sheet', {}],
    ['sidebar', { items: [['Home', '/']] }],
    ['tabs', { items: [{ content: 'Body' }] }],
    ['theme_toggle', {}],
    ['top_nav', { items: [['Home', '/']] }]
  ].freeze
end
