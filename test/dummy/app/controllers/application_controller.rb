class ApplicationController < ActionController::Base
  layout 'application'

  # `?locale=vi` renders the page in Vietnamese, the way a host with a language
  # switch would. It exists so the browser tests can prove the strings a Stimulus
  # controller writes after load come from the server's translation, not from
  # JavaScript. Anything outside the list is ignored rather than trusted.
  around_action :use_requested_locale

  private

  def use_requested_locale(&)
    I18n.with_locale(params[:locale].presence_in(%w[en vi]) || I18n.default_locale, &)
  end
end
