class HabitQuery
  def initialize(user:, date: Date.current)
    @user = user
    @date = date
  end

  # =========================
  # public API
  # =========================

  def active_base
    @active_base ||= begin
      Habit
        .where(user: @user, archived_at: nil)
        .joins(:goal, :category)
        .merge(Goal.active.effective_on(@date))
        .includes(:goal, :category)
        .distinct
        .to_a
    end
  end

  # Home のタブ切り替え用
  def habits_for(tab)
    grouped_habits.fetch(tab.to_s, [])
  end

  # 件数（空カード判定など）
  def count_for(tab)
    habits_for(tab).size
  end

  def exists_for?(tab)
    habits_for(tab).any?
  end

  def none_for?(tab)
    habits_for(tab).empty?
  end

  # =========================
  # internal
  # =========================

  def grouped_habits
    @grouped_habits ||= active_base.group_by do |habit|
      habit.goal.frequency # "daily" / "weekly" / "monthly"
    end
  end
end
