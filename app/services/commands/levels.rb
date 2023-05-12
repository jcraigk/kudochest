class Commands::Levels < Commands::Base
  def call
    respond_success
  end

  private

  def respond_success
    ChatResponse.new \
      mode: :private,
      text: level_table_text
  end

  def level_table_text
    <<~TEXT.strip
      ```
      #{team.levels_table}
      ```
    TEXT
  end
end
