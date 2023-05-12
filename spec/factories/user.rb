FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user-#{n}@example.com" }
    password { 'valid_password' }
    password_confirmation { 'valid_password' }
  end
end
