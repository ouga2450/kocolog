FactoryBot.define do
  factory :mood_log do
    association :user
    association :mood
    recorded_at { Time.current }
    note { "note" }

    trait :with_feeling do
      association :feeling
    end

    trait :with_habit_log do
      habit_log { build(:habit_log, user: user) }
      timing { :before }
    end
  end
end
