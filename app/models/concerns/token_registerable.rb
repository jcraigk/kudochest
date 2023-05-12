module TokenRegisterable
  extend ActiveSupport::Concern

  TOKEN_CHARS = (0..9).to_a + ('a'..'z').to_a
  TOKEN_LENGTH = 10

  included do
    before_create :generate_reg_token
    validates :reg_token, uniqueness: true
  end

  def generate_reg_token
    self.reg_token = loop do
      token = TOKEN_CHARS.sort_by { rand }.join[0...TOKEN_LENGTH]
      break token unless self.class.unscoped.where.not(id:).find_by(reg_token: token)
    end
  end

  def reset_reg_token!
    generate_reg_token
    save!
  end
end
