# frozen_string_literal: true
FactoryBot.define do
  factory :claim do
    reward
    profile

    price { 100 }
  end
end
