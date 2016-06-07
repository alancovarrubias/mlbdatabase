class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      
    	t.references :away_team, :default => nil
    	t.references :home_team, :default => nil

      # Date
    	t.string "year", :default => ""
      t.string "month", :default => ""
      t.string "day", :default => ""
      t.string "num", :default => ""

      # Attributes
      t.string "time", :default => ""
      t.string "ump", :default => ""

      # Weather
      t.string "wind_1", :default => ""
      t.string "humidity_1", :default => ""
      t.string "pressure_1", :default => ""
      t.string "temperature_1", :default => ""
      t.string "precipitation_1", :default => ""
      t.string "wind_2", :default => ""
      t.string "humidity_2", :default => ""
      t.string "pressure_2", :default => ""
      t.string "temperature_2", :default => ""
      t.string "precipitation_2", :default => ""
      t.string "wind_3", :default => ""
      t.string "humidity_3", :default => ""
      t.string "pressure_3", :default => ""
      t.string "temperature_3", :default => ""
      t.string "precipitation_3", :default => ""

      t.timestamps
    end
  end
end
