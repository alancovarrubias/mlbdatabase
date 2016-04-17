class RemoveExtraneousColumns < ActiveRecord::Migration
  def change
  	remove_column :games, :wind_1
  	remove_column :games, :wind_2
  	remove_column :games, :wind_3
  	remove_column :games, :humidity_1
  	remove_column :games, :humidity_2
  	remove_column :games, :humidity_3
  	remove_column :games, :temperature_1
  	remove_column :games, :temperature_2
  	remove_column :games, :temperature_3
  	remove_column :games, :precipitation_1
  	remove_column :games, :precipitation_2
  	remove_column :games, :precipitation_3
  	remove_column :games, :pressure_1
  	remove_column :games, :pressure_2
  	remove_column :games, :pressure_3
  	remove_column :games, :wind_1_value
  	remove_column :games, :wind_2_value
  	remove_column :games, :wind_3_value
  	remove_column :games, :humidity_1_value
  	remove_column :games, :humidity_2_value
  	remove_column :games, :humidity_3_value
  	remove_column :games, :temperature_1_value
  	remove_column :games, :temperature_2_value
  	remove_column :games, :temperature_3_value
  	remove_column :games, :precipitation_1_value
  	remove_column :games, :precipitation_2_value
  	remove_column :games, :precipitation_3_value
  	remove_column :games, :pressure_1_value
  	remove_column :games, :pressure_2_value
  	remove_column :games, :pressure_3_value
  	remove_column :games, :year
  	remove_column :games, :month
  	remove_column :games, :day
  end
end
