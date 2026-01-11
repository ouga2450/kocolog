class MoodLog < ApplicationRecord
  include Hashid::Rails
  # recorded_atのデフォルト値を現在時刻に設定（マイグレーションのdefaultオプションはDB側で設定されるため、validationエラーを防ぐ目的でモデル側でも設定）
  before_validation :set_default_recorded_at, on: :create
  before_validation :truncate_recorded_at_to_minute

  # --- 関連 ---
  belongs_to :user
  belongs_to :mood
  belongs_to :habit_log, optional: true
  belongs_to :feeling, optional: true

  # --- バリデーション ---
  validates :recorded_at, presence: true
  # selfで囲うことでundefinedエラーを防止(nilを返す)
  validates :timing, presence: true, if: -> { self[:habit_log_id].present? }

  # --- enum ---
  enum :timing, [ :before, :after ]

  # --- スコープ ---
  scope :for_today, -> { where(recorded_at: Date.current.all_day) }
  scope :for_date, ->(date) { where(recorded_at: date.all_day) }
  scope :recent, -> { order(recorded_at: :desc) }

  # --- インスタンスメソッド ---
  def mood_label
    mood.label
  end

  private

  def set_default_recorded_at
    self.recorded_at ||= Time.current
  end

  # 秒以下を切り捨てて、HTMLバリデーションと整合を取る
  def truncate_recorded_at_to_minute
    return if recorded_at.blank?
    self.recorded_at = recorded_at.change(sec: 0, usec: 0)
  end
end
