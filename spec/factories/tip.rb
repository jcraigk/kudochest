# frozen_string_literal: true
FactoryBot.define do
  factory :tip do
    association :from_profile, factory: :profile
    association :to_profile, factory: :profile

    quantity { 1 }
    note { 'for being my hero!' }
    sequence(:event_ts) { |n| "1572928377.#{n + 203_000}" }
    from_channel_rid { FactoryHelper.slack_rid('C') }
    sequence(:from_channel_name) { |n| "channel-#{n}" }
    source { 'inline' }
  end
end
