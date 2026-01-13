require "rails_helper"

RSpec.describe HabitForm, type: :model do
  let(:user) { create(:user) }
  let(:category) { create(:category) }

  def build_form(attrs = {})
    defaults = {
      name: "Read",
      description: "desc",
      category_id: category.id,
      user_id: user.id,
      goal_unit: "check_based",
      frequency: "daily",
      amount: 1,
      status: "active"
    }

    described_class.new(defaults.merge(attrs))
  end

  describe "validations" do
    it "is valid with required attributes" do
      form = build_form
      expect(form).to be_valid
    end

    it "is invalid without name" do
      form = build_form(name: nil)
      expect(form).not_to be_valid
    end

    it "is invalid without category_id" do
      form = build_form(category_id: nil)
      expect(form).not_to be_valid
    end

    it "is invalid without user_id" do
      form = build_form(user_id: nil)
      expect(form).not_to be_valid
    end

    it "is invalid without goal_unit" do
      form = build_form(goal_unit: nil)
      expect(form).not_to be_valid
    end

    it "is invalid without frequency" do
      form = build_form(frequency: nil)
      expect(form).not_to be_valid
    end

    it "defaults status to active when nil" do
      form = build_form(status: nil)
      expect(form.status).to eq("active")
      expect(form).to be_valid
    end

    it "requires amount for count_based" do
      form = build_form(goal_unit: "count_based", amount: nil)
      expect(form).not_to be_valid
    end

    it "is invalid when amount is not positive for count_based" do
      form = build_form(goal_unit: "count_based", amount: 0)
      expect(form).not_to be_valid
    end

    it "is invalid when start_date is after end_date" do
      form = build_form(start_date: Date.current, end_date: Date.current - 1.day)
      expect(form).not_to be_valid
    end
  end

  describe ".from_model" do
    it "builds form attributes from habit and goal" do
      habit = create(:habit, user: user, category: category, name: "Write")
      goal = create(
        :goal,
        user: habit.user,
        habit: habit,
        goal_unit: :count_based,
        frequency: :weekly,
        amount: 2,
        status: :active,
        start_date: Date.current,
        end_date: Date.current + 7.days
      )

      form = described_class.from_model(habit)

      expect(form.id).to eq(habit.id)
      expect(form.name).to eq("Write")
      expect(form.category_id).to eq(category.id)
      expect(form.user_id).to eq(user.id)
      expect(form.goal_unit).to eq(goal.goal_unit)
      expect(form.frequency).to eq(goal.frequency)
      expect(form.amount).to eq(goal.amount)
      expect(form.start_date).to eq(goal.start_date)
      expect(form.end_date).to eq(goal.end_date)
      expect(form.status).to eq(goal.status)
    end
  end

  describe "#persisted?" do
    it "returns true when id is present" do
      form = described_class.new(id: 1)
      expect(form.persisted?).to be(true)
    end
  end

  describe "#save" do
    it "creates habit and goal records" do
      form = build_form

      expect {
        form.save
      }.to change(Habit, :count).by(1).and change(Goal, :count).by(1)
    end
  end

  describe "#update" do
    it "updates habit and goal records" do
      habit = create(:habit, user: user, category: category, name: "Old")
      goal = create(:goal, user: user, habit: habit, goal_unit: :check_based, frequency: :daily, amount: 1)

      form = described_class.new(
        id: habit.id,
        name: "New",
        description: "updated",
        category_id: category.id,
        user_id: user.id,
        goal_unit: "count_based",
        frequency: "weekly",
        amount: 3,
        start_date: Date.current,
        end_date: Date.current + 1.day,
        status: "active"
      )

      expect(form.update).to be(true)

      habit.reload
      goal.reload

      expect(habit.name).to eq("New")
      expect(habit.description).to eq("updated")
      expect(goal.goal_unit).to eq("count_based")
      expect(goal.frequency).to eq("weekly")
      expect(goal.amount).to eq(3)
    end
  end
end
