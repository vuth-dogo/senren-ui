module Senren
  class RichTextEditorLiteComponent < BaseComponent
    VARIANTS = {
      default: 'border-[hsl(var(--senren-border))] bg-[hsl(var(--senren-card))]'
    }.freeze
    SIZES = { md: '' }.freeze

    def initialize(name: 'content', value: nil, label: senren_t('rich_text_editor_lite.label', default: 'Content'),
                   placeholder: senren_t('rich_text_editor_lite.placeholder', default: 'Write something...'), id: nil,
                   toolbar: true, debug: ::Rails.env.development?, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @name = name
      @value = value
      @label = label
      @placeholder = placeholder
      @dom_id = id || senren_dom_id(name)
      @toolbar = toolbar
      @debug = debug
    end

    attr_reader :name, :value, :label, :placeholder, :dom_id

    def toolbar? = !!@toolbar

    def debug? = !!@debug

    # Read by the controller from a Stimulus value, so the prompt it opens is in
    # the host's language without a sentence living in JavaScript.
    def link_prompt = senren_t('rich_text_editor_lite.link_prompt', default: 'Paste a URL')

    # [command, visible text, aria-label]. `P`, `H1`-`H3`, `B`, `I` and `1.` are
    # symbols, not words, so they are not translated; every word is.
    def toolbar_buttons
      [
        ['formatBlock:p', 'P', senren_t('rich_text_editor_lite.toolbar.paragraph', default: 'Paragraph')],
        ['formatBlock:h1', 'H1', senren_t('rich_text_editor_lite.toolbar.heading_1', default: 'Heading 1')],
        ['formatBlock:h2', 'H2', senren_t('rich_text_editor_lite.toolbar.heading_2', default: 'Heading 2')],
        ['formatBlock:h3', 'H3', senren_t('rich_text_editor_lite.toolbar.heading_3', default: 'Heading 3')],
        ['bold', 'B', senren_t('rich_text_editor_lite.toolbar.bold', default: 'Bold')],
        ['italic', 'I', senren_t('rich_text_editor_lite.toolbar.italic', default: 'Italic')],
        ['createLink', senren_t('rich_text_editor_lite.toolbar_short.link', default: 'Link'),
         senren_t('rich_text_editor_lite.toolbar.create_link', default: 'Create link')],
        ['insertUnorderedList', senren_t('rich_text_editor_lite.toolbar_short.list', default: 'List'),
         senren_t('rich_text_editor_lite.toolbar.bulleted_list', default: 'Bulleted list')],
        ['insertOrderedList', '1.', senren_t('rich_text_editor_lite.toolbar.numbered_list', default: 'Numbered list')],
        ['align:left', senren_t('rich_text_editor_lite.toolbar_short.left', default: 'Left'),
         senren_t('rich_text_editor_lite.toolbar.align_left', default: 'Align left')],
        ['align:center', senren_t('rich_text_editor_lite.toolbar_short.center', default: 'Center'),
         senren_t('rich_text_editor_lite.toolbar.align_center', default: 'Align center')],
        ['align:right', senren_t('rich_text_editor_lite.toolbar_short.right', default: 'Right'),
         senren_t('rich_text_editor_lite.toolbar.align_right', default: 'Align right')],
        ['align:justify', senren_t('rich_text_editor_lite.toolbar_short.justify', default: 'Justify'),
         senren_t('rich_text_editor_lite.toolbar.justify', default: 'Justify')]
      ]
    end

    def initial_content
      value.presence || content.to_s.presence || "<p>#{ERB::Util.html_escape(placeholder)}</p>"
    end
  end
end
