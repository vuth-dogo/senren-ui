# Plan 024 - Cart and Product List

## Purpose

Add the two components a storefront needs — a product tile that adds to a cart,
and the cart itself — and use them as the reference implementation of the
conventions established in plan 023.

This library is instruction material for AI agents as much as it is code. A new
component is therefore judged twice: does it work, and does it show the right
way to build the next one.

## Scope

- `product_card` — image, title, price, and an add-to-cart action.
- `cart` — line items with quantity steppers, a live subtotal, and removal.
- A `storefront` recipe composing them with existing components.

Out of scope:

- Persistence, pricing rules, tax, currency conversion. The server owns those.
- Any network call from a Stimulus controller. The repo forbids it, and Turbo
  already covers server state.

## Decisions

1. **The server owns the cart; the client owns the widget.** Adding to the cart
   is an ordinary form submission that Turbo handles. The Stimulus controller
   only does what cannot round-trip pleasantly: stepping a quantity and
   recomputing the displayed subtotal while the user clicks. Nothing is
   invented client-side that the server would disagree with.
2. **`product_card` needs no JavaScript.** It renders a form. Declaring it
   `client: false` keeps a storefront listing page free of controller downloads,
   which matters because a listing renders the tile many times.
3. **Money is passed in as it should be displayed.** Components take
   `price_cents` and a preformatted `price`, and never do currency formatting.
   Formatting is locale- and money-library-specific and belongs to the host app;
   a UI library that guesses gets it wrong in another country.
4. **The cart follows the value-driven pattern from plan 023.** Quantity lives
   in a Stimulus value, actions only assign it, and `quantityValueChanged` does
   the DOM work. That makes a server-rendered quantity authoritative, survives
   a Turbo morph, and lets a Turbo Stream update a line without a JS call.
5. **Changes are announced, not assumed.** The controller dispatches
   `senren--cart:changed` with the new subtotal so a host app can update a
   header badge without reaching into the component's internals.
6. **Empty state is part of the component.** A cart is empty most of the time;
   leaving that to the caller guarantees inconsistent storefronts.

## Files to create

- `templates/components/product_card/product_card_component.{rb,html.erb}`
- `templates/components/cart/cart_component.{rb,html.erb}`
- `templates/controllers/cart_controller.js`
- `test/components/cart_component_test.rb`
- `test/system/cart_system_test.rb`

## Files to modify

- `registry/components.yml` — both entries, full schema.
- `registry/recipes.yml` — a `storefront` recipe.
- `test/dummy/app/helpers/component_preview_helper.rb` — previews, which is what
  enrols both components in the render, variant, determinism, and accessibility
  suites automatically.
- `test/dummy/app/views/components/interactive.html.erb` — a cart for the system
  test to drive.

## Expected behavior

- A product tile renders its image, title, price, and an add-to-cart button that
  submits to the given URL. With no image it renders a neutral placeholder
  rather than a broken image.
- A cart renders each line with a quantity stepper and a remove control, plus a
  subtotal.
- Stepping a quantity updates that line's total and the subtotal immediately,
  and never goes below one.
- Removing a line removes it from the subtotal.
- An empty cart renders its empty state, not an empty box.
- Rendering a cart with a server-set quantity shows that quantity with no
  JavaScript involvement.

## Test strategy

The registry-driven suites cover both components as soon as they have a preview:
rendering, every declared variant and size, byte-stable output, and the
structural accessibility rules. Only what those cannot express is written by
hand:

- a component test for the money and quantity arithmetic, which is pure Ruby
- a system test for stepping, removing, the subtotal, and the dispatched event

## Acceptance criteria

- [ ] Both components render in the kitchen sink and in every declared variant.
- [ ] `product_card` ships no controller and adds no JavaScript to a page.
- [ ] Cart quantity is driven by a Stimulus value, not by reading the DOM.
- [ ] Subtotal updates on step and on remove.
- [ ] `senren--cart:changed` fires with the new subtotal.
- [ ] `bin/ci` passes.
