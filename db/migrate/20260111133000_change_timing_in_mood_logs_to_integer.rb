class ChangeTimingInMoodLogsToInteger < ActiveRecord::Migration[7.2]
  def up
    change_column :mood_logs, :timing, :integer, using: "timing::integer"
  end

  def down
    change_column :mood_logs, :timing, :string, using: "timing::text"
  end
end
