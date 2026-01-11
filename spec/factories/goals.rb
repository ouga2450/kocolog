FactoryBot.define do
  factory :goal do
    association :habit
    user { habit.user }
    goal_unit { :check_based }
    frequency { :daily }
    status { :active }
    amount { 1 }

    trait :count_based do
      goal_unit { :count_based }
      amount { 3 }
    end

    trait :draft do
      status { :draft }
    end

    trait :with_period do
      start_date { Date.current - 1 }
      end_date { Date.current + 1 }
    end

    trait :check_based do
      goal_unit { :check_based }
      amount { 1 }
    end

    trait :count_based do
      goal_unit { :count_based }
      amount { 3 }
    end
  end
end
