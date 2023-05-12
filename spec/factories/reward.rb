FactoryBot.define do
  factory :reward do
    team

    quantity { 0 }
    price { 100 }
    sequence(:name) { |n| "Reward ##{n}" }
    description { Faker::Lorem.sentence }
  end
end
