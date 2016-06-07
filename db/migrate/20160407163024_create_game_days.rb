class CreateGameDays < ActiveRecord::Migration
  def change
    create_table :game_days do |t|
      t.belongs_to :season
      t.integer    :year
      t.integer    :month
      t.integer    :day
      t.timestamps
    end
  end
end
