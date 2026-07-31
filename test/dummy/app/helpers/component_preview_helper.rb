# frozen_string_literal: true

require 'date'
require 'senren/rails'
require 'senren/rails/registry'

# This helper is intentionally exhaustive: the kitchen-sink system test should
# fail when the registry gains a component without a representative preview.
# rubocop:disable Metrics/ModuleLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
module ComponentPreviewHelper
  def preview_component_names
    Senren::Rails::Registry.load!.names
  end

  def render_component_preview(name)
    case name.to_s
    when 'accordion'
      render Senren::AccordionComponent.new(items: [
                                              { id: 'intro', title: 'Intro', content: 'Intro content' },
                                              { id: 'details', title: 'Details', content: 'Details content' }
                                            ])
    when 'activity_feed'
      render Senren::ActivityFeedComponent.new(items: [
                                                 { title: 'Published component',
                                                   description: 'Preview was refreshed',
                                                   time: '1m ago' },
                                                 { title: 'Reviewed test',
                                                   description: 'System coverage passed',
                                                   time: '5m ago' }
                                               ])
    when 'alert'
      render Senren::AlertComponent.new(variant: :info) do |alert|
        alert.with_title { 'Preview ready' }
        alert.with_description { 'The alert component rendered.' }
      end
    when 'alert_dialog'
      render Senren::AlertDialogComponent.new(id: 'preview-alert-dialog') do |dialog|
        dialog.with_trigger { render(Senren::ButtonComponent.new) { 'Open alert dialog' } }
        dialog.with_title { 'Confirm action' }
        dialog.with_description { 'This is an alert dialog preview.' }
        dialog.with_cancel { render(Senren::ButtonComponent.new(variant: :ghost)) { 'Cancel' } }
        dialog.with_confirm { render(Senren::ButtonComponent.new(variant: :destructive)) { 'Confirm' } }
      end
    when 'api_key_field'
      render Senren::ApiKeyFieldComponent.new(value: 'sk_test_1234567890')
    when 'app_shell'
      render Senren::AppShellComponent.new(content_id: 'preview-shell-main') do |shell|
        shell.with_top_nav { render(Senren::TopNavComponent.new(items: nav_items)) }
        shell.with_sidebar { render(Senren::SidebarComponent.new(items: nav_items)) }
        shell.with_header { render(Senren::PageHeaderComponent.new(title: 'Shell preview')) }
        shell.with_footer { 'Preview footer' }
        'Shell content'
      end
    when 'aspect_ratio'
      render(Senren::AspectRatioComponent.new(variant: :video)) { tag.div('Media preview', class: 'grid h-full place-items-center') }
    when 'avatar'
      render Senren::AvatarComponent.new(alt: 'Senren user', fallback: 'SU')
    when 'badge'
      render(Senren::BadgeComponent.new(variant: :success)) { 'Stable' }
    when 'billing_plan_card'
      render Senren::BillingPlanCardComponent.new(
        name: 'Team',
        price: '$19',
        interval: 'month',
        description: 'For small product teams.',
        features: ['Unlimited previews', 'System test helpers'],
        cta_label: 'Choose plan',
        cta_href: '#'
      )
    when 'breadcrumb'
      render Senren::BreadcrumbComponent.new(items: [
                                               { label: 'Home', href: '#' },
                                               { label: 'Components', href: '#' },
                                               { label: 'Preview' }
                                             ])
    when 'bulk_action_bar'
      render Senren::BulkActionBarComponent.new(selected_count: 2) do |bar|
        bar.with_actions { render(Senren::ButtonComponent.new(size: :sm)) { 'Archive' } }
      end
    when 'button'
      render(Senren::ButtonComponent.new(variant: :primary)) { 'Primary button' }
    when 'calendar'
      render Senren::CalendarComponent.new(date: Date.new(2026, 5, 1), selected: Date.new(2026, 5, 15), name: 'date')
    when 'card'
      render Senren::CardComponent.new do |card|
        card.with_header { 'Card header' }
        card.with_body { 'Card body' }
        card.with_footer { 'Card footer' }
      end
    when 'carousel'
      render Senren::CarouselComponent.new(slides: [
                                             { title: 'First slide', description: 'Carousel content', badge: 'New' },
                                             { title: 'Second slide', description: 'More content' }
                                           ])
    when 'checkbox'
      render Senren::CheckboxComponent.new(name: 'terms', label: 'Accept terms', checked: true)
    when 'checkbox_group'
      render Senren::CheckboxGroupComponent.new do |group|
        group.with_legend { 'Notification channels' }
        group.with_option(name: 'channels[]', value: 'email', label: 'Email', checked: true)
        group.with_option(name: 'channels[]', value: 'sms', label: 'SMS')
      end
    when 'clipboard'
      render Senren::ClipboardComponent.new(value: 'copy-this', label: 'Copy token')
    when 'codeblock'
      render Senren::CodeblockComponent.new(
        source: "render Senren::ButtonComponent.new\n",
        language: 'ruby',
        filename: 'preview.rb'
      )
    when 'collapsible'
      render(Senren::CollapsibleComponent.new(title: 'More options')) { 'Hidden options' }
    when 'combobox'
      render Senren::ComboboxComponent.new(name: 'status', placeholder: 'Choose status', options: status_options)
    when 'command'
      render Senren::CommandComponent.new(items: [
                                            { label: 'Open file', description: 'Open a preview file' },
                                            { label: 'Run tests', description: 'Execute system tests' }
                                          ])
    when 'context_menu'
      render Senren::ContextMenuComponent.new do |menu|
        menu.with_trigger { tag.div('Right click target', tabindex: 0) }
        menu.with_item { 'Inspect' }
        menu.with_item { 'Duplicate' }
      end
    when 'data_table'
      render Senren::DataTableComponent.new(columns: table_columns, rows: table_rows, caption: 'Preview rows')
    when 'date_picker'
      render Senren::DatePickerComponent.new(name: 'published_on', value: '2026-05-30')
    when 'dialog'
      render Senren::DialogComponent.new(id: 'preview-dialog') do |dialog|
        dialog.with_trigger { render(Senren::ButtonComponent.new) { 'Open dialog' } }
        dialog.with_title { 'Dialog title' }
        dialog.with_description { 'Dialog description' }
        dialog.with_body { 'Dialog body' }
      end
    when 'dropdown_menu'
      render Senren::DropdownMenuComponent.new do |menu|
        menu.with_trigger { render(Senren::ButtonComponent.new) { 'Open menu' } }
        menu.with_item { 'First action' }
        menu.with_item { 'Second action' }
      end
    when 'empty_state'
      render Senren::EmptyStateComponent.new(title: 'No previews', description: 'Create the first preview.') do |state|
        state.with_actions { render(Senren::ButtonComponent.new) { 'Create preview' } }
      end
    when 'filter_bar'
      render(Senren::FilterBarComponent.new) { render(Senren::SearchInputComponent.new(name: 'q')) }
    when 'form'
      render(Senren::FormComponent.new(url: '#')) do
        render(Senren::InputComponent.new(name: 'email', value: 'user@example.com', 'aria-label': 'Email address'))
      end
    when 'hover_card'
      render Senren::HoverCardComponent.new do |card|
        card.with_trigger { 'Hover user' }
        card.with_content_panel { 'Hover card content' }
      end
    when 'input'
      render Senren::InputComponent.new(name: 'title', value: 'Hello Senren', 'aria-label': 'Title')
    when 'invite_member_dialog'
      render Senren::InviteMemberDialogComponent.new(button_label: 'Invite teammate')
    when 'label'
      render Senren::LabelComponent.new(for_field: 'email', text: 'Email')
    when 'link'
      render(Senren::LinkComponent.new(href: '#')) { 'Documentation link' }
    when 'masked_input'
      render Senren::MaskedInputComponent.new(mask: '999-999', name: 'code', value: '123456', 'aria-label': 'Code')
    when 'native_select'
      render Senren::NativeSelectComponent.new(name: 'status', options: status_options, selected: 'published')
    when 'page_header'
      render Senren::PageHeaderComponent.new(title: 'Page title', description: 'Page description') do |header|
        header.with_eyebrow { 'Preview' }
        header.with_actions { render(Senren::ButtonComponent.new) { 'Action' } }
      end
    when 'pagination'
      render Senren::PaginationComponent.new(current_page: 2, total_pages: 5, path: '/components/kitchen_sink')
    when 'popover'
      render Senren::PopoverComponent.new do |popover|
        popover.with_trigger { render(Senren::ButtonComponent.new) { 'Open popover' } }
        popover.with_content_panel { 'Popover content' }
      end
    when 'progress'
      render Senren::ProgressComponent.new(value: 65, label: 'Build progress')
    when 'radio_button'
      render Senren::RadioButtonComponent.new(name: 'plan', value: 'team', label: 'Team plan', checked: true)
    when 'rich_text_editor_lite'
      render Senren::RichTextEditorLiteComponent.new(name: 'body', value: '<p>Initial content</p>')
    when 'search_input'
      render Senren::SearchInputComponent.new(name: 'site_search', value: 'senren')
    when 'select'
      render Senren::SelectComponent.new(name: 'priority', options: status_options, selected: 'draft')
    when 'separator'
      render Senren::SeparatorComponent.new(variant: :horizontal)
    when 'settings_section'
      render Senren::SettingsSectionComponent.new(title: 'Profile', description: 'Manage profile settings') do |section|
        section.with_actions { render(Senren::ButtonComponent.new(size: :sm)) { 'Save' } }
        'Settings content'
      end
    when 'sheet'
      render Senren::SheetComponent.new(id: 'preview-sheet') do |sheet|
        sheet.with_trigger { render(Senren::ButtonComponent.new) { 'Open sheet' } }
        sheet.with_title { 'Sheet title' }
        sheet.with_description { 'Sheet description' }
        sheet.with_body { 'Sheet body' }
      end
    when 'shortcut_key'
      render Senren::ShortcutKeyComponent.new(keys: %w[Ctrl K])
    when 'sidebar'
      render(Senren::SidebarComponent.new(items: nav_items)) { 'Workspace' }
    when 'skeleton'
      render Senren::SkeletonComponent.new(variant: :text)
    when 'stat_card'
      render Senren::StatCardComponent.new(
        label: 'Revenue',
        value: '$12k',
        change: '+8%',
        helper_text: 'Compared with last month'
      )
    when 'switch'
      render Senren::SwitchComponent.new(name: 'published', label: 'Published', checked: true)
    when 'table'
      render Senren::TableComponent.new(columns: table_columns, rows: table_rows, caption: 'Preview table')
    when 'tabs'
      render Senren::TabsComponent.new(items: [
                                         { id: 'overview', label: 'Overview', content: 'Overview panel' },
                                         { id: 'tab-details', label: 'Details', content: 'Details panel' }
                                       ])
    when 'team_member_list'
      render Senren::TeamMemberListComponent.new(members: [
                                                   { name: 'Ada Lovelace',
                                                     role: 'Owner',
                                                     email: 'ada@example.com' },
                                                   { name: 'Grace Hopper',
                                                     role: 'Admin',
                                                     email: 'grace@example.com' }
                                                 ])
    when 'textarea'
      render Senren::TextareaComponent.new(name: 'notes', value: 'Textarea preview')
    when 'theme_toggle'
      render Senren::ThemeToggleComponent.new(label: 'Toggle theme')
    when 'tooltip'
      render(Senren::TooltipComponent.new(text: 'Helpful tooltip')) { 'Tooltip target' }
    when 'top_nav'
      render Senren::TopNavComponent.new(items: nav_items, current_path: '#') do |nav|
        nav.with_brand { 'Senren' }
        nav.with_actions { render(Senren::ButtonComponent.new(size: :sm)) { 'New' } }
      end
    when 'typography'
      render(Senren::TypographyComponent.new(variant: :p)) { 'Typography text' }
    else
      raise ArgumentError, "Missing preview for #{name}"
    end
  end

  private

  def nav_items
    [
      { label: 'Components', href: '#', active: true },
      { label: 'Docs', href: '#' }
    ]
  end

  def status_options
    [%w[draft Draft], %w[published Published], %w[archived Archived]]
  end

  def table_columns
    [
      { key: :name, label: 'Name' },
      { key: :status, label: 'Status' }
    ]
  end

  def table_rows
    [
      { name: 'Button', status: 'Ready' },
      { name: 'Dialog', status: 'Ready' }
    ]
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
