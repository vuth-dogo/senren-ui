## Summary

- What changed?
- Why was it needed?

## Validation

- [ ] `bundle exec rake test`
- [ ] `bundle exec rubocop`
- [ ] `bun run controllers:check` (if JS changed)

## Senren repo rules

- [ ] I updated or created a matching file in `plans/` for architectural changes.
- [ ] I updated or created a matching file in `history/` for the implementation session.
- [ ] I kept `data-senren-component` on the real root element for any touched component.

## Release and safety notes

- [ ] This PR does not introduce secrets, tokens, or private keys.
- [ ] This PR does not add a new JS framework or network calls from Stimulus.
