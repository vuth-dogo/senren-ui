# frozen_string_literal: true

# The entry point Bundler reaches for by default.
#
# `gem "senren-ui"` with no `require:` option makes Bundler try "senren-ui",
# then its hyphen-to-slash fallback "senren/ui". Without this file both fail —
# and Bundler swallows the second LoadError, so the app boots with no engine,
# no rake tasks, and no AssetPathGuard, while the generator and `senren:add`
# keep working because they require "senren/rails" themselves.
#
# That combination is the worst possible failure mode: the install looks
# healthy and the production source-disclosure guard is simply absent. The
# README documents `require: "senren/rails"`, which is still correct; this makes
# forgetting it harmless rather than silent.
require 'senren/rails'
