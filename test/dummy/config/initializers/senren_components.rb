repo_root = File.expand_path('../../../..', __dir__)

load File.join(repo_root, 'lib/generators/senren/install/templates/base_component.rb.tt')

component_files = Dir[File.join(repo_root, 'templates/components/*/*_component.rb')]
load_first = [
  File.join(repo_root, 'templates/components/dropdown_menu/dropdown_menu_component.rb')
]

(load_first + (component_files - load_first)).each do |path|
  load path
end
