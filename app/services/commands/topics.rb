# frozen_string_literal: true
class Commands::Topics < Commands::Base
  def call
    ChatResponse.new(
      mode: :private,
      text: topic_text
    )
  end

  private

  def topic_text
    return topics_disabled unless team.enable_topics?
    topic_list
  end

  def topic_list
    Topic.active.where(team: team).order(name: :asc).map do |topic|
      <<~TEXT.chomp
        *Name:* #{topic.name}
        *Description:* #{topic.description}
        *Keyword:* `#{topic.keyword}`
        *Emoji:* :#{topic.emoji}:
      TEXT
    end.join("\n\n")
  end

  def topics_disabled
    'Topics are currently disabled'
  end
end
