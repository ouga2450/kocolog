class Goal < ApplicationRecord
  # --- 関連 ---
  belongs_to :user
  belongs_to :habit

  has_many :habit_logs, dependent: :destroy

  # --- enum ---
  enum :goal_unit, [ :check_based, :count_based ]  # 目標の種類 {time_based: 2} 将来用
  enum :frequency, [ :daily, :weekly, :monthly ]  # 達成頻度
  enum :status, [ :draft, :active ]  # 目標セット

  # --- バリデーション ---
  before_validation :set_amount_for_check_based
  validates :goal_unit, presence: true
  validates :frequency, presence: true
  validates :status, presence: true
  validates :amount, presence: true

  # count / time の場合だけ amount が必要
  validates :amount, numericality: { greater_than: 0 }
  validate :start_date_must_be_before_end_date

  # --- scope ---
  # 有効な目標取得
  scope :effective_on, ->(date) {
    active
      .where("start_date IS NULL OR start_date <= ?", date)
      .where("end_date IS NULL OR end_date >= ?", date)
  }
  # 今日有効な目標取得
  scope :effective_today, -> {
    effective_on(Date.current)
  }

  # 今日有効な目標を頻度別取得
  scope :for_today,      -> { daily.effective_today }
  scope :for_this_week,  -> { weekly.effective_today }
  scope :for_this_month, -> { monthly.effective_today }

  # --- インスタンスメソッド ---
  def start_date_must_be_before_end_date
    return if start_date.blank? || end_date.blank?

    if start_date > end_date
      errors.add(:start_date, "は終了日より前に設定してください")
    end
  end

  # 表示用
  def display_goal
    freq = case frequency
    when "daily"   then "毎日"
    when "weekly"  then "毎週"
    when "monthly" then "毎月"
    end

    case goal_unit
    when "check_based"
      "#{freq}実行"
    when "count_based"
      "#{freq}#{amount}回"
    when "time_based"
      "#{freq}#{amount}分"
    end
  end

  def display_period
    if start_date.present? && end_date.present?
      "#{start_date} 〜 #{end_date}"
    elsif start_date.present?
      "#{start_date} 〜（期限なし）"
    elsif end_date.present?
      "（開始日なし）〜 #{end_date}"
    else
      "期間なし"
    end
  end

  private

  def set_amount_for_check_based
    return unless check_based?

    self.amount = 1
  end
end
