class AddAirDensity < ActiveRecord::Migration
  def change
    add_column :weathers, :air_density, :float, default: 0.0
    add_column :games, :temps, :float, default: 0.0
    add_column :games, :dew, :float, default: 0.0
    add_column :games, :baro, :float, default: 0.0
    add_column :games, :humid, :float, default: 0.0
  end
end
