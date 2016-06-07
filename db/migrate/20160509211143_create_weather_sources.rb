class CreateWeatherSources < ActiveRecord::Migration
  def change
    create_table :weather_sources do |t|
      t.references :game, index: true, foreign_key: true
      t.integer    :hour, default: 0
      t.float      :temp
      t.float      :precip
      t.float      :windSpd
      t.float      :cldCvr
      t.float      :dewPt
      t.float      :feelsLike
      t.float      :relHum
      t.float      :sfcPres
      t.float      :spcHum
      t.timestamps
    end
  end
end
