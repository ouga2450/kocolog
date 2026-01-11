class HabitLogForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.model_name
    ActiveModel::Name.new(self, nil, "HabitLog")
  end

  attr_reader :user, :habit_log, :habit

  # --- HabitLog attributes ---
  attribute :id, :integer
  attribute :habit_id, :integer
  attribute :goal_id, :integer
  attribute :performed_value, :integer
  attribute :started_at, :datetime
  attribute :ended_at, :datetime

  # --- before/after mood attributes ---
  %i[before after].each do |prefix|
    attribute "#{prefix}_mood_id", :integer
    attribute "#{prefix}_feeling_id", :integer
    attribute "#{prefix}_note", :string
  end

  # --- バリデーション ---
  validates :habit_id, :goal_id, :started_at, presence: true
  validates :performed_value,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
  validate :within_habit_active_range

  # new/edit データ構成
  def initialize(user:, habit: nil, habit_log: nil, attributes: {})
    @user = user
    @habit_log = habit_log
    @habit = habit_log&.habit || habit

    defaults = default_attributes
    super(defaults.merge(attributes))
  end

  def persisted?
    habit_log&.persisted?
  end

  def started_at=(value)
    super(convert_to_time_zone(value))
  end

  def ended_at=(value)
    super(convert_to_time_zone(value))
  end

  private

  def convert_to_time_zone(value)
    return value if value.is_a?(ActiveSupport::TimeWithZone)
    return nil if value.blank?

    # ActiveRecord と同じ Time.zone のパースを実行
    Time.zone.parse(value.to_s)
  end

  # new/edit attributesセット
  def default_attributes
    return new_attributes unless habit_log
    edit_attributes
  end

  def new_attributes
    default_performed_value = 1
    default_mood = 3
    {
      habit_id: habit.id,
      goal_id: habit.goal&.id,
      performed_value: default_performed_value,
      started_at: 30.minutes.ago,
      before_mood_id: default_mood,
      ended_at: Time.current,
      after_mood_id: default_mood
    }
  end

  def edit_attributes
    base = {
      id: habit_log.id,
      habit_id: habit_log.habit_id,
      goal_id: habit_log.goal_id,
      performed_value: habit_log.performed_value,
      started_at: habit_log.started_at,
      ended_at: habit_log.ended_at
    }

    base.merge(mood_attributes(:before))
        .merge(mood_attributes(:after))
  end

  # edit時 mood attributesセット
  def mood_attributes(timing)
    log = habit_log.mood_logs.public_send(timing).first
    return {} unless log

    {
      "#{timing}_mood_id": log.mood_id,
      "#{timing}_feeling_id": log.feeling_id,
      "#{timing}_note": log.note
    }
  end

  # 時刻範囲がhabitの期間指定に収まっているか
  def within_habit_active_range
    return if habit.blank?
    return if habit.goal.blank?
    return if started_at.blank? && ended_at.blank?

    active_start = habit.goal.start_date
    active_end   = habit.goal.end_date

    return if active_start.blank? || active_end.blank?

    if started_at.present? &&
      !started_at.between?(active_start, active_end)
      errors.add(:started_at, "は行動が有効な期間内で記録してください")
    end

    if ended_at.present? &&
      !ended_at.between?(active_start, active_end)
      errors.add(:ended_at, "は行動が有効な期間内で記録してください")
    end
  end
end
