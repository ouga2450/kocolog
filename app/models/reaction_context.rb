class ReactionContext
  attr_reader :date,
              :mood_logs,
              :habit_logs,
              :habits,
              :avg_mood,
              :mood_graph,
              :summaries

  def initialize(user:, date:)
    @user = user
    @date = date
    build
  end

  private

  def build
    build_mood_logs
    build_habit_logs
    build_mood_graph
    build_habits
    build_avg_mood
    build_summaries
  end

  def build_mood_logs
    @mood_logs =
      @user.mood_logs
           .includes(:mood)
           .for_date(@date)
           .recent
           .order(:recorded_at)
  end

  def build_habit_logs
    @habit_logs =
      @user.habit_logs
           .includes(habit: [ :goal, :category ])
           .for_date(@date)
           .recent
           .order(:started_at)
  end

  def build_mood_graph
    logs_scope =
      @user.mood_logs
           .includes(:mood)
           .for_date(@date)
    @mood_graph = TimeSeriesAggregation.new(logs_scope).call
  end

  def build_habits
    @habits =
      @user.habits
           .includes(:goal, :category)
           .kept
           .with_active_goal
           .with_effective_goal_on(@date)
  end

  def build_avg_mood
    @avg_mood =
      @mood_logs
        .joins(:mood)
        .average("moods.score")
        &.to_f
  end

  def build_summaries
    frequency = %i[daily weekly monthly]

    # 期間ごとのログを一括取得
    logs_by_frequency =
      frequency.index_with do |freq|
        HabitLogsQuery.new(
          user: @user,
          date: @date,
          frequency: freq
          )
          .logs
          .group_by(&:habit_id)
      end

    # Progress を組み立てる
    @summaries =
      frequency.index_with do |freq|
        frequency_habits = @habits.public_send(freq) || Habit.none
        logs_by_habit = logs_by_frequency[freq]

        progresses =
          frequency_habits.map do |habit|
            HabitProgress.new(
              habit: habit,
              habit_logs: logs_by_habit[habit.id] || []
            )
          end

        HabitProgressSummary.new(progresses, @date, freq)
      end
  end
end
