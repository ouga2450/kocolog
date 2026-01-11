FactoryBot.define do
  factory :habit_log do
    association :goal
    user { goal.user }
    habit { goal.habit }
    started_at { Time.current }
    performed_value { 1 }

    trait :with_ended_at do
      ended_at { started_at + 1.hour }
    end
  end
end
