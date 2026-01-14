class HabitForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.model_name
    ActiveModel::Name.new(self, nil, "Habit")
  end

  # --- Habit の属性 ---
  attribute :id, :integer
  attribute :name, :string
  attribute :description, :string
  attribute :category_id, :integer
  attribute :user_id, :integer

  # --- Goal の属性（rename 後） ---
  attribute :goal_unit, :string    # enum
  attribute :frequency, :string    # enum
  attribute :amount, :integer
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :status, :string

  # attr_reader（@habit や @goal にアクセス）
  attr_reader :habit, :goal

  # --- バリデーション ---

  # Habit用
  validates :name, :category_id, :user_id, presence: true

  # Goal用
  validates :goal_unit, :frequency, presence: true
  validates :status, presence: true

  # amount は count / time の場合だけ1以上
  # check_based の場合は後から自動設定
  validates :amount,
  numericality: { greater_than: 0 },
  if: -> { goal_unit.in?(%w[count_based time_based]) }

  # 日付チェック
  validate :start_date_must_be_before_end_date

  def initialize(attributes = {})
    super
    self.status ||= "active"
  end

  def persisted?
    id.present?
  end

  # --- 編集用フォームオブジェクトを生成 ---
  def self.from_model(habit)
    goal = habit.goal

    new(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      category_id: habit.category_id,
      user_id: habit.user_id,

      # rename 反映
      goal_unit: goal.goal_unit,
      frequency: goal.frequency,
      amount: goal.amount,
      start_date: goal.start_date,
      end_date: goal.end_date,
      status: goal.status
    )
  end

  # --- 新規保存 ---
  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      habit = Habit.create!(
        name: name,
        description: description,
        category_id: category_id,
        user_id: user_id,
        archived_at: nil
      )

      Goal.create!(
        user_id: user_id,
        habit_id: habit.id,

        # rename 反映
        goal_unit: goal_unit,
        frequency: frequency,
        amount: amount,

        start_date: start_date,
        end_date: end_date,
        status: status || :active
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # --- 更新処理 ---
  def update
    return false unless valid?

    ActiveRecord::Base.transaction do
      habit = Habit.find(id)
      goal = habit.goal

      habit.update!(
        name: name,
        description: description,
        category_id: category_id
      )

      goal.update!(
        # rename 反映
        goal_unit: goal_unit,
        frequency: frequency,
        amount: amount,
        start_date: start_date,
        end_date: end_date,
        status: status || :active
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end


  private

  def start_date_must_be_before_end_date
    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      errors.add(:start_date, "は終了日より前に設定してください")
    end
  end
end
