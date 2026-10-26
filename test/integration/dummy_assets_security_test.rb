# frozen_string_literal: true

require_relative '../application_integration_test_case'

class DummyAssetsSecurityTest < ApplicationIntegrationTestCase
  def test_known_controller_is_served_without_a_csrf_token
    get '/assets/controllers/senren/dialog_controller.js'

    assert_response :success
    assert_equal 'application/javascript', response.media_type
    assert_equal 'no-store', response.headers['Cache-Control']
    assert_equal File.read(File.expand_path('../../templates/controllers/dialog_controller.js', __dir__)), response.body
  end

  def test_the_other_read_only_asset_routes_still_work
    %w[application stimulus].each do |name|
      get "/assets/#{name}.js"

      assert_response :success
      assert_equal 'application/javascript', response.media_type
    end
  end

  def test_an_unknown_controller_name_is_rejected
    get '/assets/controllers/senren/not_registered_controller.js'

    assert_response :not_found
  end

  def test_traversal_names_are_not_routable
    assert_raises(ActionController::RoutingError) do
      get '/assets/controllers/senren/..%2f..%2fGemfile_controller.js'
    end
  end

  def test_asset_routes_do_not_accept_state_changing_requests
    assert_raises(ActionController::RoutingError) do
      post '/assets/controllers/senren/dialog_controller.js'
    end
  end
end
