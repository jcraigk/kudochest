# frozen_string_literal: true
FactoryBot.define do
  factory :channel do
    team

    sequence(:name) { |n| "channel-#{n}" }
    rid { FactoryHelper.rid(team.platform, 'C') }
  end
end
