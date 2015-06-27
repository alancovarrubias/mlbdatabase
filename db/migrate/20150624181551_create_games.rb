class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
    	t.references :away_team
    	t.references :home_team
    	t.string "year"
      t.string "month"
      t.string "day"
      t.string "num"
      t.string "time"
      t.string "ump"
      t.string "wind_1"
      t.string "humidity_1"
      t.string "pressure_1"
      t.string "temperature_1"
      t.string "precipitation_1"
      t.string "wind_2"
      t.string "humidity_2"
      t.string "pressure_2"
      t.string "temperature_2"
      t.string "precipitation_2"
      t.string "wind_3"
      t.string "humidity_3"
      t.string "pressure_3"
      t.string "temperature_3"
      t.string "precipitation_3"
      t.timestamps
    end
  end
end
