class UserMailer < ApplicationMailer
  def verification_required(user)
    @user = user
    @url = "#{App.base_url}/users/#{user.activation_token}/verify"
    mail to: user.email, subject: t('auth.verification_required')
  end

  def verified(user)
    @user = user
    @url = "#{App.base_url}/login"
    mail to: user.email, subject: t('auth.account_verified')
  end

  def reset_password(user)
    @user = user
    @url = "#{App.base_url}/password_resets/#{user.reset_password_token}/edit"
    mail to: user.email, subject: t('auth.password_reset')
  end
end
