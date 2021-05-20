# frozen_string_literal: true
class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create verify]

  layout 'public', only: %i[new]

  def new
    @user = User.new(subscribe_newsletter: true)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user, true)
      redirect_to dashboard_path
    else
      redirect_to new_user_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def verify
    if (@user = User.load_from_activation_token(params[:id]))
      @user.activate!
      auto_login(@user, true)
      redirect_to dashboard_path, notice: t('auth.user_verified')
    else
      not_authenticated
    end
  end

  def edit_preferences
    authorize current_user
  end

  def update_preferences
    authorize current_user
    if current_user.update(user_pref_params)
      redirect_to edit_preferences_user_path(current_user), notice: t('users.update_prefs_success')
    else
      flash.now[:alert] = t('users.update_prefs_fail', msg: user_errors)
      render :edit_preferences
    end
  end

  def update_email
    authorize current_user
    return update_email_success if current_user.update(user_email_attrs)
    update_email_fail
  end

  def update_password
    authorize current_user
    current_user.password_confirmation = params[:user][:password_confirmation]
    return update_password_success if current_user.change_password(params[:user][:password])
    update_password_fail
  end

  def resend_verification
    current_user.resend_verification_email
    redirect_to dashboard_path, notice: t('auth.verification_resent', email: current_user.email)
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :subscribe_newsletter)
  end

  def user_pref_params
    params.require(:user).permit(:subscribe_newsletter, :theme)
  end

  def user_email_attrs
    {
      activation_state: :pending,
      email: params[:user][:email]
    }
  end

  def user_errors
    current_user.errors.full_messages.to_sentence
  end

  def update_password_success
    redirect_to edit_preferences_user_path(current_user), notice: t('users.update_password_success')
  end

  def update_password_fail
    flash.now[:alert] = t('users.update_password_fail', msg: user_errors)
    render :edit_preferences
  end

  def update_email_success
    current_user.resend_verification_email
    redirect_to edit_preferences_user_path(current_user), notice: t('users.update_email_success')
  end

  def update_email_fail
    flash.now[:alert] = t('users.update_email_fail', msg: user_errors)
    render :edit_preferences
  end
end
