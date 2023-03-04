# frozen_string_literal: true
class ConstService < Base::Service
  param :platform
  param :klass

  def call
    "#{platform.titleize}::#{klass}".constantize
  end
end
