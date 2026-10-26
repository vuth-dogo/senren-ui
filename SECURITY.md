# Security Policy

## Supported Versions

Security fixes are applied to the latest released tag on `main`. Older
tags may receive guidance, but fixes are not guaranteed to be backported.

### Rails compatibility and security support

The test matrix includes Rails 7.1 to check compatibility. That line no longer
receives upstream security patches: Rails 7.1.6 still has known vulnerabilities.
Use a maintained Rails line with its latest security patches for deployed apps.
For Rails 7.2, use at least 7.2.3.2; later Rails lines also need their current
security patches. An application's own lockfile must be audited independently
of this library's development bundle.

## Reporting a Vulnerability

Please do not open public GitHub issues for security problems.

Use one of these private channels instead:

1. GitHub Security Advisories:
   `https://github.com/vuth-dogo/senren-ui/security/advisories/new`
2. Email the maintainer at `thanhvu8a1@gmail.com`

When reporting, include:

- affected gem version or commit SHA
- reproduction steps
- impact assessment
- any suggested fix or mitigation

You should expect an acknowledgment within 72 hours. If the report is
valid, the fix will be prepared privately and disclosed after a patch or
mitigation is ready.
