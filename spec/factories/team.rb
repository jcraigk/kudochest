# frozen_string_literal: true
FactoryBot.define do
  factory :team do
    association :owning_user, factory: :user

    platform { 'slack' }
    sequence(:name) { |n| "Team #{n}" }
    rid { FactoryHelper.rid(platform, 'T') }
    avatar_url { Faker::Internet.url }
    api_key { SecureRandom.hex }
    app_profile_rid { FactoryHelper.rid(platform, 'U') }
    app_subteam_rid { FactoryHelper.rid(:discord) }
    tokens_disbursed_at { Time.current }
    max_level { App.default_max_level }
    max_level_karma { App.default_max_level_karma }
    token_max { App.default_token_max }
    time_zone { 'UTC' }
    token_hour { 7 }

    trait :with_profiles do
      after(:create) do |team|
        team.profiles += create_list(:profile, 3)
      end
    end

    trait :with_app_profile do
      after(:create) do |team|
        team.profiles << create(:profile, rid: team.app_profile_rid)
      end
    end
  end
end
