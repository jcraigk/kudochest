# frozen_string_literal: true
class OpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login

  def healthz
    render plain: 'OK'
  end
end
