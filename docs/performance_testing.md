# Performance Testing

Senren uses CI-safe performance gates by default. The goal is to catch
regressions that this source-copy UI gem can control: template payload
growth, Stimulus controller payload growth, eager controller loading, and
runtime-heavy client behavior.

## Commands

```bash
bin/performance
bin/system
bin/ci
```

`bin/performance` reads `config/performance_budgets.yml`.
`bin/system` runs headless browser tests against `test/dummy`.

`bin/system` runs Selenium against headless Chrome. It uses a system
Chrome/Chromium and `/usr/bin/chromedriver` when they are present (the Linux CI
image), and otherwise lets Selenium Manager resolve and download a matching
driver — so macOS and other local machines need no setup.

Set `SENREN_CHROME_BIN` or `SENREN_CHROMEDRIVER` only to force a specific
binary; leaving them unset is the supported path.

## Benchmark Model

- Static budgets are deterministic and run on every PR.
- System tests verify browser behavior and coarse budgets.
- Lighthouse CI is deferred until a stable preview/docs URL exists.
- Competitive framework benchmarking is out of scope for normal CI.

## Browser Budgets

System tests assert gross DOM size, controller loading, external resource,
and interaction-duration budgets. They intentionally avoid tight timing
thresholds because shared CI hardware is noisy.
