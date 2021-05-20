# frozen_string_literal: true
class Hooks::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_before_action :verify_authenticity_token
end
