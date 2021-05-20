# frozen_string_literal: true
FactoryBot.define do
  factory :subteam do
    team

    sequence(:name) { |n| "Subteam #{n}" }
    sequence(:handle) { |n| "subteam-#{n}" }
    sequence(:description) { |n| "Subteam description #{n}" }
    rid { FactoryHelper.rid(team.platform, 'S') }

    trait :with_profiles do
      after(:create) do |this|
        this.profiles = create_list(:profile, 2, team: this.team)
      end
    end
  end
end
