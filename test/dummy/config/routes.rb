Rails.application.routes.draw do
  root 'components#static'

  get 'components/static', to: 'components#static'
  get 'components/interactive', to: 'components#interactive'
  get 'components/kitchen_sink', to: 'components#kitchen_sink'
  get 'components/red_team', to: 'components#red_team'

  get 'favicon.ico', to: ->(_env) { [204, {}, []] }
  get 'assets/application.js', to: 'assets#application', defaults: { format: :js }
  get 'assets/stimulus.js', to: 'assets#stimulus', defaults: { format: :js }
  get 'assets/controllers/senren/:name_controller',
      to: 'assets#senren_controller',
      defaults: { format: :js },
      constraints: { name_controller: /[a-z0-9_]+_controller/ }
end
