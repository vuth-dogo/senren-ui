# frozen_string_literal: true

require_relative 'lib/senren/rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'senren-ui'
  spec.version       = Senren::Rails::VERSION
  spec.authors       = ['vutt']
  spec.email         = ['thanhvu8a1@gmail.com']

  spec.summary       = 'Rails-native UI component library with ViewComponent, Hotwire, Tailwind, and AI-agent ' \
                       'skill files.'
  spec.description   = <<~DESC
    Senren UI is a Rails-native UI component library inspired by the developer
    experience of shadcn/ui. It ships generators, a registry, and a centralized
    AI-agent skill system. Components are copied into the host app (source-copy
    architecture) so developers and AI agents can read and edit them directly.
  DESC
  spec.homepage      = 'https://github.com/vuth-dogo/senren-ui'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/tree/main"
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    '{lib,registry,templates,docs}/**/*',
    'MIT-LICENSE',
    'LICENSE',
    'Rakefile',
    'README.md',
    'CHANGELOG.md',
    'CONTRIBUTING.md'
  ].select { |f| File.file?(f) }

  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 7.1'
  spec.add_dependency 'view_component', '>= 3.0'
end
