# frozen_string_literal: true
FactoryBot.define do
  factory :profile do
    team
    user

    sequence(:real_name) { |n| "Real Name #{n}" }
    sequence(:display_name) { |n| "display-name-#{n}" }
    rid { FactoryHelper.rid(team.platform, 'U') }
    avatar_url { Faker::Internet.url }
  end
end
