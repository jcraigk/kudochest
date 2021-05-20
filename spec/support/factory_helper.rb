# frozen_string_literal: true
module FactoryHelper
  def self.rid(platform, first_char = nil)
    case platform.to_sym
    when :slack then slack_rid(first_char)
    when :discord then discord_rid
    end
  end

  def self.slack_rid(first_char)
    chars = [('A'..'Z'), (0..9)].map(&:to_a).flatten
    rid = (0...8).map { chars[rand(chars.length)] }.join
    first_char + rid
  end

  def self.discord_rid
    rand(1_000_000..9_999_999_999)
  end
end
