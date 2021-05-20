# frozen_string_literal: true
class UserPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def edit_preferences?
    users_match?
  end

  def update_preferences?
    users_match_and_verified?
  end

  def update_email?
    users_match?
  end

  def update_password?
    users_match_and_verified? && not_external?
  end

  private

  def users_match?
    current_user == user
  end

  def not_external?
    !user.external?
  end

  def users_match_and_verified?
    users_match? && user.verified?
  end
end
