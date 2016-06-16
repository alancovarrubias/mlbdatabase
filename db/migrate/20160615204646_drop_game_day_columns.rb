class DropGameDayColumns < ActiveRecord::Migration
  def change
    remove_column :game_days, :year, :integer
    remove_column :game_days, :month, :integer
    remove_column :game_days, :day, :integer
  end
end
