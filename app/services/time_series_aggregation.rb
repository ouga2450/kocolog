class TimeSeriesAggregation
  def initialize(scope, force_unit: nil, range: nil)
    @scope = scope
    @force_unit = force_unit
    @range = range
  end

  # 返り値: { time => average_score, ... }
  def call
    from = @scope.minimum(:recorded_at)
    to   = @scope.maximum(:recorded_at)

    return empty_result if from.nil? || to.nil?

    @from = from
    unit = @force_unit || decide_unit(from, to)
    data = aggregate(unit)

    {
      unit: unit,
      label_format: label_format_for(unit),
      points: format_points(data)
    }
  end

  private

  # 集約単位を決定
  def decide_unit(from, to)
    diff = to - from

    case diff
    when ..12.hours then :quarter_hour
    when ..1.days   then :half_hour
    when ..7.days   then :hour
    when ..30.days  then :day
    when ..90.days  then :three_days
    when ..180.days then :week
    else                 :month
    end
  end

  # 集約単位ごとにまとめ、気分の平均化
  # 返り値: { time => average_score, ... }
  def aggregate(unit)
    case unit
    when :quarter_hour
      @scope.group_by_minute(:recorded_at, n: 15).average("moods.score")
    when :half_hour
      @scope.group_by_minute(:recorded_at, n: 30).average("moods.score")
    when :hour
      @scope.group_by_hour(:recorded_at).average("moods.score")
    when :day
      @scope.group_by_day(:recorded_at).average("moods.score")
    when :week
      @scope.group_by_week(:recorded_at).average("moods.score")
    when :month
      @scope.group_by_month(:recorded_at).average("moods.score")
    when :three_days
      aggregate_three_days
    end
  end

  # 3日ごとにグルーピングして平均を計算
  def aggregate_three_days
    logs = @scope.to_a
    return {} if logs.empty?

    from_date = @from.to_date

    # bucketはグルーピングの代表時刻に変換（group_byのキー）
    # time: bucket, value: average_score
    logs
      .group_by { |log| ((log.recorded_at.to_date - from_date).to_i / 3) }
      .transform_keys { |bucket| (from_date + bucket * 3).to_time }
      .transform_values do |bucket_logs|
        bucket_logs.sum { |log| log.mood.score } / bucket_logs.size.to_f
      end
  end

  def empty_result
    {
      unit: :none,
      label_format: nil,
      points: []
    }
  end

  def label_format_for(unit)
    case unit
    when :quarter_hour, :half_hour
      "%H:%M"
    when :hour
      "%m/%d %H時"
    when :day
      "%m/%d"
    when :three_days
      "%m/%d"
    when :week
      "週 (%m/%d〜)"
    when :month
      "%Y/%m"
    end
  end

  # グラフ描画用のハッシュ配列に変換
  def format_points(data)
    data.map do |time, value|
      { time: time, value: value }
    end.sort_by { |p| p[:time] }
  end
end
