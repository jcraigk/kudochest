# frozen_string_literal: true
module KarmaHelper
  def karma_format(value)
    return '0' if value.to_f.zero?
    format('%<value>.2f', value: value)
      .delete_suffix('0')
      .delete_suffix('0')
      .delete_suffix('.')
      .reverse
      .scan(/(\d*\.\d{1,3}|\d{1,3})/)
      .join(',')
      .reverse
      .delete_prefix('0')
  end
end
