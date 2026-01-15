class CalendarsController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current

    beginning = @date.beginning_of_month.beginning_of_week(:monday)
    ending    = @date.end_of_month.end_of_week(:monday)

    # 月全体を一括ロード（DBアクセス2回だけ）
    mood_logs = current_user.mood_logs
                  .where(recorded_at: beginning..ending)
                  .includes(:mood)
                  .joins(:mood)

    habit_logs = current_user.habit_logs
                  .where(started_at: beginning..ending)

    # 日付ごとにグルーピング
    @mood_logs_by_day  = mood_logs.group_by { |ml| ml.recorded_at.to_date }
    @habit_logs_by_day = habit_logs.group_by { |hl| hl.started_at.to_date }

    range = @date.beginning_of_month..@date.end_of_month
    @mood_graph =
      TimeSeriesAggregation.new(
        mood_logs,
        force_unit: :day,
        range: range
      ).call
    @avg_mood =
      mood_logs
        .average("moods.score")
        &.to_f

    @beginning = beginning
    @ending = ending
  end

  def show
    @date = Date.parse(params[:date]) rescue nil

    if @date.nil?
      redirect_to calendars_path, alert: "無効な日付です"
      return
    end

    @habit_logs = current_user.habit_logs
      .where(started_at: @date.all_day)
      .order(:started_at)
      .includes(habit: :category)

    @mood_logs = current_user.mood_logs
      .where(recorded_at: @date.all_day)
      .order(:recorded_at)
      .includes(:mood, :feeling)

    respond_to do |format|
      format.html  # ← 従来のshowページ
      format.turbo_stream { render layout: false } # モーダル用
    end
  end
end
