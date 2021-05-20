# frozen_string_literal: true
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.around(:each, :freeze_time) do |example|
    freeze_time { example.run }
  end
end
