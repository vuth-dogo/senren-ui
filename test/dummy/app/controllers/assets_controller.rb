class AssetsController < ActionController::Base
  skip_forgery_protection

  REPO_ROOT = File.expand_path('../../../..', __dir__)

  def application
    serve_file Rails.root.join('app/javascript/application.js')
  end

  def stimulus
    serve_file Rails.root.join('app/javascript/vendor/stimulus_lite.js')
  end

  def senren_controller
    name = params.fetch(:name_controller).delete_suffix('_controller')
    return head :not_found unless name.match?(/\A[a-z0-9_]+\z/)

    serve_file File.join(REPO_ROOT, 'templates/controllers', "#{name}_controller.js")
  end

  private

  def serve_file(path)
    return head :not_found unless File.file?(path)

    response.headers['Cache-Control'] = 'no-store'
    render plain: File.read(path), content_type: 'application/javascript'
  end
end
