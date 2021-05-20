# frozen_string_literal: true
class PasswordResetsController < ApplicationController
  before_action :load_user_from_token, only: :update
  skip_before_action :require_login

  layout 'public', only: %i[new edit]

  def new; end

  def create
    @user = User.find_by(email: params[:email])
    @user&.deliver_reset_password_instructions!

    redirect_to new_password_reset_path, notice: t('auth.password_reset_sent')
  end

  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]
    not_authenticated unless @user
  end

  def update
    return not_authenticated if @user.blank?

    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.change_password(params[:user][:password])
      auto_login(@user, true)
      return redirect_to dashboard_path, notice: t('auth.password_updated')
    end

    render action: :edit
  end

  private

  def load_user_from_token
    @token = params[:user][:token]
    @user = User.load_from_reset_password_token(@token)
  end
end
