# frozen_string_literal: true
class User < ApplicationRecord
  include TokenRegisterable
  extend Enumerize

  authenticates_with_sorcery!

  enumerize :theme, in: %w[light dark], default: 'light'

  has_many :profiles, dependent: :destroy
  has_many :owned_teams,
           class_name: 'Team',
           foreign_key: :owner_user_id,
           inverse_of: :owning_user,
           dependent: :nullify
  has_many :authentications, dependent: :destroy

  attribute :subscribe_newsletter,  :boolean, default: true
  attribute :admin,                 :boolean, default: false

  validates :password, length: { minimum: App.password_length }, if: :password
  validates :password, confirmation: true, if: :password
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  accepts_nested_attributes_for :authentications

  def verified?
    activation_state == 'active'
  end

  def resend_verification_email
    setup_activation
    save!
    send(:send_activation_needed_email!)
  end
end
