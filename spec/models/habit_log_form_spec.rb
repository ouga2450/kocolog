require "rails_helper"

RSpec.describe HabitLogForm, type: :model do
  let(:user) { create(:user) }
  let(:habit) { create(:habit, user: user) }
  let!(:goal) { create(:goal, user: user, habit: habit) }

  def build_form(attrs = {}, habit: nil, habit_log: nil)
    habit ||= self.habit

    described_class.new(
      user: user,
      habit: habit,
      habit_log: habit_log,
      attributes: attrs
    )
  end

  # デフォルト値はhabit_log_form.rb側で設定
  describe "defaults" do
    it "sets defaults for new form" do
      form = build_form

      expect(form.habit_id).to eq(habit.id)
      expect(form.goal_id).to eq(goal.id)
      expect(form.performed_value).to eq(1)
      expect(form.before_mood_id).to eq(3)
      expect(form.after_mood_id).to eq(3)
      expect(form.started_at).to be_present
      expect(form.ended_at).to be_present
    end

    it "overrides defaults with provided attributes" do
      form = build_form({ performed_value: 5, before_note: "note" })

      expect(form.performed_value).to eq(5)
      expect(form.before_note).to eq("note")
    end
  end

  describe "validations" do
    it "is valid with required attributes" do
      form = build_form
      expect(form).to be_valid
    end

    it "is invalid without habit_id" do
      form = build_form({ habit_id: nil })
      expect(form).not_to be_valid
    end

    it "is invalid without goal_id" do
      form = build_form({ goal_id: nil })
      expect(form).not_to be_valid
    end

    it "is invalid without started_at" do
      form = build_form({ started_at: nil })
      expect(form).not_to be_valid
    end

    it "allows performed_value to be nil" do
      form = build_form({ performed_value: nil })
      expect(form).to be_valid
    end

    it "is invalid when performed_value is negative" do
      form = build_form({ performed_value: -1 })
      expect(form).not_to be_valid
    end
  end

  describe "range validation" do
    before do
      goal.update!(start_date: Date.current, end_date: Date.current + 3.days)
    end

    it "adds errors when started_at is outside range" do
      form = build_form({ started_at: Time.current - 4.days })
      form.valid?

      expect(form.errors[:started_at]).not_to be_empty
    end

    it "adds errors when ended_at is outside range" do
      form = build_form({ ended_at: Time.current + 5.days })
      form.valid?

      expect(form.errors[:ended_at]).not_to be_empty
    end
  end

  describe "edit form attributes" do
    it "uses habit_log and mood_logs values" do
      habit_log = create(
        :habit_log,
        user: user,
        habit: habit,
        goal: goal,
        performed_value: 2,
        started_at: Time.current - 1.hour,
        ended_at: Time.current
      )

      before_log = create(
        :mood_log,
        user: user,
        habit_log: habit_log,
        timing: :before,
        note: "before note"
      )
      after_log = create(
        :mood_log,
        user: user,
        habit_log: habit_log,
        timing: :after,
        note: "after note"
      )

      form = build_form({}, habit_log: habit_log)

      expect(form.id).to eq(habit_log.id)
      expect(form.habit_id).to eq(habit_log.habit_id)
      expect(form.goal_id).to eq(habit_log.goal_id)
      expect(form.performed_value).to eq(habit_log.performed_value)
      expect(form.before_mood_id).to eq(before_log.mood_id)
      expect(form.after_mood_id).to eq(after_log.mood_id)
      expect(form.before_note).to eq("before note")
      expect(form.after_note).to eq("after note")
    end
  end

  describe "#persisted?" do
    it "returns true when habit_log is persisted" do
      habit_log = create(:habit_log, user: user, habit: habit, goal: goal)
      form = build_form({}, habit_log: habit_log)

      expect(form.persisted?).to be(true)
    end
  end
end
