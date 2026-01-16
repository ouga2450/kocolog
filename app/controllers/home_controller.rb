class HomeController < ApplicationController
  def index
    date = Date.current
    habits_query = HabitQuery.new(user: current_user, date: date)

    habit_logs =
      current_user.habit_logs
        .for_today
        .includes(habit: :category)
        .order(started_at: :desc)

    mood_logs =
      current_user.mood_logs
        .for_today
        .includes(:mood, :feeling)
        .order(recorded_at: :desc)

    @moods = Mood.order(:score)

    @habits           = habits_query.active_base
    @habits_today     = habits_query.habits_for("daily")
    @habits_this_week = habits_query.habits_for("weekly")
    @habits_this_month= habits_query.habits_for("monthly")

    @habit_logs_today = habit_logs
    @mood_logs_today  = mood_logs
  end
end
