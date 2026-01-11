require "rails_helper"

RSpec.describe HabitLog, type: :model do
  describe "associations" do
    it "belongs to user, habit, goal and has many mood_logs" do
      user_assoc = described_class.reflect_on_association(:user)
      habit_assoc = described_class.reflect_on_association(:habit)
      goal_assoc = described_class.reflect_on_association(:goal)
      mood_logs_assoc = described_class.reflect_on_association(:mood_logs)

      expect(user_assoc.macro).to eq(:belongs_to)
      expect(habit_assoc.macro).to eq(:belongs_to)
      expect(goal_assoc.macro).to eq(:belongs_to)
      expect(mood_logs_assoc.macro).to eq(:has_many)
      expect(mood_logs_assoc.options[:dependent]).to eq(:nullify)
    end
  end

  describe "validations" do
    it "is valid with all required attributes" do
      habit_log = build(:habit_log)
      expect(habit_log).to be_valid
      expect(habit_log.errors).to be_empty
    end

    it "is invalid without started_at" do
      habit_log = build(:habit_log, started_at: nil)
      expect(habit_log).not_to be_valid
    end

    it "is invalid when ended_at is before started_at" do
      time = Time.current
      habit_log = build(:habit_log, started_at: time, ended_at: time - 1.minute)

      expect(habit_log).not_to be_valid
    end

    it "sets performed_value for check_based" do
      habit_log = build(:habit_log, goal: build(:goal, goal_unit: :check_based), performed_value: nil)
      habit_log.valid?

      expect(habit_log.performed_value).to eq(1)
      expect(habit_log).to be_valid
    end

    it "is invalid without performed_value for count_based" do
      habit_log = build(:habit_log, goal: build(:goal, :count_based), performed_value: nil)
      expect(habit_log).not_to be_valid
    end
  end

  describe "scopes" do
    it "filters logs by date and association" do
      today_log = create(:habit_log, started_at: Time.current)
      yesterday_log = create(:habit_log, started_at: 1.day.ago)
      other_habit_log = create(:habit_log, started_at: Time.current)

      expect(described_class.for_today).to include(today_log)
      expect(described_class.for_today).not_to include(yesterday_log)
      expect(described_class.for_date(Date.current - 1)).to include(yesterday_log)
      expect(described_class.for_date(Date.current - 1)).not_to include(today_log)
      expect(described_class.for_habit(today_log.habit_id)).to include(today_log)
      expect(described_class.for_habit(today_log.habit_id)).not_to include(other_habit_log)
      expect(described_class.for_goal(today_log.goal_id)).to include(today_log)
      expect(described_class.for_goal(today_log.goal_id)).not_to include(other_habit_log)
    end

    it "orders logs by recent started_at" do
      older = create(:habit_log, started_at: 2.hours.ago)
      newer = create(:habit_log, started_at: 1.hour.ago)

      expect(described_class.recent.first).to eq(newer)
      expect(described_class.recent.last).to eq(older)
    end
  end

  describe "instance methods" do
    it "calculates duration_minutes" do
      start_time = Time.current
      habit_log = build(:habit_log, started_at: start_time, ended_at: start_time + 91.minutes)

      expect(habit_log.duration_minutes).to eq(91)
    end

    it "returns before and after mood logs" do
      habit_log = create(:habit_log)
      before_log = create(:mood_log, habit_log: habit_log, timing: :before)
      after_log = create(:mood_log, habit_log: habit_log, timing: :after)

      expect(habit_log.before_mood_log).to eq(before_log)
      expect(habit_log.after_mood_log).to eq(after_log)
    end

    it "checks if the log is for today" do
      habit_log = build(:habit_log, started_at: Time.current)
      expect(habit_log.today?).to be(true)

      habit_log.started_at = 2.days.ago
      expect(habit_log.today?).to be(false)
    end

    it "returns value_for_goal based on goal unit" do
      check_log = build(:habit_log, goal: build(:goal, :check_based), performed_value: nil)
      check_log.valid?

      count_log = build(:habit_log, goal: build(:goal, :count_based), performed_value: 3)

      expect(check_log.value_for_goal).to eq(1)
      expect(count_log.value_for_goal).to eq(3)
    end

    it "calculates remaining_value from target_value and value_for_goal" do
      habit_log = build(:habit_log)
      allow(habit_log).to receive(:value_for_goal).and_return(2)
      allow(habit_log).to receive(:goal).and_return(double(target_value: 5))

      expect(habit_log.remaining_value).to eq(3)
    end
  end
end
