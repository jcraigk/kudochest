# frozen_string_literal: true
FactoryBot.define do
  factory :topic do
    team

    sequence(:name) { |n| "Topic #{n}" }
    sequence(:keyword) { |n| "keyword#{n}" }
    sequence(:emoji) { |n| "emoji#{n}" }
    description { Faker::Lorem.sentence(word_count: 25) }
  end
end
