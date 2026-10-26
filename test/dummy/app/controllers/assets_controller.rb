class AssetsController < ActionController::Base
  # These GET endpoints publish static JavaScript for normal script/module tags.
  # Rails' separate non-XHR JavaScript response check would reject those tags;
  # keep the CSRF token verifier and exempt only these public script responses.
  skip_after_action :verify_same_origin_request,
                    only: %i[application stimulus senren_controller], if: -> { request.get? }

  REPO_ROOT = File.expand_path('../../../..', __dir__)
  CONTROLLER_FILES = Dir.glob(File.join(REPO_ROOT, 'templates/controllers/*_controller.js')).to_h do |path|
    [File.basename(path, '.js'), path]
  end.freeze

  def application
    serve_file Rails.root.join('app/javascript/application.js')
  end

  def stimulus
    serve_file Rails.root.join('app/javascript/vendor/stimulus_lite.js')
  end

  def senren_controller
    path = CONTROLLER_FILES[params[:name_controller]]
    return head :not_found unless path

    serve_file path
  end

  private

  def serve_file(path)
    return head :not_found unless File.file?(path)

    response.headers['Cache-Control'] = 'no-store'
    render plain: File.read(path), content_type: 'application/javascript'
  end
end
