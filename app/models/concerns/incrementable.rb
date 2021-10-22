# frozen_string_literal: true
module Incrementable
  extend ActiveSupport::Concern

  # https://apidock.com/rails/ActiveRecord/Base/increment!
  def increment_with_sql!(attr, quantity, decrement)
    op = decrement ? '-' : '+'
    value_case = "CASE WHEN #{attr} IS NULL THEN 0 ELSE #{attr} END"
    sql = "#{attr} = #{value_case} #{op} #{quantity.to_i} WHERE id = #{id}"
    self.class.update_all(sql) # rubocop:disable Rails/SkipsModelValidations
    reload
  end
end
