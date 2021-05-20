# frozen_string_literal: true
class Commands::Levels < Commands::Base
  def call
    respond_success
  end

  private

  def respond_success
    OpenStruct.new(
      mode: :private,
      text: level_table_text
    )
  end

  def level_table_text
    <<~TEXT.strip
      ```
      #{team.level_karma_table}
      ```
    TEXT
  end
end
