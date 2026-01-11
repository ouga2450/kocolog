require "rails_helper"

RSpec.describe MoodLog, type: :model do
  describe "associations" do
    it "belongs to user and mood, optionally habit_log and feeling" do
      user_assoc = described_class.reflect_on_association(:user)
      mood_assoc = described_class.reflect_on_association(:mood)
      habit_log_assoc = described_class.reflect_on_association(:habit_log)
      feeling_assoc = described_class.reflect_on_association(:feeling)

      expect(user_assoc.macro).to eq(:belongs_to)
      expect(mood_assoc.macro).to eq(:belongs_to)
      expect(habit_log_assoc.macro).to eq(:belongs_to)
      expect(habit_log_assoc.options[:optional]).to eq(true)
      expect(feeling_assoc.macro).to eq(:belongs_to)
      expect(feeling_assoc.options[:optional]).to eq(true)
    end
  end

  describe "validations" do
    it "is valid with all required attributes" do
      mood_log = build(:mood_log)
      expect(mood_log).to be_valid
      expect(mood_log.errors).to be_empty
    end

    it "is invalid without user" do
      mood_log = build(:mood_log, user: nil)
      expect(mood_log).not_to be_valid
    end

    it "is invalid without mood" do
      mood_log = build(:mood_log, mood: nil)
      expect(mood_log).not_to be_valid
    end

    it "sets recorded_at when nil" do
      mood_log = build(:mood_log, recorded_at: nil)
      expect(mood_log).to be_valid
    end

    it "requires timing when habit_log is present" do
      habit_log = build_stubbed(:habit_log)
      mood_log = build(:mood_log, habit_log: habit_log, timing: nil)
      expect(mood_log).not_to be_valid
    end

    it "does not require timing when habit_log is nil" do
      mood_log = build(:mood_log)
      expect(mood_log).to be_valid
    end
  end

  describe "callbacks" do
    it "sets recorded_at when nil" do
      mood_log = build(:mood_log, recorded_at: nil)
      mood_log.valid?
      expect(mood_log.recorded_at).not_to be_nil
    end

    it "truncates recorded_at to minute" do
      time = Time.current.change(sec: 30, usec: 123456)
      mood_log = build(:mood_log, recorded_at: time)
      mood_log.valid?

      expect(mood_log.recorded_at.sec).to eq(0)
      expect(mood_log.recorded_at.usec).to eq(0)
    end
  end

  describe "scopes" do
    it "filters logs for today and date" do
      today_log = create(:mood_log, recorded_at: Time.current)
      yesterday_log = create(:mood_log, recorded_at: 1.day.ago)

      expect(described_class.for_today).to include(today_log)
      expect(described_class.for_today).not_to include(yesterday_log)
      expect(described_class.for_date(Date.current - 1)).to include(yesterday_log)
    end

    it "orders logs by recent recorded_at" do
      older = create(:mood_log, recorded_at: 2.hours.ago)
      newer = create(:mood_log, recorded_at: 1.hour.ago)

      expect(described_class.recent.first).to eq(newer)
      expect(described_class.recent.last).to eq(older)
    end
  end

  describe "#mood_label" do
    it "returns the mood label" do
      mood_log = build(:mood_log)
      expect(mood_log.mood_label).to eq(mood_log.mood.label)
    end
  end
end
