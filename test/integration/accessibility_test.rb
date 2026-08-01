# frozen_string_literal: true

require_relative '../application_integration_test_case'
require 'nokogiri'

# Structural accessibility checks against the rendered pages.
#
# The registry carries an `accessibility` note for all 62 components, but it is
# prose — "role=separator with aria-orientation" — and nothing asserted the
# markup matched. These are the invariants that can be checked mechanically and
# that break silently: a duplicate id quietly detaches aria-controls, an
# aria-controls pointing at nothing is a dead reference, an anchor without href
# is not focusable, and a control with no accessible name is unusable by a
# screen reader.
#
# This is not a substitute for axe or manual testing. It is the subset a
# renderer can prove.
class AccessibilityTest < ApplicationIntegrationTestCase
  PAGES = %w[/components/static /components/interactive /components/kitchen_sink].freeze

  # https://www.w3.org/TR/wai-aria-1.2/#role_definitions — the roles this
  # library actually uses, plus the common structural ones.
  VALID_ROLES = %w[
    alert alertdialog button checkbox combobox dialog grid gridcell group
    heading img link list listbox listitem menu menubar menuitem
    menuitemcheckbox menuitemradio navigation none note option presentation
    progressbar radio radiogroup region row rowgroup rowheader columnheader
    search searchbox separator status switch tab table tablist tabpanel
    textbox toolbar tooltip treeitem banner main complementary contentinfo form
  ].freeze

  def each_page
    PAGES.each do |path|
      get path

      assert_response :success, "#{path} must render"
      yield path, Nokogiri::HTML5.parse(response.body)
    end
  end

  # Duplicate ids silently break every aria-controls, aria-labelledby, and
  # <label for> that points at them: the browser resolves the first match.
  def test_element_ids_are_unique
    each_page do |path, doc|
      ids = doc.css('[id]').map { |node| node['id'] }
      duplicates = ids.tally.select { |_, count| count > 1 }.keys

      assert_empty duplicates, "#{path} has duplicate ids: #{duplicates.join(', ')}"
    end
  end

  def test_roles_are_valid_aria_roles
    each_page do |path, doc|
      invalid = doc.css('[role]').map { |node| node['role'] }.flat_map(&:split).uniq - VALID_ROLES

      assert_empty invalid, "#{path} uses unknown ARIA roles: #{invalid.join(', ')}"
    end
  end

  # A reference to an id that is not on the page is dead: assistive technology
  # has nothing to announce or navigate to.
  def test_aria_references_point_at_elements_that_exist
    %w[aria-controls aria-labelledby aria-describedby].each do |attribute|
      each_page do |path, doc|
        ids = doc.css('[id]').to_set { |node| node['id'] }
        dangling = doc.css("[#{attribute}]").flat_map { |node| node[attribute].split }.uniq - ids.to_a

        assert_empty dangling, "#{path}: #{attribute} points at missing ids: #{dangling.join(', ')}"
      end
    end
  end

  # The registry says of link: "Use real anchors for navigation, never buttons."
  # An anchor without href is not focusable and not announced as a link, which
  # is the same failure from the other direction.
  def test_anchors_are_focusable
    each_page do |path, doc|
      hrefless = doc.css('a').reject { |node| node['href'] || node['role'] }

      assert_empty hrefless.map(&:to_html), "#{path} has anchors without href"
    end
  end

  # Every control a user can operate needs a name from somewhere: its text, an
  # aria-label, an aria-labelledby, or an associated <label>.
  def test_interactive_controls_have_accessible_names
    each_page do |path, doc|
      labelled_ids = doc.css('label[for]').to_set { |node| node['for'] }

      unnamed = doc.css('button, input, select, textarea')
                   .reject { |node| node['type'] == 'hidden' }
                   .reject { |node| accessible_name?(node, labelled_ids) }

      assert_empty unnamed.map { |node| node.to_html[0, 90] },
                   "#{path} has controls with no accessible name"
    end
  end

  # The ways a control can acquire an accessible name, in rough order of how
  # often this library uses them. The wrapping-label case matters most: the
  # checkbox, radio, and switch components put the input inside the <label>
  # rather than pairing them by id, and an earlier version of this check
  # reported all of them as unnamed.
  def accessible_name?(node, labelled_ids)
    return true if %w[aria-label aria-labelledby title placeholder].any? { |attr| node[attr].to_s.strip.present? }
    return true if node.text.strip.present?
    return true if labelled_ids.include?(node['id'])

    node.ancestors('label').any? { |label| label.text.strip.present? }
  end

  # aria-hidden removes a subtree from the accessibility tree; a focusable
  # element inside one can still be tabbed to and then announces nothing.
  def test_aria_hidden_subtrees_contain_nothing_focusable
    each_page do |path, doc|
      trapped = doc.css('[aria-hidden="true"]').flat_map do |node|
        node.css('a[href], button, input, select, textarea, [tabindex]')
            .reject { |child| child['tabindex'] == '-1' }
      end

      assert_empty trapped.map { |node| node.to_html[0, 90] },
                   "#{path} has focusable elements inside aria-hidden"
    end
  end
end
