class ErrorsController < ApplicationController
  skip_before_action :require_login

  layout 'public'

  def forbidden
    render status: :forbidden, template: 'public/errors/403', formats: %i[html]
  end

  def not_found
    render status: :not_found, template: 'public/errors/404', formats: %i[html]
  end

  def internal_server_error
    render status: :internal_server_error, template: 'public/errors/500', formats: %i[html]
  end
end
