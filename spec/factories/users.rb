FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    full_name { "Test User" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { "reader" }
    confirmed_at { Time.current }

    trait :admin do
      role { "admin" }
      full_name { "Admin User" }
    end

    trait :author do
      role { "author" }
      full_name { "Author User" }
    end

    trait :reader do
      role { "reader" }
      full_name { "Reader User" }
    end
  end
end
