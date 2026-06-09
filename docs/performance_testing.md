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

`bin/system` uses Selenium with local Chromium/ChromeDriver by default.
Override paths with `SENREN_CHROME_BIN` and `SENREN_CHROMEDRIVER` if your
machine installs them somewhere else.

## Benchmark Model

- Static budgets are deterministic and run on every PR.
- System tests verify browser behavior and coarse budgets.
- Lighthouse CI is deferred until a stable preview/docs URL exists.
- Competitive framework benchmarking is out of scope for normal CI.

## Browser Budgets

System tests assert gross DOM size, controller loading, external resource,
and interaction-duration budgets. They intentionally avoid tight timing
thresholds because shared CI hardware is noisy.
